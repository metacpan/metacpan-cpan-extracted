use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Link;
use base 'HTML::Tested::Value::Array';
use Carp;

sub value_to_string {
	my ($self, $id, $val, $caller) = @_;
	my $n = $self->name;
	my $l = $caller->ht_get_widget_option($n, "caption");
	$l = shift(@$val) unless defined($l);

	my $f = $caller->ht_get_widget_option($n, "href_format");

	confess "Invalid value in $id link"
		unless ($val && ref($val) eq 'ARRAY');

	my $h = $f ? sprintf($f, @$val) : $val->[0];
	return <<ENDS
<a id="$id" href="$h">$l</a>
ENDS
}

1;
