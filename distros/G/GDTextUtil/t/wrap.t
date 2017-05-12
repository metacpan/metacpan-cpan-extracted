# $Id: wrap.t,v 1.14 2003/02/20 12:23:32 mgjv Exp $

use lib ".", "..";
BEGIN { require "t/lib.pl" }

use Test::More tests => 14;
use GD;
BEGIN { use_ok "GD::Text::Wrap" };

$text = <<EOSTR;
Lorem ipsum dolor sit amet, consectetuer adipiscing elit, 
sed diam nonummy nibh euismod tincidunt ut laoreet dolore 
magna aliquam erat volutpat.
EOSTR

# Create a GD:Image object
$gd = GD::Image->new(170,150);
ok (defined $gd, "GD::Image object");

# Allocate colours
$gd->colorAllocate(255,255,255);
$gd->colorAllocate(  0,  0,  0);
is($gd->colorsTotal,2, "color allocation");

# Create a GD::Text::Wrap object
$wp = GD::Text::Wrap->new($gd, text => $text);
ok ($wp, "GD::Text::Wrap object");

$wp->set(align => 'left', width => 130);

# Get the bounding box
@bb = $wp->get_bounds(20,10);
is ("@bb", "20 10 150 128", "bounding box");

# Draw, and check that the result is the same
@bb2 = $wp->draw(20,10);
is("@bb", "@bb2", "drawing bounding box");

$wp->set(align => 'left');
@bb2 = $wp->draw(20,10);
is ("@bb", "@bb2", "left align");

$wp->set(align => 'justified');
@bb2 = $wp->draw(20,10);
is ("@bb", "@bb2", "justified");

$wp->set(align => 'right');
@bb2 = $wp->draw(20,10);
is ("@bb", "@bb2", "right align");

@bb = "20 10 150 143";
$wp->set(preserve_nl => 1);
@bb2 = $wp->draw(20,10);
is ("@bb", "@bb2", "preserve_nl");
$wp->set(preserve_nl => 0);

SKIP:
{
    skip "No TTF Support", 3 unless ($wp->can_do_ttf);

    $rc = $wp->set_font('Dustismo_Sans', 10);
    ok ($rc, "ttf font set");

    skip "Some TTF tests disabled: Freetype inconsistent", 2;

    # Get the bounding box
    @bb = $wp->get_bounds(20,10);
    ok (aeq(\@bb, [qw'20 10 150 113'], 1), "ttf bounding box")
	or diag("bb = @bb");

    @bb2 = $wp->draw(20,10);
    ok (aeq(\@bb, \@bb2, 0), "ttf drawing")
	or diag("bb2 = @bb2");
}

ok (1, "end");

__END__
#Only here to test the test.
open(GD, '>/tmp/wrap.png') or die $!;
binmode GD;
print GD $gd->png();
close GD;

