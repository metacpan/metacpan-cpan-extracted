#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();

$DB::single=1;
die "untrapped";
11;
exit;

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';

BEGIN {
    our @expected_order = (
        [   line => 12,
            'step'
        ],
        [   exception => 'untrapped at ' . __FILE__ . " line 12.\n",
            line => 12,
            'done',
        ],
    );
}

my $uncaught_exception;
sub notify_uncaught_exception {
    my($db, $exception) = @_;

    $? = 0;
    $uncaught_exception = $exception;
    perform_test($db, $exception);
}

sub notify_stopped {
    my($db, $location) = @_;
    perform_test($db, $location);
}

sub perform_test {
    my($db, $location) = @_;

    our $tb;
    unless ($tb) {
        require Test::Builder;
        $tb = Test::Builder->new();
        $tb->plan( tests => 3 );
        # We're testing that the Debugger's END block is run correctly
        # which interferes with the way Test::Builder reports retsults.
        # This hack disables Test::Builder's reporting in its own END block.
        # We'll call it's reporting mechanism in the final test function
        $tb->no_ending(1);
    }

    our @expected_order;
    my $next_test = shift @expected_order;
    while (@$next_test) {
        my $cmd = shift @$next_test;
        if ($cmd eq 'line') {
            my $expected_line = shift @$next_test;
            $tb->is_num($location->line, $expected_line, "At line $expected_line");

        } elsif ($cmd eq 'exception') {
            my $expected_exception = shift @$next_test;
            $tb->is_eq($expected_exception, $location->exception, "Got exception: $expected_exception");

        } elsif ($cmd eq 'step') {
            $db->step;

        } elsif ($cmd eq 'done') {
            # Here's where we make Test::Builder report results
            $tb->no_ending(0);
            $tb->_ending();

        } else {
            $tb->ok(0, "unknown command $cmd");
        }
    }
}
