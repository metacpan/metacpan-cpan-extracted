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
$sphere3 = Graphics::VTK::ImageEllipsoidSource->new;
$sphere3->SetCenter(128,160,0);
$sphere3->SetRadius(70,70,70);
$append = Graphics::VTK::ImageAppendComponents->new;
$AddInput = $AddInput . $sphere3->GetOutput;
$AddInput = $AddInput . $sphere1->GetOutput;
$AddInput = $AddInput . $sphere2->GetOutput;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($append->GetOutput);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
# make interface
do 'WindowLevelInterface.pl';
