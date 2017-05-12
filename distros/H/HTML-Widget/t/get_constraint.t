use strict;
use warnings;

use Test::More tests => 8;

use HTML::Widget;

my $w = HTML::Widget->new;

$w->constraint( 'Integer',   'foo' );
$w->constraint( 'Printable', 'bar' );
$w->constraint( 'All',       'baz', 'one' );
$w->constraint( 'All',       'baz', 'two' );

{
    my @constraints = $w->get_constraint;

    is( scalar(@constraints), 1, 'correct number of constraints' );

    is_deeply( $constraints[0]->names, ['foo'], 'correct constraint names' );
}

{
    my @constraints = $w->get_constraint( type => 'Integer' );

    is( scalar(@constraints), 1, 'correct number of constraints' );

    is_deeply( $constraints[0]->names, ['foo'], 'correct constraint names' );

    isa_ok(
        $constraints[0],
        'HTML::Widget::Constraint::Integer',
        'correct constraint type'
    );
}

{
    my @constraints = $w->get_constraint( type => 'All' );

    is( scalar(@constraints), 1, 'correct number of constraints' );

    is_deeply( $constraints[0]->names,
        [qw/ baz one /], 'correct constraint names' );

    isa_ok(
        $constraints[0],
        'HTML::Widget::Constraint::All',
        'correct constraint type'
    );
}
