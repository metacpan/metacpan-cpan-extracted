#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# extract data
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(50,50,50);
$sample->SetImplicitFunction($quadric);
$sample->ComputeNormalsOff;
$trans = Graphics::VTK::Transform->new;
$trans->Scale(1,'.5','.333');
$sphere = Graphics::VTK::Sphere->new;
$sphere->SetRadius(0.25);
$sphere->SetTransform($trans);
$trans2 = Graphics::VTK::Transform->new;
$trans2->Scale('.25','.5',1.0);
$sphere2 = Graphics::VTK::Sphere->new;
$sphere2->SetRadius(0.25);
$sphere2->SetTransform($trans2);
$union = Graphics::VTK::ImplicitBoolean->new;
$union->AddFunction($sphere);
$union->AddFunction($sphere2);
$union->SetOperationType(0);
#union
$extract = Graphics::VTK::ExtractGeometry->new;
$extract->SetInput($sample->GetOutput);
$extract->SetImplicitFunction($union);
$shrink = Graphics::VTK::ShrinkFilter->new;
$shrink->SetInput($extract->GetOutput);
$shrink->SetShrinkFactor(0.5);
$dataMapper = Graphics::VTK::DataSetMapper->new;
$dataMapper->SetInput($shrink->GetOutput);
$dataActor = Graphics::VTK::Actor->new;
$dataActor->SetMapper($dataMapper);
# outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($dataActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "valid/extractD.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
