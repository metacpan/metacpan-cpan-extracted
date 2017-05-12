package Log::Syslog::Constants;

use 5.6.2;
use strict;
use warnings;

our $VERSION = '1.02';

# severities
use constant LOG_EMERG      => 0; # system is unusable
use constant LOG_ALERT      => 1; # action must be taken immediately
use constant LOG_CRIT       => 2; # critical conditions
use constant LOG_ERR        => 3; # error conditions
use constant LOG_WARNING    => 4; # warning conditions
use constant LOG_NOTICE     => 5; # normal but significant condition
use constant LOG_INFO       => 6; # informational
use constant LOG_DEBUG      => 7; # debug-level messages

# facilities
use constant LOG_KERN       => 0; # kernel messages
use constant LOG_USER       => 1; # random user-level messages
use constant LOG_MAIL       => 2; # mail system
use constant LOG_DAEMON     => 3; # system daemons
use constant LOG_AUTH       => 4; # security/authorization messages
use constant LOG_SYSLOG     => 5; # messages generated internally by syslogd
use constant LOG_LPR        => 6; # line printer subsystem
use constant LOG_NEWS       => 7; # network news subsystem
use constant LOG_UUCP       => 8; # UUCP subsystem
use constant LOG_CRON       => 9; # clock daemon
use constant LOG_AUTHPRIV   => 10; # security/authorization messages (private)
use constant LOG_FTP        => 11; # ftp daemon
use constant LOG_LOCAL0     => 16; # reserved for local use
use constant LOG_LOCAL1     => 17; # reserved for local use
use constant LOG_LOCAL2     => 18; # reserved for local use
use constant LOG_LOCAL3     => 19; # reserved for local use
use constant LOG_LOCAL4     => 20; # reserved for local use
use constant LOG_LOCAL5     => 21; # reserved for local use
use constant LOG_LOCAL6     => 22; # reserved for local use
use constant LOG_LOCAL7     => 23; # reserved for local use

my %_severities_by_name = (
    emerg    => LOG_EMERG,
    alert    => LOG_ALERT,
    crit     => LOG_CRIT,
    err      => LOG_ERR,
    warning  => LOG_WARNING,
    notice   => LOG_NOTICE,
    info     => LOG_INFO,
    debug    => LOG_DEBUG,
);

my %_facilities_by_name = (
    kern     => LOG_KERN,
    user     => LOG_USER,
    mail     => LOG_MAIL,
    daemon   => LOG_DAEMON,
    auth     => LOG_AUTH,
    syslog   => LOG_SYSLOG,
    lpr      => LOG_LPR,
    news     => LOG_NEWS,
    uucp     => LOG_UUCP,
    cron     => LOG_CRON,
    authpriv => LOG_AUTHPRIV,
    ftp      => LOG_FTP,
    local0   => LOG_LOCAL0,
    local1   => LOG_LOCAL1,
    local2   => LOG_LOCAL2,
    local3   => LOG_LOCAL3,
    local4   => LOG_LOCAL4,
    local5   => LOG_LOCAL5,
    local6   => LOG_LOCAL6,
    local7   => LOG_LOCAL7,
);

sub get_severity {
    $_severities_by_name{lc $_[0]};
}

sub get_facility {
    $_facilities_by_name{lc $_[0]};
}

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    severities   => [qw/
        LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARNING
        LOG_NOTICE LOG_INFO LOG_DEBUG
    /],
    facilities => [qw/
        LOG_KERN LOG_USER LOG_MAIL LOG_DAEMON LOG_AUTH
        LOG_SYSLOG LOG_LPR LOG_NEWS LOG_UUCP LOG_CRON
        LOG_AUTHPRIV LOG_FTP LOG_LOCAL0 LOG_LOCAL1 LOG_LOCAL2
        LOG_LOCAL3 LOG_LOCAL4 LOG_LOCAL5 LOG_LOCAL6 LOG_LOCAL7
    /],
    functions => [qw/
        get_severity get_facility
    /],
);
@{ $EXPORT_TAGS{'all'} } = (
    @{ $EXPORT_TAGS{'facilities'} },
    @{ $EXPORT_TAGS{'severities'} },
    @{ $EXPORT_TAGS{'functions'} },
);

our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = qw();

1;

__END__

=head1 NAME

Log::Syslog::Constants - Perl extension containing syslog priority constants as
defined in RFC3164.

=head1 SYNOPSIS

  use Log::Syslog::Constants ':all';

  @severities = (
    LOG_EMERG, LOG_ALERT, LOG_CRIT, LOG_ERR, LOG_WARNING, LOG_NOTICE, LOG_INFO,
    LOG_DEBUG
  );

  @facilities = (
    LOG_KERN, LOG_USER, LOG_MAIL, LOG_DAEMON, LOG_AUTH, LOG_SYSLOG, LOG_LPR,
    LOG_NEWS, LOG_UUCP, LOG_CRON, LOG_AUTHPRIV, LOG_FTP, LOG_LOCAL0,
    LOG_LOCAL1, LOG_LOCAL2, LOG_LOCAL3, LOG_LOCAL4, LOG_LOCAL5, LOG_LOCAL6,
    LOG_LOCAL7
  );

  $info_constant = get_severity('INFO');
  $local0_constant = get_facility('local0');

=head1 DESCRIPTION

Syslog messages--as standardized in RFC3164--embed a priority number (the PRI
part) which is composed of a severity and a facility value. The constants which
encode these values are specified in section 4.1.1, and are made available by
this module. For instance, the exportable LOG_FTP constant has a value of 11,
the value for the FTP facility.

=head1 EXPORTS

Nothing is exported by default. You may optionally import individual constants
and functions or groups of them:

  use Log::Syslog::Constants qw(:severities); # LOG_CRIT, LOG_DEBUG, etc
  use Log::Syslog::Constants qw(:facilities); # LOG_CRON, LOG_LOCAL3, etc
  use Log::Syslog::Constants qw(:functions); # get_facility, get_severity
  use Log::Syslog::Constants qw(:all); # all of the above

=head1 FUNCTIONS

=over 4

=item * get_facility($facility_string)

=item * get_severity($severity_string)

These functions look up a constant value by name, e.g.
C<get_severity('info') == LOG_INFO>.

=back

=head1 SEE ALSO

L<RFC3164|http://www.ietf.org/rfc/rfc3164.txt>

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Say Media, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
