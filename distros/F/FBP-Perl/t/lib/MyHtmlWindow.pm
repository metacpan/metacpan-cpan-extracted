package t::lib::MyHtmlWindow;

use strict;
use Wx;
use Wx::Html;

our $VERSION = '0.78';
our @ISA     = 'Wx::HtmlWindow';

sub new {
	shift->SUPER::new(@_);
}

1;
