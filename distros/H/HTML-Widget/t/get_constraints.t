use strict;
use warnings;

use Test::More tests => 13;

use HTML::Widget;

my $w = HTML::Widget->new;

$w->constraint( 'Integer',   'foo' );
$w->constraint( 'Printable', 'bar' );
$w->constraint( 'All',       'baz', 'one' );
$w->constraint( 'All',       'baz', 'two' );

{
    my @constraints = $w->get_constraints;

    is( scalar(@constraints), 4, 'correct number of constraints' );

    is_deeply( $constraints[0]->names, ['foo'], 'correct constraint names' );
    is_deeply( $constraints[1]->names, ['bar'], 'correct constraint names' );
    is_deeply( $constraints[2]->names,
        [qw/ baz one /], 'correct constraint names' );
    is_deeply( $constraints[3]->names,
        [qw/ baz two /], 'correct constraint names' );
}

{
    my @constraints = $w->get_constraints( type => 'Integer' );

    is( scalar(@constraints), 1, 'correct number of constraints' );

    is_deeply( $constraints[0]->names, ['foo'], 'correct constraint names' );

    isa_ok(
        $constraints[0],
        'HTML::Widget::Constraint::Integer',
        'correct constraint type'
    );
}

{
    my @constraints = $w->get_constraints( type => 'All' );

    is( scalar(@constraints), 2, 'correct number of constraints' );

    is_deeply( $constraints[0]->names,
        [qw/ baz one /], 'correct constraint names' );

    is_deeply( $constraints[1]->names,
        [qw/ baz two /], 'correct constraint names' );

    isa_ok(
        $constraints[0],
        'HTML::Widget::Constraint::All',
        'correct constraint type'
    );

    isa_ok(
        $constraints[1],
        'HTML::Widget::Constraint::All',
        'correct constraint type'
    );
}
