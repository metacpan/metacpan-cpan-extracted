#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Exercise vtkGeometryFilter for different data types
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline - structured grid
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$gf = Graphics::VTK::GeometryFilter->new;
$gf->SetInput($pl3d->GetOutput);
$gMapper = Graphics::VTK::PolyDataMapper->new;
$gMapper->SetInput($gf->GetOutput);
$gMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$gActor = Graphics::VTK::Actor->new;
$gActor->SetMapper($gMapper);
$gf2 = Graphics::VTK::GeometryFilter->new;
$gf2->SetInput($pl3d->GetOutput);
$gf2->ExtentClippingOn;
$gf2->SetExtent(10,17,-6,6,23,37);
$gf2->PointClippingOn;
$gf2->SetPointMinimum(0);
$gf2->SetPointMaximum(10000);
$gf2->CellClippingOn;
$gf2->SetCellMinimum(0);
$gf2->SetCellMaximum(7500);
$g2Mapper = Graphics::VTK::PolyDataMapper->new;
$g2Mapper->SetInput($gf2->GetOutput);
$g2Mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$g2Actor = Graphics::VTK::Actor->new;
$g2Actor->SetMapper($g2Mapper);
$g2Actor->AddPosition(0,15,0);
# create pipeline - poly data
$gf3 = Graphics::VTK::GeometryFilter->new;
$gf3->SetInput($gf->GetOutput);
$g3Mapper = Graphics::VTK::PolyDataMapper->new;
$g3Mapper->SetInput($gf3->GetOutput);
$g3Mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$g3Actor = Graphics::VTK::Actor->new;
$g3Actor->SetMapper($g3Mapper);
$g3Actor->AddPosition(0,0,15);
$gf4 = Graphics::VTK::GeometryFilter->new;
$gf4->SetInput($gf2->GetOutput);
$gf4->ExtentClippingOn;
$gf4->SetExtent(10,17,-6,6,23,37);
$gf4->PointClippingOn;
$gf4->SetPointMinimum(0);
$gf4->SetPointMaximum(10000);
$gf4->CellClippingOn;
$gf4->SetCellMinimum(0);
$gf4->SetCellMaximum(7500);
$g4Mapper = Graphics::VTK::PolyDataMapper->new;
$g4Mapper->SetInput($gf4->GetOutput);
$g4Mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$g4Actor = Graphics::VTK::Actor->new;
$g4Actor->SetMapper($g4Mapper);
$g4Actor->AddPosition(0,15,15);
# create pipeline - unstructured grid
$s = Graphics::VTK::Sphere->new;
$s->SetCenter($pl3d->GetOutput->GetCenter);
$s->SetRadius(100.0);
#everything
$eg = Graphics::VTK::ExtractGeometry->new;
$eg->SetInput($pl3d->GetOutput);
$eg->SetImplicitFunction($s);
$gf5 = Graphics::VTK::GeometryFilter->new;
$gf5->SetInput($eg->GetOutput);
$g5Mapper = Graphics::VTK::PolyDataMapper->new;
$g5Mapper->SetInput($gf5->GetOutput);
$g5Mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$g5Actor = Graphics::VTK::Actor->new;
$g5Actor->SetMapper($g5Mapper);
$g5Actor->AddPosition(0,0,30);
$gf6 = Graphics::VTK::GeometryFilter->new;
$gf6->SetInput($eg->GetOutput);
$gf6->ExtentClippingOn;
$gf6->SetExtent(10,17,-6,6,23,37);
$gf6->PointClippingOn;
$gf6->SetPointMinimum(0);
$gf6->SetPointMaximum(10000);
$gf6->CellClippingOn;
$gf6->SetCellMinimum(0);
$gf6->SetCellMaximum(7500);
$g6Mapper = Graphics::VTK::PolyDataMapper->new;
$g6Mapper->SetInput($gf6->GetOutput);
$g6Mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$g6Actor = Graphics::VTK::Actor->new;
$g6Actor->SetMapper($g6Mapper);
$g6Actor->AddPosition(0,15,30);
# create pipeline - rectilinear grid
$rgridReader = Graphics::VTK::RectilinearGridReader->new;
$rgridReader->SetFileName("$VTK_DATA/RectGrid.vtk");
$rgridReader->Update;
$gf7 = Graphics::VTK::GeometryFilter->new;
$gf7->SetInput($rgridReader->GetOutput);
$g7Mapper = Graphics::VTK::PolyDataMapper->new;
$g7Mapper->SetInput($gf7->GetOutput);
$g7Mapper->SetScalarRange($rgridReader->GetOutput->GetScalarRange);
$g7Actor = Graphics::VTK::Actor->new;
$g7Actor->SetMapper($g7Mapper);
$g7Actor->SetScale(3,3,3);
$gf8 = Graphics::VTK::GeometryFilter->new;
$gf8->SetInput($rgridReader->GetOutput);
$gf8->ExtentClippingOn;
$gf8->SetExtent(0,1,-2,2,0,4);
$gf8->PointClippingOn;
$gf8->SetPointMinimum(0);
$gf8->SetPointMaximum(10000);
$gf8->CellClippingOn;
$gf8->SetCellMinimum(0);
$gf8->SetCellMaximum(7500);
$g8Mapper = Graphics::VTK::PolyDataMapper->new;
$g8Mapper->SetInput($gf8->GetOutput);
$g8Mapper->SetScalarRange($rgridReader->GetOutput->GetScalarRange);
$g8Actor = Graphics::VTK::Actor->new;
$g8Actor->SetMapper($g8Mapper);
$g8Actor->SetScale(3,3,3);
$g8Actor->AddPosition(0,15,0);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($gActor);
$ren1->AddActor($g2Actor);
$ren1->AddActor($g3Actor);
$ren1->AddActor($g4Actor);
$ren1->AddActor($g5Actor);
$ren1->AddActor($g6Actor);
$ren1->AddActor($g7Actor);
$ren1->AddActor($g8Actor);
$renWin->SetSize(340,550);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(84,174);
$cam1->SetFocalPoint(5.22824,6.09412,35.9813);
$cam1->SetPosition(100.052,62.875,102.818);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.307455,-0.464269,0.830617);
$iren->Initialize;
$renWin->SetFileName("geomFilter.tcl.ppm");
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
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
