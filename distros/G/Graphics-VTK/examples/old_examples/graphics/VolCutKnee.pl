#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$ren1->BackingStoreOn;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/vw_knee.slc");
$reader->Update;
$white_tfun = Graphics::VTK::PiecewiseFunction->new;
$white_tfun->AddPoint(0,1.0);
$white_tfun->AddPoint(255,1.0);
$tfun = Graphics::VTK::PiecewiseFunction->new;
$tfun->AddPoint(70,0.0);
$tfun->AddPoint(80,1.0);
$ren1->SetBackground('.1','.2','.4');
$vol_prop = Graphics::VTK::VolumeProperty->new;
$vol_prop->SetColor(@Graphics::VTK::Colors::white_tfun);
$vol_prop->SetScalarOpacity($tfun);
$vol_prop->SetInterpolationTypeToLinear;
$vol_prop->ShadeOn;
$comp_func = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volmap = Graphics::VTK::VolumeRayCastMapper->new;
$volmap->SetVolumeRayCastFunction($comp_func);
$volmap->SetInput($reader->GetOutput);
$volmap->SetSampleDistance(1.0);
$vol = Graphics::VTK::Volume->new;
$vol->SetProperty($vol_prop);
$vol->SetMapper($volmap);
$ren1->AddVolume($vol);
$shrink = Graphics::VTK::ImageShrink3D->new;
$shrink->SetInput($reader->GetOutput);
$shrink->SetShrinkFactors(4,4,2);
$shrink->AveragingOn;
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($shrink->GetOutput);
$contour->SetValue(0,30.0);
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,100.0,150.0,130.0);
$points->InsertPoint(1,100.0,150.0,130.0);
$points->InsertPoint(2,100.0,150.0,130.0);
$normals = Graphics::VTK::Normals->new;
$normals->InsertNormal(0,1.0,0.0,0.0);
$normals->InsertNormal(1,0.0,1.0,0.0);
$normals->InsertNormal(2,0.0,0.0,1.0);
$planes = Graphics::VTK::Planes->new;
$planes->SetPoints($points);
$planes->SetNormals($normals);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($contour->GetOutput);
$clipper->SetClipFunction($planes);
$clipper->GenerateClipScalarsOn;
$skin_mapper = Graphics::VTK::PolyDataMapper->new;
$skin_mapper->SetInput($clipper->GetOutput);
$skin_mapper->ScalarVisibilityOff;
$skin = Graphics::VTK::Actor->new;
$skin->SetMapper($skin_mapper);
$skin->GetProperty->SetColor(0.8,0.4,0.2);
$ren1->AddActor($skin);
$renWin->SetSize(200,200);
$ren1->GetActiveCamera->SetPosition(-47.5305,-319.315,92.0083);
$ren1->GetActiveCamera->SetFocalPoint(78.9121,89.8372,95.1229);
$ren1->GetActiveCamera->SetViewUp(-0.00708891,0.00980254,-0.999927);
$ren1->GetActiveCamera->SetViewPlaneNormal(-0.29525,-0.955392,-0.0072728);
$ren1->GetActiveCamera->SetClippingRange(42.8255,2141.28);
$iren->Initialize;
$renWin->Render;
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
