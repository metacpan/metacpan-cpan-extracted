#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of clipping and cutting
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
#source $VTK_TCL/vtkInclude.tcl
# create test data by hand. Use an alternative creation method for 
# polygonal data.
$pts = Graphics::VTK::Points->new;
$pts->InsertPoint(0,0,0,0);
$pts->InsertPoint(1,1,0,0);
$pts->InsertPoint(2,2,0,0);
$pts->InsertPoint(3,3,0,0);
$pts->InsertPoint(4,0,1,0);
$pts->InsertPoint(5,1,1,0);
$pts->InsertPoint(6,2,1,0);
$pts->InsertPoint(7,3,1,0);
$pts->InsertPoint(8,0,2,0);
$pts->InsertPoint(9,1,2,0);
$pts->InsertPoint(10,2,2,0);
$pts->InsertPoint(11,3,2,0);
$pts->InsertPoint(12,1,3,0);
$pts->InsertPoint(13,2,3,0);
$pts->InsertPoint(14,0,4,0);
$pts->InsertPoint(15,1,4,0);
$pts->InsertPoint(16,2,4,0);
$pts->InsertPoint(17,3,4,0);
$pts->InsertPoint(18,0,4,1);
$pts->InsertPoint(19,1,4,1);
$pts->InsertPoint(20,2,4,1);
$pts->InsertPoint(21,3,4,1);
$pts->InsertPoint(22,0,5,0);
$pts->InsertPoint(23,1,5,0);
$pts->InsertPoint(24,2,5,0);
$pts->InsertPoint(25,3,5,0);
$pts->InsertPoint(26,0,5,1);
$pts->InsertPoint(27,1,5,1);
$pts->InsertPoint(28,2,5,1);
$pts->InsertPoint(29,3,5,1);
$ids = Graphics::VTK::IdList->new;
$data = Graphics::VTK::PolyData->new;
$data->Allocate(100,100);
#initial amount and extend size
$data->SetPoints($pts);
# create polygons
$ids->Reset;
$ids->InsertNextId(0);
$ids->InsertNextId(1);
$ids->InsertNextId(5);
$ids->InsertNextId(4);
$data->InsertNextCell($VTK_QUAD,$ids);
$ids->Reset;
$ids->InsertNextId(1);
$ids->InsertNextId(2);
$ids->InsertNextId(6);
$ids->InsertNextId(5);
$data->InsertNextCell($VTK_QUAD,$ids);
$ids->Reset;
$ids->InsertNextId(2);
$ids->InsertNextId(3);
$ids->InsertNextId(7);
$ids->InsertNextId(6);
$data->InsertNextCell($VTK_QUAD,$ids);
# create a line and poly-line
$ids->Reset;
$ids->InsertNextId(8);
$ids->InsertNextId(9);
$data->InsertNextCell($VTK_LINE,$ids);
$ids->Reset;
$ids->InsertNextId(9);
$ids->InsertNextId(10);
$ids->InsertNextId(11);
$data->InsertNextCell($VTK_POLY_LINE,$ids);
# create some points
$ids->Reset;
$ids->InsertNextId(12);
$ids->InsertNextId(13);
$data->InsertNextCell($VTK_POLY_VERTEX,$ids);
# create a triangle strip
$ids->Reset;
$ids->InsertNextId(14);
$ids->InsertNextId(22);
$ids->InsertNextId(15);
$ids->InsertNextId(23);
$ids->InsertNextId(16);
$ids->InsertNextId(24);
$ids->InsertNextId(17);
$ids->InsertNextId(25);
$data->InsertNextCell($VTK_TRIANGLE_STRIP,$ids);
# create two 5-sided polygons
$ids->Reset;
$ids->InsertNextId(18);
$ids->InsertNextId(19);
$ids->InsertNextId(20);
$ids->InsertNextId(27);
$ids->InsertNextId(26);
$data->InsertNextCell($VTK_POLYGON,$ids);
$ids->Reset;
$ids->InsertNextId(20);
$ids->InsertNextId(21);
$ids->InsertNextId(29);
$ids->InsertNextId(28);
$ids->InsertNextId(27);
$data->InsertNextCell($VTK_POLYGON,$ids);
# Create pipeline
$meshMapper = Graphics::VTK::DataSetMapper->new;
$meshMapper->SetInput($data);
$meshActor = Graphics::VTK::Actor->new;
$meshActor->SetMapper($meshMapper);
$meshActor->GetProperty->SetColor(@Graphics::VTK::Colors::green);
$meshActor->GetProperty->SetOpacity(0.2);
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(1.75,0,0);
$plane->SetNormal(1,0,0);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($data);
$clipper->SetClipFunction($plane);
$clipper->SetValue(0.0);
# turn off the scalars
$clipper->GetOutput->GetPointData->CopyScalarsOff;
$clippedMapper = Graphics::VTK::DataSetMapper->new;
$clippedMapper->SetInput($clipper->GetOutput);
$clippedActor = Graphics::VTK::Actor->new;
$clippedActor->SetMapper($clippedMapper);
$clippedActor->GetProperty->SetColor(@Graphics::VTK::Colors::red);
$extract = Graphics::VTK::ExtractEdges->new;
$extract->SetInput($clipper->GetOutput);
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($extract->GetOutput);
$tubes->SetRadius(0.02);
$tubes->SetNumberOfSides(6);
$mapEdges = Graphics::VTK::PolyDataMapper->new;
$mapEdges->SetInput($tubes->GetOutput);
$edgeActor = Graphics::VTK::Actor->new;
$edgeActor->SetMapper($mapEdges);
$edgeActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$edgeActor->GetProperty->SetSpecularColor(1,1,1);
$edgeActor->GetProperty->SetSpecular(0.3);
$edgeActor->GetProperty->SetSpecularPower(20);
$edgeActor->GetProperty->SetAmbient(0.2);
$edgeActor->GetProperty->SetDiffuse(0.8);
$ball = Graphics::VTK::SphereSource->new;
$ball->SetRadius(0.05);
$ball->SetThetaResolution(12);
$ball->SetPhiResolution(12);
$balls = Graphics::VTK::Glyph3D->new;
$balls->SetInput($clipper->GetOutput);
$balls->SetSource($ball->GetOutput);
$mapBalls = Graphics::VTK::PolyDataMapper->new;
$mapBalls->SetInput($balls->GetOutput);
$ballActor = Graphics::VTK::Actor->new;
$ballActor->SetMapper($mapBalls);
$ballActor->GetProperty->SetColor(@Graphics::VTK::Colors::hot_pink);
$ballActor->GetProperty->SetSpecularColor(1,1,1);
$ballActor->GetProperty->SetSpecular(0.3);
$ballActor->GetProperty->SetSpecularPower(20);
$ballActor->GetProperty->SetAmbient(0.2);
$ballActor->GetProperty->SetDiffuse(0.8);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($ballActor);
$ren1->AddActor($edgeActor);
$ren1->AddActor($meshActor);
$ren1->AddActor($clippedActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,400);
$ren1->GetActiveCamera->Zoom(1.3);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("clipCut.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
