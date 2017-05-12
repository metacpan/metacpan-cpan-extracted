use strict;
use warnings;

use Test::More tests => 5;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;
my ( $foo, $bar, $zoo );

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );
$w->element( 'Textfield', 'zoo' );

$w->constraint( 'CallbackOnce', 'foo', 'bar', 'zoo' )
    ->callback( sub { ( $foo, $bar, $zoo ) = @_; return 1; } );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => '',
            zoo => 'nada',
        } );

    my $f = $w->process($query);

    is( $foo, '', '$foo assigned correctly' );
    ok( !defined $bar, '$bar undef' );
    is( $zoo, 'nada', '$zoo assigned correctly' );

    ok( $f->valid('foo'), 'foo valid' );
    ok( $f->valid('zoo'), 'zoo valid' );
}

