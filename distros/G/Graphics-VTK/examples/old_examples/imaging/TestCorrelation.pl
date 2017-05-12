#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Show the constant kernel.  Smooth an impulse function.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
$s1 = Graphics::VTK::ImageCanvasSource2D->new;
$s1->SetScalarType($Graphics::VTK::FLOAT);
$s1->SetExtent(0,255,0,255,0,0);
$s1->SetDrawColor(0);
$s1->FillBox(0,255,0,255);
$s1->SetDrawColor(2.0);
$s1->FillTriangle(10,100,190,150,40,250);
$s2 = Graphics::VTK::ImageCanvasSource2D->new;
$s2->SetScalarType($Graphics::VTK::FLOAT);
$s2->SetExtent(0,31,0,31,0,0);
$s2->SetDrawColor(0.0);
$s2->FillBox(0,31,0,31);
$s2->SetDrawColor(2.0);
$s2->FillTriangle(10,1,25,10,1,5);
$convolve = Graphics::VTK::ImageCorrelation->new;
$convolve->SetDimensionality(2);
$convolve->SetInput1($s1->GetOutput);
$convolve->SetInput2($s2->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($convolve->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
# make interface
do 'WindowLevelInterface.pl';
