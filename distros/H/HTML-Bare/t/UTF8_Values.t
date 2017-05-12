#!/usr/bin/perl -w

use strict;
use warnings;

# NB we have use utf8 here, but the source should be 7bit clean
# however I need the utf8::is_utf8 and utf8::valid names which
# are no longer exposed without the use line.
#use utf8;

use Test::Harness;
$Test::Harness::verbose=1;
use Test::More qw(no_plan);


use_ok('HTML::Bare');

my $data = {
    hash   => "#",
    oo     => "\x{f6}",
    iso_a  => "\x{c4}",
    iso_oo => "\x{d6}",
    aa     => "\x{e4}",
    euro   => "\x{20ac}",
};

# build XML string with UTF8 values
my $xmldata = "<data>\n";
foreach ( keys %{$data} ) {
    $xmldata .= "  <$_>";
    $xmldata .= $data->{$_};
    $xmldata .= "</$_>\n";
}
$xmldata .= "</data>\n";

# parse the provided XML
my $obj = new HTML::Bare( text => $xmldata, file => 't/test_utf8.xml' );
my $root = $obj->parse;

# convert back to XML from parse
use Data::Dumper;
my $roundtrip = $obj->html($root);

## this isn't valid as order/spacing not preserved
is( $roundtrip, $xmldata, 'Round trip XML identical' );

while ( my ( $name, $char ) = each %{$data} ) {
    my $str = $root->{data}{$name}{value};
    ok( utf8::is_utf8($str), "Character $name is correct encoding" )
      if ( utf8::is_utf8($char) );
    ok( utf8::valid($str), "Character $name is Valid" );
    ok( ( length($str) == 1 ), "String returned for $name is 1 char long" );

    is( $str, $char, "Character $name OK" );
}

# save it to a file
$obj->save();

my ( $ob2, $root2 ) = HTML::Bare->new( file => 't/test_utf8.xml' );
my $round2 = $obj->html( $root2 );

is( $roundtrip, $xmldata, 'Written file reads back in the same' );