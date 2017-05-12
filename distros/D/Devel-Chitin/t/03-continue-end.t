#!/usr/bin/env perl
use strict;
use warnings; no warnings qw(void once);

run_in_debugger();

7;
$DB::single=1;
9;
10;
11;


sub run_in_debugger {
    if ($ARGV[0] and $ARGV[0] eq '--test') {
        attach_debugger_and_run();
    } else {
        my $rv = system($^X, '-Ilib', '-It/lib', '-d:Chitin::NullDB', __FILE__, '--test');
        if ($? == -1) {
            die "Couldn't start test in debugger mode: $!";
        }
        exit;
    }
}

my $tb;
sub attach_debugger_and_run {
    Devel::Chitin::TestDB->attach();
    require Test::Builder;
    $tb = Test::Builder->new();
    $tb->plan(tests => 6);
    # We're testing that the Debugger's END block is run correctly
    # which interferes with the way Test::Builder reports retsults.
    # This hack disables Test::Builder's reporting in its own END block.
    # We'll call it's reporting mechanism in the final test function
    $tb->no_ending(1);
}


package Devel::Chitin::TestDB;
BEGIN { our @ISA = qw( Devel::Chitin ) }

my @tests; BEGIN { @tests = (
    \&test_1,
    \&test_2,
    \&test_3,
);
}

sub execute_test {
    my $next = shift @tests;
    if ($next) {
        $next->(@_);
    } else {
        $tb->ok(0, 'Out of tests');
    }
}
sub notify_stopped {
    execute_test(@_);
}
sub notify_program_terminated {
    execute_test(@_);
}


sub test_1 {
    my($self, $loc) = @_;

    $tb->is_eq($loc->line, 9, 'Stopped on line 9, breakpoint in code');
    $tb->ok(! $loc->at_end, 'Not at the end of the program');
    $tb->ok($self->continue(), 'continue');
}

sub test_2 {
    my($self, $exit_code) = @_;
    $tb->ok(! $exit_code, 'exit code is 0');
}

sub test_3 {
    my($self, $loc) = @_;

    $tb->ok(($loc->subroutine eq 'Devel::Chitin::exiting::at_exit'),
            'in the "at_exit" subroutine');
    $tb->ok($loc->at_end, 'At the end of the program');

    $tb->finalize;

    # Here's where we make Test::Builder report results
    $tb->no_ending(0);
    $tb->_ending();
}

