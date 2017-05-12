#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate marching cubes pine root model (256^3 model)
# get the interactor ui and colors
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(256,256);
$v16->SetDataByteOrderToBigEndian;
$v16->SetFilePrefix("$VTK_DATA/pineRoot/pine_root");
$v16->SetImageRange(50,100);
$v16->SetDataSpacing(0.3125,0.3125,0.390625);
$v16->SetDataMask(0x7fff);
$mcubes = Graphics::VTK::SliceCubes->new;
$mcubes->SetReader($v16);
$mcubes->SetValue(1750);
$mcubes->SetFileName("pine_root.tri");
$mcubes->SetLimitsFileName("pine_root.lim");
$mcubes->Update;
$reader = Graphics::VTK::MCubesReader->new;
$reader->SetFileName("pine_root.tri");
$reader->SetLimitsFileName("pine_root.lim");
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($reader->GetOutput);
$a = Graphics::VTK::Actor->new;
$a->SetMapper($mapper);
$a->GetProperty->SetColor(@Graphics::VTK::Colors::raw_sienna);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($a);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground($slate_grey);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "valid/genPineRoot.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
