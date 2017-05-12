#!/usr/bin/env perl 

use strict;
use warnings;

use JSON;
use Path::Tiny 0.062;
use JSON::Schema::AsType;
use List::MoreUtils qw/ any /;

use Test::More;

use lib 't/lib';

use TestUtils;

$::explain = 1;
$JSON::Schema::AsType::strict_string = 1;

my $jsts_dir = path( __FILE__ )->parent->child( 'json-schema-test-suite' );

# seed the external schemas
my $remote_dir = $jsts_dir->child('remotes');

$remote_dir->visit(sub{
    my $path = shift;
    return unless $path =~ qr/\.json$/;

    my $name = $path->relative($remote_dir);

    JSON::Schema::AsType->new( 
        uri    => "http://localhost:1234/$name",
        schema => from_json $path->slurp 
    );

    return;

},{recurse => 1});


@ARGV = grep { $_->is_file } $jsts_dir->child( 'tests','draft6')->children unless @ARGV;

run_tests_for(6,path($_)) for @ARGV;

done_testing;





