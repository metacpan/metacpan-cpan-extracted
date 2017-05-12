#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor
use Graphics::VTK::Tk::vtkInt;
$f = $open->__VTK_DATA_bpa_mol_('r');
$i = 0;
while ($gets->_f('line') >= 0)
 {
  $scan->_line("%f %f %f %f %d",$at{$i}{'x'},$at{$i}{'y'},$at{$i}{'z'},$at{$i}{'r'},$at{$i}{'t'});
  $i += 1;
 }
$close->_f;
$x = "x";
$y = "y";
$z = "z";
$natom = $i;
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$atom0 = Graphics::VTK::SphereSource->new;
$atom0->SetPhiResolution(18);
$atom0->SetThetaResolution(18);
$atom0->SetRadius(1);
$fastAtom0 = Graphics::VTK::Stripper->new;
$fastAtom0->SetInput($atom0->GetOutput);
$atom1 = Graphics::VTK::SphereSource->new;
$atom1->SetPhiResolution(18);
$atom1->SetThetaResolution(18);
$atom1->SetRadius(1);
$fastAtom1 = Graphics::VTK::Stripper->new;
$fastAtom1->SetInput($atom1->GetOutput);
$atom2 = Graphics::VTK::SphereSource->new;
$atom2->SetPhiResolution(18);
$atom2->SetThetaResolution(18);
$atom2->SetRadius(1.50);
$fastAtom2 = Graphics::VTK::Stripper->new;
$fastAtom2->SetInput($atom2->GetOutput);
$atom3 = Graphics::VTK::SphereSource->new;
$atom3->SetPhiResolution(18);
$atom3->SetThetaResolution(18);
$atom3->SetRadius(1.85);
$fastAtom3 = Graphics::VTK::Stripper->new;
$fastAtom3->SetInput($atom3->GetOutput);
$atom4 = Graphics::VTK::SphereSource->new;
$atom4->SetPhiResolution(18);
$atom4->SetThetaResolution(18);
$atom4->SetRadius(1);
$fastAtom4 = Graphics::VTK::Stripper->new;
$fastAtom4->SetInput($atom4->GetOutput);
$atom5 = Graphics::VTK::SphereSource->new;
$atom5->SetPhiResolution(18);
$atom5->SetThetaResolution(18);
$atom5->SetRadius(1.65);
$fastAtom5 = Graphics::VTK::Stripper->new;
$fastAtom5->SetInput($atom5->GetOutput);
$points = Graphics::VTK::Points->new;
$scalars = Graphics::VTK::Scalars->new;
for ($i = 0; $i < $natom; $i += 1)
 {
  $points->InsertPoint($i,$at{$i}{'x'},$at{$i}{'y'},$at{$i}{'z'});
  $scalars->InsertScalar($i,$at{$i}{'t'});
 }
$molecule = Graphics::VTK::PolyData->new;
$molecule->SetPoints($points);
$molecule->GetPointData->SetScalars($scalars);
$glyphs = Graphics::VTK::Glyph3D->new;
$glyphs->SetInput($molecule);
$glyphs->SetNumberOfSources(6);
$glyphs->SetSource(0,$fastAtom0->GetOutput);
$glyphs->SetSource(1,$fastAtom1->GetOutput);
$glyphs->SetSource(2,$fastAtom2->GetOutput);
$glyphs->SetSource(3,$fastAtom3->GetOutput);
$glyphs->SetSource(4,$fastAtom4->GetOutput);
$glyphs->SetSource(5,$fastAtom5->GetOutput);
$glyphs->SetIndexModeToScalar;
$glyphs->SetRange(0,5);
$glyphs->ScalingOff;
$lut = Graphics::VTK::LookupTable->new;
$lut->SetNumberOfColors(6);
$lut->Build;
$lut->SetTableValue(0,0,0,0,0);
$lut->SetTableValue(1,1,0,0,1);
$lut->SetTableValue(2,0,1,0,1);
$lut->SetTableValue(3,0,0,1,1);
$lut->SetTableValue(4,1,1,0,1);
$lut->SetTableValue(5,1,0,1,1);
$atommapper = Graphics::VTK::PolyDataMapper->new;
$atommapper->SetInput($glyphs->GetOutput);
$atommapper->SetScalarRange(0,5);
$atommapper->SetLookupTable($lut);
$atomprop = Graphics::VTK::Property->new;
$atomprop->SetColor(1,1,0);
$atomprop->SetDiffuse('.7');
$atomprop->SetSpecular('.5');
$atomprop->SetSpecularPower(30);
$atomactor = Graphics::VTK::Actor->new;
$atomactor->SetMapper($atommapper);
$atomactor->SetProperty($atomprop);
$ren1->AddActor($atomactor);
$ren1->GetActiveCamera->Azimuth(-60);
$ren1->GetActiveCamera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$ren1->SetBackground('.8','.8','.8');
$renWin->SetSize(400,400);
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "mole.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
