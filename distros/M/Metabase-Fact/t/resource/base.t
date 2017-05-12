# Copyright (c) 2010 by David Golden. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';

plan tests => 14;

require_ok('Metabase::Resource');
require_ok('Metabase::Resource::metabase');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my ( $obj, $err );

#--------------------------------------------------------------------------#
# required parameters missing
#--------------------------------------------------------------------------#

$err = exception { $obj = Metabase::Resource->new() };
like $err, qr/no resource string provided/, "new() without string throws error";

#--------------------------------------------------------------------------#
# fake an object and test methods
#--------------------------------------------------------------------------#

# unimplemented
for my $m (qw/validate/) {
    my $obj = bless {} => 'Metabase::Resource';
    $err = exception { $obj->$m };
    like $err, qr/$m not implemented by Metabase::Resource/, "$m not implemented";
}

# bad schema
$err = exception { $obj = Metabase::Resource->new("noschema") };
like $err, qr/could not determine URI scheme from/, "no schema found";

#--------------------------------------------------------------------------#
# new should create proper subtype object
#--------------------------------------------------------------------------#

my $string = "metabase:user:b66c7662-1d34-11de-a668-0df08d1878c0";

is exception { $obj = Metabase::Resource->new($string) }, undef,
"Metabase::Resource->new(\$string) should not die";

isa_ok( $obj, 'Metabase::Resource::metabase' );
isa_ok( $obj, 'Metabase::Resource::metabase::user' );

is( $obj->resource, $string, "\$obj->resource correct" );
is( "$obj",         $string, "string overloading working correctly" );

#--------------------------------------------------------------------------#
# generates typed metadata
#--------------------------------------------------------------------------#

# test metadata

my $metadata_types = {
    type => '//str',
    guid => '//str',
};

my $expected_metadata = {
    type => 'Metabase-Resource-metabase-user',
    guid => 'b66c7662-1d34-11de-a668-0df08d1878c0',
};

is_deeply( $metadata_types,    $obj->metadata_types, "Metadata types" );
is_deeply( $expected_metadata, $obj->metadata,       "Metadata" );

#--------------------------------------------------------------------------#
# accessors
#--------------------------------------------------------------------------#

for my $k ( sort keys %$expected_metadata ) {
    is( $obj->$k, $expected_metadata->{$k}, "\$obj->$k" );
}

