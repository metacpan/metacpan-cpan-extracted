#!/usr/bin/perl

sub simple_reducer {
    dbroweval('--nolog', '-m', 
	'-b' => 'my $count = 0; @out_args = (-cols =>[qw(n)]);',
	'-e' => '$ofref = [ $count ];',
	' $count++; ');
}
