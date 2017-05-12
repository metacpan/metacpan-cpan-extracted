#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read data
$reader = Graphics::VTK::PLOT3DReader->new;
$reader->SetXYZFileName("$VTK_DATA/combxyz.bin");
$reader->SetQFileName("$VTK_DATA/combq.bin");
$reader->SetScalarFunctionNumber(210);
$reader->Update;
# create outline
$outlineF = Graphics::VTK::StructuredGridOutlineFilter->new;
$outlineF->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outlineF->GetOutput);
$outline = Graphics::VTK::Actor->new;
$outline->SetMapper($outlineMapper);
$outline->GetProperty->SetColor(0,0,0);
# create cursor
$cursor = Graphics::VTK::Cursor3D->new;
$cursor->SetFocalPoint($reader->GetOutput->GetCenter);
$cursor->SetModelBounds($reader->GetOutput->GetBounds);
$cursor->AllOff;
$cursor->AxesOn;
$cursor->OutlineOn;
$cursor->XShadowsOn;
$cursor->YShadowsOn;
$cursor->ZShadowsOn;
$cursorMapper = Graphics::VTK::PolyDataMapper->new;
$cursorMapper->SetInput($cursor->GetOutput);
$cursorActor = Graphics::VTK::Actor->new;
$cursorActor->SetMapper($cursorMapper);
$cursorActor->GetProperty->SetColor(1,0,0);
# create probe
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetSource($reader->GetOutput);
$probe->SetInput($cursor->GetFocus);
# create a cone geometry for glyph
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(16);
$cone->SetRadius(0.25);
# create glyph
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($probe->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseVector;
$glyph->SetScaleModeToScaleByScalar;
$glyph->SetScaleFactor('.0002');
$glyphMapper = Graphics::VTK::PolyDataMapper->new;
$glyphMapper->SetInput($glyph->GetOutput);
$glyphActor = Graphics::VTK::Actor->new;
$glyphActor->SetMapper($glyphMapper);
$ren1->AddActor($outline);
$ren1->AddActor($cursorActor);
$ren1->AddActor($glyphActor);
$ren1->SetBackground(1.0,1.0,1.0);
$renWin->SetSize(300,300);
$ren1->GetActiveCamera->Elevation(60);
$ren1->ResetCameraClippingRange;
$renWin->Render;
#renWin SetFileName cursor3D.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
