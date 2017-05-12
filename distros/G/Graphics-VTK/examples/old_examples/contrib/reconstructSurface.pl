#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Demonstrates the use of surface reconstruction
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Read some points. Use a programmable filter to read them.
$pointSource = Graphics::VTK::ProgrammableSource->new;
$pointSource->SetExecuteMethod(
 sub
  {
   readPoints();
  }
);
#
sub readPoints
{
 my $file;
 my $gets;
 my $open;
 my $output;
 my $points;
 my $scan;
 # Global Variables Declared for this function: VTK_DATA
 $output = $pointSource->GetPolyDataOutput;
 $points = Graphics::VTK::Points->new;
 $output->SetPoints($points);
 #   set file [open "$VTK_DATA/SampledPoints/club71.16864.pts" r]
 $file = $open->__VTK_DATA_SampledPoints_cactus_3337_pts_('r');
 while ($gets->_file('line') != -1)
  {
   $scan->_line("%s",'firstToken');
   if ($firstToken eq "p")
    {
     $scan->_line("%s %f %f %f",'firstToken','x','y','z');
     $points->InsertNextPoint($x,$y,$z);
    }
  }

 #okay, reference counting
}
# Construct the surface and create isosurface
$surf = Graphics::VTK::SurfaceReconstructionFilter->new;
$surf->SetInput($pointSource->GetPolyDataOutput);
$cf = Graphics::VTK::ContourFilter->new;
$cf->SetInput($surf->GetOutput);
$cf->SetValue(0,0.0);
$reverse = Graphics::VTK::ReverseSense->new;
$reverse->SetInput($cf->GetOutput);
$reverse->ReverseCellsOn;
$reverse->ReverseNormalsOn;
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($reverse->GetOutput);
$map->ScalarVisibilityOff;
$surfaceActor = Graphics::VTK::Actor->new;
$surfaceActor->SetMapper($map);
$surfaceActor->GetProperty->SetDiffuseColor(1.0000,0.3882,0.2784);
$surfaceActor->GetProperty->SetSpecularColor(1,1,1);
$surfaceActor->GetProperty->SetSpecular('.4');
$surfaceActor->GetProperty->SetSpecularPower(50);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($surfaceActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->GetActiveCamera->SetFocalPoint(0,0,0);
$ren1->GetActiveCamera->SetPosition(1,0,0);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->GetActiveCamera->SetViewUp(0,0,1);
$ren1->ResetCamera;
$ren1->GetActiveCamera->Azimuth(20);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetFileName('reconstructSurface.tcl.ppm');
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
