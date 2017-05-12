#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this regression test was contributed by:
# Dr. Alexander Supalov
# GMD  -- German National Research Center for Information Technology
# SCAI -- Institute for Algorithms and Scientific Computing
# Schloss Birlinghoven                    phone:  +49 2241 14 2371
# 53754 Sankt Augustin                    fax:    +49 2241 14 2181
# Germany                                 e-mail: supalov@gmd.de
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$MW->withdraw;
#	input static grid data once
$r = Graphics::VTK::UnstructuredGridReader->new;
$r->SetFileName("$VTK_DATA/dualgrid.vtk");
$r->Update;
#	input cell attributes
$c = Graphics::VTK::DataObjectReader->new;
$c->SetFileName("$VTK_DATA/dualcell.vtk");
$c->Update;
#	input selected step data
$s = Graphics::VTK::DataObjectReader->new;
$s->SetFileName("$VTK_DATA/dualpoint.vtk");
$s->Update;
#	combine the grid and step data
$cs = Graphics::VTK::Scalars->new;
$cs->SetData($c->GetOutput->GetFieldData->GetArray(0));
$r->GetOutput->GetCellData->SetScalars($cs);

$ps = Graphics::VTK::Scalars->new;
$ps->SetData($s->GetOutput->GetFieldData->GetArray(0));
$r->GetOutput->GetPointData->SetScalars($ps);

#	now, business as usual
$f1 = Graphics::VTK::GeometryFilter->new;
$f1->SetInput($r->GetOutput);
$f = Graphics::VTK::PolyDataNormals->new;
$f->SetInput($f1->GetOutput);
$l = Graphics::VTK::LookupTable->new;
$l->SetHueRange(0.66667,0.0);
$m = Graphics::VTK::PolyDataMapper->new;
$m->SetInput($f->GetOutput);
$m->SetScalarModeToUsePointData;
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
$renWin->SetFileName('valid/dualfile.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
