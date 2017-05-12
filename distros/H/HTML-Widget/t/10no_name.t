use strict;
use warnings;

use Test::More tests => 4 + 1;    # extra NoWarnings test
use Test::NoWarnings;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

{
    my $w = HTML::Widget->new;

    $w->element('Block');

    my $f = $w->process;

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><div></div></form>
EOF
}

{
    my $w = HTML::Widget->new;

    my $e = $w->element('Block');
    $e->element('Submit');

    my $f = $w->process;

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><div><input class="submit" type="submit" /></div></form>
EOF
}

{
    my $w = HTML::Widget->new;

    my $fs = $w->element('Fieldset');
    $fs->element( 'Textfield', 'foo' );

    my $f = $w->process;

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" id="widget_foo" name="foo" type="text" /></fieldset></form>
EOF
}

{
    my $w = HTML::Widget->new;

    $w->element( 'Fieldset', 'foo' )
        ->legend( 'the legend of foo' )
        ->element('Fieldset')
            ->legend( 'the legend of blank' )
            ->element( 'Fieldset', 'baz' )
                ->legend( 'the legend of baz' )
                ->element( 'Textfield', 'bar' );

    my $f = $w->process;

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset" id="widget_foo"><legend id="widget_foo_legend">the legend of foo</legend><fieldset class="widget_fieldset"><legend>the legend of blank</legend><fieldset class="widget_fieldset" id="widget_foo_baz"><legend id="widget_foo_baz_legend">the legend of baz</legend><input class="textfield" id="widget_foo_baz_bar" name="bar" type="text" /></fieldset></fieldset></fieldset></form>
EOF
}
