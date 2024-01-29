#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use_ok 'Geography::States::Borders';

subtest invalid => sub {
    like(
        exception { Geography::States::Borders->new(country => 123) },
        qr/is not valid/,
        'constructor dies with invalid country',
    );
    my $obj = new_ok 'Geography::States::Borders' => [
        country => 'narnia',
    ];
    is $obj->country, 'narnia', 'country';
    like(
        exception { $obj->borders },
        qr/object method/,
        'borders dies with invalid country',
    );
};

subtest australia => sub {
    my $obj = new_ok 'Geography::States::Borders' => [
        country => 'australia',
    ];
    is $obj->country, 'australia', 'country';
    my $got = $obj->borders;
    is_deeply $got->{TAS}, [], 'TAS borders';
    is_deeply $got->{QLD}, [qw(NSW SA NT)], 'QLD borders';
};

subtest brazil => sub {
    my $obj = new_ok 'Geography::States::Borders' => [
        country => 'brazil',
    ];
    is $obj->country, 'brazil', 'country';
    my $got = $obj->borders;
    is_deeply $got->{RS}, ['SC'], 'RS borders';
    is_deeply $got->{RJ}, [qw(SP MG ES)], 'RJ borders';
};

subtest canada => sub {
    my $obj = new_ok 'Geography::States::Borders' => [
        country => 'canada',
    ];
    is $obj->country, 'canada', 'country';
    my $got = $obj->borders;
    is_deeply $got->{PE}, [], 'PE borders';
    is_deeply $got->{YT}, [qw(BC NT)], 'YT borders';
};

subtest netherlands => sub {
    my $obj = new_ok 'Geography::States::Borders' => [
        country => 'netherlands',
    ];
    is $obj->country, 'netherlands', 'country';
    my $got = $obj->borders;
    is_deeply $got->{AW}, [], 'AW borders';
    is_deeply $got->{UT}, [qw(ZH NH GE)], 'UT borders';
};

subtest usa => sub {
    my $obj = new_ok 'Geography::States::Borders' => [
        country => 'usa',
    ];
    is $obj->country, 'usa', 'country';
    my $got = $obj->borders;
    is_deeply $got->{AK}, [], 'AK borders';
    is_deeply $got->{OR}, [qw(CA ID NV WA)], 'OR borders';
};

done_testing();
