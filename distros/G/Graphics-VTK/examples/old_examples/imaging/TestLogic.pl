#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# append multiple displaced spheres into an RGB image.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$sphere1 = Graphics::VTK::ImageEllipsoidSource->new;
$sphere1->SetCenter(95,100,0);
$sphere1->SetRadius(70,70,70);
$sphere2 = Graphics::VTK::ImageEllipsoidSource->new;
$sphere2->SetCenter(161,100,0);
$sphere2->SetRadius(70,70,70);
$xor = Graphics::VTK::ImageLogic->new;
$xor->SetInput1($sphere1->GetOutput);
$xor->SetInput2($sphere2->GetOutput);
$xor->SetOutputTrueValue(150);
$xor->SetOperationToXor;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($xor->GetOutput);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
# make interface
do 'WindowLevelInterface.pl';
