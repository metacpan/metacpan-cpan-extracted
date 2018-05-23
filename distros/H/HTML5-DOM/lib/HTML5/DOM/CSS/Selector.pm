package HTML5::DOM::CSS::Selector;
use strict;
use warnings;

use HTML5::DOM::CSS::Selector::Entry;

use overload
	'""'		=> sub { shift->text }, 
	'@{}'		=> sub { shift->array }, 
	'bool'		=> sub { 1 }, 
	fallback	=> 1;

sub new {
	my ($class, $text) = @_;
	return HTML5::DOM::CSS->new->parseSelector($text);
}

# TODO: implement in XS?
sub array {
	my $self = shift;
	my @tmp;
	my $l = $self->length;
	for (my $i = 0; $i < $l; ++$i) {
		push @tmp, $self->entry($i);
	}
	return \@tmp;
}

1;
__END__
