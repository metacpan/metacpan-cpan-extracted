package Image::Caa::DriverANSI;

use strict;
use warnings;

sub new {
	my ($class) = @_;

	my $self = bless {}, $class;

	$self->{color_map} = {
		int(Image::Caa::CAA_COLOR_BLACK)	=> [30,1],
		int(Image::Caa::CAA_COLOR_RED)		=> [31,1],
		int(Image::Caa::CAA_COLOR_GREEN)	=> [32,1],
		int(Image::Caa::CAA_COLOR_YELLOW)	=> [33,1],
		int(Image::Caa::CAA_COLOR_BLUE)		=> [34,1],
		int(Image::Caa::CAA_COLOR_MAGENTA)	=> [35,1],
		int(Image::Caa::CAA_COLOR_CYAN)		=> [36,1],
		int(Image::Caa::CAA_COLOR_LIGHTGRAY)	=> [37,1],

		int(Image::Caa::CAA_COLOR_DARKGRAY)	=> [30,0],
		int(Image::Caa::CAA_COLOR_LIGHTRED)	=> [31,0],
		int(Image::Caa::CAA_COLOR_LIGHTGREEN)	=> [32,0],
		int(Image::Caa::CAA_COLOR_BROWN)	=> [33,0],
		int(Image::Caa::CAA_COLOR_LIGHTBLUE)	=> [34,0],
		int(Image::Caa::CAA_COLOR_LIGHTMAGENTA)	=> [35,0],
		int(Image::Caa::CAA_COLOR_LIGHTCYAN)	=> [36,0],
		int(Image::Caa::CAA_COLOR_WHITE)	=> [37,0],
	};

	$self->{color_pairs} = {};

	return $self;
}

sub init {
	my ($self) = @_;

	$self->{current_color_key} = '';
	$self->{last_x} = 0;
}

sub set_color{
	my ($self, $fg, $bg) = @_;

	my $key = "$fg:$bg";

	$self->{current_color_key} = $key;

	if (!defined $self->{color_pairs}->{$key}){

		my ($fg_col, $fg_dark) = @{$self->{color_map}->{$fg}};
		my ($bg_col, $bg_dark) = @{$self->{color_map}->{$bg}};

		$bg_col += 10;

		$self->{color_pairs}->{$key} = "\e[${fg_col};".($fg_dark?2:1).";${bg_col};".($bg_dark?6:5)."m";
	}
}

sub putchar{
	my ($self, $x, $y, $outch) = @_;

	if ($x < $self->{last_x}){

		print "\n";
	}

	$self->{last_x} = $x;

	print $self->{color_pairs}->{$self->{current_color_key}};
	print $outch;
	print "\e[0m";
}

sub fini {
	my ($self) = @_;

	print "\n";
}

1;