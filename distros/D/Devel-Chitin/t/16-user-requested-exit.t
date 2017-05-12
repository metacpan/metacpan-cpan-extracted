#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();

$DB::single=1;
12;
13;
14;

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';

use Test::Builder;
BEGIN {
    if (Devel::Chitin::TestRunner::is_in_test_program()) {
        our $tb = Test::Builder->new();
        $tb->plan(tests => 3);
        # We're testing that the Debugger's END block is run correctly
        # which interferes with the way Test::Builder reports retsults.
        # This hack disables Test::Builder's reporting in its own END block.
        # We'll call it's reporting mechanism in the final test function
        $tb->no_ending(1);
    }
}

sub notify_stopped {
    my($db, $loc) = @_;
    our $tb;

    my $ok = $loc->filename eq __FILE__
            and
            $loc->line == 12;
    $tb->ok($ok, 'Stopped on line 12');

    $tb->ok($db->user_requested_exit(), 'set user_requested_exit');

    $db->continue;
}

sub notify_program_exit {
    our $tb;
    $tb->ok(1, 'in notify_program_exit');

    # Here's where we make Test::Builder report results
    $tb->no_ending(0);
    $tb->_ending();
}

sub notify_program_terminated {
    our $tb;
    $tb->ok(0, 'notify_program_terminated not called');
    exit;
}
