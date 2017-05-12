#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#   Clip Actor with Spherical Lens
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
#
sub mkname
{
 my $a = shift;
 my $b = shift;
 my $return;
 return ($a,$b);
}
# proc to make actors
# create pipeline
#
sub MakeActor
{
 my $name = shift;
 my $r = shift;
 my $g = shift;
 my $b = shift;
 my $actor;
 my $filename;
 my $mapper;
 my $mkname;
 my $reader;
 my $return;
 $filename = mkname($name,'.vtk');
 $reader = mkname($name,'PolyDataReader');
 $reader = Graphics::VTK::PolyDataReader->new;
 $reader->SetFileName($filename);
 $mapper = mkname($name,'PolyDataMapper');
 $mapper = Graphics::VTK::PolyDataMapper->new;
 $mapper->SetInput($reader->GetOutput);
 $mapper->ScalarVisibilityOff;
 $mapper->ImmediateModeRenderingOn;
 $actor = mkname($name,'Actor');
 $actor = Graphics::VTK::Actor->new;
 $actor->SetMapper($mapper);
 $actor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::r,$g,$b);
 $actor->GetProperty->SetSpecularPower(50);
 $actor->GetProperty->SetSpecular('.5');
 $actor->GetProperty->SetDiffuse('.8');
 return $actor;
}
# Now create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor(MakeActor($VTK_DATA,'/skin',$flesh));
$x = 0;
$y = 70;
$z = -70;
$r = 30;
# make a base plane
$basePlane = Graphics::VTK::PlaneSource->new;
$basePlane->SetOrigin(-102.4,139.5,-102.4);
$basePlane->SetPoint1(101.6,139.5,-102.4);
$basePlane->SetPoint2(-102.4,139.5,101.6);
$baseMapper = Graphics::VTK::PolyDataMapper->new;
$baseMapper->SetInput($basePlane->GetOutput);
$base = Graphics::VTK::Actor->new;
$base->SetMapper($baseMapper);
$ren1->AddActor($base);
# make the geometry for a lens
$lensSource = Graphics::VTK::SphereSource->new;
$lensSource->SetRadius($r);
$lensSource->SetCenter($x,$y,$z);
$lensSource->SetThetaResolution(256);
$lensSource->SetPhiResolution(256);
$lensGeometryMapper = Graphics::VTK::PolyDataMapper->new;
$lensGeometryMapper->SetInput($lensSource->GetOutput);
$lensGeometryMapper->ImmediateModeRenderingOn;
$lensGeometry = Graphics::VTK::Actor->new;
$lensGeometry->SetMapper($lensGeometryMapper);
$lensGeometry->VisibilityOff;
# read the volume
$RESOLUTION = 256;
$START_SLICE = 1;
$END_SLICE = 93;
$PIXEL_SIZE = '.8';
$origin = ($RESOLUTION / 2.0) * $PIXEL_SIZE * -1.0;
$SLICE_ORDER = 'si';
#source $VTK_TCL/frog/SliceOrder.tcl
$reader = Graphics::VTK::Volume16Reader->new;
$reader->SetDataDimensions($RESOLUTION,$RESOLUTION);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataSpacing($PIXEL_SIZE,$PIXEL_SIZE,1.5);
$reader->SetDataOrigin($origin,$origin,1.5);
$reader->SetImageRange($START_SLICE,$END_SLICE);
$reader->SetTransform('si');
$reader->SetHeaderSize(0);
$reader->SetDataMask(0x7fff);
$reader->SetDataByteOrderToLittleEndian;
$reader->Update;
$aVolumeModel = Graphics::VTK::ImplicitVolume->new;
$aVolumeModel->SetVolume($reader->GetOutput);
$aVolumeModel->SetOutValue(0);
# clip the lens geometry
$lensClipper = Graphics::VTK::ClipPolyData->new;
$lensClipper->SetInput($lensSource->GetOutput);
$lensClipper->SetClipFunction($aVolumeModel);
$lensClipper->SetValue(600.5);
$lensClipper->GenerateClipScalarsOn;
$lensClipper->GenerateClippedOutputOff;
$lensClipper->Update;
$wlLut = Graphics::VTK::WindowLevelLookupTable->new;
$wlLut->SetWindow(1000);
$wlLut->SetLevel(1200);
$wlLut->SetTableRange(0,2047);
$wlLut->Build;
$lensMapper = Graphics::VTK::PolyDataMapper->new;
$lensMapper->SetInput($lensClipper->GetOutput);
$lensMapper->SetScalarRange(0,2047);
$lensMapper->SetLookupTable($wlLut);
$lensMapper->ScalarVisibilityOn;
$lens = Graphics::VTK::Actor->new;
$lens->SetMapper($lensMapper);
# clip the surface geometry with the lens function
$lensFunction = Graphics::VTK::Sphere->new;
$lensFunction->SetCenter($x,$y,$z);
$lensFunction->SetRadius($r);
$surfaceClipper = Graphics::VTK::ClipPolyData->new;
$surfaceClipper->SetInput($VTK_DATA->_skinPolyDataReader('GetOutput'));
$surfaceClipper->SetClipFunction($lensFunction);
$surfaceClipper->GenerateClippedOutputOn;
$surfaceClipper->GenerateClipScalarsOn;
$surfaceClipper->InsideOutOn;
$surfaceClipper->Update;
$surfaceMapper = Graphics::VTK::PolyDataMapper->new;
$surfaceMapper->SetInput($surfaceClipper->GetOutput);
$surfaceMapper->SetScalarRange(-100,100);
$surfaceMapper->ScalarVisibilityOff;
$surfaceMapper->ImmediateModeRenderingOn;
$clippedSurface = Graphics::VTK::Actor->new;
$clippedSurface->SetMapper($surfaceMapper);
$clippedSurface->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$clippedSurface->GetProperty->SetSpecular('.4');
$clippedSurface->GetProperty->SetSpecularPower(30);
$clippedSurface->GetProperty->SetOpacity('.5');
$insideSurfaceMapper = Graphics::VTK::PolyDataMapper->new;
$insideSurfaceMapper->SetInput($surfaceClipper->GetClippedOutput);
$insideSurfaceMapper->ScalarVisibilityOff;
$insideSurfaceMapper->ImmediateModeRenderingOn;
$VTK_DATA->_skinActor('SetMapper',$insideSurfaceMapper);
$VTK_DATA->_skinActor('VisibilityOn');
# set up volume rendering
$tfun = Graphics::VTK::PiecewiseFunction->new;
$tfun->AddPoint(70.0,0.0);
$tfun->AddPoint(599.0,0);
$tfun->AddPoint(600.0,0);
$tfun->AddPoint(1195.0,0);
$tfun->AddPoint(1200,'.2');
$tfun->AddPoint(1300,'.3');
$tfun->AddPoint(2000,'.3');
$tfun->AddPoint(4095.0,1.0);
$ctfun = Graphics::VTK::ColorTransferFunction->new;
$ctfun->AddRedPoint(0.0,0.5);
$ctfun->AddRedPoint(600.0,1.0);
$ctfun->AddRedPoint(4095.0,0.5);
$ctfun->AddGreenPoint(600.0,0.5);
$ctfun->AddGreenPoint(1280.0,'.2');
$ctfun->AddGreenPoint(4095.0,0.5);
$ctfun->AddBluePoint(600.0,0.5);
$ctfun->AddBluePoint(1960.0,'.1');
$ctfun->AddBluePoint(4095.0,0.5);
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$raybounder = Graphics::VTK::ProjectedPolyDataRayBounder->new;
$raybounder->SetPolyData($lensSource->GetOutput);
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volumeMapper->SetRayBounder($raybounder);
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::ctfun);
$volumeProperty->SetScalarOpacity($tfun);
$volumeProperty->SetInterpolationTypeToLinear;
$volumeProperty->ShadeOn;
$newvol = Graphics::VTK::Volume->new;
$newvol->SetMapper($volumeMapper);
$newvol->SetProperty($volumeProperty);
$ren1->AddVolume($newvol);
$ren1->AddActor($lens);
$lens->PickableOff;
$lens->VisibilityOn;
#ren1 AddActor clippedSurface
$clippedSurface->VisibilityOff;
$ren1->AddActor($lensGeometry);
$lensGeometry->VisibilityOff;
$ren1->SetBackground(0.2,0.3,0.4);
$renWin->SetSize(320,240);
$ren1->GetActiveCamera->SetViewUp(0,-1,0);
$ren1->GetActiveCamera->Azimuth(230);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.75);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
# Clip with spherical lens
#
sub Clip
{
 my $x = shift;
 my $y = shift;
 my $z = shift;
 my $r = shift;
 $lensSource->SetCenter($x,$y,$z);
 $lensSource->SetRadius($r);
 $lensFunction->SetCenter($x,$y,$z);
 $lensFunction->SetRadius($r);
 print("lensClipper [expr [lindex [time {lensClipper Update} 1] 0] / 1000000.0] seconds");
 print("surfaceClipper [expr [lindex [time {surfaceClipper Update} 1] 0] / 1000000.0] seconds");
 $renWin->Render;
}
#
sub PickAndClip
{
 my $Clip;
 # Global Variables Declared for this function: r
 Clip($iren->GetPicker->GetPickPosition,$r);
}
$iren->SetDesiredUpdateRate('.5');
$iren->SetEndPickMethod(
 sub
  {
   PickAndClip();
  }
);
#
sub PickAndPrint
{
 print("eval [[iren GetPicker] GetPickPosition]");
}
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName surfVol.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
