package Imager::Graph::Bar;

=head1 NAME

  Imager::Graph::Bar - a tool for drawing bar charts on Imager images

=head1 SYNOPSIS

  use Imager::Graph::Bar;
  use Imager::Font;

  my $font = Imager::Font->new(file => '/path/to/font.ttf') || die "Error: $!";

  my $graph = Imager::Graph::Bar->new();
  $graph->set_image_width(900);
  $graph->set_image_height(600);
  $graph->set_font($font);
  $graph->use_automatic_axis();
  $graph->show_legend();

  my @data = (1, 2, 3, 5, 7, 11);
  my @labels = qw(one two three five seven eleven);

  $graph->add_data_series(\@data, 'Primes');
  $graph->set_labels(\@labels);

  my $img = $graph->draw() || die $graph->error;

  $img->write(file => 'bars.png');



=cut

use strict;
use vars qw(@ISA);
use Imager::Graph::Horizontal;
@ISA = qw(Imager::Graph::Horizontal);

sub _get_default_series_type {
  return 'bar';
}

1;

