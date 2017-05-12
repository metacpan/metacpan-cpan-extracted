#!/usr/bin/perl -w

use strict;
use warnings;

# NB we have use utf8 here, but the source should be 7bit clean
# however I need the utf8::is_utf8 and utf8::valid names which
# are no longer exposed without the use line.
use utf8;

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
    $xmldata .= "  <$_ char=\"" . $data->{$_} . "\" />\n";
}
$xmldata .= "</data>\n";

# parse the provided XML
my $obj = new HTML::Bare( text => $xmldata );
my $root = $obj->parse;

# convert back to XML from parse
my $roundtrip = $obj->html($root);

## this isn't valid as order/spacing not preserved
is( $roundtrip, $xmldata, 'Round trip XML identical' );

while ( my ( $name, $char ) = each %{$data} ) {
    my $str = $root->{data}{$name}{char}{value};
    ok( $root->{data}{$name}{char}{_att}, "$name has char attribute" );
    ok( utf8::is_utf8($str), "Character $name is correct encoding" )
      if ( utf8::is_utf8($char) );
    ok( utf8::valid($str), "Character $name is Valid" );
    ok( ( length($str) == 1 ), "String returned for $name is 1 char long" );

    is( $str, $char, "Character $name OK" );
}