#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version: tests polygonal planes
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetResolution(4,5);
$plane->SetOrigin(0,0,1);
$plane->SetPoint1(2,0,1);
$plane->SetPoint2(0,3,1);
$plane->SetCenter(3,2,1);
$plane->SetNormal(0,0,1);
$plane->SetNormal(1,2,3);
$plane->Update;
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($plane->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->GetProperty->SetRepresentationToWireframe;
# create simple poly data so we can apply glyph
$pts = Graphics::VTK::Points->new;
$pts->InsertPoint(0,$plane->GetCenter);
$normal = Graphics::VTK::Normals->new;
$normal->InsertNormal(0,$plane->GetNormal);
$pd = Graphics::VTK::PolyData->new;
$pd->SetPoints($pts);
$pd->GetPointData->SetNormals($normal);
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);
$transform = Graphics::VTK::Transform->new;
$transform->Scale('.2','.2','.2');
$transform->Translate(0.5,0.0,0.0);
$transformF = Graphics::VTK::TransformPolyDataFilter->new;
$transformF->SetInput($cone->GetOutput);
$transformF->SetTransform($transform);
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($pd);
$glyph->SetSource($transformF->GetOutput);
$glyph->SetVectorModeToUseNormal;
$mapGlyph = Graphics::VTK::PolyDataMapper->new;
$mapGlyph->SetInput($glyph->GetOutput);
$glyphActor = Graphics::VTK::Actor->new;
$glyphActor->SetMapper($mapGlyph);
$glyphActor->GetProperty->SetColor(1,0,0);
# Create the rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($planeActor);
$ren1->AddActor($glyphActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(450,450);
# Get handles to some useful objects
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "plane.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
