#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrate the use and manipulation of fields and use of 
# vtkProgrammableDataObjectSource. This creates fields the hard way 
# (as compared to reading a vtk field file), but shows you how to
# interfaceto your own raw data.
# The image should be the same as financialField.tcl
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$xAxis = 'INTEREST_RATE';
$yAxis = 'MONTHLY_PAYMENT';
$zAxis = 'MONTHLY_INCOME';
$scalar = 'TIME_LATE';
# Parse an ascii file and manually create a field. Then construct a 
# dataset from the field.
$dos = Graphics::VTK::ProgrammableDataObjectSource->new;
$dos->SetExecuteMethod(
 sub
  {
   parseFile();
  }
);
#
sub parseFile
{
 my $fieldData;
 my $file;
 my $gets;
 my $i;
 my $interestRate;
 my $j;
 my $line;
 my $m;
 my $monthlyIncome;
 my $monthlyPayment;
 my $timeLate;
 # Global Variables Declared for this function: VTK_DATA
 open( FILE, $ENV{VTK_DATA}."/financial.txt") or die("Can't open file '".$ENV{VTK_DATA}."/financial.txt'\n");
 $line = <FILE>;
 $line =~ /NUMBER_POINTS\s(\d+)/;
 my $numPoints = $1;
  # Get the data object's field data and allocate
 # room for 4 fields
 $fieldData = $dos->GetOutput->GetFieldData;
 $fieldData->AllocateArrays(4);
  # read TIME_LATE - dependent variable
 $timeLate = Graphics::VTK::FloatArray->new;
 $timeLate->SetName('TIME_LATE');

 # Read the entire string:
 undef $/;
 my $string = <FILE>; 
 my @components = split ('\n\n', $string);
 
 my $temp = $components[0];
 my @points = split( /\s+/s, $temp);

 shift @points; shift @points; # get rid of first two element to get just the points
 
 foreach (@points){ $timeLate->InsertNextValue($_)};
 
 # Add the array
 $fieldData->AddArray($timeLate); 

 # MONTHLY_PAYMENT - independent variable
 $monthlyPayment = Graphics::VTK::FloatArray->new;
 $monthlyPayment->SetName('MONTHLY_PAYMENT');
 $temp = $components[1];
 @points = split( /\s+/s, $temp);

 shift @points; # get rid of first two element to get just the points
 
 foreach (@points){ $monthlyPayment->InsertNextValue($_)};
 
 $fieldData->AddArray($monthlyPayment);
 # UNPAID_PRINCIPLE - skip

 # LOAN_AMOUNT - skip

 # INTEREST_RATE - independnet variable
 $interestRate = Graphics::VTK::FloatArray->new;
 $interestRate->SetName('INTEREST_RATE');
 $temp = $components[4];
 @points = split( /\s+/s, $temp);

 shift @points; # get rid of first two element to get just the points
 
 foreach (@points){ $interestRate->InsertNextValue($_)};
 $fieldData->AddArray($interestRate);

 # MONTHLY_INCOME - independent variable
 $monthlyIncome = Graphics::VTK::IntArray->new;
 $monthlyIncome->SetName('MONTHLY_INCOME');
 $temp = $components[5];
 @points = split( /\s+/s, $temp);

 shift @points; # get rid of first two element to get just the points
 
 foreach (@points){ $monthlyIncome->InsertNextValue($_)};

 $fieldData->AddArray($monthlyIncome);
}


# Create the dataset
$do2ds = Graphics::VTK::DataObjectToDataSetFilter->new;
$do2ds->SetInput($dos->GetOutput);
$do2ds->SetDataSetTypeToPolyData;
#format: component#, arrayname, arraycomp, minArrayId, maxArrayId, normalize
$do2ds->DefaultNormalizeOn;
$do2ds->SetPointComponent(0,$xAxis,0);
$do2ds->SetPointComponent(1,$yAxis,0);
$do2ds->SetPointComponent(2,$zAxis,0);

# RearrangeFields is used to move fields between DataObject's
# FieldData, PointData and CellData.
$rf = Graphics::VTK::RearrangeFields->new;
$rf->SetInput($do2ds->GetOutput);
# Add an operation to "move TIME_LATE from DataObject's FieldData to
# PointData"
$rf->AddOperation('MOVE',$scalar,'DATA_OBJECT','POINT_DATA');
# Force the filter to execute. This is need to force the pipeline
# to execute so that we can find the range of the array TIME_LATE
$rf->Update;

# Set max to the second (GetRange return [min,max]) of the "range of the 
# array called $scalar in the PointData of the output of rf"
$max = ($rf->GetOutput->GetPointData->GetArray($scalar)->GetRange(0))[1];
# Use an ArrayCalculator to normalize TIME_LATE
$calc = Graphics::VTK::ArrayCalculator->new;
$calc->SetInput($rf->GetOutput);
# Working on point data
$calc->SetAttributeModeToUsePointData;
# Map $scalar to s. When setting function, we can use s to
# represent the array $scalar (TIME_LATE) 
$calc->AddScalarVariable('s',$scalar,0);
# Divide $scalar by $max (applies division to all components of the array)
$calc->SetFunction("s / $max");
# The output array will be called resArray
$calc->SetResultArrayName('resArray');
# Use AssignAttribute to make resArray the active scalar field
$aa = Graphics::VTK::AssignAttribute->new;
$aa->SetInput($calc->GetOutput);
$aa->Assign('resArray','SCALARS','POINT_DATA');
$aa->Update;



$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($aa->GetOutput);
$fd2ad->SetInputFieldToDataObjectField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->DefaultNormalizeOn;
$fd2ad->SetScalarComponent(0,$scalar,0);
# construct pipeline for original population
$popSplatter = Graphics::VTK::GaussianSplatter->new;
$popSplatter->SetInput($aa->GetOutput);
$popSplatter->SetSampleDimensions(50,50,50);
$popSplatter->SetRadius(0.05);
$popSplatter->ScalarWarpingOff;
$popSurface = Graphics::VTK::ContourFilter->new;
$popSurface->SetInput($popSplatter->GetOutput);
$popSurface->SetValue(0,0.01);
$popMapper = Graphics::VTK::PolyDataMapper->new;
$popMapper->SetInput($popSurface->GetOutput);
$popMapper->ScalarVisibilityOff;
$popActor = Graphics::VTK::Actor->new;
$popActor->SetMapper($popMapper);
$popActor->GetProperty->SetOpacity(0.3);
$popActor->GetProperty->SetColor('.9','.9','.9');
# construct pipeline for delinquent population
$lateSplatter = Graphics::VTK::GaussianSplatter->new;
$lateSplatter->SetInput($aa->GetOutput);
$lateSplatter->SetSampleDimensions(50,50,50);
$lateSplatter->SetRadius(0.05);
$lateSplatter->SetScaleFactor(0.05);
$lateSurface = Graphics::VTK::ContourFilter->new;
$lateSurface->SetInput($lateSplatter->GetOutput);
$lateSurface->SetValue(0,0.01);
$lateMapper = Graphics::VTK::PolyDataMapper->new;
$lateMapper->SetInput($lateSurface->GetOutput);
$lateMapper->ScalarVisibilityOff;
$lateActor = Graphics::VTK::Actor->new;
$lateActor->SetMapper($lateMapper);
$lateActor->GetProperty->SetColor(1.0,0.0,0.0);
# create axes
$popSplatter->Update;
@bounds = $popSplatter->GetOutput->GetBounds;
$axes = Graphics::VTK::Axes->new;
$axes->SetOrigin($bounds[0],$bounds[2],$bounds[4]);
$axes->SetScaleFactor($popSplatter->GetOutput->GetLength / 5.0);
$axesTubes = Graphics::VTK::TubeFilter->new;
$axesTubes->SetInput($axes->GetOutput);
$axesTubes->SetRadius($axes->GetScaleFactor / 25.0);
$axesTubes->SetNumberOfSides(6);
$axesMapper = Graphics::VTK::PolyDataMapper->new;
$axesMapper->SetInput($axesTubes->GetOutput);
$axesActor = Graphics::VTK::Actor->new;
$axesActor->SetMapper($axesMapper);
# label the axes
$XText = Graphics::VTK::VectorText->new;
$XText->SetText($xAxis);
$XTextMapper = Graphics::VTK::PolyDataMapper->new;
$XTextMapper->SetInput($XText->GetOutput);
$XActor = Graphics::VTK::Follower->new;
$XActor->SetMapper($XTextMapper);
$XActor->SetScale(0.02,'.02','.02');
$XActor->SetPosition(0.35,-0.05,-0.05);
$XActor->GetProperty->SetColor(0,0,0);
$YText = Graphics::VTK::VectorText->new;
$YText->SetText($yAxis);
$YTextMapper = Graphics::VTK::PolyDataMapper->new;
$YTextMapper->SetInput($YText->GetOutput);
$YActor = Graphics::VTK::Follower->new;
$YActor->SetMapper($YTextMapper);
$YActor->SetScale(0.02,'.02','.02');
$YActor->SetPosition(-0.05,0.35,-0.05);
$YActor->GetProperty->SetColor(0,0,0);
$ZText = Graphics::VTK::VectorText->new;
$ZText->SetText($zAxis);
$ZTextMapper = Graphics::VTK::PolyDataMapper->new;
$ZTextMapper->SetInput($ZText->GetOutput);
$ZActor = Graphics::VTK::Follower->new;
$ZActor->SetMapper($ZTextMapper);
$ZActor->SetScale(0.02,'.02','.02');
$ZActor->SetPosition(-0.05,-0.05,0.35);
$ZActor->GetProperty->SetColor(0,0,0);
# Graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetWindowName("vtk - Field Data");
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($axesActor);
$ren1->AddActor($lateActor);
$ren1->AddActor($XActor);
$ren1->AddActor($YActor);
$ren1->AddActor($ZActor);
$ren1->AddActor($popActor);
#it's last because its translucent
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange('.274',13.72);
$camera->SetFocalPoint(0.433816,0.333131,0.449);
$camera->SetPosition(-1.96987,1.15145,1.49053);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0.378927,0.911821,0.158107);
$ren1->SetActiveCamera($camera);
$XActor->SetCamera($camera);
$YActor->SetCamera($camera);
$ZActor->SetCamera($camera);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
