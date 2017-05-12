#!/usr/bin/perl

use 5.010;

use lib 'lib', '../lib';

use strict;
use warnings;

use Exception::Base
    'Exception::My';

use TryCatch;

my $what = @ARGV ? $ARGV[0] : int rand 5;

try {
    do_something($what);
    say "*** no exception 0";
}
catch ($e where { $_->matches('2') }) {
    say "*** caught 2";
}
catch ($e where { $_->isa('Exception::My') }) {
    say "*** caught 3";
}
catch ($e where { $_->matches(qr/Message/) }) {
    say "*** caught 1";
}
catch {
    say "*** caught unknown 4";
};

sub do_something {
    my ($what) = @_;
    say "*** do_something($what)";
    given ($what) {
        when (1) {
            Exception::Base->throw( message => 'Message', value => 1 );
        }
        when (2) {
            Exception::My->throw( value => 2 );
        }
        when (3) {
            Exception::My->throw;
        }
        when (4) {
            Exception::Base->throw;
        }
    };
};
