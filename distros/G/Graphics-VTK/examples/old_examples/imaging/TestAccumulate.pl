#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$source->______imaging_examplesTcl_vtkImageInclude_tcl;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$smooth = Graphics::VTK::ImageGaussianSmooth->new;
$smooth->SetDimensionality(2);
$smooth->SetStandardDeviations(1,1);
$smooth->SetInput($reader->GetOutput);
$append = Graphics::VTK::ImageAppendComponents->new;
$SetInput1 = $SetInput1 . $reader->GetOutput;
$SetInput2 = $SetInput2 . $smooth->GetOutput;
$clip = Graphics::VTK::ImageClip->new;
$clip->SetInput($append->GetOutput);
$clip->SetOutputWholeExtent(0,255,0,255,20,22);
$accum = Graphics::VTK::ImageAccumulate->new;
$accum->SetInput($clip->GetOutput);
$accum->SetComponentExtent(0,512,0,512,0,0);
$accum->SetComponentSpacing(6,6,0.0);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($accum->GetOutput);
#	viewer SetZSlice 22
$viewer->SetColorWindow(4);
$viewer->SetColorLevel(2);
$source->______imaging_examplesTcl_WindowLevelInterface_tcl;
