# Copyright (c) 1999-2003 by Ilya Martynov. All rights
# reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package Mail::CheckUser;

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(check_email
                last_check
                check_hostname
                check_username);
$EXPORT_TAGS{constants} = [qw(CU_OK
                              CU_BAD_SYNTAX
                              CU_UNKNOWN_DOMAIN
                              CU_DNS_TIMEOUT
                              CU_UNKNOWN_USER
                              CU_SMTP_TIMEOUT
                              CU_SMTP_UNREACHABLE
                              CU_MAILBOX_FULL
                              CU_TRY_AGAIN)];
push @EXPORT_OK, @{$EXPORT_TAGS{constants}};

$VERSION = '1.24';

use Carp;
use Net::DNS;
use Net::SMTP;
use IO::Handle;

use vars qw($Skip_Network_Checks $Skip_SMTP_Checks
            $Skip_SYN $Net_DNS_Resolver
            $NXDOMAIN
            $Timeout $Treat_Timeout_As_Fail $Debug
            $Treat_Full_As_Fail
            $Treat_Grey_As_Fail
            $Sender_Addr $Helo_Domain $Last_Check);

# if it is true Mail::CheckUser doesn't make network checks
$Skip_Network_Checks = 0;
# if it is true Mail::CheckUser doesn't try to connect to mail
# server to check if user is valid
$Skip_SMTP_Checks = 0;
# timeout in seconds for network checks
$Timeout = 60;
# if it is true the Net::Ping SYN/ACK check will be skipped
$Skip_SYN = 0;
# if it is true Mail::CheckUser treats timeouted checks as
# failed checks
$Treat_Timeout_As_Fail = 0;
# if it is true Mail::CheckUser treats mailbox full message
# as failed checks
$Treat_Full_As_Fail = 0;
# if it is true Mail::CheckUser treats temporary (400's)
# as failed checks
$Treat_Grey_As_Fail = 0;
# sender addr used in MAIL/RCPT check
$Sender_Addr = 'check@user.com';
# sender domain used in HELO SMTP command - if undef lets
# Net::SMTP use its default value
$Helo_Domain = undef;
# Default Net::DNS::Resolver override object
$Net_DNS_Resolver = undef;
# if true then enable debug mode
$Debug = 0;
# Wildcard gTLD always denote bogus domains
# (http://www.imperialviolet.org/dnsfix.html)
## gTLD Wildcard IPs
$NXDOMAIN = {
  # com/net
  "64.94.110.11"     => 1, # A

  # ac
  "194.205.62.122"   => 1, # A

  # cc
  "206.253.214.102"  => 1, # A
  "snubby.enic.cc"   => 1, # MX
  "206.191.159.103"  => 1, # MX

  # cx
  "219.88.106.80"    => 1, # A
  "mail.nonregistered.nic.cx" => 1, # MX

  # mp
  "202.128.12.163"   => 1, # A

  # museum
  "195.7.77.20"      => 1, # A

  # nu
  "64.55.105.9"      => 1, # A
  "212.181.91.6"     => 1, # A

  # ph
  "203.119.4.6"      => 1, # A
  "45.79.222.138"    => 1, # A

  # pw
  "216.98.141.250"   => 1, # A
  "65.125.231.178"   => 1, # A
  "wfb.dnsvr.com"    => 1, # CNAME

  # sh
  "194.205.62.62"    => 1, # A

  # td
  "146.101.245.154"  => 1, # A
  "www.nic.td"       => 1, # CNAME

  # tk
  "195.20.32.83"     => 1, # A
  "195.20.32.86"     => 1, # A
  "nukumatau.taloha.com" => 1, # MX
  "195.20.32.99"     => 1, # MX

  # tm
  "194.205.62.42"    => 1, # A

  # tw
  "203.73.24.11"     => 1, # A

  # ws
  "216.35.187.246"   => 1, # A
  "mail.worldsite.ws" => 1, # MX
  "mail.hope-mail.com" => 1, # MX
  "216.35.187.251"   => 1, # MX

};

# check_email EMAIL
sub check_email( $ );
# last_check
sub last_check( );
# check_hostname_syntax HOSTNAME
sub check_hostname_syntax( $ );
# check_username_syntax USERNAME
sub check_username_syntax( $ );
# check_network HOSTNAME, USERNAME
sub check_network( $$ );
# check_user_on_host MSERVER, USERNAME, HOSTNAME, TIMEOUT
sub check_user_on_host( $$$$ );
# _calc_timeout FULL_TIMEOUT START_TIME
sub _calc_timeout( $$ );
# _pm_log LOG_STR
sub _pm_log( $ );
# _result RESULT, REASON
sub _result( $$ );

# check result codes
use constant CU_OK               => 0;
use constant CU_BAD_SYNTAX       => 1;
use constant CU_UNKNOWN_DOMAIN   => 2;
use constant CU_DNS_TIMEOUT      => 3;
use constant CU_UNKNOWN_USER     => 4;
use constant CU_SMTP_TIMEOUT     => 5;
use constant CU_SMTP_UNREACHABLE => 6;
use constant CU_MAILBOX_FULL     => 7;
use constant CU_TRY_AGAIN        => 8;

sub check_email($) {
    my($email) = @_;

    unless(defined $email) {
        croak __PACKAGE__ . "::check_email: \$email is undefined";
    }

    _pm_log '=' x 40;
    _pm_log "check_email: checking \"$email\"";

    # split email address on username and hostname
    my($username, $hostname) = $email =~ /^(.*)@(.*)$/;
    # return false if it impossible
    unless(defined $hostname) {
        return _result(CU_BAD_SYNTAX, 'bad address format: missing @');
    }

    my $ok = 1;
    $ok &&= check_hostname_syntax $hostname;
    $ok &&= check_username_syntax $username;
    if($Skip_Network_Checks) {
        _pm_log "check_email: skipping network checks";
    } elsif ($ok) {
        $ok &&= check_network $hostname, $username;
    }

    return $ok;
}

sub last_check() {
    return $Mail::CheckUser::Last_Check;
}

# build hostname regexp
# NOTE: it doesn't strictly follow RFC822
# because of what registrars now allow.
my $DOMAIN_RE   = qr/(?:[\da-zA-Z]+ -+)* [\da-zA-Z]+/x;
my $HOSTNAME_RE = qr/^ (?:$DOMAIN_RE \.)+ [a-zA-Z]+ $/xo;

sub check_hostname_syntax($) {
    my($hostname) = @_;

    _pm_log "check_hostname_syntax: checking \"$hostname\"";

    # check if hostname syntax is correct
    if($hostname =~ $HOSTNAME_RE) {
        return _result(CU_OK, 'correct hostname syntax');
    } else {
        return _result(CU_BAD_SYNTAX, 'bad hostname syntax');
    }
}

# build username regexp
# NOTE: it doesn't strictly follow RFC821
my $STRING_RE = ('[' . quotemeta(join '',
                                 grep(!/[<>()\[\]\\\.,;:\@"]/, # ["], UnBug Emacs
                                      map chr, 33 .. 126)) . ']');
my $USERNAME_RE = qr/^ (?:$STRING_RE+ \.)* $STRING_RE+ $/xo;


sub check_username_syntax($) {
    my($username) = @_;

    _pm_log "check_username_syntax: checking \"$username\"";

    # check if username syntax is correct
    if($username =~ $USERNAME_RE) {
        return _result(CU_OK, 'correct username syntax');
    } else {
        return _result(CU_BAD_SYNTAX, 'bad username syntax');
    }
}

sub check_network($$) {
    my($hostname, $username) = @_;

    _pm_log "check_network: checking \"$username\" on \"$hostname\"";

    # list of mail servers for hostname
    my @mservers = ();

    my $timeout = $Timeout;
    my $start_time = time;

    my $resolver = $Mail::CheckUser::Net_DNS_Resolver || new Net::DNS::Resolver;
    my $tout = _calc_timeout($timeout, $start_time);
    return _result(CU_DNS_TIMEOUT, 'DNS timeout') if $tout == 0;
    $resolver->udp_timeout($tout);

    my @mx = mx($resolver, "$hostname.");
    $tout = _calc_timeout($timeout, $start_time);
    return _result(CU_DNS_TIMEOUT, 'DNS timeout') if $tout == 0;

    # check result of query
    if(@mx) {
        # if MX record exists,
        # then it's already sorted by preference
        @mservers = map {$_->exchange} @mx;
    } else {
        # if there is no MX record try hostname as mail server
        my $tout = _calc_timeout($timeout, $start_time);
        return _result(CU_DNS_TIMEOUT, 'DNS timeout') if $tout == 0;
        $resolver->udp_timeout($tout);

        my $res = $resolver->search("$hostname.", 'A');
        # check if timeout has happen
        $tout = _calc_timeout($timeout, $start_time);
        return _result(CU_DNS_TIMEOUT, 'DNS timeout') if $tout == 0;

        # check result of query
        if($res) {
            @mservers = ($hostname);
            my $ip;
            foreach my $rr ($res->answer) {
              if ($rr->type eq "A") {
                $ip = $rr->address;
                last;
              } elsif ($rr->type eq "CNAME") {
                $ip = $rr->cname;
              } else {
                # Should never happen!
                $ip = "";
              }
            }
            _pm_log "check_network: \"$ip\" Wildcard gTLD check";
            return _result(CU_UNKNOWN_DOMAIN, 'Wildcard gTLD') if $NXDOMAIN->{lc $ip};
        } else {
            return _result(CU_UNKNOWN_DOMAIN, 'DNS failure: ' . $resolver->errorstring);
        }
    }

    foreach my $mserver (@mservers) {
        _pm_log "check_network: \"$mserver\" Wildcard gTLD check";
        return _result(CU_UNKNOWN_DOMAIN, 'Wildcard gTLD') if $NXDOMAIN->{lc $mserver};
    }

    if($Skip_SMTP_Checks) {
        return _result(CU_OK, 'skipping SMTP checks');
    } else {
        if ($Skip_SYN) {
            # Skip SYN/ACK check.
            # Just check user on each mail server one at a time.
            foreach my $mserver (@mservers) {
                my $tout = _calc_timeout($timeout, $start_time);
                if ($mserver !~ /^\d+\.\d+\.\d+\.\d+$/) {
                    # Resolve it to an IP
                    return _result(CU_DNS_TIMEOUT, 'DNS timeout') if $tout == 0;
                    $resolver->udp_timeout($tout);
                    if (my $ans = $resolver->query($mserver)) {
                        foreach my $rr_a ($ans->answer) {
                            if ($rr_a->type eq "A") {
                                $mserver = $rr_a->address;
                                last;
                            }
                        }
                    }
                    $tout = _calc_timeout($timeout, $start_time);
                }
                return _result(CU_SMTP_TIMEOUT, 'SMTP timeout') if $tout == 0;

                my $res = check_user_on_host $mserver, $username, $hostname, $tout;

                return 1 if $res == 1;
                return 0 if $res == 0;
            }
        } else {
            # Determine which mail servers are on
            my $resolve = {};
            my $tout = _calc_timeout($timeout, $start_time);
            foreach my $mserver (@mservers) {
                # All mservers need to be resolved to IPs before the SYN check
                if ($mserver =~ /^\d+\.\d+\.\d+\.\d+$/) {
                    $resolve->{$mserver} = 1;
                } else {
                    _pm_log "check_network: \"$mserver\" resolving";
                    return _result(CU_DNS_TIMEOUT, 'DNS timeout') if $tout == 0;
                    $resolver->udp_timeout($tout);
                    if (my $ans = $resolver->query($mserver)) {
                        foreach my $rr_a ($ans->answer) {
                            if ($rr_a->type eq "A") {
                                $mserver = $rr_a->address;
                                $resolve->{$mserver} = 1;
                                _pm_log "check_network: resolved to IP \"$mserver\"";
                                last;
                            }
                        }
                    } else {
                        _pm_log "check_network: \"$mserver\" host not found!";
                    }
                    $tout = _calc_timeout($timeout, $start_time);
                }
            }

            require Net::Ping;
            import Net::Ping 2.24;
            # Use only three-fourths of the full timeout for lookups
            # in order to leave time to actually speak to the server.
            my $ping = Net::Ping->new("syn", _calc_timeout($timeout, $start_time) * 3 / 4 + 1);
            $ping->{port_num} = getservbyname("smtp", "tcp");
            $ping->tcp_service_check(1);
            foreach my $mserver (@mservers) {
                _pm_log "check_network: \"$mserver\" sending SYN...";
                # untaint before passing to Net::Ping
                my ($tainted) = $mserver =~ /(\d+\.\d+\.\d+\.\d+)/;
                if ($tainted and $tainted eq $mserver and
                    $resolve->{$tainted} and $ping->ping($tainted)) {
                    _pm_log "check_network: \"$tainted\" SYN packet sent.";
                } else {
                    _pm_log "check_network: \"$mserver\" host not found!";
                }
            }
            foreach my $mserver (@mservers) {
                my $tout = _calc_timeout($timeout, $start_time);
                return _result(CU_SMTP_TIMEOUT, 'SMTP timeout') if $tout == 0;

                _pm_log "check_network: \"$mserver\" waiting for ACK";
                if ($resolve->{$mserver}) {
                    # untaint before passing to Net::Ping
                    my($mserver) = $mserver =~ /(\d+\.\d+\.\d+\.\d+)/;
                    if ($ping->ack($mserver)) {
                        _pm_log "check_network: \"$mserver\" ACK received.";
                        # check user on this mail server
                        my $res = check_user_on_host $mserver, $username, $hostname, $tout;

                        return 1 if $res == 1;
                        return 0 if $res == 0;
                    } else {
                        _pm_log "check_network: \"$mserver\" no ACK received: [".
                            ($ping->nack($mserver) || "no SYN sent")."]";
                    }
                } else {
                    _pm_log "check_network: skipping check_user_on_host \"$mserver\" since it did not resolve";
                }
            }
        }

        return _result(CU_SMTP_UNREACHABLE,
                       'Cannot connect SMTP servers: ' .
                       join(', ', @mservers));
    }

    # it should be impossible to reach this statement
    die "Internal error";
}

sub check_user_on_host($$$$) {
    my($mserver, $username, $hostname, $timeout) = @_;

    _pm_log "check_user_on_host: checking user \"$username\" on \"$mserver\"";

    my $start_time = time;

    # disable warnings because Net::SMTP can generate some on timeout
    # conditions
    local $^W = 0;

    # try to connect to mail server
    my $tout = _calc_timeout($timeout, $start_time);
    return _result(CU_SMTP_TIMEOUT, 'SMTP timeout') if $tout == 0;

    my @hello_params = defined $Helo_Domain ? (Hello => $Helo_Domain) : ();
    my $smtp = Net::SMTP->new($mserver, Timeout => $tout, @hello_params);
    unless(defined $smtp) {
        _pm_log "check_user_on_host: unable to connect to \"$mserver\"";
        return -1;
    }

    # try to check if user is valid with MAIL/RCPT commands
    $tout = _calc_timeout($timeout, $start_time);
    return _result(CU_SMTP_TIMEOUT, 'SMTP timeout') if $tout == 0;
    $smtp->timeout($tout);

    # send MAIL FROM command
    unless($smtp->mail($Sender_Addr)) {
        # something wrong?

        # check for timeout
        return _result(CU_SMTP_TIMEOUT, 'SMTP timeout') if $tout == 0;

        _pm_log "check_user_on_host: can't say MAIL - " . $smtp->message;
        return -1;
    }

    # send RCPT TO command
    if($smtp->to("$username\@$hostname")) {
        # give server opportunity to exist gracefully by telling it QUIT
        my $tout = _calc_timeout($timeout, $start_time);
        if($tout) {
            $smtp->timeout($tout);
            $smtp->quit;
        }

        return _result(CU_OK, 'SMTP server accepts username');
    } else {
        # check if verify returned error because of timeout
        my $tout = _calc_timeout($timeout, $start_time);
        return _result(CU_SMTP_TIMEOUT, 'SMTP timeout') if $tout == 0;

        my $code = $smtp->code;

        # give server opportunity to exist gracefully by telling it QUIT
        $smtp->timeout($tout);
        $smtp->quit;

        if($code == 550 or $code == 551 or $code == 553) {
            return _result(CU_UNKNOWN_USER, 'no such user');
        } elsif($code == 552) {
            return _result(CU_MAILBOX_FULL, 'mailbox full');
        } elsif($code =~ /^4/) {
            return _result(CU_TRY_AGAIN, 'temporary delivery failure');
        } else {
            _pm_log "check_user_on_host: unknown error in response";
            return _result(CU_OK, 'unknown error in response');
        }
    }


    # it should be impossible to reach this statement
    die "Internal error";
}

sub _calc_timeout($$) {
    my($full_timeout, $start_time) = @_;

    my $now_time = time;
    my $passed_time = $now_time - $start_time;
    _pm_log "_calc_timeout: start - $start_time, now - $now_time";
    _pm_log "_calc_timeout: timeout - $full_timeout, passed - $passed_time";

    my $timeout = $full_timeout - $passed_time;

    if($timeout < 0) {
        return 0;
    } else {
        return $timeout;
    }
}

sub _pm_log($) {
    my($log_str) = @_;

    if($Debug) {
        print STDERR "$log_str\n";
    }
}

sub _result($$) {
    my($code, $reason) = @_;

    my $ok = 0;

    $ok = 1 if $code == CU_OK;
    $ok = 1 if $code == CU_SMTP_UNREACHABLE;
    $ok = 1 if $code == CU_MAILBOX_FULL and not $Treat_Full_As_Fail;
    $ok = 1 if $code == CU_DNS_TIMEOUT and not $Treat_Timeout_As_Fail;
    $ok = 1 if $code == CU_SMTP_TIMEOUT and not $Treat_Timeout_As_Fail;
    $ok = 1 if $code == CU_TRY_AGAIN and not $Treat_Grey_As_Fail;

    $Last_Check = { ok     => $ok,
                    code   => $code,
                    reason => $reason };

    my($sub) = (caller(1))[3] =~ /^.*::(.*)$/;

    _pm_log "$sub: check result is " .
            ($ok ? 'ok' : 'not ok') .
            ": [$code] $reason";

    return $ok;
}

1;
__END__

=head1 NAME

Mail::CheckUser - check email addresses for validity

=head1 SYNOPSIS

    use Mail::CheckUser qw(check_email);
    my $ok = check_email($email_addr);

    use Mail::CheckUser qw(:constants check_email last_check)
    my $ok = check_email($email_addr);
    print "DNS timeout\n"
        if last_check()->{code} == CU_DNS_TIMEOUT;

    use Mail::CheckUser;
    my $res = Mail::CheckUser::check_email($email_addr);


=head1 DESCRIPTION

This Perl module provides routines for checking validity of email address.

It makes several checks:

=over 4

=item 1

It checks the syntax of an email address.

=item 2

It checks if there any MX records or A records for the domain part
of the email address.

=item 3

It tries to connect to an email server directly via SMTP to check if
mailbox is valid.  Old versions of this module performed this check
via the VRFY command.  Now the module uses another check; it uses a
combination of MAIL and RCPT commands which simulates sending an
email.  It can detect bad mailboxes in many cases.

=back

If is possible to turn off some or all networking checks (items 2 and 3).
See L<"GLOBAL VARIABLES">.

This module was designed with CGIs (or any other dynamic Web content
programmed with Perl) in mind.  Usually it is required to quickly
check e-mail addresses in forms.  If the check can't be finished in
reasonable time, the e-mail address should be treated as valid.  This
is the default policy.  By default if a timeout happens the result of
the check is treated as positive.  This behavior can be overridden -
see L<"GLOBAL VARIABLES">.

=head1 IMPORTANT WARNING

In many cases there is no way to detect the validity of email
addresses with network checks.  For example, non-monolithic mail
servers (such as Postfix and qmail) often report that a user exists
even if it is not so.  This is because in cases where the work of the
server is split among many components, the SMTP server may not know
how to check for the existence of a particular user.  Systems like
these will reject mail to unknown users, but they do so after the SMTP
conversation.  In cases like these, the only absolutely sure way to
determine whether or not a user exists is to actually send a mail and
wait to see if a bounce messages comes back.  Obviously, this is not a
workable strategy for this module.  Does it mean that the network
checks in this module are useless?  No.  For one thing, just the DNS
checks go a long way towards weeding out mistyped domain parts.  Also,
there are still many SMTP servers that will reject a bad address
during the SMTP conversation.  Because of this, it's still a useful
part of checking for a valid email address.  And this module was
designed such that if there is exists possibility (however small) that
the email address is valid, it will be treated as valid by this
module.

Another warning is about C<$Mail::CheckUser::Treat_Timeout_As_Fail>
global variable.  Use it carefully - if it is set to true then some
valid email addresses can be treated as bad simply because an SMTP or
DNS server responds slowly.

Another warning is about C<$Mail::CheckUser::Treat_Full_As_Fail>
global variable.  Use it carefully - if it is set to true then some
valid email addresses can be treated as bad simply because their
mailbox happens to be temporarily full.

=head1 EXAMPLE

This simple script checks if email address C<blabla@foo.bar> is
valid.

    use Mail::CheckUser qw(check_email last_check);

    my $email = 'blabla@foo.bar';

    if(check_email($email)) {
        print "E-mail address <$email> is OK\n";
    } else {
        print "E-mail address <$email> isn't valid: ",
              last_check()->{reason}, "\n";
    }

=head1 SUBROUTINES

=over 4

=item $ok = check_email($email)

Validates email address C<$email>.  Return true if email address is
valid and false otherwise.

=item $res = last_check()

Returns detailed result of last check made with C<check_email> as hash
reference:

    { ok => OK, code => CODE, reason => REASON }

=over 4

=item OK

True if last checked email address is valid.  False otherwise.

=item CODE

A number which describes result of last check.  See L<"CONSTANTS">.

=item REASON

A string which describes result of last check.

=back

=back

=head1 CONSTANTS

Constants used by C<last_check> to describe result of last check can
be exported with

    use Mail::CheckUser qw(:constants)

List of all defined constants:

=over 4

=item CU_OK

Check is successful.

=item CU_BAD_SYNTAX

Bad syntax of email address.

=item CU_UNKNOWN_DOMAIN

Mail domain mentioned in email address is unknown.

=item CU_DNS_TIMEOUT

Timeout has happen during DNS checks.

=item CU_UNKNOWN_USER

User is unknown on SMTP server.

=item CU_SMTP_TIMEOUT

Timeout has happen during SMTP checks.

=item CU_SMTP_UNREACHABLE

All SMTP servers for mail domain were found unreachable during SMTP
checks.

=item CU_MAILBOX_FULL

Mailbox is temporarily full but probably a valid username.

=back

=head1 GLOBAL VARIABLES

It is possible to configure C<check_email> using the global variables listed
below.

=over 4

=item $Mail::CheckUser::Skip_Network_Checks

If true then do only syntax checks.  By default it is false.

=item $Mail::CheckUser::Skip_SMTP_Checks

If it is true then do not try to connect to mail server to check if a
user exists.  If this is true, and
C<$Mail::CheckUser::Skip_Network_Checks> is false, only syntax and DNS
checks are performed.  By default it is false.

=item $Mail::CheckUser::Skip_SYN

By default L<Net::Ping|Net::Ping> is used to determine remote
reachability of SMTP servers before doing SMTP checks.
Setting this to true skips this check.  By default it is false.

=item $Mail::CheckUser::Sender_Addr

MAIL/RCPT check needs an email address to use as the 'From' address
when performing its checks.  The default value is C<check@user.com>.

=item $Mail::CheckUser::Helo_Domain

Sender domain used in HELO SMTP command.  If undef
L<Net::SMTP|Net::SMTP> is allowed to use its default value.  By
default it is undef.

=item Mail::CheckUser::Timeout

Timeout in seconds for network checks.  By default it is C<60>.

=item $Mail::CheckUser::Treat_Timeout_As_Fail

If it is true C<Mail::CheckUser> treats checks that time out as
failed.  By default it is false.

=item $Mail::CheckUser::Treat_Full_As_Fail

If it is true C<Mail::CheckUser> treats error "552 mailbox full"
as an invalid email and sets CU_MAILBOX_FULL.
By default it is false.

=item $Mail::CheckUser::Treat_Grey_As_Fail

If it is true C<Mail::CheckUser> treats all 400's errors
as an invalid email and sets CU_TRY_AGAIN.
By default it is false.

=item $Mail::CheckUser::Net_DNS_Resolver

Override with customized Net::DNS::Resolver object.
This is used to lookup MX and A records for the
email domain when network checks are enabled.
If undef, Net::DNS::Resolver->new will be used.
The default value is undef.

=item $Mail::CheckUser::Debug

If it is true then enable debug output on C<STDERR>.  By default it is
false.

=back

=head1 AUTHORS

Ilya Martynov B<ilya@martynov.org>

Rob Brown B<bbb@cpan.org>

Module maintained at Source Forge (
http://sourceforge.net/projects/mail-checkuser/
).

=head1 COPYRIGHT

Copyright (c) 1999-2003 by Ilya Martynov.  All rights
reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

$Id: CheckUser.pm,v 1.46 2003/09/18 23:51:36 hookbot Exp $

=head1 SEE ALSO

perl(1).

=cut
