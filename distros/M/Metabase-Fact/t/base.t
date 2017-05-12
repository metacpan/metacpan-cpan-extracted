# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';
use Test::Metabase::StringFact;

plan tests => 17;

require_ok('Metabase::Fact');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my ( $obj, $err );

#--------------------------------------------------------------------------#
# required parameters missing
#--------------------------------------------------------------------------#

$err = exception { $obj = Metabase::Fact->new() };
like( $err, qr/missing required/, "new() without params throws error" );
for my $p (qw/ resource content /) {
    like( $err, qr/$p/, "... '$p' noted missing" );
}

is( Metabase::Fact->default_schema_version, 1, "schema_version() defaults to 1", );

#--------------------------------------------------------------------------#
# fake an object and test methods
#--------------------------------------------------------------------------#

# type is class munged from "::" to "-"
is( Metabase::Fact->type, "Metabase-Fact", "->type converts class name" );

# unimplemented
for my $m (qw/content_as_bytes content_from_bytes validate_content/) {
    my $obj = bless {} => 'Metabase::Fact';
    $err = exception { $obj->$m };
    like( $err, qr/$m not implemented by Metabase::Fact/, "$m not implemented" );
}

#--------------------------------------------------------------------------#
# new should take either hashref or list
#--------------------------------------------------------------------------#

my $string = "Who am I?";

my $args = {
    resource => "metabase:fact:543fc732-0eec-11df-a736-0018f34ec37c",
    content  => $string,
};

is exception { $obj = Test::Metabase::StringFact->new($args) }, undef,
"new( <hashref> ) doesn't die";

isa_ok( $obj, 'Test::Metabase::StringFact' );

is exception { $obj = Test::Metabase::StringFact->new(%$args) }, undef,
"new( <list> ) doesn't die";

isa_ok( $obj, 'Test::Metabase::StringFact' );

is( $obj->type, "Test-Metabase-StringFact", "object type is correct" );
is( $obj->content, $string, "object content correct" );

#--------------------------------------------------------------------------#
# class validation
#--------------------------------------------------------------------------#

$err = exception { $obj->_load_fact_class("Cwd;die 'Insecure'!"); };
like(
    $err,
    qr/does not look like a class name/,
    "fact class loading validates class name"
);
$err = exception { $obj->resource->_load("Cwd;die 'Insecure'!"); };
like(
    $err,
    qr/does not look like a class name/,
    "fact class loading validates class name"
);

