use strict;
use warnings;

use Test::More tests => 6;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

my $e = $w->element( 'RadioGroup', 'bar' )->values( [ 'opt1', 'opt2', 'opt3' ] )
    ->value('opt1');

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><fieldset class="radiogroup_fieldset" id="widget_bar"><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input checked="checked" class="radio" id="widget_bar_1" name="bar" type="radio" value="opt1" />Opt1</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="opt2" />Opt2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="opt3" />Opt3</label></span></fieldset></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( { bar => 'opt2' } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><fieldset class="radiogroup_fieldset" id="widget_bar"><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input class="radio" id="widget_bar_1" name="bar" type="radio" value="opt1" />Opt1</label><label for="widget_bar_2" id="widget_bar_2_label"><input checked="checked" class="radio" id="widget_bar_2" name="bar" type="radio" value="opt2" />Opt2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="opt3" />Opt3</label></span></fieldset></fieldset></form>
EOF
}

# With legend
$e->legend('Select One');
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form (label)' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><fieldset class="radiogroup_fieldset" id="widget_bar"><legend class="radiogroup_legend">Select One</legend><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input checked="checked" class="radio" id="widget_bar_1" name="bar" type="radio" value="opt1" />Opt1</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="opt2" />Opt2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="opt3" />Opt3</label></span></fieldset></fieldset></form>
EOF
}

# With label
$e->legend(undef);
$e->label('Choose');

{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form (label)' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><fieldset class="radiogroup_fieldset" id="widget_bar"><span class="radiogroup_label" id="widget_bar_label">Choose</span><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input checked="checked" class="radio" id="widget_bar_1" name="bar" type="radio" value="opt1" />Opt1</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="opt2" />Opt2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="opt3" />Opt3</label></span></fieldset></fieldset></form>
EOF
}

# With comment too
$e->comment('Informed');
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form (label+comment)' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><fieldset class="radiogroup_fieldset" id="widget_bar"><span class="radiogroup_label" id="widget_bar_label">Choose</span><span class="label_comments" id="widget_bar_comment">Informed</span><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input checked="checked" class="radio" id="widget_bar_1" name="bar" type="radio" value="opt1" />Opt1</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="opt2" />Opt2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="opt3" />Opt3</label></span></fieldset></fieldset></form>
EOF
}

# With error
$w->constraint( 'In' => 'bar' )->in('octopus');
{
    my $query = HTMLWidget::TestLib->mock_query( { bar => 'opt2' } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form (label+comment+error)' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="labels_with_errors" id="widget_bar"><fieldset class="radiogroup_fieldset"><span class="radiogroup_label" id="widget_bar_label">Choose</span><span class="label_comments" id="widget_bar_comment">Informed</span><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input class="radio" id="widget_bar_1" name="bar" type="radio" value="opt1" />Opt1</label><label for="widget_bar_2" id="widget_bar_2_label"><input checked="checked" class="radio" id="widget_bar_2" name="bar" type="radio" value="opt2" />Opt2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="opt3" />Opt3</label></span></fieldset></span><span class="error_messages" id="widget_bar_errors"><span class="in_errors" id="widget_bar_error_in">Invalid Input</span></span></fieldset></form>
EOF
}
