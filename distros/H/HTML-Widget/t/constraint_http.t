use strict;
use warnings;

use Test::More tests => 11;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'HTTP', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'http://oook.de' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'http://oook.de', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '' } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'foo valid' );

    is( $f->param('foo'), '', 'foo is empty string' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'foobar' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query(
        { foo => [ 'http://catalyst.perl.org', 'http://oook.de' ], } );

    my $f = $w->process($query);

    is( $f->valid('foo'), 1, "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 'http://catalyst.perl.org', "Multiple valid values" );
    is( $results[1], 'http://oook.de',           "Multiple valid values" );

    ok( !$f->errors, 'no errors' );
}

# Multiple Invalid
{
    my $query
        = HTMLWidget::TestLib->mock_query( { foo => [ 'yada', 'foo' ], } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}
