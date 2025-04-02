#! perl

use 5.040;

use IO::Socket::IP;
use IO::Uring;

my $ring = IO::Uring->new(32);
my $listener = IO::Socket::IP->new(
	LocalService => 12345,
	Listen       => 8,
	ReuseAddr    => 1,
);

sub do_read($fh) {
	my $buffer = "\0" x 512;

	$ring->recv($fh, $buffer, 0, 0, 0, sub($res, $flags) {
		if ($res < 0) {
			$! = -$res;
			die "Could not recv: $!";
		}
		return unless $res;

		do_send($fh, substr($buffer, 0, $res));
	});
}

sub do_send($fh, $buffer) {
	$ring->send($fh, $buffer, 0, 0, 0, sub($res, $flags) {
		if ($res < 0) {
			$! = -$res;
			die "Could not recv: $!";
		}

		if ($res < length $buffer) {
			do_write($fh, substr($buffer, $res));
		} else {
			do_read($fh);
		}
	});
}

$ring->accept($listener, 0, sub($res, $flags) {
	if ($res < 0) {
		$! = -$res;
		die "Could not accept: $!";
	}

	open my $fh, '+<&=', $res or die "Could not open new handle";

	do_read($fh);
});

$ring->run_once while 1;
