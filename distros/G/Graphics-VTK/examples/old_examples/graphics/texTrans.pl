#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Test the texture transformation object
# Get the interactor
use Graphics::VTK::Tk::vtkInt;
# load in the texture map
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/masonry.ppm");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
# create a plane source and actor
$plane = Graphics::VTK::PlaneSource->new;
$trans = Graphics::VTK::TransformTextureCoords->new;
$trans->SetInput($plane->GetOutput);
$trans->SetScale(2,3,1);
$trans->FlipSOn;
$trans->SetPosition(0.5,1.0,0.0);
#need to do this because of non-zero origin
$planeMapper = Graphics::VTK::DataSetMapper->new;
$planeMapper->SetInput($trans->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->SetTexture($atext);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetSize(500,500);
$renWin->Render;
#renWin SetFileName "texTrans.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
