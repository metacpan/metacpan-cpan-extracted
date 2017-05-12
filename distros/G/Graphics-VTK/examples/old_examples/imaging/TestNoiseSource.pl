#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the NoiseSource
#source vtkImageInclude.tcl
# Image pipeline
$noise = Graphics::VTK::ImageNoiseSource->new;
$noise->SetWholeExtent(0,225,0,225,0,20);
$noise->SetMinimum(0.0);
$noise->SetMaximum(255.0);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($noise->GetOutput);
$viewer->SetZSlice(10);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
