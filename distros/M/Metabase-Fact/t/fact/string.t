# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';

plan tests => 12;

require_ok('FactSubclasses.pm');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my ( $obj, $err );

my $string = "Who am I?";

my $meta = { 'length' => [ '//num' => length $string ], };

my $args = {
    resource => "cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz",
    content  => $string,
};

is exception { $obj = FactThree->new($args) }, undef, "new( <hashref> ) doesn't die";

isa_ok( $obj, 'Metabase::Fact::String' );

my $test_guid = "b4ac3de6-15bb-11df-b44d-0018f34ec37c";
is exception { $obj = FactThree->new( %$args, guid => $test_guid ) }, undef,
"new( <list> ) doesn't die";

isa_ok( $obj, 'Metabase::Fact::String' );
is( $obj->type, "FactThree", "object type is correct" );

is( $obj->resource, $args->{resource}, "object refers to distribution" );
is_deeply( $obj->content_metadata, $meta, "object content_metadata() correct" );
is( $obj->content, $string, "object content correct" );

my $want_struct = {
    content  => $string,
    metadata => {
        core => {
            type           => 'FactThree',
            schema_version => 1,
            guid           => $test_guid,
            resource       => $args->{resource},
            valid          => 1,
        },
    },
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

is_deeply( $have_struct, $want_struct, "object as_struct() correct" );

