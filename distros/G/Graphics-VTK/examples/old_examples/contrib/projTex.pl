#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate texture coordinates on a "random" sphere.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$cyber = Graphics::VTK::PolyDataReader->new;
$cyber->SetFileName("$VTK_DATA/fran_cut.vtk");
$tmapper = Graphics::VTK::ProjectedTexture->new;
$tmapper->SetPosition(0,0.0,1.2);
$tmapper->SetFocalPoint(0,0,0);
$tmapper->SetAspectRatio(1.2,0.7,1);
$tmapper->SetSRange(0.25,1.25);
$tmapper->SetInput($cyber->GetOutput);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($tmapper->GetOutput);
# load in the texture map and assign to actor
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/earth.ppm");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
$atext->RepeatOn;
$triangulation = Graphics::VTK::Actor->new;
$triangulation->SetMapper($mapper);
# Create rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($triangulation);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam = $ren1->GetActiveCamera;
$ren1->ResetCamera;
$cam->Azimuth(130);
$cam->Dolly(1.3);
$ren1->ResetCameraClippingRange;
$Pos = $cam->GetPosition;
$FP = $cam->GetFocalPoint;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$triangulation->SetTexture($atext);
$tmapper->SetPosition($Pos);
$tmapper->SetUp($cam->GetViewUp);
$tmapper->SetFocalPoint($FP);
$iren->Initialize;
#ren1 SetStartRenderMethod move
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName projTex.tcl.ppm
#renWin SaveImageAsPPM
#
sub move
{
 my $cam;
 $cam = $ren1->GetActiveCamera;
 $tmapper->SetPosition($cam->GetPosition);
 $tmapper->SetUp($cam->GetViewUp);
 $tmapper->SetFocalPoint($cam->GetFocalPoint);
}
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
