#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# use implicit modeller to create a logo
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# get some nice colors
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# make the letter v
$letterV = Graphics::VTK::VectorText->new;
$letterV->SetText('v');
$letterVTris = Graphics::VTK::TriangleFilter->new;
$letterVTris->SetInput($letterV->GetOutput);
$letterVStrips = Graphics::VTK::Stripper->new;
$letterVStrips->SetInput($letterVTris->GetOutput);
# read the geometry file containing the letter t
$letterT = Graphics::VTK::VectorText->new;
$letterT->SetText('t');
# read the geometry file containing the letter k
$letterK = Graphics::VTK::VectorText->new;
$letterK->SetText('k');
# create a transform and transform filter for each letter
$VTransform = Graphics::VTK::Transform->new;
$VTransformFilter = Graphics::VTK::TransformPolyDataFilter->new;
$VTransformFilter->SetInput($letterVStrips->GetOutput);
$VTransformFilter->SetTransform($VTransform);
$TTransform = Graphics::VTK::Transform->new;
$TTransformFilter = Graphics::VTK::TransformPolyDataFilter->new;
$TTransformFilter->SetInput($letterT->GetOutput);
$TTransformFilter->SetTransform($TTransform);
$KTransform = Graphics::VTK::Transform->new;
$KTransformFilter = Graphics::VTK::TransformPolyDataFilter->new;
$KTransformFilter->SetInput($letterK->GetOutput);
$KTransformFilter->SetTransform($KTransform);
# now append them all
$appendAll = Graphics::VTK::AppendPolyData->new;
$appendAll->AddInput($VTransformFilter->GetOutput);
$appendAll->AddInput($TTransformFilter->GetOutput);
$appendAll->AddInput($KTransformFilter->GetOutput);
# create normals
$logoNormals = Graphics::VTK::PolyDataNormals->new;
$logoNormals->SetInput($appendAll->GetOutput);
$logoNormals->SetFeatureAngle(60);
# map to rendering primitives
$logoMapper = Graphics::VTK::PolyDataMapper->new;
$logoMapper->SetInput($logoNormals->GetOutput);
# now an actor
$logo = Graphics::VTK::Actor->new;
$logo->SetMapper($logoMapper);
# now create an implicit model of the same letter
$blobbyLogoImp = Graphics::VTK::ImplicitModeller->new;
$blobbyLogoImp->SetInput($appendAll->GetOutput);
$blobbyLogoImp->SetMaximumDistance('.2');
$blobbyLogoImp->SetSampleDimensions(64,64,64);
$blobbyLogoImp->SetAdjustDistance('.5');
# extract an iso surface
$blobbyLogoIso = Graphics::VTK::ContourFilter->new;
$blobbyLogoIso->SetInput($blobbyLogoImp->GetOutput);
$blobbyLogoIso->SetValue(1,'.1');
# make normals
$blobbyLogoNormals = Graphics::VTK::PolyDataNormals->new;
$blobbyLogoNormals->SetInput($blobbyLogoIso->GetOutput);
$blobbyLogoNormals->SetFeatureAngle(60.0);
$blobbyLogoNormals->SetMaxRecursionDepth(100);
# map to rendering primitives
$blobbyLogoMapper = Graphics::VTK::PolyDataMapper->new;
$blobbyLogoMapper->SetInput($blobbyLogoNormals->GetOutput);
$blobbyLogoMapper->ScalarVisibilityOff;
# now an actor
$blobbyLogo = Graphics::VTK::Actor->new;
$blobbyLogo->SetMapper($blobbyLogoMapper);
$blobbyLogo->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$blobbyLogo->GetProperty->SetOpacity('.5');
# position the letters
$VTransform->Identity;
$VTransform->Translate('-.5',0,'.7');
$VTransform->RotateY(50);
$KTransform->Identity;
$KTransform->Translate('.5',0,'-.1');
$KTransform->RotateY(-50);
# move the polygonal letters to the front
$logo->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$logo->SetPosition(0,0,0);
$aCam = Graphics::VTK::Camera->new;
$aCam->SetFocalPoint(0.340664,0.470782,0.34374);
$aCam->SetPosition(0.698674,1.45247,2.89482);
$aCam->ComputeViewPlaneNormal;
$aCam->SetViewAngle(30);
$aCam->SetViewUp(0,1,0);
#  now  make a renderer and tell it about lights and actors
$renWin->SetSize(640,480);
$ren1->SetActiveCamera($aCam);
$ren1->AddActor($logo);
$ren1->AddActor($blobbyLogo);
$ren1->SetBackground(1,1,1);
$renWin->Render;
#renWin SetFileName vtkLogo.tcl.ppm
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
