use strict;
use warnings;

use Test::More tests => 7;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'year' );
$w->element( 'Textfield', 'month' );
$w->element( 'Textfield', 'day' );

$w->constraint( 'Date', 'year', 'month', 'day' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            year  => '2005',
            month => '12',
            day   => '9',
        } );

    my $f = $w->process($query);

    is( $f->param('year'),  2005, 'year value' );
    is( $f->param('month'), 12,   'month value' );
    is( $f->param('day'),   9,    'day value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            year  => '2005',
            month => 'foo',
            day   => '500',
        } );

    my $f = $w->process($query);

    ok( $f->errors('year'),  'year has errors' );
    ok( $f->errors('month'), 'month has errors' );
    ok( $f->errors('day'),   'day has errors' );
}
