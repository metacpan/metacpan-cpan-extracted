#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 'lib';

use Test::More 'no_plan';

use_ok('JSON::Pointer::Extend');

test1();
test2();
test3();

sub test1 {
    my $json_pointer = JSON::Pointer::Extend->new();
    isa_ok($json_pointer, 'JSON::Pointer::Extend');

    my $document = {
        'seat'  => {
            'name'  => 'Место 1',
        },
        'prices'    => [
            {
                'name'  => 'price0',
            },
            {
                'name'  => 'price1',
            },
            {
                'name'  => 'price2',
            },
        ],
        'arr'   => [qw/1 2 3/],
    };

    my $pointer = {
        '/seat/name' => \&cb1,
        '/prices/*/name' => \&cb2,
        '/arr/*' => \&cb3,
    };

    $json_pointer->document($document);
    $json_pointer->pointer($pointer);

    $json_pointer->process();

    is($document->{'seat'}->{'translate'}, 'translate ' . $document->{'seat'}->{'name'});
    is($document->{'arr'}->[-1], 4);
}

sub test2 {
    my $document = [
        'seat',
        'price',
        'hall',
    ];

    my $pointer = {
        '' => \&cb4,
    };

    my $json_pointer = JSON::Pointer::Extend->new(
        '-document'     => $document,
        '-pointer'      => $pointer,
    );
    isa_ok($json_pointer, 'JSON::Pointer::Extend');

    $json_pointer->process();
    is($document->[-1], 'new_value');
}

sub test3 {
    my $document = [
        {name => 'name1'},
        {name => 'name2'},
        {name => 'name3'},
    ];

    my $pointer = {
        '/*/name' => \&cb5,
    };

    my $json_pointer = JSON::Pointer::Extend->new(
        '-document'     => $document,
        '-pointer'      => $pointer,
    );
    isa_ok($json_pointer, 'JSON::Pointer::Extend');

    $json_pointer->process();
    is($document->[0]->{'name'}, 'new_value2');
}


sub cb1 {
    my ($val, $doc, $field_name) = @_;
    is($val, 'Место 1');
    is($field_name, 'name');
    $doc->{'translate'} = 'translate ' . $val;
}

sub cb2 {
    my ($val, $doc) = @_;
    like($val, qr/price0|price1|price2/);
}

sub cb3 {
    my ($val, $doc) = @_;
    like($val, qr/[123]/);
    is(ref($doc), 'ARRAY');
    push @$doc, 4;
}

sub cb4 {
    my ($val, $doc) = @_;
    like($val, qr/seat|price|hall/);
    is(ref($doc), 'ARRAY');
    push @$doc, 'new_value';
}

sub cb5 {
    my ($val, $doc) = @_;
    like($val, qr/name1|name2|name3/);
    is(ref($doc), 'HASH');
    $doc->{name} = 'new_value2';
}
