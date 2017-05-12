#!/usr/bin/perl

use strict;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep);

my $joined = join('', @ARGV);
my $device = (exists($ENV{'DISPLAY'})) ? 1 : 0;

# $wait = $joined =~ /(\d+)/ if (scalar(@ARGV));
my $dump = ($joined =~ /dump/)   ? 1 : 0;
my $wait = ($joined =~ /nowait/) ? 0 : .75;
if ($joined =~ /(\d+)/) {
    $device = $1;
}

my $fb = Graphics::Framebuffer->new('SPLASH' => 1, 'SHOW_ERRORS' => 1, 'FB_DEVICE' => "/dev/fb$device");    # ,'SIMULATED_X'=>1280,'SIMULATED_Y'=>720);

my $xadj = $fb->{'XRES'} / 1920;
my $yadj = $fb->{'YRES'} / 1080;

$fb->cls('OFF') unless ($dump);

# $fb->or_mode();

foreach my $font (sort(keys %{ $fb->{'FONTS'} })) {
    unless ($dump) {
        $fb->cls();
        my $tprint = {
            'bounding_box' => 1,
            'face'         => $fb->{'FONTS'}->{$font}->{'font'},
            'center'       => 3,
            'text'         => $font,
            'font_path'    => $fb->{'FONTS'}->{$font}->{'path'},
            'color'        => 'FFFFFFFF',
            'height'       => 150 * $yadj,
            'antialias'    => 1
        };
        my $smprint = {
            'bounding_box' => 1,
            'text'         => $font,
            'color'        => '99FF99FF',
            'height'       => 72 * $yadj,
            'y'            => 78 * $yadj,
            'antialias'    => 1
        };
        $fb->ttf_print($fb->ttf_print($tprint));
        $fb->ttf_print($fb->ttf_print($smprint));
        print STDOUT "$font\n" if ($fb->{'XRES'} <= 320 && $device);
        if ($wait) {
            sleep $wait;
        }
    } else {
        print STDOUT "$font\n";
    }
} ## end foreach my $font (sort(keys...))

$fb->cls('ON') unless ($dump);

=head1 NAME

Available Fonts Display

=head1 DESCRIPTION

This displays (in the actual font) all of the system fonts the Graphics::Framebuffer module could find.

=head1 SYNOPSIS

 perl fonts.pl [wait time] [dump]

=head2 Example

=over 4

 perl fonts 0.75

=back

=head1 OPTIONS

=over 2

=item B<wait time> (a decimal number)

Tells the script to wait "wait time" seconds before showing the next font.  This can be fractions of a second.  The default is "0.5" seconds.

=item B<dump>

Tells the script to dump a list of the font names to STDOUT.

=back

=cut
