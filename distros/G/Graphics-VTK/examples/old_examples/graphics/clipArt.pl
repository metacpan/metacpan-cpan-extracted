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
# Create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$imageIn = Graphics::VTK::BMPReader->new;
$imageIn->SetFileName("$VTK_DATA/beach.bmp");
$imageIn->ReleaseDataFlagOff;
$imageIn->Update;
#
sub PowerOfTwo
{
 my $amt = shift;
 my $pow;
 my $return;
 $pow = 0;
 $amt += -1;
 while (1)
  {
   $amt = __($amt,1);
   $pow += 1;
   return __(1,$pow) if ($amt <= 0);
  }
}
$orgX = ($imageIn->GetOutput->GetWholeExtent)[1] - ($imageIn->GetOutput->GetWholeExtent)[0] + 1;
$orgY = ($imageIn->GetOutput->GetWholeExtent)[3] - ($imageIn->GetOutput->GetWholeExtent)[2] + 1;
$padX = PowerOfTwo($orgX);
$padY = PowerOfTwo($orgY);
$imagePowerOf2 = Graphics::VTK::ImageConstantPad->new;
$imagePowerOf2->SetInput($imageIn->GetOutput);
$imagePowerOf2->SetOutputWholeExtent(0,$padX - 1,0,$padY - 1,0,0);
$toHSV = Graphics::VTK::ImageRGBToHSV->new;
$toHSV->SetInput($imageIn->GetOutput);
$toHSV->ReleaseDataFlagOff;
$extractImage = Graphics::VTK::ImageExtractComponents->new;
$extractImage->SetInput($toHSV->GetOutput);
$extractImage->SetComponents(2);
$extractImage->ReleaseDataFlagOff;
$threshold = Graphics::VTK::ImageThreshold->new;
$threshold->SetInput($extractImage->GetOutput);
$threshold->ThresholdByUpper(230);
$threshold->SetInValue(255);
$threshold->SetOutValue(0);
$threshold->Update;
$extent = $threshold->GetOutput->GetWholeExtent;
$seed1 = "[lindex $extent 0] [lindex $extent 2]";
$seed2 = "[lindex $extent 1] [lindex $extent 2]";
$seed3 = "[lindex $extent 1] [lindex $extent 3]";
$seed4 = "[lindex $extent 0] [lindex $extent 3]";
$connect = Graphics::VTK::ImageSeedConnectivity->new;
$connect->SetInput($threshold->GetOutput);
$connect->SetInputConnectValue(255);
$connect->SetOutputConnectedValue(255);
$connect->SetOutputUnconnectedValue(0);
$connect->AddSeed($seed1);
$connect->AddSeed($seed2);
$connect->AddSeed($seed3);
$connect->AddSeed($seed4);
$smooth = Graphics::VTK::ImageGaussianSmooth->new;
$smooth->SetDimensionality(2);
$smooth->SetStandardDeviation(1,1);
$smooth->SetInput($connect->GetOutput);
$shrink = Graphics::VTK::ImageShrink3D->new;
$shrink->SetInput($smooth->GetOutput);
$shrink->SetShrinkFactors(2,2,1);
$shrink->AveragingOn;
$toStructuredPoints = Graphics::VTK::ImageToStructuredPoints->new;
$toStructuredPoints->SetInput($shrink->GetOutput);
$geometry = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geometry->SetInput($toStructuredPoints->GetOutput);
$geometryTexture = Graphics::VTK::TextureMapToPlane->new;
$geometryTexture->SetInput($geometry->GetOutput);
$geometryTexture->SetOrigin(0,0,0);
$geometryTexture->SetPoint1($padX - 1,0,0);
$geometryTexture->SetPoint2(0,$padY - 1,0);
$geometryPD = Graphics::VTK::CastToConcrete->new;
$geometryPD->SetInput($geometryTexture->GetOutput);
$clip = Graphics::VTK::ClipPolyData->new;
$clip->SetInput($geometryPD->GetPolyDataOutput);
$clip->SetValue(5.5);
$clip->GenerateClipScalarsOff;
$clip->InsideOutOff;
$clip->InsideOutOn;
$clip->GetOutput->GetPointData->CopyScalarsOff;
$clip->Update;
$triangles = Graphics::VTK::TriangleFilter->new;
$triangles->SetInput($clip->GetOutput);
$decimate = Graphics::VTK::DecimatePro->new;
$decimate->SetInput($triangles->GetOutput);
$decimate->BoundaryVertexDeletionOn;
$decimate->SetDegree(25);
$decimate->PreserveTopologyOn;
$extrude = Graphics::VTK::LinearExtrusionFilter->new;
$extrude->SetInput($decimate->GetOutput);
$extrude->SetExtrusionType(2);
$extrude->SetScaleFactor(-20);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($extrude->GetOutput);
$normals->SetFeatureAngle(80);
$scaleTexture = Graphics::VTK::TransformTextureCoords->new;
$scaleTexture->SetInput($normals->GetOutput);
$scaleTexture->SetScale(($orgX * 1.0) / $padX,($orgY * 1.0) / $padY,1.0);
$scaleTexture->SetOrigin(0,0,0);
$texturePD = Graphics::VTK::CastToConcrete->new;
$texturePD->SetInput($scaleTexture->GetOutput);
$strip = Graphics::VTK::Stripper->new;
$strip->SetInput($texturePD->GetPolyDataOutput);
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($strip->GetOutput);
$map->SetInput($texturePD->GetPolyDataOutput);
$map->ScalarVisibilityOff;
$imageTexture = Graphics::VTK::Texture->new;
$imageTexture->InterpolateOn;
$imageTexture->SetInput($imagePowerOf2->GetOutput);
$clipart = Graphics::VTK::Actor->new;
$clipart->SetMapper($map);
$clipart->SetTexture($imageTexture);
$ren1->AddActor($clipart);
$clipart->GetProperty->SetDiffuseColor(1,1,1);
$clipart->GetProperty->SetSpecular('.5');
$clipart->GetProperty->SetSpecularPower(30);
$clipart->GetProperty->SetDiffuse('.9');
$camera = $ren1->GetActiveCamera;
$camera->Azimuth(30);
$camera->Elevation(-30);
$camera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$ren1->SetBackground(0.2,0.3,0.4);
$renWin->SetSize(320,256);
$iren->Initialize;
$renWin->Render;
# render the image
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
