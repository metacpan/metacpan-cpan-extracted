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
# Test field data reading - Thanks to Alexander Supalov
$MW->withdraw;
$r = Graphics::VTK::DataSetReader->new;
$r->SetFileName("$VTK_DATA/fieldfile.vtk");
$r->Update;
$w = Graphics::VTK::DataSetWriter->new;
$w->SetFileName("fieldfile.vtk");
$w->SetInput($r->GetOutput);
$w->Update;
$a = $r->GetOutput->GetCellData->GetFieldData->GetArray(0);
$s = Graphics::VTK::Scalars->new;
$s->SetData($a);
$r->GetOutput->GetCellData->SetScalars($s);

$f = Graphics::VTK::GeometryFilter->new;
$f->SetInput($r->GetOutput);
$l = Graphics::VTK::LookupTable->new;
$l->SetHueRange(0.66667,0.0);
$m = Graphics::VTK::DataSetMapper->new;
$m->SetInput($f->GetOutput);
$m->SetLookupTable($l);
$m->SetScalarRange(1,3);
$p = Graphics::VTK::Property->new;
$p->SetDiffuse(0.5);
$p->SetAmbient(0.5);
$a = Graphics::VTK::Actor->new;
$a->SetMapper($m);
$a->SetProperty($p);
$ren = Graphics::VTK::Renderer->new;
$ren->AddActor($a);
$ren->SetBackground(1,1,1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren);
$renWin->SetInteractor($iren);
$renWin->Render;
$renWin->SetFileName('valid/fieldfile.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
