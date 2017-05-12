#!/usr/bin/perl -w
use Test::More;
use Test::Exception;

eval { require Unix::Syslog };

use vars qw($REAL_TESTS $FAKE_TESTS);
$FAKE_TESTS ||= 0;
$REAL_TESTS = 41;

plan( skip_all => q{Unix::Syslog not installed; can't test} ) if $@;
plan tests => ($FAKE_TESTS + $REAL_TESTS);

use_ok('Log::Syslog::Abstract', qw( openlog syslog closelog ));

dies_ok { openlog() } 'openlog with no args dies';
like ( $@, qr/first argument must be an identifier string/, '... with expected error');

dies_ok { openlog('wookie') } 'openlog with one arg dies';
like ( $@, qr/second argument must be flag string/, '... with expected error');

dies_ok { openlog('wookie', 'pid,ndelay') } 'openlog with 2 args dies';
like ( $@, qr/third argument must be a facility string/, '... with expected error');

# Only check mapping of values if we have a real Unix::Syslog on this
# platform.

# check _convert_flags
my %flag_to_value = (
	pid     => Unix::Syslog::LOG_PID(),
	ndelay  => Unix::Syslog::LOG_NDELAY(),
);
is( Log::Syslog::Abstract::_convert_flags( 'pid,ndelay'), 0x01 | 0x08, 'bitwise-or of all flags is as expected');
foreach my $flag ( keys %flag_to_value ) {
	is( Log::Syslog::Abstract::_convert_flags( $flag ), $flag_to_value{$flag}, "Flag $flag works");
}

# check _convert_facility
# TODO: works on Linux... what about elsewhere?
my %facility_to_value = (
	emerg => Unix::Syslog::LOG_EMERG(),
	panic => Unix::Syslog::LOG_EMERG(),
	alert => Unix::Syslog::LOG_ALERT(),
	crit => Unix::Syslog::LOG_CRIT(),
	error => Unix::Syslog::LOG_ERR(),
	'err' => Unix::Syslog::LOG_ERR(),
	warning => Unix::Syslog::LOG_WARNING(),
	notice => Unix::Syslog::LOG_NOTICE(),
	info => Unix::Syslog::LOG_INFO(),
	debug => Unix::Syslog::LOG_DEBUG(),

	kern => Unix::Syslog::LOG_KERN(),
	user => Unix::Syslog::LOG_USER(),
	mail => Unix::Syslog::LOG_MAIL(),
	daemon => Unix::Syslog::LOG_DAEMON(),
	auth => Unix::Syslog::LOG_AUTH(),
	syslog => Unix::Syslog::LOG_SYSLOG(),
	lpr => Unix::Syslog::LOG_LPR(),
	news => Unix::Syslog::LOG_NEWS(),
	uucp => Unix::Syslog::LOG_UUCP(),
	cron => Unix::Syslog::LOG_CRON(),
	authpriv => Unix::Syslog::LOG_AUTHPRIV(),
	ftp => Unix::Syslog::LOG_FTP(),
	local0 => Unix::Syslog::LOG_LOCAL0(),
	local1 => Unix::Syslog::LOG_LOCAL1(),
	local2 => Unix::Syslog::LOG_LOCAL2(),
	local3 => Unix::Syslog::LOG_LOCAL3(),
	local4 => Unix::Syslog::LOG_LOCAL4(),
	local5 => Unix::Syslog::LOG_LOCAL5(),
	local6 => Unix::Syslog::LOG_LOCAL6(),
	local7 => Unix::Syslog::LOG_LOCAL7(),
);

foreach my $facility ( keys %facility_to_value ) {
	is( Log::Syslog::Abstract::_convert_facility( $facility ), $facility_to_value{$facility}, "Flag $facility works");
}

# Try some combinations
is( Log::Syslog::Abstract::_convert_facility( 'notice|local7') , $facility_to_value{notice} | $facility_to_value{local7}, 'bitwise-OR works');
