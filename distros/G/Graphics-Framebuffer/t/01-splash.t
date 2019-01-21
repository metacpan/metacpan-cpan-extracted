#!perl -T

use strict;
use Test::Most tests => 1;

BEGIN {
    $^W = 0;
}

unless (defined($ENV{'DISPLAY'})) {
    $ENV{'PATH'} .= ':/usr/share/fonts';
    eval {
        use Graphics::Framebuffer;

        my ($PF,$F) = Graphics::Framebuffer->new('DOUBLE_BUFFER' => 16, 'RESET' => 0);
        my $DB = 1;
        isa_ok($PF,'Graphics::Framebuffer');
        if (defined($PF)) {
            my $scr = $PF->screen_dimensions();
            if ($scr->{'bits_per_pixel'} != 16) {
                $DB = 0;
                $F  = $PF;
            }
            my $xm  = $scr->{'height'} / 1080;
            $F->cls();
            $F->ttf_print($F->ttf_print({
                'height'       => 134 * $xm,
                'wscale'       => 1.05,         # Scales the width.  1 is normal
                'color'        => '222244FF', # Hex value of color 00-FF (RRGGBBAA)
                'text'         => 'Hey, This Works!',
                'bounding_box' => 1,
                'center'       => CENTER_XY,
                'antialias'    => 1
            }));
            $F->ttf_print($F->ttf_print({
                'height'       => 130 * $xm,
                'wscale'       => 1,         # Scales the width.  1 is normal
                'color'        => 'FFFFFFFF', # Hex value of color 00-FF (RRGGBBAA)
                'text'         => 'Hey, This Works!',
                'bounding_box' => 1,
                'center'       => CENTER_XY,
                'antialias'    => 1
            }));
            $PF->blit_flip($F) if ($DB);
            sleep 2;
            $F->cls();
        } else {
            diag("If Testing Failed, it's because you are either:\n\n1> Are installing from within X-Windows\n2> You don't have a Framebuffer to test with (/dev/fb0)\n3> Or your a CPAN tester that's not reading the instructions, and improperly marking this module failed.\n");
        }
    };
    if ($@) {
        if ($@ =~ /Mmap/i) {
            diag("\n\n" . '='x79 . qq{

Could not Memory Map a framebuffer.

This happens if you do not have a framebuffer device/driver, or you do not
have permission to access the framebuffer, or you are testing from within
X-Windows (you need to test and use from the text console).

} . '='x79 . "\n$@\n");
        } else {
            diag("\n\nCould not create an object\n$@");
        }
    }
} else {
    diag("\n\nYou are installing from within X-Windows!  This presents problems.  Go to a REAL console.\n\nIf you are a CPAN tester, then please test according to the documentation.\n\n");
    ok(1,'In X-Windows (GRRR).  Skipping tests, but not pronouncing this a failure.');
}
