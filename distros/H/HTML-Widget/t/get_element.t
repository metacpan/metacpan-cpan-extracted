use strict;
use warnings;

use Test::More tests => 11;

use HTML::Widget;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );
$w->element( 'Textarea',  'baz' );
$w->element( 'Password',  'baz' );

{
    my @elements = $w->get_element;

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'foo', 'correct element name' );
}

{
    my @elements = $w->get_element( type => 'Textfield' );

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'foo', 'correct element name' );
}

{
    my @elements = $w->get_element( type => 'Textarea' );

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'baz', 'correct element name' );
}

{
    my @elements = $w->get_element( name => 'bar' );

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'bar', 'correct element name' );
}

{
    my @elements = $w->get_element( name => 'baz' );

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'baz', 'correct element name' );

    isa_ok(
        $elements[0],
        'HTML::Widget::Element::Textarea',
        'correct element type'
    );
}
