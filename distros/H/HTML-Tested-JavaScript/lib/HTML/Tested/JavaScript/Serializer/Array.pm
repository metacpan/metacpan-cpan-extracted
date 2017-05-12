use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer::Array;
use base 'HTML::Tested::Value::Array';

sub value_to_string {
	my ($self, $name, $val) = @_;
	return '"' . $self->name . "\": [ " . join(", "
		, map { "\"$_\"" } @$val) . " ]";
}

sub absorb_one_value {
	my ($self, $root, $val, @path) = @_;
	my @arr = split(",", $val) if defined($val);
	@arr = map { $self->unseal_value($_, $root) } @arr
			if ($self->options->{is_sealed});
	$root->{ $self->name } = \@arr;
}

1;
