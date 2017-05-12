#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the SinusoidSource
#source vtkImageInclude.tcl
# Image pipeline
$cos = Graphics::VTK::ImageSinusoidSource->new;
$cos->SetWholeExtent(0,225,0,225,0,20);
$cos->SetAmplitude(250);
$cos->SetDirection(1,1,1);
$cos->SetPeriod(20);
$cos->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($cos->GetOutput);
$viewer->SetZSlice(10);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
