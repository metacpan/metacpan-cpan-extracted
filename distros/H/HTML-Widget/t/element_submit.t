use strict;
use warnings;

use Test::More tests => 4;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Submit', 'foo' )->value('foo');
$w->element( 'Submit', 'bar' );
$w->element( 'Submit', 'foobar' )->src('http://localhost/test.jpg');
$w->element( 'Submit', 'foo1' )->src('test.jpg')->height(10);
$w->element( 'Submit', 'foo2' )->src('test.jpg')->width(10);
$w->element( 'Submit', 'foo3' )->src('test.jpg')->height(10)->width(20);

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="submit" id="widget_foo" name="foo" type="submit" value="foo" /><input class="submit" id="widget_bar" name="bar" type="submit" /><input class="submit" id="widget_foobar" name="foobar" src="http://localhost/test.jpg" type="image" /><input class="submit" height="10" id="widget_foo1" name="foo1" src="test.jpg" type="image" /><input class="submit" id="widget_foo2" name="foo2" src="test.jpg" type="image" width="10" /><input class="submit" height="10" id="widget_foo3" name="foo3" src="test.jpg" type="image" width="20" /></fieldset></form>
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
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="submit" id="widget_foo" name="foo" type="submit" value="yada" /><input class="submit" id="widget_bar" name="bar" type="submit" value="23" /><input class="submit" id="widget_foobar" name="foobar" src="http://localhost/test.jpg" type="image" /><input class="submit" height="10" id="widget_foo1" name="foo1" src="test.jpg" type="image" /><input class="submit" id="widget_foo2" name="foo2" src="test.jpg" type="image" width="10" /><input class="submit" height="10" id="widget_foo3" name="foo3" src="test.jpg" type="image" width="20" /></fieldset></form>
EOF

    ok( !$f->valid('foo') );
    ok( $f->valid('bar') );
}
