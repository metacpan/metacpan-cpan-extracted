use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new->tag('span')->subtag('span');

$w->element( 'Span', 'foo' )->content('foo');
$w->element( 'Span', 'bar' );

my $b = HTML::Element->new('b');
$b->push_content('bold text');

$w->element( 'Span', 'baz' )->content($b);

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<span id="widget"><span><span class="span" id="widget_foo">foo</span><span class="span" id="widget_bar"></span><span class="span" id="widget_baz"><b>bold text</b></span></span></span>
EOF
}
