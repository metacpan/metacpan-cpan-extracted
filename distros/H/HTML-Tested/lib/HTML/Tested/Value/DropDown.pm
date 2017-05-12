use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::DropDown;
use base 'HTML::Tested::Value::Array';

sub merge_one_value {
	my ($self, $root, $val, @path) = @_;
	my $n = $self->name;
	my $v = $root->{$n};
	if (ref($v)) {
		$_->[2] = $_->[0] eq $val for @$v;
	} else {
		$root->{$n} = $self->transform_value($root, $val, $n);
	}
}

sub transform_value {
	my ($self, $caller, $val, $n) = @_;
	goto OUT if (ref($val) eq 'ARRAY');

	my $dv = $self->get_default_value($caller, $n);
	my @res = map { [ $_->[0], $_->[1], $_->[0] eq $val ] } @$dv;
	$val = \@res;
OUT:
	return [ map { $self->SUPER::transform_value($caller, $_, $n) } @$val ];
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	my $options = join("\n", map {
		my $sel = $_->[2] ? " selected=\"selected\"" : "";
		"<option value=\"$_->[0]\"$sel>$_->[1]</option>"
	} @$val);
	return <<ENDS;
<select id="$name" name="$name">
$options
</select>
ENDS
}

1;
