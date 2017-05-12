use strict;

my $test;

BEGIN {$test = 0; print "1..8 \n";}

package one;
use Function::ID;
sub bone
{
    $test++;
    print "not " if $this_fn ne 'bone';
    print "ok $test - one::bone short\n";

    $test++;
    print "not " if $this_function ne 'one::bone';
    print "ok $test - one::bone long\n";
}

$test++;
print "not " if defined $this_fn;
print "ok $test - one, outside function, short form\n";

$test++;
print "not " if  defined $this_function;
print "ok $test - one, outside function, long form\n";


package main;
use Function::ID;

sub sinew
{
    $test++;
    print "not " if $this_fn ne 'sinew';
    print "ok $test - main::sinew short\n";

    $test++;
    print "not " if $this_function ne 'main::sinew';
    print "ok $test - main::sinew long\n";
}

$test++;
print "not " if defined $this_fn;
print "ok $test - main, outside function, short form\n";

$test++;
print "not " if defined $this_function;
print "ok $test - main, outside function, long form\n";

one::bone;

$test++;
eval { $this_fn = 'bite me' };
print "not " if substr($@,0,29) ne 'Attempt to assign to $this_fn';
print "ok $test - illegal store (short)\n";

$test++;
eval { $this_function = 'no no no' };
print "not " if substr($@,0,35) ne 'Attempt to assign to $this_function';
print "ok $test - illegal store (long)\n";
