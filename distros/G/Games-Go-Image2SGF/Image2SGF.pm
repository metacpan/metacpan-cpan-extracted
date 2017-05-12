#!/usr/bin/perl -w

package Games::Go::Image2SGF;
our $VERSION = '1.03';

=cut

=head1 NAME

Games::Go::Image2SGF -- interpret photographs of go positions.

=head1 SYNOPSIS

   my $board = Games::Go::Image2SGF->new(
       tl         => [50,   50],
       tr         => [1000, 50],
       bl         => [50,   1000],
       br         => [1000, 1000],
       image      => 'go_photograph.jpg'
   );

   $board->to_sgf;
   print $board->{sgf};

=head1 DESCRIPTION

B<Games::Go::Image2SGF> is a I<perl5> module to create a computer-readable 
I<SGF> format description of the position on a Go board, given a photograph 
of the position.

=head1 OPTIONS

Options are passed to B<Games::Go::ImageSGF> via its constructor.  It will 
attempt to use sane defaults for arguments you don't supply; you must supply
values for the required arguments. 

=over 4

=item tl, tr, bl, br

Required.  The coordinates of the four corners of the go board's grid.  You 
can obtain these by loading your photograph in an image editor that displays 
image coordinates and hovering the cursor over each of the grid corners. 

=item image 

Required.  The filename of the image to interpret.  This can be in any format 
supported by I<Imager>.

=item white, black, board

Optional.  A fairly-representative colour for the white stones, black stones, 
and go board itself, presented in decimal RGB triplets -- eg. C<[255,255,255]> 
for white.  You should only set these if the defaults are generating incorrect
SGF.  Default:  Black is C<[0,0,0]>, white is C<[255,255,255]>, board colour 
is C<[100,100,100]>.

=item sample_radius

Optional.  After inferring the grid from the corner points you give, the 
module will search in a radius of C<sample_radius> pixels to look at the
area's colour.  As with the C<white, black, board> arguments, the default 
is likely to do the right thing; you should only need to change this if
your image is very large or very small.  Default:  10 pixels.

=back

=head1 NOTES

You may want to use the methods defined in the module in another order, or
in conjunction with other methods of your own -- for example, to track
video of a live game instead of still images.  Note that methods with a 
leading C<_> are considered internal, and their semantics may change.

=head1 DEPENDENCIES

C<Imager>, C<perl5>.

=head1 SEE ALSO

Further examples at L<http://www.inference.phy.cam.ac.uk/cjb/image2sgf.html>,
the L<http://www.red-bean.com/sgf/> SGF standard, and the collaborative guide
to Go at L<http://senseis.xmp.net/>.

=head1 AUTHOR

Chris Ball E<lt>chris@cpan.orgE<gt>

=cut

use constant BOARDSIZE => 19;
use constant BOARD     => 0;
use constant WHITE     => 1;
use constant BLACK     => 2;
use constant X         => 0;
use constant Y         => 1;
use constant EPSILON   => 0.0001;

use strict;
use Imager;

sub new {
    
    # Set up some initial defaults.  These are overridden by the user
    # in their constructor.  White/black/board/sample_radius are optional.
    my $self = bless {
        white         => [255,255,255],
        black         => [0,0,0],
        board         => [100,100,100],
        sample_radius => 10,
    }, shift;
    
    # Handle arguments. 
    my %options = @_;
    while (my($key, $val) = each %options) { 
        $self->{$key} = $val;
    }

    # Some of our arguments are required, and we should have them at this point.
    foreach (qw/tl tr bl br image/) {
        unless (defined ($self->{$_})) {
            die "$_ is a required option; see the POD documentation.\n";
        }
    }

    # The mycolors array will be used by Imager to perform the quantization.
    $self->{mycolors} = [ Imager::Color->new(@{ $self->{white} }),
                          Imager::Color->new(@{ $self->{board} }),
                          Imager::Color->new(@{ $self->{black} }) ];

    return $self;
}

sub read_image {
    my $self = shift;
    
    my $img  = Imager->new();
    $img->open(file => $self->{image}) or die $img->errstr();
    $self->{img} = $img;
}

sub quantize {
    my $self = shift;

    # Quantize the image.  We tell Imager to choose the colour in mycolors
    # that each pixel in the image is nearest to, and set the pixel in the
    # created image to that colour.
    $self->{img} = $self->{img}->to_paletted(
        make_colors => "none",
        colors      => $self->{mycolors},
        max_colors  => 3
    ) or die $self->{img}->errstr();
}

sub find_intersections {
    my $self = shift;

    $self->invert_coords;

    # Find the equations for the lines connecting the four sides.
    # Lines are defined by their slope (m) and yintercept (b) with
    # the line equation:  y = mx + b.
    my $m_left = ($self->{tl}[Y] - $self->{bl}[Y]) /
                 ($self->{tl}[X] - $self->{bl}[X]);
    my $b_left = $self->{bl}[Y] - ($m_left * $self->{bl}[X]);

    my $m_right = ($self->{tr}[Y] - $self->{br}[Y]) / 
                  ($self->{tr}[X] - $self->{br}[X]);
    my $b_right = $self->{br}[Y] - ($m_right * $self->{br}[X]);

    my $m_top = ($self->{tr}[Y] - $self->{tl}[Y]) / 
                ($self->{tr}[X] - $self->{tl}[X]);
    my $b_top = $self->{tl}[Y] - ($m_top * $self->{tl}[X]);

    my $m_bottom = ($self->{br}[Y] - $self->{bl}[Y]) / 
                   ($self->{br}[X] - $self->{bl}[X]);
    my $b_bottom = $self->{bl}[Y] - ($m_bottom * $self->{bl}[X]);

    # Find the "vanishing points" for the grid the board forms. These are a 
    # "vertical vanishing point" (vvp) for the intersection of left and right 
    # lines, and a "horizontal vanishing point" (hvp) for top and bottom 
    # intersection.  There is the possibility that two lines are perfectly 
    # parallel -- we check this first and create a very small difference if 
    # we would otherwise generate a SIGFPE. 
    if ($m_top == $m_bottom) { 
        $m_top += EPSILON;
    }
    if ($m_left == $m_right) {
        $m_left += EPSILON;
    }

    my $x_vvp = ($b_right - $b_left) / ($m_left - $m_right);
    my $y_vvp = ($m_left * $x_vvp) + $b_left;
    my $x_hvp = ($b_top - $b_bottom) / ($m_bottom - $m_top);
    my $y_hvp = ($m_bottom * $x_hvp) + $b_bottom;

    # The "horizon" for any two point perspective grid will be the line 
    # connecting these two vanishing points. 
    my $m_horizon = ($y_vvp - $y_hvp) / ($x_vvp - $x_hvp);
    my $b_horizon = $y_vvp - ($m_horizon * $x_vvp);

    # Now find the equation of a line parallel to the horizon that goes through
    # the bottom right point, called "fg" (short for foreground). (It's 
    # arbitrary which point this parallel line goes through, really, as long as
    # it's different from the horizon line itself.)
    my $m_fg = $m_horizon;
    my $b_fg = $self->{br}[Y] - ($m_fg * $self->{br}[X]);

    # Find intersections of the left and right lines on this foreground (fg)
    my $left_fg_x = ($b_left - $b_fg) / ($m_fg - $m_left);
    my $right_fg_x = ($b_right - $b_fg) / ($m_fg - $m_right);
    
    # Find distance between these intersections along the x axis.
    my $left_right_fg_x_dist = abs($right_fg_x - $left_fg_x);

    # Divide this distance into BOARDSIZE-1 fragments to find the spacing of 
    # BOARDSIZE points along it.
    my $fg_lr_spacing = $left_right_fg_x_dist / (BOARDSIZE - 1);

    # Find intersections of the top and bottom lines on the foreground
    my $top_fg_x = ($b_top - $b_fg) / ($m_fg - $m_top);
    my $bottom_fg_x = ($b_bottom - $b_fg) / ($m_fg - $m_bottom);
    
    # Find distance between these intersections along the x axis.
    my $top_bottom_fg_x_dist = abs($top_fg_x - $bottom_fg_x);

    # Divide this distance into BOARDSIZE-1 fragments to find spacing.
    my $fg_tb_spacing = $top_bottom_fg_x_dist / (BOARDSIZE - 1);

    # Go through the foreground left-right x points, establish the vertical 
    # lines as detemined by the slope between them and the vvp. Start 
    # with left point and move towards the right.
    if ($left_fg_x < $right_fg_x) {
      for my $i (1 .. BOARDSIZE) {
        my $x_i = $left_fg_x + ($fg_lr_spacing * ($i - 1));
        my $y_i = $m_fg * $x_i + $b_fg;
        $self->{vert_m_hash}[$i] = ($y_vvp - $y_i) / ($x_vvp - $x_i);
        $self->{vert_b_hash}[$i] = $y_i - ($self->{vert_m_hash}[$i] * $x_i);
      }
    } else {
      for my $i (1 .. BOARDSIZE) {
        my $x_i = $left_fg_x - ($fg_lr_spacing * ($i - 1));
        my $y_i = $m_fg * $x_i + $b_fg;
        $self->{vert_m_hash}[$i] = ($y_vvp - $y_i) / ($x_vvp - $x_i);
        $self->{vert_b_hash}[$i] = $y_i - ($self->{vert_m_hash}[$i] * $x_i);
      }
    }

    # Similarly, go through the foreground top-bottom x points, establish the 
    # horizontal lines as determined by the slope between them and the hvp. 
    # Want to number things from top to bottom, so will start things from 
    # top foreground x and move towards bottom.
    if ($top_fg_x < $bottom_fg_x) {
      for my $i (1 .. BOARDSIZE) {
        my $x_i = $top_fg_x + ($fg_tb_spacing * ($i - 1));
        my $y_i = $m_fg * $x_i + $b_fg;
        $self->{horiz_m_hash}[$i] = ($y_hvp - $y_i) / ($x_hvp - $x_i);
        $self->{horiz_b_hash}[$i] = $y_i - ($self->{horiz_m_hash}[$i] * $x_i);
      }
    } else {
      for my $i (1 .. BOARDSIZE) {
        my $x_i = $top_fg_x - ($fg_tb_spacing * ($i - 1));
        my $y_i = $m_fg * $x_i + $b_fg;
        $self->{horiz_m_hash}[$i] = ($y_hvp - $y_i) / ($x_hvp - $x_i);
        $self->{horiz_b_hash}[$i] = $y_i - ($self->{horiz_m_hash}[$i] * $x_i);
      }
    }

    for my $i (1 .. BOARDSIZE) {
      for my $j (1 .. BOARDSIZE) {
        my $x_vertex = ($self->{horiz_b_hash}[$i] - $self->{vert_b_hash}[$j]) / 
                       ($self->{vert_m_hash}[$j] - $self->{horiz_m_hash}[$i]);
        my $y_vertex = ($self->{horiz_m_hash}[$i] * $x_vertex) + 
                       $self->{horiz_b_hash}[$i];
        # Coordinate system:
        # intersection [3,5] is third from top, fifth from left
        $self->{intersection}[$i][$j] = [ $x_vertex, -1 * $y_vertex ];
      }
    }
}


sub sample {
    my ($self, $i, $j, $radius) = @_;
    my $stone      = "undecided";
    my $blackcount = 0;
    my $whitecount = 0;
    my $boardcount = 0;
    my $x_vertex   = $self->{intersection}[$i][$j][X];
    my $y_vertex   = $self->{intersection}[$i][$j][Y];
    my $black      = $self->{mycolors}->[0];
    my $board      = $self->{mycolors}->[1];
    my $white      = $self->{mycolors}->[2]; 
    
    for (my $k = ($x_vertex - $radius); $k <= ($x_vertex + $radius); $k++) {
        for (my $l = ($y_vertex - $radius); $l <= ($y_vertex + $radius); $l++) {
             if (($x_vertex - $k)**2 + ($y_vertex - $l)**2 <= ($radius**2)) {
                # If this is true, then the point ($k, $l) is in our circle.
                # Now we sample at it.
                my $gp = $self->{img}->getpixel('x' => $k, 'y' => $l);
                next if $gp == undef;
                if (_color_cmp($gp, $black) == 1) { $blackcount++; }
                if (_color_cmp($gp, $board) == 1) { $boardcount++; }
                if (_color_cmp($gp, $white) == 1) { $whitecount++; }
            }
        }
    }

    # Finished sampling.  Use a simple majority to work out which colour
    # wins.  TODO -- there are better ways of doing this.  For example,
    # if we determine one stone to be white or black, we could afterwards 
    # set its radius _in our quantized image_ back to the board colour;
    # this "explaining away" would alleviate cases where the grid is 
    # slightly off and we're catching pixels of an already-recorded 
    # stone on the edges.
    if (($whitecount > $blackcount) and ($whitecount > $boardcount)) {
        $stone = WHITE;
    } elsif ($blackcount > $boardcount) {
        $stone = BLACK;
    } else {
        $stone = BOARD;
    }

    my @letters = qw/z a b c d e f g h i j k l m n o p q r s/;
    if ($stone == WHITE or $stone == BLACK) {
        $self->update_sgf($stone, $letters[$i], $letters[$j], $stone);
    }

    return $stone;
}

sub invert_coords {
    my $self = shift;
    
    # Because the origin (0,0) in the inputed coordinates is in the
    # upper left instead of the intuitive-for-geometry bottom left,
    # we want to call this the "fourth quadrant". That means all the
    # y values are treated as negative numbers, so we convert:
    for (qw(tl tr bl br)) { $self->{$_}[Y] = -$self->{$_}[Y]; }
}

sub start_sgf {
    my $self = shift;
    my $time = scalar localtime;
    $self->{sgf} .= <<ENDSTARTSGF;
(;GM[1]FF[4]SZ[19]
GN[Image2SGF conversion of $time.]

AP[Image2SGF by Chris Ball.]
PL[B]
ENDSTARTSGF
}

sub update_sgf {
   my $self = shift;
   my ($stone, $x, $y) = @_;
   if ($stone == BLACK) {
       push @{$self->{blackstones}}, "$y$x";
   }
   elsif ($stone == WHITE) {
       push @{$self->{whitestones}}, "$y$x";
   }
}

sub finish_sgf {
    my $self = shift;
    
    $self->{sgf} .= "\nAB"; 
    $self->{sgf} .= "[$_]" foreach (@{$self->{blackstones}}); 
    
    $self->{sgf} .= "\nAW";
    $self->{sgf} .= "[$_]" foreach (@{$self->{whitestones}}); 
    
    $self->{sgf} .= ")\n\n";
}

sub _color_cmp {
    my ($l, $r) = @_;
    my @l = $l->rgba;
    my @r = $r->rgba;
    return ($l[0] == $r[0] and $l[1] == $r[1] and $l[2] == $r[2]);
}

sub _to_coords {
    # Example:  "cd" => "C16".
    my ($x, $y) = @_;
    return chr(64 + $y + ($y > 9 && 1)) . (20 - $x);
}

sub _from_coords {
    # Example:  "C16" => "cd".
    my $move = shift;
    /(.)(\d+)/;
    return ($2, ord($1) - 65);
}

sub to_sgf {
    my $self = shift;

    # The only user-visible method right now.  Runs the conversion functions.
    # (Which are separate methods so that we can keep track of a live game 
    # efficiently -- if the camera is stationary above the board, we only 
    # have to find the grid location once, and can just repeatedly call 
    # read_image/quantize/sample, reusing the coordinates.)
    $self->find_intersections;
    $self->start_sgf;
    $self->read_image;
    $self->quantize;

    for my $i (1 .. BOARDSIZE) {
        for my $j (1 .. BOARDSIZE) {
            my $stone = $self->sample($i, $j, $self->{sample_radius});
        }
    }
    
    $self->finish_sgf;
}

1;

