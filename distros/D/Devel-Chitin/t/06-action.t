#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    4,
    sub { $DB::single=1;
        my $a = 1;
        13;
        Test::More::is($a, 2, 'Action changed the value of $a to 2');
        $DB::single=1;
        14;
    },
    \&create_action,
    'continue',
    'done',
);
    
sub create_action {
    my($db, $loc) = @_;
    Test::More::ok(Devel::Chitin::Action->new(
            file => $loc->filename,
            line => 13,
            code => 'Test::More::ok(1, "action fired"); $a++',
        ), 'Set action on line 13');
    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 13,
            code => 'Test::More::ok(1, "Inactive action not fired"); $a++',
            inactive => 1,
        ), 'Set inactive action also on line 13');
}

