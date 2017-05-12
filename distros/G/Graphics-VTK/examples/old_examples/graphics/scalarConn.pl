#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate use of scalar connectivity
use Graphics::VTK::Tk::vtkInt;
# Quadric definition
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(30,30,30);
$sample->SetImplicitFunction($quadric);
$sample->Update;
$sample->Print;
$sample->ComputeNormalsOff;
# Extract cells that contains isosurface of interest
$conn = Graphics::VTK::ConnectivityFilter->new;
$conn->SetInput($sample->GetOutput);
$conn->ScalarConnectivityOn;
$conn->SetScalarRange(0.6,0.6);
$conn->SetExtractionModeToCellSeededRegions;
$conn->AddSeed(105);
# Create a surface 
$contours = Graphics::VTK::ContourFilter->new;
$contours->SetInput($conn->GetOutput);
#  contours SetInput [sample GetOutput]
$contours->GenerateValues(5,0.0,1.2);
$contMapper = Graphics::VTK::DataSetMapper->new;
#  contMapper SetInput [contours GetOutput]
$contMapper->SetInput($conn->GetOutput);
$contMapper->SetScalarRange(0.0,1.2);
$contActor = Graphics::VTK::Actor->new;
$contActor->SetMapper($contMapper);
# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
# Graphics
# create a window to render into
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
# create a renderer
# interactiver renderer catches mouse events (optional)
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->SetBackground(1,1,1);
$ren1->AddActor($contActor);
$ren1->AddActor($outlineActor);
$ren1->GetActiveCamera->Zoom(1.4);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName('valid/scalarConn.tcl.ppm');
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
