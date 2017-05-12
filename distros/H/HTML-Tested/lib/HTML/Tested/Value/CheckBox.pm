use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::CheckBox;
use base 'HTML::Tested::Value::Array';

sub transform_value {
	my ($self, $caller, $val, $n) = @_;
	$val = [ 1, $val ] if (!$val || !ref($val));
	return $self->SUPER::transform_value($caller, $val, $n);
}

sub merge_one_value {
	my ($self, $root, $val, @path) = @_;
	my $n = $self->name;
	my $c = $root->$n;
	if (!$c || !ref($c)) {
		$root->$n($val);
	} else {
		push @{ $root->$n }, $val;
	}
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	my $che = $val->[1] ? " checked=\"1\"" : "";
	return <<ENDS
<input type="checkbox" id="$name" name="$name" value="$val->[0]"$che />
ENDS
}

sub finish_load {
	my ($self, $root) = @_;
	my $n = $self->name;
	return if $root->$n || $root->ht_get_widget_option($n, "keep_undef");
	$root->$n(0);
}

1;
