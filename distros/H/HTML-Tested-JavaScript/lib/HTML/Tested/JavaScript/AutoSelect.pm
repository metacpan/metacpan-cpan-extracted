use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::AutoSelect;
use base 'HTML::Tested::Value::DropDown';

sub value_to_string {
	my ($self, $name, $val) = @_;
	my $res = $self->SUPER::value_to_string($name, $val);
	my $href = $self->options->{href} || "?$name=";
	return <<ENDS
<form>$res</form>
<script>
document.getElementById("$name").onchange = function() {
	document.location.href = "$href" + this.options[
		this.selectedIndex ].value;
};
</script>
ENDS
}

1;
