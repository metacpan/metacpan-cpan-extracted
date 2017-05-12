package Image::Delivery::Provider::IOHandle;

use strict;
use UNIVERSAL 'isa';
use base 'Image::Delivery::Provider::Scalar';
use File::Slurp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.14';
}





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my $handle = isa(ref $_[0], 'IO::Handle') ? shift : return undef;

	# Slurp in the image
	my $image = File::Slurp::read_file( $handle, scalar_ref => 1 );
	return undef unless ref $image eq 'SCALAR';

	# Hand off to our parent
	$class->SUPER::new( $image, @_ );
}

1;
