#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create selected cones
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA/carotid.vtk");
$threshold = Graphics::VTK::ThresholdPoints->new;
$threshold->SetInput($reader->GetOutput);
$threshold->ThresholdByUpper(200);
$mask = Graphics::VTK::MaskPoints->new;
$mask->SetInput($threshold->GetOutput);
$mask->SetOnRatio(10);
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(3);
$cone->SetHeight(1);
$cone->SetRadius(0.25);
$cones = Graphics::VTK::Glyph3D->new;
$cones->SetInput($mask->GetOutput);
$cones->SetSource($cone->GetOutput);
$cones->SetScaleFactor(0.5);
$cones->SetScaleModeToScaleByVector;
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange('.667',0.0);
$lut->Build;
$vecMapper = Graphics::VTK::PolyDataMapper->new;
$vecMapper->SetInput($cones->GetOutput);
$vecMapper->SetScalarRange(2,10);
$vecMapper->SetLookupTable($lut);
$vecActor = Graphics::VTK::Actor->new;
$vecActor->SetMapper($vecMapper);
# contours of speed
$iso = Graphics::VTK::MarchingContourFilter->new;
$iso->SetInput($reader->GetOutput);
$iso->SetValue(0,190);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetRepresentationToWireframe;
$isoActor->GetProperty->SetOpacity(0.25);
# outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($vecActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
#renWin SetSize 1000 1000
$ren1->SetBackground(0.1,0.2,0.4);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "thrshldV.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
