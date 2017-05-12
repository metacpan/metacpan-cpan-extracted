package HTML::Tag::DATE;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.02';

BEGIN {
	our $class_def	= {
							element			=> 'DATE',
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
	my $js			= $HTML::Tag::DATE::js || $self->js;
	my $ret		=<<"";
  <!-- Load the javascript functions if necessary -->
  <script type="text/javascript" src="$js"></script>
	<input type="text" htmltag="date" name="$name" value="$value" />

	return $ret;
}

sub _normalize_value {
	my $value = shift;
	if ($value eq 'now') {
		my ($day,$month,$year) = (localtime())[3..5];
		$year += 1900;
		$month++; 
		$month 	= "0$month" if length($month) == 1;
		$day 		= "0$day" if length($day) == 1;
		$value 	= "$year-$month-$day";
	}
	return $value;
}


1;

# vim: set ts=2:
