use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->empty_errors(1);

$w->element( 'Textfield', 'foo' );

$w->constraint( 'All', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" type="text" value="yada" /></span><span class="error_messages" id="widget_foo_errors"></span></fieldset></form>
EOF
}
