#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("$VTK_DATA/binary.pgm");
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToShort;
$dilate = Graphics::VTK::ImageDilateErode3D->new;
$dilate->SetInput($cast->GetOutput);
$dilate->SetDilateValue(255);
$dilate->SetErodeValue(0);
$dilate->SetKernelSize(31,31,1);
$erode = Graphics::VTK::ImageDilateErode3D->new;
$erode->SetInput($dilate->GetOutput);
$erode->SetDilateValue(0);
$erode->SetErodeValue(255);
$erode->SetKernelSize(31,31,1);
$add = Graphics::VTK::ImageMathematics->new;
$add->SetInput1($cast->GetOutput);
$add->SetInput2($erode->GetOutput);
$add->SetOperationToAdd;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($add->GetOutput);
$viewer->SetColorWindow(512);
$viewer->SetColorLevel(256);
# make interface
do 'WindowLevelInterface.pl';
