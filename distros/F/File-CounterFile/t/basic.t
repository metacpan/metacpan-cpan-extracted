#!/usr/bin/perl -w

print "1..1\n";

use strict;
use File::CounterFile;

my $cf = "./zz-counter-$$";  # the name for out temprary counter

# Test normal object creation and increment

unlink $cf;
my $c = new File::CounterFile $cf;

my $id1 = $c->inc;
my $id2 = $c->inc;

$c = new File::CounterFile $cf;
my $id3 = $c->inc;
my $id4 = $c->dec;

die "test failed" unless ($id1 == 1 && $id2 == 2 && $id3 == 3 && $id4 == 2);
unlink $cf or die "Can't unlink $cf: $!";

# Test magic increment

$id1 = (new File::CounterFile $cf, "aa98")->inc;
$id2 = (new File::CounterFile $cf)->inc;
$id3 = (new File::CounterFile $cf)->inc;

eval {
    # This should now work because "Decrement is not magical in perl"
    $c = new File::CounterFile $cf; $id4 = $c->dec; $c = undef;
};
die "test failed (No exception to catch)" unless $@;

#print "$id1 $id2 $id3\n";

die "test failed" unless ($id1 eq "aa99" && $id2 eq "ab00" && $id3 eq "ab01");
unlink $cf or die "Can't unlink $cf: $!";

# Test operator overloading

$c = new File::CounterFile $cf, "100";

$c->lock;

$c++;  # counter is now 101
$c++;  # counter is now 102
$c++;  # counter is now 103
$c--;  # counter is now 102 again

$id1 = "$c";
$id2 = ++$c;

$c = undef;  # destroy object

unlink $cf;

die "test failed" unless $id1 == 102 && $id2 == 103;

print "# Selftest for File::CounterFile $File::CounterFile::VERSION ok\n";
print "ok 1\n";
