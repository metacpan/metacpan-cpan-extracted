package Imager::Graph::StackedColumn;

=head1 NAME

  Imager::Graph::StackedColumn - a tool for drawing stacked column charts on Imager images

=head1 SYNOPSIS

  use Imager::Graph::StackedColumn;
  use Imager::Font;

  my $font = Imager::Font->new(file => '/path/to/font.ttf') || die "Error: $!";

  my $graph = Imager::Graph::StackedColumn->new();
  $graph->set_image_width(900);
  $graph->set_image_height(600);
  $graph->set_font($font);
  $graph->use_automatic_axis();
  $graph->show_legend();

  my @data = (1, 2, 3, 5, 7, 11);
  my @data2 = (1, 1, 1, 2, 2, 2);
  my @labels = qw(one two three five seven eleven);

  $graph->add_data_series(\@data, 'Primes');
  $graph->add_data_series(\@data2, 'Numbers');
  $graph->set_labels(\@labels);

  my $img = $graph->draw() || die $graph->error;

  $img->write(file => 'columns.png');

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph::Vertical;
@ISA = qw(Imager::Graph::Vertical);

sub _get_default_series_type {
  return 'stacked_column';
}

1;

