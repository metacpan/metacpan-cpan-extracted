use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer::Value;
use base 'HTML::Tested::JavaScript::Variable';

sub value_to_string {
	my ($self, $name, $val) = @_;
	# it should be $self->name here because we don't encode it as list
	return '"' . $self->name . "\": $val";
}

1;
