#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Plane source to generate texture
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetResolution(63,63);
# resolution specifies number of quads
# Transform for texture and quad
$aTransform = Graphics::VTK::Transform->new;
$aTransform->RotateX(30);
$planeTransform = Graphics::VTK::TransformPolyDataFilter->new;
$planeTransform->SetTransform($aTransform);
$planeTransform->SetInput($plane->GetOutput);
# Generate a synthetic volume from quadric
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);
$transformSamples = Graphics::VTK::Transform->new;
$transformSamples->RotateX(30);
$transformSamples->Inverse;
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(30,30,30);
$sample->SetImplicitFunction($quadric);
$sample->Update;
# Probe the synthetic volume
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($planeTransform->GetOutput);
$probe->SetSource($sample->GetOutput);
$probe->Update;
# Create Structured points and set the scalars
$structuredPoints = Graphics::VTK::StructuredPoints->new;
$structuredPoints->GetPointData->SetScalars($probe->GetOutput->GetPointData->GetScalars);
$structuredPoints->SetDimensions(64,64,1);
# these dimensions must match probe point count
# Define the texture with structured points
$polyTexture = Graphics::VTK::Texture->new;
$polyTexture->SetInput($structuredPoints);
# The quad we'll see
$quad = Graphics::VTK::PlaneSource->new;
$quad->SetResolution(1,1);
# Use the same transform as the probed points
$quadTransform = Graphics::VTK::TransformPolyDataFilter->new;
$quadTransform->SetTransform($aTransform);
$quadTransform->SetInput($quad->GetOutput);
$quadMapper = Graphics::VTK::PolyDataMapper->new;
$quadMapper->SetInput($quadTransform->GetOutput);
$quadActor = Graphics::VTK::Actor->new;
$quadActor->SetMapper($quadMapper);
$quadActor->SetTexture($polyTexture);
# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
$ren1->SetBackground(1,1,1);
$ren1->AddActor($quadActor);
$ren1->AddActor($outlineActor);
$ren1->GetActiveCamera->Dolly(1.3);
$ren1->ResetCameraClippingRange;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
# Update the scalars in the structured points with the probe's output
#
sub updateStructuredPoints
{
 $structuredPoints->GetPointData->SetScalars($probe->GetOutput->GetPointData->GetScalars);
}
# Transform the probe and resample
#
sub resample
{
 # Transform the probe points and the quad
 $aTransform->RotateY(10);
 # Force an update on the probe since the pipeline is broken
 $probe->Update;
 $renWin->Render;
}
# Set the probes end method to update the scalars in the structured points
$probe->SetEndMethod('updateStructuredPoints');
for ($i = 1; $i <= 36; $i += 1)
 {
  resample();
 }
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
