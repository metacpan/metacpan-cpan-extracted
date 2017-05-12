#!/usr/bin/env perl

use strict;
use Test::More 'no_plan';

{
    package Dummy::HashArgs;

    use Method::Cached;

    sub echo :Cached(0, HASH) {
        my (%args) = @_;
        sprintf 'param1-%s param2-%s %s',
            (defined $args{param1} ? $args{param1} : q{}),
            (defined $args{param2} ? $args{param2} : q{}),
            rand;
    }
}

{
    # use Dummy::HashArgs;
    Dummy::HashArgs->import;

    my $param1 = rand;
    my $param2 = rand;

    my %params = (
        param1 => $param1,
        param2 => $param2,
    );

    my $value1 = Dummy::HashArgs::echo(%params);
    my $value2 = Dummy::HashArgs::echo(%params);

    delete $params{param2};

    my $value3 = Dummy::HashArgs::echo(%params);

    $params{param2} = undef;

    my $value4 = Dummy::HashArgs::echo(%params);

    $params{param2} = $param2;

    my $value5 = Dummy::HashArgs::echo(%params);

    $params{param3} = 1;

    my $value6 = Dummy::HashArgs::echo(%params);

    is   $value1, $value2;
    isnt $value1, $value3;
    isnt $value1, $value4;
    is   $value1, $value5;
    isnt $value1, $value6;
}
