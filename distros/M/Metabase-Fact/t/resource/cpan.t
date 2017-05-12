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

plan tests => 7;

require_ok('Metabase::Resource');

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
# new should create proper subtype object
#--------------------------------------------------------------------------#

my $string = "cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz";

is exception { $obj = Metabase::Resource->new($string) }, undef,
"Metabase::Resource->new(\$string) should not die";

isa_ok( $obj, 'Metabase::Resource::cpan' );

is( $obj->resource, $string, "object content correct" );

#--------------------------------------------------------------------------#
# generates typed metadata
#--------------------------------------------------------------------------#

# test metadata

my $metadata_types = {
    type         => '//str',
    cpan_id      => '//str',
    dist_file    => '//str',
    dist_name    => '//str',
    dist_version => '//str',
};

my $expected_metadata = {
    type         => 'Metabase-Resource-cpan-distfile',
    cpan_id      => 'JOHNDOE',
    dist_file    => 'JOHNDOE/Foo-Bar-1.23.tar.gz',
    dist_name    => 'Foo-Bar',
    dist_version => '1.23',
};

is_deeply( $metadata_types,    $obj->metadata_types, "Metadata types" );
is_deeply( $expected_metadata, $obj->metadata,       "Metadata" );
