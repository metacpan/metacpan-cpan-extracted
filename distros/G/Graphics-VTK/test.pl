# Test Scipt for the Graphics::VTK package
#
#  This checks for the presence of a VTK_DATA environment 
#  variable, and then runs all the known-good example scripts
#
#

use Cwd; # to get the current pwd

my @scripts = (qw!
Annotation/annotatePick
Annotation/cubeAxes
Annotation/labeledMesh
Annotation/multiLineText
Annotation/TestText
Annotation/textOrigin
Annotation/xyPlot
DataManipulation/Arrays
DataManipulation/CreateStrip
DataManipulation/FinancialField
DataManipulation/marching
GUI/Mace
GUI/MaceTk
ImageProcessing/Contours2D
ImageProcessing/Histogram
IO/flamingo
IO/stl
Modelling/constrainedDelaunay
Modelling/Delaunay3D
Modelling/DelMesh
Modelling/expCos
Modelling/faultLines
Modelling/hello
Modelling/iceCream
Modelling/reconstructSurface
Rendering/assembly
Rendering/CADPart
Rendering/CSpline
Rendering/Cylinder
Rendering/FilterCADPart
Rendering/keyBottle
Rendering/rainbow
Rendering/RenderLargeImage
Rendering/TPlane
Tutorial/Step1/Cone
Tutorial/Step2/Cone2
VisualizationAlgorithms/ClipCow
VisualizationAlgorithms/ColorIsosurface
VisualizationAlgorithms/CutCombustor
VisualizationAlgorithms/deciFran
VisualizationAlgorithms/DepthSort
VisualizationAlgorithms/ExtractGeometry
VisualizationAlgorithms/ExtractUGrid
VisualizationAlgorithms/GenerateTextureCoords
VisualizationAlgorithms/imageWarp
VisualizationAlgorithms/officeTube
VisualizationAlgorithms/officeTubes
VisualizationAlgorithms/probeComb
VisualizationAlgorithms/smoothFran
VisualizationAlgorithms/spikeF
VisualizationAlgorithms/streamSurface
VisualizationAlgorithms/SubsampleGrid
VisualizationAlgorithms/VisQuad
VisualizationAlgorithms/warpComb
VolumeRendering/SimpleRayCast

pipeline/Cone
pipeline/financialField

!);


# Check for VTK_DATA environment variable
unless(defined($ENV{VTK_DATA_ROOT})){
	die("Error VTK_DATA_ROOT Environment variable not defined.\nVTK Test Data Should be Downloaded from the VTK website (www.kitware.com),\nand this environment variable set to its location to test this module\n");
}

my $pwd = cwd;

foreach my $script(@scripts){
	my ($dir,$scr) = $script =~ /(.+?)\/(\w+)$/;
	chdir "$pwd/examples/$dir";
	print "Running script $script. Press 'q' or Select File->Exit to Quit\n";
	my $command = "perl -Mblib -I./ -w $scr.pl";
	system $command;
	
}

chdir $pwd;

