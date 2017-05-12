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
$source->______imaging_examplesTcl_vtkImageInclude_tcl;
$source->______imaging_examplesTcl_TkImageViewerInteractor_tcl;
$cone = Graphics::VTK::ConeSource->new;
$cone->SetHeight(1.5);
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->GetProperty->SetColor(0.8,0.9,1.0);
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor->GetProperty->SetColor(0.7,1.0,0.7);
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetBackground(0.8,0.4,0.3);
# WinNT mixes both background colors in a stripped pattern
#ren1 SetBackground  0.1 0.2 0.4
$ren1->AddActor($sphereActor);
$ren2 = Graphics::VTK::Renderer->new;
$ren2->SetBackground(0.8,0.4,0.3);
$ren2->AddActor($coneActor);
$ren2->SetActiveCamera($ren1->GetActiveCamera);
$renWin1 = Graphics::VTK::RenderWindow->new;
$renWin1->AddRenderer($ren1);
$renWin1->SetPosition(10,10);
$renWin1->SetSize(256,256);
$renWin2 = Graphics::VTK::RenderWindow->new;
$renWin2->AddRenderer($ren2);
$renWin2->SetPosition(275,10);
$renWin2->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin1);
$renWin1->Render;
$renWin2->Render;
$ren1Image = Graphics::VTK::RendererSource->new;
$ren1Image->SetInput($ren1);
$ren1Image->DepthValuesOn;
$ren1Image->Update;
$ren2Image = Graphics::VTK::RendererSource->new;
$ren2Image->SetInput($ren2);
$ren2Image->DepthValuesOn;
$ren2Image->Update;
$composite = Graphics::VTK::ImageComposite->new;
$composite->AddInput($ren1Image->GetOutput);
$composite->AddInput($ren2Image->GetOutput);
# through up the zbuffer
$zScalars = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$zScalars->SetInput($composite->GetOutput);
#zScalars SetInput [ren2Image GetOutput]
$zScalars->SetInputFieldToPointDataField;
$zScalars->SetOutputAttributeDataToPointData;
$zScalars->SetScalarComponent(0,'ZBuffer',0);
#tk_messageBox -message [[[[zScalars GetOutput] GetPointData] GetScalars] Print]
$viewer = Graphics::VTK::ImageViewer->new;
#viewer SetColorLevel 0.5
#viewer SetColorWindow 1.0
#viewer SetInput [zScalars GetOutput]
$viewer->SetColorLevel(127.5);
$viewer->SetColorWindow(255);
$viewer->SetInput($composite->GetOutput);
$viewer->GetImageWindow->DoubleBufferOn;
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer);
#    BindTkRenderWidget .top.f1.r1
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
#BindTkImageViewer .top.f1.r1 
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
