use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Submit;
use base 'HTML::Tested::Value';

sub value_to_string {
	my ($self, $name, $val) = @_;
	my $vstr = $val ? " value=\"$val\"" : "";
	return <<ENDS;
<input type="submit" name="$name" id="$name"$vstr />
ENDS
}

1;
