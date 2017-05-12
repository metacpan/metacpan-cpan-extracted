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
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$plane = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane->SetInput($pl3d->GetOutput);
$plane->SetExtent(10,10,1,100,1,100);
$plane2 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane2->SetInput($pl3d->GetOutput);
$plane2->SetExtent(30,30,1,100,1,100);
$plane3 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane3->SetInput($pl3d->GetOutput);
$plane3->SetExtent(45,45,1,100,1,100);
$appendF = Graphics::VTK::AppendPolyData->new;
$appendF->AddInput($plane->GetOutput);
$appendF->AddInput($plane2->GetOutput);
$appendF->AddInput($plane3->GetOutput);
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($appendF->GetOutput);
$warp->SetScaleFactor(0.005);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($warp->GetPolyDataOutput);
$normals->SetFeatureAngle(60);
$planeMapper = Graphics::VTK::DataSetMapper->new;
$planeMapper->SetInput($normals->GetOutput);
$planeMapper->SetScalarRange(0.197813,0.710419);
$planeMapper->ScalarVisibilityOff;
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeProp = $planeActor->GetProperty;
$planeProp->SetColor(@Graphics::VTK::Colors::salmon);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(@Graphics::VTK::Colors::black);
$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$iren->Initialize;
$ren1->GetActiveCamera->Zoom(1.4);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "velProf.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
