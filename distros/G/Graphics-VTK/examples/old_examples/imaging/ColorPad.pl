#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Make an image larger by repeating the data.  Tile.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::PNMReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetFileName("$VTK_DATA/earth.ppm");
$pad = Graphics::VTK::ImageMirrorPad->new;
$pad->SetInput($reader->GetOutput);
$pad->SetOutputWholeExtent(-220,340,-220,340,0,92);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($pad->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127);
$viewer->GetActor2D->SetDisplayPosition(220,220);
#make interface
do 'WindowLevelInterface.pl';
