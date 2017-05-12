use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Button',     'my_button', )->value(1);
$w->element( 'Checkbox',   'my_checkbox' )->value(1)->checked('checked');
$w->element( 'Checkbox',   'my_checkbox' )->value(0);
$w->element( 'Hidden',     'my_hidden' )->value(1);
$w->element( 'Password',   'my_password' )->value(1)->fill(1);
$w->element( 'Radio',      'my_radio' )->value(1)->checked('checked');
$w->element( 'Radio',      'my_radio' )->value(0);
$w->element( 'RadioGroup', 'my_radiogroup' )->values( 1, 0 )->checked(1);
$w->element( 'Reset',      'my_reset' )->value(1);
$w->element( 'Select',     'my_select' )
    ->options( 0 => 'unsubscribed', 1 => 'subscribed' )->selected(1);
$w->element( 'Submit',    'my_submit' )->value(1);
$w->element( 'Textarea',  'my_textarea' )->value(1);
$w->element( 'Textfield', 'my_textfield' )->value(1);

{
    my $f = $w->process();
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="button" id="widget_my_button" name="my_button" type="button" value="1" /><input checked="checked" class="checkbox" id="widget_my_checkbox_1" name="my_checkbox" type="checkbox" value="1" /><input class="checkbox" id="widget_my_checkbox_2" name="my_checkbox" type="checkbox" value="0" /><input class="hidden" id="widget_my_hidden" name="my_hidden" type="hidden" value="1" /><input class="password" id="widget_my_password" name="my_password" type="password" value="1" /><input checked="checked" class="radio" id="widget_my_radio_1" name="my_radio" type="radio" value="1" /><input class="radio" id="widget_my_radio_2" name="my_radio" type="radio" value="0" /><fieldset class="radiogroup_fieldset" id="widget_my_radiogroup"><span class="radiogroup"><label for="widget_my_radiogroup_1" id="widget_my_radiogroup_1_label"><input checked="checked" class="radio" id="widget_my_radiogroup_1" name="my_radiogroup" type="radio" value="1" />1</label><label for="widget_my_radiogroup_2" id="widget_my_radiogroup_2_label"><input class="radio" id="widget_my_radiogroup_2" name="my_radiogroup" type="radio" value="0" />0</label></span></fieldset><input class="reset" id="widget_my_reset" name="my_reset" type="reset" value="1" /><select class="select" id="widget_my_select" name="my_select"><option value="0">unsubscribed</option><option selected="selected" value="1">subscribed</option></select><input class="submit" id="widget_my_submit" name="my_submit" type="submit" value="1" /><textarea class="textarea" cols="40" id="widget_my_textarea" name="my_textarea" rows="20">1</textarea><input class="textfield" id="widget_my_textfield" name="my_textfield" type="text" value="1" /></fieldset></form>
EOF
}

# make sure XML of the result object has empty values, not defaults

{
    my $query = HTMLWidget::TestLib->mock_query( {} );

    my $f = $w->process($query);

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="button" id="widget_my_button" name="my_button" type="button" /><input class="checkbox" id="widget_my_checkbox_1" name="my_checkbox" type="checkbox" value="1" /><input class="checkbox" id="widget_my_checkbox_2" name="my_checkbox" type="checkbox" value="0" /><input class="hidden" id="widget_my_hidden" name="my_hidden" type="hidden" /><input class="password" id="widget_my_password" name="my_password" type="password" /><input class="radio" id="widget_my_radio_1" name="my_radio" type="radio" value="1" /><input class="radio" id="widget_my_radio_2" name="my_radio" type="radio" value="0" /><fieldset class="radiogroup_fieldset" id="widget_my_radiogroup"><span class="radiogroup"><label for="widget_my_radiogroup_1" id="widget_my_radiogroup_1_label"><input class="radio" id="widget_my_radiogroup_1" name="my_radiogroup" type="radio" value="1" />1</label><label for="widget_my_radiogroup_2" id="widget_my_radiogroup_2_label"><input class="radio" id="widget_my_radiogroup_2" name="my_radiogroup" type="radio" value="0" />0</label></span></fieldset><input class="reset" id="widget_my_reset" name="my_reset" type="reset" /><select class="select" id="widget_my_select" name="my_select"><option value="0">unsubscribed</option><option value="1">subscribed</option></select><input class="submit" id="widget_my_submit" name="my_submit" type="submit" /><textarea class="textarea" cols="40" id="widget_my_textarea" name="my_textarea" rows="20"></textarea><input class="textfield" id="widget_my_textfield" name="my_textfield" type="text" /></fieldset></form>
EOF
}

