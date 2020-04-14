#!/usr/bin/env perl

use strict;

use Graphics::Framebuffer;
use Getopt::Long;
use Data::Dumper;

our $RUNNING = 1;

my $new_x;
my $new_y;
my $color = 'FFFFFFFF';
my $ampm  = 0;

GetOptions(
    'x=i'     => \$new_x,
    'y=i'     => \$new_y,
    'color=s' => \$color,
    'ampm'    => \$ampm,
);

my $FB = (defined($new_x) || defined($new_y)) ?
  Graphics::Framebuffer->new('SPLASH' => 0, 'SIMULATED_X' => $new_x, 'SIMULATED_Y' => $new_y) :
  Graphics::Framebuffer->new('SPLASH' => 0);

$SIG{'QUIT'} = $SIG{'INT'} = $SIG{'KILL'} = $SIG{'HUP'} = $SIG{'TERM'} = sub { $RUNNING = 0; $FB->text_mode(); exec('reset'); };

$FB->cls('OFF'); # Turn off the console cursor

# You can optionally set graphics mode here, but remember to turn on text mode
# before exiting.

$FB->graphics_mode(); # Shuts off all text and cursors.

# Gathers information on the screen for you to use as global information
# {
#    'width'          => pixel width of physical screen,
#    'height'         => pixel height of physical screen,
#    'bits_per_pixel' => bits per pixel (16, 24, or 32),
#    'bytes_per_line' => Number of bytes per scan line,
#    'top_clip'       => top edge of clipping rectangle (Y),
#    'left_clip'      => left edge of clipping rectangle (X),
#    'bottom_clip'    => bottom edge of clipping rectangle (YY),
#    'right_clip'     => right edge of clipping rectangle (XX),
#    'width_clip'     => width of clipping rectangle,
#    'height_clip'    => height of clipping rectangle,
#    'color_order'    => RGB, BGR, etc,
# }
my $screen_info = $FB->screen_dimensions();

my $x_adj = $screen_info->{'width'}  / 1920;
my $y_adj = $screen_info->{'height'} / 1080;

my $font = $FB->get_font_list('^DejaVuSansMono$');

while($RUNNING) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $t;
    if ($ampm) {
        if ($hour > 12) {
            $t = sprintf('%02d:%02d:%02d pm',$hour-12,$min,$sec);
        } else {
            $t = sprintf('%02d:%02d:%02d am',$hour,$min,$sec);
        }
    } else {
        $t = sprintf('%02d:%02d:%02d',$hour,$min,$sec);
    }
    my $tp = {
        'bounding_box' => 1,
        'face'         => $font->{'face'},
        'font_path'    => $font->{'font_path'},
        'text'         => $t,
        'color'        => ($color =~ /random/i) ? sprintf('%02X%02X%02XFF',int(128 + rand(128)), int(128 + rand(128)), int(128 + rand(128))) : $color,
        'height'       => 200 * $y_adj,
        'x'            => 10,
        'y'            => 200,
        'antialias'    => 1,
    };
    $FB->normal_mode();
    my $bbox = $FB->ttf_print($tp);
    my $width = $screen_info->{'width'} - $bbox->{'pwidth'};
    my $height = ($screen_info->{'height'} - $bbox->{'pheight'}) - (210 * $y_adj);
    $bbox->{'x'} = int(rand($width));
    $bbox->{'y'} = int(rand($height)) + (210 * $y_adj);
    $FB->ttf_print($bbox);
    sleep 2;
    $FB->xor_mode();
    $FB->ttf_print($bbox);
}

$FB->text_mode();  # Turn text and cursor back on.  You MUST do this if
                   # graphics mode was set.
$FB->cls('ON');    # Turn the console cursor back on
exit(0);

__END__

=head1 NAME

Screen Saver

=head1 SYNOPIS

perl screensaver.pl [options]

=head1 DESCRIPTION

Simple screen saver that prints the time at random locations on the screen

=head1 OPTIONS

=head2 --B<color>="FFFFFFFF" or --B<color>="random"

Sets the font color in hex.

  RRGGBBAA format

Also can choose a random color with "random".

=head2 --B<ampm>

By default it prints in 24 hour format.  This option chooses 12 hour am/pm output instead.

=cut
