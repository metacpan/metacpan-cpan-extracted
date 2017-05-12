#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Example demonstrates how to generate a 3D tetrahedra mesh from a volume
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
# Quadric definition
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(20,20,20);
$sample->SetImplicitFunction($quadric);
$sample->ComputeNormalsOff;
# Generate tetrahedral mesh
$clip = Graphics::VTK::ClipVolume->new;
$clip->SetInput($sample->GetOutput);
$clip->SetValue(1.0);
$clip->GenerateClippedOutputOff;
$clipMapper = Graphics::VTK::DataSetMapper->new;
$clipMapper->SetInput($clip->GetOutput);
$clipMapper->ScalarVisibilityOff;
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor('.8','.4','.4');
# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($clip->GetInput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
# Define graphics objects
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->SetBackground(1,1,1);
$ren1->AddActor($clipActor);
$ren1->AddActor($outlineActor);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName clipVolume.tcl.ppm
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
