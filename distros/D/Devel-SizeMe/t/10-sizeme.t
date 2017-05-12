#!/usr/bin/perl -w

use strict;
use Test::More;

use Devel::SizeMe qw(size total_size perl_size heap_size);

# the main purpose of this test is to run perl_size and heap_size
# to see if they crash when trawling through the guts of the interpreter

my $datfile = "test_sizeme.dat";
my $data = [ ({foo=>42}) x 2 ];

$ENV{SIZEME} = $datfile;

unlink $datfile;
ok size($data), 'run size';
ok -s $datfile;

ok unlink $datfile;
ok total_size($data), 'run total_size';
ok -s $datfile, 'wrote file file, size '.-s($datfile);

ok unlink $datfile;
ok perl_size(), 'run perl_size';
ok -s $datfile, 'wrote file file, size '.-s($datfile);

ok unlink $datfile;
ok heap_size(), 'run heap_size';
ok -s $datfile, 'wrote file file, size '.-s($datfile);

ok unlink $datfile;

done_testing();
