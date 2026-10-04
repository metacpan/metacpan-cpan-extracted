#!/usr/bin/env perl
# t/rt_181461.t -- RT#181461: journald tests failed, then hung, on perls
# without 64-bit integers
#
# The journald binary framing used pack('Q<'), which dies on such perls, so
# every send failed ("Invalid type 'Q' in pack"), and t/journald.t then
# blocked for ever in recv().  The length is now packed as two 32-bit words
# (fixed in 0.35), and t/journald.t receives with MSG_DONTWAIT (0.36).
#
# This file makes pack() and unpack() die on 'Q' and 'q', as they do on
# those perls, before Log::Abstraction is compiled.

use strict;
use warnings;

use File::Temp qw(tempdir);
use Socket qw(AF_UNIX SOCK_DGRAM sockaddr_un MSG_DONTWAIT);
use Test::Most;

# Unix-domain sockets aren't available everywhere (notably Windows).  This
# must come before any test, and the reason must not end "at FILE line N."
{
	my $ok = eval {
		socket(my $probe, AF_UNIX, SOCK_DGRAM, 0) or die "$!\n";
		close $probe;
		1;
	};
	if(!$ok) {
		chomp(my $reason = $@);
		plan skip_all => "Unix domain sockets not available: $reason";
	}
}

# Behave like a perl without 64-bit integers for all code compiled from here
# on, including Log::Abstraction
BEGIN {
	*CORE::GLOBAL::pack = sub {
		my $template = shift;
		die "Invalid type 'Q' in pack\n" if($template =~ /[Qq]/);
		return CORE::pack($template, @_);
	};
	*CORE::GLOBAL::unpack = sub {
		my ($template, @rest) = @_;
		die "Invalid type 'Q' in unpack\n" if($template =~ /[Qq]/);
		return CORE::unpack($template, @rest ? $rest[0] : $_);
	};
}

use Log::Abstraction;

# Fail rather than hang, which is how the reported run ended
local $SIG{ALRM} = sub { BAIL_OUT('timed out: a journald test hung (RT#181461)') };
alarm(60);

my $tmpdir   = tempdir(CLEANUP => 1);
my $sockpath = "$tmpdir/journal.socket";

# Bind a receiver, run $code, and return the datagram sent (or '' if none).
# The receive doesn't block, so a failed send can't hang the test
sub capture {
	my ($code) = @_;

	socket(my $recv, AF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
	bind($recv, sockaddr_un($sockpath)) or die "bind: $!";
	$code->();
	my $data = '';
	recv($recv, $data, 65536, MSG_DONTWAIT);
	close $recv;
	unlink $sockpath;
	return $data;
}

subtest 'the simulation works' => sub {
	throws_ok(sub { my $x = pack('Q<', 1) }, qr/Invalid type 'Q' in pack/, "pack('Q<') dies");
	throws_ok(sub { my @x = unpack('q', 'x' x 8) }, qr/Invalid type 'Q' in unpack/, "unpack('q') dies");
	is(unpack('V', pack('V', 7)), 7, "pack('V') still works");
};

subtest 'binary-framed journald fields are sent' => sub {
	my $warned;
	local $SIG{__WARN__} = sub { $warned .= $_[0] };

	# A message with a line break is sent with binary framing, the code
	# path that used pack('Q<')
	my $message = "line one\nline two";
	my $data = capture(sub {
		Log::Abstraction->new(level => 'info', logger => { journald => { socket => $sockpath } })
			->info($message);
	});

	ok(!defined($warned), 'no "journald send failed" warning') or diag($warned);
	ok(length($data), 'a datagram was received');
	like($data, qr/^MESSAGE\n/, 'MESSAGE uses binary framing');

	# Read the length back as two 32-bit little-endian words
	my ($low, $high) = unpack('VV', substr($data, length("MESSAGE\n"), 8));
	my $len = $low + $high * 2**32;
	is($len, length($message), 'the length is correct');
	is($high, 0, 'the high word is 0');
	is(substr($data, length("MESSAGE\n") + 8, $len), $message, 'the message follows the length');
};

subtest 'a structured field with a line break is sent too' => sub {
	my $warned;
	local $SIG{__WARN__} = sub { $warned .= $_[0] };

	my $data = capture(sub {
		Log::Abstraction->new(level => 'info', logger => { journald => { socket => $sockpath } })
			->info('m', { detail => "a\nb" });
	});
	ok(!defined($warned), 'no warning') or diag($warned);
	like($data, qr/^DETAIL\n/m, 'DETAIL uses binary framing');
};

subtest 'a failed send returns promptly' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $log = Log::Abstraction->new(level => 'info', logger => { journald => { socket => "$tmpdir/missing.socket" } });
	my $start = time();
	lives_ok(sub { $log->info("x\ny") for(1..3) }, 'logging to a missing socket does not die');
	cmp_ok(time() - $start, '<', 10, 'and does not hang');
	is(scalar(@warnings), 1, 'one warning for repeated failures');
	like($warnings[0], qr/journald send failed/, 'about the failed send');
	unlike($warnings[0], qr/Invalid type/, 'not about pack');
};

subtest "the source has no 64-bit pack template" => sub {
	my $source = $INC{'Log/Abstraction.pm'};
	open(my $fin, '<', $source) or die "$source: $!";
	my @bad = grep { /\b(?:un)?pack\s*\(\s*(['"])[^'"]*[Qq]/ && !/^\s*#/ } <$fin>;
	close $fin;
	is_deeply(\@bad, [], "no pack('Q...') or unpack('Q...') in $source");
};

alarm(0);

done_testing();
