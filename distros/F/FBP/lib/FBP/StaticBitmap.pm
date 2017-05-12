package FBP::StaticBitmap;

use Mouse;
use Scalar::Util ();

our $VERSION = '0.41';

extends 'FBP::Window';

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
