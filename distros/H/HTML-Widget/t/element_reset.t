use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Reset', 'foo' )->value('foo');
$w->element( 'Reset', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="reset" id="widget_foo" name="foo" type="reset" value="foo" /><input class="reset" id="widget_bar" name="bar" type="reset" /></fieldset></form>
EOF
}
