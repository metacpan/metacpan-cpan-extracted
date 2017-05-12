#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;

my ($SECONDS, $M_SECONDS); # Script's startup time
my $DEBUG = @ARGV; # Pass an argument to turn debug mode on

#
# Install mock versions of the Time::HiRes functions that are used by %R. This
# functions will be created even if Time::HiRes is not installed. This test can
# be executed even if Time::HiRes is not installed as the real module is never
# used.
#
BEGIN {
	# This block is used to force Log4perl to detect Time::HiRes no matter if
	# the module is installed.
	{
		require Log::Log4perl::Util;
		my $original = \&Log::Log4perl::Util::module_available;

		no warnings 'redefine';
		*Log::Log4perl::Util::module_available = sub {
			if ($_[0] eq 'Time::HiRes') {
				return 1; # Pretend that the module is always installed
			}
			goto $original;
		}
	}


	# Find out if Time::HiRes is installed
	my $original_time;
	eval {
		require Time::HiRes;
		$original_time = \&Time::HiRes::gettimeofday;
	};
	if (! $original_time) {
		# The real module Time::HiRes is not installed so we pretend that it is
		# already loaded.
		my $filename = File::Spec->catfile('Time', 'HiRes.pm');
		$INC{$filename} = $filename;
	}

	# Default time values.
	$SECONDS = time;
	$M_SECONDS = 100_000;


	{
		no warnings 'redefine';
		*Time::HiRes::gettimeofday = sub () {
			return ($SECONDS, $M_SECONDS);
		};
	}
}


use Log::Log4perl qw(:easy);
use Log::Log4perl::Appender::TestBuffer;


if ($Log::Log4perl::VERSION < 1.25) {
	exit main();
}
else {
	SKIP:
	{
		skip "functionality merged into log4perl", 2;
	}
}


# Pretend that the script was at sleep
sub fake_sleep ($) {
	my ($seconds) = @_;
	$SECONDS += $seconds;
	$M_SECONDS = ($M_SECONDS + 1_000) % 1_000_000;
}


sub main {

	init_logger();
	
	# Count the number of warnings issued by log4perl.
	# Here we are testing that the modifications to the layout don't affect the
	# PatternLayout. PatternLayout should complain about %R.
	my $warns = 0;
	local $SIG{__WARN__} = sub {
		my ($message) = @_;
		if ($message =~ /^Invalid conversion in sprintf: "%R"/) {
			++$warns;
			return;
		}
		warn @_;
	};

	# Start some logging
	INFO "Start";

	fake_sleep 1;
	DEBUG "Pause: 1 sec";

	fake_sleep 2;
	INFO  "Pause: 2 secs";

	fake_sleep 1;
	DEBUG "Pause: 1 sec";

	WARN "End";

	#  Debug traces to be turned on when troubleshooting
	if ($DEBUG) {
		# Get the contents of the buffers
		foreach my $appender (qw(A B)) {
			my $buffer = Log::Log4perl::Appender::TestBuffer->by_name($appender)->buffer();
			diag("========= $appender ==========");
			diag($buffer);
		}
	}

	# Get the elapsed times so far
	my @a = get_all_elapsed_ms('A');
	my @b = get_all_elapsed_ms('B');

	is_deeply(
		\@a,
		[
			'A 0ms Start [0ms]',
			'A 1001ms Pause: 1 sec [1000ms]',
			'A 2001ms Pause: 2 secs [3002ms]',
			'A 1001ms Pause: 1 sec [4003ms]',
			'A 0ms End [4003ms]',
		]
	);

	is_deeply(
		\@b,
		[
			'B 0ms Start [0ms]',
			'B 3002ms Pause: 2 secs [3002ms]',
			'B 1001ms End [4003ms]',
		]
	);

	return 0;
}


#
# Returns the elapsed times logged so far.
#
sub get_all_elapsed_ms {
	my ($categoty) = @_;

	return split /\n/,
		Log::Log4perl::Appender::TestBuffer->by_name($categoty)->buffer()
	;
}


#
# Initialize the logging system
#
sub init_logger {

	my $conf = <<'__END__';
log4perl.rootLogger = ALL, A, B, C

log4perl.appender.A = Log::Log4perl::Appender::TestBuffer
log4perl.appender.A.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
log4perl.appender.A.layout.ConversionPattern = A %Rms %m [%rms]%n
log4perl.appender.A.Threshold = ALL

log4perl.appender.B = Log::Log4perl::Appender::TestBuffer
log4perl.appender.B.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
log4perl.appender.B.layout.ConversionPattern = B %Rms %m [%rms]%n
log4perl.appender.B.Threshold = INFO

log4perl.appender.C = Log::Log4perl::Appender::TestBuffer
log4perl.appender.C.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.C.layout.ConversionPattern = C %Rms %m [%rms]%n
log4perl.appender.C.Threshold = INFO
__END__

	Log::Log4perl->init(\$conf);
}
