use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::RichEdit;
use base 'HTML::Tested::Value';
use HTML::Tested::JavaScript;
use HTML::Tested::Value::DropDown;

sub new {
	my ($class, $parent, $name, @more) = @_;
	my $self = $class->SUPER::new($parent, $name, @more);
	my @fonts = map { [ $_, $_ ] } ('Arial', 'Courier', 'Times New Roman'
		, 'Courier New', 'Georgia', 'Trebuchet MS', 'Verdana', 'Serif');
	$parent->ht_add_widget('HTML::Tested::Value::DropDown'
		, "$name\_fontname"
		, default_value => [ [ "", "Font" ], @fonts ]);
	$parent->ht_add_widget('HTML::Tested::Value::DropDown'
		, "$name\_fontsize", default_value => [ [ "", "Size" ]
			, map { [ $_, $_ ] } (1 .. 7) ]);
	return $self;
}

my $_src_data = 'data:application/xhtml+xml,' . __PACKAGE__->encode_value(
	'<html xmlns="http://www.w3.org/1999/xhtml"><head></head><body></body></html>');
sub render {
	my ($self, $caller, $stash, $id) = @_;
	my $n = $self->name;
	$stash->{$n} = "<iframe id=\"$n\" src='$_src_data'></iframe>";
	my $scr = '<script src="' . $HTML::Tested::JavaScript::Location
		. '/rich_edit.js">' . "</script>\n";
	
	$scr .= "<script>\nhtre_register_on_load(\"$n\");\n</script>\n"
			unless $caller->ht_get_widget_option($n, "no_onload");
	$stash->{$n . "_script"} = $scr;
}

1;
