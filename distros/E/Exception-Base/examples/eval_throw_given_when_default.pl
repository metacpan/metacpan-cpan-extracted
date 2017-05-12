#!/usr/bin/perl

use 5.010;

use lib 'lib', '../lib';

use strict;
use warnings;

use Exception::Base
    'Exception::My';

my $what = @ARGV ? $ARGV[0] : int rand 5;

eval {
    do_something($what);
};
if ($@) {
    given(my $e = Exception::Base->catch) {
        when ($e->matches('2')) {
            say "*** caught 2";
        }
        when ($e->isa('Exception::My')) {
            say "*** caught 3";
        }
        when ($e->matches(qr/Message/)) {
            say "*** caught 1";
        }
        default {
            say "*** caught unknown 4";
        }
    };
}
else {
    say "*** no exception 0";
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
