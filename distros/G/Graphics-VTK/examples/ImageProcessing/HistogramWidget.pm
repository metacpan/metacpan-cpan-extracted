#!/usr/local/bin/perl -w
#
#
#   Histogram widget for the test script Histogram.pl
#
#
package Graphics::VTK::Tk::HistogramWidget;
use Tk;

use Graphics::VTK;
use Carp;

use base  qw(Tk::Derived Tk::Frame);

Tk::Widget->Construct("HistogramWidget");

# creates a meta object which clips a region of the input, and
# draws a histogram for the data.

# create a histogram object
#
sub Populate {
    	my ($widget, $args) = @_;
    
    	$widget->SUPER::Populate($args);
	my $accumulate;
	my $actor;
	my $canvas;
	my $clip;
	my $imager;
	my $mapper;
	my $viewer;
	$clip = $widget->{'Clip'} = Graphics::VTK::ImageClip->new;
	$accumulate = $widget->{'Accumulate'} = Graphics::VTK::ImageAccumulate->new;
	$canvas = $widget->{'Canvas'} = Graphics::VTK::ImageCanvasSource2D->new;
	$canvas->SetNumberOfScalarComponents(1);
	$canvas->SetScalarTypeToUnsignedChar;
	#$viewer = $widget->{'Viewer'} = Graphics::VTK::ImageViewer->new;
	#$viewer->SetColorWindow(256);
	#$viewer->SetColorLevel(127);
    	my $top = $widget->Component('Frame', 'top');
	my $vtkImageViewer = $widget->Component('vtkImageViewer', 'vtkImageViewer', 
							-delegate => ['Render', 'GetImageViewer'], # render method is delegate to vtkImageViewer
							'-width',512,'-height',200);
	#						-iv => $viewer);

	$viewer = $widget->{'Viewer'} = $vtkImageViewer->cget(-iv);
	$viewer->SetColorWindow(256);
	$viewer->SetColorLevel(127);
	# Delegate options to this widget
	$widget->ConfigSpecs(
	   DEFAULT => [$vtkImageViewer],
	   );


	$accumulate->SetInput($clip->GetOutput);
	$viewer->SetInput($canvas->GetOutput);

	# create text actor for value display
	$mapper = $widget->{'Mapper1'} = Graphics::VTK::TextMapper->new;
	$mapper->SetInput("none");
	$mapper->SetFontFamilyToTimes;
	$mapper->SetFontSize(18);
	$mapper->BoldOn;
	$mapper->ShadowOn;
	$actor = $widget->{'Actor1'} = Graphics::VTK::Actor2D->new;
	$actor->SetMapper($mapper);
	$actor->SetLayerNumber(1);
	$actor->GetPositionCoordinate->SetValue(4,4);
	$actor->GetProperty->SetColor(0,0.8,0);
	$actor->SetVisibility(0);
	$imager = $vtkImageViewer->GetImageViewer->GetRenderer;
	$imager->AddActor2D($actor);
	# line 2
	$mapper = $widget->{'Mapper2'} = Graphics::VTK::TextMapper->new;
	$mapper->SetInput("none");
	$mapper->SetFontFamilyToTimes;
	$mapper->SetFontSize(18);
	$mapper->BoldOn;
	$mapper->ShadowOn;
	$actor = $widget->{'Actor2'} = Graphics::VTK::Actor2D->new;
	$actor->SetMapper($mapper);
	$actor->SetLayerNumber(1);
	$actor->GetPositionCoordinate->SetValue(4,4);
	$actor->GetProperty->SetColor(0,0.8,0);
	$actor->SetVisibility(0);
	$imager = $vtkImageViewer->GetImageViewer->GetRenderer;
	$imager->AddActor2D($actor);

	$vtkImageViewer->pack(-expand => 'y', -fill => 'both');
	
	#$widget->OnDestroy(sub{ $viewer->DESTROY});
	return $widget;
}


# Sets the input
#
sub SetInput
{
 my $widget = shift;
 my $input = shift;
 my $clip;
 $clip = $widget->{'Clip'};
 $clip->SetInput($input);
}

# Render
#
sub HistogramWidgetRender
{
 my $widget = shift;
 my $accumulate;
 my $canvas;
 my $data;
 my $height;
 my $histRange;
 my $idx;
 my $inputRange;
 my $numBins;
 my $origin;
 my $scale;
 my $spacing;
 my $split;
 my $width;
 my $x;
 my $y;
 my $y1;
 my $y2;
 # get the size of the histogram window
 $width = $widget->cget('-width');
 $height = $widget->cget('-height');
 # setup the bins of the accumulate filter from the range of input data
 $accumulate = $widget->{'Accumulate'};
 $numBins = $width / 2;
 $data = $accumulate->GetInput;
 $data->Update;
 #return unless(defined($data->GetPointData->GetScalars)); # don't do anything if the input data hasn't been defined yet
 @inputRange = $data->GetPointData->GetScalars->GetRange;
 $origin = $inputRange[0];
 $spacing = 1.0 * ($inputRange[1] - $origin) / $numBins;
 $accumulate->SetComponentExtent(0,$numBins - 1,0,0,0,0);
 $accumulate->SetComponentOrigin($origin,0.0,0.0);
 $accumulate->SetComponentSpacing($spacing,1.0,1.0);

 # initialize the canvas
 $canvas = $widget->{'Canvas'};
 $canvas->SetExtent(0,$width,0,$height,0,0);
 $canvas->SetDrawColor(255);
 $canvas->FillBox(0,$width,0,$height);
 $canvas->SetDrawColor(0);

 # get the histogram data
 $data = $accumulate->GetOutput;
 $data->Update;

 # scale the histogram max to fit the window
 @histRange = $data->GetPointData->GetScalars->GetRange;
 $scale = 0.9 * $height / $histRange[1];

 for ($idx = 0; $idx < $numBins; $idx += 1)
  {
   $y = $data->GetScalarComponentAsFloat($idx,0,0,0);
   $y1 = $y * $scale;
   $y2 = int($y1);
   $x = $idx * 2;
   $canvas->DrawSegment($x,0,$x,$y2);
  }

 $widget->Render;
}


#
sub SetExtent
{
 my $widget = shift;
 my $x1 = shift;
 my $x2 = shift;
 my $y1 = shift;
 my $y2 = shift;
 my $z1 = shift;
 my $z2 = shift;
 my $clip;
 $clip = $widget->{'Clip'};
 $clip->SetOutputWholeExtent($x1,$x2,$y1,$y2,$z1,$z2);
}


# ---- Bindings and interaction procedures ----

#
sub ClassInit
{
 my ($class,$widget) = @_;
 $widget->bind($class,'<Expose>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->HistogramWidgetRender;
   }
 );

 # probe value
 $widget->bind($class,'<ButtonPress-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->StartInteraction($Ev->x,$Ev->y); ##Stopped Here
   }
 );
 $widget->bind($class,'<B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->UpdateInteraction($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class,'<ButtonRelease-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->EndInteraction;
   }
 );
}


#
sub StartInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $actor1;
 my $actor2;
 my $height;
 # make the text visible
 $actor1 = $widget->{'Actor1'};
 $actor2 = $widget->{'Actor2'};
 $actor1->SetVisibility(1);
 $actor2->SetVisibility(1);

 # in case the window has been resized, place at the top of the window.
 $height = $widget->cget('-height');
 $actor1->GetPositionCoordinate->SetValue(4,$height - 22);
 $actor2->GetPositionCoordinate->SetValue(4,$height - 40);

 $widget->UpdateInteraction($x,$y);
}

#
sub EndInteraction
{
 my $widget = shift;
 my $actor;
 $actor = $widget->{'Actor1'};
 $actor->SetVisibility(0);
 $actor = $widget->{'Actor2'};
 $actor->SetVisibility(0);
 $widget->Render;
}

#
sub UpdateInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $accumulate;
 my $binMax;
 my $binMin;
 my $data;
 my $mapper;
 my $max;
 my $origin;
 my $return;
 my $spacing;
 my $str1;
 my $str2;
 # compute the bin selected by the mouse
 $x = $x / 2;
 $accumulate = $widget->{'Accumulate'};
 $origin = ($accumulate->GetComponentOrigin)[0];
 $spacing = ($accumulate->GetComponentSpacing)[0];
 $binMin = $origin + $spacing * $x;
 $binMax = $binMin + $spacing;
 # now get the height of the histogram
 $data = $accumulate->GetOutput;
 $data->Update;
 # make sure value is in extent
 $max = ($data->GetExtent)[1];
 return if ($x < 0 || $x > $max);
 $y = $data->GetScalarComponentAsFloat($x,0,0,0);
 # format the string to display
 $str1 = sprintf("Bin: \[%.1f, %.1f)",$binMin,$binMax);
 $str2 = sprintf("Count: %d",$y);
 # display the value
 $mapper = $widget->{'Mapper1'};
 $mapper->SetInput($str1);
 $mapper = $widget->{'Mapper2'};
 $mapper->SetInput($str2);
 $widget->Render;
}
