package Graphics::Framebuffer::Splash;

use strict;
no strict 'vars';    # We have to map a variable as the screen.  So strict is going to whine about what we do with it.
no warnings;         # We have to be as quiet as possible

use constant {
    TRUE  => 1,
    FALSE => 0
};

use List::Util qw(min max);

BEGIN {
    require Exporter;
    our @ISA = qw( Exporter );
    our $VERSION = '1.24';
    our @EXPORT = qw( _perl_logo splash );
    our @EXPORT_OK = qw();
}

sub _perl_logo {
    my $self = shift;
    return unless (exists($self->{'FONTS'}->{'DejaVuSerif'}));
    my $hf = $self->{'H_SCALE'};
    my $vf = $self->{'V_SCALE'};
    my $X  = $self->{'H_OFFSET'};
    my $Y  = $self->{'V_OFFSET'};

    $self->normal_mode();
    $self->set_color({ 'red' => 0, 'green' => 0, 'blue' => 0, 'alpha' => 128 });
    $self->ellipse(
        {
            'x'       => (965 * $hf) + $X,
            'y'       => (96 * $vf) + $Y,
            'xradius' => 140 * $hf,
            'yradius' => 65 * $vf,
            'filled'  => TRUE
        }
    );
    $self->set_color({ 'red' => 0, 'green' => 64, 'blue' => 255, 'alpha' => 255 });
    $self->ellipse(
        {
            'x'       => (960 * $hf) + $X,
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

sub splash {
    my $self    = shift;
    my $version = shift || $self->{'VERSION'};
    return if ($self->{'SPLASH'} == 0);

    my $X = $self->{'X_CLIP'};
    my $Y = $self->{'Y_CLIP'};
    my $W = $self->{'W_CLIP'};
    my $H = $self->{'H_CLIP'};
    my ($R,$G,$B);

    # The logo was designed using 1920x1080 screen.  It is scaled accordingly.
    my $hf = $W / 1920;    # Scales the logo.  Everything scales according to these values.
    my $vf = $H / 1080;
    $self->{'H_SCALE'}  = $hf;
    $self->{'V_SCALE'}  = $vf;
    $self->{'H_OFFSET'} = $X;
    $self->{'V_OFFSET'} = $Y;

    my $bold = $self->{'FONT_FACE'};
    $bold =~ s/\.ttf$/Bold.ttf/;

    $self->cls();
    $self->clip_reset();
    $self->normal_mode();

    # If the screen is tiny, then we use a different splash screen
    $self->normal_mode();

    # Draws the main boxes
    $self->set_color({ 'red' => 0, 'green' => 32, 'blue' => 0, 'alpha' => 255 });
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
    $self->alpha_mode() if ($self->{'GPU'} !~ /nouveaufb/ && $self->{'ACCELERATED'}); # Nouveau SUCKS
    $self->set_color({ 'red' => 0, 'green' => 0, 'blue' => 128, 'alpha' => 255 });
    $self->polygon(
        {
            'coordinates' => [(400 * $hf) + $X, (80 * $vf) + $Y, (20 * $hf) + $X, (800 * $vf) + $Y, (1600 * $hf) + $X, (1078 * $vf) + $Y, (1900 * $hf) + $X, (5 * $vf) + $Y],
            'filled'      => TRUE,
            'gradient'    => {
                'colors' => {
                    'red'   => [0,   0],
                    'green' => [0,   0],
                    'blue'  => [128, 255],
                    'alpha' => [128, 255],
                },
            }
        }
    );

    $self->set_color({ 'red' => 255, 'green' => 0, 'blue' => 0, 'alpha' => 100 });
    $self->rbox(
        {
            'x'        => (150 * $hf) + $X,
            'y'        => (150 * $vf) + $Y,
            'width'    => 1660 * $hf,
            'height'   => 800 * $vf,
            'radius'   => 15 * min($hf, $vf),
            'filled'   => TRUE,
            'gradient' => {
                'direction' => 'vertical',
                'colors'    => {
                    'red'   => [32, 200],
                    'green' => [0,  0],
                    'blue'  => [0,  0],
                    'alpha' => [96, 220],
                },
            },
        }
    );

    ### Draws the Circle with GFB in it ###
    # The dark shadow circle
    $self->set_color({ 'red' => 32, 'green' => 0, 'blue' => 0, 'alpha' => ($self->{'GPU'} !~ /nouveaufb/) ? 200 : 255 });
    $self->circle(
        {
            'x'      => (207 * $hf) + $X,
            'y'      => (207 * $vf) + $Y,
            'radius' => 200 * min($vf, $hf),
            'filled' => TRUE
        }
    );

    $self->normal_mode();

    # The "coin"
    $self->set_color({ 'red' => 255, 'green' => 255, 'blue' => 255, 'alpha' => 255 });
    $self->circle(
        {
            'x'        => (200 * $hf) + $X,
            'y'        => (200 * $vf) + $Y,
            'radius'   => 200 * min($hf, $vf),
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
    $self->set_color({ 'red' => 32, 'green' => 32, 'blue' => 0, 'alpha' => 255 });
    $self->filled_pie(
        {
            'x'             => (97 * $hf) + $X,
            'y'             => (202 * $vf) + $Y,
            'radius'        => 52 * $vf,
            'start_degrees' => 90,
            'end_degrees'   => 10,
            'granularity'   => 0.05
        }
    );

    # F
    $self->polygon(
        {
            'coordinates' => [(162 * $hf) + $X, (252 * $vf) + $Y, (162 * $hf) + $X, (152 * $vf) + $Y, (262 * $hf) + $X, (152 * $vf) + $Y, (242 * $hf) + $X, (172 * $vf) + $Y, (182 * $hf) + $X, (172 * $vf) + $Y, (182 * $hf) + $X, (192 * $vf) + $Y, (222 * $hf) + $X, (192 * $vf) + $Y, (202 * $hf) + $X, (212 * $vf) + $Y, (182 * $hf) + $X, (212 * $vf) + $Y, (182 * $hf) + $X, (232 * $vf) + $Y],
            'filled'      => TRUE,
            'pixel_size'  => 1
        }
    );

    # B
    $self->polygon(
        {
            'coordinates' => [(272 * $hf) + $X, (252 * $vf) + $Y, (272 * $hf) + $X, (152 * $vf) + $Y, (322 * $hf) + $X, (152 * $vf) + $Y, (322 * $hf) + $X, (252 * $vf) + $Y],
            'filled'      => TRUE,
            'pixel_size'  => 1
        }
    );
    $self->circle(
        {
            'x'      => (322 * $hf) + $X,
            'y'      => (177 * $vf) + $Y,
            'radius' => 25 * $vf,
            'filled' => TRUE
        }
    );
    $self->circle(
        {
            'x'      => (322 * $hf) + $X,
            'y'      => (227 * $vf) + $Y,
            'radius' => 25 * $vf,
            'filled' => TRUE
        }
    );

    if ($self->{'COLOR_ORDER'} == $self->{'BGR'}) {
        ($R,$G,$B) = (0,0,255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'BRG'}) {
        ($R,$G,$B) = (0,0,255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RGB'}) {
        ($R,$G,$B) = (255,0,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RBG'}) {
        ($R,$G,$B) = (255,0,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GRB'}) {
        ($R,$G,$B) = (0,255,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GBR'}) {
        ($R,$G,$B) = (0,255,0);
    }
    $self->set_color({ 'red' => $R, 'green' => $G, 'blue' => $B, 'alpha' => 255 });

    # G
    $self->filled_pie(
        {
            'x'             => (95 * $hf) + $X,
            'y'             => (200 * $vf) + $Y,
            'radius'        => 52 * $vf,
            'start_degrees' => 90,
            'end_degrees'   => 10,
            'granularity'   => 0.05
        }
    );

    # F
    if ($self->{'COLOR_ORDER'} == $self->{'BGR'}) {
        ($R,$G,$B) = (0,255,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'BRG'}) {
        ($R,$G,$B) = (255,0,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RGB'}) {
        ($R,$G,$B) = (0,255,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RBG'}) {
        ($R,$G,$B) = (0,0,255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GRB'}) {
        ($R,$G,$B) = (255,0,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GBR'}) {
        ($R,$G,$B) = (0,0,255);
    }
    $self->set_color({ 'red' => $R, 'green' => $G, 'blue' => $B, 'alpha' => 255 });

    $self->polygon(
        {
            'coordinates' => [
                (160 * $hf) + $X,
                (250 * $vf) + $Y,

                (160 * $hf) + $X,
                (150 * $vf) + $Y,

                (260 * $hf) + $X,
                (150 * $vf) + $Y,

                (240 * $hf) + $X,
                (170 * $vf) + $Y,

                (180 * $hf) + $X,
                (170 * $vf) + $Y,

                (180 * $hf) + $X,
                (190 * $vf) + $Y,

                (220 * $hf) + $X,
                (190 * $vf) + $Y,

                (200 * $hf) + $X,
                (210 * $vf) + $Y,

                (180 * $hf) + $X,
                (210 * $vf) + $Y,

                (180 * $hf) + $X,
                (230 * $vf) + $Y
            ],
            'filled'      => TRUE,
            'pixel_size'  => 1
        }
    );

    $self->normal_mode();

    # B
    if ($self->{'COLOR_ORDER'} == $self->{'BGR'}) {
        ($R,$G,$B) = (255,0,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'BRG'}) {
        ($R,$G,$B) = (0,255,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RGB'}) {
        ($R,$G,$B) = (0,0,255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'RBG'}) {
        ($R,$G,$B) = (0,255,0);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GRB'}) {
        ($R,$G,$B) = (0,0,255);
    } elsif ($self->{'COLOR_ORDER'} == $self->{'GBR'}) {
        ($R,$G,$B) = (255,0,0);
    }
    $self->set_color({ 'red' => $R, 'green' => $G, 'blue' => $B, 'alpha' => 255 });

    $self->polygon(
        {
            'coordinates' => [
                (270 * $hf) + $X,
                (250 * $vf) + $Y,

                (270 * $hf) + $X,
                (150 * $vf) + $Y,

                (320 * $hf) + $X,
                (150 * $vf) + $Y,

                (320 * $hf) + $X,
                (250 * $vf) + $Y,
            ],
            'filled' => TRUE,
        }
    );
    $self->circle(
        {
            'x'      => (320 * $hf) + $X,
            'y'      => (175 * $vf) + $Y,
            'radius' => 25 * $vf,
            'filled' => TRUE
        }
    );
    $self->circle(
        {
            'x'      => (320 * $hf) + $X,
            'y'      => (225 * $vf) + $Y,
            'radius' => 25 * $vf,
            'filled' => TRUE
        }
    );

    # Accelerated shadow
    $self->set_color({ 'red' => 32, 'green' => 0, 'blue' => 0, 'alpha' => 255 });
    $self->rbox(
        {
            'x'      => (478 * $hf) + $X,
            'y'      => (208 * $vf) + $Y,
            'width'  => (1230 * $hf),
            'height' => (150 * $vf),
            'radius' => 30 * $vf,
            'filled' => TRUE,
        }
    );

    # (Un)Accelerated green-yellow
    $self->rbox(
        {
            'x'        => (470 * $hf) + $X,
            'y'        => (200 * $vf) + $Y,
            'width'    => (1230 * $hf),
            'height'   => (150 * $vf),
            'radius'   => 30 * $vf,
            'filled'   => TRUE,
            'gradient' => {
                'direction' => 'vertical',
                'colors'    => {
                    'red'   => [0,0,   255, 255, 255, 0],
                    'green' => [0,255, 255, 255, 0,   0],
                    'blue'  => [0,0,   0,   0,   255, 0],
                    'alpha' => [0,255, 255, 255, 255, 0],
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
                    'x'            => (510 * $hf) + $X,
                    'y'            => (351 * $vf) + $Y,
                    'height'       => 110 * $vf,
                    'wscale'       => .9,
                    'color'        => '0101FFFF',
                    'text'         => $t,
                    'bounding_box' => TRUE,
                    'center'       => 0,
                    'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
                }
            )
        );
    }
    if ($self->{'BITS'} >= 24) {
        my $shadow = $self->ttf_print(
            {
                'bounding_box' => TRUE,
                'x'            => 0,
                'y'            => (621 * $vf) + $Y,
                'height'       => 200 * $vf,
                'wscale'       => 1,
                'color'        => ($self->{'GPU'} !~ /nouveaufb/) ? '221100A0' : '221100FF',
                'text'         => 'Graphics-Framebuffer',
                'bounding_box' => TRUE,
                'center'       => $self->{'CENTER_X'},
                'antialias'    => TRUE
            }
        );
        if ($shadow->{'pwidth'} > (1500 * $hf)) {
            $shadow->{'bounding_box'} = TRUE;
            $shadow->{'wscale'}       = int(1500 * $hf) / $shadow->{'pwidth'};
            $shadow                   = $self->ttf_print($shadow);
        }
        $shadow->{'x'} += max(1, 8 * $hf);
        $shadow->{'y'} += max(1, 8 * $vf);
        delete($shadow->{'center'});
        $self->ttf_print($shadow);
    } ## end if ($self->{'BITS'} >=...)
    my $gfb = $self->ttf_print(
        {
            'bounding_box' => TRUE,
            'x'            => 0,
            'y'            => (621 * $vf) + $Y,
            'height'       => 200 * $vf,
            'wscale'       => 1,
            'color'        => 'FFFF00FF',
            'text'         => 'Graphics-Framebuffer',
            'bounding_box' => TRUE,
            'center'       => $self->{'CENTER_X'},
            'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
        }
    );
    if ($gfb->{'pwidth'} > (1500 * $hf)) {
        $gfb->{'bounding_box'} = TRUE;
        $gfb->{'wscale'}       = int(1500 * $hf) / $gfb->{'pwidth'};
        $gfb                   = $self->ttf_print($gfb);
    }
    $self->ttf_print($gfb);

    my $rk = $self->ttf_print(
        {
            'bounding_box' => TRUE,
            'x'            => 0,
            'y'            => (632 * $vf) + $Y,
            'height'       => 50 * $vf,
            'wscale'       => 1,
            'color'        => '00EE00FF',
            'text'         => 'by Richard Kelsch',
            'bounding_box' => TRUE,
            'center'       => FALSE,
            'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
        }
    );
    $rk->{'x'} = (1710 * $hf) - $rk->{'pwidth'};
    $self->ttf_print($rk);

    $self->alpha_mode() if ($self->{'GPU'} !~ /nouveaufb/ && $self->{'ACCELERATED'}); # Nouveau totally sucks for framebuffer work, so we disable alpha

    $self->rbox(
        {
            'x'      => (188 * $hf) + $X,
            'y'      => (640 * $vf) + $Y,
            'width'  => (1580 * $hf),
            'height' => (280 * $vf),

            #                'radius' => 30 * $vf,
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
                'y'            => (785 * $vf) + $Y,
                'height'       => 118 * $vf,
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
            'y'            => (915 * $vf) + $Y,
            'height'       => 118 * $vf,
            'wscale'       => 1,
            'color'        => 'FFFFFFFF',
            'text'         => sprintf('%dx%d-%02d on %s', $self->{'XRES'}, $self->{'YRES'}, $self->{'BITS'}, $self->{'GPU'}),
            'bounding_box' => TRUE,
            'center'       => $self->{'CENTER_X'},
            'antialias'    => ($self->{'BITS'} >= 24) ? TRUE : FALSE
        }
    );
    if ($scaleit->{'pwidth'} > int(1500 * $hf)) {
        $scaleit->{'bounding_box'} = TRUE;
        $scaleit->{'wscale'}       = int(1500 * $hf) / $scaleit->{'pwidth'};
        $scaleit                   = $self->ttf_print($scaleit);
    }
    $self->ttf_print($scaleit);
    $self->_perl_logo();
    $self->normal_mode();
} ## end sub splash

1;

=head1 NAME

Graphics::Framebuffer::Splash

=head1 DESCRIPTION

See the "Graphics::Frambuffer" documentation, as methods within here are pulled into the main module

=cut

