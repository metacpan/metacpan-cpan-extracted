
use strict;
use Test::More tests => 9;

BEGIN { $^W = 1 }

use_ok( 'HTML::StripScripts' );

my $f = HTML::StripScripts->new;
isa_ok($f, 'HTML::StripScripts');

my $ff = $f->new;
isa_ok($f, 'HTML::StripScripts');

$f->input_start_document;
$f->input_end_document;
is( $f->filtered_document, '', 'empty document' );

$f = HTML::StripScripts->new;
$f->input_start_document;
$f->input_start('<i>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<i>foo</i>', 'basic' );

$f->input_start_document;
$f->input_start('<b>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<b>foo</b>', 'second document' );

$f->input_start_document;
$f->input_start('<b style="color: pink">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<b style="color:pink">foo</b>', 'style attribute' );

$f->input_start_document;
$f->input_start('<img alt="foo foo">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<img alt="foo foo" />foo', 'img alt' );

$f->input_start_document;
$f->input_start('<i>');
$f->input_text('0');
$f->input_end('</i>');
$f->input_end_document;
is ($f->filtered_document,'<i>0</i>', 'false but valid content');
