package Image::Caa::DitherOrdered2;

use strict;
use warnings;

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;

	return $self;
}

sub init {
	my ($self, $line) = @_;

	$self->{table} = [0x00, 0x80, 0xc0, 0x40];

	my $skip = ($line % 2) * 2;
	shift @{$self->{table}} for 1..$skip;

	$self->{index} = 0;
}

sub get {
	my ($self) = @_;

	return $self->{table}->[$self->{index}];
}

sub increment {
	my ($self) = @_;

	$self->{index} = ($self->{index} + 1) % 2;
}

1;