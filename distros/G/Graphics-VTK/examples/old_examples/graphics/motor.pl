#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of motor visualization
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create cutting planes
$planes = Graphics::VTK::Planes->new;
$points = Graphics::VTK::Points->new;
$norms = Graphics::VTK::Normals->new;
$points->InsertPoint(0,0.0,0.0,0.0);
$norms->InsertNormal(0,0.0,0.0,1.0);
$points->InsertPoint(1,0.0,0.0,0.0);
$norms->InsertNormal(1,-1.0,0.0,0.0);
$planes->SetPoints($points);
$planes->SetNormals($norms);
# texture
$texReader = Graphics::VTK::StructuredPointsReader->new;
$texReader->SetFileName("$VTK_DATA/texThres2.vtk");
$texture = Graphics::VTK::Texture->new;
$texture->SetInput($texReader->GetOutput);
$texture->InterpolateOff;
$texture->RepeatOff;
# read motor parts...each part colored separately
$byu = Graphics::VTK::BYUReader->new;
$byu->SetGeometryFileName("$VTK_DATA/motor.g");
$byu->SetPartNumber(1);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($byu->GetOutput);
$tex1 = Graphics::VTK::ImplicitTextureCoords->new;
$tex1->SetInput($normals->GetOutput);
$tex1->SetRFunction($planes);
#    tex1 FlipTextureOn
$byuMapper = Graphics::VTK::DataSetMapper->new;
$byuMapper->SetInput($tex1->GetOutput);
$byuActor = Graphics::VTK::Actor->new;
$byuActor->SetMapper($byuMapper);
$byuActor->SetTexture($texture);
$byuActor->GetProperty->SetColor(@Graphics::VTK::Colors::cold_grey);
$byu2 = Graphics::VTK::BYUReader->new;
$byu2->SetGeometryFileName("$VTK_DATA/motor.g");
$byu2->SetPartNumber(2);
$normals2 = Graphics::VTK::PolyDataNormals->new;
$normals2->SetInput($byu2->GetOutput);
$tex2 = Graphics::VTK::ImplicitTextureCoords->new;
$tex2->SetInput($normals2->GetOutput);
$tex2->SetRFunction($planes);
#    tex2 FlipTextureOn
$byuMapper2 = Graphics::VTK::DataSetMapper->new;
$byuMapper2->SetInput($tex2->GetOutput);
$byuActor2 = Graphics::VTK::Actor->new;
$byuActor2->SetMapper($byuMapper2);
$byuActor2->SetTexture($texture);
$byuActor2->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$byu3 = Graphics::VTK::BYUReader->new;
$byu3->SetGeometryFileName("$VTK_DATA/motor.g");
$byu3->SetPartNumber(3);
$triangle3 = Graphics::VTK::TriangleFilter->new;
$triangle3->SetInput($byu3->GetOutput);
$normals3 = Graphics::VTK::PolyDataNormals->new;
$normals3->SetInput($triangle3->GetOutput);
$tex3 = Graphics::VTK::ImplicitTextureCoords->new;
$tex3->SetInput($normals3->GetOutput);
$tex3->SetRFunction($planes);
#    tex3 FlipTextureOn
$byuMapper3 = Graphics::VTK::DataSetMapper->new;
$byuMapper3->SetInput($tex3->GetOutput);
$byuActor3 = Graphics::VTK::Actor->new;
$byuActor3->SetMapper($byuMapper3);
$byuActor3->SetTexture($texture);
$byuActor3->GetProperty->SetColor(@Graphics::VTK::Colors::raw_sienna);
$byu4 = Graphics::VTK::BYUReader->new;
$byu4->SetGeometryFileName("$VTK_DATA/motor.g");
$byu4->SetPartNumber(4);
$normals4 = Graphics::VTK::PolyDataNormals->new;
$normals4->SetInput($byu4->GetOutput);
$tex4 = Graphics::VTK::ImplicitTextureCoords->new;
$tex4->SetInput($normals4->GetOutput);
$tex4->SetRFunction($planes);
#    tex4 FlipTextureOn
$byuMapper4 = Graphics::VTK::DataSetMapper->new;
$byuMapper4->SetInput($tex4->GetOutput);
$byuActor4 = Graphics::VTK::Actor->new;
$byuActor4->SetMapper($byuMapper4);
$byuActor4->SetTexture($texture);
$byuActor4->GetProperty->SetColor(@Graphics::VTK::Colors::banana);
$byu5 = Graphics::VTK::BYUReader->new;
$byu5->SetGeometryFileName("$VTK_DATA/motor.g");
$byu5->SetPartNumber(5);
$normals5 = Graphics::VTK::PolyDataNormals->new;
$normals5->SetInput($byu5->GetOutput);
$tex5 = Graphics::VTK::ImplicitTextureCoords->new;
$tex5->SetInput($normals5->GetOutput);
$tex5->SetRFunction($planes);
#    tex5 FlipTextureOn
$byuMapper5 = Graphics::VTK::DataSetMapper->new;
$byuMapper5->SetInput($tex5->GetOutput);
$byuActor5 = Graphics::VTK::Actor->new;
$byuActor5->SetMapper($byuMapper5);
$byuActor5->SetTexture($texture);
$byuActor5->GetProperty->SetColor(@Graphics::VTK::Colors::peach_puff);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($byuActor);
$ren1->AddActor($byuActor2);
$ren1->AddActor($byuActor3);
$byuActor3->VisibilityOff;
$ren1->AddActor($byuActor4);
$ren1->AddActor($byuActor5);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$camera = Graphics::VTK::Camera->new;
$camera->SetFocalPoint(0.0286334,0.0362996,0.0379685);
$camera->SetPosition(1.37067,1.08629,-1.30349);
$camera->ComputeViewPlaneNormal;
$camera->SetViewAngle(17.673);
$camera->SetClippingRange(1,10);
$camera->SetViewUp(-0.376306,-0.5085,-0.774482);
$ren1->SetActiveCamera($camera);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("motor.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
