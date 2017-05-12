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
$ps = Graphics::VTK::PointSource->new;
$ps->SetNumberOfPoints(2000);
$ps->Update;
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($ps->GetOutput);
$points = Graphics::VTK::Actor->new;
$points->SetMapper($map);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
#ren1 AddActor points
#renWin Render
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ss = Graphics::VTK::SphereSource->new;
$ss->SetRadius(0.02);
$pd = Graphics::VTK::PolyData->new;
$pts = Graphics::VTK::Points->new;
$pd->SetPoints($pts);
$gly = Graphics::VTK::Glyph3D->new;
$gly->SetSource($ss->GetOutput);
$gly->SetInput($pd);
$ssmap = Graphics::VTK::PolyDataMapper->new;
$ssmap->SetInput($gly->GetOutput);
$ssact = Graphics::VTK::Actor->new;
$ssact->SetMapper($ssmap);
$ssact->GetProperty->SetColor(1,0.3,1);
$bmap = Graphics::VTK::PolyDataMapper->new;
$bmap->SetInput($ss->GetOutput);
$ba = Graphics::VTK::Actor->new;
$ba->SetMapper($bmap);
$ba->GetProperty->SetColor(0.5,1,0.5);
$ba->SetScale(1.1,1.1,1.1);
$ren1->AddActor($ssact);
$ren1->AddActor($ba);
$pl = Graphics::VTK::PointLocator2D->new;
$pl->SetDataSet($ps->GetOutput);
$idl = Graphics::VTK::IdList->new;
$loc = '0.3 0.3 0.3';
$ba->SetPosition($loc);
$pl->FindPointsWithinRadius(0.1,$loc[0],$loc[1],$idl);
$pts->Reset;
for ($i = 0; $i < $idl->GetNumberOfIds; $i += 1)
 {
  $pts->InsertNextPoint($ps->GetOutput->GetPoints->GetPoint($idl->GetId($i)));
 }
$pd->Modified;
$ren1->GetActiveCamera->Zoom(1.7);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
