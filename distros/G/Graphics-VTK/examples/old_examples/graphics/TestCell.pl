#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# user interface command widget
use Graphics::VTK::Tk::vtkInt;
# create a rendering window and renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create an actor and give it cone geometry
$spts = Graphics::VTK::StructuredPoints->new;
$spts->SetDimensions(3,3,1);
$scalars = Graphics::VTK::Scalars->new;
$scalars->InsertNextScalar(1);
$scalars->InsertNextScalar(3);
$scalars->InsertNextScalar(2);
$scalars->InsertNextScalar(4);
$normals = Graphics::VTK::Normals->new;
$normals->InsertNextNormal(1,0,0);
$normals->InsertNextNormal('.7',0,'.7');
$normals->InsertNextNormal(0,0,1);
$normals->InsertNextNormal(0,'.7','.7');
$spts->GetCellData->SetScalars($scalars);
$spts->GetCellData->SetNormals($normals);
$aMapper = Graphics::VTK::DataSetMapper->new;
$aMapper->SetInput($spts);
#  aMapper SetInput pd
$aMapper->SetScalarRange(1,4);
$anActor = Graphics::VTK::Actor->new;
$anActor->SetMapper($aMapper);
# assign our actor to the renderer
$ren1->AddActor($anActor);
# enable user interface interactor
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
