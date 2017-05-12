#!/usr/bin/perl

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
    my $e = Exception::Base->catch;
    if ($e->matches('2')) {
        print "*** caught 2\n";
    }
    elsif ($e->isa('Exception::My')) {
        print "*** caught 3\n";
    }
    elsif ($e->matches(qr/Message/)) {
        print "*** caught 1\n";
    }
    else {
        print "*** caught unknown 4\n";
    };
}
else {
    print "*** no exception 0\n";
};

sub do_something {
    my ($what) = @_;
    print "*** do_something($what)\n";
    if ($what == 1) {
        Exception::Base->throw( message => 'Message', value => 1 );
    }
    elsif ($what == 2) {
        Exception::My->throw( value => 2 );
    }
    elsif ($what == 3) {
        Exception::My->throw;
    }
    elsif ($what == 4) {
        Exception::Base->throw;
    };
};
