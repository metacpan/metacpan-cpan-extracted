# -*- mode: Perl; -*-
package JsonTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Encode ();

use Test::More;
use Test::Exception;

use Eve::Json;
use Eve::Support;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'json'} = Eve::Json->new();

    $self->{'json_data'} = {
        "{\n   \"something\" : \"simple\"\n}\n" => {'something' => 'simple'},
        "[\n   \"an\",\n   \"array\"\n]\n" => ['an', 'array'],
        "{\n   \"a\" : [\n      1,\n      2\n   ],\n   \"no\" : null\n}\n" =>
            Eve::Support::indexed_hash('a' => [1, 2], 'no' => undef)};
}

sub test_encode : Test(3) {
    my $self = shift;

    for my $json_string (keys %{$self->{'json_data'}}) {
        is(
            $self->{'json'}->encode(reference =>
                $self->{'json_data'}->{$json_string}),
            $json_string);
    }
}

sub test_decode : Test(3) {
    my $self = shift;

    for my $json_string (keys %{$self->{'json_data'}}) {
        is_deeply(
            $self->{'json'}->decode(string => $json_string),
            $self->{'json_data'}->{$json_string});
    }
}

sub test_decode_error_value : Test {
    my $self = shift;

    throws_ok(
        sub { $self->{'json'}->decode(string => 'Some undecodable garbage'); },
        'Eve::Error::Value');
}

sub test_encode_error_value : Test {
    my $self = shift;

    throws_ok(
        sub { $self->{'json'}->encode(reference => sub { return; }); },
        'Eve::Error::Value');
}

1;
