#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Create blow molding image (data point 9)
# get the interactor
use Graphics::VTK::Tk::vtkInt;
# create reader and warp data with vectors
$reader = Graphics::VTK::DataSetReader->new;
$reader->SetFileName("$VTK_DATA/blow.vtk");
$reader->SetScalarsName("thickness9");
$reader->SetVectorsName("displacement9");
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($reader->GetUnstructuredGridOutput);
# extract mold from mesh using connectivity
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($warp->GetOutput);
$connect->SetExtractionModeToSpecifiedRegions;
$connect->AddSpecifiedRegion(0);
$connect->AddSpecifiedRegion(1);
$moldMapper = Graphics::VTK::DataSetMapper->new;
$moldMapper->SetInput($reader->GetOutput);
$moldMapper->ScalarVisibilityOff;
$moldActor = Graphics::VTK::Actor->new;
$moldActor->SetMapper($moldMapper);
$moldActor->GetProperty->SetColor('.2','.2','.2');
$moldActor->GetProperty->SetRepresentationToWireframe;
# extract parison from mesh using connectivity
$connect2 = Graphics::VTK::ConnectivityFilter->new;
$connect2->SetInput($warp->GetOutput);
$connect2->SetExtractionModeToSpecifiedRegions;
$connect2->AddSpecifiedRegion(2);
$parison = Graphics::VTK::GeometryFilter->new;
$parison->SetInput($connect2->GetOutput);
$normals2 = Graphics::VTK::PolyDataNormals->new;
$normals2->SetInput($parison->GetOutput);
$normals2->SetFeatureAngle(60);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange(0.0,0.66667);
$parisonMapper = Graphics::VTK::PolyDataMapper->new;
$parisonMapper->SetInput($normals2->GetOutput);
$parisonMapper->SetLookupTable($lut);
$parisonMapper->SetScalarRange(0.12,1.0);
$parisonActor = Graphics::VTK::Actor->new;
$parisonActor->SetMapper($parisonMapper);
$cf = Graphics::VTK::ContourFilter->new;
$cf->SetInput($connect2->GetOutput);
$cf->SetValue(0,'.5');
$contourMapper = Graphics::VTK::PolyDataMapper->new;
$contourMapper->SetInput($cf->GetOutput);
$contours = Graphics::VTK::Actor->new;
$contours->SetMapper($contourMapper);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($moldActor);
$ren1->AddActor($parisonActor);
$ren1->AddActor($contours);
$ren1->GetActiveCamera->Azimuth(60);
$ren1->GetActiveCamera->Roll(-90);
$ren1->GetActiveCamera->Dolly(2);
$ren1->ResetCameraClippingRange;
$ren1->SetBackground(1,1,1);
$renWin->SetSize(750,400);
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "blow.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
