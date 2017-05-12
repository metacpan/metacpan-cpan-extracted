#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# A very basic medical image volume visualization tool
# When you run this example, type 'o' and 'c' to switch
# between object and camera interaction,  otherwise you
# will miss the full effect
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# read data file
# set the origin so that (0.0,0.0,0.0) is the center of the image
# some Tcl-induced shenanigans...
$array->set('spacing','0 1.0 1 1.0 2 2.0');
$array->set('extent','0 0 1 255 2 0 3 255 4 1 5 93');
$array->set('origin','0 -127.5 1 -127.5 2 -94.0');
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataSpacing($spacing{0},$spacing{1},$spacing{2});
$reader->SetDataExtent($extent{0},$extent{1},$extent{2},$extent{3},$extent{4},$extent{5});
$reader->SetDataOrigin($origin{0},$origin{1},$origin{2});
$reader->SetFilePrefix("../../../vtkdata/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->UpdateWholeExtent;
# transform shared by reslice filter and texture mapped plane actor
$transform = Graphics::VTK::Transform->new;
# slice extraction filter
$reslice = Graphics::VTK::ImageReslice->new;
$reslice->SetInput($reader->GetOutput);
$reslice->SetResliceTransform($transform);
$reslice->InterpolateOn;
$reslice->SetBackgroundLevel(1023);
$reslice->SetOutputSpacing($spacing{0},$spacing{1},$spacing{2});
$reslice->SetOutputOrigin($origin{0},$origin{1},0.0);
$reslice->SetOutputExtent($extent{0},$extent{1},$extent{2},$extent{3},0,0);
# lookup table for texture map
$table = Graphics::VTK::LookupTable->new;
$table->SetTableRange(100,2000);
$table->SetSaturationRange(0,0);
$table->SetHueRange(0,0);
$table->SetValueRange(0,1);
$table->Build;
# texture from reslice filter
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($reslice->GetOutput);
$atext->SetLookupTable($table);
$atext->InterpolateOn;
# need a plane to texture map onto
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetXResolution(1);
$plane->SetYResolution(1);
$plane->SetOrigin($origin{0} + $spacing{0} * $extent{0} - 0.5,$origin{1} + $spacing{1} * $extent{2} - 0.5,0.0);
$plane->SetPoint1($origin{0} + $spacing{0} * $extent{1} + 0.5,$origin{1} + $spacing{1} * $extent{2} - 0.5,0.0);
$plane->SetPoint2($origin{0} + $spacing{0} * $extent{0} - 0.5,$origin{1} + $spacing{1} * $extent{3} + 0.5,0.0);
# generate texture coordinates
$tmapper = Graphics::VTK::TextureMapToPlane->new;
$tmapper->SetInput($plane->GetOutput);
# mapper for the textured plane
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($tmapper->GetOutput);
# put everything together (note that the same transform
# is used for slice extraction and actor positioning)
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->SetTexture($atext);
$actor->SetUserMatrix($transform->GetMatrix);
$actor->SetOrigin(0.0,0.0,0.0);
# create rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# add a frame around the volume
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(1.0000,0.8431,0.0000);
# add the actors to the renderer, set the background and size
$ren1->AddActor($actor);
$ren1->AddActor($outlineActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# apply transformations
$transform->RotateX(10.0);
$transform->RotateY(10.0);
# don't show the tcl window
$MW->withdraw;
# render the image
$renWin->Render;
$renWin->SetFileName("TextureReslice.tcl.ppm");
#renWin SaveImageAsPPM

Tk->MainLoop;
