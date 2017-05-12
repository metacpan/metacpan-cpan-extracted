use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Variable;
use base 'HTML::Tested::Value';
use HTML::Tested::JavaScript::Serializer;
use JSON::XS;

sub encode_value {
	my ($self, $val) = @_;
	no warnings 'numeric';
	my $d = $val + 0;
	return JSON::XS->new->allow_nonref->encode($val eq $d ? $d + 0 : $val);
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	return HTML::Tested::JavaScript::Serializer::Wrap($name, $val);
}

1;
