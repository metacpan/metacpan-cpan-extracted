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
# Create the RenderWindow, Renderer and Interactor
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
$extract = Graphics::VTK::ExtractGrid->new;
$extract->SetVOI(1,55,-1000,1000,-1000,1000);
$extract->SetInput($pl3d->GetOutput);
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0,4,2);
$plane->SetNormal(0,1,0);
$cutter = Graphics::VTK::Cutter->new;
$cutter->SetInput($extract->GetOutput);
$cutter->SetCutFunction($plane);
$cutter->GenerateCutScalarsOff;
$cutter->SetSortBy(1);
$clut = Graphics::VTK::LookupTable->new;
$clut->SetHueRange(0,'.67');
$clut->Build;
$cutterMapper = Graphics::VTK::PolyDataMapper->new;
$cutterMapper->SetInput($cutter->GetOutput);
$cutterMapper->SetScalarRange('.18','.7');
$cutterMapper->SetLookupTable($clut);
$cut = Graphics::VTK::Actor->new;
$cut->SetMapper($cutterMapper);
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($pl3d->GetOutput);
$iso->SetValue(0,'.22');
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($iso->GetOutput);
$normals->SetFeatureAngle(45);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($normals->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$isoActor->GetProperty->SetSpecularColor(@Graphics::VTK::Colors::white);
$isoActor->GetProperty->SetDiffuse('.8');
$isoActor->GetProperty->SetSpecular('.5');
$isoActor->GetProperty->SetSpecularPower(30);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineTubes = Graphics::VTK::TubeFilter->new;
$outlineTubes->SetInput($outline->GetOutput);
$outlineTubes->SetRadius('.1');
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outlineTubes->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$outlineActor->GetProperty->SetColor(@Graphics::VTK::Colors::banana);
$ren1->AddActor($isoActor);
$isoActor->VisibilityOn;
$ren1->AddActor($cut);
$opacity = '.06';
$cut->GetProperty->SetOpacity(1);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(640,480);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(2.7439,-37.3196,38.7167);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.16123,0.264271,0.950876);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# Cut: generates n cut planes normal to camera's view plane
#
sub Cut
{
 my $n = shift;
 # Global Variables Declared for this function: cam1, opacity
 $plane->SetNormal($cam1->GetViewPlaneNormal);
 $plane->SetOrigin($cam1->GetFocalPoint);
 $cutter->GenerateValues($n,-15,15);
 $clut->SetAlphaRange($opacity,$opacity);
 $renWin->Render;
}
# Generate 10 cut planes
Cut(10);
#renWin SetFileName "valid/combVol.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
