#!/usr/bin/perl

use Test::More tests => 6;
use Mac::iTunes::Library::Parse;


{
my $data = "\x00\x01";
my $short = Mac::iTunes::Library::Parse::_get_short_int( \$data );

is( $short, 1, "Get short int in network order, low    bit set" );

$data = "\x01\x00";
$short = Mac::iTunes::Library::Parse::_get_short_int( \$data );

is( $short, 256, "Get short int in network order, middle bit set" );

$data = "\x80\x00";
$short = Mac::iTunes::Library::Parse::_get_short_int( \$data );
is( $short, 32768, "Get short int in network order, high   bit set" )
}

{
my $data = "\x00\x00\x00\x01";
my $long = Mac::iTunes::Library::Parse::_get_long_int( \$data );

is( $long, 1, "Get long  int in network order, low    bit set" );

$data = "\x80\x00\x00\x00";
$long = Mac::iTunes::Library::Parse::_get_long_int( \$data );
is( $long, 2147483648, "Get short int in network order, high   bit set" )
}

{
my $data = "\x01";
my $long = Mac::iTunes::Library::Parse::_get_char_int( \$data );

is( $long, 1, "Get char  int in network order, low    bit set" );
}