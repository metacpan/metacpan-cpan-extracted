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
$pad->SetOutputWholeExtent(-220,340,-220,340,0,0);
$quant = Graphics::VTK::ImageQuantizeRGBToIndex->new;
$quant->SetInput($pad->GetOutput);
$quant->SetNumberOfColors(64);
$quant->Update;
$map = Graphics::VTK::ImageMapToRGBA->new;
$map->SetInput($quant->GetOutput);
$map->SetLookupTable($quant->GetLookupTable);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($map->GetOutput);
$viewer->SetZSlice(0);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127);
$viewer->GetActor2D->SetDisplayPosition(220,220);
$viewer->Render;
do 'WindowLevelInterface.pl';
