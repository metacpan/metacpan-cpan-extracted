#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Simple viewer for images.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,2);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$magnify = Graphics::VTK::ImageMagnify->new;
$magnify->SetInput($reader->GetOutput);
$magnify->SetMagnificationFactors(2,2,1);
$magnify->InterpolateOn;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($magnify->GetOutput);
$viewer->SetZSlice(1);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#viewer DebugOn
$viewer->Render;
$MW->withdraw;
# time the window level operation
$i = 0;
#
sub timeit
{
 my $puts;
 my $time;
 # Global Variables Declared for this function: i
 $puts->start;
 print(1000000.0 / ($time->viewer_SetColorLevel__i__viewer_Render__incr_i(100))[0]);
 $puts->end;
}
timeit();

Tk->MainLoop;
