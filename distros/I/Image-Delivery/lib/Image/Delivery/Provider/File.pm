package Image::Delivery::Provider::File;

use strict;
use base 'Image::Delivery::Provider::Scalar';
use File::Slurp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.14';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $file  = (defined $_[0] and -f $_[0] and -r _) ? shift : return undef;

	# Slurp in the image
	my $image = File::Slurp::read_file( $file, scalar_ref => 1 );
	return undef unless ref $image eq 'SCALAR';

	# Hand off to our parent
	$class->SUPER::new( $image, @_ );
}

1;
