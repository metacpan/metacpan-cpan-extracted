#!/usr/bin/perl -w

# Fake up a Unix::Syslog class
BEGIN { $INC{'Unix/Syslog.pm'} = 1; }
package Unix::Syslog;
sub _stub    { die [ q{Unix::Syslog stub}, @_ ] }
no warnings 'once';
*openlog  = \&_stub;
*syslog   = \&_stub;
*closelog = \&_stub;
use warnings 'once';

# Constants borrowed from sys/syslog.h on Linux.  May not be the same
# on all platforms, but for testing purposes it should be fine.
sub LOG_PID     { 0x01 };
sub LOG_NDELAY  { 0x08 };

sub LOG_EMERG   { 0    };
sub LOG_ALERT   { 1    };
sub LOG_CRIT    { 2    };
sub LOG_ERR     { 3    };
sub LOG_WARNING { 4    };
sub LOG_NOTICE  { 5    };
sub LOG_INFO    { 6    };
sub LOG_DEBUG   { 7    };

sub LOG_KERN     { 0<<3 };
sub LOG_USER     { 1<<3 };
sub LOG_MAIL     { 2<<3 };
sub LOG_DAEMON   { 3<<3 };
sub LOG_AUTH     { 4<<3 };
sub LOG_SYSLOG   { 5<<3 };
sub LOG_LPR      { 6<<3 };
sub LOG_NEWS     { 7<<3 };
sub LOG_UUCP     { 8<<3 };
sub LOG_CRON     { 9<<3 };
sub LOG_AUTHPRIV { 10<<3 };
sub LOG_FTP      { 11<<3 };
sub LOG_LOCAL0   { 16<<3 };
sub LOG_LOCAL1   { 17<<3 };
sub LOG_LOCAL2   { 18<<3 };
sub LOG_LOCAL3   { 19<<3 };
sub LOG_LOCAL4   { 20<<3 };
sub LOG_LOCAL5   { 21<<3 };
sub LOG_LOCAL6   { 22<<3 };
sub LOG_LOCAL7   { 23<<3 };

our %EXPORT_TAGS = ("macros" => [qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR
				LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG
				LOG_KERN LOG_USER LOG_MAIL LOG_DAEMON LOG_AUTH
				LOG_SYSLOG LOG_LPR LOG_NEWS LOG_UUCP LOG_CRON
				LOG_AUTHPRIV LOG_FTP LOG_LOCAL0 LOG_LOCAL1
				LOG_LOCAL2 LOG_LOCAL3 LOG_LOCAL4 LOG_LOCAL5
				LOG_LOCAL6 LOG_LOCAL7 LOG_PID LOG_CONS
				LOG_ODELAY LOG_NDELAY LOG_NOWAIT LOG_PERROR
				LOG_NFACILITIES LOG_FACMASK LOG_FAC LOG_MASK
				LOG_PRI LOG_UPTO LOG_MAKEPRI)],
);

package main;

use Test::Exception;
use vars qw($FAKE_TESTS);
$FAKE_TESTS = 6;

# Perform same tests as real module
require 't/unix_syslog_real.t';

dies_ok { openlog('wookie', 'pid,ndelay', 'mail') } 'openlog hits our stub'; 
is_deeply( $@, [ q{Unix::Syslog stub}, 'wookie', Unix::Syslog::LOG_PID | Unix::Syslog::LOG_NDELAY, Unix::Syslog::LOG_MAIL ], '... got expected data via the stub');

dies_ok { syslog('err', '%s', 'Our wookie is broken') } 'syslog hits our stub'; 
is_deeply( $@, [ q{Unix::Syslog stub}, Unix::Syslog::LOG_ERR, '%s', 'Our wookie is broken' ], '... got expected data via the stub');

dies_ok { closelog() } 'closelog hits our stub'; 
is_deeply( $@, [ q{Unix::Syslog stub} ], '... got expected data via the stub');
