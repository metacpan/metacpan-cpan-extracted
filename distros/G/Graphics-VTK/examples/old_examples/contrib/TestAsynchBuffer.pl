#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# this example uses AsynchornousBuffer to allow interaction while
# an iso surface is being computed.  A tempory low resolution object
# is created as a stand in.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$lgt = Graphics::VTK::Light->new;
# create pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,127,0,127,1,93);
$reader->SetFilePrefix("$VTK_DATA/headsq/half");
$reader->SetDataSpacing(1.6,1.6,1.5);
$iso = Graphics::VTK::ImageMarchingCubes->new;
$iso->SetInput($reader->GetOutput);
$iso->SetValue(0,1150);
$iso->ComputeNormalsOn;
$iso->ComputeScalarsOff;
$gradient = Graphics::VTK::VectorNorm->new;
$gradient->SetInput($iso->GetOutput);
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(68);
$sphere->SetCenter(100,100,69);
$buf = Graphics::VTK::AsynchronousBuffer->new;
$buf->SetInput($sphere->GetOutput);
$buf->Update;
$buf->SetInput($iso->GetOutput);
$buf->BlockingOff;
$isoMapper = Graphics::VTK::DataSetMapper->new;
$isoMapper->SetInput($buf->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoMapper->SetScalarRange(0,1200);
$isoMapper->ImmediateModeRenderingOn;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoProp = $isoActor->GetProperty;
$isoProp->SetColor(@Graphics::VTK::Colors::antique_white);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
#eval $outlineProp SetColor 0 0 0
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$ren1->AddLight($lgt);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(90);
$cam1->SetViewUp(0,0,-1);
$cam1->Zoom(1.3);
$lgt->SetPosition($cam1->GetPosition);
$lgt->SetFocalPoint($cam1->GetFocalPoint);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$iren->Initialize;
#renWin SetFileName "TestAsynchBuffer.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
