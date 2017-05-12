#!/usr/local/bin/perl -w
#
use Graphics::VTK;
use Tk;
use Graphics::VTK::Tk;
use Graphics::VTK::Tk::vtkInteractor;

$MW = Tk::MainWindow->new;

# Decimate.tcl - a little application to decimate files
# 	Written by Will
#
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#
# Source external files
#source TkInteractor.tcl
use Graphics::VTK::Tk::vtkInt;
#
# Define global variables
$deciReduction = 0.0;
$deciPreserve = 1;
$view = 'Left';
$Surface = 1;
$FEdges = 0;
$BEdges = 0;
$NMEdges = 0;
$Compare = 0;
$edgeSplitting = 1;
$flipNormals = 0;
$CurrentFilter = undef;
#
# Instances of vtk objects
$PolyData = Graphics::VTK::PolyData->new;
#    PolyData GlobalWarningDisplayOff
$PreviousPolyData = Graphics::VTK::PolyData->new;
$TempPolyData = Graphics::VTK::PolyData->new;
$CellTypes = Graphics::VTK::CellTypes->new;
#
$deci = Graphics::VTK::DecimatePro->new;
$deci->SetStartMethod(
 sub
  {
   StartProgress($deci,"Decimating...");
  }
);
$deci->SetProgressMethod(
 sub
  {
   ShowProgress($deci,"Decimating...");
  }
);
$deci->SetEndMethod(
 sub
  {
   EndProgress();
  }
);
$smooth = Graphics::VTK::SmoothPolyDataFilter->new;
$smooth->SetStartMethod(
 sub
  {
   StartProgress($smooth,"Smoothing...");
  }
);
$smooth->SetProgressMethod(
 sub
  {
   ShowProgress($smooth,"Smoothing...");
  }
);
$smooth->SetEndMethod(
 sub
  {
   EndProgress();
  }
);
$cleaner = Graphics::VTK::CleanPolyData->new;
$cleaner->SetStartMethod(
 sub
  {
   StartProgress($cleaner,"Cleaning...");
  }
);
$cleaner->SetProgressMethod(
 sub
  {
   ShowProgress($cleaner,"Cleaning...");
  }
);
$cleaner->SetEndMethod(
 sub
  {
   EndProgress();
  }
);
$connect = Graphics::VTK::PolyDataConnectivityFilter->new;
$connect->SetStartMethod(
 sub
  {
   StartProgress($connect,"Connectivity...");
  }
);
$connect->SetProgressMethod(
 sub
  {
   ShowProgress($connect,"Connectivity...");
  }
);
$connect->SetEndMethod(
 sub
  {
   EndProgress();
  }
);
$tri = Graphics::VTK::TriangleFilter->new;
$tri->SetStartMethod(
 sub
  {
   StartProgress($tri,"Triangulating...");
  }
);
$tri->SetProgressMethod(
 sub
  {
   ShowProgress($tri,"Triangulating...");
  }
);
$tri->SetEndMethod(
 sub
  {
   EndProgress();
  }
);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetStartMethod(
 sub
  {
   StartProgress($normals,"Generating Normals...");
  }
);
$normals->SetProgressMethod(
 sub
  {
   ShowProgress($normals,"Generating Normals...");
  }
);
$normals->SetEndMethod(
 sub
  {
   EndProgress();
  }
);
#
######################################## Create top-level GUI
#
$MW->title("vtk Decimator v1.0");
$MW->{'.mbar'} = $MW->Frame('-relief','raised','-bd',2);
$MW->{'.mbar'}->pack('-side','top','-fill','x');
#
$MW->{'.mbar.file'} = $MW->{'.mbar'}->Menubutton('-text','File');
$MW->{'.mbar.edit'} = $MW->{'.mbar'}->Menubutton('-text','Edit');
$MW->{'.mbar.view'} = $MW->{'.mbar'}->Menubutton('-text','View');
$MW->{'.mbar.options'} = $MW->{'.mbar'}->Menubutton('-text','Options');
$MW->{'.mbar.help'} = $MW->{'.mbar'}->Menubutton('-text','Help');
foreach $_ (($MW->{'.mbar.file'},$MW->{'.mbar.edit'},$MW->{'.mbar.view'},$MW->{'.mbar.options'}))
 {
  $_->pack('-side','left');
 }
$MW->{'.mbar.help'}->pack('-side','right');
#
# menu .mbar.file.menu
$MW->{'.mbar.file'}->command('-label','Open','-command',
 sub
  {
   OpenFile();
  }
);
$MW->{'.mbar.file'}->command('-label','Save','-state','disabled','-command',
 sub
  {
   SaveFile();
  }
);
$MW->{'.mbar.file'}->command('-label','Exit','-command',
 sub
  {
   exit();
  }
);
#
# menu .mbar.edit.menu
$MW->{'.mbar.edit'}->command('-label','Clean','-state','disabled','-command',
 sub
  {
   Clean();
  }
);
$MW->{'.mbar.edit'}->command('-label','Connectivity','-state','disabled','-command',
 sub
  {
   Connect();
  }
);
$MW->{'.mbar.edit'}->command('-label','Decimate','-state','disabled','-command',
 sub
  {
   Decimate();
  }
);
$MW->{'.mbar.edit'}->command('-label','Normals','-state','disabled','-command',
 sub
  {
   Normals();
  }
);
$MW->{'.mbar.edit'}->command('-label','Smooth','-state','disabled','-command',
 sub
  {
   Smooth();
  }
);
$MW->{'.mbar.edit'}->command('-label','Triangulate','-state','disabled','-command',
 sub
  {
   Triangulate();
  }
);
$MW->{'.mbar.edit'}->command('-label',"Undo/Redo",'-command',
 sub
  {
   Undo();
  }
);
#
# menu .mbar.view.menu
$MW->{'.mbar.view'}->checkbutton('-label',"Object Surface",'-command',
 sub
  {
   UpdateGUI();
   $RenWin->Render;
  }
,'-variable',\$Surface);
$MW->{'.mbar.view'}->checkbutton('-label',"Feature Edges",'-command',
 sub
  {
   UpdateGUI();
   $RenWin->Render;
  }
,'-variable',\$FEdges);
$MW->{'.mbar.view'}->checkbutton('-label',"Boundary Edges",'-command',
 sub
  {
   UpdateGUI();
   $RenWin->Render;
  }
,'-variable',\$BEdges);
$MW->{'.mbar.view'}->checkbutton('-label',"Non-manifold Edges",'-command',
 sub
  {
   UpdateGUI();
   $RenWin->Render;
  }
,'-variable',\$NMEdges);
$MW->{'.mbar.view'}->separator;
$MW->{'.mbar.view'}->radiobutton('-label','Front','-value','Front','-command',
 sub
  {
   UpdateView(1,0,0,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Back','-value','Back','-command',
 sub
  {
   UpdateView(-1,0,0,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Left','-value','Left','-command',
 sub
  {
   UpdateView(0,0,1,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Right','-value','Right','-command',
 sub
  {
   UpdateView(0,0,-1,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Top','-value','Top','-command',
 sub
  {
   UpdateView(0,1,0,0,0,1);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Bottom','-value','Bottom','-command',
 sub
  {
   UpdateView(0,-1,0,0,0,1);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Isometric','-value','Isometric','-command',
 sub
  {
   UpdateView(1,1,1,0,1,0);
  }
,'-variable',\$view);
#
# menu .mbar.options.menu
$MW->{'.mbar.options'}->command('-label',"Compare Results",'-state','disabled','-command',
 sub
  {
   Compare();
  }
);
$MW->{'.mbar.options'}->command('-label',"Background Color...",'-command',
 sub
  {
   BackgroundColor();
  }
);
$MW->{'.mbar.options'}->command('-label',"Surface Properties...",'-command',
 sub
  {
   Properties();
  }
);
#
# menu .mbar.help.menu
$MW->{'.mbar.help'}->command('-label','Buy a Kitware support contract');
#
# The rendering widget
$MW->{'.window'} = $MW->vtkInteractor('-width',300,'-height',300);
$MW->{'.window'}->pack('-side','top','-anchor','nw','-padx',3,'-pady',3,'-fill','both','-expand',1);
#
# Status bar
$MW->{'.bottomF'} = $MW->Frame('-relief','sunken','-borderwidth',3);
$MW->{'.bottomF.status'} = $MW->{'.bottomF'}->Label('-borderwidth',0,'-text',"(No data)");
$MW->{'.bottomF.status'}->pack('-side','top','-anchor','w','-expand',1,'-fill','x','-padx',0,'-pady',0);
$MW->{'.bottomF'}->pack('-side','top','-anchor','w','-expand',1,'-fill','x','-padx',0,'-pady',0);
#
# Graphics objects
$camera = Graphics::VTK::Camera->new;
$light = Graphics::VTK::Light->new;
$Renderer = Graphics::VTK::Renderer->new;
$Renderer->SetActiveCamera($camera);
$Renderer->AddLight($light);
$CompareRenderer = Graphics::VTK::Renderer->new;
$CompareRenderer->SetViewport(0.0,0.0,0.5,1.0);
$CompareRenderer->SetActiveCamera($camera);
$CompareRenderer->AddLight($light);
$RenWin = $MW->{'.window'}->GetRenderWindow;
$RenWin->AddRenderer($Renderer);
#
# Procedure to set particular views
#
sub UpdateView
{
 my $x = shift;
 my $y = shift;
 my $z = shift;
 my $vx = shift;
 my $vy = shift;
 my $vz = shift;
 my $Render;
 # Global Variables Declared for this function: RenWin
 #
 $camera = $Renderer->GetActiveCamera;
 $camera->SetViewPlaneNormal($x,$y,$z);
 $camera->SetViewUp($vx,$vy,$vz);
 $Renderer->ResetCamera;
 $RenWin->Render;
}
#
# Procedure opens file and resets view
#
sub OpenFile
{
 my $ShowProgress;
 my $StartProgress;
 my $filename;
 my $reader;
 my $types;
 # Global Variables Declared for this function: RenWin, CurrentFilter
 #
 $types = [['BYU','.g'],['Cyberware (Laser Scanner)','.cyb'],['Marching Cubes','.tri'],['Stereo-Lithography','.stl'],['Visualization Toolkit (polygonal)','.vtk'],['Wavefront','.obj'],['All Files ','*']];
 $filename = $MW->getOpenFile(-filetypes => $types);
 if ($filename ne "")
  {

   if ($filename =~ /.*?\.g/)
    {
     $reader = Graphics::VTK::BYUReader->new;
     $reader->SetGeometryFileName($filename);
    }
   elsif ($filename =~ /.*?\.stl/)
    {
     $reader = Graphics::VTK::STLReader->new;
     $reader->SetFileName($filename);
    }
   elsif ($filename =~ /.*?\.vtk/)
    {
     $reader = Graphics::VTK::PolyDataReader->new;
     $reader->SetFileName($filename);
    }
   elsif ($filename =~ /.*?\.cyb/)
    {
     $reader = Graphics::VTK::CyberReader->new;
     $reader->SetFileName($filename);
    }
   elsif ($filename =~ /.*?\.tri/)
    {
     $reader = Graphics::VTK::MCubesReader->new;
     $reader->SetFileName($filename);
    }
   elsif ($filename =~ /.*?\.obj/)
    {
     $reader = Graphics::VTK::OBJReader->new;
     $reader->SetFileName($filename);
    }
   else
    {
     print("Can't read this file");
     return;
    }
   #
   $reader->SetStartMethod(
    sub
     {
      StartProgress($reader,"Reading...");
     }
   );
   $reader->SetProgressMethod(
    sub
     {
      ShowProgress($reader,"Reading...");
     }
   );
   $reader->SetEndMethod(
    sub
     {
      EndProgress();
     }
   );
   #
   UpdateUndo($reader);
   UpdateGUI();
   #
   $filename = "vtk Decimator: [file tail $filename]";
   $MW->title($filename);
   #
   $Renderer->ResetCamera;
   $RenWin->Render;
  }
}
#
# Procedure saves data to file
#
sub SaveFile
{
 my $file;
 my $filename;
 my $return;
 my $tk_getSaveFile;
 my $types;
 my $writer;
 # Global Variables Declared for this function: PolyData, RenWin
 #
 $types = [['BYU','.g'],['Marching Cubes','.tri'],['RIB (Renderman)','.rib'],['Stereo-Lithography','.stl'],['Visualization Toolkit (polygonal)','.vtk'],['VRML','.wrl'],['Wavefront OBJ','.obj'],['All Files ','*']];
 $filename = $tk_getSaveFile->_filetypes($types);
 if ($filename ne "")
  {

   if ($filename =~ /.*?\.g/)
    {
     $writer = Graphics::VTK::BYUWriter->new;
     $writer->SetGeometryFileName($filename);
     $writer->SetInput($PolyData);
    }
   elsif ($filename =~ /.*?\.stl/)
    {
     $writer = Graphics::VTK::STLWriter->new;
     $writer->SetFileName($filename);
     $writer->SetInput($PolyData);
    }
   elsif ($filename =~ /.*?\.vtk/)
    {
     $writer = Graphics::VTK::PolyDataWriter->new;
     $writer->SetFileName($filename);
     $writer->SetInput($PolyData);
    }
   elsif ($filename =~ /.*?\.tri/)
    {
     $writer = Graphics::VTK::MCubesWriter->new;
     $writer->SetFileName($filename);
     $writer->SetInput($PolyData);
    }
   elsif ($filename =~ /.*?\.wrl/)
    {
     $writer = Graphics::VTK::VRMLExporter->new;
     $writer->SetRenderWindow($RenWin);
     $writer->SetFileName($filename);
    }
   elsif ($filename =~ /.*?\.obj/)
    {
     $writer = Graphics::VTK::OBJExporter->new;
     $writer->SetRenderWindow($RenWin);
     $writer->SetFilePrefix($file->rootname($filename));
    }
   elsif ($filename =~ /.*?\.rib/)
    {
     $writer = Graphics::VTK::RIBExporter->new;
     $writer->SetRenderWindow($RenWin);
     $writer->SetFilePrefix($file->rootname($filename));
    }
   else
    {
     print("Can't write this file");
     return;
    }
   #
   $writer->Write;
  }
}
#
# Enable the undo procedure after filter execution
#
sub UpdateUndo
{
 my $filter = shift;
 my $ReleaseData;
 # Global Variables Declared for this function: CurrentFilter
 #
 $CurrentFilter = $filter;
 $filter->Update;
 #
 $PreviousPolyData->CopyStructure($PolyData);
 $PreviousPolyData->GetPointData->PassData($PolyData->GetPointData);
 $PreviousPolyData->Modified;
 #
 $PolyData->CopyStructure($filter->GetOutput);
 $PolyData->GetPointData->PassData($filter->GetOutput->GetPointData);
 $PolyData->Modified;
 #
 ReleaseData();
}
#
# Undo last edit
#
sub Undo
{
 my $UpdateGUI;
 # Global Variables Declared for this function: RenWin
 #
 $TempPolyData->CopyStructure($PolyData);
 $TempPolyData->GetPointData->PassData($PolyData->GetPointData);
 #
 $PolyData->CopyStructure($PreviousPolyData);
 $PolyData->GetPointData->PassData($PreviousPolyData->GetPointData);
 $PolyData->Modified;
 #
 $PreviousPolyData->CopyStructure($TempPolyData);
 $PreviousPolyData->GetPointData->PassData($TempPolyData->GetPointData);
 $PreviousPolyData->Modified;
 #
 UpdateGUI();
 $RenWin->Render;
}
#
### Procedure initializes filters so that they release their memory
#
#
sub ReleaseData
{
 $deci->GetOutput->Initialize;
 $smooth->GetOutput->Initialize;
 $cleaner->GetOutput->Initialize;
 $connect->GetOutput->Initialize;
 $tri->GetOutput->Initialize;
 $smooth->GetOutput->Initialize;
}
#
#### Create pipeline
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($PolyData);
$property = Graphics::VTK::Property->new;
$property->SetColor(0.8900,0.8100,0.3400);
$property->SetSpecularColor(1,1,1);
$property->SetSpecular(0.3);
$property->SetSpecularPower(20);
$property->SetAmbient(0.2);
$property->SetDiffuse(0.8);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->SetProperty($property);
#
# Welcome banner
$banner = Graphics::VTK::TextMapper->new;
$banner->SetInput("vtk Decimator\nVersion 1.0");
$banner->SetFontFamilyToArial;
$banner->SetFontSize(18);
$banner->ItalicOn;
$banner->SetJustificationToCentered;
$bannerActor = Graphics::VTK::Actor2D->new;
$bannerActor->SetMapper($banner);
$bannerActor->GetProperty->SetColor(0,1,0);
$bannerActor->GetPositionCoordinate->SetCoordinateSystemToNormalizedDisplay;
$bannerActor->GetPositionCoordinate->SetValue(0.5,0.5);
$Renderer->AddProp($bannerActor);
#
# Actor used for side-by-side data comparison
$CompareMapper = Graphics::VTK::PolyDataMapper->new;
$CompareMapper->SetInput($PreviousPolyData);
$CompareActor = Graphics::VTK::Actor->new;
$CompareActor->SetMapper($CompareMapper);
$CompareActor->SetProperty($property);
$CompareRenderer->AddActor($CompareActor);
#
# Edges
$FeatureEdges = Graphics::VTK::FeatureEdges->new;
$FeatureEdges->SetInput($PolyData);
$FeatureEdges->BoundaryEdgesOff;
$FeatureEdges->NonManifoldEdgesOff;
$FeatureEdges->ManifoldEdgesOff;
$FeatureEdges->FeatureEdgesOff;
$FEdgesMapper = Graphics::VTK::PolyDataMapper->new;
$FEdgesMapper->SetInput($FeatureEdges->GetOutput);
$FEdgesMapper->SetScalarModeToUseCellData;
$FEdgesActor = Graphics::VTK::Actor->new;
$FEdgesActor->SetMapper($FEdgesMapper);
#
$Renderer->ResetCamera;
$Renderer->GetActiveCamera->Zoom(1.25);
#
#
# Procedure updates data statistics and GUI menus
#
#
sub UpdateGUI
{
 my $NumberOfElements;
 my $NumberOfNodes;
 my $s;
 # Global Variables Declared for this function: Surface, RenWin
 # Global Variables Declared for this function: FEdges, BEdges, NMEdges, RenWin
 #
 $NumberOfNodes = $PolyData->GetNumberOfPoints;
 $NumberOfElements = $PolyData->GetNumberOfCells;
 $PolyData->GetCellTypes($CellTypes);
 #
 $Renderer->RemoveActor($bannerActor);
 $Renderer->RemoveActor($actor);
 $Renderer->RemoveActor($FEdgesActor);
 #
 # Check to see whether to add surface model
 if ($PolyData->GetNumberOfCells <= 0)
  {
   $Renderer->AddActor($bannerActor);
   $MW->{'.mbar.edit'}->entryconfigure(1,'-state','disabled');
   $MW->{'.mbar.edit'}->entryconfigure(2,'-state','disabled');
   $MW->{'.mbar.edit'}->entryconfigure(3,'-state','disabled');
   $MW->{'.mbar.edit'}->entryconfigure(4,'-state','disabled');
   $MW->{'.mbar.edit'}->entryconfigure(5,'-state','disabled');
   $MW->{'.mbar.file'}->entryconfigure(1,'-state','disabled');
   $MW->{'.mbar.options'}->entryconfigure(1,'-state','disabled');
   $s = "(None)";
   #
  }
 else
  {
   $Renderer->AddActor($actor) if ($Surface);
   #
   if ($FEdges || $BEdges || $NMEdges)
    {
     $Renderer->AddActor($FEdgesActor);
     $FeatureEdges->SetBoundaryEdges($BEdges);
     $FeatureEdges->SetFeatureEdges($FEdges);
     $FeatureEdges->SetNonManifoldEdges($NMEdges);
    }
   #
   $MW->{'.mbar.edit'}->entryconfigure(1,'-state','normal');
   if ($CellTypes->GetNumberOfTypes != 1 || $CellTypes->GetCellType(0) != 5)
    {
     $MW->{'.mbar.edit'}->entryconfigure(2,'-state','disabled');
     $MW->{'.mbar.edit'}->entryconfigure(6,'-state','normal');
     $s = sprintf("Vertices:%d    Cells:%d",$NumberOfNodes,$NumberOfElements);
    }
   else
    {
     $MW->{'.mbar.edit'}->entryconfigure(2,'-state','normal');
     $MW->{'.mbar.edit'}->entryconfigure(6,'-state','disabled');
     $s = sprintf("Vertices:%d    Triangles:%d",$NumberOfNodes,$NumberOfElements);
    }
   $MW->{'.mbar.edit'}->entryconfigure(3,'-state','normal');
   $MW->{'.mbar.edit'}->entryconfigure(4,'-state','normal');
   $MW->{'.mbar.edit'}->entryconfigure(5,'-state','normal');
   $MW->{'.mbar.file'}->entryconfigure(2,'-state','normal');
   $MW->{'.mbar.options'}->entryconfigure(1,'-state','normal');
  }
 #
 $MW->{'.bottomF.status'}->configure('-text',$s);
}
#
### Procedure manages splitting screen and comparing data
#
#
sub Compare
{
 # Global Variables Declared for this function: Compare, RenWin
 #
 if ($Compare == 0)
  {
   $RenWin->AddRenderer($CompareRenderer);
   $Renderer->SetViewport(0.5,0.0,1.0,1.0);
   $MW->{'.mbar.options'}->entryconfigure(1,'-label',"Uncompare Results");
   $Compare = 1;
   #
  }
 else
  {
   $RenWin->RemoveRenderer($CompareRenderer);
   $Renderer->SetViewport(0.0,0.0,1.0,1.0);
   $MW->{'.mbar.options'}->entryconfigure(1,'-label',"Compare Results");
   $Compare = 0;
  }
 #
 $RenWin->Render;
}
#
########################## The decimation GUI
#
# Procedure defines GUI and behavior for decimating data
#
#
sub Decimate
{
 my $UpdateDecimationGUI;
 UpdateDecimationGUI();
 $MW->{'.decimate'}->deiconify;
}
#
#
sub CloseDecimate
{
 $MW->{'.decimate'}->withdraw;
}
#
$MW->{'.decimate'} = $MW->Toplevel;
$MW->{'.decimate'}->withdraw;
$MW->{'.decimate'}->title("Decimate");
$MW->{'.decimate'}->protocol('WM_DELETE_WINDOW','wm withdraw .decimate');
#
$MW->{'.decimate.f1'} = $MW->{'.decimate'}->Frame;
$MW->{'.decimate.f1.preserve'} = $MW->{'.decimate.f1'}->Checkbutton('-text',"Preserve Topology",'-variable',\$deciPreserve);
$MW->{'.decimate.f1.red'} = $MW->{'.decimate.f1'}->Scale('-from',0,'-label',"Requested Number Of Polygons",'-resolution',1,'-length','3.0i','-to',100000,'-command',
 sub
  {
   SetDeciPolygons();
  }
,'-orient','horizontal');
$MW->{'.decimate.f1.red'}->set(4000);
foreach $_ (($MW->{'.decimate.f1.preserve'},$MW->{'.decimate.f1.red'}))
 {
  $_->pack('-pady','0.1i','-side','top','-anchor','w');
 }
#
$MW->{'.decimate.fb'} = $MW->{'.decimate'}->Frame;
$MW->{'.decimate.fb.apply'} = $MW->{'.decimate.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyDecimation();
  }
);
$MW->{'.decimate.fb.cancel'} = $MW->{'.decimate.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseDecimate();
  }
);
foreach $_ (($MW->{'.decimate.fb.apply'},$MW->{'.decimate.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
foreach $_ (($MW->{'.decimate.f1'},$MW->{'.decimate.fb'}))
 {
  $_->pack('-side','top','-fill','both','-expand',1);
 }
#
#
sub UpdateDecimationGUI
{
 my $SetDeciPolygons;
 my $numPolys;
 #
 $numPolys = $PolyData->GetNumberOfCells;
 $MW->{'.decimate.f1.red'}->configure('-to',$numPolys);
 #
 SetDeciPolygons($MW->{'.decimate.f1.red'}->get);
}
#
#
sub ApplyDecimation
{
 my $CloseDecimate;
 my $UpdateGUI;
 # Global Variables Declared for this function: deciReduction, deciPreserve, RenWin
 #
 $deci->SetInput($PolyData);
 #
 $deci->SetTargetReduction($deciReduction);
 $deci->SetPreserveTopology($deciPreserve);
 #
 UpdateUndo($deci);
 UpdateGUI();
 #
 $RenWin->Render;
 CloseDecimate();
}
#
#
sub SetDeciPolygons
{
 my $value = shift || 0;;
 my $numInPolys;
 my $return;
 # Global Variables Declared for this function: deciReduction
 #
 $numInPolys = $PolyData->GetNumberOfCells;
 return if ($numInPolys <= 0);
 $deciReduction = (($numInPolys) - $value) / $numInPolys;
}
#
########################## The smooth poly data GUI
#
# Procedure defines GUI and behavior for decimating data
#
#
sub Smooth
{
 my $UpdateSmoothGUI;
 UpdateSmoothGUI();
 $MW->{'.smooth'}->deiconify;
}
#
#
sub CloseSmooth
{
 $MW->{'.smooth'}->withdraw;
}
#
$MW->{'.smooth'} = $MW->Toplevel;
$MW->{'.smooth'}->withdraw;
$MW->{'.smooth'}->title("Smooth");
$MW->{'.smooth'}->protocol('WM_DELETE_WINDOW','wm withdraw .smooth');
#
$MW->{'.smooth.f1'} = $MW->{'.smooth'}->Frame;
$MW->{'.smooth.f1.num'} = $MW->{'.smooth.f1'}->Scale('-from',1,'-label',"Number Of Iterations",'-resolution',1,'-length','3.0i','-to',1000,'-orient','horizontal');
$MW->{'.smooth.f1.num'}->set(100);
$MW->{'.smooth.f1.fact'} = $MW->{'.smooth.f1'}->Scale('-from',0.00,'-label',"RelaxationFactor",'-resolution',0.01,'-length','3.0i','-to',1.00,'-orient','horizontal');
$MW->{'.smooth.f1.fact'}->set(0.01);
foreach $_ (($MW->{'.smooth.f1.num'},$MW->{'.smooth.f1.fact'}))
 {
  $_->pack('-pady','0.1i','-side','top','-anchor','w');
 }
#
$MW->{'.smooth.fb'} = $MW->{'.smooth'}->Frame;
$MW->{'.smooth.fb.apply'} = $MW->{'.smooth.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplySmooth();
  }
);
$MW->{'.smooth.fb.cancel'} = $MW->{'.smooth.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseSmooth();
  }
);
foreach $_ (($MW->{'.smooth.fb.apply'},$MW->{'.smooth.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
foreach $_ (($MW->{'.smooth.f1'},$MW->{'.smooth.fb'}))
 {
  $_->pack('-side','top','-fill','both','-expand',1);
 }
#
#
sub UpdateSmoothGUI
{
 #
 $MW->{'.smooth.f1.num'}->set($smooth->GetNumberOfIterations);
 $MW->{'.smooth.f1.fact'}->set($smooth->GetRelaxationFactor);
}
#
#
sub ApplySmooth
{
 my $CloseSmooth;
 # Global Variables Declared for this function: RenWin
 #
 $smooth->SetInput($PolyData);
 #
 $smooth->SetNumberOfIterations($MW->{'.smooth.f1.num'}->get);
 $smooth->SetRelaxationFactor($MW->{'.smooth.f1.fact'}->get);
 #
 UpdateUndo($smooth);
 UpdateGUI();
 #
 $RenWin->Render;
 CloseSmooth();
}
#
#
#
########################## The clean GUI
#
# Procedure defines GUI and behavior for cleaning data. Cleaning means
# removing degenerate polygons and eliminating coincident or unused points.
#
#
sub Clean
{
 my $UpdateCleanGUI;
 UpdateCleanGUI();
 $MW->{'.clean'}->deiconify;
}
#
sub CloseClean
{
 $MW->{'.clean'}->withdraw;
}
#
$MW->{'.clean'} = $MW->Toplevel;
$MW->{'.clean'}->withdraw;
$MW->{'.clean'}->title("Clean Data");
$MW->{'.clean'}->protocol('WM_DELETE_WINDOW','wm withdraw .clean');
#
$MW->{'.clean.f1'} = $MW->{'.clean'}->Frame;
$MW->{'.clean.f1.s'} = $MW->{'.clean.f1'}->Scale('-from',0.000,'-label',"Tolerance",'-resolution',0.001,'-length','3.0i','-to',1.000,'-digits',3,'-orient','horizontal');
$MW->{'.clean.f1.s'}->set(0.000);
$MW->{'.clean.f1.s'}->pack('-side','top','-anchor','w');
#
$MW->{'.clean.fb'} = $MW->{'.clean'}->Frame;
$MW->{'.clean.fb.apply'} = $MW->{'.clean.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyClean();
  }
);
$MW->{'.clean.fb.cancel'} = $MW->{'.clean.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseClean();
  }
);
foreach $_ (($MW->{'.clean.fb.apply'},$MW->{'.clean.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
foreach $_ (($MW->{'.clean.f1'},$MW->{'.clean.fb'}))
 {
  $_->pack('-side','top','-fill','both','-expand',1);
 }
#
#
sub UpdateCleanGUI
{
 $MW->{'.clean.f1.s'}->set($cleaner->GetTolerance);
}
#
#
sub ApplyClean
{
 # Global Variables Declared for this function: RenWin
 #
 $cleaner->SetInput($PolyData);
 $cleaner->SetTolerance($MW->{'.clean.f1.s'}->get);
 #
 UpdateUndo($cleaner);
 UpdateGUI();
 #
 $RenWin->Render;
 CloseClean();
}
########################## The connectivity GUI
#
# Procedure defines GUI and behavior for extracting connected data. Connecting
# means extracting all cells joined at a vertex.
#
#
sub Connect
{
 my $UpdateConnectGUI;
 UpdateConnectGUI();
 $MW->{'.connect'}->deiconify;
}
#
sub CloseConnect
{
 $MW->{'.connect'}->withdraw;
}
#
$MW->{'.connect'} = $MW->Toplevel;
$MW->{'.connect'}->withdraw;
$MW->{'.connect'}->title("Extract Connected Data");
$MW->{'.connect'}->protocol('WM_DELETE_WINDOW','wm withdraw .connect');
#
$MW->{'.connect.fb'} = $MW->{'.connect'}->Frame;
$MW->{'.connect.fb.apply'} = $MW->{'.connect.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyConnect();
  }
);
$MW->{'.connect.fb.cancel'} = $MW->{'.connect.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseConnect();
  }
);
foreach $_ (($MW->{'.connect.fb.apply'},$MW->{'.connect.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
$MW->{'.connect.fb'}->pack('-side','top','-fill','both','-expand',1);
#
#
sub UpdateConnectGUI
{
 ();
}
#
#
sub ApplyConnect
{
 # Global Variables Declared for this function: RenWin
 #
 $connect->SetInput($PolyData);
 #
 UpdateUndo($connect);
 UpdateGUI();
 #
 $RenWin->Render;
 CloseConnect();
}
########################## The triangulate GUI
#
# Procedure defines GUI and behavior for triangulating data. This will
# convert all polygons into triangles
#
sub Triangulate
{
 my $UpdateTriGUI;
 UpdateTriGUI();
 $MW->{'.tri'}->deiconify;
}
#
sub CloseTri
{
 $MW->{'.tri'}->withdraw;
}
#
$MW->{'.tri'} = $MW->Toplevel;
$MW->{'.tri'}->withdraw;
$MW->{'.tri'}->title("Triangulate Data");
$MW->{'.tri'}->protocol('WM_DELETE_WINDOW','wm withdraw .tri');
#
$MW->{'.tri.fb'} = $MW->{'.tri'}->Frame;
$MW->{'.tri.fb.apply'} = $MW->{'.tri.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyTri();
  }
);
$MW->{'.tri.fb.cancel'} = $MW->{'.tri.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseTri();
  }
);
foreach $_ (($MW->{'.tri.fb.apply'},$MW->{'.tri.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
$MW->{'.tri.fb'}->pack('-side','top','-fill','both','-expand',1);
#
#
sub UpdateTriGUI
{
 ();
}
#
#
sub ApplyTri
{
 # Global Variables Declared for this function: RenWin
 #
 $tri->SetInput($PolyData);
 #
 UpdateUndo($tri);
 UpdateGUI();
 #
 $RenWin->Render;
 CloseTri();
}
#
########################## The surface normals GUI
#
# Procedure defines GUI and behavior for generating surface normals. This will
# convert all polygons into triangles.
#
sub Normals
{
 my $UpdateNormalsGUI;
 UpdateNormalsGUI();
 $MW->{'.normals'}->deiconify;
}
#
sub CloseNormals
{
 $MW->{'.normals'}->withdraw;
}
#
$MW->{'.normals'} = $MW->Toplevel;
$MW->{'.normals'}->withdraw;
$MW->{'.normals'}->title("Generate Surface Normals");
$MW->{'.normals'}->protocol('WM_DELETE_WINDOW','wm withdraw .normals');
#
$MW->{'.normals.f1'} = $MW->{'.normals'}->Frame;
$MW->{'.normals.f1.fangle'} = $MW->{'.normals.f1'}->Scale('-from',0,'-label',"Feature Angle",'-resolution',1,'-length','3.0i','-to',180,'-orient','horizontal');
$MW->{'.normals.f1.split'} = $MW->{'.normals.f1'}->Checkbutton('-text',"Edge Splitting",'-variable',\$edgeSplitting);
$MW->{'.normals.f1.flip'} = $MW->{'.normals.f1'}->Checkbutton('-text',"Flip Normals",'-variable',\$flipNormals);
foreach $_ (($MW->{'.normals.f1.fangle'},$MW->{'.normals.f1.split'},$MW->{'.normals.f1.flip'}))
 {
  $_->pack('-pady','0.1i','-side','top','-anchor','w');
 }
#
$MW->{'.normals.fb'} = $MW->{'.normals'}->Frame;
$MW->{'.normals.fb.apply'} = $MW->{'.normals.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyNormals();
  }
);
$MW->{'.normals.fb.cancel'} = $MW->{'.normals.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseNormals();
  }
);
foreach $_ (($MW->{'.normals.fb.apply'},$MW->{'.normals.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
foreach $_ (($MW->{'.normals.f1'},$MW->{'.normals.fb'}))
 {
  $_->pack('-side','top','-fill','both','-expand',1);
 }
#
#
sub UpdateNormalsGUI
{
 $MW->{'.normals.f1.fangle'}->set($normals->GetFeatureAngle);
}
#
#
sub ApplyNormals
{
# Global Variables Declared for this function: edgeSplitting, flipNormals
 # Global Variables Declared for this function: RenWin
 #
 $normals->SetFeatureAngle($MW->{'.normals.f1.fangle'}->get);
 $normals->SetSplitting($edgeSplitting);
 $normals->SetFlipNormals($flipNormals);
 #
 $normals->SetInput($PolyData);
 #
 UpdateUndo($normals);
 UpdateGUI();
 #
 $RenWin->Render;
 CloseNormals();
}
#
############################ Setting background color
##
#
sub BackgroundColor
{
 my @background;
 #
 @background = $Renderer->GetBackground;
 $MW->{'.back.f1.l.r'}->set($background[0] * 255.0);
 $MW->{'.back.f1.l.g'}->set($background[1] * 255.0);
 $MW->{'.back.f1.l.b'}->set($background[2] * 255.0);
 $MW->{'.back'}->deiconify;
}
#
#
sub CloseBackground
{
 $MW->{'.back'}->withdraw;
}
#
$MW->{'.back'} = $MW->Toplevel;
$MW->{'.back'}->withdraw;
$MW->{'.back'}->title("Select Background Color");
$MW->{'.back'}->protocol('WM_DELETE_WINDOW','wm withdraw .back');
$MW->{'.back.f1'} = $MW->{'.back'}->Frame;
#
$MW->{'.back.f1.l'} = $MW->{'.back.f1'}->Frame('-relief','raised','-borderwidth',3);
$MW->{'.back.f1.l.r'} = $MW->{'.back.f1.l'}->Scale('-from',255,'-background','#f00','-to',0,'-command',
 sub
  {
   SetColor();
  }
,'-orient','vertical');
$MW->{'.back.f1.l.g'} = $MW->{'.back.f1.l'}->Scale('-from',255,'-background','#0f0','-to',0,'-command',
 sub
  {
   SetColor();
  }
,'-orient','vertical');
$MW->{'.back.f1.l.b'} = $MW->{'.back.f1.l'}->Scale('-from',255,'-background','#00f','-to',0,'-command',
 sub
  {
   SetColor();
  }
,'-orient','vertical');
foreach $_ (($MW->{'.back.f1.l.r'},$MW->{'.back.f1.l.g'},$MW->{'.back.f1.l.b'}))
 {
  $_->pack('-side','left','-fill','both');
 }
#
$MW->{'.back.f1.m'} = $MW->{'.back.f1'}->Frame('-relief','raised','-borderwidth',3);
$MW->{'.back.f1.m.sample'} = $MW->{'.back.f1.m'}->Label('-highlightthickness',0,'-text',"  Background Color  ");
$MW->{'.back.f1.m.sample'}->pack('-fill','both','-expand',1);
#
$MW->{'.back.f1.r'} = $MW->{'.back.f1'}->Frame('-relief','raised','-borderwidth',3);
$ColorWheel = $MW->Photo('-file','ColorWheel.ppm');
$MW->{'.back.f1.r.wheel'} = $MW->{'.back.f1.r'}->Label('-highlightthickness',0,'-image',$ColorWheel);
$MW->{'.back.f1.r.wheel'}->bind('<Button-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   ($r,$g,$b) = $ColorWheel->get($Ev->x,$Ev->y);
   $MW->{'.back.f1.l.r'}->set($r);
   $MW->{'.back.f1.l.g'}->set($g);
   $MW->{'.back.f1.l.b'}->set($b);
  }
);
$MW->{'.back.f1.r.wheel'}->pack('-fill','both');
foreach $_ (($MW->{'.back.f1.l'},$MW->{'.back.f1.m'},$MW->{'.back.f1.r'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','both');
 }
#
$MW->{'.back.fb'} = $MW->{'.back'}->Frame;
$MW->{'.back.fb.apply'} = $MW->{'.back.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyBackground();
  }
);
$MW->{'.back.fb.cancel'} = $MW->{'.back.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseBackground();
  }
);
foreach $_ (($MW->{'.back.fb.apply'},$MW->{'.back.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
foreach $_ (($MW->{'.back.f1'},$MW->{'.back.fb'}))
 {
  $_->pack('-side','top','-fill','both','-expand',1);
 }
#
#
sub SetColor
{
 my $value = shift;
 my $color;
 $color = sprintf('#%02x%02x%02x',$MW->{'.back.f1.l.r'}->get,$MW->{'.back.f1.l.g'}->get,$MW->{'.back.f1.l.b'}->get);
 $MW->{'.back.f1.m.sample'}->configure('-background',$color);
}
#
#
sub ApplyBackground
{
 my $Render;
 # Global Variables Declared for this function: RenWin
 #
 $Renderer->SetBackground($MW->{'.back.f1.l.r'}->get / 255.0,$MW->{'.back.f1.l.g'}->get / 255.0,$MW->{'.back.f1.l.b'}->get / 255.0);
 $CompareRenderer->SetBackground($MW->{'.back.f1.l.r'}->get / 255.0,$MW->{'.back.f1.l.g'}->get / 255.0,$MW->{'.back.f1.l.b'}->get / 255.0);
 $RenWin->Render;
}
#
############################ Set surface properties
##
#
sub Properties
{
 my @color;
 #
 @color = $property->GetColor;
 $MW->{'.prop.f1.l.r'}->set($color[0] * 255.0);
 $MW->{'.prop.f1.l.g'}->set($color[1] * 255.0);
 $MW->{'.prop.f1.l.b'}->set($color[2] * 255.0);
 $MW->{'.prop.sliders.amb'}->set($property->GetAmbient);
 $MW->{'.prop.sliders.diff'}->set($property->GetDiffuse);
 $MW->{'.prop.sliders.spec'}->set($property->GetSpecular);
 $MW->{'.prop.sliders.power'}->set($property->GetSpecularPower);
 #
 $MW->{'.prop'}->deiconify;
}
#
#
sub CloseProperties
{
 $MW->{'.prop'}->withdraw;
}
#
$MW->{'.prop'} = $MW->Toplevel;
$MW->{'.prop'}->withdraw;
$MW->{'.prop'}->title("Set Surface Properties");
$MW->{'.prop'}->protocol('WM_DELETE_WINDOW','wm withdraw .prop');
$MW->{'.prop.f1'} = $MW->{'.prop'}->Frame;
#
$MW->{'.prop.f1.l'} = $MW->{'.prop.f1'}->Frame('-relief','raised','-borderwidth',3);
$MW->{'.prop.f1.l.r'} = $MW->{'.prop.f1.l'}->Scale('-from',255,'-background','#f00','-to',0,'-command',
 sub
  {
   SetSurfaceColor();
  }
,'-orient','vertical');
$MW->{'.prop.f1.l.g'} = $MW->{'.prop.f1.l'}->Scale('-from',255,'-background','#0f0','-to',0,'-command',
 sub
  {
   SetSurfaceColor();
  }
,'-orient','vertical');
$MW->{'.prop.f1.l.b'} = $MW->{'.prop.f1.l'}->Scale('-from',255,'-background','#00f','-to',0,'-command',
 sub
  {
   SetSurfaceColor();
  }
,'-orient','vertical');
foreach $_ (($MW->{'.prop.f1.l.r'},$MW->{'.prop.f1.l.g'},$MW->{'.prop.f1.l.b'}))
 {
  $_->pack('-side','left','-fill','both');
 }
#
$MW->{'.prop.f1.m'} = $MW->{'.prop.f1'}->Frame('-relief','raised','-borderwidth',3);
$MW->{'.prop.f1.m.sample'} = $MW->{'.prop.f1.m'}->Label('-highlightthickness',0,'-text',"   Surface Color    ");
$MW->{'.prop.f1.m.sample'}->pack('-fill','both','-expand',1);
#
$MW->{'.prop.f1.r'} = $MW->{'.prop.f1'}->Frame('-relief','raised','-borderwidth',3);
$ColorWheel = $MW->Photo('-file','ColorWheel.ppm');
$MW->{'.prop.f1.r.wheel'} = $MW->{'.prop.f1.r'}->Label('-highlightthickness',0,'-image',$ColorWheel);
$MW->{'.prop.f1.r.wheel'}->bind('<Button-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   ($r,$g,$b) = $ColorWheel->get($Ev->x,$Ev->y);
   $MW->{'.prop.f1.l.r'}->set($r);
   $MW->{'.prop.f1.l.g'}->set($g);
   $MW->{'.prop.f1.l.b'}->set($b);
  }
);
$MW->{'.prop.f1.r.wheel'}->pack('-fill','both');
foreach $_ (($MW->{'.prop.f1.l'},$MW->{'.prop.f1.m'},$MW->{'.prop.f1.r'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','both');
 }
#
$MW->{'.prop.sliders'} = $MW->{'.prop'}->Frame;
$MW->{'.prop.sliders.amb'} = $MW->{'.prop.sliders'}->Scale('-from',0.00,'-label','Ambient','-resolution',0.01,'-to',1.00,'-orient','horizontal');
$MW->{'.prop.sliders.diff'} = $MW->{'.prop.sliders'}->Scale('-from',0.00,'-label','Diffuse','-resolution',0.01,'-to',1.00,'-orient','horizontal');
$MW->{'.prop.sliders.spec'} = $MW->{'.prop.sliders'}->Scale('-from',0.00,'-label','Specular','-resolution',0.01,'-to',1.00,'-orient','horizontal');
$MW->{'.prop.sliders.power'} = $MW->{'.prop.sliders'}->Scale('-from',0,'-label',"Specular Power",'-resolution',1,'-to',100,'-orient','horizontal');
foreach $_ (($MW->{'.prop.sliders.spec'},$MW->{'.prop.sliders.power'},$MW->{'.prop.sliders.amb'},$MW->{'.prop.sliders.diff'}))
 {
  $_->pack('-side','top','-fill','both');
 }
#
$MW->{'.prop.fb'} = $MW->{'.prop'}->Frame;
$MW->{'.prop.fb.apply'} = $MW->{'.prop.fb'}->Button('-text','Apply','-command',
 sub
  {
   ApplyProperties();
  }
);
$MW->{'.prop.fb.cancel'} = $MW->{'.prop.fb'}->Button('-text','Cancel','-command',
 sub
  {
   CloseProperties();
  }
);
foreach $_ (($MW->{'.prop.fb.apply'},$MW->{'.prop.fb.cancel'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','x');
 }
foreach $_ (($MW->{'.prop.f1'},$MW->{'.prop.sliders'},$MW->{'.prop.fb'}))
 {
  $_->pack('-side','top','-fill','both','-expand',1);
 }
#
#
sub SetSurfaceColor
{
 my $value = shift;
 my $color;
 $color = sprintf('#%02x%02x%02x',$MW->{'.prop.f1.l.r'}->get,$MW->{'.prop.f1.l.g'}->get,$MW->{'.prop.f1.l.b'}->get);
 $MW->{'.prop.f1.m.sample'}->configure('-background',$color);
}
#
#
sub ApplyProperties
{
 # Global Variables Declared for this function: RenWin
 #
 $property->SetColor($MW->{'.prop.f1.l.r'}->get / 255.0,$MW->{'.prop.f1.l.g'}->get / 255.0,$MW->{'.prop.f1.l.b'}->get / 255.0);
 $property->SetAmbient($MW->{'.prop.sliders.amb'}->get);
 $property->SetDiffuse($MW->{'.prop.sliders.diff'}->get);
 $property->SetSpecular($MW->{'.prop.sliders.spec'}->get);
 $property->SetSpecularPower($MW->{'.prop.sliders.power'}->get);
 $RenWin->Render;
}
#
#------------------------Procedures for ProgressWidget----------------------
#
sub StartProgress
{
 my $filter = shift;
 my $label = shift;
 my $height;
 my $width;
 # Global Variables Declared for this function: BarId
 # Global Variables Declared for this function: TextId
 #
 $height = $MW->{'.bottomF.status'}->height;
 $width = $MW->{'.bottomF.status'}->width;
 #
 unless (exists $MW->{'.bottomF.canvas'})
  {
   $MW->{'.bottomF.canvas'} = $MW->{'.bottomF'}->Canvas('-highlightthickness',0,'-borderwidth',0,'-width',$width,'-height',$height);
  }
 else
  {
   $MW->{'.bottomF.canvas'}->configure('-height',$height,'-width',$width);
   $MW->{'.bottomF.canvas'}->delete($BarId);
   $MW->{'.bottomF.canvas'}->delete($TextId);
  }
 #
 $BarId = $MW->{'.bottomF.canvas'}->create('rect',0,0,0,$height,'-fill','#888');
 $TextId = $MW->{'.bottomF.canvas'}->create('text',$width / 2,$height / 2,'-anchor','center','-justify','center','-text',$label);
 $MW->{'.bottomF.status'}->packForget;
 $MW->{'.bottomF.canvas'}->pack('-padx',0,'-pady',0);
 #
 $MW->update;
}
#
#
sub ShowProgress
{
 my $filter = shift;
 my $label = shift;
 my $height;
 my $progress;
 my $width;
 # Global Variables Declared for this function: BarId
 # Global Variables Declared for this function: TextId
 #
 $progress = $filter->GetProgress;
 $height = $MW->{'.bottomF.status'}->height;
 $width = $MW->{'.bottomF.status'}->width;
 #
 $MW->{'.bottomF.canvas'}->delete($BarId);
 $MW->{'.bottomF.canvas'}->delete($TextId);
 $BarId = $MW->{'.bottomF.canvas'}->create('rect',0,0,$progress * $width,$height,'-fill','#888');
 $TextId = $MW->{'.bottomF.canvas'}->create('text',$width / 2,$height / 2,'-anchor','center','-justify','center','-text',$label);
 #
 $MW->update;
}
#
#
sub EndProgress
{
 $MW->{'.bottomF.canvas'}->packForget;
 $MW->{'.bottomF.status'}->pack('-side','top','-anchor','w','-expand',1,'-fill','x');
 #
 $MW->update;
}
#
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
