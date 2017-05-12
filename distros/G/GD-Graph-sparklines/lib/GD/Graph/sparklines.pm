package GD::Graph::sparklines;

use strict;
use vars qw($VERSION);
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);
use base qw(GD::Graph::axestype);

$VERSION = '0.2';
my $svn_info = 
  '$LastChangedDate: 2004-09-28 12:05:35 +0100 (Tue, 28 Sep 2004) $';

# set some defaults and define our own options
my %Defaults = (
    y_min_clip => undef,
    y_max_clip => undef,
    y_band_min => undef,
    y_band_max => undef,
    traditional => 1,

    x_label => undef,
    y_label => undef,
    title   => undef,
    x_ticks => 0,
    y_ticks => 0,
    no_axes => 1,
);

sub initialise {
    my $self = shift;
    $self->SUPER::initialise();
    my $Defaults = join "\n", keys %Defaults;
    foreach my $key (keys %Defaults) {
        $self->set( $key => $Defaults{$key} );
    }
    
    if ($self->{traditional}) { # light grey lines
        my $colours = $self->get('dclrs');
        $self->set( dclrs=>['lgray', @$colours] );
    }

    1;
}

sub _has_default { 
    my $self = shift;
    my $attr = shift || return;
    exists $Defaults{$attr} || $self->SUPER::_has_default($attr);
}

sub draw_data_set {
    my $self = shift;
    my $data = shift;
    my $dsci = $self->set_clr($self->pick_data_clr($data));
    my $medci = $self->set_clr(_rgb($self->{fgclr}));
    my @values = $self->{_data}->y_values($data) or
        return $self->_set_error("Impossible illegal data set: $data",
           $self->{_data}->error);

    my %y = (
        max => $self->get('y_max_clip'),
        min => $self->get('y_min_clip'),
        low => $self->get('y_band_min'),
        hi  => $self->get('y_band_max')
    );

    # plot a "normal values" band
    if (defined($y{low}) and defined($y{hi})) {
        my ($tlx, $tly) = $self->val_to_pixel(0, $y{hi}, $data);
        my ($brx, $bry) = $self->val_to_pixel(scalar @values+1, $y{low}, $data);
        my $bg = $self->set_clr(_rgb('#DDDDDD'));
    
        $self->{graph}->filledRectangle($tlx, $tly, $brx, $bry, $bg);
    }
    
    my ($lx, $ly) = (undef, undef);
    for (my $i = 0; $i < @values; $i++) 
    {
        my $value = $values[$i];
        
        if (!defined($value)) {
            print "value[$i] isn't defined\n";
            undef $lx; undef $ly;
            next;
        }
      
        my ($px, $py) = $self->val_to_pixel($i+1, $value, $data);

        if (defined($px) and defined($py)) {
            if (defined($lx) and defined($ly)) {
                $self->{graph}->line($lx, $ly, $px, $py, $dsci);
            }
            ($lx, $ly) = ($px, $py);
        } else {
            die "error converting [$i, $value] to coordinates";
        }
    }

    if ($self->{traditional}) {
        my $red = $self->set_clr(_rgb('red'));

        # draw a single pixel if we're a shallow graph for space economy
        if ($self->{height} < 24) {
            $self->{graph}->setPixel($lx, $ly, $red);
        } else {
            $self->{graph}->filledRectangle($lx-1, $ly-1, $lx+1, $ly+1, $red);
        }
    }

    return $data;
}

# mostly cargo-culted from GD::Graph::boxplot
sub set_max_min 
{
  my $self = shift;

  my $min = 2<<29;
  my $max = -$min;
  
    for my $i ( 1 .. $self->{_data}->num_sets )    # 1 because x-labels are [0]
    {
      for my $j ( 0 .. $self->{_data}->num_points )
      {
          next unless defined($self->{_data}->[$i][$j]);

          $max = $self->{_data}->[$i][$j]
            if ($self->{_data}->[$i][$j] > $max);
          $min = $self->{_data}->[$i][$j]
            if ($self->{_data}->[$i][$j] < $min);        
        }
    }

  $self->{y_min}[1] = $min - 3;
  $self->{y_max}[1] = $max + 3;

  # Overwrite these with any user supplied ones
  $self->{y_min}[1] = $self->{y_min_value} if defined $self->{y_min_value};
  $self->{y_max}[1] = $self->{y_max_value} if defined $self->{y_max_value};
  
  $self->{y_min}[1] = $self->{y1_min_value} if defined $self->{y1_min_value};
  $self->{y_max}[1] = $self->{y1_max_value} if defined $self->{y1_max_value};

  # clipping overrides any max/min in the data
  $self->{y_min}[1] = $self->{y_min_clip} if defined $self->{y_min_clip};
  $self->{y_max}[1] = $self->{y_max_clip} if defined $self->{y_max_clip};

  return $self;
}

# override these methods to force the graph to fill the image
sub setup_bottom_boundary {
    my $self = shift;
    $self->{bottom} = $self->{height} - $self->{b_margin};
}

sub setup_top_boundary {
    my $self = shift;
    $self->{top} = $self->{t_margin};
}

sub create_y_labels {
    my $self = shift;
    $self->{y_label_len}[$_]    = 0 for 1, 2;
    $self->{y_label_height}[$_] = 0 for 1, 2;
}

sub create_x_labels {
    my $self = shift;
    $self->{x_label_height} = 0;
    $self->{x_label_width} = 0;
}
    

$VERSION;

__END__
=head1 NAME

GD::Graph::sparklines - plot "sparkline" graphs

=head1 SYNOPSIS

  use GD::Graph::sparklines;

  my $graph = GD::Graph::sparklines->new(100, 30);
  my $gd = $graph->plot( [[0,1,2,3], [16, 40, 35, 20]] );
  print $gd->png();

=head1 DESCRIPTION

GD::Graph::sparklines is a Perl module for creating sparklines using
the L<GD::Graph> infrastructure -- if you want a sparkline of your 
data, you can just replace

  use GD::Graph::lines;

with

  use GD::Graph::sparklines;

and it will "just work", assuming you've not used any esoteric options.

GD::Graph::sparklines was originally a simple wrapper around
L<GD::Graph::lines> but it turned out very difficult to get the
graph sizing correct without subclassing and overriding methods.

(It's also very difficult to get B<ploticus> to draw sparklines.)

=head1 OPTIONS

GD::Graph::sparklines adds a few options to the GD::Graph set.

=head2 y_min_clip, y_max_clip  (no defaults)

If set, clips the graph to those values (overriding any minimum or
maximum values in the data sets).

=head2 y_band_min, y_band_max  (no defaults)

If set, plots a background "range" band between the two values.

=head2 traditional (default: set)

If set, forces the first colour to be light grey and plots a small
red blob on the last value point.

If not, uses the standard GD::Graph colours (as set by B<dclrs>) and 
doesn't plot the blob.

=head1 BUGS

Undoubtedly lots.  In particular, the full power of GD::Graph isn't
implemented and will probably go terribly wrong if attempted.

The graphs are generally ugly -- I tend to render them at 4x and use
"| convert -scale 25%" to generate the final smoothed output.  (GD's
B<copyResampled> method doesn't seem to work very well otherwise 
there'd be a B<resample> option for generating anti-aliased graphs.)

Plotting more than one dataset on a sparkline will look ugly.

=head1 CREDITS

Edward Tufte for his chapter about sparklines in "Beautiful Evidence"
Martien Verbruggen for GD::Graph
George A. Fitch III for GD::Graph::boxplot which helped me a lot

=head1 AUTHOR

Copyright (c) 2004, Rob Partington E<lt>perl-ggs@frottage.orgE<gt>

=head1 SEE ALSO

L<http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0001Eb&topic_id=1>
L<http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0001OR&topic_id=1>
