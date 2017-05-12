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
use Graphics::VTK::Tk::vtkInt;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
#reader Update
$cache = Graphics::VTK::ImageCacheFilter->new;
$cache->SetInput($reader->GetOutput);
$cache->SetCacheSize(20);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($cache->GetOutput);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
$viewer->SetPosition(50,50);
#viewer DebugOn
for ($i = 0; $i < 5; $i += 1)
 {
  for ($j = 10; $j < 30; $j += 1)
   {
    $viewer->SetZSlice($j);
    $viewer->Render;
   }
 }
#wm deiconify .vtkInteract
#make interface
do 'WindowLevelInterface.pl';
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
