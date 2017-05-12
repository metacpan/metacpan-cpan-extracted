package Image::Delivery::Provider::Scalar;

use strict;
use UNIVERSAL 'isa';
use base 'Image::Delivery::Provider';
use Digest::TransformPath ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.14';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $image = ref $_[0] eq 'SCALAR' ? shift : return undef;
	my %params = @_;

	# Create the object
	my $self = bless {
		image => $image,
		}, $class;

	# Handle arguments
	if ( isa($params{TransformPath}, 'Digest::TransformPath') ) {
		$self->{TransformPath} = $params{TransformPath};
	}
	if ( defined $params{id} and length $params{id} ) {
		$self->{id} = $params{id};
	}
	if ( defined $params{content_type} and length $params{content_type} ) {
		$self->{content_type} = $params{content_type};
	}
	if ( defined $params{extension} and length $params{extension} ) {
		$self->{extension} = $params{extension};
	}

	# Are we allowed to use the image type passed
	my $extension = $self->extension or return undef;
	unless ( grep { $extension eq $_ } $self->filetypes ) {
		# Unsupported file type
		return undef;
	}

	$self;
}

sub image { $_[0]->{image} }

1;
