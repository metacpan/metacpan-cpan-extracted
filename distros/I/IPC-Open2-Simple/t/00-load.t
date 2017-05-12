#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('IPC::Open2::Simple', 'open2s') || print "Bail out!\n";
}

diag( "Testing IPC::Open2::Simple $IPC::Open2::Simple::VERSION, Perl $], $^X" );

SKIP: {
	skip 'not on a unix system', 2, if not -x '/bin/cat';

	my $input = "IPC::Open2 is too hard!\n";
	my $ret = open2s(\my $output, \$input, '/bin/cat');

	is $ret,    0,      'return code 0';
	is $output, $input, 'output is as expected';
}
