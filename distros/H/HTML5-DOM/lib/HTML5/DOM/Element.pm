package HTML5::DOM::Element;
use strict;
use warnings;

use HTML5::DOM::Node;
use HTML5::DOM::TokenList;

our @ISA = ("HTML5::DOM::Node");

sub classList {
	return HTML5::DOM::TokenList->new($_[0], "class");
}

sub className {
	my $class = $_[0]->attr("class");
	return defined $class ? $class : "";
}

1;
