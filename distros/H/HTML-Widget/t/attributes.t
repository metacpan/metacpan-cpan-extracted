use strict;
use warnings;

use Test::More tests => 11;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

# widget

my $w = HTML::Widget->new( 'form', { class => 'myForm' } );

ok( exists $w->attributes->{class}, 'key exists' );

$w->attributes( onsubmit => 'foo' );
$w->attributes( { onclick => 'bar' } );

ok( exists $w->attributes->{onsubmit}, 'key exists' );
ok( exists $w->attributes->{onclick},  'key exists' );

#element

my $e = $w->element( 'Textfield', 'foo',
    { class => 'myText', disabled => 'disabled' } )->size(10);

ok( $e->attributes->{disabled}, 'key exists' );

$e->attributes( onsubmit => 'foo' );
$e->attributes( { onclick => 'bar' } );

ok( exists $e->attributes->{onsubmit}, 'key exists' );
ok( exists $e->attributes->{onclick},  'key exists' );

# delete attributes idiom

%{ $w->attributes } = ();

ok( !exists $w->attributes->{class}, 'key does not exist' );

%{ $e->attributes } = ();

ok( !exists $e->attributes->{disabled}, 'key does not exist' );

#element inside a block

my $b = $w->element('Block');
my $e2 = $b->element( 'Textfield', 'foo', { foobar => 'disabled' } )->size(10);

ok( $e2->attributes->{foobar}, 'key exists' );

$e2->attributes( onsubmit => 'foo' );
$e2->attributes( { onclick => 'bar' } );

ok( exists $e2->attributes->{onsubmit}, 'key exists' );
ok( exists $e2->attributes->{onclick},  'key exists' );

