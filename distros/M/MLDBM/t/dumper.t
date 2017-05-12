#!/usr/bin/perl -w
use Fcntl;
use MLDBM;
use Data::Dumper;
use MLDBM;

use strict;

tie my %o, 'MLDBM', 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
print "1..4\n";

my $c_scalar = 'c';
my $c = [\$c_scalar];
$b = {};
$a = [1, $b, $c];
$b->{a} = $a;
$b->{b} = $a->[1];
$b->{c} = $a->[2];
@o{qw(a b c)} = ($a, $b, $c);
$o{d} = "{once upon a time}";
$o{e} = 1024;
$o{f} = 1024.1024;

my $struct = [@o{qw(a b c)}];
my $first_compare = &MLDBM::_compare([ $a, $b, $c ], $struct);

if ($first_compare) { print "ok 1\n" }
else { print "not ok\n" }
print ($o{d} eq "{once upon a time}" ? "ok 2\n" : "# |$o{d}|\nnot ok 2\n");
print ($o{e} == 1024 ? "ok 3\n" : "# |$o{e}|\nnot ok 3\n");
print ($o{f} eq 1024.1024 ? "ok 4\n" : "# |$o{f}|\nnot ok 4\n");

