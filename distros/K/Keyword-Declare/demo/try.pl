#! /usr/bin/env perl

use 5.012;
use warnings;
use lib qw< dlib ../dlib >;

use Perl6::Try;

try {
    my $x = rand;
    say 'Okay at line ', __LINE__;
    something_fatal();

    CATCH ($error) {
        say 'Not so good at line ', __LINE__;
        when (/oops/) { say "Accidental $error\nx: $x"       }
        when (/argh/) { say "Serious $error\nx: $x"          }
        default       { say "Something bad: $error\nx: $x" }
    }
}


sub something_fatal {
    die +('oops!', 'argh?', 'phew!')[rand 3];
}
