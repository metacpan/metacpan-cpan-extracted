package Graph::Writer::DSM;
$Graph::Writer::DSM::VERSION = '0.008';
use Modern::Perl;
use base qw( Graph::Writer );
use List::MoreUtils qw( uniq first_index apply );
use Chart::Gnuplot;
use File::Temp;

=head1 NAME

Graph::Writer::DSM - draw graph as a DSM matrix

=head1 VERSION

version 0.008

=head1 DESCRIPTION

Write graph as a quadractic matrix N x N, where N is the number of vertices in
the graph. It is useful to visualize graphs with at least 1k vertices.

See more about DSM: L<http://en.wikipedia.org/wiki/Design_structure_matrix>.

=head1 SYNOPSIS

    use Graph;
    use Graph::Writer::DSM;
    my $graph = Graph->new();
    my $writer = Graph::Writer::DSM->new(%OPTIONS);
    $writer->write_graph($graph, "output.png");

=head1 METHODS

=head1 new()

Like L<Graph::Writer::GraphViz>, this module provide some extra parameters
to new() method.

    $writer = Graph::Writer::DSM->new(color => 'red');

Supported parameters are:

=over 4

=item pointsize

Default: 0.2.

=item color

Default: 'blue'.

=item tics_label

Default: false.

=back

=cut
 
sub _init  {
  my ($self, %param) = @_;
  $self->SUPER::_init();
  $self->{_dsm_point_size} = $param{pointsize} // 0.2;
  $self->{_dsm_color} = $param{color} // 'blue';
  $self->{_dsm_tics_label} = $param{tics_label} // undef;
}

sub _move_file_to_filehandle {
  my ($file, $FILEHANDLE) = @_;
  open FILE, '<', $file;
  local $/ = undef;
  my $FILE = <FILE>;
  close FILE;
  print $FILEHANDLE $FILE;
  unlink $file;
}

=head1 write_graph()

Write a specific graph to a named file:

    $writer->write_graph($graph, $file);

The $file argument can either be a filename, or a filehandle for a previously
opened file.

=cut

sub _write_graph {
  my ($self, $graph, $FILE) = @_;
  my @vertices = uniq sort $graph->vertices;
  my $output_temp = File::Temp::tempnam('/tmp', 'chart') . '.png';

  if ($self->{_dsm_tics_label}) {
    my $i = -1;
    my @y_labels = map { $i++; "'$_ $i' $i" } apply { s/.*\///; $_ } @vertices;
    $self->{_dsm_ytics} = { labels => \@y_labels };
    $self->{_dsm_x2tics} = [0 .. $#vertices];
  }
  else {
    $self->{_dsm_ytics} = [0, $#vertices];
    $self->{_dsm_x2tics} = [0, $#vertices];
  }

  my $chart = Chart::Gnuplot->new(
    x2range  => [0, $#vertices],
    xrange   => [0, $#vertices],
    yrange   => [$#vertices, 0],
    output   => $output_temp,
    bg       => 'white',
    xtics    => undef,
    x2tics   => $self->{_dsm_x2tics},
    ytics    => $self->{_dsm_ytics},
    size     => 'ratio 1',
    terminal => 'png',
  );
  my @points = ();
  my @edges = $graph->edges;
  foreach my $edge (@edges) {
    my $col = first_index { $_ eq $edge->[0] } @vertices;
    my $row = first_index { $_ eq $edge->[1] } @vertices;
    push @points, [$row, $col];
  }
  my $dataSet = Chart::Gnuplot::DataSet->new(
    points     => \@points,
    style      => 'points',
    color      => $self->{_dsm_color},
    pointtype  => 5,
    pointsize  => $self->{_dsm_point_size},
  );
  $chart->plot2d($dataSet);
  _move_file_to_filehandle($output_temp, \*$FILE);
  return 1;
}
   
1;

=head1 SEE ALSO

L<Graph>, L<Graph::Writer>, L<Chart::Gnuplot>.

=head1 COPYRIGHT

Copyright (c) 2013, Joenio Costa
