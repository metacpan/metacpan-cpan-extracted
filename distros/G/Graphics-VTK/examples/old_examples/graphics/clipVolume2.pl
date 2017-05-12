#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Example demonstrates how to generate a 3D tetrahedra mesh from a volume. This example
# differs from clipVolume.tcl in that the mesh is generated within a range of contour
# values.
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
# Program a bandpass filter to clip a range of data. What we do is transform the 
# scalars so that values lying betweeen (minRange,maxRange) are >= 0.0; all 
# others are < 0.0,
$dataset = Graphics::VTK::ImplicitDataSet->new;
$dataset->SetDataSet($sample->GetOutput);
$window = Graphics::VTK::ImplicitWindowFunction->new;
$window->SetImplicitFunction($dataset);
$window->SetWindowRange(0.5,1.0);
# Generate tetrahedral mesh
$clip = Graphics::VTK::ClipVolume->new;
$clip->SetInput($sample->GetOutput);
$clip->SetClipFunction($window);
$clip->SetValue(0.0);
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
#renWin SetFileName clipVolume2.tcl.ppm
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
