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
# Create ren1dering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# ingest data file
$toolModel = Graphics::VTK::UGFacetReader->new;
$toolModel->SetFileName("$VTK_DATA/bolt.fac");
$toolModel->MergingOn;
# create implicit model of vtk
$toolImp = Graphics::VTK::ImplicitModeller->new;
$toolImp->SetInput($toolModel->GetOutput);
$toolImp->SetSampleDimensions(25,25,50);
$toolImp->SetMaximumDistance(0.33);
$toolImp->SetAdjustDistance(0.75);
# create swept surface
$transforms = Graphics::VTK::TransformCollection->new;
$t1 = Graphics::VTK::Transform->new;
$t1->Identity;
$t2 = Graphics::VTK::Transform->new;
$t2->Translate(-1,0,0);
$t3 = Graphics::VTK::Transform->new;
$t3->Translate(-1,0,-1);
$transforms->AddItem($t1);
$transforms->AddItem($t2);
$transforms->AddItem($t3);
$toolVolume = Graphics::VTK::SweptSurface->new;
$toolVolume->SetInput($toolImp->GetOutput);
$toolVolume->SetTransforms($transforms);
$toolVolume->SetSampleDimensions(50,50,50);
$toolVolume->SetNumberOfInterpolationSteps(0);
$toolFunc = Graphics::VTK::ImplicitVolume->new;
$toolFunc->SetVolume($toolVolume->GetOutput);
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,-1,0,0);
$points->InsertPoint(1,1,0,0);
$points->InsertPoint(2,0,-1,0);
$points->InsertPoint(3,0,1,0);
$points->InsertPoint(4,0,0,-1);
$points->InsertPoint(5,0,0,1);
$normals = Graphics::VTK::Normals->new;
$normals->InsertNormal(0,-1,0,0);
$normals->InsertNormal(1,1,0,0);
$normals->InsertNormal(2,0,-1,0);
$normals->InsertNormal(3,0,1,0);
$normals->InsertNormal(4,0,0,-1);
$normals->InsertNormal(5,0,0,1);
$partImp = Graphics::VTK::Planes->new;
$partImp->SetPoints($points);
$partImp->SetNormals($normals);
$boolean = Graphics::VTK::ImplicitBoolean->new;
$boolean->SetOperationTypeToDifference;
$boolean->AddFunction($partImp);
$boolean->AddFunction($toolFunc);
$sampleBoolean = Graphics::VTK::SampleFunction->new;
$sampleBoolean->SetImplicitFunction($boolean);
$sampleBoolean->SetModelBounds(-2,2,-2,2,-2,2);
$sampleBoolean->SetSampleDimensions(64,64,64);
$iso = Graphics::VTK::MarchingContourFilter->new;
$iso->SetInput($sampleBoolean->GetOutput);
$iso->SetValue(0,'-.05');
$sweptSurfaceMapper = Graphics::VTK::PolyDataMapper->new;
$sweptSurfaceMapper->SetInput($iso->GetOutput);
$sweptSurfaceMapper->ScalarVisibilityOff;
$sweptSurface = Graphics::VTK::Actor->new;
$sweptSurface->SetMapper($sweptSurfaceMapper);
$sweptSurface->GetProperty->SetColor(0.2510,0.8784,0.8157);
$toolMapper = Graphics::VTK::PolyDataMapper->new;
$toolMapper->SetInput($toolModel->GetOutput);
$toolMapper->ScalarVisibilityOff;
$tool = Graphics::VTK::Actor->new;
$tool->SetMapper($toolMapper);
$ren1->AddActor($sweptSurface);
$ren1->AddActor($tool);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;
#renWin SetFileName "nc.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
