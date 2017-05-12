#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Created oriented text
use Graphics::VTK::Tk::vtkInt;
# pipeline
$text0Source = Graphics::VTK::TextSource->new;
$text0Source->SetText("Text Source with Scalars (default)");
$text0Mapper = Graphics::VTK::PolyDataMapper->new;
$text0Mapper->SetInput($text0Source->GetOutput);
$text0Actor = Graphics::VTK::Actor->new;
$text0Actor->SetMapper($text0Mapper);
$text0Actor->SetScale('.1','.1','.1');
$text0Actor->AddPosition(0,2,0);
$text1Source = Graphics::VTK::TextSource->new;
$text1Source->SetText("Text Source with Scalars");
$text1Source->SetForegroundColor(1,0,0);
$text1Source->SetBackgroundColor(1,1,1);
$text1Mapper = Graphics::VTK::PolyDataMapper->new;
$text1Mapper->SetInput($text1Source->GetOutput);
$text1Actor = Graphics::VTK::Actor->new;
$text1Actor->SetMapper($text1Mapper);
$text1Actor->SetScale('.1','.1','.1');
$text2Source = Graphics::VTK::TextSource->new;
$text2Source->SetText("Text Source without Scalars");
$text2Source->BackingOff;
$text2Mapper = Graphics::VTK::PolyDataMapper->new;
$text2Mapper->SetInput($text2Source->GetOutput);
$text2Mapper->ScalarVisibilityOff;
$text2Actor = Graphics::VTK::Actor->new;
$text2Actor->SetMapper($text2Mapper);
$text2Actor->GetProperty->SetColor(1,1,0);
$text2Actor->SetScale('.1','.1','.1');
$text2Actor->AddPosition(0,-2,0);
$text3Source = Graphics::VTK::VectorText->new;
$text3Source->SetText("Vector Text");
$text3Mapper = Graphics::VTK::PolyDataMapper->new;
$text3Mapper->SetInput($text3Source->GetOutput);
$text3Mapper->ScalarVisibilityOff;
$text3Actor = Graphics::VTK::Actor->new;
$text3Actor->SetMapper($text3Mapper);
$text3Actor->GetProperty->SetColor('.1',1,0);
$text3Actor->AddPosition(0,-4,0);
# create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(500,500);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($text0Actor);
$ren1->AddActor($text1Actor);
$ren1->AddActor($text2Actor);
$ren1->AddActor($text3Actor);
$ren1->GetActiveCamera->Zoom(1.5);
$ren1->SetBackground('.1','.2','.4');
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "text.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
