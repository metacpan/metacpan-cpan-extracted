#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Demonstrate automatic resampling of textures (i.e., OpenGL only handles
# power of two texture maps. This examples exercise's vtk's automatic
# power of two resampling).
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
# generate texture map (not power of two)
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(64,64);
$v16->GetOutput->SetOrigin(0.0,0.0,0.0);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("$VTK_DATA/headsq/quarter");
$v16->SetImageRange(1,93);
$v16->SetDataSpacing(3.2,3.2,1.5);
$extract = Graphics::VTK::ExtractVOI->new;
$extract->SetInput($v16->GetOutput);
$extract->SetVOI(32,32,0,63,0,93);
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($extract->GetOutput);
$atext->InterpolateOn;
# gnerate plane to map texture on to
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetXResolution(1);
$plane->SetYResolution(1);
$textureMapper = Graphics::VTK::PolyDataMapper->new;
$textureMapper->SetInput($plane->GetOutput);
$textureActor = Graphics::VTK::Actor->new;
$textureActor->SetMapper($textureMapper);
$textureActor->SetTexture($atext);
# Create the RenderWindow, Renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($textureActor);
$renWin->SetSize(250,250);
$ren1->SetBackground(0.1,0.2,0.4);
$iren->Initialize;
$renWin->SetFileName("resampledTexture.tcl.ppm");
#renWin SaveImageAsPPM
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
