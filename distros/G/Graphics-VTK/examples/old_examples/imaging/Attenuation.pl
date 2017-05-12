#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Show the constant kernel.  Smooth an impulse function.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("../../../vtkdata/AttenuationArtifact.pgm");
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToFloat;
# get rid of discrete scalars
$smooth = Graphics::VTK::ImageGaussianSmooth->new;
$smooth->SetDimensionality(2);
$smooth->SetInput($cast->GetOutput);
$smooth->SetStandardDeviations(0.8,0.8,0);
$m1 = Graphics::VTK::Sphere->new;
$m1->SetCenter(310,130,0);
$m1->SetRadius(0);
$m2 = Graphics::VTK::SampleFunction->new;
$m2->SetImplicitFunction($m1);
$m2->SetModelBounds(0,264,0,264,0,1);
$m2->SetSampleDimensions(264,264,1);
$m3 = Graphics::VTK::ImageShiftScale->new;
$m3->SetInput($m2->GetOutput);
$m3->SetScale(0.000095);
$m4 = Graphics::VTK::ImageMathematics->new;
$m4->SetInput1($m3->GetOutput);
$m4->SetOperationToSquare;
$m4->BypassOn;
$m5 = Graphics::VTK::ImageMathematics->new;
$m5->SetInput1($m4->GetOutput);
$m5->SetOperationToInvert;
$m6 = Graphics::VTK::ImageShiftScale->new;
$m6->SetInput($m5->GetOutput);
$m6->SetScale(255);
$t2 = Graphics::VTK::ImageShiftScale->new;
#t2 SetInput [t1 GetOutput]
$t2->SetScale(-1);
#vtkImageMathematics m3
#m3 SetInput1 [t2 GetOutput]
#m3 SetOperationToInvert
#m3 ReleaseDataFlagOff
$div = Graphics::VTK::ImageMathematics->new;
$div->SetInput1($smooth->GetOutput);
$div->SetInput2($m3->GetOutput);
$div->SetOperationToMultiply;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($div->GetOutput);
#viewer SetInput [cast GetOutput]
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
#viewer ColorFlagOn
# make interface
do 'WindowLevelInterface.pl';
