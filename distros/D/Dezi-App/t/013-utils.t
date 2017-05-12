#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 9;
use SWISH::3 qw( :constants );

use_ok('Dezi::Utils');

my $utils = 'Dezi::Utils';    # static methods only

is( $utils->mime_type('foo.json'), "application/json", "got json mime type" );
is( $utils->mime_type('foo.yml'), "application/x-yaml",
    "got yaml mime type" );
is( $utils->parser_for('foo.json'), "HTML", "json -> HTML parser" );

# override defaults a couple ways

{
    no warnings;
    $Dezi::Utils::ParserTypes{'application/json'} = 'TXT';
}

is( $utils->parser_for('foo.json'),
    "TXT", "json -> TXT parser, overriden via package hash" );

# must delete class register so that swish3 is used instead
delete $Dezi::Utils::ParserTypes{'application/json'};

ok( $utils->merge_swish3_config(
        SWISH_PARSERS() => { 'XML' => [ 'foo', 'application/json' ] }
    ),
    "override application/json to use XML parser"
);
is( $utils->parser_for('foo.json'),
    "XML", "json -> XML parser, overriden via merge_swish3_config" );

# misc config merge
ok( $utils->merge_swish3_config( 'foo' => 'bar' ), "misc config merge" );
is( $utils->get_swish3->config->get_misc->get('foo'),
    'bar', "misc config happy" );

#$utils->get_swish3->config->debug;
