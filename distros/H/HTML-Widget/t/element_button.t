use strict;
use warnings;

use Test::More tests => 4;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Button', 'foo' )->value('foo');
$w->element( 'Button', 'bar' );

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="button" id="widget_foo" name="foo" type="button" value="foo" /><input class="button" id="widget_bar" name="bar" type="button" /></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => '23',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="button" id="widget_foo" name="foo" type="button" value="yada" /><input class="button" id="widget_bar" name="bar" type="button" value="23" /></fieldset></form>
EOF

    ok( !$f->valid('foo') );
    ok( $f->valid('bar') );
}
