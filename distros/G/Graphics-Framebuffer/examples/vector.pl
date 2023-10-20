#!/usr/bin/env perl

# Vector drawing parser
# Virtual resolution is ALWAYS 3840 x 2160
# it will be converted to the actual resolution when drawn
# The commands are a subset of the actual GFB capabilites

use strict;

use Graphics::Framebuffer;
# use Data::Dumper::Simple;

BEGIN {
	our $VERSION = '0.02';
};

my $F = Graphics::Framebuffer->new('SPLASH' => 0);

my ($width,$height,$bpp) = $F->screen_dimensions();
my ($xf,$yf) = ($width / 3840, $height / 2160);

open(my $FILE, '<', shift(@ARGV));
chomp(my @text = <$FILE>);
close($FILE);

my $cmd = {
    'WAIT' => sub {
        my $wait = shift || 1;
        sleep $wait;
    },
    'TEXT_MODE' => sub {
        $F->text_mode();
    },
    'GRAPHICS_MODE' => sub {
        $F->graphics_mode();
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
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
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
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
            }
        );
    },
    'ANGLE_LINE' => sub {
        $F->angle_line(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'radius'     => shift(@_) * (($xf + $yf)/2),
                'angle'      => shift(@_),
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
            }
        );
    },
    'DRAWTO' => sub {
        $F->drawto(
            {
                'x'          => shift(@_) * $xf,
                'y'          => shift(@_) * $yf,
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
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
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
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
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
            }
        );
    },
    'POLYGON' => sub {
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
                'filled'     => (scalar(@_)) ? shift(@_) : 0,
                'radius'     => (scalar(@_)) ? shift(@_) * $yf : 0,
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
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
                'filled'     => (scalar(@_)) ? shift(@_) : 0,
                'radius'     => (scalar(@_)) ? shift(@_) * $yf : 0,
                'pixel_size' => (scalar(@_)) ? shift(@_) : 1,
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
    'CIP_RSET' => sub {
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

parse(@text);

sub parse {
    my @cmds = @_;

    foreach my $line (@cmds) {
        $line =~ s/\#.*//;
        next if ($line eq '');
        my ($c,$t,@p);
        unless ($line =~ /\s+/) {
            $c = $line;
            $cmd->{$line}->();
        } else {
            ($c,$t) = ($line =~ /^(.*?)\s+(.*)/);
            if ($t =~ /,/) {
                @p = split(/,\s*/,$t);
            } else {
                push(@p,$t);
            }
        }
        if (exists($cmd->{uc($c)})) {
            $cmd->{uc($c)}->(@p);
        } else {
            warn "$c not found!";
        }
    }
}

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

=item B<WAIT> seconds

Waits for the given number of seconds before showing the remaining scripted primitives.  Seconds is an integer.

=item B<GRAPHICS_MODE>

Set the framebuffer to graphics mode.  This shuts off all cursor and text printing functions of the terminal.  Make sure you restore text mode before exiting the vector layer.

=item B<TEXT_MODE>

Set the framebuffer back to text mode, after having been previous set to graphics mode with B<GRAPHICS_MODE>

=item B<SPLASH>

Shows the Graphics::Framebuffer splash screen.

=item B<NORMAL_MODE>

Sets the drawing mode to B<normal>.  This is the default mode and where pixels are completed replaced without regard to previously placed pixels.  This is the fastet drawing mode.

=item B<XOR_MODE>

Sets the drawing mode to B<xor> drawing mode.  Pixels will be XORed with what is already on the screen.

=item B<OR_MODE>

Sets the drawing mode to B<or> drawing mode.  Pixels will be ORed with what is already on the screen.

=item B<AND_MODE>

Sets the drawing mode to B<and> drawing mode.  Pixels will be ANDed with what is already on the screen.

=item B<ALPHA_MODE>

Sets the drawing mode to B<alpha> drawing mode.  Pixels will be overlayed on top of what is already on the screen based on the alpha (opacity) value of the FOREGROUND color.

=item B<MASK_MODE>

Sets the drawing mode to B<mask> drawing mode.  Only pixels that are not the BACKGROUND color are drawn to the screen (mostly useful with blitting).

=item B<UNMASK_MODE>

Sets the drawing mode to B<unmask> drawing mode.  Only pixels will be drawn on BACKGROUND colored pixels.

=item B<ADD_MODE>

Sets the drawing mode to B<add> drawing mode.  Pixels will be ADDed with what is already on the screen.

=item B<SUBTRACT_MODE>

Sets the drawing mode to B<subtract> drawing mode.  Pixels will be SUBTRACTEDed from what is already on the screen.

=item B<MULTIPLY_MODE>

Sets the drawing mode to B<multiply> drawing mode.  Pixels will be MULTIPLIEDed with what is already on the screen.

=item B<DIVIDE_MODE>

Sets the drawing mode to B<divide> drawing mode.  Pixels will be DIVIDEDed with what is already on the screen.

=item B<CLS>

The screen will be cleared with the BACKGROUND color.  Also sets the pixel location to 0,0

=item B<ATTRIBUTE_RESET>

Sets the FOREGROUND color to white, the BACKGROUND color to black, and resets clipping.

=item B<PLOT> x, y [, pixel size]

Plots a single pixel, in the FOREGROUND color, at the x,y coordinates.

=item B<LINE> x, y, xx, yy [, pixel size]

Draws a line, in the FOREGROUND color, from x,y to xx,yy.

=item B<ANGLE_LINE> x, y, radius, angle [, pixel size]

Draws a line, in the FOREGROUND color, starting at point x,y with the length of radius at the given compass angle.

=item B<DRAWTO> x, y [, pixel size]

Draws a line, in the FOREGROUND color, from the last plotted point to point x,y

=item B<BEZIER> points, pixel size, coordinate pairs

Draws a bezier curve using the number of points, pixel size, and set number of coordinates (always in x,y pairs).

=item B<ARC> x, y, radius, start degrees, end degrees, granularity

=item B<FILLED_PIE> x, y, radius, start degrees, end degrees, granularity

=item B<POLY_ARC> x, y, radius, start degrees, end degrees, granularity

=item B<ELLIPSE> x, y, xradius, yradius [, filled] [, pixel size]

=item B<CIRCLE> x, y, radius [, filled] [, pixel size]

=item B<POLYGON> coordinate pairs

=item B<FILLED_POLYGON> coordinate pairs

=item B<BOX> x, y, xx, yy [, filled] [, corner radius] [, pixel size]

=item B<RBOX> x, y, width, height [, filled] [, corner radius] [, pixel size]

=item B<FOREGROUND> red, green, blue [, alpha]

=item B<BACKGROUND> red, green, blue [, alpha]

=item B<FILL> x, y

=item B<REPLACE_COLOR> old red, old green, old blue, new red, new green, new blue

=item B<BLIT_MOVE> x, y, width, height, new x, new y

=item B<BLIT_COPY> x, y, width, height, new x, new y

=item B<PERL>

=item B<SOFTWARE>

=item B<CLIP_RESET>

=item B<CLIP_SET> x, y, xx, yy

=item B<CLIP_RSET> x, y, width, height

=item B<VSYNC>

=back

=cut
