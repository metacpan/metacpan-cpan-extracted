#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# cut an outer sphere to reveal an inner sphere
# converted from tcutSph.cxx
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow  Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# hidden sphere
$sphere1 = Graphics::VTK::SphereSource->new;
$sphere1->SetThetaResolution(12);
$sphere1->SetPhiResolution(12);
$sphere1->SetRadius(0.5);
$innerMapper = Graphics::VTK::PolyDataMapper->new;
$innerMapper->SetInput($sphere1->GetOutput);
$innerSphere = Graphics::VTK::Actor->new;
$innerSphere->SetMapper($innerMapper);
$innerSphere->GetProperty->SetColor(1,'.9216','.8039');
# sphere to texture
$sphere2 = Graphics::VTK::SphereSource->new;
$sphere2->SetThetaResolution(24);
$sphere2->SetPhiResolution(24);
$sphere2->SetRadius(1.0);
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,0,0,0);
$points->InsertPoint(1,0,0,0);
$normals = Graphics::VTK::Normals->new;
$normals->InsertNormal(0,1,0,0);
$normals->InsertNormal(1,0,1,0);
$planes = Graphics::VTK::Planes->new;
$planes->SetPoints($points);
$planes->SetNormals($normals);
$tcoords = Graphics::VTK::ImplicitTextureCoords->new;
$tcoords->SetInput($sphere2->GetOutput);
$tcoords->SetRFunction($planes);
$outerMapper = Graphics::VTK::DataSetMapper->new;
$outerMapper->SetInput($tcoords->GetOutput);
$tmap = Graphics::VTK::StructuredPointsReader->new;
$tmap->SetFileName("$VTK_DATA/texThres.vtk");
$texture = Graphics::VTK::Texture->new;
$texture->SetInput($tmap->GetOutput);
$texture->InterpolateOff;
$texture->RepeatOff;
$outerSphere = Graphics::VTK::Actor->new;
$outerSphere->SetMapper($outerMapper);
$outerSphere->SetTexture($texture);
$outerSphere->GetProperty->SetColor(1,'.6275','.4784');
$ren1->AddActor($innerSphere);
$ren1->AddActor($outerSphere);
$ren1->SetBackground(0.4392,0.5020,0.5647);
$renWin->SetSize(500,500);
# interact with data
$renWin->Render;
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "tcutSph.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
