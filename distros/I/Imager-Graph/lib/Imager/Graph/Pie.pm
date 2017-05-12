package Imager::Graph::Pie;

=head1 NAME

  Imager::Graph::Pie - a tool for drawing pie charts on Imager images

=head1 SYNOPSIS

  use Imager::Graph::Pie;

  my $chart = Imager::Graph::Pie->new;
  # see Imager::Graph for options
  my $img = $chart->draw(
                         data => [ $first_amount, $second_amount ],
                         size => 350);

=head1 DESCRIPTION

Imager::Graph::Pie is intender to make it simple to use L<Imager> to
create good looking pie graphs.

Most of the basic layout and color selection is handed off to
L<Imager::Graph>.

=over

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph;
@ISA = qw(Imager::Graph);
use Imager::Graph::Util;
use POSIX qw(floor);

use constant PI => 3.1415926535;

=item $graph->draw(...)

Draws a pie graph onto a new image and returns the image.

You must at least supply a C<data> parameter and should probably supply a C<labels> parameter.  If you supply a C<labels> parameter, you must supply a C<font> parameter.

The C<data> parameter should be a reference to an array containing the
data the pie graph should present.

The C<labels> parameter is a reference to an array of labels,
corresponding to the values in C<data>.

=back

=head1 FEATURES

As described in L<Imager::Graph> you can enable extra features for
your graph.  The features you can use with pie graphs are:

=over

=item show_callouts_onAll_segments()

Feature: allcallouts.
X<allcallouts>X<features, allcallouts>

all labels are presented as callouts

=cut

sub show_callouts_onAll_segments {
    $_[0]->{'custom_style'}->{'features'}->{'allcallouts'} = 1;
}

=item show_only_label_percentages()

Feature: labelspconly
X<labelspconly>X<features, labelspconly>

only show the percentage, not the labels.

=cut

sub show_only_label_percentages {
    $_[0]->{'custom_style'}->{'features'}->{'labelspconly'} = 1;
}

=item show_label_percentages()

Feature: labelspc
X<labelspc>X<features, labelspc>

adds the percentage of the pie to each label.

=cut

sub show_label_percentages {
    $_[0]->{'custom_style'}->{'features'}->{'labelspc'} = 1;
}

=back

Inherited features:

=over

=item legend

adds a legend to your graph.  Requires the labels parameter

=item labels

labels each segment of the graph.  If the label doesn't fit inside the
segment it is presented as a callout.

=item outline

the pie segments are outlined.

=item dropshadow

the pie is given a drop shadow.

=back

=head1 PIE CHART STYLES

The following style values are specific to pie charts:

Controlling callouts, the C<callout> option:

=over

=item *

color - the color of the callout line and the callout text.

=item *

font, size - font and size of the callout text

=item *

outside - the distance the radial callout line goes outside the pie

=item *

leadlen - the length of the horizontal callout line from the end of
the radial line.

=item *

gap - the distance between the end of the horizontal callout line and
the label.

=item *

inside - the length of the radial callout line within the pie.

=back

The outline, line option controls the color of the pie segment
outlines, if enabled with the C<outline> feature.

Under C<pie>:

=over

=item *

maxsegment - any segment below this fraction of the total of the
segments will be put into the "others" segment.  Default: 0.01

=back

The top level C<otherlabel> setting controls the label for the
"others" segment, default "(others)".

=head1 EXAMPLES

Assuming:

  # from the Netcraft September 2001 web survey
  # http://www.netcraft.com/survey/
  my @data   = qw(17874757  8146372   1321544  811406 );
  my @labels = qw(Apache    Microsoft i_planet  Zeus   );

  my $pie = Imager::Graph::Pie->new;

First a simple graph, normal size, no labels:

  my $img = $pie->draw(data=>\@data)
    or die $pie->error;

label the segments:

  # error handling omitted for brevity from now on
  $img = $pie->draw(data=>\@data, labels=>\@labels, features=>'labels');

just percentages in the segments:

  $img = $pie->draw(data=>\@data, features=>'labelspconly');

add a legend as well:

  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    features=>[ 'labelspconly', 'legend' ]);

and a title, but move the legend down, and add a dropshadow:

  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    title=>'Netcraft Web Survey',
                    legend=>{ valign=>'bottom' },
                    features=>[ qw/labelspconly legend dropshadow/ ]);

something a bit prettier:

  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    style=>'fount_lin', features=>'legend');

suitable for monochrome output:

  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    style=>'mono', features=>'legend');

=cut

# this function is too long
sub draw {
  my ($self, %opts) = @_;

  my $data_series = $self->_get_data_series(\%opts);

  $self->_valid_input($data_series)
    or return;

  my @data = @{$data_series->[0]->{'data'}};

  my @labels = @{$self->_get_labels(\%opts) || []};

  $self->_style_setup(\%opts);

  my $style = $self->{_style};

  my $img = $self->_make_img()
    or return;

  my @chart_box = ( 0, 0, $img->getwidth-1, $img->getheight-1 );
  if ($style->{title}{text}) {
    $self->_draw_title($img, \@chart_box)
      or return;
  }

  my $total = 0;
  for my $item (@data) {
    $total += $item;
  }

  # consolidate any segments that are too small to display
  $self->_consolidate_segments(\@data, \@labels, $total);

  if ($style->{features}{legend} && (scalar @labels)) {
    $self->_draw_legend($img, \@labels, \@chart_box)
      or return;
  }

  # the following code is fairly ugly
  # it attempts to work out a good layout for the components of the chart
  my @info;
  my $index = 0;
  my $pos = 0;
  my @ebox = (0, 0, 0, 0);
  defined(my $callout_outside = $self->_get_number('callout.outside'))
    or return;
  defined(my $callout_leadlen = $self->_get_number('callout.leadlen'))
    or return;
  defined(my $callout_gap = $self->_get_number('callout.gap'))
    or return;
  defined(my $label_vpad = $self->_get_number('label.vpad'))
    or return;
  defined(my $label_hpad = $self->_get_number('label.hpad'))
    or return;
  my $guessradius = 
    int($self->_small_extent(\@chart_box) * $style->{pie}{guessfactor} * 0.5);
  for my $data (@data) {
    my $item = { data=>$data, index=>$index };
    my $size = 2 * PI * $data / $total;
    $item->{begin} = $pos;
    $pos += $size;
    $item->{end} = $pos;
    if (scalar @labels) {
      $item->{text} = $labels[$index];
    }
    if ($style->{features}{labelspconly}) {
      $item->{text} = 
        $style->{label}{pconlyformat}->($data/$total * 100);
    }
    if ($item->{text}) {
      if ($style->{features}{labelspc}) {
        $item->{text} = 
          $style->{label}{pcformat}->($item->{text}, $data/$total * 100);
        $item->{label} = 1;
      }
      elsif ($style->{features}{labelspconly}) {
        $item->{text} = 
          $style->{label}{pconlyformat}->($data/$total * 100);
        $item->{label} = 1;
      }
      elsif ($style->{features}{labels}) {
        $item->{label} = 1;
      }
      $item->{callout} = 1 if $style->{features}{allcallouts};
      if (!$item->{callout}) {
        my @lbox = $self->_text_bbox($item->{text}, 'label')
          or return;
        $item->{lbox} = \@lbox;
        if ($item->{label}) {
          unless ($self->_fit_text(0, 0, 'label', $item->{text}, $guessradius,
                                   $item->{begin}, $item->{end})) {
            $item->{callout} = 1;
          }
        }
      }
      if ($item->{callout}) {
        $item->{label} = 0;
        my @cbox = $self->_text_bbox($item->{text}, 'callout')
          or return;
        $item->{cbox} = \@cbox;
        $item->{cangle} = ($item->{begin} + $item->{end}) / 2;
        my $dist = cos($item->{cangle}) * ($guessradius+
                                           $callout_outside);
        my $co_size = $callout_leadlen + $callout_gap + $item->{cbox}[2];
        if ($dist < 0) {
          $dist -= $co_size - $guessradius;
          $dist < $ebox[0] and $ebox[0] = $dist;
        }
        else {
          $dist += $co_size - $guessradius;
          $dist > $ebox[2] and $ebox[2] = $dist;
        }
      }
    }
    push(@info, $item);
    ++$index;
  }

  my $radius = 
    int($self->_small_extent(\@chart_box) * $style->{pie}{size} * 0.5);
  my $max_width = $chart_box[2] - $chart_box[0] + $ebox[0] - $ebox[2];
  if ($radius > $max_width / 2) {
    $radius = int($max_width / 2);
  }
  $chart_box[0] -= $ebox[0];
  $chart_box[2] -= $ebox[2];
  my $cx = int(($chart_box[0] + $chart_box[2]) / 2);
  my $cy = int(($chart_box[1] + $chart_box[3]) / 2);
  if ($style->{features}{dropshadow}) {
    my @shadow_fill = $self->_get_fill('dropshadow.fill')
      or return;
    my $offx = $self->_get_number('dropshadow.offx')
      or return;
    my $offy = $self->_get_number('dropshadow.offy');
    for my $item (@info) {
      $img->arc(x=>$cx+$offx, 'y'=>$cy+$offy, r=>$radius+1, aa => 1,
                d1=>180/PI * $item->{begin}, d2=>180/PI * $item->{end},
                @shadow_fill);
    }
    $self->_filter_region($img, 
                          $cx+$offx-$radius-10, $cy+$offy-$radius-10, 
                          $cx+$offx+$radius+10, $cy+$offy+$radius+10,
                          'dropshadow.filter')
      if $style->{dropshadow}{filter};
  }

  my @fill_box = ( $cx-$radius, $cy-$radius, $cx+$radius, $cy+$radius );
  my $fill_aa = $self->_get_number('fill.aa');
  for my $item (@info) {
    $item->{begin} < $item->{end}
      or next;
    my @fill = $self->_data_fill($item->{index}, \@fill_box)
      or return;
    $img->arc(x=>$cx, 'y'=>$cy, r=>$radius, aa => $fill_aa,
              d1=>180/PI * $item->{begin}, d2=>180/PI * $item->{end},
              @fill);
  }
  if ($style->{features}{outline}) {
    my %outstyle = $self->_line_style('outline');
    my $out_radius = 0.5 + $radius;
    for my $item (@info) {
      my $px = int($cx + $out_radius * cos($item->{begin}));
      my $py = int($cy + $out_radius * sin($item->{begin}));
      $item->{begin} < $item->{end}
        or next;
      $img->line(x1=>$cx, y1=>$cy, x2=>$px, y2=>$py, %outstyle);
      for (my $i = $item->{begin}; $i < $item->{end}; $i += PI/180) {
        my $stroke_end = $i + PI/180;
        $stroke_end = $item->{end} if $stroke_end > $item->{end};
        my $nx = int($cx + $out_radius * cos($stroke_end));
        my $ny = int($cy + $out_radius * sin($stroke_end));
        $img->line(x1=>$px, y1=>$py, x2=>$nx, y2=>$ny, %outstyle);
        ($px, $py) = ($nx, $ny);
      }
    }
  }

  my $callout_inside = $radius - $self->_get_number('callout.inside');
  $callout_outside += $radius;
  my %callout_text;
  my %label_text;
  my %callout_line;
  my $leader_aa = $self->_get_number('callout.leadaa');
  for my $label (@info) {
    if ($label->{label} && !$label->{callout}) {
      # at this point we know we need the label font, to calculate
      # whether the label will fit if anything else
      unless (%label_text) {
        %label_text = $self->_text_style('label')
          or return;
      }
      my @loc = $self->_fit_text($cx, $cy, 'label', $label->{text}, $radius,
                                 $label->{begin}, $label->{end});
      if (@loc) {
        my $tcx = ($loc[0]+$loc[2])/2;
        my $tcy = ($loc[1]+$loc[3])/2;
        #$img->box(xmin=>$loc[0], ymin=>$loc[1], xmax=>$loc[2], ymax=>$loc[3],
        #          color=>Imager::Color->new(0,0,0));
        $img->string(%label_text, x=>$tcx-$label->{lbox}[2]/2,
                     'y'=>$tcy+$label->{lbox}[3]/2+$label->{lbox}[1],
                     text=>$label->{text});
      }
      else {
        $label->{callout} = 1;
        my @cbox = $self->_text_bbox($label->{text}, 'callout')
          or return;
        $label->{cbox} = \@cbox; 
        $label->{cangle} = ($label->{begin} + $label->{end}) / 2;
      }
    }
    if ($label->{callout}) {
      unless (%callout_text) {
        %callout_text = $self->_text_style('callout')
          or return;
	%callout_line = $self->_line_style('callout');
      }
      my $ix = floor(0.5 + $cx + $callout_inside * cos($label->{cangle}));
      my $iy = floor(0.5 + $cy + $callout_inside * sin($label->{cangle}));
      my $ox = floor(0.5 + $cx + $callout_outside * cos($label->{cangle}));
      my $oy = floor(0.5 + $cy + $callout_outside * sin($label->{cangle}));
      my $lx = ($ox < $cx) ? $ox - $callout_leadlen : $ox + $callout_leadlen;
      $img->polyline(points => [ [ $ix, $iy ],
				 [ $ox, $oy ],
				 [ $lx, $oy ] ],
		     %callout_line);
      #my $tx = $lx + $callout_gap;
      my $ty = $oy + $label->{cbox}[3]/2+$label->{cbox}[1];
      if ($lx < $cx) {
        $img->string(%callout_text, x=>$lx-$callout_gap-$label->{cbox}[2], 
                     'y'=>$ty, text=>$label->{text});
      }
      else {
        $img->string(%callout_text, x=>$lx+$callout_gap, 'y'=>$ty, 
                     text=>$label->{text});
      }
    }
  }

  $img;
}

sub _valid_input {
  my ($self, $data_series) = @_;

  if (!defined $data_series || !scalar @$data_series) {
    return $self->_error("No data supplied");
  }

  @$data_series == 1
    or return $self->_error("Pie charts only allow one data series");

  my $data = $data_series->[0]{data};

  if (!scalar @$data) {
    return $self->_error("No values in data series");
  }

  my $total = 0;
  {
    my $index = 0;
    for my $item (@$data) {
      $item < 0
        and return $self->_error("Data index $index is less than zero");

      $total += $item;

      ++$index;
    }
  }
  $total == 0
    and return $self->_error("Sum of all data values is zero");

  return 1;
}

=head1 INTERNAL FUNCTIONS

These are used in the implementation of Imager::Graph, and are
documented for debuggers and developers.

=over

=item _consolidate_segments($data, $labels, $total)

Consolidate segments that are too small into an 'others' segment.

=cut

sub _consolidate_segments {
  my ($self, $data, $labels, $total) = @_;

  my @others;
  my $index = 0;
  for my $item (@$data) {
    if ($item / $total < $self->{_style}{pie}{maxsegment}) {
      push(@others, $index);
    }
    ++$index;
  }
  if (@others) {
    my $others = 0;
    for my $index (reverse @others) {
      $others += $data->[$index];
      splice(@$labels, $index, 1);
      splice(@$data, $index, 1);
    }
    push(@$labels, $self->{_style}{otherlabel}) if @$labels;
    push(@$data, $others);
  }
}

# used for debugging
sub _test_line {
  my ($x, $y, @l) = @_;

  my $res = $l[0]*$x + $l[1] * $y + $l[2];
  print "test ", (abs($res) < 0.000001) ? "success\n" : "failure $res\n";
}

=item _fit_text($cx, $cy, $name, $text, $radius, $begin, $end)

Attempts to fit text into a pie segment with its center at ($cx, $cy)
with the given radius, covering the angles $begin through $end.

Returns a list defining the bounding box of the text if it does fit.

=cut

sub _fit_text {
  my ($self, $cx, $cy, $name, $text, $radius, $begin, $end) = @_;

  #print "fit: $cx, $cy '$text' $radius $begin $end\n";
  my @tbox = $self->_text_bbox($text, $name)
    or return;
  my $tcx = floor(0.5+$cx + cos(($begin+$end)/2) * $radius *3/5);
  my $tcy = floor(0.5+$cy + sin(($begin+$end)/2) * $radius *3/5);
  my $topy = $tcy - $tbox[3]/2;
  my $boty = $topy + $tbox[3];
  my @lines;
  for my $y ($topy, $boty) {
    my %entry = ( 'y'=>$y );
    $entry{line} = [ line_from_points($tcx, $y, $tcx+1, $y) ];
    $entry{left} = -$radius;
    $entry{right} = $radius;
    for my $angle ($begin, $end) {
      my $ex = $cx + cos($angle)*$radius;
      my $ey = $cy + sin($angle)*$radius;
      my @line = line_from_points($cx, $cy, $ex, $ey);
      #_test_line($cx, $cy, @line);
      #_test_line($ex, $ey, @line);
      my $goodsign = $line[0] * $tcx + $line[1] * $tcy + $line[2];
      for my $pos (@entry{qw/left right/}) {
        my $sign = $line[0] * ($pos+$tcx) + $line[1] * $y + $line[2];
        if ($goodsign * $sign < 0) {
          if (my @p = intersect_lines(@line, @{$entry{line}})) {
            # die "$goodsign $sign ($pos, $tcx) no intersect (@line) (@{$entry{line}})"  ; # this would be wierd
            #_test_line(@p, @line);
            #_test_line(@p, @{$entry{line}});
            $pos = $p[0]-$tcx;
          }
          else {
            return;
          }
            
        }

        # circle
        my $dist2 = ($pos+$tcx-$cx) * ($pos+$tcx-$cx) 
          + ($y - $cy) * ($y - $cy);
        if ($dist2 > $radius * $radius) {
          my @points = 
            intersect_line_and_circle(@{$entry{line}}, $cx, $cy, $radius);
          while (@points) {
            my @p = splice(@points, 0, 2);
            if ($p[0] < $cx && $tcx+$pos < $p[0]) {
              $pos = $p[0]-$tcx;
            }
            elsif ($p[0] > $cx && $tcx+$pos > $p[0]) {
              $pos = $p[0]-$tcx;
            }
          }
        }
      }
    }
    push(@lines, \%entry);
  }
  my $left = $lines[0]{left} > $lines[1]{left} ? $lines[0]{left} : $lines[1]{left};
  my $right = $lines[0]{right} < $lines[1]{right} ? $lines[0]{right} : $lines[1]{right};
  return if $right - $left < $tbox[2];

  return ($tcx+$left, $topy, $tcx+$right, $boty);
}

sub _composite {
  ( 'pie', $_[0]->SUPER::_composite() );
}

sub _style_defs {
  my ($self) = @_;

  my %work = %{$self->SUPER::_style_defs()};
  $work{otherlabel} = "(others)";
  $work{pie} = 
    {
     guessfactor=>0.6,
     size=>0.8,
     maxsegment=> 0.01,
    };

  \%work;
}

1;
__END__

=back

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

Imager::Graph(3), Imager(3), perl(1)

=cut
