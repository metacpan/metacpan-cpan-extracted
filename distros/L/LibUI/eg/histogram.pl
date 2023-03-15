use strict;
use warnings;
use lib '../lib';
use LibUI ':all';
use LibUI::Window;
use LibUI::Label;
use LibUI::Area;
use LibUI::HBox;
use LibUI::VBox;
use LibUI::Spinbox;
use LibUI::ColorButton;
use LibUI::Window::ResizeEdge;
use LibUI::Draw::Brush;
use LibUI::Draw::Path;
use LibUI::Draw;
use LibUI::Draw::Matrix;
#
my $currentPoint = -1;
my $dps          = 10;
my ( $window, $histogram, $colorButton, @datapoints );
#
# some metrics
sub xoffLeft()     {20}    # histogram margins
sub yoffTop ()     {20}
sub xoffRight ()   {20}
sub yoffBottom ()  {20}
sub pointRadius () {5}

# helper to quickly set a brush color
sub setSolidBrush {
    my ( $color, $alpha ) = @_;
    my $component;
    my $brush;
    #
    $brush->{type} = LibUI::Draw::BrushType::Solid();
    $component     = ( ( $color >> 16 ) & 0xFF );
    $brush->{R}    = ($component) / 255;
    $component     = ( ( $color >> 8 ) & 0xFF );
    $brush->{G}    = ($component) / 255;
    $component     = ( $color & 0xFF );
    $brush->{B}    = ($component) / 255;
    $brush->{A}    = $alpha;
    $brush;
}

# and some colors
# names and values from https://msdn.microsoft.com/en-us/library/windows/desktop/dd370907%28v=vs.85%29.aspx
sub White()      {0xFFFFFF}
sub Black()      {0x000000}
sub DodgerBlue() {0x1E90FF}
#
sub pointLocations {
    my ( $width, $height ) = @_;
    my $xincr = $width / ( $dps - 1 );    # 10 - 1 to make the last point be at the end
    my $yincr = $height / 100;
    my ( $xs, $ys );
    my $n = 0;
    for ( 0 .. ( $dps - 1 ) ) {
        $n = $datapoints[$_]->value();    # get the value of the point

        # because y=0 is the top but n=0 is the bottom, we need to flip
        $n        = 100 - $n;
        $xs->[$_] = $xincr * $_;
        $ys->[$_] = $yincr * $n;
    }
    ( $xs, $ys );
}

sub constructGraph {
    my ( $width, $height, $extend ) = @_;
    my ( $xs, $ys ) = pointLocations( $width, $height );
    my $path = LibUI::Draw::Path->new( LibUI::Draw::FillMode::Winding() );
    $path->newFigure( $xs->[0], $ys->[0] );
    $path->lineTo( $xs->[$_], $ys->[$_] ) for 1 .. ( $dps - 1 );
    if ($extend) {
        $path->lineTo( $width, $height );
        $path->lineTo( 0,      $height );
        $path->closeFigure;
    }
    $path->end;
    return $path;
}

sub graphSize {
    my ( $clientWidth, $clientHeight ) = @_;
    return ( $clientWidth - xoffLeft - xoffRight, $clientHeight - yoffTop - yoffBottom );
}

sub handlerDraw {    #(uiAreaHandler *a, uiArea *area, uiAreaDrawParams *p)
    my ( $a, $area, $p ) = @_;

    # fill the are with white
    my $brush = setSolidBrush( White, 1.0 );
    my $path  = LibUI::Draw::Path->new( LibUI::Draw::FillMode::Winding() );
    $path->addRectangle( 0, 0, $p->{width}, $p->{height} );
    $path->end;
    LibUI::Draw::fill( $p->{context}, $path, $brush );
    $path->free;

    # figure out dimensions
    my ( $graphWidth, $graphHeight ) = graphSize( $p->{width}, $p->{height} );
    my $sp = {    # stroke params
        cap        => LibUI::Draw::LineCap::Flat(),
        join       => LibUI::Draw::LineJoin::Miter(),
        thickness  => 2,
        miterLimit => 10                                # uiDrawDefaultMiterLimit;
    };

    # draw the axes
    $brush = setSolidBrush( Black, 1.0 );
    $path  = LibUI::Draw::Path->new( LibUI::Draw::FillMode::Winding() );
    $path->newFigure( xoffLeft, yoffTop );
    $path->lineTo( xoffLeft,               yoffTop + $graphHeight );
    $path->lineTo( xoffLeft + $graphWidth, yoffTop + $graphHeight );
    $path->end;
    LibUI::Draw::stroke( $p->{context}, $path, $brush, $sp );
    $path->free;

    # now transform the coordinate space so (0, 0) is the top-left corner of the graph
    my $m;    # TODO: I hate this. Should identity() create a matrix?
    LibUI::Draw::Matrix::setIdentity($m);
    LibUI::Draw::Matrix::translate( $m, xoffLeft, yoffTop );
    LibUI::Draw::transform( $p->{context}, $m );

    # now get the color for the graph itself and set up the brush
    # we set brush alpha below to different values for the fill and stroke
    ( $brush->{R}, $brush->{G}, $brush->{B}, my $graphA ) = $colorButton->color;
    $brush->{type} = LibUI::Draw::BrushType::Solid();

    # now create the fill for the graph below the graph line
    $path = constructGraph( $graphWidth, $graphHeight, 1 );
    $brush->{A} = $graphA / 2;
    LibUI::Draw::fill( $p->{context}, $path, $brush );
    $path->free;

    # now draw the histogram line
    $path = constructGraph( $graphWidth, $graphHeight, 0 );
    $brush->{A} = $graphA;
    LibUI::Draw::stroke( $p->{context}, $path, $brush, $sp );
    $path->free;

    # now draw the point being hovered over
    if ( $currentPoint != -1 ) {
        my ( $xs, $ys ) = pointLocations( $graphWidth, $graphHeight );
        $path = LibUI::Draw::Path->new( LibUI::Draw::FillMode::Winding() );
        $path->newFigureWithArc(
            $xs->[$currentPoint], $ys->[$currentPoint], pointRadius, 0, 6.23,    # TODO: pi
            0
        );
        $path->end;

        # use the same brush as for the histogram lines
        LibUI::Draw::fill( $p->{context}, $path, $brush );
        $path->free;
    }
}

sub inPoint {
    my ( $x, $y, $xtest, $ytest ) = @_;

    # TODO switch to using a matrix
    $x -= xoffLeft;
    $y -= yoffTop;
    return ( $x >= $xtest - pointRadius ) &&
        ( $x <= $xtest + pointRadius )    &&
        ( $y >= $ytest - pointRadius )    &&
        ( $y <= $ytest + pointRadius );
}

sub handlerMouseEvent {
    my ( $a, $area, $e ) = @_;

    # (uiAreaHandler *a, uiArea *area, uiAreaMouseEvent *e)
    my ( $graphWidth, $graphHeight ) = graphSize( $e->{width}, $e->{height} );
    my ( $xs,         $ys )          = pointLocations( $graphWidth, $graphHeight );
    $currentPoint = -1;
    for my $i ( 0 .. ( $dps - 1 ) ) {
        if ( inPoint( $e->{x}, $e->{y}, $xs->[$i], $ys->[$i] ) ) {
            $currentPoint = $i;
            last;
        }
    }

    # TODO only redraw the relevant area
    $histogram->queueRedrawAll;
}

sub handlerMouseCrossed {    #(uiAreaHandler *ah, uiArea *a, int left)

    # do nothing
}

sub handlerDragBroken {    #(uiAreaHandler *ah, uiArea *a)

    # do nothing
}

sub handlerKeyEvent {    #(uiAreaHandler *ah, uiArea *a, uiAreaKeyEvent *e)

    # reject all keys
    return 0;
}

sub onDatapointChanged {

    #(uiSpinbox *s, void *data)
    $histogram->queueRedrawAll;
}

sub onColorChanged {

    #(uiColorButton *b, void *data)
    $histogram->queueRedrawAll;
}
###
Init() && die;
$window = LibUI::Window->new( 'LibUI.pm - Histogram Example', 640, 480, 1 );
$window->setMargined(1);
#
my $hbox = LibUI::HBox->new;
$hbox->setPadded(1);
$window->setChild($hbox);
#
my $vbox = LibUI::VBox->new;
$vbox->setPadded(1);
$hbox->append( $vbox, 0 );
#
for ( 0 .. ( $dps - 1 ) ) {
    $datapoints[$_] = LibUI::Spinbox->new( 0, 100 );
    $datapoints[$_]->setValue( rand() * 101 );
    $datapoints[$_]->onChanged( \&onDatapointChanged, undef );
    $vbox->append( $datapoints[$_], 0 );
}
$colorButton = LibUI::ColorButton->new;

# TODO: inline these
my $brush = setSolidBrush( DodgerBlue, 1.0 );
$colorButton->setColor( $brush->{R}, $brush->{G}, $brush->{B}, $brush->{A} );
$colorButton->onChanged( \&onColorChanged, undef );
$vbox->append( $colorButton, 0 );
#
$histogram = LibUI::Area->new(
    {   draw         => \&handlerDraw,
        mouseEvent   => \&handlerMouseEvent,
        mouseCrossed => \&handlerMouseCrossed,
        dragBroken   => \&handlerDragBroken,
        keyEvent     => \&handlerKeyEvent
    }
);
$hbox->append( $histogram, 1 );
#
$window->onClosing(
    sub {
        Quit();
        return 1;
    },
    undef
);
$window->setMargined(1);
$window->show;
Main();
