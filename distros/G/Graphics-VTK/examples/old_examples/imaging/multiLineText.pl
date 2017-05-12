#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrate the use of multiline 2D text
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$singleLineTextB = Graphics::VTK::TextMapper->new;
$singleLineTextB->SetInput("Single line (bottom)");
$singleLineTextB->SetFontSize(14);
$singleLineTextB->SetFontFamilyToArial;
$singleLineTextB->BoldOff;
$singleLineTextB->ItalicOff;
$singleLineTextB->ShadowOff;
$singleLineTextB->SetVerticalJustificationToBottom;
$singleLineTextActorB = Graphics::VTK::Actor2D->new;
$singleLineTextActorB->SetMapper($singleLineTextB);
$singleLineTextActorB->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$singleLineTextActorB->GetPositionCoordinate->SetValue(0.05,0.85);
$singleLineTextActorB->GetProperty->SetColor(1,0,0);
$singleLineTextC = Graphics::VTK::TextMapper->new;
$singleLineTextC->SetInput("Single line (centered)");
$singleLineTextC->SetFontSize(14);
$singleLineTextC->SetFontFamilyToArial;
$singleLineTextC->BoldOff;
$singleLineTextC->ItalicOff;
$singleLineTextC->ShadowOff;
$singleLineTextC->SetVerticalJustificationToCentered;
$singleLineTextActorC = Graphics::VTK::Actor2D->new;
$singleLineTextActorC->SetMapper($singleLineTextC);
$singleLineTextActorC->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$singleLineTextActorC->GetPositionCoordinate->SetValue(0.05,0.75);
$singleLineTextActorC->GetProperty->SetColor(0,1,0);
$singleLineTextT = Graphics::VTK::TextMapper->new;
$singleLineTextT->SetInput("Single line (top)");
$singleLineTextT->SetFontSize(14);
$singleLineTextT->SetFontFamilyToArial;
$singleLineTextT->BoldOff;
$singleLineTextT->ItalicOff;
$singleLineTextT->ShadowOff;
$singleLineTextT->SetVerticalJustificationToTop;
$singleLineTextActorT = Graphics::VTK::Actor2D->new;
$singleLineTextActorT->SetMapper($singleLineTextT);
$singleLineTextActorT->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$singleLineTextActorT->GetPositionCoordinate->SetValue(0.05,0.65);
$singleLineTextActorT->GetProperty->SetColor(0,0,1);
$textMapperL = Graphics::VTK::TextMapper->new;
$textMapperL->SetInput("This is\nmulti-line\ntext output\n(left-top)");
$textMapperL->SetFontSize(14);
$textMapperL->SetFontFamilyToArial;
$textMapperL->BoldOn;
$textMapperL->ItalicOn;
$textMapperL->ShadowOn;
$textMapperL->SetJustificationToLeft;
$textMapperL->SetVerticalJustificationToTop;
$textMapperL->SetLineSpacing(0.8);
$textActorL = Graphics::VTK::Actor2D->new;
$textActorL->SetMapper($textMapperL);
$textActorL->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$textActorL->GetPositionCoordinate->SetValue(0.05,0.5);
$textActorL->GetProperty->SetColor(1,0,0);
$textMapperC = Graphics::VTK::TextMapper->new;
$textMapperC->SetInput("This is\nmulti-line\ntext output\n(centered)");
$textMapperC->SetFontSize(14);
$textMapperC->SetFontFamilyToArial;
$textMapperC->BoldOn;
$textMapperC->ItalicOn;
$textMapperC->ShadowOn;
$textMapperC->SetJustificationToCentered;
$textMapperC->SetVerticalJustificationToCentered;
$textMapperC->SetLineSpacing(0.8);
$textActorC = Graphics::VTK::Actor2D->new;
$textActorC->SetMapper($textMapperC);
$textActorC->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$textActorC->GetPositionCoordinate->SetValue(0.5,0.5);
$textActorC->GetProperty->SetColor(0,1,0);
$textMapperR = Graphics::VTK::TextMapper->new;
$textMapperR->SetInput("This is\nmulti-line\ntext output\n(right-bottom)");
$textMapperR->SetFontSize(14);
$textMapperR->SetFontFamilyToArial;
$textMapperR->BoldOn;
$textMapperR->ItalicOn;
$textMapperR->ShadowOn;
$textMapperR->SetJustificationToRight;
$textMapperR->SetVerticalJustificationToBottom;
$textMapperR->SetLineSpacing(0.8);
$textActorR = Graphics::VTK::Actor2D->new;
$textActorR->SetMapper($textMapperR);
$textActorR->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$textActorR->GetPositionCoordinate->SetValue(0.95,0.5);
$textActorR->GetProperty->SetColor(0,0,1);
$Pts = Graphics::VTK::Points->new;
$Pts->InsertNextPoint(0.05,0.0,0.0);
$Pts->InsertNextPoint(0.05,1.0,0.0);
$Pts->InsertNextPoint(0.5,0.0,0.0);
$Pts->InsertNextPoint(0.5,1.0,0.0);
$Pts->InsertNextPoint(0.95,0.0,0.0);
$Pts->InsertNextPoint(0.95,1.0,0.0);
$Pts->InsertNextPoint(0.0,0.5,0.0);
$Pts->InsertNextPoint(1.0,0.5,0.0);
$Pts->InsertNextPoint(0.00,0.85,0.0);
$Pts->InsertNextPoint(0.50,0.85,0.0);
$Pts->InsertNextPoint(0.00,0.75,0.0);
$Pts->InsertNextPoint(0.50,0.75,0.0);
$Pts->InsertNextPoint(0.00,0.65,0.0);
$Pts->InsertNextPoint(0.50,0.65,0.0);
$Lines = Graphics::VTK::CellArray->new;
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(0);
$Lines->InsertCellPoint(1);
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(2);
$Lines->InsertCellPoint(3);
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(4);
$Lines->InsertCellPoint(5);
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(6);
$Lines->InsertCellPoint(7);
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(8);
$Lines->InsertCellPoint(9);
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(10);
$Lines->InsertCellPoint(11);
$Lines->InsertNextCell(2);
$Lines->InsertCellPoint(12);
$Lines->InsertCellPoint(13);
$Grid = Graphics::VTK::PolyData->new;
$Grid->SetPoints($Pts);
$Grid->SetLines($Lines);
$normCoords = Graphics::VTK::Coordinate->new;
$normCoords->SetCoordinateSystemToNormalizedViewport;
$mapper = Graphics::VTK::PolyDataMapper2D->new;
$mapper->SetInput($Grid);
$mapper->SetTransformCoordinate($normCoords);
$gridActor = Graphics::VTK::Actor2D->new;
$gridActor->SetMapper($mapper);
$gridActor->GetProperty->SetColor(0.1,0.1,0.1);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor2D($textActorL);
$ren1->AddActor2D($textActorC);
$ren1->AddActor2D($textActorR);
$ren1->AddActor2D($singleLineTextActorB);
$ren1->AddActor2D($singleLineTextActorC);
$ren1->AddActor2D($singleLineTextActorT);
$ren1->AddActor2D($gridActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,300);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
$renWin->SetFileName("multiLineText.tcl.ppm");
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
