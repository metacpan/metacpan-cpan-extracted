#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# an example of deleting a rendering window
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$ls = Graphics::VTK::SphereSource->new;
$pdm = Graphics::VTK::PolyDataMapper->new;
$pdm->SetInput($ls->GetOutput);
$a1 = Graphics::VTK::Actor->new;
$a1->SetMapper($pdm);
$ren1->AddActor($a1);
$renWin->SetSize(400,400);
$a1->GetProperty->SetColor(0.6,0.4,1.0);
$ren1->SetBackground(0.5,0.7,0.3);
$renWin->Render;
# delete the old ones
$rename->_renWin('');
$rename->_ren1('');
# create a new window
$renWin = Graphics::VTK::RenderWindow->new;
$ren1 = Graphics::VTK::Renderer->new;
$renWin->AddRenderer($ren1);
$ren1->AddActor($a1);
$renWin->SetSize(300,300);
$a1->GetProperty->SetColor(0.4,0.6,1.0);
$ren1->SetBackground(0.7,0.5,0.3);
$renWin->Render;
exit();
