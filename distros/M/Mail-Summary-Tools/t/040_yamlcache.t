#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use ok "Mail::Summary::Tools::YAMLCache";

use Path::Class;
use File::Temp qw/tempfile/;

my ( $fh, $tmpfile ) = tempfile();

my $y = Mail::Summary::Tools::YAMLCache->new( file => file($tmpfile) );

isa_ok( $y, "Mail::Summary::Tools::YAMLCache" );

can_ok( $y, qw/get set delete/ );

my $key = "foo:bar";

is( $y->get($key), undef );

$y->set( $key => 42 );

is( $y->get($key), 42 );

undef $y;
$y = Mail::Summary::Tools::YAMLCache->new( file => file($tmpfile) );

is( $y->get($key), 42 );

$y->set("foo:gorch", 123 );

undef $y;
$y = Mail::Summary::Tools::YAMLCache->new( file => file($tmpfile) );

is( $y->get($key), 42 );
is( $y->get("foo:gorch"), 123 );

$y->delete( $key );

is( $y->get($key), undef );


