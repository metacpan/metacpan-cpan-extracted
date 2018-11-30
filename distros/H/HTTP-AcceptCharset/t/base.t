#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use HTTP::AcceptCharset;

my %tests = (
    'all' => {
        header  => '*',
        values  => [qw/*/],
        ok      => [qw/utf-8 iso-8859-1 UTF-8 Utf-8/],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'iso-8859-1',
            ],
            [
                [qw/iso-8859-1 utf-16/],
                'iso-8859-1',
            ],
            [
                [qw/iso-8859-2 utf-16/],
                'iso-8859-2',
            ],
        ],
    },
    'utf-8' => {
        header  => 'utf-8',
        values  => [qw/utf-8/],
        ok      => [qw/utf-8/],
        nok     => [qw/iso-8859-1/, '', undef],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'utf-8',
            ],
            [
                [qw/iso-8859-1 utf-16/],
                '',
            ],
            [
                [qw/iso-8859-2 utf-16/],
                '',
            ],
        ],
    },
    'iso-8859-1' => {
        header  => 'iso-8859-1',
        values  => [qw/iso-8859-1/],
        nok     => [qw/utf-8/],
        ok      => [qw/iso-8859-1/],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'iso-8859-1'
            ],
            [
                [qw/iso-8859-1 utf-16/],
                'iso-8859-1'
            ],
            [
                [qw/iso-8859-2 utf-16/],
                '',
            ],
        ],
    },
    'several - weighted' => {
        header  => 'utf-8, iso-8859-1;q=0.5',
        values  => [qw/utf-8 iso-8859-1/],
        ok      => [qw/iso-8859-1 utf-8/],
        nok     => [qw/iso-8859-2/],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'utf-8'
            ],
            [
                [qw/iso-8859-1 utf-16/],
                'iso-8859-1'
            ],
            [
                [qw/iso-8859-2 utf-16/],
                '',
            ],
        ],
    },
    'several - weighted (reverse)' => {
        header  => 'iso-8859-1;q=0.5, utf-8',
        values  => [qw/utf-8 iso-8859-1/],
        ok      => [qw/iso-8859-1 utf-8/],
        nok     => [qw/iso-8859-2/],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'utf-8'
            ],
            [
                [qw/iso-8859-1 utf-16/],
                'iso-8859-1'
            ],
            [
                [qw/iso-8859-2 utf-16/],
                '',
            ],
        ],
    },
    'emtpy string' => {
        header  => '',
        values  => [qw//],
        ok      => [qw/utf-8 iso-8859-1 UTF-8 Utf-8/],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'iso-8859-1',
            ],
            [
                [qw/iso-8859-1 utf-16/],
                'iso-8859-1',
            ],
            [
                [qw/iso-8859-2 utf-16/],
                'iso-8859-2',
            ],
        ],
    },
    'undef' => {
        header  => undef,
        values  => [qw//],
        ok      => [qw/utf-8 iso-8859-1 UTF-8 Utf-8/],
        checks  => [
            [
                [qw/iso-8859-1 utf-8/],
                'iso-8859-1',
            ],
            [
                [qw/iso-8859-1 utf-16/],
                'iso-8859-1',
            ],
            [
                [qw/iso-8859-2 utf-16/],
                'iso-8859-2',
            ],
        ],
    },
);

for my $name ( sort keys %tests ) {
    my $test   = $tests{$name};
    my $header = $test->{header};
    my $obj    = HTTP::AcceptCharset->new( $header ); 

    isa_ok $obj, 'HTTP::AcceptCharset';

    #diag $header;
    #diag Dumper( $obj->values );
    is $obj->string, $header, "string $name";
    is_deeply $obj->values, $test->{values}, "values $name";

    is $obj->match(), '', "Empty param list ($name)";

    for my $ok_check ( @{ $test->{ok} || [] } ) {
        is $obj->match( $ok_check ), lc $ok_check, "Is: $name -> $ok_check";
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
        my $obj_with_hash = HTTP::AcceptCharset->new( string => $header );
        isa_ok $obj_with_hash, 'HTTP::AcceptCharset';
        is $obj_with_hash->string, $header;
        is_deeply $obj_with_hash->values, $test->{values};
    }

    # pass hashref to 'new'
    {
        my $obj_with_hashref = HTTP::AcceptCharset->new({ string => $header });
        isa_ok $obj_with_hashref, 'HTTP::AcceptCharset';
        is $obj_with_hashref->string, $header;
        is_deeply $obj_with_hashref->values, $test->{values};
    }
}

done_testing();
