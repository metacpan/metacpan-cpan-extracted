#
# Mail::SPF::Server
# Server class for processing SPF requests.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Server.pm 61 2013-07-22 03:45:15Z julian $
#
##############################################################################

package Mail::SPF::Server;

=head1 NAME

Mail::SPF::Server - Server class for processing SPF requests

=cut

use warnings;
use strict;

use base 'Mail::SPF::Base';

use Error ':try';
use Net::DNS::Resolver;

use Mail::SPF::MacroString;
use Mail::SPF::Record;
use Mail::SPF::Result;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant record_classes_by_version => {
    1   => 'Mail::SPF::v1::Record',
    2   => 'Mail::SPF::v2::Record'
};

use constant result_base_class => 'Mail::SPF::Result';

use constant query_rr_type_all                      => 0;
use constant query_rr_type_txt                      => 1;
use constant query_rr_type_spf                      => 2;

use constant default_default_authority_explanation  =>
    'Please see http://www.openspf.org/Why?s=%{_scope};id=%{S};ip=%{C};r=%{R}';

sub default_query_rr_types { shift->query_rr_type_txt };

use constant default_max_dns_interactive_terms      => 10;  # RFC 4408, 10.1/6
use constant default_max_name_lookups_per_term      => 10;  # RFC 4408, 10.1/7
sub default_max_name_lookups_per_mx_mech  { shift->max_name_lookups_per_term };
sub default_max_name_lookups_per_ptr_mech { shift->max_name_lookups_per_term };

use constant default_max_void_dns_lookups           => 2;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Mail::SPF;

    my $spf_server  = Mail::SPF::Server->new(
        # Optional custom default for authority explanation:
        default_authority_explanation =>
            'See http://www.%{d}/why/id=%{S};ip=%{I};r=%{R}'
    );

    my $result      = $spf_server->process($request);

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

B<Mail::SPF::Server> is a server class for processing SPF requests.  Each
server instance can be configured with specific processing parameters.  Also,
the default I<Net::DNS::Resolver> DNS resolver used for making DNS look-ups can
be overridden with a custom resolver object.

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Server>

Creates a new server object for processing SPF requests.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<default_authority_explanation>

A I<string> denoting the default (not macro-expanded) authority explanation
string to use if the authority domain does not specify an explanation string of
its own.  Defaults to:

    'Please see http://www.openspf.org/Why?s=%{_scope};id=%{S};ip=%{C};r=%{R}'

As can be seen from the default, a non-standard C<_scope> pseudo macro is
supported that expands to the name of the identity's scope.  (Note: Do I<not>
use any non-standard macros in explanation strings published in DNS.)

=item B<hostname>

A I<string> denoting the local system's fully qualified host name that should
be used for expanding the C<r> macro in explanation strings.  Defaults to the
system's configured host name.

=item B<dns_resolver>

An optional DNS resolver object.  If none is specified, a new I<Net::DNS::Resolver>
object is used.  The resolver object may be of a different class, but it must
provide an interface similar to I<Net::DNS::Resolver> -- at least the C<send>
and C<errorstring> methods must be supported, and the C<send> method must
return either an object of class I<Net::DNS::Packet>, or, in the case of an
error, B<undef>.

=item B<query_rr_types>

For which RR types to query when looking up and selecting SPF records.  The
following values are supported:

=over

=item B<< Mail::SPF::Server->query_rr_type_all >>

Both C<TXT> and C<SPF> type RRs.

=item B<< Mail::SPF::Server->query_rr_type_txt >> (default)

C<TXT> type RRs only.

=item B<< Mail::SPF::Server->query_rr_type_spf >>

C<SPF> type RRs only.

=back

For years B<Mail::SPF> has defaulted to looking up both C<SPF> and C<TXT> type
RRs as recommended by RFC 4408.  Experience has shown, however, that a
significant portion of name servers suffer from serious brain damage with
regard to the handling of queries for RR types that are unknown to them, such
as the C<SPF> RR type.  Consequently B<Mail::SPF> now defaults to looking up
only C<TXT> type RRs.  This may be overridden by setting the B<query_rr_types>
option.

See RFC 4408, 3.1.1, for a discussion of the topic, as well as the description
of the L</select_record> method.

=item B<max_dns_interactive_terms>

An I<integer> denoting the maximum number of terms (mechanisms and modifiers)
per SPF check that perform DNS look-ups, as defined in RFC 4408, 10.1,
paragraph 6.  If B<undef> is specified, there is no limit on the number of such
terms.  Defaults to B<10>, which is the value defined in RFC 4408.

A value above the default is I<strongly discouraged> for security reasons.  A
value below the default has implications with regard to the predictability of
SPF results.  Only deviate from the default if you know what you are doing!

=item B<max_name_lookups_per_term>

An I<integer> denoting the maximum number of DNS name look-ups per term
(mechanism or modifier), as defined in RFC 4408, 10.1, paragraph 7.  If
B<undef> is specified, there is no limit on the number of look-ups performed.
Defaults to B<10>, which is the value defined in RFC 4408.

A value above the default is I<strongly discouraged> for security reasons.  A
value below the default has implications with regard to the predictability of
SPF results.  Only deviate from the default if you know what you are doing!

=item B<max_name_lookups_per_mx_mech>

=item B<max_name_lookups_per_ptr_mech>

An I<integer> denoting the maximum number of DNS name look-ups per B<mx> or B<ptr>
mechanism, respectively.  Defaults to the value of the C<max_name_lookups_per_term>
option.  See there for additional information and security notes.

=item B<max_void_dns_lookups>

An I<integer> denoting the maximum number of "void" DNS look-ups per SPF check,
i.e. the number of DNS look-ups that were caused by DNS-interactive terms and
macros (as defined in RFC 4408, 10.1, paragraphs 6 and 7) and that are allowed
to return an empty answer with RCODE 0 or RCODE 3 (C<NXDOMAIN>) before
processing is aborted with a C<permerror> result.  If B<undef> is specified,
there is no stricter limit on the number of void DNS look-ups beyond the usual
processing limits.  Defaults to B<2>.

Specifically, the DNS look-ups that are subject to this limit are those caused
by the C<a>, C<mx>, C<ptr>, and C<exists> mechanisms and the C<p> macro.

A value of B<2> is likely to prevent effective DoS attacks against third-party
victim domains.  However, a definite limit may cause C<permerror> results even
with certain (overly complex) innocent sender policies where useful results
would normally be returned.

=back

=cut

sub new {
    my ($self, %options) = @_;
    $self = $self->SUPER::new(%options);

    $self->{default_authority_explanation} = $self->default_default_authority_explanation
        if not defined($self->{default_authority_explanation});
    $self->{default_authority_explanation} = Mail::SPF::MacroString->new(
        text            => $self->{default_authority_explanation},
        server          => $self,
        is_explanation  => TRUE
    )
        if not UNIVERSAL::isa($self->{default_authority_explanation}, 'Mail::SPF::MacroString');

    $self->{hostname} ||= Mail::SPF::Util->hostname;

    $self->{dns_resolver} ||= Net::DNS::Resolver->new();

    $self->{query_rr_types} = $self->default_query_rr_types
        if not defined($self->{query_rr_types});

    $self->{max_dns_interactive_terms}      = $self->default_max_dns_interactive_terms
                                       if not exists($self->{max_dns_interactive_terms});
    $self->{max_name_lookups_per_term}      = $self->default_max_name_lookups_per_term
                                       if not exists($self->{max_name_lookups_per_term});
    $self->{max_name_lookups_per_mx_mech}   = $self->default_max_name_lookups_per_mx_mech
                                       if not exists($self->{max_name_lookups_per_mx_mech});
    $self->{max_name_lookups_per_ptr_mech}  = $self->default_max_name_lookups_per_ptr_mech
                                       if not exists($self->{max_name_lookups_per_ptr_mech});

    $self->{max_void_dns_lookups}           = $self->default_max_void_dns_lookups
                                       if not exists($self->{max_void_dns_lookups});

    return $self;
}

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<result_class>: returns I<class>

=item B<result_class($name)>: returns I<class>

Returns a I<Mail::SPF::Result> descendent class determined from the given
result name via the server's inherent result base class, or returns the
server's inherent result base class if no result name is given.  This method
may also be used as an instance method.

I<Note>:  Do not write code invoking class methods on I<literal> result class
names as this would ignore any derivative result classes provided by
B<Mail::SPF> extension modules.

=cut

sub result_class {
    my ($self, $name) = @_;
    return
        defined($name) ?
            $self->result_base_class->result_classes->{$name}
        :   $self->result_base_class;
}

=item B<throw_result($name, $request)>: throws I<Mail::SPF::Result>

=item B<throw_result($name, $request, $text)>: throws I<Mail::SPF::Result>

Throws a I<Mail::SPF::Result> descendant determined from the given result name
via the server's inherent result base class, passing an optional result text
and associating the given I<Mail::SPF::Request> object with the result object.
This method may also be used as an instance method.

I<Note>:  Do not write code invoking C<throw> on I<literal> result class names
as this would ignore any derivative result classes provided by B<Mail::SPF>
extension modules.

=cut

sub throw_result {
    my ($self, $name, $request, @text) = @_;
    $self->result_class($name)->throw($self, $request, @text);
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<process($request)>: returns I<Mail::SPF::Result>

Processes the given I<Mail::SPF::Request> object, queries the authoritative
domain for an SPF sender policy (see the description of the L</select_record>
method), evaluates the policy with regard to the given identity and other
request parameters, and returns a I<Mail::SPF::Result> object denoting the
result of the policy evaluation.  See RFC 4408, 4, and RFC 4406, 4, for
details.

=cut

sub process {
    my ($self, $request) = @_;

    $request->state('authority_explanation', undef);
    $request->state('dns_interactive_terms_count', 0);
    $request->state('void_dns_lookups_count', 0);

    my $result;
    try {
        my $record = $self->select_record($request);
        $request->record($record);
        $record->eval($self, $request);
    }
    catch Mail::SPF::Result with {
        $result = shift;
    }
    catch Mail::SPF::EDNSError with {
        $result = $self->result_class('temperror')->new($self, $request, shift->text);
    }
    catch Mail::SPF::ENoAcceptableRecord with {
        $result = $self->result_class('none'     )->new($self, $request, shift->text);
    }
    catch Mail::SPF::ERedundantAcceptableRecords with {
        $result = $self->result_class('permerror')->new($self, $request, shift->text);
    }
    catch Mail::SPF::ESyntaxError with {
        $result = $self->result_class('permerror')->new($self, $request, shift->text);
    }
    catch Mail::SPF::EProcessingLimitExceeded with {
        $result = $self->result_class('permerror')->new($self, $request, shift->text);
    };
    # Propagate other, unknown errors.
    # This should not happen, but if it does, it helps exposing the bug!

    return $result;
}

=item B<select_record($request)>: returns I<Mail::SPF::Record>;
throws I<Mail::SPF::EDNSError>,
I<Mail::SPF::ENoAcceptableRecord>, I<Mail::SPF::ERedundantAcceptableRecords>,
I<Mail::SPF::ESyntaxError>

Queries the authority domain of the given I<Mail::SPF::Request> object for SPF
sender policy records and, if multiple records are available, selects the
record of the highest acceptable record version that covers the requested
scope.

More precisely, the following algorithm is performed (assuming that both C<TXT>
and C<SPF> RR types are being queried):

=over

=item 1.

Determine the authority domain, the set of acceptable SPF record versions, and
the identity scope from the given request object.

=item 2.

Query the authority domain for SPF records of the C<SPF> DNS RR type,
discarding any records that are of an inacceptable version or do not cover the
desired scope.

If this yields no SPF records, query the authority domain for SPF records of
the C<TXT> DNS RR type, discarding any records that are of an inacceptable
version or do not cover the desired scope.

If still no acceptable SPF records could be found, throw a
I<Mail::SPF::ENoAcceptableRecord> exception.

=item 3.

Discard all records but those of the highest acceptable version found.

If exactly one record remains, return it.  Otherwise, throw a
I<Mail::SPF::ERedundantAcceptableRecords> exception.

=back

If the querying of either RR type has been disabled via the L</new>
constructor's C<query_rr_types> option, the respective part in step 2 will
be skipped.

I<Mail::SPF::EDNSError> exceptions due to DNS look-ups and
I<Mail::SPF::ESyntaxError> exceptions due to invalid acceptable records may
also be thrown.

=cut

sub select_record {
    my ($self, $request) = @_;

    my $domain   = $request->authority_domain;
    my @versions = $request->versions;
    my $scope    = $request->scope;

    # Employ identical behavior for 'v=spf1' and 'spf2.0' records, both of
    # which support SPF (code 99) and TXT type records (this may be different
    # in future revisions of SPF):
    # Query for SPF type records first, then fall back to TXT type records.

    my @records;
    my $query_count = 0;
    my @dns_errors;

    # Query for SPF-type RRs first:
    if (
        $self->query_rr_types == $self->query_rr_type_all or
        $self->query_rr_types &  $self->query_rr_type_spf
    ) {
        try {
            $query_count++;
            my $packet = $self->dns_lookup($domain, 'SPF');
            push(
                @records,
                $self->get_acceptable_records_from_packet(
                    $packet, 'SPF', \@versions, $scope, $domain)
            );
        }
        catch Mail::SPF::EDNSError with {
            push(@dns_errors, shift);
        };
        #catch Mail::SPF::EDNSTimeout with {
        #    # FIXME Ignore DNS time-outs on SPF type lookups?
        #    # Apparrently some brain-dead DNS servers time out on SPF-type queries.
        #};
    }

    # If no usable SPF-type RRs, try TXT-type RRs:
    if (
        not @records and
        (
            $self->query_rr_types == $self->query_rr_type_all or
            $self->query_rr_types &  $self->query_rr_type_txt
        )
    ) {
        # NOTE:
        #   This deliberately violates RFC 4406 (Sender ID), 4.4/3 (4.4.1):
        #   TXT-type RRs are still tried if there _are_ SPF-type RRs but all of
        #   them are inapplicable (i.e. "Hi!", or even "spf2.0/pra" for an
        #   'mfrom' scope request).  This conforms to the spirit of the more
        #   sensible algorithm in RFC 4408 (SPF), 4.5.
        #   Implication:  Sender ID processing may make use of existing TXT-
        #   type records where a result of "None" would normally be returned
        #   under a strict interpretation of RFC 4406.

        try {
            $query_count++;
            my $packet = $self->dns_lookup($domain, 'TXT');
            push(
                @records,
                $self->get_acceptable_records_from_packet(
                    $packet, 'TXT', \@versions, $scope, $domain)
            );
        }
        catch Mail::SPF::EDNSError with {
            push(@dns_errors, shift);
        };
    }

    @dns_errors < $query_count
        or $dns_errors[0]->throw;
        # Unless at least one query succeeded, re-throw the first DNS error that occurred.

    @records
        or throw Mail::SPF::ENoAcceptableRecord(
            "No applicable sender policy available");  # RFC 4408, 4.5/7

    # Discard all records but the highest acceptable version:
    my $preferred_record_class = $records[0]->class;
    @records = grep($_->isa($preferred_record_class), @records);

    @records == 1
        or throw Mail::SPF::ERedundantAcceptableRecords(
            "Redundant applicable '" . $preferred_record_class->version_tag . "' " .
            "sender policies found");  # RFC 4408, 4.5/6

    return $records[0];
}

=item B<get_acceptable_records_from_packet($packet, $rr_type, \@versions, $scope, $domain)>:
returns I<list> of I<Mail::SPF::Record>

Filters from the given I<Net::DNS::Packet> object all resource records of the
given RR type and for the given domain name, discarding any records that are
not SPF records at all, that are of an inacceptable SPF record version, or that
do not cover the given scope.  Returns a list of acceptable records.

=cut

sub get_acceptable_records_from_packet {
    my ($self, $packet, $rr_type, $versions, $scope, $domain) = @_;

    my @versions = sort { $b <=> $a } @$versions;
        # Try higher record versions first.
        # (This may be too simplistic for future revisions of SPF.)

    my @records;
    foreach my $rr ($packet->answer) {
        next if $rr->type ne $rr_type;  # Ignore RRs of unexpected type.

        my $text = join('', $rr->char_str_list);
        my $record;

        # Try to parse RR as each of the requested record versions,
        # starting from the highest version:
        VERSION:
        foreach my $version (@versions) {
            my $class = $self->record_classes_by_version->{$version};
            eval("require $class");
            try {
                $record = $class->new_from_string($text);
            }
            catch Mail::SPF::EInvalidRecordVersion with {};
                # Ignore non-SPF and unknown-version records.
                # Propagate other errors (including syntax errors), though.
            last VERSION if defined($record);
        }

        push(@records, $record)
            if  defined($record)
            and grep($scope eq $_, $record->scopes);  # record covers requested scope?
    }
    return @records;
}

=item B<dns_lookup($domain, $rr_type)>: returns I<Net::DNS::Packet>;
throws I<Mail::SPF::EDNSTimeout>, I<Mail::SPF::EDNSError>

Queries the DNS using the configured resolver for resource records of the
desired type at the specified domain and returns a I<Net::DNS::Packet> object
if an answer packet was received.  Throws a I<Mail::SPF::EDNSTimeout> exception
if a DNS time-out occurred.  Throws a I<Mail::SPF::EDNSError> exception if an
error (other than RCODE 3 AKA C<NXDOMAIN>) occurred.

=cut

sub dns_lookup {
    my ($self, $domain, $rr_type) = @_;

    if (UNIVERSAL::isa($domain, 'Mail::SPF::MacroString')) {
        $domain = $domain->expand;
        # Truncate overlong labels at 63 bytes (RFC 4408, 8.1/27):
        $domain =~ s/([^.]{63})[^.]+/$1/g;
        # Drop labels from the head of domain if longer than 253 bytes (RFC 4408, 8.1/25):
        $domain =~ s/^[^.]+\.(.*)$/$1/
            while length($domain) > 253;
    }

    $domain =~ s/^(.*?)\.?$/\L$1/;  # Normalize domain.

    my $packet = $self->dns_resolver->send($domain, $rr_type);

    # Throw DNS exception unless an answer packet with RCODE 0 or 3 (NXDOMAIN)
    # was received (thereby treating NXDOMAIN as an acceptable but empty answer packet):
    $self->dns_resolver->errorstring !~ /^(timeout|query timed out)$/
        or throw Mail::SPF::EDNSTimeout(
            "Time-out on DNS '$rr_type' lookup of '$domain'");
    defined($packet)
        or throw Mail::SPF::EDNSError(
            "Unknown error on DNS '$rr_type' lookup of '$domain'");
    $packet->header->rcode =~ /^(NOERROR|NXDOMAIN)$/
        or throw Mail::SPF::EDNSError(
            "'" . $packet->header->rcode . "' error on DNS '$rr_type' lookup of '$domain'");

    return $packet;
}

=item B<count_dns_interactive_term($request)>: throws I<Mail::SPF::EProcessingLimitExceeded>

Increments by one the count of DNS-interactive mechanisms and modifiers that
have been processed so far during the evaluation of the given
I<Mail::SPF::Request> object.  If this exceeds the configured limit (see the
L</new> constructor's C<max_dns_interactive_terms> option), throws a
I<Mail::SPF::EProcessingLimitExceeded> exception.

This method is supposed to be called by the C<match> and C<process> methods of
I<Mail::SPF::Mech> and I<Mail::SPF::Mod> sub-classes before (and only if) they
do any DNS look-ups.

=cut

sub count_dns_interactive_term {
    my ($self, $request) = @_;
    my $dns_interactive_terms_count = ++$request->root_request->state('dns_interactive_terms_count');
    my $max_dns_interactive_terms = $self->max_dns_interactive_terms;
    if (
        defined($max_dns_interactive_terms) and
        $dns_interactive_terms_count > $max_dns_interactive_terms
    ) {
        throw Mail::SPF::EProcessingLimitExceeded(
            "Maximum DNS-interactive terms limit ($max_dns_interactive_terms) exceeded");
    }
    return;
}

=item B<count_void_dns_lookup($request)>: throws I<Mail::SPF::EProcessingLimitExceeded>

Increments by one the count of "void" DNS look-ups that have occurred so far
during the evaluation of the given I<Mail::SPF::Request> object.  If this
exceeds the configured limit (see the L</new> constructor's C<max_void_dns_lookups>
option), throws a I<Mail::SPF::EProcessingLimitExceeded> exception.

This method is supposed to be called by any code after any calls to the
L</dns_lookup> method whenever (i) no answer records were returned, and (ii)
this fact is a possible indication of a DoS attack against a third-party victim
domain, and (iii) the number of "void" look-ups is not already constrained
otherwise (as for example is the case with the C<include> mechanism and the
C<redirect> modifier).  Specifically, this applies to look-ups performed by the
C<a>, C<mx>, C<ptr>, and C<exists> mechanisms and the C<p> macro.

=cut

sub count_void_dns_lookup {
    my ($self, $request) = @_;
    my $void_dns_lookups_count = ++$request->root_request->state('void_dns_lookups_count');
    my $max_void_dns_lookups = $self->max_void_dns_lookups;
    if (
        defined($max_void_dns_lookups) and
        $void_dns_lookups_count > $max_void_dns_lookups
    ) {
        throw Mail::SPF::EProcessingLimitExceeded(
            "Maximum void DNS look-ups limit ($max_void_dns_lookups) exceeded");
    }
    return;
}

=item B<default_authority_explanation>: returns I<Mail::SPF::MacroString>

Returns the default authority explanation as a I<MacroString> object.  See the
description of the L</new> constructor's C<default_authority_explanation>
option.

=item B<hostname>: returns I<string>

Returns the local system's host name.  See the description of the L</new>
constructor's C<hostname> option.

=item B<dns_resolver>: returns I<Net::DNS::Resolver> or compatible object

Returns the DNS resolver object of the server object.  See the description of
the L</new> constructor's C<dns_resolver> option.

=item B<query_rr_types>: returns I<integer>

Returns a value denoting the RR types for which to query when looking up and
selecting SPF records.  See the description of the L</new> constructor's
C<query_rr_types> option.

=item B<max_dns_interactive_terms>: returns I<integer>

=item B<max_name_lookups_per_term>: returns I<integer>

=item B<max_name_lookups_per_mx_mech>: returns I<integer>

=item B<max_name_lookups_per_ptr_mech>: returns I<integer>

=item B<max_void_dns_lookups>: returns I<integer>

Return the limit values of the server object.  See the description of the
L</new> constructor's corresponding options.

=cut

# Make read-only accessors:
__PACKAGE__->make_accessor($_, TRUE)
    foreach qw(
        default_authority_explanation
        hostname

        dns_resolver
        query_rr_types

        max_dns_interactive_terms
        max_name_lookups_per_term
        max_name_lookups_per_mx_mech
        max_name_lookups_per_ptr_mech

        max_void_dns_lookups
    );

=back

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Request>, L<Mail::SPF::Result>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
