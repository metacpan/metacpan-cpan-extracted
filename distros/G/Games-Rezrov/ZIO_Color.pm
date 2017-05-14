package Games::Rezrov::ZIO_Color;
#
#  stuff for ZIOs that have color support
#

use strict;
use Games::Rezrov::MethodMaker qw(

			   cc
			   fg
			   bg
			   default_fg
			   default_bg
			   sfg
			   sbg

);

use constant DEFAULT_BACKGROUND_COLOR => 'blue';
use constant DEFAULT_FOREGROUND_COLOR => 'white';
use constant DEFAULT_CURSOR_COLOR => 'black';

sub parse_color_options {
  # - interpret standard command-line options for colors
  # - set up defaults
  my ($self, $options) = @_;
  my $fg = lc($options->{"fg"} || DEFAULT_FOREGROUND_COLOR);
  my $bg = lc($options->{"bg"} || DEFAULT_BACKGROUND_COLOR);
  my $sfg = lc($options->{"sfg"} || $bg);
  my $sbg = lc($options->{"sbg"} || $fg);
  # status line: default to inverse of foreground/background colors

  $self->fg($fg);
  $self->bg($bg);
  $self->default_fg($fg);
  $self->default_bg($bg);
  $self->sfg($sfg);
  $self->sbg($sbg);

  my $cc = lc($options->{"cc"} || DEFAULT_CURSOR_COLOR);
  $self->cc($cc eq $bg ? $fg : $cc);
  # if cursor color is the same as the background color,
  # change it to the foreground color
}

1;
