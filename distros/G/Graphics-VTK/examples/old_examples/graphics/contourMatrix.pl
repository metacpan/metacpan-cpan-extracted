#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Contour data stored as a matrix of values in a vtk structured points file
use Graphics::VTK::Tk::vtkInt;
# create pipeline
$reader = Graphics::VTK::DataSetReader->new;
$reader->SetFileName("$VTK_DATA/matrix.vtk");
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($reader->GetStructuredPointsOutput);
$contour->SetValue(0,'.5');
$contourMapper = Graphics::VTK::DataSetMapper->new;
$contourMapper->SetInput($contour->GetOutput);
$contourMapper->ScalarVisibilityOff;
$contourActor = Graphics::VTK::Actor->new;
$contourActor->SetMapper($contourMapper);
$contourActor->SetPosition(0,0,5);
$toGeometry = Graphics::VTK::StructuredPointsGeometryFilter->new;
$toGeometry->SetInput($reader->GetStructuredPointsOutput);
$carpet = Graphics::VTK::WarpScalar->new;
$carpet->SetInput($toGeometry->GetOutput);
$carpet->SetNormal(0,0,1);
$carpet->SetScaleFactor(3);
$carpetMapper = Graphics::VTK::DataSetMapper->new;
$carpetMapper->SetInput($carpet->GetOutput);
$carpetMapper->ScalarVisibilityOff;
$carpetActor = Graphics::VTK::Actor->new;
$carpetActor->SetMapper($carpetMapper);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($contourActor);
$ren1->AddActor($carpetActor);
$renWin->SetSize(400,400);
$ren1->GetActiveCamera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName "contourMatrix.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
