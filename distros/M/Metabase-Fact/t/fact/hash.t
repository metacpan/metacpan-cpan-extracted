# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Data::GUID qw/guid_string/;
use Test::More;
use Test::Fatal;
use JSON::MaybeXS ();

use lib 't/lib';

plan tests => 23;

require_ok('FactSubclasses.pm');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my $json = JSON::MaybeXS->new(ascii => 1);

my ( $obj, $err );

my $struct = {
    first  => 'alpha',
    second => 'beta',
};

my $meta = { size => [ '//num' => 2 ], };

my $args = {
    resource => "cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz",
    content  => $struct,
};

my $test_args = {
    resource => $args->{resource},
    content  => {},
};

$err = exception { $obj = FactFour->new($test_args) };
like( $err, qr/missing required keys.+?first/, 'missing required dies' );

$test_args->{content}{first} = undef;

is exception { $obj = FactFour->new($test_args) }, undef, "undef required field is OK";

$test_args->{content}{first} = 1;

is exception { $obj = FactFour->new($test_args) }, undef, "new( <hashref> ) doesn't die";

$test_args->{content}{third} = 3;

$err = exception { $obj = FactFour->new($test_args) };
like( $err, qr/invalid keys.+?third/, 'invalid key dies' );

isa_ok( $obj, 'Metabase::Fact::Hash' );

is exception { $obj = FactFour->new(%$args) }, undef, "new( <list> ) doesn't die";

isa_ok( $obj, 'Metabase::Fact::Hash' );
ok( $obj->guid, "object has a GUID" );
is( $obj->type,                   "FactFour", "object type is correct" );
is( $obj->{metadata}{core}{type}, "FactFour", "object type is set internally" );

is( $obj->resource, $args->{resource}, "object refers to distribution" );
is_deeply( $obj->content_metadata, $meta,   "object content_metadata() correct" );
is_deeply( $obj->content,          $struct, "object content correct" );

my $want_struct = {
    content  => $json->encode($struct),
    metadata => {
        core => {
            type           => 'FactFour',
            schema_version => 1,
            guid           => $obj->guid,
            resource       => $args->{resource},
            valid          => 1,
        },
    }
};

my $have_struct = $obj->as_struct;
is(
    $have_struct->{metadata}{core}{update_time},
    $have_struct->{metadata}{core}{creation_time},
    "creation_time equals update_time"
);

my $creation_time = delete $have_struct->{metadata}{core}{creation_time};
like(
    $creation_time,
    qr/\A\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/,
    'creation_time is ISO 8601 Zulu',
);
delete $have_struct->{metadata}{core}{update_time};

is_deeply( $have_struct, $want_struct, "object as_struct correct" );

my $creator_uri = 'metabase:user:351e99ea-1d21-11de-ab9c-3268421c7a0a';
$obj->set_creator($creator_uri);
$want_struct->{metadata}{core}{creator} = Metabase::Resource->new($creator_uri);

$have_struct = $obj->as_struct;
delete $have_struct->{metadata}{core}{update_time};
delete $have_struct->{metadata}{core}{creation_time};
is_deeply( $have_struct, $want_struct, "object as_struct correct w/creator" );

$obj->set_valid(0);
$want_struct->{metadata}{core}{valid} = 0;
$have_struct = $obj->as_struct;
delete $have_struct->{metadata}{core}{update_time};
delete $have_struct->{metadata}{core}{creation_time};
is_deeply( $have_struct, $want_struct, "set_valid(0)" );

$obj->set_valid(2);
$want_struct->{metadata}{core}{valid} = 1;
$have_struct = $obj->as_struct;
delete $have_struct->{metadata}{core}{update_time};
delete $have_struct->{metadata}{core}{creation_time};
is_deeply( $have_struct, $want_struct, "set_valid(2) normalized to '1'" );

#--------------------------------------------------------------------------#

$obj = FactFour->new(%$args);
my $obj2 = FactFour->from_struct( $obj->as_struct );
is_deeply( $obj2, $obj, "roundtrip as->from struct" );

#--------------------------------------------------------------------------#

{
    my $guid = uc guid_string;
    $obj = FactFour->new( %$args, guid => $guid );
    ok( $obj, "got object (set upper case guid manually)" );
    is( $obj->guid, lc $guid, "object has correct lower-case guid" );
}

