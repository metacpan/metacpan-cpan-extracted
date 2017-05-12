#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of clipping on polygonal data
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create pipeline
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(1);
$sphere->SetPhiResolution(50);
$sphere->SetThetaResolution(50);
#vtkPlaneSource sphere
#    sphere SetXResolution 10
#    sphere SetYResolution 25
#vtkConeSource sphere
#    sphere SetResolution 10
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0.25,0,0);
$plane->SetNormal(-1,-1,0);
$iwf = Graphics::VTK::ImplicitWindowFunction->new;
$iwf->SetImplicitFunction($plane);
$iwf->SetWindowRange('-.2','.2');
$iwf->SetWindowValues(0,1);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($sphere->GetOutput);
$clipper->SetClipFunction($iwf);
$clipper->SetValue(0.0);
$clipper->GenerateClipScalarsOn;
$clipMapper = Graphics::VTK::DataSetMapper->new;
$clipMapper->SetInput($clipper->GetOutput);
$clipMapper->ScalarVisibilityOff;
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($clipActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,400);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("clipSphere2.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
