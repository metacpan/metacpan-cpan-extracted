use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Hidden',    'bar' );

{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'é',
            bar => '" foo >',
        } );

    my $f = $w->process($query);

    like( "$f", qr'value="é"', 'utf-8 character ok' );

    like( "$f", qr'value="&#34; foo &#62;"', '' );
}
