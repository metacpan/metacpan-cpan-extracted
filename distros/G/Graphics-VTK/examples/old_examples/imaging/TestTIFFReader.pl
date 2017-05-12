#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$reader = Graphics::VTK::TIFFReader->new;
$reader->SetFileName("../../../vtkdata/testTIFF.tif");
#reader SetFileName $argv
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($reader->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
#make interface
do 'WindowLevelInterface.pl';
