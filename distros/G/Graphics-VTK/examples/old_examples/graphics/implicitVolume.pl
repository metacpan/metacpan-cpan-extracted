#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# clip a surface with a plane and a plane with an implicit volume
# get the interactor ui
$source->______examplesTcl_vtkInt_tcl;
$source->______examplesTcl_colors_tcl;
$source->______examplesTcl_frog_SliceOrder_tcl;
# Create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$skinReader = Graphics::VTK::PolyDataReader->new;
$skinReader->SetFileName("../../../vtkdata/skin.vtk");
$RESOLUTION = 256;
$START_SLICE = 1;
$END_SLICE = 93;
$PIXEL_SIZE = '.8';
$centerX = ($RESOLUTION / 2);
$centerY = ($RESOLUTION / 2);
$centerZ = ($END_SLICE - $START_SLICE) / 2;
$endX = ($RESOLUTION - 1);
$endY = ($RESOLUTION - 1);
$endZ = ($END_SLICE - 1);
$origin = ($RESOLUTION / 2.0) * $PIXEL_SIZE * -1.0;
$SLICE_ORDER = 'si';
$reader = Graphics::VTK::Volume16Reader->new;
$reader->SetDataDimensions($RESOLUTION,$RESOLUTION);
$reader->SetFilePrefix('../../../vtkdata/fullHead/headsq');
$reader->SetDataSpacing($PIXEL_SIZE,$PIXEL_SIZE,1.5);
$reader->SetDataOrigin($origin,$origin,1.5);
$reader->SetImageRange($START_SLICE,$END_SLICE);
$reader->SetHeaderSize(0);
$reader->SetDataMask(0x7fff);
$reader->SetDataByteOrderToLittleEndian;
$reader->SetTransform('si');
$aPlaneSection = Graphics::VTK::ExtractVOI->new;
$aPlaneSection->SetVOI($centerX,$centerX,0,$endZ,0,$endY);
$aPlaneSection->SetInput($reader->GetOutput);
$aPlaneSection->Update;
$bounds = $aPlaneSection->GetOutput->GetBounds;
$aPlaneSource = Graphics::VTK::PlaneSource->new;
$aPlaneSource->SetOrigin($bounds[0],$bounds[2],$bounds[4]);
$aPlaneSource->SetPoint1($bounds[0],$bounds[2],$bounds[5]);
$aPlaneSource->SetPoint2($bounds[0],$bounds[3],$bounds[4]);
$aPlaneSource->SetResolution(200,100);
$aVolumeModel = Graphics::VTK::ImplicitVolume->new;
$aVolumeModel->SetVolume($reader->GetOutput);
$aClipper = Graphics::VTK::ClipPolyData->new;
$aClipper->SetInput($aPlaneSource->GetOutput);
$aClipper->SetClipFunction($aVolumeModel);
$aClipper->SetValue(600.5);
$aClipper->GenerateClipScalarsOn;
$aClipper->Update;
$wlLut = Graphics::VTK::WindowLevelLookupTable->new;
$wlLut->SetWindow(1000);
$wlLut->SetLevel(1200);
$wlLut->SetTableRange(0,2047);
$wlLut->Build;
$aClipperMapper = Graphics::VTK::PolyDataMapper->new;
$aClipperMapper->SetInput($aClipper->GetOutput);
$aClipperMapper->SetScalarRange(0,2047);
$aClipperMapper->SetLookupTable($wlLut);
$aClipperMapper->ScalarVisibilityOn;
$cut = Graphics::VTK::Actor->new;
$cut->SetMapper($aClipperMapper);
$aPlane = Graphics::VTK::Plane->new;
$aPlane->SetOrigin($aPlaneSource->GetOrigin);
$aPlane->SetNormal($aPlaneSource->GetNormal);
$aCutter = Graphics::VTK::ClipPolyData->new;
$aCutter->SetClipFunction($aPlane);
$aCutter->SetInput($skinReader->GetOutput);
$skinMapper = Graphics::VTK::PolyDataMapper->new;
$skinMapper->SetInput($aCutter->GetOutput);
$skinMapper->ScalarVisibilityOff;
$skin = Graphics::VTK::Actor->new;
$skin->SetMapper($skinMapper);
$skin->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::flesh);
$skin->GetProperty->SetDiffuse('.8');
$skin->GetProperty->SetSpecular('.5');
$skin->GetProperty->SetSpecularPower(30);
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::flesh);
$backProp->SetDiffuse('.2');
$backProp->SetSpecular('.5');
$backProp->SetSpecularPower(30);
$skin->SetBackfaceProperty($backProp);
$ren1->AddActor($skin);
$ren1->AddActor($cut);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(480,480);
$ren1->GetActiveCamera->SetViewUp(0,-1,0);
$ren1->GetActiveCamera->Azimuth(230);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
$renWin->Render;
#renWin SetFileName "implicitVolume.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;

Tk->MainLoop;
