package JSAN::Librarian::Library;

# Implements a JavaScript::Librarian::Library object from a Config::Tiny
# index of a JSAN installed lib.

use strict;
use Config::Tiny          ();
use Params::Util          '_INSTANCE';
use JSAN::Librarian::Book ();
use JavaScript::Librarian::Library;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'JavaScript::Librarian::Library';
}





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my $config = undef;
	if ( _INSTANCE($_[0], 'Config::Tiny') ) {
		$config = shift;
	} elsif ( defined _STRING($_[0]) ) {
		$config = Config::Tiny->read($_[0]) or return undef;
	} else {
		return undef;
	}

	# Remove any root entries
	delete $config->{_};

	# Create the object
	my $self = bless {
		config => $config,
	}, $class;

	$self;
}

sub _load_item_list {
	my $self   = shift;
	my @books  = ();
	my $config = $self->{config};
	foreach my $book ( keys %$config ) {
		push @books, JSAN::Librarian::Book->new( $book, $config->{$book} );
	}
	return \@books;
}

1;
