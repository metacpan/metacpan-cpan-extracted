#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Moose::More;
use Data::DTO::GELF;
use Data::UUID;
use POSIX qw(strftime);
use Data::Random::String;

use JSON -convert_blessed_universally;

use Readonly;
Readonly my $CLASS => 'Data::DTO::GELF';

my $obj;
my $data = {
    'full_message' => Data::Random::String->create_random_string(
        length   => '100',
        contains => 'alpha'
    ),
    'level'    => "DEBUG",
    '_timestr' => strftime( "%Y-%m-%d %H:%M:%S", gmtime( time() ) ),
    '_uuid'    => Data::UUID->new()->create_str(),
};

subtest "$CLASS Is valid object." => sub {
    lives_ok {
        $obj = $CLASS->new($data)
    }
    "Lives though creating instance if $CLASS";

    ok( $obj, "$CLASS is Instanced" );
};

subtest "$CLASS has proper values" => sub {
    cmp_ok( $obj->version(), "eq", "1.1", "Version tag is 1.1" );
    cmp_ok( $obj->full_message(), "eq", $data->{full_message},
        "Full message is ok" );
    cmp_ok(
        $obj->short_message(), "eq",
        ( substr $data->{full_message}, 0, 100 ),
        "Short message is full message truncated to 100 chars."
    );
    cmp_ok( $obj->level(), "==", "0", "DEBUG level is coerced to 0" );
    ok( defined $obj->timestamp(), "Timestamp is defined" );
    cmp_ok( $obj->_uuid(), "eq", $data->{_uuid},
        "Dynamic _var's were created" );

};
subtest "$CLASS hashifys for TO_JSON" => sub {
    lives_ok {
        my $json = JSON->new->allow_nonref->convert_blessed;
        my $j    = $json->encode($obj);
        ok( defined $j, "Has JSON value" );
    }
    "Lives through converting to json";
};

done_testing();
