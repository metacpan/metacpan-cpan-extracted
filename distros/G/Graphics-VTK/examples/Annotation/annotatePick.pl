#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates cell picking using vtkCellPicker.  It displays
# the results of picking using a vtkTextMapper.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# create a sphere source, mapper, and actor

$sphere = Graphics::VTK::SphereSource->new;

$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::LODActor->new;
$sphereActor->SetMapper($sphereMapper);

# create the spikes by glyphing the sphere with a cone.  Create the mapper
# and actor for the glyphs.
$cone = Graphics::VTK::ConeSource->new;
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($sphere->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.25);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);
$spikeActor = Graphics::VTK::LODActor->new;
$spikeActor->SetMapper($spikeMapper);

# Create a cell picker.
$picker = Graphics::VTK::CellPicker->new;
$picker->AddObserver('EndPickEvent',
 sub
  {
   annotatePick();
  }
);

# Create a text mapper and actor to display the results of picking.
$textMapper = Graphics::VTK::TextMapper->new;
$textMapper->SetFontFamilyToArial;
$textMapper->SetFontSize(10);
$textMapper->BoldOn;
$textMapper->ShadowOn;
$textActor = Graphics::VTK::Actor2D->new;
$textActor->VisibilityOff;
$textActor->SetMapper($textMapper);
$textActor->GetProperty->SetColor(1,0,0);

# Create the Renderer, RenderWindow, and RenderWindowInteractor

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$iren->SetPicker($picker);

# Add the actors to the renderer, set the background and size

$ren1->AddActor2D($textActor);
$ren1->AddActor($sphereActor);
$ren1->AddActor($spikeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);

# Get the camera and zoom in closer to the image.
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);

# Set the user method (bound to key 'u')
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

# Withdraw the default tk window
$MW->withdraw;

# Create a Tcl procedure to create the text for the text mapper used to
# display the results of picking.
#
sub annotatePick
{
 my $pickPos;
 my $selPt;
 my $x;
 my $xp;
 my $y;
 my $yp;
 my $zp;
 if ($picker->GetCellId < 0)
  {
   $textActor->VisibilityOff;

  }
 else
  {
   @selPt = $picker->GetSelectionPoint;
   $x = $selPt[0];
   $y = $selPt[1];
   @pickPos = $picker->GetPickPosition;
   $xp = $pickPos[0];
   $yp = $pickPos[1];
   $zp = $pickPos[2];

   $textMapper->SetInput("($xp, $yp, $zp)");
   $textActor->SetPosition($x,$y);
   $textActor->VisibilityOn;
  }

 $renWin->Render;
}

# Pick the cell at this location.
$picker->Pick(85,126,0,$ren1);
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
