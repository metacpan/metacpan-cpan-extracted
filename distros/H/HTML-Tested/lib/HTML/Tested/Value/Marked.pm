use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Marked;
use base 'HTML::Tested::Value';

sub value_to_string {
	my ($self, $name, $val) = @_;
	return "<!-- $name --> $val";
}

1;
