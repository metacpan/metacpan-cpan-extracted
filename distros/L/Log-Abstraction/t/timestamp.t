#!/usr/bin/env perl
# t/timestamp.t -- timestamp_format, timestamp_precision and utc

use strict;
use warnings;

use POSIX ();
use Readonly;
use Test::Mockingbird;
use Test::Most;

use_ok('Log::Abstraction');

# 2001-09-09T01:46:40Z, plus a fraction that is exact in binary
Readonly::Scalar my $EPOCH => 1_000_000_000;

# Log one message with the clock fixed at $now, and return its timestamp
sub stamp {
	my ($now, %args) = @_;

	my $guard = Test::Mockingbird::mock_scoped('Time::HiRes::time' => sub { $now });
	my $out = '';
	open(my $fh, '>', \$out) or die $!;
	Log::Abstraction->new(level => 'info', fd => $fh, array => [], format => '%timestamp%', %args)->info('m');
	close $fh;
	chomp($out);
	return $out;
}

# Apply a change to $ENV{TZ}.  POSIX::tzset dies on Windows ("not
# implemented on this architecture"); with_tz then sees that localtime is
# unchanged and skips
sub tzset { eval { POSIX::tzset(); 1 }; return }

# Run $code with TZ set, or skip if this system ignores that TZ value.
# $want_hour is the local hour expected at $EPOCH
sub with_tz {
	my ($tz, $want_hour, $code) = @_;

	local $ENV{TZ} = $tz;
	tzset();
	SKIP: {
		skip("TZ '$tz' is not supported here", 1) if((localtime($EPOCH))[2] != $want_hour);
		$code->();
	}
	return;
}
END { tzset() }

subtest 'default format is unchanged' => sub {
	like(stamp($EPOCH + 0.5), qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$/, 'YYYY-MM-DD HH:MM:SS');
	is(stamp($EPOCH + 0.5, utc => 1), '2001-09-09 01:46:40', 'in UTC');
};

subtest 'iso8601 and rfc3339 in UTC' => sub {
	is(stamp($EPOCH, utc => 1, timestamp_format => 'rfc3339'), '2001-09-09T01:46:40Z', 'rfc3339');
	is(stamp($EPOCH, utc => 1, timestamp_format => 'iso8601'), '2001-09-09T01:46:40Z', 'iso8601');
	is(stamp($EPOCH, utc => 1, timestamp_format => 'RFC3339'), '2001-09-09T01:46:40Z', 'case-insensitive');
};

subtest 'timestamp_precision' => sub {
	my %utc = (utc => 1, timestamp_format => 'rfc3339');
	is(stamp($EPOCH + 0.125, %utc, timestamp_precision => 0), '2001-09-09T01:46:40Z', '0 digits');
	is(stamp($EPOCH + 0.125, %utc, timestamp_precision => 3), '2001-09-09T01:46:40.125Z', '3 digits');
	is(stamp($EPOCH + 0.125, %utc, timestamp_precision => 6), '2001-09-09T01:46:40.125000Z', '6 digits');
	is(stamp($EPOCH + 0.125, %utc, timestamp_precision => 9), '2001-09-09T01:46:40.125000000Z', '9 digits');
	is(stamp($EPOCH + 0.125, utc => 1, timestamp_precision => 3), '2001-09-09 01:46:40.125', 'with the default format');
	is(stamp($EPOCH + 0.125, utc => 1, timestamp_precision => 2, timestamp_format => '%S|%S'), '40.12|40.12',
		'after every %S');
};

subtest '%N fractional seconds' => sub {
	my $now = $EPOCH + 1023 / 1024;    # .9990234375
	is(stamp($now, utc => 1, timestamp_format => '%S.%N'), '40.999023437', '%N is 9 digits');
	is(stamp($now, utc => 1, timestamp_format => '%S.%3N'), '40.999', '%3N');
	is(stamp($now, utc => 1, timestamp_format => '%S.%8N'), '40.99902343', 'truncated, not rounded');
	is(stamp($now, utc => 1, timestamp_format => '%S.%1N'), '40.9', '%1N');
	is(stamp($EPOCH, utc => 1, timestamp_format => '%S.%3N'), '40.000', 'zero fraction');
};

subtest '%z, %:z and %Z in UTC' => sub {
	is(stamp($EPOCH, utc => 1, timestamp_format => '%z %:z %Z'), '+0000 +00:00 UTC', 'offsets and zone');
};

subtest '%% is a literal %' => sub {
	is(stamp($EPOCH + 0.125, utc => 1, timestamp_precision => 3, timestamp_format => '%%N %%z %%S %S'),
		'%N %z %S 40.125', 'escaped tokens are not expanded');
};

subtest 'local offsets' => sub {
	with_tz('EST5', 20, sub {
		is(stamp($EPOCH, timestamp_format => 'rfc3339'), '2001-09-08T20:46:40-05:00', 'EST5: -05:00');
		is(stamp($EPOCH, timestamp_format => '%z'), '-0500', 'EST5: %z');
	});
	with_tz('EST5EDT,M3.2.0,M11.1.0', 21, sub {
		is(stamp($EPOCH, timestamp_format => 'rfc3339'), '2001-09-08T21:46:40-04:00', 'daylight saving: -04:00');
	});
	with_tz('IST-5:30', 7, sub {
		is(stamp($EPOCH, timestamp_format => 'rfc3339', timestamp_precision => 3),
			'2001-09-09T07:16:40.000+05:30', 'half-hour offset: +05:30');
	});
	with_tz('EST5', 20, sub {
		is(stamp($EPOCH, timestamp_format => 'rfc3339', utc => 1), '2001-09-09T01:46:40Z', 'utc ignores TZ');
	});
};

subtest 'format => json uses the timestamp options' => sub {
	require JSON::PP;
	my $json = stamp($EPOCH + 0.5, format => 'json', utc => 1, timestamp_format => 'rfc3339', timestamp_precision => 1);
	is(JSON::PP->new->decode($json)->{timestamp}, '2001-09-09T01:46:40.5Z', 'JSON timestamp');
};

subtest 'one timestamp per message for every backend' => sub {
	my $calls = 0;
	my $guard = Test::Mockingbird::mock_scoped('Time::HiRes::time' => sub { $EPOCH + 0.001 * ++$calls });
	my ($out1, $out2) = ('', '');
	open(my $fh1, '>', \$out1) or die $!;
	open(my $fh2, '>', \$out2) or die $!;
	my $log = Log::Abstraction->new(level => 'info', fd => $fh2, logger => { fd => $fh1 },
		format => '%timestamp%', utc => 1, timestamp_precision => 3);

	$log->info('a');
	close $fh1;
	close $fh2;
	is($calls, 1, 'the clock is read once');
	is($out1, $out2, 'both backends show the same time');
	is($out1, "2001-09-09 01:46:40.001\n", 'and it is the time of the call');
};

subtest 'invalid options croak' => sub {
	for my $bad (10, -1, 'x', 1.5, '') {
		throws_ok(sub { Log::Abstraction->new(logger => [], timestamp_precision => $bad) },
			qr/timestamp_precision must be an integer from 0 to 9, not '\Q$bad\E'/, "timestamp_precision '$bad'");
	}
	throws_ok(sub { Log::Abstraction->new(logger => [], timestamp_format => '') },
		qr/timestamp_format must be a non-empty string/, 'empty timestamp_format');
	throws_ok(sub { Log::Abstraction->new(logger => [], timestamp_format => undef) },
		qr/timestamp_format must be a non-empty string/, 'undef timestamp_format');
	throws_ok(sub { Log::Abstraction->new(logger => [], timestamp_format => []) },
		qr/timestamp_format must be a non-empty string/, 'reference as timestamp_format');
	throws_ok(sub { Log::Abstraction->new(logger => [])->new(timestamp_precision => 99) },
		qr/timestamp_precision must be an integer/, 'checked when cloning too');
};

subtest 'a clone can change the timestamp options' => sub {
	my $guard = Test::Mockingbird::mock_scoped('Time::HiRes::time' => sub { $EPOCH });
	my $out = '';
	open(my $fh, '>', \$out) or die $!;
	my $log = Log::Abstraction->new(level => 'info', fd => $fh, array => [], format => '%timestamp%', utc => 1);
	$log->new(timestamp_format => 'rfc3339')->info('clone');
	$log->info('parent');
	close $fh;
	is($out, "2001-09-09T01:46:40Z\n2001-09-09 01:46:40\n", 'clone and parent differ');
};

done_testing();
