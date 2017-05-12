use strict;
use warnings;
use utf8;

use Test::More tests => 13;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'Printable', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query
        = HTMLWidget::TestLib->mock_query( { foo => pack( 'H*', 123456 ), } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 'bar', 'yada' ] } );

    my $f = $w->process($query);

    is( $f->valid('foo'), 1, "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 'bar',  "Multiple valid values" );
    is( $results[1], 'yada', "Multiple valid values" );
}

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query(
        { foo => [ 'yada', pack( 'H*', 123456 ) ], } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

my $c = HTML::Widget::Constraint::Printable->new;

ok( $c->validate("foo"),      "alpha" );
ok( $c->validate("foo bar"),  "alpha, space" );
ok( $c->validate(",la; bar"), "punct" );
ok( $c->validate("יובל"), "hebrew" );
ok( !$c->validate("\x00"),    "zero" );
ok( !$c->validate("\xb"),     "backspace" );

