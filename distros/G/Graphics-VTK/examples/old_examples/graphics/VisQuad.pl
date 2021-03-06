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
# Quadric definition
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(30,30,30);
$sample->SetImplicitFunction($quadric);
$sample->Update;
$sample->Print;
# Create five surfaces F(x,y,z) = constant between range specified
$contours = Graphics::VTK::ContourFilter->new;
$contours->SetInput($sample->GetOutput);
$contours->GenerateValues(5,0.0,1.2);
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
$ren1->SetBackground(1,1,1);
$ren1->AddActor($contActor);
$ren1->AddActor($outlineActor);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName VisQuad.tcl.ppm
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
