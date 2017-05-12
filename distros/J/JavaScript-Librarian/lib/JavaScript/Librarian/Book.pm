package JavaScript::Librarian::Book;

# A fairly trivial subclass of Algorithm::Dependency::Item, which is also
# required to implement the ->path method, which returns the relative
# path of the actual .js file within the base path.

use strict;
use base 'Algorithm::Dependency::Item';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.00';
}





#####################################################################
# Constructor and Accessors

# Implement a more complex constructor that will allow the use of ANY
# hash of values, as long as after creation, ->id, ->depends and ->path
# all return correctly.
sub new {
	my $class = shift;
	my %hash  = ref $_[0] eq 'HASH' ? %{shift()} : return undef;

	# Create the object
	my $self = bless \%hash, $class;

	# Do our methods all behave correctly
	$self->id   or return undef;
	$self->path or return undef;
	if ( grep { ! defined $_ or ref $_ or $_ eq '' } $self->depends ) {
		return undef;
	}

	$self;
}

sub path { $_[0]->{path} }

1;
