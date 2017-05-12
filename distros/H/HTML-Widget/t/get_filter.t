use strict;
use warnings;

use Test::More tests => 8;

use HTML::Widget;

my $w = HTML::Widget->new;

$w->filter( 'HTMLEscape', 'foo' );
$w->filter( 'LowerCase',  'bar' );
$w->filter( 'LowerCase',  'baz' );
$w->filter( 'Whitespace', 'baz' );

{
    my @filters = $w->get_filter;

    is( scalar(@filters), 1, 'correct number of filters' );

    is_deeply( $filters[0]->names, ['foo'], 'correct filter names' );
}

{
    my @filters = $w->get_filter( type => 'Whitespace' );

    is( scalar(@filters), 1, 'correct number of filters' );

    is_deeply( $filters[0]->names, ['baz'], 'correct filter names' );

    isa_ok(
        $filters[0],
        'HTML::Widget::Filter::Whitespace',
        'correct filter type'
    );
}

{
    my @filters = $w->get_filter( type => 'LowerCase' );

    is( scalar(@filters), 1, 'correct number of filters' );

    is_deeply( $filters[0]->names, ['bar'], 'correct filter names' );

    isa_ok(
        $filters[0],
        'HTML::Widget::Filter::LowerCase',
        'correct filter type'
    );
}
