package Kwiki::Image;
use strict;
use warnings;
use Kwiki::Plugin '-Base';

our $VERSION = 0.01;

const class_title => 'Image';
const class_id => 'image';

sub register {
	my $registry = shift;
	$registry->add(wafl => image => 'Kwiki::Image::Wafl');
}

package Kwiki::Image::Wafl;
use Spoon::Formatter;

use base 'Spoon::Formatter::WaflPhrase';

sub html {
	my $string = $self->arguments;
	my ($src,$url,$alt,$class) = split /\s/, $string;
	my $altString = $alt || 'image';
	my $classString = '';
	if ($class) {
		$classString = " class=\"$class\"";
	}
	my $html = "<img src=\"" . $src . "\" alt=\"$altString\"$classString />";
	if ($url) {
		$html = '<a href="' . $url . '">' . $html . '</a>';
	}
	return $html;
}

1;
