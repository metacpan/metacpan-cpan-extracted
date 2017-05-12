use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->filter( 'HTMLEscape', 'foo' );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => '<p>message</p>',
            bar => '<b>23</b>',
        } );

    my $f = $w->process($query);

    is( $f->param('foo'), '&lt;p&gt;message&lt;/p&gt;', 'foo value' );
    is( $f->param('bar'), '<b>23</b>', 'bar value' );

SKIP: {
    skip "HTML::Element now checks for already-escaped characters - Won't fix", 1;
    
    like(
        "$f",
        qr{\Q value="&#38;lt;p&#38;gt;message&#38;lt;/p&#38;gt;" }x,
        'XML output is double encoded'
    );
    }
}

