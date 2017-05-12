package Mail::SPF::Query;

# ----------------------------------------------------------
#                      Mail::SPF::Query
#   Test an IP / sender address pair for SPF authorization
#
#                   http://www.openspf.org
#         http://search.cpan.org/dist/Mail-SPF-Query
#
# Copyright (C) 2003-2005 Meng Weng Wong <mengwong+spf@pobox.com>
# Contributions by various members of the SPF project <http://www.openspf.org>
# License: like Perl, i.e. GPL-2 and Artistic License
#
# $Id: Query.pm 143 2006-02-26 17:41:10Z julian $
# ----------------------------------------------------------

use 5.006;

use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '1.999.1';  # fake version for EU::MM and CPAN
$VERSION = '1.999001';     # real numerical version

use Sys::Hostname::Long;
use Net::DNS qw();  # by default it exports mx, which we define.
use Net::CIDR::Lite;
use URI::Escape;

# ----------------------------------------------------------
#                      initialization
# ----------------------------------------------------------

my $GUESS_MECHS         = "a/24 mx/24 ptr";
my $TRUSTED_FORWARDER   = "include:spf.trusted-forwarder.org";

my $DEFAULT_EXPLANATION = "Please see http://www.openspf.org/why.html?sender=%{S}&ip=%{I}&receiver=%{R}";
my @KNOWN_MECHANISMS    = qw( a mx ptr include ip4 ip6 exists all );
my $MAX_LOOKUP_COUNT    = 10;

my $Domains_Queried     = {};

our $CACHE_TIMEOUT      = 120;
our $DNS_RESOLVER_TIMEOUT = 15;

# ----------------------------------------------------------
#        no user-serviceable parts below this line
# ----------------------------------------------------------

my $looks_like_ipv4  = qr/\d+\.\d+\.\d+\.\d+/;
my $looks_like_email = qr/\S+\@\S+/;

=head1 NAME

Mail::SPF::Query - query Sender Policy Framework for an IP,email,helo

=head1 VERSION

1.999.1

=head1 SYNOPSIS

    my $query = new Mail::SPF::Query (ip => "127.0.0.1", sender=>'foo@example.com', helo=>"somehost.example.com", trusted=>0, guess=>0);
    my ($result,           # pass | fail | softfail | neutral | none | error | unknown [mechanism]
        $smtp_comment,     # "please see http://www.openspf.org/why.html?..."  when rejecting, return this string to the SMTP client
        $header_comment,   # prepend_header("Received-SPF" => "$result ($header_comment)")
        $spf_record,       # "v=spf1 ..." original SPF record for the domain
       ) = $query->result();

    if    ($result eq "pass") { "Domain is not forged. Apply RHSBL and content filters." }
    elsif ($result eq "fail") { "Domain is forged. Reject or save to spambox." }

=head1 ABSTRACT

The SPF protocol relies on sender domains to describe their designated outbound
mailers in DNS.  Given an email address, Mail::SPF::Query determines the
legitimacy of an SMTP client IP address.

=head1 DESCRIPTION

There are two ways to use Mail::SPF::Query.  Your choice depends on whether the
domains your server is an MX for have secondary MXes which your server doesn't
know about.

The first and more common style, calling ->result(), is suitable when all mail
is received directly from the originator's MTA.  If the domains you receive do
not have secondary MX entries, this is appropriate.  This style of use is
outlined in the SYNOPSIS above.  This is the common case.

The second style is more complex, but works when your server receives mail from
secondary MXes.  This performs checks as each recipient is handled.  If the
message is coming from a valid MX secondary for a recipient, then the SPF check
is not performed, and a "pass" response is returned right away.  To do this,
call C<result2()> and C<message_result2()> instead of C<result()>.

If you do not know what a secondary MX is, you probably don't have one.  Use
the first style.

You can try out Mail::SPF::Query on the command line with the following
command:

    perl -MMail::SPF::Query -le 'print for Mail::SPF::Query->new(
        helo => shift, ipv4 => shift, sender => shift)->result' \
        helohost.example.com 1.2.3.4 user@example.com

=head1 BUGS

Mail::SPF::Query tries to implement the SPF specification (see L</"SEE ALSO">)
as close as reasonably possible given that M:S:Q has been the very first SPF
implementation and has changed with the SPF specification over time.  As a
result, M:S:Q has various known deficiencies that cannot be corrected with
reasonably little effort:

=over

=item *

B<Unable to query HELO and MAIL FROM separately.>  M:S:Q is not designed to
support the I<separate> querying of the HELO and MAIL FROM identities.  Passing
the HELO identity as the C<sender> argument for a stand-alone HELO check might
generally work but could yield unexpected results.

=item *

B<No IPv6 support.>  IPv6 is not supported.  C<ip6> mechanisms in SPF records
and everywhere else are simply ignored.

=item *

B<Result explanation may be inappropriate for local policy results.>  If a
query result was caused by anything other than a real SPF record (i.e. local
policy, overrides, fallbacks, etc.), and no custom C<default_explanation> was
specified, the domain's explanation or M:S:Q's hard-coded default explanation
will still be returned.  Be aware that in this case the explanation may not
correctly explain the reason for such an artificial result.

=for comment
INTERNAL NOTE:  If the spf_source is not 'original-spf-record' (but e.g. a
local policy source), do not return the "why.html" default explanation, because
"why.html" will not be able to reproduce the local policy.

=back

=head1 NON-STANDARD FEATURES

Also due to its long history, M:S:Q does have some legacy features that are not
parts of the official SPF specification, most notably I<best guess processing>
and I<trusted forwarder accreditation checking>.  Please be careful when using
these I<non-standard> features or when reproducing them in your own SPF
implementation, as they may cause unexpected results.

=head1 METHODS

=head2 C<< Mail::SPF::Query->new() >>

    my $query = eval { new Mail::SPF::Query (
        ip          => '127.0.0.1',
        sender      => 'foo@example.com',
        helo        => 'host.example.com',

        # Optional parameters:
        debug       => 1, debuglog => sub { print STDERR "@_\n" },
        local       => 'extra mechanisms',
        trusted     => 1,                   # do trusted forwarder processing
        guess       => 1,                   # do best guess if no SPF record
        default_explanation => 'Please see http://spf.my.isp/spferror.html for details',
        max_lookup_count    => 10,          # total number of SPF includes/redirects
        sanitize    => 0,                   # do not sanitize all returned strings
        myhostname  => 'foo.example.com',   # prepended to header_comment
        override    => {   'example.net' => 'v=spf1 a mx -all',
                         '*.example.net' => 'v=spf1 a mx -all' },
        fallback    => {   'example.org' => 'v=spf1 a mx -all',
                         '*.example.org' => 'v=spf1 a mx -all' }
    ) };

    if ($@) { warn "bad input to Mail::SPF::Query: $@" }

Set C<trusted=E<gt>1> to turned on C<trusted-forwarder.org> accreditation
checking.  The mechanism C<include:spf.trusted-forwarder.org> is used just
before a C<-all> or C<?all>.  The precise circumstances are somewhat more
complicated, but it does get the case of C<v=spf1 -all> right -- i.e.
C<trusted-forwarder.org> is not checked.  B<This is a non-standard feature.>

Set C<guess=E<gt>1> to turned on automatic best guess processing.  This will
use the best_guess SPF record when one cannot be found in the DNS.  Note that
this can only return C<pass> or C<neutral>.  The C<trusted> and C<local> flags
also operate when the best_guess is being used.  B<This is a non-standard
feature.>

Set C<local=E<gt>'include:local.domain'> to include some extra processing just
before a C<-all> or C<?all>.  The local processing happens just before the
trusted forwarder processing.  B<This is a non-standard feature.>

Set C<default_explanation> to a string to be used if the SPF record does not
provide a specific explanation. The default value will direct the user to a
page at www.openspf.org with the following message:

    Please see http://www.openspf.org/why.html?sender=%{S}&ip=%{I}&receiver=%{R}

Note that the string has macro substitution performed.

Set C<sanitize> to 0 to get all the returned strings unsanitized.
Alternatively, pass a function reference and this function will be used to
sanitize the returned values.  The function must take a single string argument
and return a single string which contains the sanitized result.

Set C<debug=E<gt>1> to watch the queries happen.

Set C<override> to define SPF records for domains that do publish but which you
want to override anyway.  Wildcards are supported.  B<This is a non-standard
feature.>

Set C<fallback> to define "pretend" SPF records for domains that don't publish
them yet.  Wildcards are supported.  B<This is a non-standard feature.>

Note: domain name arguments to override and fallback need to be in all
lowercase.

=cut

# ----------------------------------------------------------
#                            new
# ----------------------------------------------------------

sub new {
  my $class = shift;
  my $query = bless { @_ }, $class;

  $query->{lookup_count} = 0;

  $query->{ipv4} = delete $query->{ip}
    if defined($query->{ip}) and $query->{ip} =~ $looks_like_ipv4;
  $query->{helo} = delete $query->{ehlo}
    if defined($query->{ehlo});

  $query->{local} .= ' ' . $TRUSTED_FORWARDER if ($query->{trusted});

  $query->{trusted} = undef;

  $query->{spf_error_explanation} ||= "SPF record error";

  $query->{default_explanation} ||= $DEFAULT_EXPLANATION;

  $query->{default_record} = $GUESS_MECHS if ($query->{guess});

  if (($query->{sanitize} && !ref($query->{sanitize})) || !defined($query->{sanitize})) {
      # Apply default sanitizer
      $query->{sanitize} = \&strict_sanitize;
  }

  $query->{sender} =~ s/<(.*)>/$1/g;

  if (not ($query->{ipv4} and length $query->{ipv4})) {
    die "no IP address given";
  }

  for ($query->{sender}) { s/^\s+//; s/\s+$//; }

  $query->{spf_source} = "domain of $query->{sender}";
  $query->{spf_source_type} = "original-spf-record";

  ($query->{domain}) = $query->{sender} =~ /([^@]+)$/; # given foo@bar@baz.com, the domain is baz.com, not bar@baz.com.

  # the domain should not be an address literal --- [1.2.3.4]
  if ($query->{domain} =~ /^\[\d+\.\d+\.\d+\.\d+\]$/) {
    die "sender domain should be an FQDN, not an address literal";
  }

  if (not $query->{helo}) { require Carp; import Carp qw(cluck); cluck ("Mail::SPF::Query: ->new() requires a \"helo\" argument.\n");
                            $query->{helo} = $query->{domain};
                          }

  $query->debuglog("new: ipv4=$query->{ipv4}, sender=$query->{sender}, helo=$query->{helo}");

  ($query->{helo}) =~ s/.*\@//; # strip localpart from helo

  if (not $query->{domain}) {
    $query->debuglog("sender $query->{sender} has no domain, using HELO domain $query->{helo} instead.");
    $query->{domain} = $query->{helo};
    $query->{sender} = $query->{helo};
  }

  if (not length $query->{domain}) { die "unable to identify domain of sender $query->{sender}" }

  $query->{orig_domain} = $query->{domain};

  $query->{loop_report} = [$query->{domain}];

  ($query->{localpart}) = $query->{sender} =~ /(.+)\@/;
  $query->{localpart} = "postmaster" if not length $query->{localpart};

  $query->debuglog("localpart is $query->{localpart}");

  $query->{Reversed_IP} = ($query->{ipv4} ? reverse_in_addr($query->{ipv4}) :
                           $query->{ipv6} ? die "IPv6 not supported" : "");

  if (not $query->{myhostname}) {
    $query->{myhostname} = Sys::Hostname::Long::hostname_long();
  }
  $query->{myhostname} ||= "localhost";

  # Unfold legacy { 'domain' => { record => '...' } } override and fallback
  # structures to just { 'domain' => '...' }:
  foreach ('override', 'fallback') {
    if (ref(my $domains_hash = $query->{$_}) eq 'HASH') {
      foreach my $domain (keys(%$domains_hash)) {
        $domains_hash->{$domain} = $domains_hash->{$domain}->{record}
          if ref($domains_hash->{$domain}) eq 'HASH';
      }
    }
  }

  $query->post_new(@_) if $class->can("post_new");

  return $query;
}

=head2 C<< $query->result() >>

    my ($result, $smtp_comment, $header_comment, $spf_record, $detail) = $query->result();

C<$result> will be one of C<pass>, C<fail>, C<softfail>, C<neutral>, C<none>,
C<error> or C<unknown [...]>:

=over

=item C<pass>

The client IP address is an authorized mailer for the sender.  The mail should
be accepted subject to local policy regarding the sender.

=item C<fail>

The client IP address is not an authorized mailer, and the sender wants you to
reject the transaction for fear of forgery.

=item C<softfail>

The client IP address is not an authorized mailer, but the sender prefers that
you accept the transaction because it isn't absolutely sure all its users are
mailing through approved servers.  The C<softfail> status is often used during
initial deployment of SPF records by a domain.

=item C<neutral>

The sender makes no assertion about the status of the client IP.

=item C<none>

There is no SPF record for this domain.

=item C<error>

The DNS lookup encountered a temporary error during processing.

=item C<unknown [...]>

The domain has a configuration error in the published data or defines a
mechanism that this library does not understand.  If the data contained an
unrecognized mechanism, it will be presented following "unknown".  You should
test for unknown using a regexp C</^unknown/> rather than C<eq "unknown">.

=back

Results are cached internally for a default of 120 seconds.  You can call
C<-E<gt>result()> repeatedly; subsequent lookups won't hit your DNS.

C<smtp_comment> should be displayed to the SMTP client.

C<header_comment> goes into a C<Received-SPF> header, like so:

    Received-SPF: $result ($header_comment)

C<spf_record> shows the original SPF record fetched for the query.  If there is
no SPF record, it is blank.  Otherwise, it will start with C<v=spf1> and
contain the SPF mechanisms and such that describe the domain.

Note that the strings returned by this method (and most of the other methods)
are (at least partially) under the control of the sender's domain.  This means
that, if the sender is an attacker, the contents can be assumed to be hostile.
The various methods that return these strings make sure that (by default) the
strings returned contain only characters in the range 32 - 126.  This behavior
can be changed by setting C<sanitize> to 0 to turn off sanitization entirely.
You can also set C<sanitize> to a function reference to perform custom
sanitization.  In particular, assume that C<smtp_comment> might contain a
newline character. 

C<detail> is a hash of all the foregoing result elements, plus extra data
returned by the SPF result.

I<Why the weird duplication?>  In the beginning, C<result()> returned only one
value, the C<$result>.  Then C<$smtp_comment> and C<$header_comment> came
along.  Then C<$spf_record>.  Past a certain number of positional results, it
makes more sense to have a hash.  But we didn't want to break backwards
compatibility, so we just declared that the fifth result would be a hash and
future return value would go in there.

The keys of the hash are:

    result
    smtp_comment
    header_comment
    header_pairs
    spf_record
    modifiers

=cut

# ----------------------------------------------------------
#                           result
# ----------------------------------------------------------

sub result {
  my $query = shift;
  my %result_set;

  my ($result, $smtp_explanation, $smtp_why, $orig_txt) = $query->spfquery(
    $query->{best_guess} ? $query->{guess_mechs} : ()
  );

  $smtp_why = "" if $smtp_why eq "default";

  my $smtp_comment = ($smtp_explanation && $smtp_why) ? "$smtp_explanation: $smtp_why" : ($smtp_explanation || $smtp_why);

  $query->{smtp_comment} = $smtp_comment;

  my $header_comment = "$query->{myhostname}: ". $query->header_comment($result);

  # $result =~ s/\s.*$//; # this regex truncates "unknown some:mechanism" to just "unknown"

  $query->{result} = $result;

  my $hash = { result         => $query->sanitize(lc $result),
               smtp_comment   => $query->sanitize($smtp_comment),
               header_comment => $query->sanitize($header_comment),
               spf_record     => $query->sanitize($orig_txt),
               modifiers      => $query->{modifiers},
               header_pairs   => $query->sanitize(scalar $query->header_pairs()),
             };        

  return ($hash->{result},
          $hash->{smtp_comment},
          $hash->{header_comment},
          $hash->{spf_record},
          $hash,
         ) if wantarray;

  return  $query->sanitize(lc $result);
}

sub header_comment {
  my $query = shift;
  my $result = shift;
  my $ip = $query->ip;
  if ($result eq "pass" and $query->{smtp_comment} eq "localhost is always allowed.") { return $query->{smtp_comment} }

  $query->debuglog("header_comment: spf_source = $query->{spf_source}");
  $query->debuglog("header_comment: spf_source_type = $query->{spf_source_type}");

  if ($query->{spf_source_type} eq "original-spf-record") {
  return
    (  $result eq "pass"      ? "$query->{spf_source} designates $ip as permitted sender"
     : $result eq "fail"      ? "$query->{spf_source} does not designate $ip as permitted sender"
     : $result eq "softfail"  ? "transitioning $query->{spf_source} does not designate $ip as permitted sender"
     : $result =~ /^unknown / ? "encountered unrecognized mechanism during SPF processing of $query->{spf_source}"
     : $result eq "unknown"   ? "error in processing during lookup of $query->{sender}"
     : $result eq "neutral"   ? "$ip is neither permitted nor denied by domain of $query->{sender}"
     : $result eq "error"     ? "encountered temporary error during SPF processing of $query->{spf_source}"
     : $result eq "none"      ? "$query->{spf_source} does not designate permitted sender hosts" 
     :                          "could not perform SPF query for $query->{spf_source}" );
  }

  return $query->{spf_source};

}

sub header_pairs {
  my $query = shift;
# from spf-draft-200404.txt
#    SPF clients may append zero or more of the following key-value-pairs
#    at their discretion:
# 
#       receiver       the hostname of the SPF client
#       client-ip      the IP address of the SMTP client
#       envelope-from  the envelope sender address
#       helo           the hostname given in the HELO or EHLO command
#       mechanism      the mechanism that matched (if no mechanisms
#                      matched, substitute the word "default".)
#       problem        if an error was returned, details about the error
# 
#    Other key-value pairs may be defined by SPF clients.  Until a new key
#    name becomes widely accepted, new key names should start with "x-".

  my @pairs = (
               "receiver"      => $query->{myhostname},
               "client-ip"     => ($query->{ipv4} || $query->{ipv6} || ""),
               "envelope-from" => $query->{sender},
               "helo"          => $query->{helo},
               mechanism       => ($query->{matched_mechanism} ? display_mechanism($query->{matched_mechanism}) : "default"),
               ($query->{result} eq "error"
                ? (problem         => $query->{spf_error_explanation})
                : ()),
               ($query->{spf_source_type} ne "original-spf-record" ? ("x-spf-source" => $query->{spf_source}) : ()),
              );

  if (wantarray) { return @pairs; }
  my @pair_text;
  while (@pairs) {
    my ($key, $val) = (shift(@pairs), shift (@pairs));
    push @pair_text, "$key=$val;";
  }
  return join " ", @pair_text;
}

=head2 C<< $query->result2() >>

    my ($result, $smtp_comment, $header_comment, $spf_record) = $query->result2('recipient@domain', 'recipient2@domain');

C<result2()> does everything that C<result()> does, but it first checks to see if
the sending system is a recognized MX secondary for the recipient(s).  If so,
then it returns C<pass> and does not perform the SPF query.  Note that the
sending system may be a MX secondary for some (but not all) of the recipients
for a multi-recipient message, which is why result2 takes an argument list.
See also C<message_result2()>.

B<This is a non-standard feature.>  B<This feature is also deprecated, because
exemption of trusted relays, such as secondary MXes, should really be performed
by the software that uses this library before doing an SPF check.>

C<$result> will be one of C<pass>, C<fail>, C<neutral [...]>, or C<unknown>.
See C<result()> above for meanings.

If you have secondary MXes and if you are unable to explicitly white-list them
before SPF tests occur, you can use this method in place of C<result()>,
calling it as many times as there are recipients, or just providing all the
recipients at one time.

C<smtp_comment> can be displayed to the SMTP client.

For example:

    my $query = new Mail::SPF::Query (ip => "127.0.0.1",
                                      sender=>'foo@example.com',
                                      helo=>"somehost.example.com");

    ...

    my ($result, $smtp_comment, $header_comment);

    ($result, $smtp_comment, $header_comment) = $query->result2('recip1@example.com');
    # return suitable error code based on $result eq 'fail' or not

    ($result, $smtp_comment, $header_comment) = $query->result2('recip2@example.org');
    # return suitable error code based on $result eq 'fail' or not

    ($result, $smtp_comment, $header_comment) = $query->message_result2();
    # return suitable error if $result eq 'fail'
    # prefix message with "Received-SPF: $result ($header_comment)"

=cut

# ----------------------------------------------------------
#                           result2
# ----------------------------------------------------------

sub result2 {
  my $query = shift;
  my @recipients = @_;

  if (!$query->{result2}) {
      my $all_mx_secondary = 'neutral';

      foreach my $recip (@recipients) {
          my ($rhost) = $recip =~ /([^@]+)$/;

          $query->debuglog("result2: Checking status of recipient $recip (at host $rhost)");

          my $cache_result = $query->{mx_cache}->{$rhost};
          if (not defined($cache_result)) {
              $cache_result = $query->{mx_cache}->{$rhost} = is_secondary_for($rhost, $query->{ipv4}) ? 'yes' : 'no';
              $query->debuglog("result2: $query->{ipv4} is a MX for $rhost: $cache_result");
          }

          if ($cache_result eq 'yes') {
              $query->{is_mx_good} = [$query->sanitize('pass'),
                                      $query->sanitize('message from secondary MX'),
                                      $query->sanitize("$query->{myhostname}: message received from $query->{ipv4} which is an MX secondary for $recip"),
                                      undef];
              $all_mx_secondary = 'yes';
          } else {
              $all_mx_secondary = 'no';
              last;
          }
      }

      if ($all_mx_secondary eq 'yes') {
          return @{$query->{is_mx_good}} if wantarray;
          return $query->{is_mx_good}->[0];
      }

      my @result = $query->result();

      $query->{result2} = \@result;
  }

  return @{$query->{result2}} if wantarray;
  return $query->{result2}->[0];
}

sub is_secondary_for {
    my ($host, $addr) = @_;

    my $resolver = Net::DNS::Resolver->new(
                                           tcp_timeout => $DNS_RESOLVER_TIMEOUT,
                                           udp_timeout => $DNS_RESOLVER_TIMEOUT,
                                           )
                                           ;
    if ($resolver) {
        my $mx = $resolver->send($host, 'MX');
        if ($mx) {
            my @mxlist = sort { $a->preference <=> $b->preference } (grep { $_->type eq 'MX' } $mx->answer);
            # discard the first entry (top priority) - we shouldn't get mail from them
            shift @mxlist;
            foreach my $rr (@mxlist) {
                my $a = $resolver->send($rr->exchange, 'A');
                if ($a) {
                    foreach my $rra ($a->answer) {
                        if ($rra->type eq 'A') {
                            if ($rra->address eq $addr) {
                                return 1;
                            }
                        }
                    }
                }
            }
        }
    }

    return undef;
}

=head2 C<< $query->message_result2() >>

    my ($result, $smtp_comment, $header_comment, $spf_record) = $query->message_result2();

C<message_result2()> returns an overall status for the message after zero or
more calls to C<result2()>.  It will always be the last status returned by
C<result2()>, or the status returned by C<result()> if C<result2()> was never
called.

C<$result> will be one of C<pass>, C<fail>, C<neutral [...]>, or C<error>.  See
C<result()> above for meanings.

=cut

# ----------------------------------------------------------
#                           message_result2
# ----------------------------------------------------------

sub message_result2 {
  my $query = shift;

  if (!$query->{result2}) {
      if ($query->{is_mx_good}) {
          return @{$query->{is_mx_good}} if wantarray;
          return $query->{is_mx_good}->[0];
      }

      # we are very unlikely to get here -- unless result2 was not called.

      my @result = $query->result();

      $query->{result2} = \@result;
  }

  return @{$query->{result2}} if wantarray;
  return $query->{result2}->[0];
}

=head2 C<< $query->best_guess() >>

    my ($result, $smtp_comment, $header_comment) = $query->best_guess();

When a domain does not publish an SPF record, this library can produce an
educated guess anyway.

It pretends the domain defined A, MX, and PTR mechanisms, plus a few others.
The default set of directives is

    a/24 mx/24 ptr

That default set will return either "pass" or "neutral".

If you want to experiment with a different default, you can pass it as an
argument: C<< $query->best_guess("a mx ptr") >>

B<This is a non-standard feature.>  B<This method is also deprecated.>  You
should set C<guess=E<gt>1> on the C<new()> method instead.

=head2 C<< $query->trusted_forwarder() >>

    my ($result, $smtp_comment, $header_comment) = $query->best_guess();

It is possible that the message is coming through a known-good relay like
C<acm.org> or C<pobox.com>.  During the transitional period, many legitimate
services may appear to forge a sender address: for example, a news website may
have a "send me this article in email" link.

The C<trusted-forwarder.org> domain is a white-list of known-good hosts that
either forward mail or perform benign envelope sender forgery:

    include:spf.trusted-forwarder.org

This will return either "pass" or "neutral".

B<This is a non-standard feature.>  B<This method is also deprecated.>  You
should set C<trusted=E<gt>1> on the C<new()> method instead.

=cut

sub clone {
  my $query = shift;
  my $class = ref $query;

  my %guts = (%$query, @_, parent=>$query);

  my $clone = bless \%guts, $class;

  push @{$clone->{loop_report}}, delete $clone->{reason};

  $query->debuglog("  clone: new object:");
  for ($clone->show) { $clone->debuglog( "clone: $_" ) }

  return $clone;
}

sub top {
  my $query = shift;
  if ($query->{parent}) { return $query->{parent}->top }
  return $query;
}

sub set_temperror {
  my $query = shift;
  $query->{error} = shift;
}

sub show {
  my $query = shift;

  return map { sprintf ("%20s = %s", $_, $query->{$_}) } keys %$query;
}

sub best_guess {
  my $query = shift;
  my $guess_mechs = shift || $GUESS_MECHS;

  # clone the query object with best_guess mode turned on.
  my $guess_query = $query->clone( best_guess => 1,
                                   guess_mechs => $guess_mechs,
                                   reason => "has no data.  best guess",
                                 );

  $guess_query->top->{lookup_count} = 0;

  # if result is not defined, the domain has no SPF.
  #    perform fallback lookups.
  #    perform trusted-forwarder lookups.
  #    perform guess lookups.
  #
  # if result is defined, return it.

  my ($result, $smtp_comment, $header_comment) = $guess_query->result();
  if (defined $result and $result eq "pass") {
    my $ip = $query->ip;
    $header_comment = $query->sanitize("seems reasonable for $query->{sender} to mail through $ip");
    return ($result, $smtp_comment, $header_comment) if wantarray;
    return $result;
  }

  return $query->sanitize("neutral");
}

sub trusted_forwarder {
  my $query = shift;
  my $guess_mechs = shift || $TRUSTED_FORWARDER;
  return $query->best_guess($guess_mechs);
}

# ----------------------------------------------------------

=head2 C<< $query->sanitize('string') >>

This applies the sanitization rules for the particular query object. These
rules are controlled by the C<sanitize> parameter to the c<new()> method.

=cut

sub sanitize {
  my $query = shift;
  my $txt = shift;

  if (ref($query->{sanitize})) {
      $txt = $query->{sanitize}->($txt);
  }

  return $txt;
}

# ----------------------------------------------------------

=head2 C<< strict_sanitize('string') >>

This ensures that all the characters in the returned string are printable.  All
whitespace is converted into spaces, and all other non-printable characters are
converted into question marks.  This is probably over-aggressive for many
applications.

This function is used by default when the C<sanitize> option is passed to the
C<new()> method.

B<This function is not a class method.>

=cut

sub strict_sanitize {
  my $txt = shift;

  $txt =~ s/\s/ /g;
  $txt =~ s/[^[:print:]]/?/g;

  return $txt;
}

# ----------------------------------------------------------

=head2 C<< $query->debuglog() >>

Subclasses may override this with their own debug logger.  C<Log::Dispatch> is
recommended.

Alternatively, pass the C<new()> constructor a C<< debuglog => sub { ... } >>
callback, and we'll pass debugging lines to that.

=cut

sub debuglog {
  my $query = shift;
  return if ref $query and not $query->{debug};
  
  my $toprint = join (" ", @_);
  chomp $toprint;
  $toprint = sprintf ("%-8s %s %s %s",
                      ("|" x ($query->top->{lookup_count}+1)),
                      $query->{localpart},
                      $query->{domain},
                      $toprint);

  if (exists $query->{debuglog} and ref $query->{debuglog} eq "CODE") {
    eval { $query->{debuglog}->($toprint) };
  }
  else {
    printf STDERR "%s", "$toprint\n";
  }
}

# ----------------------------------------------------------
#                           spfquery
# ----------------------------------------------------------

sub spfquery {
  #
  # usage: my ($result, $explanation, $text, $time) = $query->spfquery( [ GUESS_MECHS ] )
  #
  #  performs a full SPF resolution using the data in $query.  to use different data, clone the object.
  #
  #  if GUESS_MECHS is present, we are operating in "guess" mode so we will not actually query the domain for TXT; we will use the guess_mechs instead.
  #
  my $query = shift;
  my $guess_mechs = shift;

  if ($query->{ipv4} and
      $query->{ipv4}=~ /^127\./) { return "pass", "localhost is always allowed." }

  $query->top->{lookup_count}++;

  if ($query->is_looping)            { return "unknown", $query->{spf_error_explanation}, $query->is_looping }
  if ($query->can_use_cached_result) { return $query->cached_result; }
  else                               { $query->tell_cache_that_lookup_is_underway; }

  my $directive_set = DirectiveSet->new($query->{domain}, $query, $guess_mechs, $query->{local}, $query->{default_record});

  if (not defined $directive_set) {
    $query->debuglog("no SPF record found for $query->{domain}");
    $query->delete_cache_point;
    if ($query->{domain} ne $query->{orig_domain}) {
        if ($query->{error}) {
            return "error", $query->{spf_error_explanation}, $query->{error};
        }
        return "unknown", $query->{spf_error_explanation}, "Missing SPF record at $query->{domain}";
    }
    if ($query->{last_dns_error} eq 'NXDOMAIN') {
        my $explanation = $query->macro_substitute($query->{default_explanation});
        return "unknown", $explanation, "domain of sender $query->{sender} does not exist";
    }
    return "none", "SPF", "domain of sender $query->{sender} does not designate mailers";
  }

  if ($directive_set->{hard_syntax_error}) {
    $query->debuglog("  syntax error while parsing $directive_set->{txt}");
    $query->delete_cache_point;
    return "unknown", $query->{spf_error_explanation}, $directive_set->{hard_syntax_error};
  }

  $query->{directive_set} = $directive_set;

  foreach my $mechanism ($directive_set->mechanisms) {
    my ($result, $comment) = $query->evaluate_mechanism($mechanism);

    if ($query->{error}) {
      $query->debuglog("  returning temporary error: $query->{error}");
      $query->delete_cache_point;
      return "error", $query->{spf_error_explanation}, $query->{error};
    }

    if (defined $result) {
      $query->debuglog("  saving result $result to cache point and returning.");
      my $explanation = $query->interpolate_explanation(
            ($result =~ /^unknown/)
            ? $query->{spf_error_explanation} : $query->{default_explanation});
      $query->save_result_to_cache($result,
                                   $explanation,
                                   $comment,
                                   $query->{directive_set}->{orig_txt});
      $query->{matched_mechanism} = $mechanism;
      return $result, $explanation, $comment, $query->{directive_set}->{orig_txt};
    }
  }

  # run the redirect modifier
  if ($query->{directive_set}->redirect) {
    my $new_domain = $query->macro_substitute($query->{directive_set}->redirect);

    $query->debuglog("  executing redirect=$new_domain");

    my $inner_query = $query->clone(domain => $new_domain,
                                    reason => "redirects to $new_domain",
                                   );

    my @inner_result = $inner_query->spfquery();

    $query->delete_cache_point;

    $query->debuglog("  executed redirect=$new_domain, got result @inner_result");

    $query->{spf_source} = $inner_query->{spf_source};
    $query->{spf_source_type} = $inner_query->{spf_source_type};
    $query->{matched_mechanism} = $inner_query->{matched_mechanism};

    return @inner_result;
  }

  $query->debuglog("  no mechanisms matched; deleting cache point and using neutral");
  $query->delete_cache_point;
  return "neutral", $query->interpolate_explanation($query->{default_explanation}), $directive_set->{soft_syntax_error};
}

# ----------------------------------------------------------
#             we cache into $Domains_Queried.
# ----------------------------------------------------------

sub cache_point {
  my $query = shift;
  return my $cache_point = join "/", ($query->{best_guess}  || 0,
                                      $query->{guess_mechs} || "",
                                      $query->{ipv4},
                                      $query->{localpart},
                                      $query->{domain},
                                      $query->{default_record},
                                      $query->{local});
}

sub is_looping {
  my $query = shift;
  my $cache_point = $query->cache_point;

  return join(" ", "loop encountered:", @{$query->{loop_report}})
    if  exists $Domains_Queried->{$cache_point}
    and not defined $Domains_Queried->{$cache_point}->[0];

  return join(" ", "query caused more than" . $query->max_lookup_count . " lookups:", @{$query->{loop_report}})
    if $query->max_lookup_count and $query->top->{lookup_count} > $query->max_lookup_count;

  return 0;
}

sub max_lookup_count {
  my $query = shift;
  return $query->{max_lookup_count} || $MAX_LOOKUP_COUNT;
}

sub can_use_cached_result {
  my $query = shift;
  my $cache_point = $query->cache_point;

  if ($Domains_Queried->{$cache_point}) {
    $query->debuglog("  lookup: we have already processed $query->{domain} before with $query->{ipv4}.");
    my @cached = @{ $Domains_Queried->{$cache_point} };
    if (not defined $CACHE_TIMEOUT
        or time - $cached[-1] > $CACHE_TIMEOUT) {
      $query->debuglog("  lookup: but its cache entry is stale; deleting it.");
      delete $Domains_Queried->{$cache_point};
      return 0;
    }

    $query->debuglog("  lookup: the cache entry is fresh; returning it.");
    return 1;
  }
  return 0;
}

sub tell_cache_that_lookup_is_underway {
  my $query = shift;

  # define an entry here so we don't loop endlessly in an Include loop.
  $Domains_Queried->{$query->cache_point} = [undef, undef, undef, undef, time];
}

sub save_result_to_cache {
  my $query = shift;
  my ($result, $explanation, $comment, $orig_txt) = (shift, shift, shift, shift);

  # define an entry here so we don't loop endlessly in an Include loop.
  $Domains_Queried->{$query->cache_point} = [$result, $explanation, $comment, $orig_txt, time];
}

sub cached_result {
  my $query = shift;
  my $cache_point = $query->cache_point;

  if ($Domains_Queried->{$cache_point}) {
    return @{ $Domains_Queried->{$cache_point} };
  }
  return;
}

sub delete_cache_point {
  my $query = shift;
  delete $Domains_Queried->{$query->cache_point};
}

sub clear_cache {
  $Domains_Queried = {};
}

sub get_ptr_domain {
    my ($query) = shift;

    return $query->{ptr_domain} if ($query->{ptr_domain});
    
    foreach my $ptrdname ($query->myquery(reverse_in_addr($query->{ipv4}) . ".in-addr.arpa", "PTR", "ptrdname")) {
        $query->debuglog("  get_ptr_domain: $query->{ipv4} is $ptrdname");
    
        $query->debuglog("  get_ptr_domain: checking hostname $ptrdname for legitimacy.");
    
        # check for legitimacy --- PTR -> hostname A -> PTR
        foreach my $ptr_to_a ($query->myquery($ptrdname, "A", "address")) {
          
            $query->debuglog("  get_ptr_domain: hostname $ptrdname -> $ptr_to_a");
      
            if ($ptr_to_a eq $query->{ipv4}) {
                return $query->{ptr_domain} = $ptrdname;
            }
        }
    }

    return undef;
}

sub macro_substitute_item {
    my $query = shift;
    my $arg = shift;

    if ($arg eq "%") { return "%" }
    if ($arg eq "_") { return " " }
    if ($arg eq "-") { return "%20" }

    $arg =~ s/^{(.*)}$/$1/;

    my ($field, $num, $reverse, $delim) = $arg =~ /^(x?\w)(\d*)(r?)(.*)$/;

    $delim = '.' if not length $delim;

    my $newval = $arg;
    my $timestamp = time;

    $newval = $query->{localpart}       if (lc $field eq 'u');
    $newval = $query->{localpart}       if (lc $field eq 'l');
    $newval = $query->{domain}          if (lc $field eq 'd');
    $newval = $query->{sender}          if (lc $field eq 's');
    $newval = $query->{orig_domain}     if (lc $field eq 'o');
    $newval = $query->ip                if (lc $field eq 'i');
    $newval = $timestamp                if (lc $field eq 't');
    $newval = $query->{helo}            if (lc $field eq 'h');
    $newval = $query->get_ptr_domain    if (lc $field eq 'p');
    $newval = $query->{myhostname}      if (lc $field eq 'r');  # only used in explanation
    $newval = $query->{ipv4} ? 'in-addr' : 'ip6'
                                        if (lc $field eq 'v');

    # We need to escape a bunch of characters inside a character class
    $delim =~ s/([\^\-\]\:\\])/\\$1/g;

    if (length $delim) {
        my @parts = split /[$delim]/, $newval;

        @parts = reverse @parts if ($reverse);

        if ($num) {
            while (@parts > $num) { shift @parts }
        }

        $newval = join ".", @parts;
    }

    $newval = uri_escape($newval)       if ($field ne lc $field);

    $query->debuglog("  macro_substitute_item: $arg: field=$field, num=$num, reverse=$reverse, delim=$delim, newval=$newval");

    return $newval;
}

sub macro_substitute {
    my $query = shift;
    my $arg = shift;
    my $maxlen = shift;

    my $original = $arg;

    # macro-char   = ( '%{' alpha *digit [ 'r' ] *delim '}' )
    #                / '%%'
    #                / '%_'
    #                / '%-'

    $arg =~ s/%([%_-]|{(\w[^}]*)})/$query->macro_substitute_item($1)/ge;

    if ($maxlen && length $arg > $maxlen) {
      $arg = substr($arg, -$maxlen);  # super.long.string -> er.long.string
      $arg =~ s/[^.]*\.//;            #    er.long.string ->    long.string
    }
    $query->debuglog("  macro_substitute: $original -> $arg") if ($original ne $arg);
    return $arg;
}

# ----------------------------------------------------------
#                    display_mechanism
# 
# in human-readable form; used in header_pairs above.
# ----------------------------------------------------------

sub display_mechanism {
  my ($modifier, $mechanism, $argument, $source) = @{shift()};

  return "$modifier$mechanism" . (length($argument) ? ":$argument" : "");
}

# ----------------------------------------------------------
#                    evaluate_mechanism
# ----------------------------------------------------------

sub evaluate_mechanism {
  my $query = shift;
  my ($modifier, $mechanism, $argument, $source) = @{shift()};

  $modifier = "+" if not length $modifier;

  $query->debuglog("  evaluate_mechanism: $modifier$mechanism($argument) for domain=$query->{domain}");

  if ({ map { $_=>1 } @KNOWN_MECHANISMS }->{$mechanism}) {
    my $mech_sub = "mech_$mechanism";
    my ($hit, $text) = $query->$mech_sub($query->macro_substitute($argument, 255));
    no warnings 'uninitialized';
    $query->debuglog("  evaluate_mechanism: $modifier$mechanism($argument) returned $hit $text");

    return if not $hit;

    return ($hit, $text) if ($hit ne "hit");
    
    if ($source) {
      $query->{spf_source} = $source;
      $query->{spf_source_type} = "from mechanism $mechanism";
    }

    return $query->shorthand2value($modifier), $text;
  }
  else {
    my $unrecognized_mechanism = join ("",
                                       ($modifier eq "+" ? "" : $modifier),
                                       $mechanism,
                                       ($argument ? ":" : ""),
                                       $argument);
    my $error_string = "unknown $unrecognized_mechanism";
    $query->debuglog("  evaluate_mechanism: unrecognized mechanism $unrecognized_mechanism, returning $error_string");
    return $error_string => "unrecognized mechanism $unrecognized_mechanism";
  }

  return ("neutral", "evaluate-mechanism: neutral");
}

# ----------------------------------------------------------
#            myquery wraps DNS resolver queries
#
# ----------------------------------------------------------

sub myquery {
  my $query = shift;
  my $label = shift;
  my $qtype = shift;
  my $method = shift;
  my $sortby = shift;

  $query->debuglog("  myquery: doing $qtype query on $label");

  for ($label) {
    if (/\.\./ or /^\./) {
      # convert .foo..com to foo.com, etc.
      $query->debuglog("  myquery: fixing up invalid syntax in $label");
      s/\.\.+/\./g;
      s/^\.//;
      $query->debuglog("  myquery: corrected label is $label");
    }
  }
  my $resquery = $query->resolver->query($label, $qtype);

  my $errorstring = $query->resolver->errorstring;
  if (not $resquery and $errorstring eq "NOERROR") {
    return;
  }

  $query->{last_dns_error} = $errorstring;

  if (not $resquery) {
    if ($errorstring eq "NXDOMAIN") {
      $query->debuglog("  myquery: $label $qtype failed: NXDOMAIN.");
      return;
    }

    $query->debuglog("  myquery: $label $qtype lookup error: $errorstring");
    $query->debuglog("  myquery: will set error condition.");
    $query->set_temperror("DNS error while looking up $label $qtype: $errorstring");
    return;
  }

  my @answers = grep { lc $_->type eq lc $qtype } $resquery->answer;

  # $query->debuglog("  myquery: found $qtype response: @answers");

  my @toreturn;
  if ($sortby) { @toreturn = map { rr_method($_,$method) } sort { $a->$sortby() <=> $b->$sortby() } @answers; }
  else         { @toreturn = map { rr_method($_,$method) }                                          @answers; }

  if (not @toreturn) {
    $query->debuglog("  myquery: result had no data.");
    return;
  }

  return @toreturn;
}

sub rr_method {
  my ($answer, $method) = @_;
  if ($method ne "char_str_list") { return $answer->$method() }

  # long TXT records can't be had with txtdata; they need to be pulled out with char_str_list which returns a list of strings
  # that need to be joined.

  my @char_str_list = $answer->$method();
  # print "rr_method returning join of @char_str_list\n";

  return join "", @char_str_list;
}

#
# Mechanisms return one of the following:
#
# undef     mechanism did not match
# "hit"     mechanism matched
# "unknown" some error happened during processing
# "error"   some temporary error
#
# ----------------------------------------------------------
#                           all
# ----------------------------------------------------------

sub mech_all {
  my $query = shift;
  return "hit" => "default";
}

# ----------------------------------------------------------
#                         include
# ----------------------------------------------------------

sub mech_include {
  my $query = shift;
  my $argument = shift;

  if (not $argument) {
    $query->debuglog("  mechanism include: no argument given.");
    return "unknown", "include mechanism not given an argument";
  }

  $query->debuglog("  mechanism include: recursing into $argument");

  my $inner_query = $query->clone(domain => $argument,
                                  reason => "includes $argument",
                                  local => undef,
                                  trusted => undef,
                                  guess => undef,
                                  default_record => undef,
                                 );

  my ($result, $explanation, $text, $orig_txt, $time) = $inner_query->spfquery();

  $query->debuglog("  mechanism include: got back result $result / $text / $time");

  if ($result eq "pass")            { return hit     => $text, $time; }
  if ($result eq "error")           { return $result => $text, $time; }
  if ($result eq "unknown")         { return $result => $text, $time; }
  if ($result eq "none")            { return unknown => $text, $time; } # fail-safe mode.  convert an included NONE into an UNKNOWN error.
  if ($result eq "fail" ||
      $result eq "neutral" ||
      $result eq "softfail")        { return undef,     $text, $time; }
  
  $query->debuglog("  mechanism include: reducing result $result to unknown");
  return "unknown", $text, $time;
}

# ----------------------------------------------------------
#                            a
# ----------------------------------------------------------

sub mech_a {
  my $query = shift;
  my $argument = shift;
  
  my $ip4_cidr_length = ($argument =~ s/  \/(\d+)//x) ? $1 : 32;
  my $ip6_cidr_length = ($argument =~ s/\/\/(\d+)//x) ? $1 : 128;

  my $domain_to_use = $argument || $query->{domain};

  # see code below in ip4 for more validation
  if ($domain_to_use !~ / \. [a-z] (?: [a-z0-9-]* [a-z0-9] ) $ /ix) {
    return ("unknown" => "bad argument to a: $domain_to_use not a valid FQDN");
  }

  foreach my $a ($query->myquery($domain_to_use, "A", "address")) {
    $query->debuglog("  mechanism a: $a");
    if ($a eq $query->{ipv4}) {
      $query->debuglog("  mechanism a: match found: $domain_to_use A $a == $query->{ipv4}");
      return "hit", "$domain_to_use A $query->{ipv4}";
    }
    elsif ($ip4_cidr_length < 32) {
      my $cidr = Net::CIDR::Lite->new("$a/$ip4_cidr_length");

      $query->debuglog("  mechanism a: looking for $query->{ipv4} in $a/$ip4_cidr_length");
      
      return (hit => "$domain_to_use A $a /$ip4_cidr_length contains $query->{ipv4}")
        if $cidr->find($query->{ipv4});
    }
  }
  return;
}

# ----------------------------------------------------------
#                            mx
# ----------------------------------------------------------

sub mech_mx {
  my $query = shift;
  my $argument = shift;

  my $ip4_cidr_length = ($argument =~ s/  \/(\d+)//x) ? $1 : 32;
  my $ip6_cidr_length = ($argument =~ s/\/\/(\d+)//x) ? $1 : 128;

  my $domain_to_use = $argument || $query->{domain};

  if ($domain_to_use !~ / \. [a-z] (?: [a-z0-9-]* [a-z0-9] ) $ /ix) {
    return ("unknown" => "bad argument to mx: $domain_to_use not a valid FQDN");
  }

  my @mxes = $query->myquery($domain_to_use, "MX", "exchange", "preference");

  foreach my $mx (@mxes) {
    # $query->debuglog("  mechanism mx: $mx");

    foreach my $a ($query->myquery($mx, "A", "address")) {
      if ($a eq $query->{ipv4}) {
        $query->debuglog("  mechanism mx: we have a match; $domain_to_use MX $mx A $a == $query->{ipv4}");
        return "hit", "$domain_to_use MX $mx A $a";
      }
      elsif ($ip4_cidr_length < 32) {
        my $cidr = Net::CIDR::Lite->new("$a/$ip4_cidr_length");

        $query->debuglog("  mechanism mx: looking for $query->{ipv4} in $a/$ip4_cidr_length");

        return (hit => "$domain_to_use MX $mx A $a /$ip4_cidr_length contains $query->{ipv4}")
          if $cidr->find($query->{ipv4});

      }
    }
  }
  return;
}

# ----------------------------------------------------------
#                           ptr
# ----------------------------------------------------------

sub mech_ptr {
  my $query = shift;
  my $argument = shift;

  if ($query->{ipv6}) { return "neutral", "ipv6 not yet supported"; }

  my $domain_to_use = $argument || $query->{domain};

  foreach my $ptrdname ($query->myquery(reverse_in_addr($query->{ipv4}) . ".in-addr.arpa", "PTR", "ptrdname")) {
    $query->debuglog("  mechanism ptr: $query->{ipv4} is $ptrdname");
    
    $query->debuglog("  mechanism ptr: checking hostname $ptrdname for legitimacy.");
    
    # check for legitimacy --- PTR -> hostname A -> PTR
    foreach my $ptr_to_a ($query->myquery($ptrdname, "A", "address")) {
      
      $query->debuglog("  mechanism ptr: hostname $ptrdname -> $ptr_to_a");
      
      if ($ptr_to_a eq $query->{ipv4}) {
        $query->debuglog("  mechanism ptr: we have a valid PTR: $query->{ipv4} PTR $ptrdname A $ptr_to_a");
        $query->debuglog("  mechanism ptr: now we see if $ptrdname ends in $domain_to_use.");
        
        if ($ptrdname =~ /(^|\.)\Q$domain_to_use\E$/i) {
          $query->debuglog("  mechanism ptr: $query->{ipv4} PTR $ptrdname does end in $domain_to_use.");
          return hit => "$query->{ipv4} PTR $ptrdname matches $domain_to_use";
        }
        else {
          $query->debuglog("  mechanism ptr: $ptrdname does not end in $domain_to_use.  no match.");
        }
      }
    }
  }
  return;
}

# ----------------------------------------------------------
#                            exists
# ----------------------------------------------------------

sub mech_exists {
  my $query = shift;
  my $argument = shift;

  return if (!$argument);

  my $domain_to_use = $argument;

  $query->debuglog("  mechanism exists: looking up $domain_to_use");
  
  foreach ($query->myquery($domain_to_use, "A", "address")) {
    $query->debuglog("  mechanism exists: $_");
    $query->debuglog("  mechanism exists: we have a match.");
    my @txt = map { s/^"//; s/"$//; $_ } $query->myquery($domain_to_use, "TXT", "char_str_list");
    if (@txt) {
        return hit => join(" ", @txt);
    }
    return hit => "$domain_to_use found";
  }
  return;
}

# ----------------------------------------------------------
#                           ip4
# ----------------------------------------------------------

sub mech_ip4 {
  my $query = shift;
  my $cidr_spec = shift;

  if ($cidr_spec eq '') {
    return ("unknown" => "no argument given to ip4");
  }

  my ($network, $cidr_length) = split (/\//, $cidr_spec, 2);

  if (
    $network !~ /^\d+\.\d+\.\d+\.\d+$/ ||
    (defined($cidr_length) && $cidr_length !~ /^\d+$/)
  ) { return ("unknown" => "bad argument to ip4: $cidr_spec"); }
  
  $cidr_length = "32" if not defined $cidr_length;

  local $@;
  my $cidr = eval { Net::CIDR::Lite->new("$network/$cidr_length") };
  if ($@) { return ("unknown" => "unable to parse ip4:$cidr_spec"); }

  $query->debuglog("  mechanism ip4: looking for $query->{ipv4} in $cidr_spec");

  return (hit => "$cidr_spec contains $query->{ipv4}") if $cidr->find($query->{ipv4});

  return;
}

# ----------------------------------------------------------
#                           ip6
# ----------------------------------------------------------

sub mech_ip6 {
  my $query = shift;

  return;
}

# ----------------------------------------------------------
#                        functions
# ----------------------------------------------------------

sub ip { # accessor
  my $query = shift;
  return $query->{ipv4} || $query->{ipv6};
}

sub reverse_in_addr {
  return join (".", (reverse split /\./, shift));
}

sub resolver {
  my $query = shift;
  return $query->{res} ||= Net::DNS::Resolver->new(
                                                   tcp_timeout => $DNS_RESOLVER_TIMEOUT,
                                                   udp_timeout => $DNS_RESOLVER_TIMEOUT,
                                                  );
}

sub fallbacks {
  my $query = shift;
  return @{$query->{fallbacks}};
}

sub shorthand2value {
  my $query = shift;
  my $shorthand = shift;
  return { "-" => "fail",
           "+" => "pass",
           "~" => "softfail",
           "?" => "neutral" } -> {$shorthand} || $shorthand;
}

sub value2shorthand {
  my $query = shift;
  my $value = lc shift;
  return { "fail"     => "-",
           "pass"     => "+",
           "softfail" => "~",
           "deny"     => "-",
           "allow"    => "+",
           "softdeny" => "~",
           "unknown"  => "?",
           "neutral"  => "?" } -> {$value} || $value;
}

sub interpolate_explanation {
  my $query = shift;
  my $txt = shift;

  if ($query->{directive_set}->explanation) {
    my @txt = map { s/^"//; s/"$//; $_ } $query->myquery($query->macro_substitute($query->{directive_set}->explanation), "TXT", "char_str_list");
    $txt = join " ", @txt;
  }

  return $query->macro_substitute($txt);
}

sub find_ancestor {
  my $query = shift;
  my $which_hash = shift;
  my $current_domain = shift;

  return if not exists $query->{$which_hash};

  $current_domain =~ s/\.$//g;
  my @current_domain = split /\./, $current_domain;

  foreach my $ancestor_level (0 .. @current_domain) {
    my @ancestor = @current_domain;
    for (1 .. $ancestor_level) { shift @ancestor }
    my $ancestor = join ".", @ancestor;

    for my $match ($ancestor_level > 0 ? "*.$ancestor" : $ancestor) {
      $query->debuglog("  DirectiveSet $which_hash: is $match in the $which_hash hash?");
      if (my $record = $query->{$which_hash}->{lc $match}) {
        $query->debuglog("  DirectiveSet $which_hash: yes, it is.");
        return wantarray ? ($which_hash, $match, $record) : $record;
      }
    }
  }
  return;
}

sub found_record_for {
  my $query = shift;
  my ($which_hash, $matched_domain_glob, $record) = $query->find_ancestor(@_);
  return if not $record;
  $query->{spf_source} = "explicit $which_hash found: $matched_domain_glob defines $record";
  $query->{spf_source_type} = "full-explanation";
  $record = "v=spf1 $record" if $record !~ /^v=spf1\b/i;
  return $record;
}

sub try_override {
  my $query = shift;
  return $query->found_record_for("override", @_);
}

sub try_fallback {
  my $query = shift;
  return $query->found_record_for("fallback", @_);
}

# ----------------------------------------------------------
#                     algo
# ----------------------------------------------------------

{
  package DirectiveSet;

  sub new {
    my $class = shift;
    my $current_domain = shift;
    my $query = shift;
    my $override_text = shift;
    my $localpolicy = shift;
    my $default_record = shift;

    my $txt;

    # Overrides can come from two places:
    # - When operating in best_guess mode, spfquery may be called with a $guess_mechs argument, which comes in as $override_text.
    # - When operating with ->new(..., override => { ... }) we need to load the override dynamically.
    if ($override_text) {
      $txt = "v=spf1 $override_text ?all";
      $query->{spf_source} = "local policy";
      $query->{spf_source_type} = "full-explanation";
    }
    elsif (exists $query->{override}) {
      $txt = $query->try_override($current_domain);
    }

    # Retrieve a record from DNS:
    if (!defined $txt) {
      my @txt;
      $query->debuglog("  DirectiveSet->new(): doing TXT query on $current_domain");
      @txt = $query->myquery($current_domain, "TXT", "char_str_list");
      $query->debuglog("  DirectiveSet->new(): TXT query on $current_domain returned error=$query->{error}, last_dns_error=$query->{last_dns_error}");

      # Combine multiple TXT strings into a single string:
      foreach (@txt) {
        $txt .= $1 if /^v=spf1\s*(.*)$/;
      }

      $txt = undef
        if $query->{error} or $query->{last_dns_error} eq 'NXDOMAIN';
    }

    # Try the fallbacks:
    if (!defined $txt and exists $query->{fallback}) {
      $query->debuglog("  DirectiveSet->new(): will try fallbacks.");
      $txt = $query->try_fallback($current_domain, "fallback");
      defined($txt)
        or $query->debuglog("  DirectiveSet->new(): fallback search failed.");
    }

    if (!defined $txt and defined $default_record) {
      $txt = "v=spf1 $default_record ?all";
      $query->{spf_source} = "local policy";
      $query->{spf_source_type} = "full-explanation";
    }

    $query->debuglog("  DirectiveSet->new(): SPF policy: $txt");

    return if not defined $txt;

    # TODO: the prepending of the v=spf1 is a massive hack; get it right by saving the actual raw orig_txt.
    my $directive_set = bless { orig_txt => ($txt =~ /^v=spf1/ ? $txt : "v=spf1 $txt"), txt => $txt } , $class;

    TXT_RESPONSE:
    for ($txt) {
      $query->debuglog("  lookup:   TXT $_");

      # parse the policy record
      
      while (/\S/) {
        s/^\s*(\S+)\s*//;
        my $word = $1;
        # $query->debuglog("  lookup:  word parsing word $word");
        if ($word =~ /^v=(\S+)/i) {
          my $version = $1;
          $query->debuglog("  lookup:   TXT version=$version");
          $directive_set->{version} = $version;
          next TXT_RESPONSE if ($version ne "spf1");
          next;
        }

        # modifiers always have an = sign.
        if (my ($lhs, $rhs) = $word =~ /^([^:\/]+)=(\S*)$/) {
          # $query->debuglog("  lookup:   TXT modifier found: $lhs = $rhs");

          # if we ever come to support multiple of the same modifier, we need to make this a list.
          $directive_set->{modifiers}->{lc $lhs} = $rhs;
          next;
        }

        # RHS optional, defaults to domain.
        # [:/] matches a:foo and a/24
        if (my ($prefix, $lhs, $rhs) = $word =~ /^([-~+?]?)([\w_-]+)([\/:]\S*)?$/i) {
          $rhs =~ s/^://;
          $prefix ||= "+";
          $query->debuglog("  lookup:   TXT prefix=$prefix, lhs=$lhs, rhs=$rhs");
          push @{$directive_set->{mechanisms}}, [$prefix => lc $lhs => $rhs];
          next;
        }

      }
    }

    if (my $rhs = delete $directive_set->{modifiers}->{default}) {
      push @{$directive_set->{mechanisms}}, [ $query->value2shorthand($rhs), all => undef ];
    }

    $directive_set->{mechanisms} = []           if not $directive_set->{mechanisms};
    if ($localpolicy) {
        my $mechanisms = $directive_set->{mechanisms};
        my $lastmech = $mechanisms->[$#$mechanisms];
        if (($lastmech->[0] eq '-' || $lastmech->[0] eq '?') &&
             $lastmech->[1] eq 'all') {
            my $index;

            for ($index = $#$mechanisms - 1; $index >= 0; $index--) {
                last if ($lastmech->[0] ne $mechanisms->[$index]->[0]);
            }
            if ($index >= 0) {
                # We want to insert the localpolicy just *after* $index
                $query->debuglog("  inserting local policy mechanisms into @{[$directive_set->show_mechanisms]} after position $index");
                my $localset = DirectiveSet->new($current_domain, $query->clone, $localpolicy);

                if ($localset) {
                    my @locallist = $localset->mechanisms;
                    # Get rid of the ?all at the end of the list
                    pop @locallist;
                    # $_->[3] goes into $query->{spf_source}.
                    map { $_->[3] = ($_->[1] eq 'include'
                                     ? "local policy includes SPF record at " . $query->macro_substitute($_->[2])
                                     : "local policy") }
                      @locallist;
                    splice(@$mechanisms, $index + 1, 0, @locallist);
                }
            }
        }
    }
    $query->debuglog("  lookup:  mec mechanisms=@{[$directive_set->show_mechanisms]}");
    return $directive_set;
  }

  sub version      {   shift->{version}      }
  sub mechanisms   { @{shift->{mechanisms}}  }
  sub explanation  {   shift->{modifiers}->{exp}      }
  sub redirect     {   shift->{modifiers}->{redirect} }
  sub get_modifier {   shift->{modifiers}->{shift()}  }
  sub syntax_error {   shift->{syntax_error} }

  sub show_mechanisms   {
    my $directive_set = shift;
    my @toreturn = map { $_->[0] . $_->[1] . "(" . ($_->[2]||"") . ")" } $directive_set->mechanisms;
    # print STDERR ("showing mechanisms @toreturn: " . Dumper($directive_set)); use Data::Dumper;
    return @toreturn;
  }
}

1;

=head1 WARNINGS

Mail::Query::SPF should only be used at the point where messages are received
from the Internet.  The underlying assumption is that the sender of the e-mail
is sending the message directly to you or one of your secondary MXes.  If your
MTA does not have an exhaustive list of secondary MXes, then the C<result2()>
and C<message_result2()> methods can be used.  These methods take care to
permit mail from secondary MXes.

=head1 AUTHORS

Meng Weng Wong <mengwong+spf@pobox.com>, Philip Gladstone, Julian Mehnle
<julian@mehnle.net>

=head1 SEE ALSO

About SPF: L<http://www.openspf.org>

Mail::SPF::Query: L<http://search.cpan.org/dist/Mail-SPF-Query>

The latest release of the SPF specification: L<http://www.openspf.org/spf-classic-current.txt>

=cut

# vim:et sts=4 sw=4
