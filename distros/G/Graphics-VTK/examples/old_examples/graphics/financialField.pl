#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrate the use and manipulation of fields
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$size = 3187;
#maximum number possible
#set size 100;#maximum number possible
$xAxis = 'INTEREST_RATE';
$yAxis = 'MONTHLY_PAYMENT';
$zAxis = 'MONTHLY_INCOME';
$scalar = 'TIME_LATE';
# extract data from field as a polydata (just points), then extract scalars
$fdr = Graphics::VTK::DataObjectReader->new;
$fdr->SetFileName("$VTK_DATA/financial.vtk");
$do2ds = Graphics::VTK::DataObjectToDataSetFilter->new;
$do2ds->SetInput($fdr->GetOutput);
$do2ds->SetDataSetTypeToPolyData;
#format: component#, arrayname, arraycomp, minArrayId, maxArrayId, normalize
$do2ds->DefaultNormalizeOn;
$do2ds->SetPointComponent(0,$xAxis,0);
$do2ds->SetPointComponent(1,$yAxis,0,0,$size,1);
$do2ds->SetPointComponent(2,$zAxis,0);
$do2ds->Update;
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($do2ds->GetOutput);
$fd2ad->SetInputFieldToDataObjectField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->DefaultNormalizeOn;
$fd2ad->SetScalarComponent(0,$scalar,0);
# construct pipeline for original population
$popSplatter = Graphics::VTK::GaussianSplatter->new;
$popSplatter->SetInput($fd2ad->GetOutput);
$popSplatter->SetSampleDimensions(50,50,50);
$popSplatter->SetRadius(0.05);
$popSplatter->ScalarWarpingOff;
$popSurface = Graphics::VTK::ContourFilter->new;
$popSurface->SetInput($popSplatter->GetOutput);
$popSurface->SetValue(0,0.01);
$popMapper = Graphics::VTK::PolyDataMapper->new;
$popMapper->SetInput($popSurface->GetOutput);
$popMapper->ScalarVisibilityOff;
$popActor = Graphics::VTK::Actor->new;
$popActor->SetMapper($popMapper);
$popActor->GetProperty->SetOpacity(0.3);
$popActor->GetProperty->SetColor('.9','.9','.9');
# construct pipeline for delinquent population
$lateSplatter = Graphics::VTK::GaussianSplatter->new;
$lateSplatter->SetInput($fd2ad->GetOutput);
$lateSplatter->SetSampleDimensions(50,50,50);
$lateSplatter->SetRadius(0.05);
$lateSplatter->SetScaleFactor(0.05);
$lateSurface = Graphics::VTK::ContourFilter->new;
$lateSurface->SetInput($lateSplatter->GetOutput);
$lateSurface->SetValue(0,0.01);
$lateMapper = Graphics::VTK::PolyDataMapper->new;
$lateMapper->SetInput($lateSurface->GetOutput);
$lateMapper->ScalarVisibilityOff;
$lateActor = Graphics::VTK::Actor->new;
$lateActor->SetMapper($lateMapper);
$lateActor->GetProperty->SetColor(1.0,0.0,0.0);
# create axes
$popSplatter->Update;
$bounds = $popSplatter->GetOutput->GetBounds;
$axes = Graphics::VTK::Axes->new;
$axes->SetOrigin($bounds[0],$bounds[2],$bounds[4]);
$axes->SetScaleFactor($popSplatter->GetOutput->GetLength / 5.0);
$axesTubes = Graphics::VTK::TubeFilter->new;
$axesTubes->SetInput($axes->GetOutput);
$axesTubes->SetRadius($axes->GetScaleFactor / 25.0);
$axesTubes->SetNumberOfSides(6);
$axesMapper = Graphics::VTK::PolyDataMapper->new;
$axesMapper->SetInput($axesTubes->GetOutput);
$axesActor = Graphics::VTK::Actor->new;
$axesActor->SetMapper($axesMapper);
# label the axes
$XText = Graphics::VTK::VectorText->new;
$XText->SetText($xAxis);
$XTextMapper = Graphics::VTK::PolyDataMapper->new;
$XTextMapper->SetInput($XText->GetOutput);
$XActor = Graphics::VTK::Follower->new;
$XActor->SetMapper($XTextMapper);
$XActor->SetScale(0.02,'.02','.02');
$XActor->SetPosition(0.35,-0.05,-0.05);
$XActor->GetProperty->SetColor(0,0,0);
$YText = Graphics::VTK::VectorText->new;
$YText->SetText($yAxis);
$YTextMapper = Graphics::VTK::PolyDataMapper->new;
$YTextMapper->SetInput($YText->GetOutput);
$YActor = Graphics::VTK::Follower->new;
$YActor->SetMapper($YTextMapper);
$YActor->SetScale(0.02,'.02','.02');
$YActor->SetPosition(-0.05,0.35,-0.05);
$YActor->GetProperty->SetColor(0,0,0);
$ZText = Graphics::VTK::VectorText->new;
$ZText->SetText($zAxis);
$ZTextMapper = Graphics::VTK::PolyDataMapper->new;
$ZTextMapper->SetInput($ZText->GetOutput);
$ZActor = Graphics::VTK::Follower->new;
$ZActor->SetMapper($ZTextMapper);
$ZActor->SetScale(0.02,'.02','.02');
$ZActor->SetPosition(-0.05,-0.05,0.35);
$ZActor->GetProperty->SetColor(0,0,0);
# Graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetWindowName("vtk - Field Data");
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($axesActor);
$ren1->AddActor($lateActor);
$ren1->AddActor($XActor);
$ren1->AddActor($YActor);
$ren1->AddActor($ZActor);
$ren1->AddActor('popActor');
#it's last because its translucent
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange('.274',13.72);
$camera->SetFocalPoint(0.433816,0.333131,0.449);
$camera->SetPosition(-1.96987,1.15145,1.49053);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0.378927,0.911821,0.158107);
$ren1->SetActiveCamera($camera);
$XActor->SetCamera($camera);
$YActor->SetCamera($camera);
$ZActor->SetCamera($camera);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->Render;
$renWin->SetFileName("financialField.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
