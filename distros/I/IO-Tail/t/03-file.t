#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday usleep);
use File::Temp qw(tempfile);

use IO::Tail;

plan tests => 23 + 9;

our $FILE;

&test_file_tests; # 23
&test_file_stdin; # 9

END{
	$FILE and unlink($FILE);
}

sub test_file_tests
{
	alarm(3);
	
	(my $fh, $FILE) = tempfile( "tmp.XXXXXX", SUFFIX=>".txt", UNLINK=>1 );
	select((select($fh),$|=1)[0]);
	pass("tempfile: $FILE");
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	my $iter = 0;
	$tail->add($FILE, sub{
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
			is($iter, 4, "[$iter] last iteration.");
			is($$ref, 'EXIT', "[$iter] \$\$ref is EXIT marker");
			is($eof, undef, "[$iter] \$eof is still tuened off");
			$$ref = '';
			$tail->remove($FILE);
			return; # quit.
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
		_child($fh);
		exit;
	}
	pass('fork');
	
	close $fh;
	pass('close $fh');
	
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
	print $wr "EXIT";
	close($wr);
	exit;
}


sub test_file_stdin
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	$tail->add('-', sub{ die "not reach here" });
	pass('add("-")');
	ok($tail->check(), 'check results something exists');
	
	$tail->remove(\*STDIN);
	pass('remove(STDIN)');
	ok(!$tail->check(), 'check results nothing exists');
	
	$tail->add(\*STDIN, sub{ die "not reach here" });
	pass('add(STDIN)');
	ok($tail->check(), 'check results something exists');
	
	$tail->remove('-');
	pass('remove("-")');
	ok(!$tail->check(), 'check results nothing exists');
	
	alarm(0);
}
