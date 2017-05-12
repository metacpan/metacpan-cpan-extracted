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
# and some nice colors
use Graphics::VTK::Colors;
# Now create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$imageIn = Graphics::VTK::PNMReader->new;
$imageIn->SetFileName("$VTK_DATA/vtks.pgm");
$imageIn->SetDataOrigin('-.5',(-(160.0 / 320.00)) / 2.0,0);
$imageIn->SetDataSpacing(1.0 / 320.00,1.0 / 320.00,1);
$imageIn->Update;
$gaussian = Graphics::VTK::ImageGaussianSmooth->new;
$gaussian->SetInput($imageIn->GetOutput);
$gaussian->SetStandardDeviations(5,5);
$gaussian->SetDimensionality(2);
$gaussian->SetRadiusFactors(2,2);
$toStructuredPoints = Graphics::VTK::ImageToStructuredPoints->new;
$toStructuredPoints->SetInput($gaussian->GetOutput);
$toStructuredPoints->Update;
$transform = Graphics::VTK::Transform->new;
$transform->Identity;
$transform->Scale('.75','.75','.75');
$transform->Inverse;
$transform->Scale(1,1,0);
$aVolume = Graphics::VTK::ImplicitVolume->new;
$aVolume->SetVolume($toStructuredPoints->GetOutput);
$aVolume->SetTransform($transform);
$aVolume->SetOutValue(256);
$aSphere = Graphics::VTK::SphereSource->new;
$aSphere->SetPhiResolution(200);
$aSphere->SetThetaResolution(200);
$aClipper = Graphics::VTK::ClipPolyData->new;
$aClipper->SetInput($aSphere->GetOutput);
$aClipper->SetValue(127.5);
$aClipper->GenerateClipScalarsOn;
$aClipper->SetClipFunction($aVolume);
$aClipper->Update;
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($aClipper->GetOutput);
$mapper->ScalarVisibilityOff;
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($mapper);
$sphereActor->SetBackfaceProperty($backProp);
$sphereActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$ren1->AddActor($sphereActor);
$ren1->GetActiveCamera->Azimuth(-20);
$ren1->GetActiveCamera->Elevation(15);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(320,320);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName clipSphereWithImage.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
