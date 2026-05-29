#!/usr/bin/env perl

# Vector drawing parser
# Virtual resolution is ALWAYS 3840 x 2160
# it will be converted to the actual resolution when drawn
# The commands are a subset of the actual GFB capabilites

# This may actually develop into a ridumentary language in
#  the future.

use strict;

use Time::HiRes 'sleep';
use Graphics::Framebuffer;
use Getopt::Long;

use constant {
    PI => 4 * atan2(1,1),
};
# use Data::Dumper::Simple;

BEGIN {
    our $VERSION = '0.05';
}

my $delay = 1;

GetOptions(
    'delay|wait=f' => \$delay,
);

my $F = Graphics::Framebuffer->new('SPLASH' => 0); # Open without fanfare

$F->cls('OFF');
$F->graphics_mode();

my ($width, $height, $bpp) = $F->screen_dimensions();
my ($xf, $yf) = ($width / 3840, $height / 2160);

open(my $FILE, '<', shift(@ARGV));
chomp(my @text = <$FILE>);
close($FILE);

my $cmd = {
    'PLAY' => sub {
        my $animation = $F->load_image(
            {
                'file'   => shift(@_),
                'center' => CENTER_XY,
            }
        );

		my $s = time + $delay;
		while(time < $s) {
			$F->play_animation($animation, 1);
		}
    },
    'PLAY_MAX' => sub {
        my $animation = $F->load_image(
            {
                'file'       => shift(@_),
                'center'     => CENTER_XY,
                'scale_type' => 'max',
				'width'      => 3840 * $xf,
				'height'     => 2160 * $yf,
            }
        );

		my $s = time + $delay;
		while(time < $s) {
			$F->play_animation($animation, 1);
		}
    },
    'GRAPHICS_MODE' => sub {
        $F->graphics_mode();
    },
    'POLYGON' => sub {
        my @coords = @_;
        $F->polygon(
            {
                'coordinates' => \@coords,
                'filled'      => 1,
            }
        );
    },
    'TEXT_MODE' => sub {
        $F->text_mode();
    },
    'WAIT' => sub {
        my $wait = shift || 1;
        sleep $wait;
    },
    'SPLASH' => sub {
        $F->splash();
    },
    'NORMAL_MODE' => sub {
        $F->normal_mode();
    },
    'XOR_MODE' => sub {
        $F->xor_mode();
    },
    'OR_MODE' => sub {
        $F->or_mode();
    },
    'AND_MODE' => sub {
        $F->and_mode();
    },
    'ALPHA_MODE' => sub {
        $F->alpha_mode();
    },
    'MASK_MODE' => sub {
        $F->mask_mode();
    },
    'UNMASK_MODE' => sub {
        $F->unmask_mode();
    },
    'ADD_MODE' => sub {
        $F->add_mode();
    },
    'SUBTRACT_MODE' => sub {
        $F->subtract_mode();
    },
    'MULTIPLY_MODE' => sub {
        $F->multiply_mode();
    },
    'DIVIDE_MODE' => sub {
        $F->divide_mode();
    },
    'CLS' => sub {
        $F->cls(@_);
    },
    'ATTRIBUTE_RESET' => sub {
        $F->attribute_reset();
    },
    'PLOT' => sub {
        $F->plot(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
            }
        );
    },
    'STAR' => sub {
        my ($X,$Y,$R) = @_;
        my $alpha = (2 * PI) / 10;
        my $radius = $R * $xf;
        my @coords; # = ($X, $Y);

        for (my $i = $radius; $i != 0; $i--) {
            my $r = $radius * ($i % 2 + 1) / 2;
            my $omega = $alpha * $i;
            push(@coords,($r * sin($omega)) + $X, ($r * cos($omega)) + $Y);
        }
        $F->polygon({'coordinates' => \@coords, 'filled' => 0, 'antialiased' => 1});
        $F->fill({'x' => $X, 'y' => $Y});
    },
    'DOT' => sub {
        $F->circle(
            {
                'x'      => shift(@_) * $xf,
                'y'      => shift(@_) * $yf,
                'radius' => abs(shift(@_)),
                'filled' => 1,
            }
        );
    },
    'LINE' => sub {
        $F->line(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'xx'         => shift(@_) * $xf,
                'yy'         => shift(@_) * $yf,
            }
        );
    },
    'ANGLE_LINE' => sub {
        $F->angle_line(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'radius'     => shift(@_) * (($xf + $yf) / 2),
                'angle'      => shift(@_),
            }
        );
    },
    'DRAWTO' => sub {
        $F->drawto(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
            }
        );
    },
    'BEZIER' => sub {
        $F->bezier(
            {
                'points'      => shift(@_),
                'pixel_size'  => shift(@_),
                'coordinates' => [@_],
            }
        );
    },
    'ARC' => sub {
        $F->arc(
            {
                'x'             => shift(@_),
                'y'             => shift(@_),
                'radius'        => shift(@_),
                'start_degrees' => shift(@_),
                'end_degrees'   => shift(@_),
                'granularity'   => shift(@_),
            }
        );
    },
    'FILLED_PIE' => sub {
        $F->filled_pie(
            {
                'x'             => shift(@_),
                'y'             => shift(@_),
                'radius'        => shift(@_),
                'start_degrees' => shift(@_),
                'end_degrees'   => shift(@_),
                'granularity'   => shift(@_),
            }
        );
    },
    'POLY_ARC' => sub {
        $F->poly_arc(
            {
                'x'             => shift(@_),
                'y'             => shift(@_),
                'radius'        => shift(@_),
                'start_degrees' => shift(@_),
                'end_degrees'   => shift(@_),
                'granularity'   => shift(@_),
            }
        );
    },
    'ELLIPSE' => sub {
        $F->ellipse(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'xradius'    => shift(@_) * $xf,
                'yradius'    => shift(@_) * $yf,
                'filled'     => (scalar(@_)) ? shift(@_) : 0,
            }
        );
    },
    'CIRCLE' => sub {
        $F->circle(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'radius'     => shift(@_) * $yf,
                'filled'     => (scalar(@_)) ? shift(@_) : 0,
            }
        );
    },
    'POLYFRAME' => sub {
        $F->polygon(
            {
                'coordinates' => [@_],
            }
        );
    },
    'FILLED_POLYGON' => sub {
        $F->polygon(
            {
                'coordinates' => [@_],
                'filled'      => 1,
            }
        );
    },
    'BOX' => sub {
        $F->box(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'xx'         => shift(@_) * $xf,
                'yy'         => shift(@_) * $yf,
                'filled'     => (scalar(@_)) ? shift(@_)       : 0,
                'radius'     => (scalar(@_)) ? shift(@_) * $yf : 0,
            }
        );
    },
    'RBOX' => sub {
        $F->rbox(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'width'      => shift(@_) * $xf,
                'height'     => shift(@_) * $yf,
                'filled'     => (scalar(@_)) ? shift(@_)       : 0,
                'radius'     => (scalar(@_)) ? shift(@_) * $yf : 0,
            }
        );
    },
    'FOREGROUND' => sub {
        $F->set_color(
            {
                'red'   => shift(@_),
                'green' => shift(@_),
                'blue'  => shift(@_),
                'alpha' => (scalar(@_)) ? shift(@_) : 255,
            }
        );
    },
    'BACKGROUND' => sub {
        $F->set_b_color(
            {
                'red'   => shift(@_),
                'green' => shift(@_),
                'blue'  => shift(@_),
                'alpha' => (scalar(@_)) ? shift(@_) : 255,
            }
        );
    },
    'FILL' => sub {
        $F->fill(
            {
                'x' => shift(@_) * $xf,
                'y' => shift(@_) * $yf,
            }
        );
    },
    'REPLACE_COLOR' => sub {
        $F->replace_color(
            {
                'old' => {
                    'red'   => shift(@_),
                    'green' => shift(@_),
                    'blue'  => shift(@_),
                },
                'new' => {
                    'red'   => shift(@_),
                    'green' => shift(@_),
                    'blue'  => shift(@_),
                },
            }
        );
    },
    'BLIT_MOVE' => sub {
        $F->blit_move(
            {
                'x'      => shift(@_),
                'y'      => shift(@_),
                'width'  => shift(@_),
                'height' => shift(@_),
                'x_dest' => shift(@_),
                'y_dest' => shift(@_),
            }
        );
    },
    'BLIT_COPY' => sub {
        $F->blit_copy(
            {
                'x'      => shift(@_),
                'y'      => shift(@_),
                'width'  => shift(@_),
                'height' => shift(@_),
                'x_dest' => shift(@_),
                'y_dest' => shift(@_),
            }
        );
    },
    'PERL' => sub {
        $F->perl();
    },
    'SOFTWARE' => sub {
        $F->software();
    },
    'CLIP_RESET' => sub {
        $F->clip_reset();
    },
    'CLIP_SET' => sub {
        $F->clip_set(
            {
                'x'  => shift(@_) * $xf,
                'y'  => shift(@_) * $yf,
                'xx' => shift(@_) * $xf,
                'yy' => shift(@_) * $yf,
            }
        );
    },
    'CLIP_RSET' => sub {
        $F->clip_rset(
            {
                'x'      => shift(@_) * $xf,
                'y'      => shift(@_) * $yf,
                'width'  => shift(@_) * $xf,
                'height' => shift(@_) * $yf,
            }
        );
    },
    'VSYNC' => sub {
        $F->vsync();
    },
};

foreach my $name (sort(keys %{$cmd})) {
    print STDERR "$name\n";
}
parse(@text);
sleep $delay if ($delay);
$F->cls('ON');
$F->text_mode();

sub parse {
    my @cmds = @_;

    foreach my $line (@cmds) {
        $line =~ s/\#.*//;
        next if ($line eq '');
        my ($c, $t, @p);
        unless ($line =~ /\s+/) {
            $c = $line;
            $cmd->{$line}->();
        } else {
            ($c, $t) = ($line =~ /^(.*?)\s+(.*)/);
            if ($t =~ /,/) {
                @p = split(/,\s*/, $t);
            } else {
                push(@p, $t);
            }
        } ## end else
        if (exists($cmd->{ uc($c) })) {
            $cmd->{ uc($c) }->(@p);
        } else {
            warn "$c not found!";
        }
    } ## end foreach my $line (@cmds)
    sleep $delay if ($delay);
} ## end sub parse

__END__

=pod

=head1 VECTOR DRAWING

=head2 DESCRIPTION

A simple layer to draw simple primitives using the Perl Graphics::Framebuffer similar to BASIC, and resolution independent.

The vector layer uses a virtual 3840 x 2160 screen, regardless of the actual resolution.  This means your drawings will always look great no matter what the actual resolution is.

There is also a timing delay to allow for specifically timed displays.

=head2 SYNOPSIS

 ./vector.pl draw.gfb

=head2 COMMANDS

=over 4

=item B<ADD_MODE>

Sets the drawing mode to B<add> drawing mode.  Pixels will be ADDed with what is already on the screen.

=item B<ALPHA_MODE>

Sets the drawing mode to B<alpha> drawing mode.  Pixels will be overlayed on top of what is already on the screen based on the alpha (opacity) value of the FOREGROUND color.

=item B<AND_MODE>

Sets the drawing mode to B<and> drawing mode.  Pixels will be ANDed with what is already on the screen.

=item B<ANGLE_LINE> x, y, radius, angle

Draws a line, in the FOREGROUND color, starting at point x,y with the length of radius at the given compass angle.

=item B<ARC> x, y, radius, start degrees, end degrees [, granularity]

Draws a circular arc at virtual center point x,y starting at start degree to end degree with the set radius, using the selected granularity

=item B<ATTRIBUTE_RESET>

Sets the FOREGROUND color to white, the BACKGROUND color to black, and resets clipping.

=item B<BACKGROUND> red, green, blue [, alpha]

Sets the background color.

=item B<BEZIER> points, pixel size, coordinate pairs

Draws a bezier curve using the number of points, pixel size, and set number of coordinates (always in x,y pairs).

=item B<BLIT_COPY> x, y, width, height, new x, new y

One screen section can be copied to another location.

=item B<BLIT_MOVE> x, y, width, height, new x, new y

One screen section can be moved to another location.

=item B<BOX> x, y, xx, yy [, filled] [, corner radius]

Draws a box at point x,y to point xx,yy optionally filled and optionally with rounded corners of a specified radius.

=item B<CIRCLE> x, y, radius [, filled]

Draws a circle at center point x,y with the specified radius and optionally filled.

=item B<CLIP_RESET>

Turns off clipping

=item B<CLIP_RSET> x, y, width, height

Sets a clipping rectangle

=item B<CLIP_SET> x, y, xx, yy

Sets a clipping rectangle.

=item B<CLS>

The screen will be cleared with the BACKGROUND color.  Also sets the pixel location to 0,0

=item B<DIVIDE_MODE>

Sets the drawing mode to B<divide> drawing mode.  Pixels will be DIVIDEDed with what is already on the screen.

=item B<DOT> x, y, size

Small solid (filled) circle in the size indicated (size = radius)

=item B<DRAWTO> x, y

Draws a line, in the FOREGROUND color, from the last plotted point to point x,y

=item B<ELLIPSE> x, y, xradius, yradius [, filled]

Draws an ellipse at x,y with xradius width and yradius height and optionally filled

=item B<FILL> x, y

Flood fill at starting point using the background color at that point as a mask.

=item B<FILLED_PIE> x, y, radius, start degrees, end degrees [, granularity]

Draws a pie wedge at virtual center point x,y starting at start degree to end degree with the set radius, using the selected granularity

=item B<FILLED_POLYGON> coordinate pairs

Draws a filles polygon from starting point and back to the starting point with other point pairs dictating shape.

=item B<FOREGROUND> red, green, blue [, alpha]

Sets the forground color.

=item B<GRAPHICS_MODE>

Set the framebuffer to graphics mode.  This shuts off all cursor and text printing functions of the terminal.  Make sure you restore text mode before exiting the vector layer.

=item B<LINE> x, y, xx, yy

Draws a line, in the FOREGROUND color, from x,y to xx,yy.

=item B<MASK_MODE>

Sets the drawing mode to B<mask> drawing mode.  Only pixels that are not the BACKGROUND color are drawn to the screen (mostly useful with blitting).

=item B<MULTIPLY_MODE>

Sets the drawing mode to B<multiply> drawing mode.  Pixels will be MULTIPLIEDed with what is already on the screen.

=item B<NORMAL_MODE>

Sets the drawing mode to B<normal>.  This is the default mode and where pixels are completed replaced without regard to previously placed pixels.  This is the fastet drawing mode.

=item B<OR_MODE>

Sets the drawing mode to B<or> drawing mode.  Pixels will be ORed with what is already on the screen.

=item B<PERL>

Turns off C acceleration

=item B<PLAY> filename

A animation (GIF) is played, centered on the screen.  "Q" must be pressed to continue

=item B<PLAY_MAX> filename

A animation (GIF) is played, proportionally scaled to the full screen and centered on the screen.  "Q" must be pressed to continue

=item B<PLOT> x, y

Plots a single pixel, in the FOREGROUND color, at the x,y coordinates.

=item B<POLYFRAME> coordinate pairs

Draws a polygon frame from starting point and back to the starting point with other point pairs dictating shape.  The coordinates must be in pairs (even numbers)

=item B<POLYGON> coordinate pairs

Draws a filled polygon from starting point and back to the starting point with other point pairs dictating shape.  The coordinates must be in pairs (even numbers)

=item B<POLY_ARC> x, y, radius, start degrees, end degrees [, granularity]

Draws a filled pie at virtual center point x,y starting at start degree to end degree with the set radius, using the selected granularity

=item B<RBOX> x, y, width, height [, filled] [, corner radius]

Draws a rounded box at point x,y with width and height, optionally filled.  Radius or corners can be optionally defined.

=item B<REPLACE_COLOR> old red, old green, old blue, new red, new green, new blue

Replaces the old color with the new color and clipping applies.

=item B<SOFTWARE>

Turns on C acceleration

=item B<SPLASH>

Shows the Graphics::Framebuffer splash screen.

=item B<STAR> x, y, size

Draw a 5 pointed star at location x,y (center point).  Use size to specify the size.

=item B<SUBTRACT_MODE>

Sets the drawing mode to B<subtract> drawing mode.  Pixels will be SUBTRACTEDed from what is already on the screen.

=item B<TEXT_MODE>

Set the framebuffer back to text mode, after having been previous set to graphics mode with B<GRAPHICS_MODE>

=item B<UNMASK_MODE>

Sets the drawing mode to B<unmask> drawing mode.  Only pixels will be drawn on BACKGROUND colored pixels.

=item B<VSYNC>

Waits for a vertical sync.

Note:  Not many framebuffer drivers support this.

=item B<WAIT> seconds

Waits for the given number of seconds before showing the remaining scripted primitives.

=item B<XOR_MODE>

Sets the drawing mode to B<xor> drawing mode.  Pixels will be XORed with what is already on the screen.

=back

=cut
