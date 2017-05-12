use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Form;
use base 'HTML::Tested::Value';

sub value_to_string {
	my ($self, $name, $val) = @_;
	return "<form id=\"$name\" name=\"$name\" method=\"post\""
			. " action=\"$val\" enctype=\"multipart/form-data\">\n";
}

1;
