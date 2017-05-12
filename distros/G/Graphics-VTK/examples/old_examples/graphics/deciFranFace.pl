#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of old franFace
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$ren2 = Graphics::VTK::Renderer->new;
$ren3 = Graphics::VTK::Renderer->new;
$ren4 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$renWin->AddRenderer($ren3);
$renWin->AddRenderer($ren4);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$pnm1 = Graphics::VTK::PNMReader->new;
$pnm1->SetFileName("$VTK_DATA/fran_cut.ppm");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($pnm1->GetOutput);
$atext->InterpolateOn;
# create a cyberware source
$cyber = Graphics::VTK::PolyDataReader->new;
$cyber->SetFileName("$VTK_DATA/fran_cut.vtk");
$topologies = "On Off";
$accumulates = "On Off";
foreach $topology ($topologies)
 {
  foreach $accumulate ($accumulates)
   {
    $deci{$topology} = Graphics::VTK::DecimatePro->new($accumulate);
    $deci{$topology}->_accumulate('SetInput',$cyber->GetOutput);
    $deci{$topology}->_accumulate('SetTargetReduction','.99');
    $deci{$topology}->_accumulate($PreserveTopology{$topology});
    $deci{$topology}->_accumulate($AccumulateError{$accumulate});
    $mapper{$topology} = Graphics::VTK::PolyDataMapper->new($accumulate);
    $mapper{$topology}->_accumulate('SetInput',$deci{$topology}->_accumulate('GetOutput'));
    $fran{$topology} = Graphics::VTK::Actor->new($accumulate);
    $fran{$topology}->_accumulate('SetMapper',$mapper{$topology},$accumulate);
    $fran{$topology}->_accumulate('SetTexture',$atext);
   }
 }
# Add the actors to the renderer, set the background and size
$ren1->SetViewport(0,'.5','.5',1);
$ren2->SetViewport('.5','.5',1,1);
$ren3->SetViewport(0,0,'.5','.5');
$ren4->SetViewport('.5',0,1,'.5');
$ren1->AddActor('franOnOn');
$ren2->AddActor('franOnOff');
$ren3->AddActor('franOffOn');
$ren4->AddActor('franOffOff');
$camera = Graphics::VTK::Camera->new;
$ren1->SetActiveCamera($camera);
$ren2->SetActiveCamera($camera);
$ren3->SetActiveCamera($camera);
$ren4->SetActiveCamera($camera);
$ren1->GetActiveCamera->SetPosition(0.314753,-0.0699988,-0.264225);
$ren1->GetActiveCamera->SetFocalPoint(0.00188636,-0.136847,'-5.84226e-09');
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->SetViewUp(0,1,0);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCameraClippingRange;
$ren2->ResetCameraClippingRange;
$ren3->ResetCameraClippingRange;
$ren4->ResetCameraClippingRange;
$ren1->SetBackground(1,1,1);
$ren2->SetBackground(1,1,1);
$ren3->SetBackground(1,1,1);
$ren4->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("deciFranFace.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
