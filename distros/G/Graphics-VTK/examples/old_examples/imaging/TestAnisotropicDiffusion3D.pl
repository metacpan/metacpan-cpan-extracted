#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Diffuses to 26 neighbors if difference is below threshold.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->SetDataSpacing(1,1,2);
#reader DebugOn
$diffusion = Graphics::VTK::ImageAnisotropicDiffusion3D->new;
$diffusion->SetInput($reader->GetOutput);
$diffusion->SetDiffusionFactor(1.0);
$diffusion->SetDiffusionThreshold(100.0);
$diffusion->SetNumberOfIterations(5);
$diffusion->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($diffusion->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(3000);
$viewer->SetColorLevel(1500);
#make interface
do 'WindowLevelInterface.pl';
