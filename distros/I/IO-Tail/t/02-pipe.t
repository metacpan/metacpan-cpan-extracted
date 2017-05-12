#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday usleep);

use IO::Tail;

plan tests => 5 + 10 + 22 + 5;

&test_handle_add_remove; # 5.
&test_pipe_close; # 10.
&test_pipe_tests; # 22
&test_pipe_closed; # 5

sub test_handle_add_remove
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	my $handle = \*STDIN;
	$tail->add($handle, sub{ die "not reach here" });
	pass('add($handle)');
	
	ok($tail->check(), 'check results something exists');
	
	$tail->remove($handle);
	ok(!$tail->check(), 'check results nothing exists');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	my $elapsed = sprintf('%.2f', $ed-$st);
	cmp_ok($elapsed, '<', '0.1', 'loop returns immediately');
	
	alarm(0);
}

sub test_pipe_close
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	ok(pipe(my $rd, my $wr), 'pipe(2)');
	
	$tail->add($rd, sub{
		my $ref = shift;
		my $eof = shift;
		isa_ok($ref, 'SCALAR', '$ref is SCALARREF');
		is($$ref, '', '$$ref is empty string');
		ok($eof, '$eof is tuened on');
	});
	pass('add($rd)');
	
	ok($tail->check(), 'check results something exists');
	
	my $pid = fork();
	if( !defined($pid) )
	{
		die "fork: $!";
	}
	if( !$pid )
	{
		# child.
		close($rd);
		close($wr);
		exit;
	}
	pass('fork');
	
	close $wr;
	pass('close $wr');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	cmp_ok($ed-$st, '<', '0.1', 'loop returns immediately');
	
	alarm(0);
}


sub test_pipe_tests
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	ok(pipe(my $rd, my $wr), 'pipe');
	
	my $iter = 0;
	$tail->add($rd, sub{
		my $ref = shift;
		my $eof = shift;
		++$iter;
		isa_ok($ref, 'SCALAR', "[$iter] \$ref is SCALARREF");
		if( $iter<=3 )
		{
			my ($match) = $$ref =~ /^(\d+\.\d+)\/\z/;
			ok($match, "[$iter] \$\$ref has valid data (gettimeofday)");
			my $just_now = gettimeofday();
			my $delay = sprintf('%.2f',$just_now - $match);
			cmp_ok($delay, '<=', '0.25', "few delay ($delay<=0.25)");
			is($eof, undef, "[$iter] \$eof is tuened off");
			$$ref = '';
		}else
		{
			is($$ref, '', '$$ref is empty string');
			is($eof, 'eof', "[$iter] \$eof is tuened on");
		}
		$ref;
	});
	pass('add($rd)');
	
	ok($tail->check(), 'check results something exists');
	
	my $pid = fork();
	if( !defined($pid) )
	{
		die "fork: $!";
	}
	if( !$pid )
	{
		# child.
		close($rd);
		_child($wr);
		exit;
	}
	pass('fork');
	
	close $wr;
	pass('close $wr');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	cmp_ok($ed-$st, '<', '1.5', 'loop returns immediately');
}

sub _child
{
	my $wr = shift;
	select((select($wr),$|=1)[0]);
	for my $i (1..3)
	{
		print $wr gettimeofday."/";
		usleep(300*1000); # 0.3 sec.
	}
	close($wr);
	exit;
}

sub test_pipe_closed
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	ok(pipe(my $rd, my $wr), 'pipe(2)');
	
	$tail->add($rd, sub{ die "not reach here" });
	pass('add($rd)');
	
	ok($tail->check(), 'check results something exists');
	
	close($rd);
	close($wr);
	
	my $ret = eval{
		local($SIG{__WARN__})=sub{}; # avoid "sysread() on closed filehandle" warning.
		$tail->check();
	};
	my $err = $@;
	like($err, qr/^sysread: /, 'raise: Bad file descriptor');
	
	alarm(0);
}

