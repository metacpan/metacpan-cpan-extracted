package Image::Caa::DriverCurses;

use strict;
use warnings;
use Curses;

sub new {
	my ($class, $args) = @_;

	my $self = bless {}, $class;

	$self->{window} = $args->{window};
	$self->{has_color} = 0;

	$self->{color_pair_next} = 1;
	$self->{color_pairs} = {};

	return $self;
}

sub init {
	my ($self) = @_;

	$self->{has_color} = has_colors();

	start_color() if $self->{has_color};
}

sub set_color{
	my ($self, $fg, $bg) = @_;

	return unless $self->{has_color};

	my $bright = $fg > 7;

	$fg -= 8 if $fg > 7;
	$bg -= 8 if $bg > 7;

	my $key = "$fg:$bg";

	if (!defined $self->{color_pairs}->{$key}){

		my $pr = $self->{color_pair_next};
		$self->{color_pair_next}++;

		init_pair($pr, $fg, $bg);
		$self->{color_pairs}->{$key} = $pr;

		print "new pair: $key\n";
	}

	$self->{window}->attron( $bright ? A_BOLD : A_DIM );
	$self->{window}->attron(COLOR_PAIR($self->{color_pairs}->{$key}));
}

sub putchar{
	my ($self, $x, $y, $outch) = @_;

	$self->{window}->addch($y, $x, $outch);
}

sub fini {
	my ($self) = @_;
}


1;