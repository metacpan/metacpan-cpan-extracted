use strict;
use warnings;

use Test::More tests => 4;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Button', 'foo' )->value('foo')->content('<b>foo</b>');
$w->element( 'Button', 'bar' )->content('<img href="bar.png">')->type('submit');

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><button class="button" id="widget_foo" name="foo" type="button" value="foo"><b>foo</b></button><button class="button" id="widget_bar" name="bar" type="submit"><img href="bar.png"></button></fieldset></form>
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
<form id="widget" method="post"><fieldset class="widget_fieldset"><button class="button" id="widget_foo" name="foo" type="button" value="yada"><b>foo</b></button><button class="button" id="widget_bar" name="bar" type="submit" value="23"><img href="bar.png"></button></fieldset></form>
EOF

    ok( !$f->valid('foo') );
    ok( $f->valid('bar') );
}
