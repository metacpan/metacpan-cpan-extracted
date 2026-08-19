#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::Signal');

# Test basic object creation
{
	my $sig = Fugu::Signal->new;
	ok( defined $sig, 'Signal handler created' );
	isa_ok( $sig, 'Fugu::Signal' );
}

# Test interrupt flag
{
	ok( !Fugu::Signal::check_interrupted(),
		'Not interrupted initially' );
}

# Test signal handler setup and restore
{
	my $sig = Fugu::Signal->new;

	my $original_int = $SIG{INT} // 'DEFAULT';
	$sig->setup_interrupt_flag('INT');

	isnt( $SIG{INT}, $original_int, 'INT handler changed' );

	$sig->restore;
	my $restored = $SIG{INT} // 'DEFAULT';
	is( $restored, $original_int, 'INT handler restored' );
}

# Test interrupt flag setting
{
	my $sig = Fugu::Signal->new;
	$sig->setup_interrupt_flag('USR1');

	ok( !$sig->interrupted, 'Not interrupted before signal' );

	kill 'USR1', $$;
	sleep 0.1;    # Give the signal time to arrive

	ok( $sig->interrupted, 'Interrupted after signal' );
	ok( Fugu::Signal::check_interrupted(),
		'The package function sees it too' );

	$sig->reset_interrupted;
	ok( !$sig->interrupted, 'reset_interrupted clears the flag' );

	$sig->restore;
}

# Test automatic restoration on DESTROY
{
	my $original_usr1 = $SIG{USR1};

	{
		my $sig = Fugu::Signal->new;
		$sig->setup_interrupt_flag('USR1');
		isnt( $SIG{USR1}, $original_usr1,
			'USR1 handler changed in scope' );
	}

	is( $SIG{USR1}, $original_usr1,
		'USR1 handler restored after scope exit' );
}

# Test interrupt flag with multiple signals
{
	my $sig = Fugu::Signal->new;
	$sig->setup_interrupt_flag( 'USR1', 'USR2' );

	kill 'USR2', $$;
	sleep 0.1;

	ok( $sig->interrupted, 'Interrupted by second signal' );

	$sig->restore;
}

# Two managers do not share state. Each one owns its interrupt flag.
{
	my $first  = Fugu::Signal->new;
	my $second = Fugu::Signal->new;

	$first->setup_interrupt_flag('USR1');
	kill 'USR1', $$;
	sleep 0.1;

	ok( $first->interrupted, 'the manager that caught it is interrupted' );
	ok( !$second->interrupted, 'the other manager is not' );

	$first->restore;
}

# A destroyed manager leaves no entry behind for check_interrupted
{
	{
		my $sig = Fugu::Signal->new;
		$sig->setup_interrupt_flag('USR2');
		kill 'USR2', $$;
		sleep 0.1;
		ok( Fugu::Signal::check_interrupted(), 'the flag is set' );
		$sig->restore;
	}
	ok( !Fugu::Signal::check_interrupted(),
		'the flag goes with the manager' );
}

done_testing();
