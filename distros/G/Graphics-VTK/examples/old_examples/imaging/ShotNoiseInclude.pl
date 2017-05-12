#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Show the constant kernel.  Smooth an impulse function.
#set shotNoiseAmplitude 2000.0
#set shotNoiseFraction 0.1
#set shotNoiseExtent 0 255 0 255 0 92
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
$shotNoiseSource = Graphics::VTK::ImageNoiseSource->new;
$shotNoiseSource->SetWholeExtent($shotNoiseExtent);
$shotNoiseSource->SetMinimum(0.0);
$shotNoiseSource->SetMaximum(1.0);
$shotNoiseSource->ReleaseDataFlagOff;
$shotNoiseThresh1 = Graphics::VTK::ImageThreshold->new;
$shotNoiseThresh1->SetInput($shotNoiseSource->GetOutput);
$shotNoiseThresh1->ThresholdByLower(1.0 - $shotNoiseFraction);
$shotNoiseThresh1->SetInValue(0);
$shotNoiseThresh1->SetOutValue($shotNoiseAmplitude);
$shotNoiseThresh2 = Graphics::VTK::ImageThreshold->new;
$shotNoiseThresh2->SetInput($shotNoiseSource->GetOutput);
$shotNoiseThresh2->ThresholdByLower($shotNoiseFraction);
$shotNoiseThresh2->SetInValue(-$shotNoiseAmplitude);
$shotNoiseThresh2->SetOutValue(0.0);
$shotNoise = Graphics::VTK::ImageMathematics->new;
$shotNoise->SetInput1($shotNoiseThresh1->GetOutput);
$shotNoise->SetInput2($shotNoiseThresh2->GetOutput);
$shotNoise->SetOperationToAdd;
