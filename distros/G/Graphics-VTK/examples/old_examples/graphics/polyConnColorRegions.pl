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
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$reader = Graphics::VTK::STLReader->new;
$reader->SetFileName("$VTK_DATA/cadPart.stl");
$cpd = Graphics::VTK::CleanPolyData->new;
$cpd->SetInput($reader->GetOutput);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetMaxRecursionDepth(10);
$normals->SetFeatureAngle(30);
$normals->SetInput($cpd->GetOutput);
$conn = Graphics::VTK::PolyDataConnectivityFilter->new;
$conn->SetMaxRecursionDepth(1000);
$conn->SetInput($normals->GetOutput);
$conn->ColorRegionsOn;
$conn->SetExtractionModeToAllRegions;
$conn->Update;
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($conn->GetOutput);
$mapper->SetScalarRange($conn->GetOutput->GetScalarRange);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$ren1->AddActor($actor);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(60);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$MW->withdraw;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName polyConnColorRegions.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
