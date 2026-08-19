#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::EventLoop.
#
# The tests drive the loop with pipes, and they assert order and
# counts rather than wall-clock times. A test machine under load runs
# a 50 ms timer late, and that is not a defect.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use Time::HiRes ();

use_ok('Fugu::EventLoop');
use_ok('Fugu::Signal');

# pipe_pair(): a reader and a writer, both unbuffered
sub pipe_pair ()
{
	pipe my $reader, my $writer or die "pipe: $!";
	$writer->autoflush(1);
	return ( $reader, $writer );
}

# drain($fh): every byte that arrived, with no buffering
#
#	A select loop must not use a buffered read. The buffer can take
#	more bytes than the callback consumes, and then the descriptor
#	is not readable again and the rest is never served.
sub drain ($fh)
{
	my $data = '';
	sysread( $fh, $data, 4096 );
	return $data;
}

subtest 'a descriptor dispatches to its callback' => sub {
	my $loop = Fugu::EventLoop->new;
	my ( $reader, $writer ) = pipe_pair();

	my @got;
	$loop->add_fd(
		$reader,
		read => sub ($fh) {
			push @got, drain($fh);
			$loop->stop if @got == 2;
		} );

	ok( !$loop->is_running, 'the loop is not running yet' );

	# A backstop, so a broken dispatch fails the test, not hangs it
	$loop->after( 5, sub { $loop->stop } );

	print {$writer} 'one';
	$loop->after( 0.02, sub { print {$writer} 'two' } );
	$loop->run;

	is_deeply( \@got, [ 'one', 'two' ], 'both writes arrived' );
	ok( !$loop->is_running, 'run returned with the loop stopped' );

	$loop->remove_fd($reader);
};

subtest 'a second add_fd replaces the callback' => sub {
	my $loop = Fugu::EventLoop->new;
	my ( $reader, $writer ) = pipe_pair();

	my ( $first, $second ) = ( 0, 0 );
	$loop->add_fd( $reader, read => sub ($) { $first++ } );
	$loop->add_fd(
		$reader,
		read => sub ($fh) {
			$second++;
			drain($fh);
			$loop->stop;
		} );
	$loop->after( 5, sub { $loop->stop } );

	print {$writer} 'x';
	$loop->run;

	is( $first,  0, 'the replaced callback does not run' );
	is( $second, 1, 'and the new one runs once' );
};

subtest 'after runs one time, every keeps running' => sub {
	my $loop = Fugu::EventLoop->new;

	my ( $once, $many ) = ( 0, 0 );
	$loop->after( 0.01, sub { $once++ } );
	$loop->every(
		0.01,
		sub {
			$many++;
			$loop->stop if $many >= 4;
		} );

	$loop->run;

	is( $once, 1, 'after ran exactly one time' );
	cmp_ok( $many, '>=', 4, 'every kept running' );
};

subtest 'timers run in deadline order' => sub {
	my $loop = Fugu::EventLoop->new;

	my @order;
	$loop->after( 0.05, sub { push @order, 'late' } );
	$loop->after( 0.01, sub { push @order, 'early' } );
	$loop->after(
		0.09,
		sub {
			push @order, 'last';
			$loop->stop;
		} );

	$loop->run;

	is_deeply( \@order, [qw(early late last)],
		'the nearest deadline runs first' );
};

subtest 'cancel drops a timer before it runs' => sub {
	my $loop = Fugu::EventLoop->new;

	my $ran = 0;
	my $handle = $loop->after( 0.02, sub { $ran++ } );
	$loop->after( 0.06, sub { $loop->stop } );

	is( $loop->cancel($handle), 1, 'cancel reports the removal' );
	is( $loop->cancel($handle), 0, 'and a second cancel finds nothing' );

	$loop->run;
	is( $ran, 0, 'the cancelled timer never ran' );
};

subtest 'a repeating timer can cancel itself' => sub {
	my $loop = Fugu::EventLoop->new;

	my $count = 0;
	my $handle;
	$handle = $loop->every(
		0.01,
		sub {
			$count++;
			$loop->cancel($handle);
		} );
	$loop->after( 0.10, sub { $loop->stop } );

	$loop->run;
	is( $count, 1, 'it ran one time and then stopped itself' );
};

subtest 'run returns when nothing is left to wait for' => sub {
	my $loop = Fugu::EventLoop->new;

	# No descriptor and no timer. A loop with nothing to wait for
	# would otherwise spin until the process is killed.
	my $start = Time::HiRes::time();
	$loop->run;
	my $elapsed = Time::HiRes::time() - $start;

	ok( $elapsed < 2, 'an empty loop returns at once' )
	    or diag("took ${elapsed}s");

	# The same holds after the last timer fires
	my $second = Fugu::EventLoop->new;
	my $ran    = 0;
	$second->after( 0.01, sub { $ran++ } );
	$second->run;
	is( $ran, 1, 'the last timer ran' );
	ok( !$second->is_running, 'and then the loop returned' );
};

subtest 'an interrupt flag ends the loop' => sub {

	my $signal = Fugu::Signal->new;
	$signal->setup_interrupt_flag('USR2');

	my $loop = Fugu::EventLoop->new( signal => $signal );

	# The loop must have something to wait for, or it would return
	# for that reason and prove nothing
	my $ticks = 0;
	$loop->every( 0.01, sub { $ticks++ } );
	$loop->after( 0.03, sub { kill 'USR2', $$ } );

	# A backstop, so a broken interrupt path fails the test instead
	# of hanging it
	$loop->after( 5, sub { $loop->stop } );

	$loop->run;

	ok( $signal->interrupted, 'the manager saw the signal' );
	ok( !$loop->is_running,   'and the loop ended' );
	cmp_ok( $ticks, '>=', 1, 'it ran until then' );

	$signal->restore;
};

subtest 'a callback that dies does not stop the loop' => sub {
	my $loop = Fugu::EventLoop->new;

	my $after_the_death = 0;
	$loop->after( 0.01, sub { die "callback failed\n" } );
	$loop->after(
		0.04,
		sub {
			$after_the_death++;
			$loop->stop;
		} );

	# The loop reports through the default logger. Point that at
	# standard error and capture it, so the test reads what an
	# operator would see.
	Fugu::TestLog->stderr('error');
	my $captured = '';
	{
		open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
		close STDERR;
		open STDERR, '>', \$captured or die "reopen STDERR: $!";

		$loop->run;

		close STDERR;
		open STDERR, '>&', $saved or die "restore STDERR: $!";
	}
	Fugu::TestLog->quiet;

	is( $after_the_death, 1, 'the loop kept running' );
	like( $captured, qr/died: callback failed/,
		'and the reason reached the log' );
};

subtest 'descriptors and timers share one loop' => sub {
	my $loop = Fugu::EventLoop->new;
	my ( $reader, $writer ) = pipe_pair();

	my ( $reads, $ticks ) = ( 0, 0 );
	$loop->add_fd(
		$reader,
		read => sub ($fh) {
			drain($fh);
			$reads++;
		} );
	$loop->every(
		0.02,
		sub {
			$ticks++;
			print {$writer} 'tick' if $ticks == 1;
			$loop->stop if $ticks >= 3;
		} );

	$loop->run;

	is( $reads, 1, 'the descriptor was served' );
	cmp_ok( $ticks, '>=', 3, 'and the timer kept its schedule' );
};

subtest 'bad arguments are programming errors' => sub {
	my $loop = Fugu::EventLoop->new;
	my ( $reader, $writer ) = pipe_pair();

	ok( !eval { $loop->add_fd($reader); 1 }, 'add_fd needs a callback' );
	ok( !eval { $loop->every( 0.1, 'not code' ); 1 },
		'a timer needs a callback' );
	ok( !eval { $loop->after( 0, sub { } ); 1 },
		'a timer needs a positive interval' );
	ok( !eval { $loop->every( -1, sub { } ); 1 },
		'and not a negative one' );

	is( $loop->cancel(undef), 0, 'cancel of nothing is not an error' );
	is( $loop->cancel(9999),  0, 'nor is cancel of an unknown handle' );
};

done_testing();
