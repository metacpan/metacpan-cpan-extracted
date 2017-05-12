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
use Graphics::VTK::Colors;
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetBackground(0.8235,0.7059,0.5490);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$aSphere = Graphics::VTK::SphereSource->new;
$aSphere->SetRadius('.1');
$aSphereMapper = Graphics::VTK::PolyDataMapper->new;
$aSphereMapper->SetInput($aSphere->GetOutput);
$seed = Graphics::VTK::Actor->new;
$seed->SetPosition(125.6,90.5,222.678);
$seed->SetMapper($aSphereMapper);
$seed->GetProperty->SetColor(1,0,0);
$ren1->AddActor($seed);
$reader = Graphics::VTK::STLReader->new;
$reader->SetFileName("$VTK_DATA/42400-IDGH.stl");
$cpd = Graphics::VTK::CleanPolyData->new;
$cpd->SetInput($reader->GetOutput);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetMaxRecursionDepth(10);
$normals->SetFeatureAngle(15);
$normals->SetInput($cpd->GetOutput);
$conn = Graphics::VTK::PolyDataConnectivityFilter->new;
$conn->SetMaxRecursionDepth(1000);
$conn->SetInput($normals->GetOutput);
$conn->SetExtractionModeToClosestPointRegion;
$conn->SetClosestPoint(125.6,90.5,222.678);
$conn->Update;
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($conn->GetOutput);
$mapper->SetScalarRange($conn->GetOutput->GetScalarRange);
$backColor = Graphics::VTK::Property->new;
$backColor->SetColor(0.8900,0.8100,0.3400);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->SetBackfaceProperty($backColor);
$actor->GetProperty->SetColor(1.0000,0.3882,0.2784);
$ren1->AddActor($actor);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$MW->withdraw;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName('polyConnClosestPoint.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
