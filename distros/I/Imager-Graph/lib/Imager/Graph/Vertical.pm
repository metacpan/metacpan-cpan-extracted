package Imager::Graph::Vertical;

=head1 NAME

Imager::Graph::Vertical- A super class for line/bar/column/area charts

=head1 SYNOPSIS

  use Imager::Graph::Vertical;

  my $vert = Imager::Graph::Vertical->new;
  $vert->add_column_data_series(\@data, "My data");
  $vert->add_area_data_series(\@data2, "Area data");
  $vert->add_stacked_column_data_series(\@data3, "stacked data");
  $vert->add_line_data_series(\@data4, "line data");
  my $img = $vert->draw();

  use Imager::Graph::Column;
  my $column = Imager::Graph::Column->new;
  $column->add_data_series(\@data, "my data");
  my $img = $column->draw();

=head1 DESCRIPTION

This is a base class that implements the functionality for column,
stacked column, line and area charts where the dependent variable is
represented in changes in the vertical position.

The subclasses, L<Imager::Graph::Column>,
L<Imager::Graph::StackedColumn>, L<Imager::Graph::Line> and
L<Imager::Graph::Area> simply provide default data series types.

=head1 METHODS

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph;
@ISA = qw(Imager::Graph);
use Imager::Fill;

our $VERSION = "0.11";

use constant STARTING_MIN_VALUE => 99999;

=over

=item add_data_series(\@data, $series_name)

Add a data series to the graph, of the default type.  This requires
that the graph object be one of the derived graph classes.

=cut

sub add_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  my $series_type = $self->_get_default_series_type();
  $self->_add_data_series($series_type, $data_ref, $series_name);

  return;
}

=item add_column_data_series(\@data, $series_name)

Add a column data series to the graph.

=cut

sub add_column_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('column', $data_ref, $series_name);

  return;
}

=item add_stacked_column_data_series(\@data, $series_name)

Add a stacked column data series to the graph.

=cut

sub add_stacked_column_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('stacked_column', $data_ref, $series_name);

  return;
}

=item add_line_data_series(\@data, $series_name)

Add a line data series to the graph.

=cut

sub add_line_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('line', $data_ref, $series_name);

  return;
}

=item add_area_data_series(\@data, $series_name)

Add a area data series to the graph.

=cut

sub add_area_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('area', $data_ref, $series_name);

  return;
}

=item set_y_max($value)

Sets the maximum y value to be displayed.  This will be ignored if the
y_max is lower than the highest value.

=cut

sub set_y_max {
  $_[0]->{'custom_style'}->{'y_max'} = $_[1];
}

=item set_y_min($value)

Sets the minimum y value to be displayed.  This will be ignored if the
y_min is higher than the lowest value.

=cut

sub set_y_min {
  $_[0]->{'custom_style'}->{'y_min'} = $_[1];
}

=item set_column_padding($int)

Sets the padding between columns.  This is a percentage of the column
width.  Defaults to 0.

=cut

sub set_column_padding {
  $_[0]->{'custom_style'}->{'column_padding'} = $_[1];
}

=item set_range_padding($percentage)

Sets the padding to be used, as a percentage.  For example, if your
data ranges from 0 to 10, and you have a 20 percent padding, the y
axis will go to 12.

Defaults to 10.  This attribute is ignored for positive numbers if
set_y_max() has been called, and ignored for negative numbers if
set_y_min() has been called.

=cut

sub set_range_padding {
  $_[0]->{'custom_style'}->{'range_padding'} = $_[1];
}

=item set_negative_background($color)

Sets the background color or fill used below the x axis.

=cut

sub set_negative_background {
  $_[0]->{'custom_style'}->{'negative_bg'} = $_[1];
}

=item draw()

Draw the graph

=cut

sub draw {
  my ($self, %opts) = @_;

  if (!$self->_valid_input()) {
    return;
  }

  $self->_style_setup(\%opts);

  my $style = $self->{_style};

  $self->_make_img
    or return;

  my $img = $self->_get_image()
    or return;

  my @image_box = ( 0, 0, $img->getwidth-1, $img->getheight-1 );
  $self->_set_image_box(\@image_box);

  my @chart_box = ( 0, 0, $img->getwidth-1, $img->getheight-1 );
  $self->_draw_legend(\@chart_box);
  if ($style->{title}{text}) {
    $self->_draw_title($img, \@chart_box)
      or return;
  }

  # Scale the graph box down to the widest graph that can cleanly hold the # of columns.
  return unless $self->_get_data_range();
  $self->_remove_tics_from_chart_box(\@chart_box, \%opts);
  my $column_count = $self->_get_column_count();

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');

  my $graph_width = $chart_box[2] - $chart_box[0];
  my $graph_height = $chart_box[3] - $chart_box[1];

  my $col_width = ($graph_width - 1) / $column_count;
  if ($col_width > 1) {
    $graph_width = int($col_width) * $column_count + 1;
  }
  else {
    $graph_width = $col_width * $column_count + 1;
  }

  my $tic_count = $self->_get_y_tics();
  my $tic_distance = ($graph_height-1) / ($tic_count - 1);
  $graph_height = int($tic_distance * ($tic_count - 1));

  my $top  = $chart_box[1];
  my $left = $chart_box[0];

  $self->{'_style'}{'graph_width'} = $graph_width;
  $self->{'_style'}{'graph_height'} = $graph_height;

  my @graph_box = ($left, $top, $left + $graph_width, $top + $graph_height);
  $self->_set_graph_box(\@graph_box);

  my @fill_box = ( $left, $top, $left+$graph_width, $top+$graph_height );
  if ($self->_feature_enabled("graph_outline")) {
    my @line = $self->_get_line("graph.outline")
      or return;

    $self->_box(
		@line,
		box => \@fill_box,
		img => $img,
	       );
    ++$fill_box[0];
    ++$fill_box[1];
    --$fill_box[2];
    --$fill_box[3];
  }

  $img->box(
            $self->_get_fill('graph.fill'),
	    box => \@fill_box,
	   );

  my $min_value = $self->_get_min_value();
  my $max_value = $self->_get_max_value();
  my $value_range = $max_value - $min_value;

  my $zero_position;
  if ($value_range) {
    $zero_position =  $top + $graph_height - (-1*$min_value / $value_range) * ($graph_height-1);
  }

  if ($min_value < 0) {
    my @neg_box = ( $left + 1, $zero_position, $left+$graph_width- 1, $top+$graph_height - 1 );
    my @neg_fill = $self->_get_fill('negative_bg', \@neg_box)
      or return;
    $img->box(
	      @neg_fill,
	      box => \@neg_box,
    );
    $img->line(
            x1 => $left+1,
            y1 => $zero_position,
            x2 => $left + $graph_width,
            y2 => $zero_position,
            color => $self->_get_color('outline.line'),
    );
  }

  $self->_reset_series_counter();

  if ($self->_get_data_series()->{'stacked_column'}) {
    return unless $self->_draw_stacked_columns();
  }
  if ($self->_get_data_series()->{'column'}) {
    return unless $self->_draw_columns();
  }
  if ($self->_get_data_series()->{'line'}) {
    return unless $self->_draw_lines();
  }
  if ($self->_get_data_series()->{'area'}) {
    return unless $self->_draw_area();
  }

  if ($self->_get_y_tics()) {
    $self->_draw_y_tics();
  }
  if ($self->_get_labels(\%opts)) {
    $self->_draw_x_tics(\%opts);
  }

  return $self->_get_image();
}

sub _get_data_range {
  my $self = shift;

  my $max_value = 0;
  my $min_value = 0;
  my $column_count = 0;

  my ($sc_min, $sc_max, $sc_cols) = $self->_get_stacked_column_range();
  my ($c_min, $c_max, $c_cols) = $self->_get_column_range();
  my ($l_min, $l_max, $l_cols) = $self->_get_line_range();
  my ($a_min, $a_max, $a_cols) = $self->_get_area_range();

  # These are side by side...
  $sc_cols += $c_cols;

  $min_value = $self->_min(STARTING_MIN_VALUE, $sc_min, $c_min, $l_min, $a_min);
  $max_value = $self->_max(0, $sc_max, $c_max, $l_max, $a_max);

  my $config_min = $self->_get_number('y_min');
  my $config_max = $self->_get_number('y_max');

  if (defined $config_max && $config_max < $max_value) {
    $config_max = undef;
  }
  if (defined $config_min && $config_min > $min_value) {
    $config_min = undef;
  }

  my $range_padding = $self->_get_number('range_padding');
  if (defined $config_min) {
    $min_value = $config_min;
  }
  else {
    if ($min_value > 0) {
      $min_value = 0;
    }
    if ($range_padding && $min_value < 0) {
      my $difference = $min_value * $range_padding / 100;
      if ($min_value < -1 && $difference > -1) {
        $difference = -1;
      }
      $min_value += $difference;
    }
  }
  if (defined $config_max) {
    $max_value = $config_max;
  }
  else {
    if ($range_padding && $max_value > 0) {
      my $difference = $max_value * $range_padding / 100;
      if ($max_value > 1 && $difference < 1) {
        $difference = 1;
      }
      $max_value += $difference;
    }
  }
  $column_count = $self->_max(0, $sc_cols, $l_cols, $a_cols);

  if ($self->_get_number('automatic_axis')) {
    # In case this was set via a style, and not by the api method
    eval { require Chart::Math::Axis; };
    if ($@) {
      return $self->_error("Can't use automatic_axis - $@");
    }

    my $axis = Chart::Math::Axis->new();
    $axis->include_zero();
    $axis->add_data($min_value, $max_value);
    $max_value = $axis->top;
    $min_value = $axis->bottom;
    my $ticks     = $axis->ticks;
    # The +1 is there because we have the bottom tick as well
    $self->set_y_tics($ticks+1);
  }

  $self->_set_max_value($max_value);
  $self->_set_min_value($min_value);
  $self->_set_column_count($column_count);

  return 1;
}

sub _min {
  my $self = shift;
  my $min = shift;

  foreach my $value (@_) {
    next unless defined $value;
    if ($value < $min) { $min = $value; }
  }
  return $min;
}

sub _max {
  my $self = shift;
  my $min = shift;

  foreach my $value (@_) {
    next unless defined $value;
    if ($value > $min) { $min = $value; }
  }
  return $min;
}

sub _get_line_range {
  my $self = shift;
  my $series = $self->_get_data_series()->{'line'};
  return (undef, undef, 0) unless $series;

  my $max_value = 0;
  my $min_value = STARTING_MIN_VALUE;
  my $column_count = 0;

  my @series = @{$series};
  foreach my $series (@series) {
    my @data = @{$series->{'data'}};

    if (scalar @data > $column_count) {
      $column_count = scalar @data;
    }

    foreach my $value (@data) {
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
  }

  return ($min_value, $max_value, $column_count);
}

sub _get_area_range {
  my $self = shift;
  my $series = $self->_get_data_series()->{'area'};
  return (undef, undef, 0) unless $series;

  my $max_value = 0;
  my $min_value = STARTING_MIN_VALUE;
  my $column_count = 0;

  my @series = @{$series};
  foreach my $series (@series) {
    my @data = @{$series->{'data'}};

    if (scalar @data > $column_count) {
      $column_count = scalar @data;
    }

    foreach my $value (@data) {
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
  }

  return ($min_value, $max_value, $column_count);
}


sub _get_column_range {
  my $self = shift;

  my $series = $self->_get_data_series()->{'column'};
  return (undef, undef, 0) unless $series;

  my $max_value = 0;
  my $min_value = STARTING_MIN_VALUE;
  my $column_count = 0;

  my @series = @{$series};
  foreach my $series (@series) {
    my @data = @{$series->{'data'}};

    foreach my $value (@data) {
      $column_count++;
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
  }

  return ($min_value, $max_value, $column_count);
}

sub _get_stacked_column_range {
  my $self = shift;

  my $max_value = 0;
  my $min_value = STARTING_MIN_VALUE;
  my $column_count = 0;

  return (undef, undef, 0) unless $self->_get_data_series()->{'stacked_column'};
  my @series = @{$self->_get_data_series()->{'stacked_column'}};

  my @max_entries;
  my @min_entries;
  for (my $i = scalar @series - 1; $i >= 0; $i--) {
    my $series = $series[$i];
    my $data = $series->{'data'};

    for (my $i = 0; $i < scalar @$data; $i++) {
      my $value = 0;
      if ($data->[$i] > 0) {
        $value = $data->[$i] + ($max_entries[$i] || 0);
        $data->[$i] = $value;
        $max_entries[$i] = $value;
      }
      elsif ($data->[$i] < 0) {
        $value = $data->[$i] + ($min_entries[$i] || 0);
        $data->[$i] = $value;
        $min_entries[$i] = $value;
      }
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
    if (scalar @$data > $column_count) {
      $column_count = scalar @$data;
    }
  }

  return ($min_value, $max_value, $column_count);
}

sub _draw_legend {
  my $self = shift;
  my $chart_box = shift;
  my $style = $self->{'_style'};

  my @labels;
  my $img = $self->_get_image();
  if (my $series = $self->_get_data_series()->{'stacked_column'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }
  if (my $series = $self->_get_data_series()->{'column'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }
  if (my $series = $self->_get_data_series()->{'line'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }
  if (my $series = $self->_get_data_series()->{'area'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }

  if ($style->{features}{legend} && (scalar @labels)) {
    $self->SUPER::_draw_legend($self->_get_image(), \@labels, $chart_box)
      or return;
  }
  return;
}

sub _draw_flat_legend {
  return 1;
}

sub _draw_lines {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();

  my $value_range = $max_value - $min_value;

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');

  my $graph_width = $self->_get_number('graph_width');
  my $graph_height = $self->_get_number('graph_height');

  my $line_series = $self->_get_data_series()->{'line'};
  my $series_counter = $self->_get_series_counter() || 0;

  my $has_columns = (defined $self->_get_data_series()->{'column'} || $self->_get_data_series->{'stacked_column'}) ? 1 : 0;

  my $col_width = int($graph_width / $column_count) -1;

  my $graph_box = $self->_get_graph_box();
  my $left = $graph_box->[0] + 1;
  my $bottom = $graph_box->[1];

  my $zero_position =  $bottom + $graph_height - (-1*$min_value / $value_range) * ($graph_height - 1);

  my $line_aa = $self->_get_number("lineaa");
  foreach my $series (@$line_series) {
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;

    my $interval;
    if ($has_columns) {
      $interval = $graph_width / ($data_size);
    }
    else {
      $interval = $graph_width / ($data_size - 1);
    }
    my $color = $self->_data_color($series_counter);

    # We need to add these last, otherwise the next line segment will overwrite half of the marker
    my @marker_positions;
    for (my $i = 0; $i < $data_size - 1; $i++) {
      my $x1 = $left + $i * $interval;
      my $x2 = $left + ($i + 1) * $interval;

      $x1 += $has_columns * $interval / 2;
      $x2 += $has_columns * $interval / 2;

      my $y1 = $bottom + ($value_range - $data[$i] + $min_value)/$value_range * $graph_height;
      my $y2 = $bottom + ($value_range - $data[$i + 1] + $min_value)/$value_range * $graph_height;

      push @marker_positions, [$x1, $y1];
      $img->line(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, aa => $line_aa, color => $color) || die $img->errstr;
    }

    my $x2 = $left + ($data_size - 1) * $interval;
    $x2 += $has_columns * $interval / 2;

    my $y2 = $bottom + ($value_range - $data[$data_size - 1] + $min_value)/$value_range * $graph_height;

    if ($self->_feature_enabled("linemarkers")) {
      push @marker_positions, [$x2, $y2];
      foreach my $position (@marker_positions) {
	$self->_draw_line_marker($position->[0], $position->[1], $series_counter);
      }
    }
    $series_counter++;
  }

  $self->_set_series_counter($series_counter);
  return 1;
}

sub _area_data_fill {
  my ($self, $index, $box) = @_;

  my %fill = $self->_data_fill($index, $box);

  my $opacity = $self->_get_number("area.opacity");
  $opacity == 1
    and return %fill;

  my $orig_fill = $fill{fill};
  unless ($orig_fill) {
    $orig_fill = Imager::Fill->new
      (
       solid => $fill{color},
       combine => "normal",
      );
  }
  return
    (
     fill => Imager::Fill->new
     (
      type => "opacity",
      other => $orig_fill,
      opacity => $opacity,
     ),
    );
}

sub _draw_area {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();

  my $value_range = $max_value - $min_value;

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');

  my $graph_width = $self->_get_number('graph_width');
  my $graph_height = $self->_get_number('graph_height');

  my $area_series = $self->_get_data_series()->{'area'};
  my $series_counter = $self->_get_series_counter() || 0;

  my $col_width = int($graph_width / $column_count) -1;

  my $graph_box = $self->_get_graph_box();
  my $left = $graph_box->[0] + 1;
  my $bottom = $graph_box->[1];
  my $right = $graph_box->[2];
  my $top = $graph_box->[3];

  my $zero_position =  $bottom + $graph_height - (-1*$min_value / $value_range) * ($graph_height - 1);

  my $line_aa = $self->_get_number("lineaa");
  foreach my $series (@$area_series) {
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;

    my $interval = $graph_width / ($data_size - 1);

    my $color = $self->_data_color($series_counter);

    # We need to add these last, otherwise the next line segment will overwrite half of the marker
    my @marker_positions;
    my @polygon_points;
    for (my $i = 0; $i < $data_size - 1; $i++) {
      my $x1 = $left + $i * $interval;

      my $y1 = $bottom + ($value_range - $data[$i] + $min_value)/$value_range * $graph_height;

      if ($i == 0) {
        push @polygon_points, [$x1, $top];
      }
      push @polygon_points, [$x1, $y1];

      push @marker_positions, [$x1, $y1];
    }

    my $x2 = $left + ($data_size - 1) * $interval;

    my $y2 = $bottom + ($value_range - $data[$data_size - 1] + $min_value)/$value_range * $graph_height;
    push @polygon_points, [$x2, $y2];
    push @polygon_points, [$x2, $top];
    push @polygon_points, $polygon_points[0];

    my @fill = $self->_area_data_fill($series_counter, [$left, $bottom, $right, $top]);
    $img->polygon(points => [@polygon_points], @fill);

    if ($self->_feature_enabled("areamarkers")) {
      push @marker_positions, [$x2, $y2];
      foreach my $position (@marker_positions) {
	$self->_draw_line_marker($position->[0], $position->[1], $series_counter);
      }
    }
    $series_counter++;
  }

  $self->_set_series_counter($series_counter);
  return 1;
}

sub _draw_columns {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();

  my $value_range = $max_value - $min_value;

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');

  my $graph_width = $self->_get_number('graph_width');
  my $graph_height = $self->_get_number('graph_height');


  my $graph_box = $self->_get_graph_box();
  my $left = $graph_box->[0] + 1;
  my $bottom = $graph_box->[1];
  my $zero_position =  int($bottom + $graph_height - (-1*$min_value / $value_range) * ($graph_height -1));

  my $bar_width = $graph_width / $column_count;

  my $outline_color;
  if ($style->{'features'}{'outline'}) {
    $outline_color = $self->_get_color('outline.line');
  }

  my $series_counter = $self->_get_series_counter() || 0;
  my $col_series = $self->_get_data_series()->{'column'};
  my $column_padding_percent = $self->_get_number('column_padding') || 0;
  my $column_padding = int($column_padding_percent * $bar_width / 100);

  # This tracks the series we're in relative to the starting series - this way colors stay accurate, but the columns don't start out too far to the right.
  my $column_series = 0;

  # If there are stacked columns, non-stacked columns need to start one to the right of where they would otherwise
  my $has_stacked_columns = (defined $self->_get_data_series()->{'stacked_column'} ? 1 : 0);

  for (my $series_pos = 0; $series_pos < scalar @$col_series; $series_pos++) {
    my $series = $col_series->[$series_pos];
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;
    for (my $i = 0; $i < $data_size; $i++) {
      my $part1 = $bar_width * (scalar @$col_series * $i);
      my $part2 = ($series_pos) * $bar_width;
      my $x1 = $left + $part1 + $part2;
      if ($has_stacked_columns) {
        $x1 += ($bar_width * ($i+1));
      }
      $x1 = int($x1);

      my $x2 = int($x1 + $bar_width - $column_padding)-1;
      # Special case for when bar_width is less than 1.
      if ($x2 < $x1) {
        $x2 = $x1;
      }

      my $y1 = int($bottom + ($value_range - $data[$i] + $min_value)/$value_range * $graph_height);

      my $color = $self->_data_color($series_counter);

      if ($data[$i] > 0) {
        my @fill = $self->_data_fill($series_counter, [$x1, $y1, $x2, $zero_position-1]);
        $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position-1, @fill);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position, color => $outline_color);
        }
      }
      else {
        my @fill = $self->_data_fill($series_counter, [$x1, $zero_position+1, $x2, $y1]);
        $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1, @fill);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1+1, color => $outline_color);
        }
      }
    }

    $series_counter++;
    $column_series++;
  }
  $self->_set_series_counter($series_counter);
  return 1;
}

sub _draw_stacked_columns {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();
  my $value_range = $max_value - $min_value;

  my $graph_box = $self->_get_graph_box();
  my $left = $graph_box->[0] + 1;
  my $bottom = $graph_box->[1];

  my $graph_width = $self->_get_number('graph_width');
  my $graph_height = $self->_get_number('graph_height');

  my $bar_width = $graph_width / $column_count;
  my $column_series = 0;
  if (my $column_series_data = $self->_get_data_series()->{'column'}) {
    $column_series = (scalar @$column_series_data);
  }
  $column_series++;

  my $column_padding_percent = $self->_get_number('column_padding') || 0;
  if ($column_padding_percent < 0) {
    return $self->_error("Column padding less than 0");
  }
  if ($column_padding_percent > 100) {
    return $self->_error("Column padding greater than 0");
  }
  my $column_padding = int($column_padding_percent * $bar_width / 100);

  my $outline_color;
  if ($style->{'features'}{'outline'}) {
    $outline_color = $self->_get_color('outline.line');
  }

  my $zero_position =  $bottom + $graph_height - (-1*$min_value / $value_range) * ($graph_height -1);
  my $col_series = $self->_get_data_series()->{'stacked_column'};
  my $series_counter = $self->_get_series_counter() || 0;

  foreach my $series (@$col_series) {
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;
    for (my $i = 0; $i < $data_size; $i++) {
      my $part1 = $bar_width * $i * $column_series;
      my $part2 = 0;
      my $x1 = int($left + $part1 + $part2);
      my $x2 = int($x1 + $bar_width - $column_padding) - 1;
      # Special case for when bar_width is less than 1.
      if ($x2 < $x1) {
        $x2 = $x1;
      }

      my $y1 = int($bottom + ($value_range - $data[$i] + $min_value)/$value_range * $graph_height);

      if ($data[$i] > 0) {
        my @fill = $self->_data_fill($series_counter, [$x1, $y1, $x2, $zero_position-1]);
        $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position-1, @fill);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position, color => $outline_color);
        }
      }
      else {
        my @fill = $self->_data_fill($series_counter, [$x1, $zero_position+1, $x2, $y1]);
        $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1, @fill);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1+1, color => $outline_color);
        }
      }
    }

    $series_counter++;
  }
  $self->_set_series_counter($series_counter);
  return 1;
}

sub _add_data_series {
  my $self = shift;
  my $series_type = shift;
  my $data_ref = shift;
  my $series_name = shift;

  my $graph_data = $self->{'graph_data'} || {};

  my $series = $graph_data->{$series_type} || [];

  push @$series, { data => $data_ref, series_name => $series_name };

  $graph_data->{$series_type} = $series;

  $self->{'graph_data'} = $graph_data;
  return;
}

=back

=head1 FEATURES

=over

=item show_horizontal_gridlines()

Feature: horizontal_gridlines
X<horizontal_gridlines>X<features, horizontal_gridlines>

Enables the C<horizontal_gridlines> feature, which shows horizontal
gridlines at the y-tics.

The style of the gridlines can be controlled with the
set_horizontal_gridline_style() method (or by setting the hgrid
style).

=cut

sub show_horizontal_gridlines {
    $_[0]->{'custom_style'}{features}{'horizontal_gridlines'} = 1;
}

=item set_horizontal_gridline_style(style => $style, color => $color)

Style: hgrid.
X<hgrid>X<style parameters, hgrid>

Set the style and color of horizonal gridlines.

See: L<Imager::Graph/"Line styles">

=cut

sub set_horizontal_gridline_style {
  my ($self, %opts) = @_;

  $self->{custom_style}{hgrid} ||= {};
  @{$self->{custom_style}{hgrid}}{keys %opts} = values %opts;

  return 1;
}

=item show_graph_outline($flag)

Feature: graph_outline
X<graph_outline>X<features, graph_outline>

If no flag is supplied, unconditionally enable the graph outline.

If $flag is supplied, enable/disable the graph_outline feature based
on that.

Enabled by default.

=cut

sub show_graph_outline {
  my ($self, $flag) = @_;

  @_ == 1 and $flag = 1;

  $self->{custom_style}{features}{graph_outline} = $flag;

  return 1;
}

=item set_graph_outline_style(color => ...)

=item set_graph_outline_style(style => ..., color => ...)

Style: graph.outline
X<graph.outline>X<style parameters, graph.outline>

Sets the style of the graph outline.

Default: the style C<fg>.

=cut

sub set_graph_outline_style {
  my ($self, %opts) = @_;

  $self->{custom_style}{graph}{outline} = \%opts;

  return 1;
}

=item set_graph_fill_style(I<fill parameters>)

Style: graph.fill
X<graph.fill>X<style parameters, graph.fill>

Set the fill used to fill the graph data area.

Default: the style C<bg>.

eg.

  $graph->set_graph_fill_style(solid => "FF000020", combine => "normal");

=cut

sub set_graph_fill_style {
  my ($self, %opts) = @_;

  $self->{custom_style}{graph}{fill} = \%opts;

  return 1;
}

=item show_area_markers()

=item show_area_markers($value)

Feature: areamarkers.

If $value is missing or true, draw markers along the top of area data
series.

eg.

  $chart->show_area_markers();

=cut

sub show_area_markers {
  my ($self, $value) = @_;

  @_ > 1 or $value = 1;

  $self->{custom_style}{features}{areamarkers} = $value;

  return 1;
}

=item show_line_markers()

=item show_line_markers($value)

Feature: linemarkers.

If $value is missing or true, draw markers on a line data series.

Note: line markers are drawn by default.

=cut

sub show_line_markers {
  my ($self, $value) = @_;

  @_ > 1 or $value = 1;

  $self->{custom_style}{features}{linemarkers} = $value;

  return 1;
}

=item use_automatic_axis()

Automatically scale the Y axis, based on L<Chart::Math::Axis>.  If
Chart::Math::Axis isn't installed, this sets an error and returns
undef.  Returns 1 if it is installed.

=cut

sub use_automatic_axis {
  eval { require Chart::Math::Axis; };
  if ($@) {
    return $_[0]->_error("use_automatic_axis - $@\nCalled from ".join(' ', caller)."\n");
  }
  $_[0]->{'custom_style'}->{'automatic_axis'} = 1;
  return 1;
}

=item set_y_tics($count)

Set the number of Y tics to use.  Their value and position will be
determined by the data range.

=cut

sub set_y_tics {
  $_[0]->{'y_tics'} = $_[1];
}

sub _get_y_tics {
  return $_[0]->{'y_tics'} || 0;
}

sub _remove_tics_from_chart_box {
  my ($self, $chart_box, $opts) = @_;

  # XXX - bad default
  my $tic_width = $self->_get_y_tic_width() || 10;
  my @y_tic_box = ($chart_box->[0], $chart_box->[1], $chart_box->[0] + $tic_width, $chart_box->[3]);

  # XXX - bad default
  my $tic_height = $self->_get_x_tic_height($opts) || 10;
  my @x_tic_box = ($chart_box->[0], $chart_box->[3] - $tic_height, $chart_box->[2], $chart_box->[3]);

  $self->_remove_box($chart_box, \@y_tic_box);
  $self->_remove_box($chart_box, \@x_tic_box);

  # If there's no title, the y-tics will be part off-screen.  Half of the x-tic height should be more than sufficient.
  my @y_tic_tops = ($chart_box->[0], $chart_box->[1], $chart_box->[2], $chart_box->[1] + int($tic_height / 2));
  $self->_remove_box($chart_box, \@y_tic_tops);

  # Make sure that the first and last label fit
  if (my $labels = $self->_get_labels($opts)) {
    if (my @box = $self->_text_bbox($labels->[0], 'legend')) {
      my @remove_box = ($chart_box->[0],
                        $chart_box->[1],
                        $chart_box->[0] + int($box[2] / 2) + 1,
                        $chart_box->[3]
                        );

      $self->_remove_box($chart_box, \@remove_box);
    }
    if (my @box = $self->_text_bbox($labels->[-1], 'legend')) {
      my @remove_box = ($chart_box->[2] - int($box[2] / 2) - 1,
                        $chart_box->[1],
                        $chart_box->[2],
                        $chart_box->[3]
                        );

      $self->_remove_box($chart_box, \@remove_box);
    }
  }
}

sub _get_y_tic_width {
  my $self = shift;
  my $min = $self->_get_min_value();
  my $max = $self->_get_max_value();
  my $tic_count = $self->_get_y_tics();

  my $interval = ($max - $min) / ($tic_count - 1);

  my %text_info = $self->_text_style('legend')
    or return;

  my $max_width = 0;
  for my $count (0 .. $tic_count - 1) {
    my $value = ($count*$interval)+$min;

    if ($interval < 1 || ($value != int($value))) {
      $value = sprintf("%.2f", $value);
    }
    my @box = $self->_text_bbox($value, 'legend');
    my $width = $box[2] - $box[0];

    # For the tic width
    $width += 10;
    if ($width > $max_width) {
      $max_width = $width;
    }
  }

  return $max_width;
}

sub _get_x_tic_height {
  my ($self, $opts) = @_;

  my $labels = $self->_get_labels($opts);

  if (!$labels) {
        return;
  }

  my $tic_count = (scalar @$labels) - 1;

  my %text_info = $self->_text_style('legend')
    or return;

  my $max_height = 0;
  for my $count (0 .. $tic_count) {
    my $label = $labels->[$count];

    my @box = $self->_text_bbox($label, 'legend');

    my $height = $box[3] - $box[1];

    # Padding + the tic
    $height += 10;
    if ($height > $max_height) {
      $max_height = $height;
    }
  }

  return $max_height;
}

sub _draw_y_tics {
  my $self = shift;
  my $min = $self->_get_min_value();
  my $max = $self->_get_max_value();
  my $tic_count = $self->_get_y_tics();

  my $img = $self->_get_image();
  my $graph_box = $self->_get_graph_box();
  my $image_box = $self->_get_image_box();

  my $interval = ($max - $min) / ($tic_count - 1);

  my %text_info = $self->_text_style('legend')
    or return;

  my $line_style = $self->_get_color('outline.line');
  my $show_gridlines = $self->{_style}{features}{'horizontal_gridlines'};
  my @grid_line = $self->_get_line("hgrid");
  my $tic_distance = ($graph_box->[3] - $graph_box->[1]) / ($tic_count - 1);
  for my $count (0 .. $tic_count - 1) {
    my $x1 = $graph_box->[0] - 5;
    my $x2 = $graph_box->[0] + 5;
    my $y1 = int($graph_box->[3] - ($count * $tic_distance));

    my $value = ($count*$interval)+$min;
    if ($interval < 1 || ($value != int($value))) {
        $value = sprintf("%.2f", $value);
    }

    my @box = $self->_text_bbox($value, 'legend')
      or return;

    $img->line(x1 => $x1, x2 => $x2, y1 => $y1, y2 => $y1, aa => 1, color => $line_style);

    my $width = $box[2];
    my $height = $box[3];

    $img->string(%text_info,
                 x    => ($x1 - $width - 3),
                 y    => ($y1 + ($height / 2)),
                 text => $value
                );

    if ($show_gridlines && $y1 != $graph_box->[1] && $y1 != $graph_box->[3]) {
      $self->_line(x1 => $graph_box->[0], y1 => $y1,
		   x2 => $graph_box->[2], y2 => $y1,
		   img => $img,
		   @grid_line);
    }
  }

}

sub _draw_x_tics {
  my ($self, $opts) = @_;

  my $img = $self->_get_image();
  my $graph_box = $self->_get_graph_box();
  my $image_box = $self->_get_image_box();

  my $labels = $self->_get_labels($opts);

  my $tic_count = (scalar @$labels) - 1;

  my $has_columns = (defined $self->_get_data_series()->{'column'} || defined $self->_get_data_series()->{'stacked_column'});

  # If we have columns, we want the x-ticks to show up in the middle of the column, not on the left edge
  my $denominator = $tic_count;
  if ($has_columns) {
    $denominator ++;
  }
  my $tic_distance = ($graph_box->[2] - $graph_box->[0]) / ($denominator);
  my %text_info = $self->_text_style('legend')
    or return;

  # If automatic axis is turned on, let's be selective about what labels we draw.
  my $max_size = 0;
  my $tic_skip = 0;
  if ($self->_get_number('automatic_axis')) {
    foreach my $label (@$labels) {
      my @box = $self->_text_bbox($label, 'legend');
      if ($box[2] > $max_size) {
        $max_size = $box[2];
      }
    }

    # Give the max_size some padding...
    $max_size *= 1.2;

    $tic_skip = int($max_size / $tic_distance) + 1;
  }

  my $line_style = $self->_get_color('outline.line');

  for my $count (0 .. $tic_count) {
    next if ($count % ($tic_skip + 1));
    my $label = $labels->[$count];
    my $x1 = $graph_box->[0] + ($tic_distance * $count);

    if ($has_columns) {
      $x1 += $tic_distance / 2;
    }

    $x1 = int($x1);

    my $y1 = $graph_box->[3] + 5;
    my $y2 = $graph_box->[3] - 5;

    $img->line(x1 => $x1, x2 => $x1, y1 => $y1, y2 => $y2, aa => 1, color => $line_style);

    my @box = $self->_text_bbox($label, 'legend')
      or return;

    my $width = $box[2];
    my $height = $box[3];

    $img->string(%text_info,
                 x    => ($x1 - ($width / 2)),
                 y    => ($y1 + ($height + 5)),
                 text => $label
                );

  }
}

sub _valid_input {
  my $self = shift;

  if (!defined $self->_get_data_series() || !keys %{$self->_get_data_series()}) {
    return $self->_error("No data supplied");
  }

  my $data = $self->_get_data_series();
  if (defined $data->{'line'} && !scalar @{$data->{'line'}->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }
  if (defined $data->{'column'} && !scalar @{$data->{'column'}->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }
  if (defined $data->{'stacked_column'} && !scalar @{$data->{'stacked_column'}->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }

  return 1;
}

sub _set_column_count   { $_[0]->{'column_count'} = $_[1]; }
sub _set_min_value      { $_[0]->{'min_value'} = $_[1]; }
sub _set_max_value      { $_[0]->{'max_value'} = $_[1]; }
sub _set_image_box      { $_[0]->{'image_box'} = $_[1]; }
sub _set_graph_box      { $_[0]->{'graph_box'} = $_[1]; }
sub _set_series_counter { $_[0]->{'series_counter'} = $_[1]; }
sub _get_column_count   { return $_[0]->{'column_count'} }
sub _get_min_value      { return $_[0]->{'min_value'} }
sub _get_max_value      { return $_[0]->{'max_value'} }
sub _get_image_box      { return $_[0]->{'image_box'} }
sub _get_graph_box      { return $_[0]->{'graph_box'} }
sub _reset_series_counter { $_[0]->{series_counter} = 0 }
sub _get_series_counter { return $_[0]->{'series_counter'} }

sub _style_defs {
  my ($self) = @_;

  my %work = %{$self->SUPER::_style_defs()};
  $work{area} =
    {
     opacity => 0.5,
    };
  push @{$work{features}}, qw/graph_outline graph_fill linemarkers/;
  $work{hgrid} =
    {
     color => "lookup(fg)",
     style => "solid",
    };

  return \%work;
}

sub _composite {
  my ($self) = @_;
  return ( $self->SUPER::_composite(), "graph", "hgrid" );
}

1;

=back

=head1 AUTHOR

Patrick Michaud, Tony Cook.

=cut
