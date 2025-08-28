package Graphics::Framebuffer::Splash;

use strict;
no strict 'vars';    # We have to map a variable as the screen.  So strict is going to whine about what we do with it.
no warnings;         # We have to be as quiet as possible

use constant {
    TRUE  => 1,
    FALSE => 0
};

use List::Util qw(min max); # Helpful for returning the minimum or maximum value within a list.

BEGIN {
    require Exporter;
    our @ISA       = qw( Exporter );
    our $VERSION   = '1.25';
    our @EXPORT    = qw( _perl_logo _coin splash );
    our @EXPORT_OK = qw();
} ## end BEGIN

sub splash {
    my $self    = shift;
    my $version = shift || $self->{'VERSION'};
    return if ($self->{'SPLASH'} == 0);

    my $X = $self->{'X_CLIP'};
    my $Y = $self->{'Y_CLIP'};
    my $W = $self->{'W_CLIP'};
    my $H = $self->{'H_CLIP'};

    # The logo was designed using 3840x2160 screen.  It is scaled accordingly.
    my $hf = $W / 3840;    # Scales the logo.  Everything scales according to these values.
    my $vf = $H / 2160;
    $self->{'H_SCALE'}  = $hf;
    $self->{'V_SCALE'}  = $vf;
    $self->{'H_OFFSET'} = $X;
    $self->{'V_OFFSET'} = $Y;

    my $bold = $self->{'FONT_FACE'};
    $bold =~ s/\.ttf$/Bold.ttf/;

    $self->cls();
    $self->clip_reset();
    $self->normal_mode();

    # Draws the main boxes
    $self->set_color( # The green background
		{
			'red'   => 0,
			'green' => 64,
			'blue'  => 0,
			'alpha' => 255,
		}
	);
    $self->rbox(
        {
            'x'      => $X,
            'y'      => $Y,
            'width'  => $W,
            'height' => $H,
            'filled' => TRUE,
            'hatch'  => 'dots16'
        }
    );
	# The blue box
    $self->alpha_mode() if ($self->{'GPU'} !~ /nouveaufb/ && $self->{'ACCELERATED'});    # Set this box to be semi-transparent unless using a Nouveau driver, because Nouveau SUCKS
    $self->set_color( # Set box to a blue hue
		{
			'red'   => 0,
			'green' => 0,
			'blue'  => 128,
			'alpha' => 255,
		}
	);
    $self->polygon( # The box is distorted, so draw it as a polygon
        {
            'coordinates' => [
				(800 * $hf) + $X,
				(160 * $vf) + $Y,

				(40 * $hf) + $X,
				(1600 * $vf) + $Y,

				(3200 * $hf) + $X,
				(2156 * $vf) + $Y,

				(3800 * $hf) + $X,
				(10 * $vf) + $Y,
			],
            'filled'      => TRUE,
            'gradient'    => {
                'colors' => {
                    'red'   => [0,   0],
                    'green' => [0,   0],
                    'blue'  => [128, 255], # Make it a blue hue gradient growing in intensity
                    'alpha' => [128, 255], # Make it less transparent as intensity climbs
                },
            }
        }
    );
    # The red box
    $self->set_color(
		{
			'red'   => 255,
			'green' => 0,
			'blue'  => 0,
			'alpha' => 100,
		}
	);
    $self->rbox(
        {
            'x'        => (260 * $hf) + $X,
            'y'        => (300 * $vf) + $Y,
            'width'    => 3350 * $hf,
            'height'   => 1600 * $vf,
            'radius'   => 30 * min($hf, $vf),
            'filled'   => TRUE,
            'gradient' => {
                'direction' => 'vertical',
                'colors'    => {
                    'red'   => [32, 200], # a gradient of red intensity
                    'green' => [0,  0],
                    'blue'  => [0,  0],
                    'alpha' => [96, 220], # a gradient of alpha intensity
                },
            },
        }
    );

    # 'Accelerated' shadow
    $self->set_color(
		{
			'red'   => 32,
			'green' => 0,
			'blue'  => 0,
			'alpha' => 255,
		}
	);
    $self->rbox(
        {
            'x'      => (956 * $hf) + $X,
            'y'      => (416 * $vf) + $Y,
            'width'  => (2460 * $hf),
            'height' => (300 * $vf),
            'radius' => 60 * $vf,
            'filled' => TRUE,
        }
    );

    # (Un)Accelerated green-yellow
    $self->rbox(
        {
            'x'        => (940 * $hf) + $X,
            'y'        => (400 * $vf) + $Y,
            'width'    => (2460 * $hf),
            'height'   => (300 * $vf),
            'radius'   => 60 * $vf,
            'filled'   => TRUE,
            'gradient' => {
                'direction' => 'vertical',
                'colors'    => {
                    'red'   => [100,  255, 100],
                    'green' => [100,  255, 100],
                    'blue'  => [0,      0,   0],
                    'alpha' => [128,  255, 128],
                },
            }
        }
    );

    {
        my $t = 'Perl Drawing Mode';
        if ($self->{'ACCELERATED'} == 1) {
            $t = 'C Assisted Mode';
        } elsif ($self->{'ACCELERATED'} == 2) {
            $t = 'GPU Assisted Mode';
        }
        $self->ttf_print(
            $self->ttf_print(
                {
                    'bounding_box' => TRUE,
                    'x'            => (1020 * $hf) + $X,
                    'y'            => (680 * $vf) + $Y,
                    'height'       => 220 * $vf,
                    'wscale'       => 1.20,
                    'color'        => '0101FFFF',
                    'text'         => $t,
                    'bounding_box' => TRUE,
                    'center'       => 0,
                    'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
                }
            )
        );
    }
    if ($self->{'BITS'} >= 24) { # We only draw shadows in 24 bits and 32 bits color levels
        my $shadow = $self->ttf_print(
            {
                'bounding_box' => TRUE,
                'x'            => 0,
                'y'            => (1242 * $vf) + $Y,
                'height'       => 400 * $vf,
                'wscale'       => 0.95,
                'color'        => ($self->{'GPU'} !~ /nouveaufb/) ? '221100A0' : '221100FF',
                'text'         => 'Graphics-Framebuffer',
                'bounding_box' => TRUE,
                'center'       => $self->{'CENTER_X'},
                'antialias'    => TRUE
            }
        );
        if ($shadow->{'pwidth'} > (3000 * $hf)) {
            $shadow->{'bounding_box'} = TRUE;
            $shadow->{'wscale'}       = int(3000 * $hf) / $shadow->{'pwidth'};
            $shadow                   = $self->ttf_print($shadow);
        }
        $shadow->{'x'} += max(1, 16 * $hf);
        $shadow->{'y'} += max(1, 16 * $vf);
        delete($shadow->{'center'});
        $self->ttf_print($shadow);
    } ## end if ($self->{'BITS'} >=...)
    my $gfb = $self->ttf_print(
        {
            'bounding_box' => TRUE,
            'x'            => 0,
            'y'            => (1242 * $vf) + $Y,
            'height'       => 400 * $vf,
            'wscale'       => 0.95,
            'color'        => 'FFFF00FF',
            'text'         => 'Graphics-Framebuffer',
            'bounding_box' => TRUE,
            'center'       => $self->{'CENTER_X'},
            'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
        }
    );
    if ($gfb->{'pwidth'} > (3000 * $hf)) {
        $gfb->{'bounding_box'} = TRUE;
        $gfb->{'wscale'}       = int(3000 * $hf) / $gfb->{'pwidth'};
        $gfb                   = $self->ttf_print($gfb);
    }
    $self->ttf_print($gfb);

    my $rk = $self->ttf_print(
        {
            'bounding_box' => TRUE,
            'x'            => 0,
            'y'            => (1270 * $vf) + $Y,
            'height'       => 100 * $vf,
            'wscale'       => 1,
            'color'        => '00EE00FF',
            'text'         => 'by Richard Kelsch',
            'bounding_box' => TRUE,
            'center'       => FALSE,
            'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
        }
    );
    $rk->{'x'} = (3480 * $hf) - $rk->{'pwidth'};
    $self->ttf_print($rk);

    # Draw the info portion
    $self->alpha_mode() if ($self->{'GPU'} !~ /nouveaufb/ && $self->{'ACCELERATED'});    # Nouveau totally sucks for framebuffer work, so we disable alpha

    $self->rbox(
        {
            'x'      => (356 * $hf) + $X,
            'y'      => (1280 * $vf) + $Y,
            'width'  => (3140 * $hf),
            'height' => (560 * $vf),
            'filled'   => TRUE,
            'gradient' => {
                'direction' => 'horizontal',
                'colors'    => {
                    'red'   => [32, 0,   32],
                    'green' => [0,  0,   0],
                    'blue'  => [0,  255, 0],
                    'alpha' => [64, 128, 64]
                }
            }
        }
    );

    $self->normal_mode();
    $self->ttf_print(
        $self->ttf_print(
            {
                'bounding_box' => TRUE,
                'x'            => 0,
                'y'            => (1570 * $vf) + $Y,
                'height'       => 236 * $vf,
                'wscale'       => 1,
                'color'        => 'FFFFFFFF',
                'text'         => sprintf('Version %.02f', $version),
                'bounding_box' => TRUE,
                'center'       => $self->{'CENTER_X'},
                'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
            }
        )
    );
    my $scaleit = $self->ttf_print(
        {
            'bounding_box' => TRUE,
            'x'            => 0,
            'y'            => (1830 * $vf) + $Y,
            'height'       => 236 * $vf,
            'wscale'       => 1,
            'color'        => 'FFFFFFFF',
            'text'         => sprintf('%dx%d-%02d on %s', $self->{'XRES'}, $self->{'YRES'}, $self->{'BITS'}, $self->{'GPU'}),
            'bounding_box' => TRUE,
            'center'       => $self->{'CENTER_X'},
            'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
        }
    );
    if ($scaleit->{'pwidth'} > int(3000 * $hf)) {
        $scaleit->{'bounding_box'} = TRUE;
        $scaleit->{'wscale'}       = int(3000 * $hf) / $scaleit->{'pwidth'};
        $scaleit                   = $self->ttf_print($scaleit);
    }
    $self->ttf_print($scaleit);
    $self->_perl_logo();
	$self->_coin();
    $self->normal_mode();
} ## end sub splash

sub _perl_logo {
    my $self = shift;
    return unless (exists($self->{'FONTS'}->{'DejaVuSerif'}));
    my $hf = $self->{'H_SCALE'};
    my $vf = $self->{'V_SCALE'};
    my $X  = $self->{'H_OFFSET'};
    my $Y  = $self->{'V_OFFSET'};

    $self->normal_mode();
    $self->set_color(
		{
			'red'   => 0,
			'green' => 0,
			'blue'  => 0,
			'alpha' => 128,
		}
	);
    $self->ellipse(
        {
            'x'       => (1930 * $hf) + $X,
            'y'       => (96 * $vf) + $Y,
            'xradius' => 140 * $hf,
            'yradius' => 65 * $vf,
            'filled'  => TRUE
        }
    );
    $self->set_color(
		{
			'red'   => 0,
			'green' => 64,
			'blue'  => 255,
			'alpha' => 255,
		}
	);
    $self->ellipse(
        {
            'x'       => (1920 * $hf) + $X,
            'y'       => (91 * $vf) + $Y,
            'xradius' => 140 * $hf,
            'yradius' => 65 * $vf,
            'filled'  => TRUE
        }
    );

    $self->xor_mode();
    $self->ttf_print(
        $self->ttf_print(
            {
                'bounding_box' => TRUE,
                'y'            => (152 * $vf) + $Y,                              # 85 * $vf,
                'height'       => 80 * $vf,
                'wscale'       => 1,
                'color'        => '0040FFFF',
                'text'         => 'Perl',
                'face'         => $self->{'FONTS'}->{'DejaVuSerif'}->{'font'},
                'font_path'    => $self->{'FONTS'}->{'DejaVuSerif'}->{'path'},
                'bounding_box' => TRUE,
                'center'       => $self->{'CENTER_X'},
                'antialias'    => FALSE
            }
        )
    );
} ## end sub _perl_logo

sub _coin {
    my $self = shift;

    my $hf = $self->{'H_SCALE'};
    my $vf = $self->{'V_SCALE'};
    my $X  = $self->{'H_OFFSET'};
    my $Y  = $self->{'V_OFFSET'};
    my ($R, $G, $B);

    ### Draws the Circle with GFB in it ###
    # The dark shadow circle
    $self->set_color(
		{
			'red'   => 32,
			'green' => 0,
			'blue'  => 0,
			'alpha' => ($self->{'GPU'} !~ /nouveaufb/) ? 200 : 255,
		}
	);
    $self->circle(
        {
            'x'      => (414 * $hf) + $X,
            'y'      => (414 * $vf) + $Y,
            'radius' => 400 * min($vf, $hf),
            'filled' => TRUE
        }
    );

    $self->normal_mode();

    # The "coin"
    $self->set_color(
		{
			'red'   => 255,
			'green' => 255,
			'blue'  => 255,
			'alpha' => 255,
		}
	);
    $self->circle(
        {
            'x'        => (400 * $hf) + $X,
            'y'        => (400 * $vf) + $Y,
            'radius'   => 400 * min($hf, $vf),
            'filled'   => TRUE,
            'gradient' => {
                'direction' => 'horizontal',
                'colors'    => {
                    'red'   => [255, 255, 255],
                    'green' => [192, 96,  228],
                    'blue'  => [0,   0,   0],
                    'alpha' => [255, 255, 255],
                },
            }
        }
    );

    # G
    $self->set_color(
		{
			'red'   => 32,
			'green' => 32,
			'blue'  => 0,
			'alpha' => 255,
		}
	);
    $self->filled_pie(
        {
            'x'             => (194 * $hf) + $X,
            'y'             => (404 * $vf) + $Y,
            'radius'        => 104 * $vf,
            'start_degrees' => 90,
            'end_degrees'   => 10,
            'granularity'   => 0.05
        }
    );

    # F
    $self->polygon(
        {
            'coordinates' => [
				(324 * $hf) + $X,
				(504 * $vf) + $Y,

				(324 * $hf) + $X,
				(304 * $vf) + $Y,

				(524 * $hf) + $X,
				(304 * $vf) + $Y,

				(484 * $hf) + $X,
				(344 * $vf) + $Y,

				(364 * $hf) + $X,
				(344 * $vf) + $Y,

				(364 * $hf) + $X,
				(384 * $vf) + $Y,

				(444 * $hf) + $X,
				(384 * $vf) + $Y,

				(404 * $hf) + $X,
				(424 * $vf) + $Y,

				(364 * $hf) + $X,
				(424 * $vf) + $Y,

				(364 * $hf) + $X,
				(464 * $vf) + $Y,
			],
            'filled'      => TRUE,
            'pixel_size'  => 1
        }
    );

    # B
    $self->polygon(
        {
            'coordinates' => [
				(544 * $hf) + $X,
				(504 * $vf) + $Y,

				(544 * $hf) + $X,
				(304 * $vf) + $Y,

				(644 * $hf) + $X,
				(304 * $vf) + $Y,

				(644 * $hf) + $X,
				(504 * $vf) + $Y,
			],
            'filled'      => TRUE,
            'pixel_size'  => 1
        }
    );
    $self->circle(
        {
            'x'      => (644 * $hf) + $X,
            'y'      => (354 * $vf) + $Y,
            'radius' => 50 * $vf,
            'filled' => TRUE
        }
    );
    $self->circle(
        {
            'x'      => (644 * $hf) + $X,
            'y'      => (454 * $vf) + $Y,
            'radius' => 50 * $vf,
            'filled' => TRUE
        }
    );

    if ($self->{'COLOR_ORDER'} == $self->{'BGR'}) {
        ($R, $G, $B) = (0, 0, 255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'BRG'}) {
        ($R, $G, $B) = (0, 0, 255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RGB'}) {
        ($R, $G, $B) = (255, 0, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RBG'}) {
        ($R, $G, $B) = (255, 0, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GRB'}) {
        ($R, $G, $B) = (0, 255, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GBR'}) {
        ($R, $G, $B) = (0, 255, 0);
    }
    $self->set_color(
		{
			'red'   => $R,
			'green' => $G,
			'blue'  => $B,
			'alpha' => 255,
		}
	);

    # G
    $self->filled_pie(
        {
            'x'             => (190 * $hf) + $X,
            'y'             => (400 * $vf) + $Y,
            'radius'        => 104 * $vf,
            'start_degrees' => 90,
            'end_degrees'   => 10,
            'granularity'   => 0.05
        }
    );

    # F
    if ($self->{'COLOR_ORDER'} == $self->{'BGR'}) {
        ($R, $G, $B) = (0, 255, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'BRG'}) {
        ($R, $G, $B) = (255, 0, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RGB'}) {
        ($R, $G, $B) = (0, 255, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RBG'}) {
        ($R, $G, $B) = (0, 0, 255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GRB'}) {
        ($R, $G, $B) = (255, 0, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GBR'}) {
        ($R, $G, $B) = (0, 0, 255);
    }
    $self->set_color({ 'red' => $R, 'green' => $G, 'blue' => $B, 'alpha' => 255 });

    $self->polygon(
        {
            'coordinates' => [
                (320 * $hf) + $X,
                (500 * $vf) + $Y,

                (320 * $hf) + $X,
                (300 * $vf) + $Y,

                (520 * $hf) + $X,
                (300 * $vf) + $Y,

                (480 * $hf) + $X,
                (340 * $vf) + $Y,

                (360 * $hf) + $X,
                (340 * $vf) + $Y,

                (360 * $hf) + $X,
                (380 * $vf) + $Y,

                (440 * $hf) + $X,
                (380 * $vf) + $Y,

                (400 * $hf) + $X,
                (420 * $vf) + $Y,

                (360 * $hf) + $X,
                (420 * $vf) + $Y,

                (360 * $hf) + $X,
                (460 * $vf) + $Y
            ],
            'filled'     => TRUE,
            'pixel_size' => 1
        }
    );

    $self->normal_mode();

    # B
    if ($self->{'COLOR_ORDER'} == $self->{'BGR'}) {
        ($R, $G, $B) = (255, 0, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'BRG'}) {
        ($R, $G, $B) = (0, 255, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RGB'}) {
        ($R, $G, $B) = (0, 0, 255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RBG'}) {
        ($R, $G, $B) = (0, 255, 0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GRB'}) {
        ($R, $G, $B) = (0, 0, 255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GBR'}) {
        ($R, $G, $B) = (255, 0, 0);
    }
    $self->set_color({ 'red' => $R, 'green' => $G, 'blue' => $B, 'alpha' => 255 });

    $self->polygon(
        {
            'coordinates' => [
                (540 * $hf) + $X,
                (500 * $vf) + $Y,

                (540 * $hf) + $X,
                (300 * $vf) + $Y,

                (640 * $hf) + $X,
                (300 * $vf) + $Y,

                (640 * $hf) + $X,
                (500 * $vf) + $Y,
            ],
            'filled' => TRUE,
        }
    );
    $self->circle(
        {
            'x'      => (640 * $hf) + $X,
            'y'      => (350 * $vf) + $Y,
            'radius' => 50 * $vf,
            'filled' => TRUE
        }
    );
    $self->circle(
        {
            'x'      => (640 * $hf) + $X,
            'y'      => (450 * $vf) + $Y,
            'radius' => 50 * $vf,
            'filled' => TRUE
        }
    );
} ## end sub _coin

1;

=head1 NAME

Graphics::Framebuffer::Splash

=head1 DESCRIPTION

See the "Graphics::Frambuffer" documentation, as methods within here are pulled into the main module

=cut

