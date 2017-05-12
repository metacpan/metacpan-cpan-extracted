#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# ingest data file
$reader = Graphics::VTK::UGFacetReader->new;
$reader->SetFileName("$VTK_DATA/bolt.fac");
$reader->MergingOff;
# create implicit model of vtk
$imp = Graphics::VTK::ImplicitModeller->new;
$imp->SetInput($reader->GetOutput);
$imp->SetSampleDimensions(25,25,50);
$imp->SetMaximumDistance(0.33);
$imp->SetAdjustDistance(0.75);
# create swept surface
$math = Graphics::VTK::Math->new;
$transforms = Graphics::VTK::TransformCollection->new;
$t1 = Graphics::VTK::Transform->new;
$t1->Identity;
$transforms->AddItem($t1);
for ($i = 2; $i <= 10; $i += 1)
 {
  $t{$i} = Graphics::VTK::Transform->new;
  $t{$i}->Translate($math->Random(-4,4),$math->Random(-4,4),$math->Random(-4,4));
  $t{$i}->RotateZ($math->Random(-180,180));
  $t{$i}->RotateX($math->Random(-180,180));
  $t{$i}->RotateY($math->Random(-180,180));
  $transforms->AddItem($t{$i});
 }
$sweptSurfaceFilter = Graphics::VTK::SweptSurface->new;
$sweptSurfaceFilter->SetInput($imp->GetOutput);
$sweptSurfaceFilter->SetTransforms($transforms);
$sweptSurfaceFilter->SetSampleDimensions(100,100,100);
$sweptSurfaceFilter->SetNumberOfInterpolationSteps(0);
$sweptSurfaceFilter->SetMaximumNumberOfInterpolationSteps(80);
$sweptSurfaceFilter->CappingOff;
$iso = Graphics::VTK::MarchingContourFilter->new;
$iso->SetInput($sweptSurfaceFilter->GetOutput);
$iso->SetValue(0,0.075);
$sweptSurfaceMapper = Graphics::VTK::PolyDataMapper->new;
$sweptSurfaceMapper->SetInput($iso->GetOutput);
$sweptSurfaceMapper->ScalarVisibilityOff;
$sweptSurface = Graphics::VTK::Actor->new;
$sweptSurface->SetMapper($sweptSurfaceMapper);
$sweptSurface->GetProperty->SetDiffuseColor(0.2510,0.8784,0.8157);
$ren1->AddActor($sweptSurface);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;
#renWin SetFileName "sweptAuto.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
