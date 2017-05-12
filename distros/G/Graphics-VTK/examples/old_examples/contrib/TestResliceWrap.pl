#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Simple viewer for images.
$source->______imaging_examplesTcl_vtkImageInclude_tcl;
# Image pipeline
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("$VTK_DATA/masonry.ppm");
$reader->SetDataExtent(0,255,0,255,0,0);
$reader->SetDataSpacing(1,1,1);
$reader->SetDataOrigin(0,0,0);
$reader->UpdateWholeExtent;
$transform = Graphics::VTK::Transform->new;
$transform->RotateZ(45);
$transform->Translate(0,0,0);
$transform->Scale(1.414,1.414,1.414);
$reslice = Graphics::VTK::ImageReslice->new;
$reslice->SetInput($reader->GetOutput);
$reslice->SetResliceTransform($transform);
$reslice->InterpolateOn;
$reslice->SetInterpolationModeToCubic;
$reslice->WrapOn;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($reslice->GetOutput);
$viewer->SetZSlice(0);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
$viewer->Render;
$source->______imaging_examplesTcl_WindowLevelInterface_tcl;
$windowToimage = Graphics::VTK::WindowToImageFilter->new;
$windowToimage->SetInput($viewer->GetImageWindow);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetInput($windowToimage->GetOutput);
$pnmWriter->SetFileName("TestResliceWrap.tcl.ppm");
#  pnmWriter Write
