#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script shows the magnitude of an image in frequency domain.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,22,22);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarType($Graphics::VTK::FLOAT);
$scale2 = Graphics::VTK::ImageShiftScale->new;
$scale2->SetInput($cast->GetOutput);
$scale2->SetScale(0.05);
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetInput($scale2->GetOutput);
$gradient->SetDimensionality(3);
$pnm = Graphics::VTK::PNMReader->new;
$pnm->SetFileName("$VTK_DATA/masonry.ppm");
$cast2 = Graphics::VTK::ImageCast->new;
$cast2->SetInput($pnm->GetOutput);
$cast2->SetOutputScalarType($Graphics::VTK::FLOAT);
$magnitude = Graphics::VTK::ImageDotProduct->new;
$magnitude->SetInput1($cast2->GetOutput);
$magnitude->SetInput2($gradient->GetOutput);
#vtkImageViewer viewer
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($magnitude->GetOutput);
$viewer->SetColorWindow(1000);
$viewer->SetColorLevel(300);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
