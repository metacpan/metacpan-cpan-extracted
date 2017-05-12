package Image::Caa::DitherOrdered4;

use strict;
use warnings;

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;

	return $self;
}

sub init {
	my ($self, $line) = @_;

	$self->{table} = [
		0x00, 0x80, 0x20, 0xa0,
		0xc0, 0x40, 0xe0, 0x60,
		0x30, 0xb0, 0x10, 0x90,
		0xf0, 0x70, 0xd0, 0x50
	];

	my $skip = ($line % 4) * 4;
	shift @{$self->{table}} for 1..$skip;

	$self->{index} = 0;
}

sub get {
	my ($self) = @_;

	return $self->{table}->[$self->{index}];
}

sub increment {
	my ($self) = @_;

	$self->{index} = ($self->{index} + 1) % 4;
}

1;