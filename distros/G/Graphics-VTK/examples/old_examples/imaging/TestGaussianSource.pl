#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the GaussianSource
#source vtkImageInclude.tcl
# Image pipeline
$gauss = Graphics::VTK::ImageGaussianSource->new;
$gauss->SetWholeExtent(0,225,0,225,0,20);
$gauss->SetCenter(100,100,10);
$gauss->SetStandardDeviation(50.0);
$gauss->SetMaximum(255.0);
$gauss->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($gauss->GetOutput);
$viewer->SetZSlice(10);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
$viewer->Render;
$gauss->SetStandardDeviation(100.0);
# make interface
do 'WindowLevelInterface.pl';
