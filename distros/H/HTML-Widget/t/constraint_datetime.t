use strict;
use warnings;

use Test::More tests => 13;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'year' );
$w->element( 'Textfield', 'month' );
$w->element( 'Textfield', 'day' );
$w->element( 'Textfield', 'hour' );
$w->element( 'Textfield', 'month' );
$w->element( 'Textfield', 'second' );

$w->constraint( 'DateTime', 'year', 'month', 'day', 'hour', 'minute',
    'second' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            year   => '2005',
            month  => '12',
            day    => '9',
            hour   => '10',
            minute => '25',
            second => '13'
        } );

    my $f = $w->process($query);

    is( $f->param('year'),   2005, 'year value' );
    is( $f->param('month'),  12,   'month value' );
    is( $f->param('day'),    9,    'day value' );
    is( $f->param('hour'),   10,   'hour value' );
    is( $f->param('minute'), 25,   'minute value' );
    is( $f->param('second'), 13,   'second value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            year   => '2005',
            month  => '11',
            day    => '500',
            hour   => '10',
            minute => '15',
            second => '23'
        } );

    my $f = $w->process($query);

    ok( $f->errors('year'),   'year has errors' );
    ok( $f->errors('month'),  'month has errors' );
    ok( $f->errors('day'),    'day has errors' );
    ok( $f->errors('hour'),   'hour has errors' );
    ok( $f->errors('minute'), 'minute has errors' );
    ok( $f->errors('second'), 'second has errors' );
}
