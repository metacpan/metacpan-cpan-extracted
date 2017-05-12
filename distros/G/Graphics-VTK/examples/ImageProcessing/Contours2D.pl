#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Quadric definition
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);

$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(30,30,30);
$sample->SetImplicitFunction($quadric);
$sample->ComputeNormalsOff;

$extract = Graphics::VTK::ExtractVOI->new;
$extract->SetInput($sample->GetOutput);
$extract->SetVOI(0,29,0,29,15,15);
$extract->SetSampleRate(1,2,3);

$contours = Graphics::VTK::ContourFilter->new;
$contours->SetInput($extract->GetOutput);
$contours->GenerateValues(13,0.0,1.2);

$contMapper = Graphics::VTK::PolyDataMapper->new;
$contMapper->SetInput($contours->GetOutput);
$contMapper->SetScalarRange(0.0,1.2);

$contActor = Graphics::VTK::Actor->new;
$contActor->SetMapper($contMapper);

# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);

$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);

$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);

# create graphics objects
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

$ren1->SetBackground(1,1,1);
$ren1->AddActor($contActor);
$ren1->AddActor($outlineActor);

$ren1->GetActiveCamera->Zoom(1.5);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

#renWin SetFileName MSquares.tcl.ppm
#renWin SaveImageAsPPM

$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
