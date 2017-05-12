use strict;
use warnings;

use Test::More tests => 17;

use HTML::Widget;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );
$w->element( 'Textarea',  'baz' );
$w->element( 'Password',  'baz' );

{
    my @elements = $w->get_elements;

    is( scalar(@elements), 4, 'correct number of elements' );

    is( $elements[0]->name, 'foo', 'correct element name' );
    is( $elements[1]->name, 'bar', 'correct element name' );
    is( $elements[2]->name, 'baz', 'correct element name' );
    is( $elements[3]->name, 'baz', 'correct element name' );
}

{
    my @elements = $w->get_elements( type => 'Textfield' );

    is( scalar(@elements), 2, 'correct number of elements' );

    is( $elements[0]->name, 'foo', 'correct element name' );
    is( $elements[1]->name, 'bar', 'correct element name' );
}

{
    my @elements = $w->get_elements( type => 'Textarea' );

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'baz', 'correct element name' );
}

{
    my @elements = $w->get_elements( name => 'bar' );

    is( scalar(@elements), 1, 'correct number of elements' );

    is( $elements[0]->name, 'bar', 'correct element name' );
}

{
    my @elements = $w->get_elements( name => 'baz' );

    is( scalar(@elements), 2, 'correct number of elements' );

    is( $elements[0]->name, 'baz', 'correct element name' );
    is( $elements[1]->name, 'baz', 'correct element name' );

    isa_ok(
        $elements[0],
        'HTML::Widget::Element::Textarea',
        'correct element type'
    );
    isa_ok(
        $elements[1],
        'HTML::Widget::Element::Password',
        'correct element type'
    );
}
