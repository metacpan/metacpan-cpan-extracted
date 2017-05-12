#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# this demonstrates appending data to generate an implicit model
# contrast this with appendImplicitModel.tcl which set the bounds
# explicitly. this scrip should produce the same results.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$cubeForBounds = Graphics::VTK::CubeSource->new;
$cubeForBounds->SetBounds(-2.5,2.5,-2.5,2.5,-2.5,2.5);
$cubeForBounds->Update;
$lineX = Graphics::VTK::LineSource->new;
$lineX->SetPoint1(-2.0,0.0,0.0);
$lineX->SetPoint2(2.0,0.0,0.0);
$lineX->Update;
$lineY = Graphics::VTK::LineSource->new;
$lineY->SetPoint1(0.0,-2.0,0.0);
$lineY->SetPoint2(0.0,2.0,0.0);
$lineY->Update;
$lineZ = Graphics::VTK::LineSource->new;
$lineZ->SetPoint1(0.0,0.0,-2.0);
$lineZ->SetPoint2(0.0,0.0,2.0);
$lineZ->Update;
$aPlane = Graphics::VTK::PlaneSource->new;
$aPlane->Update;
$Data{3} = "lineX";
$Data{1} = "lineY";
$Data{2} = "lineZ";
$Data{0} = "aPlane";
$imp = Graphics::VTK::ImplicitModeller->new;
$imp->SetSampleDimensions(100,100,100);
$imp->SetCapValue(1000);
$imp->ComputeModelBounds($cubeForBounds->GetOutput);
# Okay now let's see if we can append
$imp->StartAppend;
for ($i = 0; $i < 4; $i += 1)
 {
  $imp->Append($Data{$i}->GetOutput);
 }
$imp->EndAppend;
$cf = Graphics::VTK::ContourFilter->new;
$cf->SetInput($imp->GetOutput);
$cf->SetValue(0,0.1);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($cf->GetOutput);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($imp->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$plane = Graphics::VTK::StructuredPointsGeometryFilter->new;
$plane->SetInput($imp->GetOutput);
$plane->SetExtent(0,100,0,100,50,50);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($plane->GetOutput);
$planeMapper->SetScalarRange(0.197813,0.710419);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
# graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$ren1->AddActor($actor);
$ren1->AddActor($planeActor);
$ren1->AddActor($outlineActor);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->SetBackground(0.1,0.2,0.4);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(30);
$ren1->ResetCameraClippingRange;
$renWin->Render;
#renWin SetFileName appendImplicitModelNoBounds.tcl.ppm
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
