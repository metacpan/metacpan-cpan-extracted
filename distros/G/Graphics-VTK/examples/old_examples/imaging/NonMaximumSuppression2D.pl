#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# This script is for testing the 2dNonMaximumSuppressionFilter.
# The filter works exclusively on the output of the gradient filter.
# The effect is to pick the peaks of the gradient creating thin lines.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetInput($reader->GetOutput);
$gradient->SetDimensionality(2);
$gradient->ReleaseDataFlagOff;
$magnitude = Graphics::VTK::ImageMagnitude->new;
$magnitude->SetInput($gradient->GetOutput);
$suppress = Graphics::VTK::ImageNonMaximumSuppression->new;
$suppress->SetVectorInput($gradient->GetOutput);
$suppress->SetMagnitudeInput($magnitude->GetOutput);
$suppress->SetDimensionality(2);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($suppress->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(1000);
$viewer->SetColorLevel(500);
#viewer DebugOn
$viewer->Render;
# make interface
do 'WindowLevelInterface.pl';
