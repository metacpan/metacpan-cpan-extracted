use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Radio;
use base 'HTML::Tested::Value';

sub render {
	my ($self, $caller, $stash, $id) = @_;
	my $n = $self->name;
	my $val = $self->get_value($caller, $id, $n) or return;
	for my $v (@$val) {
		my $ch = '';
		my $opt;
		if (ref($v) eq 'ARRAY') {
			$ch = 'checked ' if $v->[1];
			$opt = $v->[0];
		} else {
			$opt = $v;
		}
		$stash->{"$n\_$opt"} = <<ENDS
<input type="radio" name="$id" id="$n" value="$opt" $ch/>
ENDS
	}
}

1;

