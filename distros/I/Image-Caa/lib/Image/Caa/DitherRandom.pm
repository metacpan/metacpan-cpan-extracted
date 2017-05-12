package Image::Caa::DitherRandom;

use strict;
use warnings;

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;

	return $self;
}

sub init {
	srand(time() ^ ($$ + ($$ << 15)));
}

sub get {
	return int(rand(0xff));
}

sub increment {
}


1;