#!/usr/local/bin/perl -w
#
use Graphics::VTK;

### Example of using the Pipeline browser #####


use Tk;
use Graphics::VTK::Tk;

use Graphics::VTK::Pipeline;

$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# user interface command widget
use Graphics::VTK::Tk::vtkInt;
# create a rendering window and renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->StereoCapableWindowOn;
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create an actor and give it cone geometry
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(8);
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
# assign our actor to the renderer
$ren1->AddActor($coneActor);
# enable user interface interactor
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Graphics::VTK::Pipeline::show($renWin);


Tk->MainLoop;
