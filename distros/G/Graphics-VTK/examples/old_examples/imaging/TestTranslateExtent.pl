#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Simple viewer for images.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
#reader Update
$translate = Graphics::VTK::ImageTranslateExtent->new;
$translate->SetInput($reader->GetOutput);
$translate->SetTranslation(10,10,10);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($translate->GetOutput);
$viewer->SetZSlice(14);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
$viewer->Render;
#make interface
do 'WindowLevelInterface.pl';
