package JSAN::Librarian::Book;

# Implements a JavaScript::Librarian::Book. In our case, the id IS the path

use strict;
use Params::Util '_HASH0';
use JavaScript::Librarian::Book;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'JavaScript::Librarian::Book';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $path  = shift or return undef;
	my $deps  = _HASH0(shift) or return undef;

	# Create the object
	my $self = bless {
		id      => $path,
		depends => [ keys %$deps ],
		}, $class;

	$self;
}

sub path { $_[0]->{id} }

1;
