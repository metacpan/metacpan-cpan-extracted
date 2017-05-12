#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# The dataset read by this exercise ("combVectors.vtk") has field data 
# associated with the pointdata, namely two vector fields. In this exercise, 
# you will convert both sets of field data into attribute data. Mappers only 
# process attribute data, not field data. So we must convert the field data to 
# attribute data in order to display it.  (You'll need to determine the "names"
# of the two vector fields in the field data.)
# If there is time remaining, you might consider adding a programmable filter 
# to convert the two sets of vectors into a single scalar field, representing 
# the angle between the two vector fields.
# You will most likely use vtkFieldDataToAttributeDataFilter, vtkHedgeHog, 
# and vtkProgrammableAttributeDataFilter.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
# get the pressure gradient vector field
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/combVectors.vtk");
# Once we know the two vector fields are named "Velocity" and 
# "PressureGradient", we can move these fields to the "vectors" of a dataset.
$velocityDataSet = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$velocityDataSet->SetInput($reader->GetOutput);
$velocityDataSet->SetInputFieldToPointDataField;
$velocityDataSet->SetOutputAttributeDataToPointData;
$velocityDataSet->SetVectorComponent(0,'Velocity',0);
$velocityDataSet->SetVectorComponent(1,'Velocity',1);
$velocityDataSet->SetVectorComponent(2,'Velocity',2);
$pressureGradientDataSet = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$pressureGradientDataSet->SetInput($reader->GetOutput);
$pressureGradientDataSet->SetInputFieldToPointDataField;
$pressureGradientDataSet->SetOutputAttributeDataToPointData;
$pressureGradientDataSet->SetVectorComponent(0,'PressureGradient',0);
$pressureGradientDataSet->SetVectorComponent(1,'PressureGradient',1);
$pressureGradientDataSet->SetVectorComponent(2,'PressureGradient',2);
# To display the vector fields, we use vtkHedgeHog to create lines.
$velocity = Graphics::VTK::HedgeHog->new;
$velocity->SetInput($velocityDataSet->GetOutput);
$velocity->SetScaleFactor(0.001);
$pressureGradient = Graphics::VTK::HedgeHog->new;
$pressureGradient->SetInput($pressureGradientDataSet->GetOutput);
$pressureGradient->SetScaleFactor(0.00001);
# We use the ProgrammableAttributeDataFilter to compute the cosine
# of the angle between the two vector fields (i.e. the dot product 
# normalized by the product of the vector lengths).
# The call to "dotProduct SetInput [velocityDataSet GetOutput]" should not
# be necessary.  This should be fixed by Viz'99
$dotProduct = Graphics::VTK::ProgrammableAttributeDataFilter->new;
$dotProduct->SetInput($velocityDataSet->GetOutput);
$dotProduct->AddInput($velocityDataSet->GetOutput);
$dotProduct->AddInput($pressureGradientDataSet->GetOutput);
$dotProduct->SetExecuteMethod(
 sub
  {
   ExecuteDot();
  }
);
#
sub ExecuteDot
{
 my $d;
 my $i;
 my $input0;
 my $input1;
 my $inputs;
 my $l0;
 my $l1;
 my $numPts;
 my $scalars;
 my $v0;
 my $v0x;
 my $v0y;
 my $v0z;
 my $v1;
 my $v1x;
 my $v1y;
 my $v1z;
 my $vectors0;
 my $vectors1;
 # proc for ProgrammableAttributeDataFilter.  Note the use of "double()"
 # in the calculations.  This protects us from Tcl using ints and 
 # overflowing.
 $inputs = $dotProduct->GetInputList;
 $input0 = $inputs->GetItem(0);
 $input1 = $inputs->GetItem(1);
 $numPts = $input0->GetNumberOfPoints;
 $vectors0 = $input0->GetPointData->GetVectors;
 $vectors1 = $input1->GetPointData->GetVectors;
 $scalars = Graphics::VTK::Scalars->new;
 for ($i = 0; $i < $numPts; $i += 1)
  {
   $v0 = $vectors0->GetVector($i);
   $v1 = $vectors1->GetVector($i);
   $v0x = $v0[0];
   $v0y = $v0[1];
   $v0z = $v0[2];
   $v1x = $v1[0];
   $v1y = $v1[1];
   $v1z = $v1[2];
   $l0 = ($v0x) * ($v0x) + ($v0y) * ($v0y) + ($v0z) * ($v0z);
   $l1 = ($v1x) * ($v1x) + ($v1y) * ($v1y) + ($v1z) * ($v1z);
   $l0 = sqrt(($l0));
   $l1 = sqrt(($l1));
   if ($l0 > 0.0 && $l1 > 0.0)
    {
     $d = (($v0x) * ($v1x) + ($v0y) * ($v1y) + ($v0z) * ($v1z)) / ($l0 * $l1);
    }
   else
    {
     $d = 0.0;
    }
   $scalars->InsertScalar($i,$d);
  }
 $dotProduct->GetOutput->GetPointData->SetScalars($scalars);

}
# Create the mappers and actors.  Note the call to GetPolyDataOutput when
# setting up the mapper for the ProgrammableAttributeDataFilter
$velocityMapper = Graphics::VTK::PolyDataMapper->new;
$velocityMapper->SetInput($velocity->GetOutput);
$velocityMapper->ScalarVisibilityOff;
$velocityActor = Graphics::VTK::LODActor->new;
$velocityActor->SetMapper($velocityMapper);
$velocityActor->SetNumberOfCloudPoints(1000);
$velocityActor->GetProperty->SetColor(1,0,0);
$pressureGradientMapper = Graphics::VTK::PolyDataMapper->new;
$pressureGradientMapper->SetInput($pressureGradient->GetOutput);
$pressureGradientMapper->ScalarVisibilityOff;
$pressureGradientActor = Graphics::VTK::LODActor->new;
$pressureGradientActor->SetMapper($pressureGradientMapper);
$pressureGradientActor->SetNumberOfCloudPoints(1000);
$pressureGradientActor->GetProperty->SetColor(0,1,0);
$dotMapper = Graphics::VTK::PolyDataMapper->new;
$dotMapper->SetInput($dotProduct->GetPolyDataOutput);
$dotMapper->SetScalarRange(-1,1);
$dotActor = Graphics::VTK::LODActor->new;
$dotActor->SetMapper($dotMapper);
$dotActor->SetNumberOfCloudPoints(1000);
$barActor = Graphics::VTK::ScalarBarActor->new;
$barActor->SetLookupTable($dotMapper->GetLookupTable);
$barActor->SetOrientationToHorizontal;
$barActor->GetProperty->SetColor(0,0,0);
$barActor->GetPositionCoordinate->SetCoordinateSystemToNormalizedViewport;
$barActor->GetPositionCoordinate->SetValue(0.1,0.01);
$barActor->SetOrientationToHorizontal;
$barActor->SetWidth(0.8);
$barActor->SetHeight(0.10);
$barActor->SetTitle("Cosine(<Velocity, PressureGradient>)");
# The PLOT3DReader is used to draw the outline of the original dataset.
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($velocityActor);
$ren1->AddActor($pressureGradientActor);
$ren1->AddActor($dotActor);
$ren1->AddActor($barActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
#ren1 SetBackground 0.1 0.2 0.4
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(-21.6807,-22.6387,35.9759);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.0158865,0.293715,0.955761);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetWindowName("Multidimensional Visualization Exercise");
#renWin SetFileName "combMultidimensional.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
