#!/usr/bin/env perl

use strict;
use Test::More 'no_plan';

{
    package Dummy::DeleteTest;

    use Method::Cached;

    sub echo :Cached(0, LIST) {
        my ($a, $b) = @_;
        sprintf '%s-%s %s', $a, $b, rand;
    }
}

{
    use Method::Cached::Manager;

    # use Dummy::DeleteTest;
    Dummy::DeleteTest->import;

    my $param1 = rand;
    my $param2 = rand;
    
    my $value1 = Dummy::DeleteTest::echo($param1, $param2);
    my $value2 = Dummy::DeleteTest::echo($param1, $param2);
    
    Method::Cached::Manager->delete('Dummy::DeleteTest::echo', $param1, $param2);
    
    my $value3 = Dummy::DeleteTest::echo($param1, $param2);

    is   $value1, $value2;
    isnt $value1, $value3;
}
