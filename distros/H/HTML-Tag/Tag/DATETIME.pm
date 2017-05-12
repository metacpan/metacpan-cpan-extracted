package HTML::Tag::DATETIME;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.02';

BEGIN {
	our $class_def	= {
							element			=> 'DATETIME',
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
	my $js			= $HTML::Tag::DATETIME::js || $self->js;
	my $ret		=<<"";
  <!-- Load the javascript functions if necessary -->
  <script type="text/javascript" src="$js"></script>
	<input type="text" htmltag="datetime" name="$name" value="$value" />

	return $ret;
}

sub _normalize_value {
	my $value = shift;
	if ($value eq 'now') {
		my ($min,$hour,$day,$month,$year) = (localtime())[1..5];
		$year += 1900;
		$month++; 
		$min 	= "0$min" if length($min) == 1;
		$hour 	= "0$hour" if length($hour) == 1;
		$month 	= "0$month" if length($month) == 1;
		$day 		= "0$day" if length($day) == 1;
		$value 	= "$year-$month-$day $hour:$min:00";
	}
	return $value;
}


1;

# vim: set ts=2:
