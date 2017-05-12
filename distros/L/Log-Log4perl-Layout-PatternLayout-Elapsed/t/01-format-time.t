#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

my $SECONDS; # Script's startup time
my $DEBUG = @ARGV; # Pass an argument to turn debug mode on

#
# Install mock time functions that will be used to simulate that time has has
# passed. This test will use Time::HiRes even if it's not installed.
#
BEGIN {

	# This block can be used to force Log4perl to NOT detect Time::HiRes no
	# matter if the module is installed.
	{
		require Log::Log4perl::Util;
		my $original = \&Log::Log4perl::Util::module_available;

		no warnings 'redefine';
		*Log::Log4perl::Util::module_available = sub {
			if ($_[0] eq 'Time::HiRes') {
				return 0; # Pretend that the module is NOT installed
			}
			goto $original;
		}
	}

	{
		$SECONDS = time();

		# At first we have to define a default for the core global time builtin
		*CORE::GLOBAL::time = sub () {
			CORE::time;
		};

		# No we can overide the core global time builtin
		no warnings 'redefine';
		*CORE::GLOBAL::time = sub () {
			return $SECONDS;
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
}


sub main {

	init_logger();


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
			'A 0s Start [0s]',
			'A 1s Pause: 1 sec [1s]',
			'A 2s Pause: 2 secs [3s]',
			'A 1s Pause: 1 sec [4s]',
			'A 0s End [4s]',
		]
	);

	is_deeply(
		\@b,
		[
			'B 0s Start [0s]',
			'B 3s Pause: 2 secs [3s]',
			'B 1s End [4s]',
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
log4perl.rootLogger = ALL, A, B

log4perl.appender.A = Log::Log4perl::Appender::TestBuffer
log4perl.appender.A.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
log4perl.appender.A.layout.ConversionPattern = A %Rs %m [%rs]%n
log4perl.appender.A.Threshold = ALL

log4perl.appender.B = Log::Log4perl::Appender::TestBuffer
log4perl.appender.B.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
log4perl.appender.B.layout.ConversionPattern = B %Rs %m [%rs]%n
log4perl.appender.B.Threshold = INFO
__END__

	Log::Log4perl->init(\$conf);
}
