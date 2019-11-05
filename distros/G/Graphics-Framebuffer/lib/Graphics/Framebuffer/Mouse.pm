package Graphics::Framebuffer::Mouse;

use strict;
no strict 'vars';    # We have to map a variable as the screen.  So strict is going to whine about what we do with it.
no warnings;         # We have to be as quiet as possible

use constant {
    TRUE  => 1,
    FALSE => 0,
};

use Time::HiRes qw(alarm);
use List::Util qw(min max);

BEGIN {
    require Exporter;
    our @ISA = qw( Exporter );
    our $VERSION = '0.03';
    our @EXPORT = qw( initialize_mouse poll_mouse get_mouse set_mouse );
    our @EXPORT_OK = qw();
}

sub initialize_mouse {
    my $self = shift;
    my $mode = shift || 'ON';

    if ($mode =~ /1|ON|ENABLE|SHOW/i) {
        $self->set_mouse({'x' => int($self->{'XRES'} / 2), 'y' => int($self->{'YRES'} / 2)});
        my $save = $self->{'DRAW_MODE'};
        $self->{'DRAW_MODE'} = $self->{'XOR_MODE'};
        $self->plot(
            {
                'x'          => $self->{'MOUSE_X'},
                'y'          => $self->{'MOUSE_Y'},
                'pixel_size' => 5,
            }
        );
        $self->{'DRAW_MODE'} = $save;
        $SIG{'ALRM'} = sub {
            alarm(0);
            $self->poll_mouse();
            alarm(.01);
        };
        alarm(.01);
    } else {
        alarm(0);
        my $save = $self->{'DRAW_MODE'};
        $self->{'DRAW_MODE'} = $self->{'XOR_MODE'};
        $self->plot(
            {
                'x'          => $self->{'MOUSE_X'},
                'y'          => $self->{'MOUSE_Y'},
                'pixel_size' => 5,
            }
        );
        $self->{'DRAW_MODE'} = $save;
    }
}

sub poll_mouse {
    my $self      = shift;
    if (open(my $m,'<','/dev/input/mice')) {
        binmode($m);
        my $mouse = '';
        if (sysread($m,$mouse,3)) {
            my ($b,$x,$y) = unpack('c3',$mouse);
            $self->{'MOUSE_BUTTON'} = $b;
            if ($x != 0 && $y != 0) {
                my $old_mode = $self->{'DRAW_MODE'};
                $self->{'DRAW_MODE'} = $self->{'XOR_MODE'};
                $self->plot(
                    {
                        'x'          => $self->{'MOUSE_X'},
                        'y'          => $self->{'MOUSE_Y'},
                        'pixel_size' => 5,
                    }
                );
                $self->{'MOUSE_X'} += $x;
                $self->{'MOUSE_Y'} -= $y; # Mouse is in reverse
                $self->{'MOUSE_X'}  = min(max(0,$self->{'MOUSE_X'}),$self->{'XRES'});
                $self->{'MOUSE_Y'}  = min(max(0,$self->{'MOUSE_Y'}),$self->{'YRES'});
                $self->plot(
                    {
                        'x'          => $self->{'MOUSE_X'},
                        'y'          => $self->{'MOUSE_Y'},
                        'pixel_size' => 5,
                    }
                );
                $self->{'DRAW_MODE'} = $old_mode;
            }
        }
        close($m);
    } elsif ($self->{'SHOW_ERRORS'}) {
        print STDERR "Could not open mouse for polling\n";
    }
}

sub get_mouse {
    my $self = shift;
    if (wantarray) {
        return($self->{'MOUSE_BUTTON'},$self->{'MOUSE_X'},$self->{'MOUSE_Y'});
    } else {
        return(
            {
                'button' => $self->{'MOUSE_BUTTON'},
                'x'      => $self->{'MOUSE_X'},
                'y'      => $self->{'MOUSE_Y'},
            }
        );
    }
}

sub set_mouse {
    my $self   = shift;
    my $params = shift;

    return unless(defined($params) && exists($params->{'x'}) && exists($params->{'y'}));

    $self->{'MOUSE_X'} = $params->{'x'};
    $self->{'MOUSE_Y'} = $params->{'y'};
}

1;

=head1 NAME

Graphics::Framebuffer::Mouse

=head1 DESCRIPTION

See the "Graphics::Frambuffer" documentation, as methods within here are pulled into the main module

=cut

