use strict;
use warnings;

use Test::More tests => 7;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'hour' );
$w->element( 'Textfield', 'minute' );
$w->element( 'Textfield', 'second' );

$w->constraint( 'Time', 'hour', 'minute', 'second' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            hour   => '6',
            minute => '12',
            second => '9',
        } );

    my $f = $w->process($query);

    is( $f->param('hour'),   6,  'hour value' );
    is( $f->param('minute'), 12, 'minute value' );
    is( $f->param('second'), 9,  'second value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            hour   => '6',
            minute => '400',
            second => '5',
        } );

    my $f = $w->process($query);

    ok( $f->errors('hour'),   'hour has errors' );
    ok( $f->errors('minute'), 'minute has errors' );
    ok( $f->errors('second'), 'second has errors' );
}
