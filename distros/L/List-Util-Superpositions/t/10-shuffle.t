#!./perl

use List::Util::Superpositions qw(shuffle);

print "1..5\n";

my @r;

@r = shuffle();
print "not " if @r;
print "ok 1\n";

@r = shuffle(9);
print "not " unless @r == 1 and $r[0] = 9;
print "ok 2\n";

my @in = 1..100;
@r = shuffle(@in);
print "not " unless @r == @in;
print "ok 3\n";

print "not " if join("",@r) eq join("",@in);
print "ok 4\n";

print "not " if join("",sort { $a <=> $b } @r) ne join("",@in);
print "ok 5\n";
