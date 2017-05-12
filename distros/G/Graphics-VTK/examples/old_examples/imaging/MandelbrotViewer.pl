#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkInt;
#source $VTK_TCL/WidgetObject.tcl
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
#source TkInteractor.tcl
$RANGE = 150;
$MAX_ITERATIONS_1 = $RANGE;
$MAX_ITERATIONS_2 = $RANGE;
$XRAD = 200;
$YRAD = 200;
$mandelbrot1 = Graphics::VTK::ImageMandelbrotSource->new;
$mandelbrot1->SetMaximumNumberOfIterations($MAX_ITERATIONS_1);
$mandelbrot1->SetWholeExtent(-$XRAD,$XRAD - 1,-$YRAD,$YRAD - 1,0,0);
$mandelbrot1->SetSpacing(1.3 / $XRAD);
$mandelbrot1->SetOriginCX(-0.72,0.22,0.0,0.0);
$mandelbrot1->SetProjectionAxes(0,1,2);
$table1 = Graphics::VTK::LookupTable->new;
$table1->SetTableRange(0,$RANGE);
$table1->SetNumberOfColors($RANGE);
$table1->Build;
$table1->SetTableValue($RANGE - 1,0.0,0.0,0.0,0.0);
$map1 = Graphics::VTK::ImageMapToRGBA->new;
$map1->SetInput($mandelbrot1->GetOutput);
$map1->SetLookupTable($table1);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($map1->GetOutput);
$viewer->SetColorWindow(255.0);
$viewer->SetColorLevel(127.5);
$viewer->GetActor2D->SetPosition($XRAD,$YRAD);
$mandelbrot2 = Graphics::VTK::ImageMandelbrotSource->new;
$mandelbrot2->SetMaximumNumberOfIterations($MAX_ITERATIONS_2);
$mandelbrot2->SetWholeExtent(-$XRAD,$XRAD - 1,-$YRAD,$YRAD - 1,0,0);
$mandelbrot2->SetSpacing(1.3 / $XRAD);
$mandelbrot2->SetOriginCX(-0.72,0.22,0.0,0.0);
$mandelbrot2->SetProjectionAxes(2,3,1);
$table2 = Graphics::VTK::LookupTable->new;
$table2->SetTableRange(0,$RANGE);
$table2->SetNumberOfColors($RANGE);
$table2->Build;
$table2->SetTableValue($RANGE - 1,0.0,0.0,0.0,0.0);
$map2 = Graphics::VTK::ImageMapToRGBA->new;
$map2->SetInput($mandelbrot2->GetOutput);
$map2->SetLookupTable($table2);
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($map2->GetOutput);
$viewer2->SetColorWindow(256.0);
$viewer2->SetColorLevel(127.5);
$viewer2->GetActor2D->SetPosition($XRAD,$YRAD);
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$top = $MW->{'.top'} = $MW->Toplevel;
$f1 = $top->{'.f1'} = $top->Frame;
$quit = $top->{'.quit'} = $top->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$quit->pack('-side','bottom','-fill','x','-expand','f');
$reset = $top->{'.reset'} = $top->Button('-text','Reset','-command',
 sub
  {
   Reset();
  }
);
$reset->pack('-side','bottom','-fill','x','-expand','f');
$f1->pack('-side','bottom','-fill','both','-expand','t');
$manFrame = $f1->{'.man'} = $f1->Frame;
$julFrame = $f1->{'.jul'} = $f1->Frame;
foreach $_ (($manFrame,$julFrame))
 {
  $_->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
 }
$manView = $manFrame->{'.view'} = $manFrame->vtkImageViewer('-width',$XRAD * 2,'-height',$YRAD * 2,'-iv',$viewer);
$manRange = $manFrame->{'.range'} = $manFrame->Label('-text',"Mandelbrot Range: 0 - $RANGE");
$manRange->pack('-side','bottom','-fill','none','-expand','f');
$manView->pack('-side','bottom','-fill','both','-expand','t');
$julView = $julFrame->{'.view'} = $julFrame->vtkImageViewer('-width',$XRAD * 2,'-height',$YRAD * 2,'-iv',$viewer2);
$julRange = $julFrame->{'.range'} = $julFrame->Label('-text',"Julia Range: 0 - $RANGE");
$julRange->pack('-side','bottom','-fill','none','-expand','f');
$julView->pack('-side','bottom','-fill','both','-expand','t');
$equation = $top->{'.equation'} = $top->Label('-text',"X = X^2 + C");
$equation->pack('-side','bottom','-fill','x');
$focus->_manView;
$manView->bind('<ButtonPress-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   StartZoom($Ev->x,$Ev->y);
  }
);
$manView->bind('<ButtonRelease-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   EndZoom($Ev->x,$Ev->y,1,2);
  }
);
$manView->bind('<ButtonRelease-2>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   Pan($Ev->x,$Ev->y,1,2);
  }
);
$manView->bind('<ButtonRelease-3>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   ZoomOut($Ev->x,$Ev->y,1,2);
  }
);
$manView->bind('<KeyPress-u>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$manView->bind('<KeyPress-e>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   exit();
  }
);
$manView->bind('<Expose>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   Expose($W);
  }
);
$julView->bind('<ButtonPress-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   StartZoom($Ev->x,$Ev->y);
  }
);
$julView->bind('<ButtonRelease-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   EndZoom($Ev->x,$Ev->y,2,1);
  }
);
$julView->bind('<ButtonRelease-2>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   Pan($Ev->x,$Ev->y,2,1);
  }
);
$julView->bind('<ButtonRelease-3>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   ZoomOut($Ev->x,$Ev->y,2,1);
  }
);
$julView->bind('<KeyPress-u>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$julView->bind('<KeyPress-e>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   exit();
  }
);
$julView->bind('<Expose>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   Expose($W);
  }
);
$IN_EXPOSE = 0;
#
sub Expose
{
 my $widget = shift;
 my $return;
 # Global Variables Declared for this function: IN_EXPOSE
 return if ($IN_EXPOSE == $widget);
 $IN_EXPOSE = $widget;
 $MW->update;
 $IN_EXPOSE = 0;
 $widget->Render;
}
#
sub Reset
{
 my $MandelbrotUpdate;
 # Global Variables Declared for this function: MAX_ITERATIONS_1, MAX_ITERATIONS_2, RANGE, XRAD
 $MAX_ITERATIONS_2 = $RANGE;
 $MAX_ITERATIONS_1 = $RANGE;
 $mandelbrot1->SetSpacing(1.3 / $XRAD);
 $mandelbrot1->SetOriginCX(-0.72,0.22,0.0,0.0);
 $mandelbrot2->SetSpacing(1.3 / $XRAD);
 $mandelbrot2->SetOriginCX(-0.72,0.22,0.0,0.0);
 MandelbrotUpdate();
}
#
sub MandelbrotUpdate
{
 my $ci;
 my $cr;
 my $max;
 my $min;
 my $tmp;
 my $xi;
 my $xr;
 # Global Variables Declared for this function: MAX_ITERATIONS_1, MAX_ITERATIONS_2, RANGE
 # Global Variables Declared for this function: manView, julView, manRange, julRange
 $mandelbrot1->SetMaximumNumberOfIterations($MAX_ITERATIONS_1);
 $mandelbrot2->SetMaximumNumberOfIterations($MAX_ITERATIONS_1);
 $tmp = $mandelbrot1->GetOriginCX;
 $cr = $tmp[0];
 $ci = $tmp[1];
 $xr = $tmp[2];
 $xi = $tmp[3];
 $mandelbrot1->Update;
 $tmp = $mandelbrot1->GetOutput->GetScalarRange;
 $min = $tmp[0];
 $max = $tmp[1];
 $manRange->configure('-text',"C = $cr + i $ci,    Mandelbrot Range: $min - $max");
 $table1->SetTableRange($min - 1,$max);
 $MAX_ITERATIONS_1 = $min + $RANGE;
 $mandelbrot2->Update;
 $tmp = $mandelbrot2->GetOutput->GetScalarRange;
 $min = $tmp[0];
 $max = $tmp[1];
 $julRange->configure('-text',"X = $xr + i $xi,    Julia Range: $min - $max");
 $table2->SetTableRange($min - 1,$max);
 $MAX_ITERATIONS_2 = $min + $RANGE;
 $manView->Render;
 $julView->Render;
}
#
sub StartZoom
{
 my $x = shift;
 my $y = shift;
 # Global Variables Declared for this function: X, Y
 $X = $x;
 $Y = $y;
}
# prescision good enough?
#
sub EndZoom
{
 my $x = shift;
 my $y = shift;
 my $master = shift;
 my $slave = shift;
 my $MandelbrotUpdate;
 my $scale;
 my $tmp;
 my $xDim;
 my $xMid;
 my $yDim;
 my $yMid;
 # Global Variables Declared for this function: X, Y, XRAD, YRAD
 # Tk origin in uppder left. Flip y axis. Put origin in middle. 
 $y = $YRAD - $y;
 $Y = $YRAD - $Y;
 $x = $x - $XRAD;
 $X = $X - $XRAD;
 # sort
 if ($X < $x)
  {
   $tmp = $X;
   $X = $x;
   $x = $tmp;
  }
 if ($Y < $y)
  {
   $tmp = $Y;
   $Y = $y;
   $y = $tmp;
  }
 # middle/radius
 $xMid = 0.5 * ($x + $X);
 $yMid = 0.5 * ($y + $Y);
 $xDim = ($X - $x);
 $yDim = ($Y - $y);
 # determine scale
 if ($xDim <= 4 && $yDim <= 4)
  {
   # Box too small.  Zoom into point.
   $scale = 0.5;
  }
 else
  {
   # relative to window dimensions
   $xDim = 1.0 * $xDim / (2 * $XRAD);
   $yDim = 1.0 * $yDim / (2 * $YRAD);
   # take the largest
   if ($xDim > $yDim)
    {
     $scale = $xDim;
    }
   else
    {
     $scale = $yDim;
    }
  }
 $mandelbrot{$master}->Pan($xMid,$yMid,0.0);
 $mandelbrot{$master}->Zoom($scale);
 $mandelbrot{$slave}->CopyOriginAndSpacing($mandelbrot{$master});
 MandelbrotUpdate();
}
#
sub Pan
{
 my $x = shift;
 my $y = shift;
 my $master = shift;
 my $slave = shift;
 my $MandelbrotUpdate;
 my $scale;
 # Global Variables Declared for this function: XRAD, YRAD
 # Tk origin in uppder left. Flip y axis. Put origin in middle. 
 $x = $x - $XRAD;
 $y = $YRAD - $y;
 $scale = 2.0;
 # Compute new origin.
 $mandelbrot{$master}->Pan($x,$y,0.0);
 $mandelbrot{$slave}->CopyOriginAndSpacing($mandelbrot{$master});
 MandelbrotUpdate();
}
#
sub ZoomOut
{
 my $x = shift;
 my $y = shift;
 my $master = shift;
 my $slave = shift;
 my $MandelbrotUpdate;
 my $scale;
 # Global Variables Declared for this function: XRAD, YRAD
 # Tk origin in uppder left. Flip y axis. Put origin in middle. 
 $x = $x - $XRAD;
 $y = $YRAD - $y;
 $scale = 2.0;
 # Compute new origin.
 $mandelbrot{$master}->Pan($x,$y,0.0);
 $mandelbrot{$master}->Zoom($scale);
 $mandelbrot{$slave}->CopyOriginAndSpacing($mandelbrot{$master});
 MandelbrotUpdate();
}
MandelbrotUpdate();
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
