#!/usr/bin/env perl
# Tests when we're used in conjunction with a debugger
use strict; use warnings;
use Test::More;
use Devel::Callsite;

note('Tests related to using when $^P = 1');

BEGIN {
    if ($^P != 0) {
	print "1..0 # SKIP This test can't be run under any sort of debugger\n";
	exit 0;
    }
}


my $threads;
BEGIN { $threads = eval "use threads; 1" }

our $db_called = 0;
BEGIN {
    package DB;
    no strict "refs";

    # DB::sub must be defined in a BEGIN block with $^P = 1 or 5.6
    # doesn't start using it properly. (Why I'm making this work on 5.6
    # I'm not entirely sure, but there we are.)
    local $^P = 1;
    no warnings 'redefine';
    sub sub { $db_called++; &$DB::sub; }
    sub db3 { Devel::Callsite::callsite(1) }
}

sub db1 { callsite(1) }
sub db2 {
    BEGIN { $^P = 1 }
    my @db = (callsite(), db1());
    BEGIN { $^P = 0 }
    callsite(), @db, db1();
}

$db_called = 0;
my @db = db2();
is $db_called, 2, "Sanity check (DB::sub was called)";
is $db[1], $db[0], "Calls with DB::sub";
is $db[2], $db[0], "Nested calls with DB::sub";
is $db[3], $db[0], "Nested calls with and without DB::sub";

sub db4 { callsite(), DB::db3() }

$db_called = 0;
my @db4 = db4();
is $db_called, 0, "Sanity check (DB::sub was not called)";
is @db4, 3, "Call from DB returns 2 values";
is $db4[1], $db4[0], "First value is the same (no DB::sub)";
is $db4[2], $db4[0], "Second value is the same (no DB::sub)";

$db_called = 0;
BEGIN { $^P = 1 }
my @db5 = db4();
BEGIN { $^P = 0 }
is $db_called, 1, "Sanity check (DB::sub was called)";
is @db5, 3, "Call from DB with DB::sub returns 2 values";
is $db5[1], $db5[0], "First value is the same (with DB::sub)";
isnt $db5[2], $db5[0], "Second value is different (with DB::sub)";

if ($threads) {
    my $parent = context();
    ok($parent > 0, "Valid context in initial thread");

    # quoted to avoid a warning on 5.6
    my $child = "threads"->new(sub { context() })->join;
    ok($child > 0, "Valid context in child thread");

    ok($parent != $child, "Parent and child contexts are different");
}
else {
    ok(context() > 0, "Valid context call");
}

done_testing;
