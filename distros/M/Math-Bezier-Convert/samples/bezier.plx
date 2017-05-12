#!/usr/bin/perl

use strict;

use lib '/program';
use Tk;
use Math::Bezier::Convert ':all';

my ($draw_line, $draw_quad, $point_line, $point_quad)=(1,1,0,0);

my $mw=MainWindow->new;
$mw->geometry('640x480');
$mw->title('Cubic bezier test');
my $board=$mw->Scrolled('Canvas', -scrollbars=>'osoe', -background=>'white')->pack( -side => 'bottom', -expand=>1, -fill=> 'both');
my $fr = $mw->Frame(-relief=> 'flat')->pack(-fill=>'x');
$fr->Checkbutton(-text=> 'Draw with polyline', -variable => \$draw_line, -command=> \&cubic, -indicatoron=>0)
   ->grid(
	  $fr->Checkbutton(-text=> 'Plot control points', -variable => \$point_line, -command=> \&cubic),
	  $fr->Label(-text=>'Approx. tolerance'),
	  $fr->Scale(-orient=>'horizontal', -variable=>\$Math::Bezier::Convert::APPROX_LINE_TOLERANCE, -from=>1, -width=>3),
	  my $lLabel = $fr->Label(-text=>'Points = ', -justify=>'left'),
	  -sticky=>'ew');
$fr->Checkbutton(-text=> 'Draw with quadratic bezier', -variable => \$draw_quad, -command=> \&quad, -indicatoron=>0)
   ->grid(
	  $fr->Checkbutton(-text=> 'Plot control points', -variable => \$point_quad, -command=> \&quad),
	  $fr->Label(-text=>'Approx. tolerance'),
	  $fr->Scale(-orient=>'horizontal', -variable=>\$Math::Bezier::Convert::APPROX_QUADRATIC_TOLERANCE, -from=>1, -width=>3),
	  my $qLabel = $fr->Label(-text=>'Points = ', -justify=>'left'),
	  -sticky=>'ew', -ipadx=>10);
$fr->Label()
    ->grid( 'x',
	   $fr->Label(-text=>'Ctrl pt. tolerance'),
	   $fr->Scale(-orient=>'horizontal', -variable=>\$Math::Bezier::Convert::CTRL_PT_TOLERANCE, -from=>2, -width=>3), 'x',
	   -sticky=>'ew');
$board->createRectangle(0,0,600,400, -outline=>'white'); # border anchor

my @anchor = (100,200, 100,50, 400,50, 400,200, 400,300, 500,300, 500,200);
my $k = 0;
cubic();quad();
while ($k < @anchor) {
    my $kk = $k;
    $board->createRectangle($anchor[$k]-4,$anchor[$k+1]-4,$anchor[$k]+4,$anchor[$k+1]+4, -outline=>'black', -fill=>'green', -tags=>['anchor'.$k, 'anchor']); # border anchor
    $board->bind('anchor'.$k, "<Button1-Motion>", [sub {shift;move_anchor($kk, @_);$board->delete('cubic','quad');cubic();quad()}, Ev('x'), Ev('y')]);
    $board->bind('anchor'.$k, "<Shift-Button1-Motion>", [sub {shift;move_anchor_alone($kk, @_);$board->delete('cubic','quad');cubic();quad()}, Ev('x'), Ev('y')]);
    $k+=2;
}
$board->createLine(@anchor[0..3], -width=>1, -fill=>'green', -tags=>['rb0','rb2']);
$board->createLine(@anchor[-4..-1], -width=>1, -fill=>'green', -tags=>['rb'.($#anchor-1),'rb'.($#anchor-3)]);
for (my $k = 4; $k<$#anchor-6; $k+=6) {
    $board->createLine(@anchor[$k..$k+5], -width=>1, -fill=>'green', -tags=>['rb'.$k, 'rb'.($k+2), 'rb'.($k+4)]);
}
$board->bind('anchor', "<ButtonRelease>", \&redraw_anchors);
$board->configure(-scrollregion=>[$board->bbox('all')]);

MainLoop;

sub move_anchor_alone {
    my ($k, $x, $y) = @_;
    my ($k1, $k2) = ($k - (($k+2) % 6), $k + 5-(($k+2) % 6));

    $k1 = 0 if $k1 < 0;
    $k2 = $#anchor if $k2 > $#anchor;
    $x = $board->canvasx($x);
    $y = $board->canvasx($y);

    $anchor[$k]=$x;
    $anchor[$k+1]=$y;
    $board->coords('anchor'.$k, $anchor[$k]-4, $anchor[$k+1]-4, $anchor[$k]+4, $anchor[$k+1]+4);
    $board->coords('rb'.$k, @anchor[$k1..$k2]);
}

sub move_anchor {
    my ($k, $x, $y) = @_;
    my ($ox, $oy) = @anchor[$k, $k+1];

    $x = $board->canvasx($x);
    $y = $board->canvasx($y);

    $anchor[$k]=$x;
    $anchor[$k+1]=$y;
    $board->coords('anchor'.$k, $anchor[$k]-4, $anchor[$k+1]-4, $anchor[$k]+4, $anchor[$k+1]+4);

    my ($k1, $k2);

    if ($k % 6 == 0) {
	my ($dx, $dy) = ($x-$ox, $y-$oy);
	if ($k<$#anchor-1) {
	    $k2 = $k + 2;
	    $anchor[$k2]+=$dx;
	    $anchor[$k2+1]+=$dy;
	    $board->coords('anchor'.$k2, $anchor[$k2]-4, $anchor[$k2+1]-4, $anchor[$k2]+4, $anchor[$k2+1]+4);
	} else {
	    $k2 = $k;
	}
	if ($k>0) {
	    $k1 = $k - 2;
	    $anchor[$k1]+=$dx;
	    $anchor[$k1+1]+=$dy;
	    $board->coords('anchor'.$k1, $anchor[$k1]-4, $anchor[$k1+1]-4, $anchor[$k1]+4, $anchor[$k1+1]+4);
	}
    } else {
	my $kk = (($k % 6) == 2) ? -1 : 1;
	my $kc = $k + $kk*2;
	$k2 = $k + $kk*4;
	$k1 = $k;
	if ($k2>=0 and $k2<=$#anchor) {
	    my $ax = $anchor[$k]-$anchor[$kc];
	    my $ay = $anchor[$k+1]-$anchor[$kc+1];
	    my $bx = $ox-$anchor[$kc];
	    my $by = $oy-$anchor[$kc+1];
	    my $kkx = $anchor[$k2]-$anchor[$kc];
	    my $kky = $anchor[$k2+1]-$anchor[$kc+1];
	    my $abi = $ax*$bx+$ay*$by;
	    my $abe = $ax*$by-$ay*$bx;
	    my $ab = sqrt($ax*$ax+$ay*$ay)*sqrt($bx*$bx+$by*$by);
	    $anchor[$k2] = ($kkx*$abi+$kky*$abe)/$ab + $anchor[$kc];
	    $anchor[$k2+1] = (-$kkx*$abe+$kky*$abi)/$ab + $anchor[$kc+1];
	    $board->coords('anchor'.$k2, $anchor[$k2]-4, $anchor[$k2+1]-4, $anchor[$k2]+4, $anchor[$k2+1]+4);
	} else {
	    $k2 = $kc;
	}
	if ($k2<$k1) {
	    my $kk = $k2;
	    $k2 = $k1;
	    $k1 = $kk;
	}
    }
    $board->coords('rb'.$k, @anchor[$k1..$k2+1]);
}

sub redraw_anchors {
    $board->delete('anchor');
    for (my $k = 0; $k < @anchor; $k+=2) {
	$board->createRectangle($anchor[$k]-4,$anchor[$k+1]-4,$anchor[$k]+4,$anchor[$k+1]+4, -outline=>'black', -fill=>'green', -tags=>['anchor'.$k, 'anchor']);
    }
}

sub cubic {
    my @coords=cubic_to_lines(@anchor);
    @coords=map {int($_+0.5)} @coords;
    $lLabel->configure(-text=>'Points = '.sprintf('%.2d',@coords/2));
    $board->delete('cubic');
    if ($draw_line) {
	$board->createLine(@coords, -tags=>'cubic', -width=>3, -fill=>'gray');
    }
    if ($point_line) {
	while (@coords) {
	    my @p=splice(@coords, 0, 2);
	    $board->createRectangle($p[0]-3,$p[1]-3,$p[0]+3,$p[1]+3, -outline=>'black', -fill=>'gray', -tag=>'cubic');
	}
    }
}

sub quad {
    my @coords=cubic_to_quadratic(@anchor);
    @coords=map {int($_+0.5)} @coords;
    my ($x, $y) = splice(@coords,0,2);
    $qLabel->configure(-text=>'Points = '.sprintf('%.2d',@coords/2));
    $board->delete('quad');

    while (@coords) {
	my @p=splice(@coords, 0, 4);
	if ($draw_quad) {$board->createLine($x, $y, @p, -tags=>'quad', -width=>1, -fill=>'blue', -smooth=>1)}
	if ($point_quad) {
	    $board->createRectangle($p[0]-4,$p[1]-4,$p[0]+4,$p[1]+4, -outline=>'blue', -fill=>'blue', -tag=>'quad');
	    $board->createRectangle($p[2]-4,$p[3]-4,$p[2]+4,$p[3]+4, -outline=>'red', -fill=>'red', -tag=>'quad');
	}
	$x=$p[2];
	$y=$p[3];
    }
}
