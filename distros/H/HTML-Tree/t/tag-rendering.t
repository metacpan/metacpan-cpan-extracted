#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 11;

use HTML::Element;

my $img = HTML::Element->new(
    'img',
    (   src    => 'damian-conway-in-a-dress.jpg',
        height => 540,
        width  => 100,
        border => 0,
        alt    => "A few bottles of Chech'tluth later...",
    )
);

my $href         = '/report/fullcsv';
my $literal_href = HTML::Element->new( '~literal',
    'text' => "window.location.href='$href'" );
$img->attr( onClick => $literal_href );

isa_ok( $img, 'HTML::Element' );
my $html = $img->as_HTML;
print $html, "\n";

like( $html, qr/<img .+ \/>/,    "Tag is self-closed" );
like( $html, qr/ height="540" /, "Height is quoted" );
like( $html, qr/ border="0" /,   "Border is quoted" );
like( $html, qr/ width="100" /,  "Width is quoted" );
like(
    $html,
    qr! onclick="window.location.href='$href'!,
    "Literal text is preserved"
);
like(
    $html,
    qr/ alt="A few bottles of Chech&#39;tluth later..." /,
    "Alt tag is quoted and escaped"
);

# _empty_element_map anchor test (RT 49932)
my $a = HTML::Element->new( 'a', href => 'example.com' );
my $xml = $a->as_XML();
like(
    $xml,
    qr{<a href="example.com"></a>},
    "A tag not in _empty_element_map"
);

my $empty_element_map = $a->_empty_element_map;
$empty_element_map->{'a'} = 1;

$xml = $a->as_XML();
like(
    $xml,
    qr{<a href="example.com" />},
    "A tag in _empty_element_map, no content"
);

$a->push_content("Extra content");
$xml = $a->as_XML();
like(
    $xml,
    qr{<a href="example.com">Extra content</a>},
    "A tag in _empty_element_map, with content"
);

my $text = undef;
my $input = HTML::Element->new( 'input', type => 'text', value => $text );
$html = $input->as_HTML;
like(
    $html,
    qr{<input type="text" value="value" />},
    "Setting an attribute to undef defaults the value to the attribute name"
);


