#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Test the programmable glyph filter
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
$res = 6;
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetResolution($res,$res);
$colors = Graphics::VTK::ElevationFilter->new;
$colors->SetInput($plane->GetOutput);
$colors->SetLowPoint(-0.25,-0.25,-0.25);
$colors->SetHighPoint(0.25,0.25,0.25);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($colors->GetPolyDataOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->GetProperty->SetRepresentationToWireframe;
# create simple poly data so we can apply glyph
$squad = Graphics::VTK::SuperquadricSource->new;
$glypher = Graphics::VTK::ProgrammableGlyphFilter->new;
$glypher->SetInput($colors->GetOutput);
$glypher->SetSource($squad->GetOutput);
$glypher->SetGlyphMethod(
 sub
  {
   Glyph();
  }
);
$glyphMapper = Graphics::VTK::PolyDataMapper->new;
$glyphMapper->SetInput($glypher->GetOutput);
$glyphActor = Graphics::VTK::Actor->new;
$glyphActor->SetMapper($glyphMapper);
# procedure for generating glyphs
#
sub Glyph
{
 my $length;
 my $pd;
 my $ptId;
 my $scale;
 my $x;
 my $xyz;
 my $y;
 # Global Variables Declared for this function: res
 $ptId = $glypher->GetPointId;
 $pd = $glypher->GetPointData;
 $xyz = $glypher->GetPoint;
 $x = $xyz[0];
 $y = $xyz[1];
 $length = $glypher->GetInput->GetLength;
 $scale = $length / (2.0 * $res);
 $squad->SetScale($scale,$scale,$scale);
 $squad->SetCenter($xyz);
 $squad->SetPhiRoundness(abs($x) * 5.0);
 $squad->SetThetaRoundness(abs($y) * 5.0);
}
# Create the rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($planeActor);
$ren1->AddActor($glyphActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(450,450);
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.5);
# Get handles to some useful objects
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetFileName("progGlyphs.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
