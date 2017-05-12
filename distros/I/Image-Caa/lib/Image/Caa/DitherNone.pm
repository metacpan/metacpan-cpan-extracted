package Image::Caa::DitherNone;

use strict;
use warnings;

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;

	return $self;
}

sub init {
}

sub get {
	return 0x80;
}

sub increment {
}


1;