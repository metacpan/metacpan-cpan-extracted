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

plan tests => 10;

require_ok('Metabase::Resource');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my ( $obj, $err );

#--------------------------------------------------------------------------#
# required parameters missing
#--------------------------------------------------------------------------#

like( exception { $obj = Metabase::Resource->new() },
qr/no resource string provided/, "new() without string throws error" );

#--------------------------------------------------------------------------#
# new should create proper subtype object
#--------------------------------------------------------------------------#

my $sha1   = "8c57606294f48eb065dff03f7ffefc1e4e2cdce4";
my $string = "perl:///commit/$sha1";

is exception { $obj = Metabase::Resource->new($string) }, undef,
"Metabase::Resource->new(\$string) should not die";

isa_ok( $obj, 'Metabase::Resource::perl' );

is( $obj->resource, $string, "object content correct" );

#--------------------------------------------------------------------------#
# generates typed metadata
#--------------------------------------------------------------------------#

# test metadata

my $metadata_types = {
    type => '//str',
    sha1 => '//str',
};

my $expected_metadata = {
    type => 'Metabase-Resource-perl-commit',
    sha1 => $sha1,
};

is_deeply( $metadata_types,    $obj->metadata_types, "Metadata types" );
is_deeply( $expected_metadata, $obj->metadata,       "Metadata" );

is( $obj->sha1, $sha1, "sha1() correct" );
is( $obj->full_url, "http://perl5.git.perl.org/perl.git/$sha1", "full_url()", );
is(
    $obj->full_url('example.com'),
    "http://example.com/perl.git/$sha1",
    "full_url('example.com')"
);
