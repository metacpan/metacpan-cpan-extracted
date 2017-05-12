use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::TextArea;
use base 'HTML::Tested::Value';

sub value_to_string {
	my ($self, $name, $val) = @_;
	return <<ENDS;
<textarea name="$name" id="$name">$val</textarea>
ENDS
}

1;
