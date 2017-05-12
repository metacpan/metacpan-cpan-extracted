use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;

use List::Gather;

sub assert_void_context {
    die 'not in void context'
        if defined wantarray;
}

is exception {
    my @x = gather { assert_void_context };
}, undef;

is exception {
    my $x = gather { assert_void_context };
}, undef;

is exception {
    no warnings 'void';
    gather { assert_void_context };
    42;
}, undef;

done_testing;
