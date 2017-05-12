package Image::Caa::DriverTest;

use strict;
use warnings;

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;

	return $self;
}

sub init {
	my ($self) = @_;

	$self->{color} = '';
	$self->{data} = {};
	$self->{buffer} = '';
}

sub set_color{
	my ($self, $fg, $bg) = @_;

	$self->{color} = "$fg:$bg";
	$self->{buffer} .= "($fg:$bg)";
}

sub putchar{
	my ($self, $x, $y, $outch) = @_;

	$self->{data}->{"$x,$y"} = "$self->{color}:$outch";
	$self->{buffer} .= $outch;
}

sub fini {
	my ($self) = @_;
}

1;