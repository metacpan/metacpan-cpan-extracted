#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use HTTP::Accept;

my %tests = (
    'all' => {
        header  => '*/*',
        values  => [qw(*/*)],
        ok      => [qw(text/html application/json)],
        checks  => [
            [
                [qw(application/json text/html)],
                'application/json',
            ],
            [
                [qw(application/json application/AML)],
                'application/json',
            ],
            [
                [qw(image/png application/AML)],
                'image/png',
            ],
        ],
    },
    'text/html' => {
        header  => 'text/html',
        values  => [qw(text/html)],
        ok      => [qw(text/html)],
        nok     => [qw(application/json), '', undef],
        checks  => [
            [
                [qw(application/json text/html)],
                'text/html',
            ],
            [
                [qw(application/json application/AML)],
                '',
            ],
            [
                [qw(image/png application/AML)],
                '',
            ],
        ],
    },
    'application/json' => {
        header  => 'application/json',
        values  => [qw(application/json)],
        nok     => [qw(text/html)],
        ok      => [qw(application/json)],
        checks  => [
            [
                [qw(application/json text/html)],
                'application/json'
            ],
            [
                [qw(application/json application/AML)],
                'application/json'
            ],
            [
                [qw(image/png application/AML)],
                '',
            ],
        ],
    },
    'several - weighted' => {
        header  => 'text/html, application/json;q=0.5',
        values  => [qw(text/html application/json)],
        ok      => [qw(application/json text/html)],
        nok     => [qw(image/png)],
        checks  => [
            [
                [qw(application/json text/html)],
                'text/html'
            ],
            [
                [qw(application/json application/AML)],
                'application/json'
            ],
            [
                [qw(image/png application/AML)],
                '',
            ],
        ],
    },
    'several - weighted (reverse)' => {
        header  => 'application/json;q=0.5, text/html',
        values  => [qw(text/html application/json)],
        ok      => [qw(application/json text/html)],
        nok     => [qw(image/png)],
        checks  => [
            [
                [qw(application/json text/html)],
                'text/html'
            ],
            [
                [qw(application/json application/AML)],
                'application/json'
            ],
            [
                [qw(image/png application/AML)],
                '',
            ],
        ],
    },
    'all application/' => {
        header  => 'application/*',
        values  => [qw(application/*)],
        ok      => [qw(application/aml application/json)],
        nok     => [qw(text/html image/jpg)],
        checks  => [
            [
                [qw(application/json text/html)],
                'application/json',
            ],
            [
                [qw(application/json application/AML)],
                'application/json',
            ],
            [
                [qw(image/png application/AML)],
                'application/aml',
            ],
        ],
    },
    'empty_string' => {
        header  => '',
        values  => [qw()],
        ok      => [qw(text/html application/json)],
        checks  => [
            [
                [qw(application/json text/html)],
                'application/json',
            ],
            [
                [qw(application/json application/AML)],
                'application/json',
            ],
            [
                [qw(image/png application/AML)],
                'image/png',
            ],
        ],
    },
);

for my $name ( sort keys %tests ) {
    my $test   = $tests{$name};
    my $header = $test->{header};
    my $obj    = HTTP::Accept->new( $header ); 

    isa_ok $obj, 'HTTP::Accept';

    #diag $header;
    #diag Dumper( $obj->values );
    is $obj->string, $header, "string $name";
    is_deeply $obj->values, $test->{values}, "values $name";

    is $obj->match(), '', "Empty param list ($name)";

    for my $ok_check ( @{ $test->{ok} || [] } ) {
        is $obj->match( $ok_check ), $ok_check, "Is: $name -> $ok_check";
    }

    for my $nok_check ( @{ $test->{nok} || [] } ) {
        is $obj->match( $nok_check ), '', "Is not: $name -> " . ( $nok_check // '<undefined>' );
    }

    for my $check ( @{ $test->{checks} || [] } ) {
        my @input  = @{ $check->[0] || [] };
        my $output = $check->[1];

        is $obj->match( @input ), $output, "$name - check - @input";
    }

    # pass hash to 'new'
    {
        my $obj_with_hash = HTTP::Accept->new( string => $header );
        isa_ok $obj_with_hash, 'HTTP::Accept';
        is $obj_with_hash->string, $header;
        is_deeply $obj_with_hash->values, $test->{values};
    }

    # pass hashref to 'new'
    {
        my $obj_with_hashref = HTTP::Accept->new({ string => $header });
        isa_ok $obj_with_hashref, 'HTTP::Accept';
        is $obj_with_hashref->string, $header;
        is_deeply $obj_with_hashref->values, $test->{values};
    }
}

done_testing();
