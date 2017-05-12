use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::ColorPicker;
use base 'HTML::Tested::Value';
use HTML::Tested qw(HTV);
use HTML::Tested::JavaScript qw($Location);

sub new {
	my ($class, $parent, $name, @more) = @_;
	my $self = $class->SUPER::new($parent, $name, @more);
	$parent->ht_add_widget(HTV, "$name\_color_style", is_trusted => 1
			, default_value => <<ENDS);
#$name\_color {
	-moz-user-select: none;
	position: relative;
	background-image: url($Location/images/color_picker.png);
	background-color: #FF0000;
	background-repeat: no-repeat;
	background-position: -6px -6px;
	height: 180px;
	width: 180px;
}

#$name\_color_pointer {
	top: -5.5px;
	left: -5.5px;
	width: 11px;
	height: 11px;
	position: absolute;
	background-position: -6px -188px;
	background-image: url($Location/images/color_picker.png);
}
ENDS
	$parent->ht_add_widget(HTV, "$name\_color", is_trusted => 1
			, default_value => <<ENDS);
<div id="$name\_color"><div id="$name\_color_pointer"></div></div>
ENDS
	$parent->ht_add_widget(HTV, "$name\_hue_style", is_trusted => 1
			, default_value => <<ENDS);
#$name\_hue {
	-moz-user-select: none;
	position: relative;
	background-image: url($Location/images/color_picker.png);
	width: 16px;
	height: 180px;
	background-position: -196px -6px;
	background-repeat: no-repeat;
}

#$name\_hue_pointer {
	width: 27px;
	height: 9px;
	position: absolute;
	top: -4.5px;
	left: -5px;
	background-image: url($Location/images/color_picker.png);
	background-position: -22px -188px;
}
ENDS
	$parent->ht_add_widget(HTV, "$name\_hue", is_trusted => 1
			, default_value => <<ENDS);
<div id="$name\_hue"><div id="$name\_hue_pointer"></div></div>
ENDS
	$parent->ht_add_widget(HTV, "$name\_rgb_$_", is_trusted => 1
			, default_value => <<ENDS)
<input type="text" id="$name\_rgb_$_" size="2" />
ENDS
		for qw(r g b);
	$parent->ht_add_widget(HTV, "$name\_color_sample_style", is_trusted => 1
			, default_value => <<ENDS);
#$name\_current_color {
	width: 60px;
	height: 60px;
	border: 2px solid #999;
	position: relative;
}

#$name\_prev_color {
	position: absolute;
	top: 50%;
	height: 50%;
	width: 100%;
}
ENDS
	$parent->ht_add_widget(HTV, "$name\_color_sample", is_trusted => 1
			, default_value => <<ENDS);
<div id="$name\_current_color"><div id="$name\_prev_color"></div></div>
ENDS
	$parent->ht_add_widget(HTV, "$name\_rgb_hex", is_trusted => 1
			, default_value => <<ENDS);
<input size="5" id="$name\_rgb_hex" type="text" />
ENDS
	return $self;
}

1;
