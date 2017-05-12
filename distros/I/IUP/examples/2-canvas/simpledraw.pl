# Canvas example

use strict;
use warnings;

use IUP ':all';
use IUP::Canvas::FileVector;
use IUP::Canvas::FileBitmap;

###global variables

my $STYLE_SIZE = 10;
my $pattern;
my $stipple;

my $IMAGE_SIZE = 100;
my $imagergba = IUP::Canvas::Bitmap->new(CD_RGBA, $IMAGE_SIZE, $IMAGE_SIZE); #XXX-FIXME segfault at this point!!!

###subroutines

sub InitGlobals {

  $pattern = IUP::Canvas::Pattern->new( [
    [CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE],
    [CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_BLUE, CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE],
    [CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_BLUE, CD_BLUE, CD_WHITE,CD_WHITE,CD_WHITE],
    [CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_BLUE, CD_BLUE, CD_BLUE, CD_WHITE,CD_WHITE],
    [CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_RED,  CD_BLUE, CD_BLUE, CD_BLUE, CD_WHITE,CD_WHITE],
    [CD_WHITE,CD_GREEN,CD_GREEN,CD_GREEN,CD_GREEN,CD_GREEN,CD_BLUE, CD_BLUE, CD_WHITE,CD_WHITE],
    [CD_WHITE,CD_WHITE,CD_GREEN,CD_GREEN,CD_GREEN,CD_GREEN,CD_GREEN,CD_BLUE, CD_WHITE,CD_WHITE],
    [CD_WHITE,CD_WHITE,CD_WHITE,CD_GREEN,CD_GREEN,CD_GREEN,CD_GREEN,CD_GREEN,CD_WHITE,CD_WHITE],  
    [CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE],
    [CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE,CD_WHITE],
  ] );
  
  $stipple = IUP::Canvas::Stipple->new($STYLE_SIZE, $STYLE_SIZE);
  #initialize the stipple buffer with cross pattern
  for my $l (0..$STYLE_SIZE-1) {
    for my $c (0..$STYLE_SIZE-1) {
      $stipple->Pixel($c, $l, (($c % 4)==0) ? 1 : 0);
    }
  }

  #initialize the alpha image buffer with a degrade from transparent to opaque
  for my $l (0..$IMAGE_SIZE-1) {
    for my $c (0..$IMAGE_SIZE-1) {
      my $alpha = ($c*255)/($IMAGE_SIZE-1);
      if ($l==0 || $l==$IMAGE_SIZE-1 || $c==0 || $c==$IMAGE_SIZE-1) {
        $imagergba->Pixel($c, $l, 0, 0, 0, $alpha);
      }
      else {
        if ($l > $IMAGE_SIZE/2) {
          $imagergba->Pixel($c, $l, 95, 143, 95, $alpha);
        }
        else {
          $imagergba->Pixel($c, $l, 255, 95, 95, $alpha);
        }
      }
    }
  }
}

sub SimpleDraw {
  my $canvas = shift;
  my ($x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3);
  
  # Get size in pixels to be used for computing coordinates.
  my ($w, $h, $w_mm, $h_mm) = $canvas->cdGetSize();

  # Clear the background to be white
  $canvas->cdBackground(CD_WHITE);
  $canvas->cdClear();

  # Draw a reactangle and a polyline at the bottom-left area,
  # using a thick line with transparency.
  # Notice that transparency is only supported in a few drivers,
  # and line join is not supported in the IMAGERGB driver.
  $canvas->cdLineWidth(3);
  $canvas->cdLineStyle(CD_CONTINUOUS);
  $canvas->cdForeground($canvas->cdEncodeAlpha(CD_DARK_MAGENTA, 128));
  $canvas->cdRect(100, 200, 100, 200);
  $canvas->cdBegin(CD_OPEN_LINES);
  $canvas->cdVertex(300, 250);
  $canvas->cdVertex(320, 270);
  $canvas->cdVertex(350, 260);
  $canvas->cdVertex(340, 200);
  $canvas->cdVertex(310, 210);
  $canvas->cdEnd();

  # Draw the red diagonal line with a custom line style.
  # Notice that line styles are not supported in the IMAGERGB driver.
  $canvas->cdForeground(CD_RED);
  $canvas->cdLineWidth(3);
  my $dashes = [20, 15, 5, 5];
  $canvas->cdLineStyleDashes($dashes);
  $canvas->cdLineStyle(CD_CUSTOM);
  $canvas->cdLine(0, 0, $w-1, $h-1);

  # Draw the blue diagonal line with a pre-defined line style.
  # Notice that the pre-defined line style is dependent on the driver.
  $canvas->cdForeground(CD_BLUE);
  $canvas->cdLineWidth(10);
  $canvas->cdLineStyle(CD_DOTTED);
  $canvas->cdLine(0, $h-1, $w-1, 0);

  # Reset line style and width
  $canvas->cdLineStyle(CD_CONTINUOUS);
  $canvas->cdLineWidth(1);

  # Draw an arc at bottom-left, and a sector at bottom-right.
  # Notice that counter-clockwise orientation of both.
  $canvas->cdInteriorStyle(CD_SOLID);
  $canvas->cdForeground(CD_MAGENTA);
  $canvas->cdSector($w-100, 100, 100, 100, 50, 180);
  $canvas->cdForeground(CD_RED);
  $canvas->cdArc(100, 100, 100, 100, 50, 180);

  # Draw a solid filled rectangle at center.
  $canvas->cdForeground(CD_YELLOW);
  $canvas->cdBox($w/2 - 100, $w/2 + 100, $h/2 - 100, $h/2 + 100);

  # Prepare font for text.
  $canvas->cdTextAlignment(CD_CENTER);
  $canvas->cdTextOrientation(70);
  $canvas->cdFont("Times", CD_BOLD, 24);

  # Draw text at center, with orientation,
  # and draw its bounding box.
  # Notice that in some drivers the bounding box is not precise.
  ($x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3) = $canvas->cdGetTextBounds($w/2, $h/2, "cdMin Draw (згн)");
  $canvas->cdForeground(CD_RED);
  $canvas->cdBegin(CD_CLOSED_LINES);
  $canvas->cdVertex($x0, $y0);
  $canvas->cdVertex($x1, $y1);
  $canvas->cdVertex($x2, $y2);
  $canvas->cdVertex($x3, $y3);
  $canvas->cdEnd();
  $canvas->cdForeground(CD_BLUE);
  $canvas->cdText($w/2, $h/2, "cdMin Draw (згн)");

  # Prepare World Coordinates
  $canvas->wdViewport(0,$w-1,0,$h-1);
  if ($w>$h) {
      $canvas->wdWindow(0,$w/$h,0,1);
  }
  else {
      $canvas->wdWindow(0,1,0,$h/$w);
  }

  # Draw a filled blue rectangle in WC
  $canvas->wdBox(0.20, 0.30, 0.40, 0.50);
  $canvas->cdForeground(CD_RED);

  # Draw the diagonal of that rectangle in WC
  $canvas->wdLine(0.20, 0.40, 0.30, 0.50);

  # Prepare Vector Text in WC.
  $canvas->wdVectorCharSize(0.07);

  # Draw vector text, and draw its bounding box.
  # We also use this text to show when we are using a contextplus driver.
  $canvas->cdForeground(CD_RED);
  my $drect;
  my $contextplus; #XXX-TODO
  if ($contextplus) {
      ($x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3) = $canvas->wdGetVectorTextBounds("WDj-Plus", 0.25, 0.35);
  }
  else {
      ($x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3) = $canvas->wdGetVectorTextBounds("WDj", 0.25, 0.35);
  }
  $canvas->cdBegin(CD_CLOSED_LINES);
  $canvas->wdVertex($x0, $y0);
  $canvas->wdVertex($x1, $y1);
  $canvas->wdVertex($x2, $y2);
  $canvas->wdVertex($x3, $y3);
  $canvas->cdEnd();
  $canvas->cdLineWidth(2);
  $canvas->cdLineStyle(CD_CONTINUOUS);
  if ($contextplus) {
      $canvas->wdVectorText(0.25, 0.35, "WDj-Plus");
  }
  else {
      $canvas->wdVectorText(0.25, 0.35, "WDj");
  }

  # Reset line width
  $canvas->cdLineWidth(1);

  # Draw a filled path at center-right (looks like a weird fish).
  # Notice that in PDF the arc is necessarily a circle arc, and not an ellipse.
  $canvas->cdForeground(CD_GREEN);
  $canvas->cdBegin(CD_PATH);
  $canvas->cdPathSet(CD_PATH_MOVETO);
  $canvas->cdVertex($w/2 + 200, $h/2);
  $canvas->cdPathSet(CD_PATH_LINETO);
  $canvas->cdVertex($w/2 + 230, $h/2 + 50);
  $canvas->cdPathSet(CD_PATH_LINETO);
  $canvas->cdVertex($w/2 + 250, $h/2 + 50);
  $canvas->cdPathSet(CD_PATH_CURVETO);
  $canvas->cdVertex($w/2+150+150, $h/2+200-50); #control point for start
  $canvas->cdVertex($w/2+150+180, $h/2+250-50); #control point for end
  $canvas->cdVertex($w/2+150+180, $h/2+200-50); #end point
  $canvas->cdPathSet(CD_PATH_CURVETO);
  $canvas->cdVertex($w/2+150+180, $h/2+150-50);
  $canvas->cdVertex($w/2+150+150, $h/2+100-50);
  $canvas->cdVertex($w/2+150+300, $h/2+100-50);
  $canvas->cdPathSet(CD_PATH_LINETO);
  $canvas->cdVertex($w/2+150+300, $h/2-50);
  $canvas->cdPathSet(CD_PATH_ARC);
  $canvas->cdVertex($w/2+300, $h/2); #center
  $canvas->cdVertex(200, 100); #width, height
  $canvas->cdVertex(-30*1000, -170*1000); #start angle, end angle (degrees / 1000);
  $canvas->cdPathSet(CD_PATH_FILL);
  $canvas->cdEnd();

  # Draw 3 pixels at center left.
  $canvas->cdPixel(10, $h/2+0, CD_RED);
  $canvas->cdPixel(11, $h/2+1, CD_GREEN);
  $canvas->cdPixel(12, $h/2+2, CD_BLUE);

  # Draw 4 mark types, distributed near each corner.
  $canvas->cdForeground(CD_RED);
  $canvas->cdMarkSize(30);
  $canvas->cdMarkType(CD_PLUS);
  $canvas->cdMark(200, 200);
  $canvas->cdMarkType(CD_CIRCLE);
  $canvas->cdMark($w - 200, 200);
  $canvas->cdMarkType(CD_HOLLOW_CIRCLE);
  $canvas->cdMark(200, $h - 200);
  $canvas->cdMarkType(CD_DIAMOND);
  $canvas->cdMark($w - 200, $h - 200);

  # Draw all the line style possibilities at bottom.
  # Notice that they have some small differences between drivers.
  $canvas->cdLineWidth(1);
  $canvas->cdLineStyle(CD_CONTINUOUS);
  $canvas->cdLine(0, 10, $w, 10);
  $canvas->cdLineStyle(CD_DASHED);
  $canvas->cdLine(0, 20, $w, 20);
  $canvas->cdLineStyle(CD_DOTTED);
  $canvas->cdLine(0, 30, $w, 30);
  $canvas->cdLineStyle(CD_DASH_DOT);
  $canvas->cdLine(0, 40, $w, 40);
  $canvas->cdLineStyle(CD_DASH_DOT_DOT);
  $canvas->cdLine(0, 50, $w, 50);

  # Draw all the hatch style possibilities in the top-left corner.
  # Notice that they have some small differences between drivers.
  $canvas->cdHatch(CD_VERTICAL);
  $canvas->cdBox(0, 50, $h - 60, $h);
  $canvas->cdHatch(CD_FDIAGONAL);
  $canvas->cdBox(50, 100, $h - 60, $h);
  $canvas->cdHatch(CD_BDIAGONAL);
  $canvas->cdBox(100, 150, $h - 60, $h);
  $canvas->cdHatch(CD_CROSS);
  $canvas->cdBox(150, 200, $h - 60, $h);
  $canvas->cdHatch(CD_HORIZONTAL);
  $canvas->cdBox(200, 250, $h - 60, $h);
  $canvas->cdHatch(CD_DIAGCROSS);
  $canvas->cdBox(250, 300, $h - 60, $h);

  # Draw 4 regions, in diamond shape,
  # at top, bottom, left, right,
  # using different interior styles.

  # At top, not filled polygon, notice that the last line style is used.
  $canvas->cdBegin(CD_CLOSED_LINES);
  $canvas->cdVertex($w/2, $h - 100);
  $canvas->cdVertex($w/2 + 50, $h - 150);
  $canvas->cdVertex($w/2, $h - 200);
  $canvas->cdVertex($w/2 - 50, $h - 150);
  $canvas->cdEnd();

  # At left, hatch filled polygon
  $canvas->cdHatch(CD_DIAGCROSS);
  $canvas->cdBegin(CD_FILL);
  $canvas->cdVertex(100, $h/2);
  $canvas->cdVertex(150, $h/2 + 50);
  $canvas->cdVertex(200, $h/2);
  $canvas->cdVertex(150, $h/2 - 50);
  $canvas->cdEnd();

  # At right, pattern filled polygon
  $canvas->cdPattern($pattern);
  $canvas->cdBegin(CD_FILL);
  $canvas->cdVertex($w - 100, $h/2);
  $canvas->cdVertex($w - 150, $h/2 + 50);
  $canvas->cdVertex($w - 200, $h/2);
  $canvas->cdVertex($w - 150, $h/2 - 50);
  $canvas->cdEnd();

  # At bottom, stipple filled polygon
  $canvas->cdStipple($stipple);
  $canvas->cdBegin(CD_FILL);
  $canvas->cdVertex($w/2, 100);
  $canvas->cdVertex($w/2 + 50, 150);
  $canvas->cdVertex($w/2, 200);
  $canvas->cdVertex($w/2 - 50, 150);
  $canvas->cdEnd();

  # Draw two beziers at bottom-left
  $canvas->cdBegin(CD_BEZIER);
  $canvas->cdVertex(100, 100);
  $canvas->cdVertex(150, 200);
  $canvas->cdVertex(180, 250);
  $canvas->cdVertex(180, 200);
  $canvas->cdVertex(180, 150);
  $canvas->cdVertex(150, 100);
  $canvas->cdVertex(300, 100);
  $canvas->cdEnd();

  # Draw the image on the top-right corner but increasing its actual size, and uses its full area
  $canvas->cdPutBitmap($imagergba, $w - 400, $h - 310, 3*$IMAGE_SIZE, 3*$IMAGE_SIZE);

  # Adds a new page, or
  # flushes the file, or
  # flushes the screen, or
  # swap the double buffer.
  $canvas->cdFlush();
}

###main program

my $canvas;
InitGlobals();

warn "Saving ...\n";
$canvas = IUP::Canvas::FileVector->new( format=>"SVG", filename=>"tmp-testoutput.svg", width=>270.933, height=>198.543, dpi=>120 );
SimpleDraw($canvas);
$canvas->cdKillCanvas(); 
undef $canvas; #XXX-FIXME why we need 'undef $canvas' and '$canvas->cdKillCanvas()' is not enough?

warn "Saving ...\n";
$canvas = IUP::Canvas::FileVector->new( format=>"EMF", filename=>"tmp-testoutput.emf", width=>1280, height=>938 );
SimpleDraw($canvas);
$canvas->cdKillCanvas;
undef $canvas;

warn "Saving ...\n";
$canvas = IUP::Canvas::FileBitmap->new( width=>1280, height=>938, dpi=>120 );
SimpleDraw($canvas);
$canvas->cdDumpBitmap("tmp-testoutput.jpg", "JPEG");
$canvas->cdDumpBitmap("tmp-testoutput.png", "PNG");
$canvas->cdKillCanvas;
undef $canvas;

warn "Done!\n";