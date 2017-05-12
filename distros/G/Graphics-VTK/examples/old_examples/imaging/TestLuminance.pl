#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script calculates the luminanace of an image
#source vtkImageInclude.tcl
# Image pipeline
$image = Graphics::VTK::BMPReader->new;
$image->SetFileName("$VTK_DATA/beach.bmp");
$luminance = Graphics::VTK::ImageLuminance->new;
$luminance->SetInput($image->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($luminance->GetOutput);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
#make interface
do 'WindowLevelInterface.pl';
