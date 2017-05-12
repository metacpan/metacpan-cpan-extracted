package FBP::ControlWithItems;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has choices => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

sub items {
	my $self    = shift;
	my @choices = $self->choices =~ /" ( (?: \\. | . )+? ) "/xg;
	foreach ( @choices ) {
		s/\\(.)/$1/g;
	}
	return @choices;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
