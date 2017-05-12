#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
use Devel::Chitin::Location;

unless (has_callsite) {
    print "# SKIP - Devel::Callsite not available\n";
}

run_test(
    has_callsite() ? 4 : undef,
    sub {
        for ( 1 .. 2 ) {
            $DB::single=1;
            22;
        }
        $DB::single=1; 24; $DB::single=1; 24;
    },
    \&set_loop_callsite,
    'continue',
    \&check_loop_callsite,
    'continue',
    \&set_sequential_callsite,
    'continue',
    \&check_sequential_callsite,
    'done',
);

my $loop_callsite;
sub set_loop_callsite {
    my($db,$loc) = @_;
    Test::More::ok($loop_callsite = $loc->callsite, 'Getting callsite inside loop');
}

sub check_loop_callsite {
    my($db,$loc) = @_;
    Test::More::is($loc->callsite, $loop_callsite, 'In loop, callsite is the same');
}

my $seq_callsite;
sub set_sequential_callsite {
    my($db,$loc) = @_;
    Test::More::ok($seq_callsite = $loc->callsite, 'Getting callsite in sequential statement');
}

sub check_sequential_callsite {
    my($db,$loc) = @_;
    Test::More::isnt($loc->callsite, $seq_callsite, 'In sequential statements, callsite is different');
}
