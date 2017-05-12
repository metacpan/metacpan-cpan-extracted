package HTML::Tag::TIME;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.06';

BEGIN {
	our $class_def	= {
							element			=> 'TIME',
							tag 				=> 'SELECT',
							js					=> 'html_tag_datetime_loader.js',
							value				=> '',
	}
}

sub html {
	my $self		= shift;
	my $name		= $self->name;
	my $value		= $self->value;

	$value 			= &_normalize_value($value);
	my $js			= $HTML::Tag::TIME::js || $self->js;
	my $ret		=<<"";
  <!-- Load the javascript functions if necessary -->
  <script type="text/javascript" src="$js"></script>
	<input type="text" htmltag="time" name="$name" value="$value" />

	return $ret;
}

sub _normalize_value {
	my $value = shift;
	if ($value eq 'now') {
		my ($min,$hour) = (localtime())[1..2];
		$min 	= "0$min" if length($min) == 1;
		$hour 		= "0$hour" if length($hour) == 1;
		$value 	= "$hour:$min";
	}
	return $value;
}


1;

# vim: set ts=2:
