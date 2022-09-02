use strict; use warnings;
use HTML::Tiny;
use Test::More tests => 51;

ok my $h = HTML::Tiny->new, 'Create succeeded';
ok my $h_html = HTML::Tiny->new( mode => 'html' ),
 'Create succeeded (mode HTML)';

common_checks( $h );
common_checks( $h_html, ' (mode HTML)' );

# Differences between the two output modes.

is $h->closed( 'br' ),      '<br />', 'simple closed OK';
is $h_html->closed( 'br' ), '<br>',   'simple closed OK (mode HTML)';

is $h->closed( 'input', { type => 'checkbox', checked => [] } ),
 '<input checked="checked" type="checkbox" />', 'Empty attr OK';
is $h_html->closed( 'input', { type => 'checkbox', checked => [] } ),
 '<input checked type="checkbox">', 'Empty attr OK (mode HTML)';

sub common_checks {
  my $h = shift;
  my $mode = shift || '';

  # No attributes

  is $h->open( 'b' ),  '<b>',  'simple open OK' . $mode;
  is $h->close( 'b' ), '</b>', 'simple close OK' . $mode;

  # Tag options

  is $h->tag( 'b', '' ), '<b></b>', 'simple tag OK' . $mode;
  is $h->tag( 'b', 'a', 'b' ), '<b>a</b><b>b</b>',
   'multi tag OK' . $mode;
  is $h->tag( 'b', [ 'a', 'b' ] ), '<b>ab</b>',
   'grouped tag OK' . $mode;
  is $h->tag( 'p', $h->tag( 'b', 'a', 'b' ) ),
   '<p><b>a</b></p><p><b>b</b></p>',
   'nested multi tag OK' . $mode;
  is $h->tag( 'p', $h->tag( 'b', [ 'a', 'b' ] ) ), '<p><b>ab</b></p>',
   'nested grouped tag OK' . $mode;

  # Attributes

  is $h->open( 'p', { class => 'normal' } ), '<p class="normal">',
   'simple attr OK' . $mode;
  is $h->open( 'p', { class => 'normal', style => undef } ),
   '<p class="normal">',
   'skip undef attr OK' . $mode;
  is $h->tag( 'p', { class => 'small' }, 'a', 'b' ),
   '<p class="small">a</p><p class="small">b</p>',
   'multi w/ attr OK' . $mode;
  is $h->tag( 'p', { class => 'small' }, 'a', { class => undef }, 'b' ),
   '<p class="small">a</p><p>b</p>', 'change attr OK' . $mode;
}

# Stringification

package T::Obj;
sub new { bless {}, shift }
sub as_string { 'an object' }
sub TO_JSON   { 'a json object' }

package T::Obj2;
sub new { bless {}, shift }

package main;

my $obj = T::Obj->new;
is $h->tag( 'p', $obj ), '<p>an object</p>', 'stringification OK';
my $obj2 = T::Obj2->new;
like $h->tag( 'p', $obj2 ), '/<p>T::Obj2=.+?</p>/', 'non as_string OK';

# Only hashes allowed

eval { $h->closed( { src => 'spork' }, 'Text here' ); };

like $@, '/Attributes\s+must\s+be\s+passed\s+as\s+hash\s+references/',
 'error on non-hash OK';

# URL encoding, decoding

is $h->url_encode( ' <hello> ' ),     '+%3chello%3e+', 'url_encode OK';
is $h->url_decode( '+%3chello%3e+' ), ' <hello> ',     'url_decode OK';
is $h->url_encode( '~' ),             '~',             'tilde OK';

is $h->url_decode( '%7B%22m%22:%22setValue%22,'
   . '%22ns%22:%22http://hexten.net/%22,'
   . '%22n%22:%22Hexten%20Test%22,'
   . '%22a%22:[%22porridge%22,1]%7D' ), '{"m":"setValue",'
 . '"ns":"http://hexten.net/",'
 . '"n":"Hexten Test",'
 . '"a":["porridge",1]}',
 'complex OK';

# Query encoding

is $h->query_encode( { a => 1, b => 2 } ), 'a=1&b=2',
 'simple query_encode OK';
is $h->query_encode( { a => 1, b => 2, '&' => '<html>' } ),
 '%26=%3chtml%3e&a=1&b=2', 'escaped query_encode OK';
is $h->query_encode, '', 'empty query_encode OK';

# Entity encoding

is $h->entity_encode( '<>\'"&' ), '&lt;&gt;&#39;&#34;&amp;',
 'entity_encode OK';

# JSON encoding

is $h->json_encode( 1 ), '1', 'json number OK';
is $h->json_encode( "\x00\x01\x02\x03\x04\x05\x06\x07"
   . "\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
   . "\x10\x11\x12\x13\x14\x15\x16\x17"
   . "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f" ),
 "\"\\z\\x01\\x02\\x03\\x04\\x05\\x06\\a"
 . "\\x08\\t\\n\\v\\f\\r\\x0e\\x0f"
 . "\\x10\\x11\\x12\\x13\\x14\\x15\\x16\\x17"
 . "\\x18\\x19\\x1a\\e\\x1c\\x1d\\x1e\\x1f\"", 'json escapes OK';
is $h->json_encode( [] ), '[]', 'json empty array OK';
is $h->json_encode( {} ), '{}', 'json empty hash OK';
is $h->json_encode( [ 1, 2, 3 ] ), '[1,2,3]', 'json simple array OK';
is $h->json_encode( { a => 1, b => 2 } ), '{"a":1,"b":2}',
 'json simple hash OK';
is $h->json_encode( { ar => [ 1, 2, 3, { a => 1, b => 2 } ] } ),
 '{"ar":[1,2,3,{"a":1,"b":2}]}', 'json complex OK';
is $h->json_encode( { obj => $obj } ), '{"obj":"a json object"}',
 'TO_JSON used OK';
is $h->json_encode( undef ), 'null', 'json null OK';
is $h->json_encode( [undef] ), '[null]', 'json null in array OK';

# Self referential
{
  my $foo = {};
  my $bar = [$foo];
  $foo->{bar} = $bar;
  eval { $h->json_encode( $foo ) };
  like $@, qr/referential/, 'self-ref error OK';
}

# Not self ref - but duplicated
{
  my $foo = { one => 1 };
  my $bar = [ $foo, $foo, $foo ];
  my $pog = { bar => $bar, foo => $foo };
  is $h->json_encode( $pog ),
   '{"bar":[{"one":1},{"one":1},{"one":1}],"foo":{"one":1}}',
   'repeated reference OK';
}
