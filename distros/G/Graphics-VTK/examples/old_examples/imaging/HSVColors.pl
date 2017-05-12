#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example uses a programable source to create a ramp.
# This is converted into a volume (256x256x256) with 3 components.
# Each axis ramps independently.
# It is then converted into a color volume with Hue, 
# Saturation and Value ramping
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
#source vtkImageInclude.tcl
$rampSource = Graphics::VTK::ProgrammableSource->new;
$rampSource->SetExecuteMethod(
 sub
  {
   ramp();
  }
);
# Generate a single ramp value
#
sub ramp
{
 my $idx;
 my $newScalars;
 $newScalars = Graphics::VTK::Scalars->new;
 $newScalars->SetNumberOfScalars(256);
 # Compute points and scalars
 for ($idx = 0; $idx < 256; $idx += 1)
  {
   $newScalars->SetScalar($idx,$idx);
  }
 $rampSource->GetStructuredPointsOutput->SetWholeExtent(0,255,0,0,0,0);
 $rampSource->GetStructuredPointsOutput->SetDimensions(256,1,1);
 $rampSource->GetStructuredPointsOutput->GetPointData->SetScalars($newScalars);

 #reference counting - it's ok
}
# use pad filter to create a volume
$pad = Graphics::VTK::ImageWrapPad->new;
$pad->SetInput($rampSource->GetStructuredPointsOutput);
$pad->SetOutputWholeExtent(0,255,0,255,0,255);
$pad->ReleaseDataFlagOn;
# hack work around of bug
$copy1 = Graphics::VTK::ImageShiftScale->new;
$copy1->SetInput($pad->GetOutput);
$copy2 = Graphics::VTK::ImageShiftScale->new;
$copy2->SetInput($pad->GetOutput);
$copy3 = Graphics::VTK::ImageShiftScale->new;
$copy3->SetInput($pad->GetOutput);
# create HSV components
$perm1 = Graphics::VTK::ImagePermute->new;
$perm1->SetInput($copy1->GetOutput);
#perm1 SetInput [pad GetOutput]
$perm1->SetFilteredAxes($VTK_IMAGE_Y_AXIS,$VTK_IMAGE_Z_AXIS,$VTK_IMAGE_X_AXIS);
$perm1->ReleaseDataFlagOn;
$perm2 = Graphics::VTK::ImagePermute->new;
$perm2->SetInput($copy2->GetOutput);
#perm2 SetInput [pad GetOutput]
$perm2->SetFilteredAxes($VTK_IMAGE_Z_AXIS,$VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$perm2->ReleaseDataFlagOn;
$append1 = Graphics::VTK::ImageAppendComponents->new;
$append1->SetInput1($copy3->GetOutput);
#append1 SetInput1 [pad GetOutput]
$append1->SetInput2($perm1->GetOutput);
$append1->ReleaseDataFlagOn;
$append2 = Graphics::VTK::ImageAppendComponents->new;
$append2->SetInput1($append1->GetOutput);
$append2->SetInput2($perm2->GetOutput);
$rgb = Graphics::VTK::ImageHSVToRGB->new;
$rgb->SetInput($append2->GetOutput);
$rgb->SetMaximum(255);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($rgb->GetOutput);
$viewer->SetZSlice(128);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
# make interface
do 'WindowLevelInterface.pl';
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
