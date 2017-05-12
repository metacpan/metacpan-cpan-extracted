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
# Create ren1dering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# ingest data file
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/vtk.vtk");
# create implicit model of vtk
$imp = Graphics::VTK::ImplicitModeller->new;
$imp->SetInput($reader->GetOutput);
$imp->SetSampleDimensions(50,50,40);
$imp->SetMaximumDistance(0.25);
$imp->SetAdjustDistance(0.5);
# create swept surface
$transforms = Graphics::VTK::TransformCollection->new;
$t1 = Graphics::VTK::Transform->new;
$t1->Identity;
$t2 = Graphics::VTK::Transform->new;
$t2->Translate(0,0,2.5);
$t2->RotateZ(90.0);
$transforms->AddItem($t1);
$transforms->AddItem($t2);
$sweptSurfaceFilter = Graphics::VTK::SweptSurface->new;
$sweptSurfaceFilter->SetInput($imp->GetOutput);
$sweptSurfaceFilter->SetTransforms($transforms);
$sweptSurfaceFilter->SetSampleDimensions(100,70,40);
$sweptSurfaceFilter->SetNumberOfInterpolationSteps(20);
$iso = Graphics::VTK::MarchingContourFilter->new;
$iso->SetInput($sweptSurfaceFilter->GetOutput);
$iso->SetValue(0,0.33);
$sweptSurfaceMapper = Graphics::VTK::PolyDataMapper->new;
$sweptSurfaceMapper->SetInput($iso->GetOutput);
$sweptSurfaceMapper->ScalarVisibilityOff;
$sweptSurface = Graphics::VTK::Actor->new;
$sweptSurface->SetMapper($sweptSurfaceMapper);
$sweptSurface->GetProperty->SetColor(0.2510,0.8784,0.8157);
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
#renWin SetFileName "sweptVtk.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
