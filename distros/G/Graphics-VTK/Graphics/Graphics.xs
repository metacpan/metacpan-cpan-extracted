#include "EXTERN.h"

/* avoid some nasty defines on win32 that cause c++ compilation to fail */
#ifdef WIN32
#define WIN32IOP_H
#endif

#include "perl.h"
#include "XSUB.h"

/* 'THIS' gets redefined to 'void' in 
the standard mingw include 'basetyps.h', which causes problems with
the 'THIS' that appears in XS code. */
#ifdef __MINGW32__
#undef THIS
#endif

#include "vtkPerl.h"
#include "vtkAppendFilter.h"
#include "vtkAppendPolyData.h"
#include "vtkApproximatingSubdivisionFilter.h"
#include "vtkArrayCalculator.h"
#include "vtkArrowSource.h"
#include "vtkAssignAttribute.h"
#include "vtkAttributeDataToFieldDataFilter.h"
#include "vtkAxes.h"
#include "vtkBlankStructuredGrid.h"
#include "vtkBlankStructuredGridWithImage.h"
#include "vtkBrownianPoints.h"
#include "vtkButterflySubdivisionFilter.h"
#include "vtkCellCenters.h"
#include "vtkCellDataToPointData.h"
#include "vtkCellDerivatives.h"
#include "vtkCleanPolyData.h"
#include "vtkClipDataSet.h"
#include "vtkClipPolyData.h"
#include "vtkClipVolume.h"
#include "vtkConeSource.h"
#include "vtkConnectivityFilter.h"
#include "vtkContourFilter.h"
#include "vtkContourGrid.h"
#include "vtkCubeSource.h"
#include "vtkCursor3D.h"
#include "vtkCutter.h"
#include "vtkCylinderSource.h"
#include "vtkDashedStreamLine.h"
#include "vtkDataObjectToDataSetFilter.h"
#include "vtkDataSetSurfaceFilter.h"
#include "vtkDataSetToDataObjectFilter.h"
#include "vtkDataSetTriangleFilter.h"
#include "vtkDecimatePro.h"
#include "vtkDelaunay2D.h"
#include "vtkDelaunay3D.h"
#include "vtkDicer.h"
#include "vtkDiskSource.h"
#include "vtkEdgePoints.h"
#include "vtkElevationFilter.h"
#include "vtkExtractEdges.h"
#include "vtkExtractGeometry.h"
#include "vtkExtractGrid.h"
#include "vtkExtractPolyDataGeometry.h"
#include "vtkExtractTensorComponents.h"
#include "vtkExtractUnstructuredGrid.h"
#include "vtkExtractVectorComponents.h"
#include "vtkFeatureEdges.h"
#include "vtkFieldDataToAttributeDataFilter.h"
#include "vtkGeometryFilter.h"
#include "vtkGlyph2D.h"
#include "vtkGlyph3D.h"
#include "vtkGlyphSource2D.h"
#include "vtkGraphLayoutFilter.h"
#include "vtkHedgeHog.h"
#include "vtkHull.h"
#include "vtkHyperStreamline.h"
#include "vtkIdFilter.h"
#include "vtkImageDataGeometryFilter.h"
#include "vtkImplicitTextureCoords.h"
#include "vtkInterpolateDataSetAttributes.h"
#include "vtkInterpolatingSubdivisionFilter.h"
#include "vtkLineSource.h"
#include "vtkLinearExtrusionFilter.h"
#include "vtkLinearSubdivisionFilter.h"
#include "vtkLinkEdgels.h"
#include "vtkLoopSubdivisionFilter.h"
#include "vtkMaskPoints.h"
#include "vtkMaskPolyData.h"
#include "vtkMassProperties.h"
#include "vtkMergeDataObjectFilter.h"
#include "vtkMergeFields.h"
#include "vtkMergeFilter.h"
#include "vtkOBBDicer.h"
#include "vtkOBBTree.h"
#include "vtkOutlineCornerFilter.h"
#include "vtkOutlineCornerSource.h"
#include "vtkOutlineFilter.h"
#include "vtkOutlineSource.h"
#include "vtkPlaneSource.h"
#include "vtkPointDataToCellData.h"
#include "vtkPointSource.h"
#include "vtkPolyDataConnectivityFilter.h"
#include "vtkPolyDataNormals.h"
#include "vtkPolyDataStreamer.h"
#include "vtkProbeFilter.h"
#include "vtkProgrammableAttributeDataFilter.h"
#include "vtkProgrammableDataObjectSource.h"
#include "vtkProgrammableFilter.h"
#include "vtkProgrammableGlyphFilter.h"
#include "vtkProgrammableSource.h"
#include "vtkProjectedTexture.h"
#include "vtkQuadricClustering.h"
#include "vtkQuadricDecimation.h"
#include "vtkQuantizePolyDataPoints.h"
#include "vtkRearrangeFields.h"
#include "vtkRectilinearGridGeometryFilter.h"
#include "vtkRecursiveDividingCubes.h"
#include "vtkReverseSense.h"
#include "vtkRibbonFilter.h"
#include "vtkRotationalExtrusionFilter.h"
#include "vtkRuledSurfaceFilter.h"
#include "vtkSelectPolyData.h"
#include "vtkShrinkFilter.h"
#include "vtkShrinkPolyData.h"
#include "vtkSimpleElevationFilter.h"
#include "vtkSmoothPolyDataFilter.h"
#include "vtkSpatialRepresentationFilter.h"
#include "vtkSphereSource.h"
#include "vtkSplitField.h"
#include "vtkStreamLine.h"
#include "vtkStreamPoints.h"
#include "vtkStreamer.h"
#include "vtkStripper.h"
#include "vtkStructuredGridGeometryFilter.h"
#include "vtkStructuredGridOutlineFilter.h"
#include "vtkStructuredPointsGeometryFilter.h"
#include "vtkSubPixelPositionEdgels.h"
#include "vtkSubdivideTetra.h"
#include "vtkSuperquadricSource.h"
#include "vtkTensorGlyph.h"
#include "vtkTextSource.h"
#include "vtkTextureMapToCylinder.h"
#include "vtkTextureMapToPlane.h"
#include "vtkTextureMapToSphere.h"
#include "vtkTexturedSphereSource.h"
#include "vtkThreshold.h"
#include "vtkThresholdPoints.h"
#include "vtkThresholdTextureCoords.h"
#include "vtkTransformFilter.h"
#include "vtkTransformPolyDataFilter.h"
#include "vtkTransformTextureCoords.h"
#include "vtkTriangleFilter.h"
#include "vtkTriangularTCoords.h"
#include "vtkTubeFilter.h"
#include "vtkVectorDot.h"
#include "vtkVectorNorm.h"
#include "vtkVoxelContoursToSurfaceFilter.h"
#include "vtkWarpLens.h"
#include "vtkWarpScalar.h"
#include "vtkWarpTo.h"
#include "vtkWarpVector.h"
#include "vtkWindowedSincPolyDataFilter.h"
#include "vtkPropAssembly.h"
/* Routine to call a perl code ref, used by all the Set...Method methods
   like SetExecuteMethod.
*/

void
callperlsub(void * codeRef){
	SV* code = (SV*) codeRef;
	int count;
	dSP;
	PUSHMARK(SP) ;
	/*printf("callperlsub called'%s'\n",SvPV_nolen(code)); */
	count = perl_call_sv(code, G_DISCARD|G_NOARGS ) ;

}

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::AppendFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAppendFilter::AddInput(arg1 = 0)
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->AddInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAppendFilter::AddInput\n");



const char *
vtkAppendFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkAppendFilter::GetInput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAppendFilter::GetInput\n");



vtkDataSetCollection *
vtkAppendFilter::GetInputList()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSetCollection";
		CODE:
		RETVAL = THIS->GetInputList();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkAppendFilter*
vtkAppendFilter::New()
		CODE:
		RETVAL = vtkAppendFilter::New();
		OUTPUT:
		RETVAL


void
vtkAppendFilter::RemoveInput(arg1 = 0)
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->RemoveInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAppendFilter::RemoveInput\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::AppendPolyData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAppendPolyData::AddInput(arg1 = 0)
	CASE: items == 2
		vtkPolyData *	arg1
		CODE:
		THIS->AddInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAppendPolyData::AddInput\n");



const char *
vtkAppendPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkAppendPolyData::GetInput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetInput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAppendPolyData::GetInput\n");



int
vtkAppendPolyData::GetParallelStreaming()
		CODE:
		RETVAL = THIS->GetParallelStreaming();
		OUTPUT:
		RETVAL


int
vtkAppendPolyData::GetUserManagedInputs()
		CODE:
		RETVAL = THIS->GetUserManagedInputs();
		OUTPUT:
		RETVAL


static vtkAppendPolyData*
vtkAppendPolyData::New()
		CODE:
		RETVAL = vtkAppendPolyData::New();
		OUTPUT:
		RETVAL


void
vtkAppendPolyData::ParallelStreamingOff()
		CODE:
		THIS->ParallelStreamingOff();
		XSRETURN_EMPTY;


void
vtkAppendPolyData::ParallelStreamingOn()
		CODE:
		THIS->ParallelStreamingOn();
		XSRETURN_EMPTY;


void
vtkAppendPolyData::RemoveInput(arg1 = 0)
	CASE: items == 2
		vtkPolyData *	arg1
		CODE:
		THIS->RemoveInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAppendPolyData::RemoveInput\n");



void
vtkAppendPolyData::SetInputByNumber(num, input)
		int 	num
		vtkPolyData *	input
		CODE:
		THIS->SetInputByNumber(num, input);
		XSRETURN_EMPTY;


void
vtkAppendPolyData::SetNumberOfInputs(num)
		int 	num
		CODE:
		THIS->SetNumberOfInputs(num);
		XSRETURN_EMPTY;


void
vtkAppendPolyData::SetParallelStreaming(arg1)
		int 	arg1
		CODE:
		THIS->SetParallelStreaming(arg1);
		XSRETURN_EMPTY;


void
vtkAppendPolyData::SetUserManagedInputs(arg1)
		int 	arg1
		CODE:
		THIS->SetUserManagedInputs(arg1);
		XSRETURN_EMPTY;


void
vtkAppendPolyData::UserManagedInputsOff()
		CODE:
		THIS->UserManagedInputsOff();
		XSRETURN_EMPTY;


void
vtkAppendPolyData::UserManagedInputsOn()
		CODE:
		THIS->UserManagedInputsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ApproximatingSubdivisionFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkApproximatingSubdivisionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkApproximatingSubdivisionFilter::GetNumberOfSubdivisions()
		CODE:
		RETVAL = THIS->GetNumberOfSubdivisions();
		OUTPUT:
		RETVAL


void
vtkApproximatingSubdivisionFilter::SetNumberOfSubdivisions(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfSubdivisions(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ArrayCalculator PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkArrayCalculator::AddScalarArrayName(arrayName, component)
		const char *	arrayName
		int 	component
		CODE:
		THIS->AddScalarArrayName(arrayName, component);
		XSRETURN_EMPTY;


void
vtkArrayCalculator::AddScalarVariable(variableName, arrayName, component)
		const char *	variableName
		const char *	arrayName
		int 	component
		CODE:
		THIS->AddScalarVariable(variableName, arrayName, component);
		XSRETURN_EMPTY;


void
vtkArrayCalculator::AddVectorArrayName(arrayName, component0, component1, component2)
		const char *	arrayName
		int 	component0
		int 	component1
		int 	component2
		CODE:
		THIS->AddVectorArrayName(arrayName, component0, component1, component2);
		XSRETURN_EMPTY;


void
vtkArrayCalculator::AddVectorVariable(variableName, arrayName, component0, component1, component2)
		const char *	variableName
		const char *	arrayName
		int 	component0
		int 	component1
		int 	component2
		CODE:
		THIS->AddVectorVariable(variableName, arrayName, component0, component1, component2);
		XSRETURN_EMPTY;


int
vtkArrayCalculator::GetAttributeMode()
		CODE:
		RETVAL = THIS->GetAttributeMode();
		OUTPUT:
		RETVAL


const char *
vtkArrayCalculator::GetAttributeModeAsString()
		CODE:
		RETVAL = THIS->GetAttributeModeAsString();
		OUTPUT:
		RETVAL


const char *
vtkArrayCalculator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkArrayCalculator::GetFunction()
		CODE:
		RETVAL = THIS->GetFunction();
		OUTPUT:
		RETVAL


int
vtkArrayCalculator::GetNumberOfScalarArrays()
		CODE:
		RETVAL = THIS->GetNumberOfScalarArrays();
		OUTPUT:
		RETVAL


int
vtkArrayCalculator::GetNumberOfVectorArrays()
		CODE:
		RETVAL = THIS->GetNumberOfVectorArrays();
		OUTPUT:
		RETVAL


char *
vtkArrayCalculator::GetResultArrayName()
		CODE:
		RETVAL = THIS->GetResultArrayName();
		OUTPUT:
		RETVAL


char *
vtkArrayCalculator::GetScalarArrayName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetScalarArrayName(i);
		OUTPUT:
		RETVAL


char *
vtkArrayCalculator::GetScalarVariableName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetScalarVariableName(i);
		OUTPUT:
		RETVAL


int
vtkArrayCalculator::GetSelectedScalarComponent(i)
		int 	i
		CODE:
		RETVAL = THIS->GetSelectedScalarComponent(i);
		OUTPUT:
		RETVAL


char *
vtkArrayCalculator::GetVectorArrayName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetVectorArrayName(i);
		OUTPUT:
		RETVAL


char *
vtkArrayCalculator::GetVectorVariableName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetVectorVariableName(i);
		OUTPUT:
		RETVAL


static vtkArrayCalculator*
vtkArrayCalculator::New()
		CODE:
		RETVAL = vtkArrayCalculator::New();
		OUTPUT:
		RETVAL


void
vtkArrayCalculator::RemoveAllVariables()
		CODE:
		THIS->RemoveAllVariables();
		XSRETURN_EMPTY;


void
vtkArrayCalculator::SetAttributeMode(arg1)
		int 	arg1
		CODE:
		THIS->SetAttributeMode(arg1);
		XSRETURN_EMPTY;


void
vtkArrayCalculator::SetAttributeModeToDefault()
		CODE:
		THIS->SetAttributeModeToDefault();
		XSRETURN_EMPTY;


void
vtkArrayCalculator::SetAttributeModeToUseCellData()
		CODE:
		THIS->SetAttributeModeToUseCellData();
		XSRETURN_EMPTY;


void
vtkArrayCalculator::SetAttributeModeToUsePointData()
		CODE:
		THIS->SetAttributeModeToUsePointData();
		XSRETURN_EMPTY;


void
vtkArrayCalculator::SetFunction(function)
		const char *	function
		CODE:
		THIS->SetFunction(function);
		XSRETURN_EMPTY;


void
vtkArrayCalculator::SetResultArrayName(name)
		const char *	name
		CODE:
		THIS->SetResultArrayName(name);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ArrowSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkArrowSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetShaftRadius()
		CODE:
		RETVAL = THIS->GetShaftRadius();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetShaftRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetShaftRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetShaftRadiusMinValue()
		CODE:
		RETVAL = THIS->GetShaftRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkArrowSource::GetShaftResolution()
		CODE:
		RETVAL = THIS->GetShaftResolution();
		OUTPUT:
		RETVAL


int
vtkArrowSource::GetShaftResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetShaftResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkArrowSource::GetShaftResolutionMinValue()
		CODE:
		RETVAL = THIS->GetShaftResolutionMinValue();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetTipLength()
		CODE:
		RETVAL = THIS->GetTipLength();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetTipLengthMaxValue()
		CODE:
		RETVAL = THIS->GetTipLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetTipLengthMinValue()
		CODE:
		RETVAL = THIS->GetTipLengthMinValue();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetTipRadius()
		CODE:
		RETVAL = THIS->GetTipRadius();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetTipRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetTipRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkArrowSource::GetTipRadiusMinValue()
		CODE:
		RETVAL = THIS->GetTipRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkArrowSource::GetTipResolution()
		CODE:
		RETVAL = THIS->GetTipResolution();
		OUTPUT:
		RETVAL


int
vtkArrowSource::GetTipResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetTipResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkArrowSource::GetTipResolutionMinValue()
		CODE:
		RETVAL = THIS->GetTipResolutionMinValue();
		OUTPUT:
		RETVAL


static vtkArrowSource*
vtkArrowSource::New()
		CODE:
		RETVAL = vtkArrowSource::New();
		OUTPUT:
		RETVAL


void
vtkArrowSource::SetShaftRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetShaftRadius(arg1);
		XSRETURN_EMPTY;


void
vtkArrowSource::SetShaftResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetShaftResolution(arg1);
		XSRETURN_EMPTY;


void
vtkArrowSource::SetTipLength(arg1)
		float 	arg1
		CODE:
		THIS->SetTipLength(arg1);
		XSRETURN_EMPTY;


void
vtkArrowSource::SetTipRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetTipRadius(arg1);
		XSRETURN_EMPTY;


void
vtkArrowSource::SetTipResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetTipResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::AssignAttribute PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAssignAttribute::Assign(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4 && SvPOK(ST(2))
		const char *	arg1
		const char *	arg2
		const char *	arg3
		CODE:
		THIS->Assign(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 4 && SvIOK(ST(1))
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->Assign(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAssignAttribute::Assign\n");



const char *
vtkAssignAttribute::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkAssignAttribute*
vtkAssignAttribute::New()
		CODE:
		RETVAL = vtkAssignAttribute::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::AttributeDataToFieldDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkAttributeDataToFieldDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkAttributeDataToFieldDataFilter::GetPassAttributeData()
		CODE:
		RETVAL = THIS->GetPassAttributeData();
		OUTPUT:
		RETVAL


static vtkAttributeDataToFieldDataFilter*
vtkAttributeDataToFieldDataFilter::New()
		CODE:
		RETVAL = vtkAttributeDataToFieldDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkAttributeDataToFieldDataFilter::PassAttributeDataOff()
		CODE:
		THIS->PassAttributeDataOff();
		XSRETURN_EMPTY;


void
vtkAttributeDataToFieldDataFilter::PassAttributeDataOn()
		CODE:
		THIS->PassAttributeDataOn();
		XSRETURN_EMPTY;


void
vtkAttributeDataToFieldDataFilter::SetPassAttributeData(arg1)
		int 	arg1
		CODE:
		THIS->SetPassAttributeData(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Axes PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAxes::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkAxes::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


const char *
vtkAxes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkAxes::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


float  *
vtkAxes::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkAxes::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


int
vtkAxes::GetSymmetric()
		CODE:
		RETVAL = THIS->GetSymmetric();
		OUTPUT:
		RETVAL


static vtkAxes*
vtkAxes::New()
		CODE:
		RETVAL = vtkAxes::New();
		OUTPUT:
		RETVAL


void
vtkAxes::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkAxes::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAxes::SetOrigin\n");



void
vtkAxes::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkAxes::SetSymmetric(arg1)
		int 	arg1
		CODE:
		THIS->SetSymmetric(arg1);
		XSRETURN_EMPTY;


void
vtkAxes::SymmetricOff()
		CODE:
		THIS->SymmetricOff();
		XSRETURN_EMPTY;


void
vtkAxes::SymmetricOn()
		CODE:
		THIS->SymmetricOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::BlankStructuredGrid PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkBlankStructuredGrid::GetArrayId()
		CODE:
		RETVAL = THIS->GetArrayId();
		OUTPUT:
		RETVAL


char *
vtkBlankStructuredGrid::GetArrayName()
		CODE:
		RETVAL = THIS->GetArrayName();
		OUTPUT:
		RETVAL


const char *
vtkBlankStructuredGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkBlankStructuredGrid::GetComponent()
		CODE:
		RETVAL = THIS->GetComponent();
		OUTPUT:
		RETVAL


int
vtkBlankStructuredGrid::GetComponentMaxValue()
		CODE:
		RETVAL = THIS->GetComponentMaxValue();
		OUTPUT:
		RETVAL


int
vtkBlankStructuredGrid::GetComponentMinValue()
		CODE:
		RETVAL = THIS->GetComponentMinValue();
		OUTPUT:
		RETVAL


float
vtkBlankStructuredGrid::GetMaxBlankingValue()
		CODE:
		RETVAL = THIS->GetMaxBlankingValue();
		OUTPUT:
		RETVAL


float
vtkBlankStructuredGrid::GetMinBlankingValue()
		CODE:
		RETVAL = THIS->GetMinBlankingValue();
		OUTPUT:
		RETVAL


static vtkBlankStructuredGrid*
vtkBlankStructuredGrid::New()
		CODE:
		RETVAL = vtkBlankStructuredGrid::New();
		OUTPUT:
		RETVAL


void
vtkBlankStructuredGrid::SetArrayId(arg1)
		int 	arg1
		CODE:
		THIS->SetArrayId(arg1);
		XSRETURN_EMPTY;


void
vtkBlankStructuredGrid::SetArrayName(arg1)
		char *	arg1
		CODE:
		THIS->SetArrayName(arg1);
		XSRETURN_EMPTY;


void
vtkBlankStructuredGrid::SetComponent(arg1)
		int 	arg1
		CODE:
		THIS->SetComponent(arg1);
		XSRETURN_EMPTY;


void
vtkBlankStructuredGrid::SetMaxBlankingValue(arg1)
		float 	arg1
		CODE:
		THIS->SetMaxBlankingValue(arg1);
		XSRETURN_EMPTY;


void
vtkBlankStructuredGrid::SetMinBlankingValue(arg1)
		float 	arg1
		CODE:
		THIS->SetMinBlankingValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::BlankStructuredGridWithImage PREFIX = vtk

PROTOTYPES: DISABLE



vtkImageData *
vtkBlankStructuredGridWithImage::GetBlankingInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetBlankingInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkBlankStructuredGridWithImage::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkBlankStructuredGridWithImage*
vtkBlankStructuredGridWithImage::New()
		CODE:
		RETVAL = vtkBlankStructuredGridWithImage::New();
		OUTPUT:
		RETVAL


void
vtkBlankStructuredGridWithImage::SetBlankingInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetBlankingInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::BrownianPoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkBrownianPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkBrownianPoints::GetMaximumSpeed()
		CODE:
		RETVAL = THIS->GetMaximumSpeed();
		OUTPUT:
		RETVAL


float
vtkBrownianPoints::GetMaximumSpeedMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumSpeedMaxValue();
		OUTPUT:
		RETVAL


float
vtkBrownianPoints::GetMaximumSpeedMinValue()
		CODE:
		RETVAL = THIS->GetMaximumSpeedMinValue();
		OUTPUT:
		RETVAL


float
vtkBrownianPoints::GetMinimumSpeed()
		CODE:
		RETVAL = THIS->GetMinimumSpeed();
		OUTPUT:
		RETVAL


float
vtkBrownianPoints::GetMinimumSpeedMaxValue()
		CODE:
		RETVAL = THIS->GetMinimumSpeedMaxValue();
		OUTPUT:
		RETVAL


float
vtkBrownianPoints::GetMinimumSpeedMinValue()
		CODE:
		RETVAL = THIS->GetMinimumSpeedMinValue();
		OUTPUT:
		RETVAL


static vtkBrownianPoints*
vtkBrownianPoints::New()
		CODE:
		RETVAL = vtkBrownianPoints::New();
		OUTPUT:
		RETVAL


void
vtkBrownianPoints::SetMaximumSpeed(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumSpeed(arg1);
		XSRETURN_EMPTY;


void
vtkBrownianPoints::SetMinimumSpeed(arg1)
		float 	arg1
		CODE:
		THIS->SetMinimumSpeed(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ButterflySubdivisionFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkButterflySubdivisionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkButterflySubdivisionFilter*
vtkButterflySubdivisionFilter::New()
		CODE:
		RETVAL = vtkButterflySubdivisionFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::CellCenters PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCellCenters::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCellCenters::GetVertexCells()
		CODE:
		RETVAL = THIS->GetVertexCells();
		OUTPUT:
		RETVAL


static vtkCellCenters*
vtkCellCenters::New()
		CODE:
		RETVAL = vtkCellCenters::New();
		OUTPUT:
		RETVAL


void
vtkCellCenters::SetVertexCells(arg1)
		int 	arg1
		CODE:
		THIS->SetVertexCells(arg1);
		XSRETURN_EMPTY;


void
vtkCellCenters::VertexCellsOff()
		CODE:
		THIS->VertexCellsOff();
		XSRETURN_EMPTY;


void
vtkCellCenters::VertexCellsOn()
		CODE:
		THIS->VertexCellsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::CellDataToPointData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCellDataToPointData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCellDataToPointData::GetPassCellData()
		CODE:
		RETVAL = THIS->GetPassCellData();
		OUTPUT:
		RETVAL


static vtkCellDataToPointData*
vtkCellDataToPointData::New()
		CODE:
		RETVAL = vtkCellDataToPointData::New();
		OUTPUT:
		RETVAL


void
vtkCellDataToPointData::PassCellDataOff()
		CODE:
		THIS->PassCellDataOff();
		XSRETURN_EMPTY;


void
vtkCellDataToPointData::PassCellDataOn()
		CODE:
		THIS->PassCellDataOn();
		XSRETURN_EMPTY;


void
vtkCellDataToPointData::SetPassCellData(arg1)
		int 	arg1
		CODE:
		THIS->SetPassCellData(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::CellDerivatives PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCellDerivatives::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCellDerivatives::GetTensorMode()
		CODE:
		RETVAL = THIS->GetTensorMode();
		OUTPUT:
		RETVAL


const char *
vtkCellDerivatives::GetTensorModeAsString()
		CODE:
		RETVAL = THIS->GetTensorModeAsString();
		OUTPUT:
		RETVAL


int
vtkCellDerivatives::GetVectorMode()
		CODE:
		RETVAL = THIS->GetVectorMode();
		OUTPUT:
		RETVAL


const char *
vtkCellDerivatives::GetVectorModeAsString()
		CODE:
		RETVAL = THIS->GetVectorModeAsString();
		OUTPUT:
		RETVAL


static vtkCellDerivatives*
vtkCellDerivatives::New()
		CODE:
		RETVAL = vtkCellDerivatives::New();
		OUTPUT:
		RETVAL


void
vtkCellDerivatives::SetTensorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetTensorMode(arg1);
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetTensorModeToComputeGradient()
		CODE:
		THIS->SetTensorModeToComputeGradient();
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetTensorModeToComputeStrain()
		CODE:
		THIS->SetTensorModeToComputeStrain();
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetTensorModeToPassTensors()
		CODE:
		THIS->SetTensorModeToPassTensors();
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetVectorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetVectorMode(arg1);
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetVectorModeToComputeGradient()
		CODE:
		THIS->SetVectorModeToComputeGradient();
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetVectorModeToComputeVorticity()
		CODE:
		THIS->SetVectorModeToComputeVorticity();
		XSRETURN_EMPTY;


void
vtkCellDerivatives::SetVectorModeToPassVectors()
		CODE:
		THIS->SetVectorModeToPassVectors();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::CleanPolyData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCleanPolyData::ConvertLinesToPointsOff()
		CODE:
		THIS->ConvertLinesToPointsOff();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ConvertLinesToPointsOn()
		CODE:
		THIS->ConvertLinesToPointsOn();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ConvertPolysToLinesOff()
		CODE:
		THIS->ConvertPolysToLinesOff();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ConvertPolysToLinesOn()
		CODE:
		THIS->ConvertPolysToLinesOn();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ConvertStripsToPolysOff()
		CODE:
		THIS->ConvertStripsToPolysOff();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ConvertStripsToPolysOn()
		CODE:
		THIS->ConvertStripsToPolysOn();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


float
vtkCleanPolyData::GetAbsoluteTolerance()
		CODE:
		RETVAL = THIS->GetAbsoluteTolerance();
		OUTPUT:
		RETVAL


float
vtkCleanPolyData::GetAbsoluteToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetAbsoluteToleranceMaxValue();
		OUTPUT:
		RETVAL


float
vtkCleanPolyData::GetAbsoluteToleranceMinValue()
		CODE:
		RETVAL = THIS->GetAbsoluteToleranceMinValue();
		OUTPUT:
		RETVAL


const char *
vtkCleanPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCleanPolyData::GetConvertLinesToPoints()
		CODE:
		RETVAL = THIS->GetConvertLinesToPoints();
		OUTPUT:
		RETVAL


int
vtkCleanPolyData::GetConvertPolysToLines()
		CODE:
		RETVAL = THIS->GetConvertPolysToLines();
		OUTPUT:
		RETVAL


int
vtkCleanPolyData::GetConvertStripsToPolys()
		CODE:
		RETVAL = THIS->GetConvertStripsToPolys();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkCleanPolyData::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkCleanPolyData::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkCleanPolyData::GetPieceInvariant()
		CODE:
		RETVAL = THIS->GetPieceInvariant();
		OUTPUT:
		RETVAL


int
vtkCleanPolyData::GetPointMerging()
		CODE:
		RETVAL = THIS->GetPointMerging();
		OUTPUT:
		RETVAL


float
vtkCleanPolyData::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


int
vtkCleanPolyData::GetToleranceIsAbsolute()
		CODE:
		RETVAL = THIS->GetToleranceIsAbsolute();
		OUTPUT:
		RETVAL


float
vtkCleanPolyData::GetToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetToleranceMaxValue();
		OUTPUT:
		RETVAL


float
vtkCleanPolyData::GetToleranceMinValue()
		CODE:
		RETVAL = THIS->GetToleranceMinValue();
		OUTPUT:
		RETVAL


static vtkCleanPolyData*
vtkCleanPolyData::New()
		CODE:
		RETVAL = vtkCleanPolyData::New();
		OUTPUT:
		RETVAL


void
vtkCleanPolyData::PieceInvariantOff()
		CODE:
		THIS->PieceInvariantOff();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::PieceInvariantOn()
		CODE:
		THIS->PieceInvariantOn();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::PointMergingOff()
		CODE:
		THIS->PointMergingOff();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::PointMergingOn()
		CODE:
		THIS->PointMergingOn();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ReleaseLocator()
		CODE:
		THIS->ReleaseLocator();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetAbsoluteTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetAbsoluteTolerance(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetConvertLinesToPoints(arg1)
		int 	arg1
		CODE:
		THIS->SetConvertLinesToPoints(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetConvertPolysToLines(arg1)
		int 	arg1
		CODE:
		THIS->SetConvertPolysToLines(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetConvertStripsToPolys(arg1)
		int 	arg1
		CODE:
		THIS->SetConvertStripsToPolys(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetPieceInvariant(arg1)
		int 	arg1
		CODE:
		THIS->SetPieceInvariant(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetPointMerging(arg1)
		int 	arg1
		CODE:
		THIS->SetPointMerging(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::SetToleranceIsAbsolute(arg1)
		int 	arg1
		CODE:
		THIS->SetToleranceIsAbsolute(arg1);
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ToleranceIsAbsoluteOff()
		CODE:
		THIS->ToleranceIsAbsoluteOff();
		XSRETURN_EMPTY;


void
vtkCleanPolyData::ToleranceIsAbsoluteOn()
		CODE:
		THIS->ToleranceIsAbsoluteOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ClipDataSet PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkClipDataSet::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkClipDataSet::GenerateClipScalarsOff()
		CODE:
		THIS->GenerateClipScalarsOff();
		XSRETURN_EMPTY;


void
vtkClipDataSet::GenerateClipScalarsOn()
		CODE:
		THIS->GenerateClipScalarsOn();
		XSRETURN_EMPTY;


void
vtkClipDataSet::GenerateClippedOutputOff()
		CODE:
		THIS->GenerateClippedOutputOff();
		XSRETURN_EMPTY;


void
vtkClipDataSet::GenerateClippedOutputOn()
		CODE:
		THIS->GenerateClippedOutputOn();
		XSRETURN_EMPTY;


const char *
vtkClipDataSet::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkClipDataSet::GetClipFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetClipFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkClipDataSet::GetClippedOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetClippedOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkClipDataSet::GetGenerateClipScalars()
		CODE:
		RETVAL = THIS->GetGenerateClipScalars();
		OUTPUT:
		RETVAL


int
vtkClipDataSet::GetGenerateClippedOutput()
		CODE:
		RETVAL = THIS->GetGenerateClippedOutput();
		OUTPUT:
		RETVAL


int
vtkClipDataSet::GetInsideOut()
		CODE:
		RETVAL = THIS->GetInsideOut();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkClipDataSet::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkClipDataSet::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkClipDataSet::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


void
vtkClipDataSet::InsideOutOff()
		CODE:
		THIS->InsideOutOff();
		XSRETURN_EMPTY;


void
vtkClipDataSet::InsideOutOn()
		CODE:
		THIS->InsideOutOn();
		XSRETURN_EMPTY;


static vtkClipDataSet*
vtkClipDataSet::New()
		CODE:
		RETVAL = vtkClipDataSet::New();
		OUTPUT:
		RETVAL


void
vtkClipDataSet::SetClipFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetClipFunction(arg1);
		XSRETURN_EMPTY;


void
vtkClipDataSet::SetGenerateClipScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateClipScalars(arg1);
		XSRETURN_EMPTY;


void
vtkClipDataSet::SetGenerateClippedOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateClippedOutput(arg1);
		XSRETURN_EMPTY;


void
vtkClipDataSet::SetInsideOut(arg1)
		int 	arg1
		CODE:
		THIS->SetInsideOut(arg1);
		XSRETURN_EMPTY;


void
vtkClipDataSet::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkClipDataSet::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ClipPolyData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkClipPolyData::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkClipPolyData::GenerateClipScalarsOff()
		CODE:
		THIS->GenerateClipScalarsOff();
		XSRETURN_EMPTY;


void
vtkClipPolyData::GenerateClipScalarsOn()
		CODE:
		THIS->GenerateClipScalarsOn();
		XSRETURN_EMPTY;


void
vtkClipPolyData::GenerateClippedOutputOff()
		CODE:
		THIS->GenerateClippedOutputOff();
		XSRETURN_EMPTY;


void
vtkClipPolyData::GenerateClippedOutputOn()
		CODE:
		THIS->GenerateClippedOutputOn();
		XSRETURN_EMPTY;


const char *
vtkClipPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkClipPolyData::GetClipFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetClipFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPolyData *
vtkClipPolyData::GetClippedOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetClippedOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkClipPolyData::GetGenerateClipScalars()
		CODE:
		RETVAL = THIS->GetGenerateClipScalars();
		OUTPUT:
		RETVAL


int
vtkClipPolyData::GetGenerateClippedOutput()
		CODE:
		RETVAL = THIS->GetGenerateClippedOutput();
		OUTPUT:
		RETVAL


int
vtkClipPolyData::GetInsideOut()
		CODE:
		RETVAL = THIS->GetInsideOut();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkClipPolyData::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkClipPolyData::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkClipPolyData::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


void
vtkClipPolyData::InsideOutOff()
		CODE:
		THIS->InsideOutOff();
		XSRETURN_EMPTY;


void
vtkClipPolyData::InsideOutOn()
		CODE:
		THIS->InsideOutOn();
		XSRETURN_EMPTY;


static vtkClipPolyData*
vtkClipPolyData::New()
		CODE:
		RETVAL = vtkClipPolyData::New();
		OUTPUT:
		RETVAL


void
vtkClipPolyData::SetClipFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetClipFunction(arg1);
		XSRETURN_EMPTY;


void
vtkClipPolyData::SetGenerateClipScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateClipScalars(arg1);
		XSRETURN_EMPTY;


void
vtkClipPolyData::SetGenerateClippedOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateClippedOutput(arg1);
		XSRETURN_EMPTY;


void
vtkClipPolyData::SetInsideOut(arg1)
		int 	arg1
		CODE:
		THIS->SetInsideOut(arg1);
		XSRETURN_EMPTY;


void
vtkClipPolyData::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkClipPolyData::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ClipVolume PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkClipVolume::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkClipVolume::GenerateClipScalarsOff()
		CODE:
		THIS->GenerateClipScalarsOff();
		XSRETURN_EMPTY;


void
vtkClipVolume::GenerateClipScalarsOn()
		CODE:
		THIS->GenerateClipScalarsOn();
		XSRETURN_EMPTY;


void
vtkClipVolume::GenerateClippedOutputOff()
		CODE:
		THIS->GenerateClippedOutputOff();
		XSRETURN_EMPTY;


void
vtkClipVolume::GenerateClippedOutputOn()
		CODE:
		THIS->GenerateClippedOutputOn();
		XSRETURN_EMPTY;


const char *
vtkClipVolume::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkClipVolume::GetClipFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetClipFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkClipVolume::GetClippedOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetClippedOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkClipVolume::GetGenerateClipScalars()
		CODE:
		RETVAL = THIS->GetGenerateClipScalars();
		OUTPUT:
		RETVAL


int
vtkClipVolume::GetGenerateClippedOutput()
		CODE:
		RETVAL = THIS->GetGenerateClippedOutput();
		OUTPUT:
		RETVAL


int
vtkClipVolume::GetInsideOut()
		CODE:
		RETVAL = THIS->GetInsideOut();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkClipVolume::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkClipVolume::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkClipVolume::GetMergeTolerance()
		CODE:
		RETVAL = THIS->GetMergeTolerance();
		OUTPUT:
		RETVAL


float
vtkClipVolume::GetMergeToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetMergeToleranceMaxValue();
		OUTPUT:
		RETVAL


float
vtkClipVolume::GetMergeToleranceMinValue()
		CODE:
		RETVAL = THIS->GetMergeToleranceMinValue();
		OUTPUT:
		RETVAL


float
vtkClipVolume::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


void
vtkClipVolume::InsideOutOff()
		CODE:
		THIS->InsideOutOff();
		XSRETURN_EMPTY;


void
vtkClipVolume::InsideOutOn()
		CODE:
		THIS->InsideOutOn();
		XSRETURN_EMPTY;


static vtkClipVolume*
vtkClipVolume::New()
		CODE:
		RETVAL = vtkClipVolume::New();
		OUTPUT:
		RETVAL


void
vtkClipVolume::SetClipFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetClipFunction(arg1);
		XSRETURN_EMPTY;


void
vtkClipVolume::SetGenerateClipScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateClipScalars(arg1);
		XSRETURN_EMPTY;


void
vtkClipVolume::SetGenerateClippedOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateClippedOutput(arg1);
		XSRETURN_EMPTY;


void
vtkClipVolume::SetInsideOut(arg1)
		int 	arg1
		CODE:
		THIS->SetInsideOut(arg1);
		XSRETURN_EMPTY;


void
vtkClipVolume::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkClipVolume::SetMergeTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetMergeTolerance(arg1);
		XSRETURN_EMPTY;


void
vtkClipVolume::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ConeSource PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkConeSource::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkConeSource::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


float
vtkConeSource::GetAngle()
		CODE:
		RETVAL = THIS->GetAngle();
		OUTPUT:
		RETVAL


int
vtkConeSource::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkConeSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkConeSource::GetHeight()
		CODE:
		RETVAL = THIS->GetHeight();
		OUTPUT:
		RETVAL


float
vtkConeSource::GetHeightMaxValue()
		CODE:
		RETVAL = THIS->GetHeightMaxValue();
		OUTPUT:
		RETVAL


float
vtkConeSource::GetHeightMinValue()
		CODE:
		RETVAL = THIS->GetHeightMinValue();
		OUTPUT:
		RETVAL


float
vtkConeSource::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkConeSource::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkConeSource::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkConeSource::GetResolution()
		CODE:
		RETVAL = THIS->GetResolution();
		OUTPUT:
		RETVAL


int
vtkConeSource::GetResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkConeSource::GetResolutionMinValue()
		CODE:
		RETVAL = THIS->GetResolutionMinValue();
		OUTPUT:
		RETVAL


static vtkConeSource*
vtkConeSource::New()
		CODE:
		RETVAL = vtkConeSource::New();
		OUTPUT:
		RETVAL


void
vtkConeSource::SetAngle(angle)
		float 	angle
		CODE:
		THIS->SetAngle(angle);
		XSRETURN_EMPTY;


void
vtkConeSource::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkConeSource::SetHeight(arg1)
		float 	arg1
		CODE:
		THIS->SetHeight(arg1);
		XSRETURN_EMPTY;


void
vtkConeSource::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkConeSource::SetResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ConnectivityFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkConnectivityFilter::AddSeed(id)
		long 	id
		CODE:
		THIS->AddSeed(id);
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::AddSpecifiedRegion(id)
		int 	id
		CODE:
		THIS->AddSpecifiedRegion(id);
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::ColorRegionsOff()
		CODE:
		THIS->ColorRegionsOff();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::ColorRegionsOn()
		CODE:
		THIS->ColorRegionsOn();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::DeleteSeed(id)
		long 	id
		CODE:
		THIS->DeleteSeed(id);
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::DeleteSpecifiedRegion(id)
		int 	id
		CODE:
		THIS->DeleteSpecifiedRegion(id);
		XSRETURN_EMPTY;


const char *
vtkConnectivityFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkConnectivityFilter::GetClosestPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetClosestPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkConnectivityFilter::GetColorRegions()
		CODE:
		RETVAL = THIS->GetColorRegions();
		OUTPUT:
		RETVAL


int
vtkConnectivityFilter::GetExtractionMode()
		CODE:
		RETVAL = THIS->GetExtractionMode();
		OUTPUT:
		RETVAL


const char *
vtkConnectivityFilter::GetExtractionModeAsString()
		CODE:
		RETVAL = THIS->GetExtractionModeAsString();
		OUTPUT:
		RETVAL


int
vtkConnectivityFilter::GetExtractionModeMaxValue()
		CODE:
		RETVAL = THIS->GetExtractionModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkConnectivityFilter::GetExtractionModeMinValue()
		CODE:
		RETVAL = THIS->GetExtractionModeMinValue();
		OUTPUT:
		RETVAL


int
vtkConnectivityFilter::GetNumberOfExtractedRegions()
		CODE:
		RETVAL = THIS->GetNumberOfExtractedRegions();
		OUTPUT:
		RETVAL


int
vtkConnectivityFilter::GetScalarConnectivity()
		CODE:
		RETVAL = THIS->GetScalarConnectivity();
		OUTPUT:
		RETVAL


float  *
vtkConnectivityFilter::GetScalarRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


void
vtkConnectivityFilter::InitializeSeedList()
		CODE:
		THIS->InitializeSeedList();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::InitializeSpecifiedRegionList()
		CODE:
		THIS->InitializeSpecifiedRegionList();
		XSRETURN_EMPTY;


static vtkConnectivityFilter*
vtkConnectivityFilter::New()
		CODE:
		RETVAL = vtkConnectivityFilter::New();
		OUTPUT:
		RETVAL


void
vtkConnectivityFilter::ScalarConnectivityOff()
		CODE:
		THIS->ScalarConnectivityOff();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::ScalarConnectivityOn()
		CODE:
		THIS->ScalarConnectivityOn();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetClosestPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetClosestPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkConnectivityFilter::SetClosestPoint\n");



void
vtkConnectivityFilter::SetColorRegions(arg1)
		int 	arg1
		CODE:
		THIS->SetColorRegions(arg1);
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionMode(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractionMode(arg1);
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionModeToAllRegions()
		CODE:
		THIS->SetExtractionModeToAllRegions();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionModeToCellSeededRegions()
		CODE:
		THIS->SetExtractionModeToCellSeededRegions();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionModeToClosestPointRegion()
		CODE:
		THIS->SetExtractionModeToClosestPointRegion();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionModeToLargestRegion()
		CODE:
		THIS->SetExtractionModeToLargestRegion();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionModeToPointSeededRegions()
		CODE:
		THIS->SetExtractionModeToPointSeededRegions();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetExtractionModeToSpecifiedRegions()
		CODE:
		THIS->SetExtractionModeToSpecifiedRegions();
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetScalarConnectivity(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarConnectivity(arg1);
		XSRETURN_EMPTY;


void
vtkConnectivityFilter::SetScalarRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetScalarRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkConnectivityFilter::SetScalarRange\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ContourFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkContourFilter::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkContourFilter::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkContourFilter::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkContourFilter::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkContourFilter::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkContourFilter::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkContourFilter::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkContourFilter::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkContourFilter::GenerateValues\n");



const char *
vtkContourFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkContourFilter::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkContourFilter::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkContourFilter::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkContourFilter::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkContourFilter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkContourFilter::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


int
vtkContourFilter::GetUseScalarTree()
		CODE:
		RETVAL = THIS->GetUseScalarTree();
		OUTPUT:
		RETVAL


float
vtkContourFilter::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkContourFilter*
vtkContourFilter::New()
		CODE:
		RETVAL = vtkContourFilter::New();
		OUTPUT:
		RETVAL


void
vtkContourFilter::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkContourFilter::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkContourFilter::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkContourFilter::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkContourFilter::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkContourFilter::SetUseScalarTree(arg1)
		int 	arg1
		CODE:
		THIS->SetUseScalarTree(arg1);
		XSRETURN_EMPTY;


void
vtkContourFilter::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;


void
vtkContourFilter::UseScalarTreeOff()
		CODE:
		THIS->UseScalarTreeOff();
		XSRETURN_EMPTY;


void
vtkContourFilter::UseScalarTreeOn()
		CODE:
		THIS->UseScalarTreeOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ContourGrid PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkContourGrid::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkContourGrid::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkContourGrid::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkContourGrid::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkContourGrid::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkContourGrid::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkContourGrid::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkContourGrid::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkContourGrid::GenerateValues\n");



const char *
vtkContourGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkContourGrid::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkContourGrid::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkContourGrid::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkContourGrid::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkContourGrid::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkContourGrid::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


int
vtkContourGrid::GetUseScalarTree()
		CODE:
		RETVAL = THIS->GetUseScalarTree();
		OUTPUT:
		RETVAL


float
vtkContourGrid::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkContourGrid*
vtkContourGrid::New()
		CODE:
		RETVAL = vtkContourGrid::New();
		OUTPUT:
		RETVAL


void
vtkContourGrid::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkContourGrid::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkContourGrid::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkContourGrid::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkContourGrid::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkContourGrid::SetUseScalarTree(arg1)
		int 	arg1
		CODE:
		THIS->SetUseScalarTree(arg1);
		XSRETURN_EMPTY;


void
vtkContourGrid::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;


void
vtkContourGrid::UseScalarTreeOff()
		CODE:
		THIS->UseScalarTreeOff();
		XSRETURN_EMPTY;


void
vtkContourGrid::UseScalarTreeOn()
		CODE:
		THIS->UseScalarTreeOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::CubeSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkCubeSource::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkCubeSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetXLength()
		CODE:
		RETVAL = THIS->GetXLength();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetXLengthMaxValue()
		CODE:
		RETVAL = THIS->GetXLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetXLengthMinValue()
		CODE:
		RETVAL = THIS->GetXLengthMinValue();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetYLength()
		CODE:
		RETVAL = THIS->GetYLength();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetYLengthMaxValue()
		CODE:
		RETVAL = THIS->GetYLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetYLengthMinValue()
		CODE:
		RETVAL = THIS->GetYLengthMinValue();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetZLength()
		CODE:
		RETVAL = THIS->GetZLength();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetZLengthMaxValue()
		CODE:
		RETVAL = THIS->GetZLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkCubeSource::GetZLengthMinValue()
		CODE:
		RETVAL = THIS->GetZLengthMinValue();
		OUTPUT:
		RETVAL


static vtkCubeSource*
vtkCubeSource::New()
		CODE:
		RETVAL = vtkCubeSource::New();
		OUTPUT:
		RETVAL


void
vtkCubeSource::SetBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCubeSource::SetBounds\n");



void
vtkCubeSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCubeSource::SetCenter\n");



void
vtkCubeSource::SetXLength(arg1)
		float 	arg1
		CODE:
		THIS->SetXLength(arg1);
		XSRETURN_EMPTY;


void
vtkCubeSource::SetYLength(arg1)
		float 	arg1
		CODE:
		THIS->SetYLength(arg1);
		XSRETURN_EMPTY;


void
vtkCubeSource::SetZLength(arg1)
		float 	arg1
		CODE:
		THIS->SetZLength(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Cursor3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCursor3D::AllOff()
		CODE:
		THIS->AllOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::AllOn()
		CODE:
		THIS->AllOn();
		XSRETURN_EMPTY;


void
vtkCursor3D::AxesOff()
		CODE:
		THIS->AxesOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::AxesOn()
		CODE:
		THIS->AxesOn();
		XSRETURN_EMPTY;


int
vtkCursor3D::GetAxes()
		CODE:
		RETVAL = THIS->GetAxes();
		OUTPUT:
		RETVAL


const char *
vtkCursor3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkCursor3D::GetFocalPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFocalPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkPolyData *
vtkCursor3D::GetFocus()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetFocus();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkCursor3D::GetModelBounds()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetModelBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int
vtkCursor3D::GetOutline()
		CODE:
		RETVAL = THIS->GetOutline();
		OUTPUT:
		RETVAL


int
vtkCursor3D::GetWrap()
		CODE:
		RETVAL = THIS->GetWrap();
		OUTPUT:
		RETVAL


int
vtkCursor3D::GetXShadows()
		CODE:
		RETVAL = THIS->GetXShadows();
		OUTPUT:
		RETVAL


int
vtkCursor3D::GetYShadows()
		CODE:
		RETVAL = THIS->GetYShadows();
		OUTPUT:
		RETVAL


int
vtkCursor3D::GetZShadows()
		CODE:
		RETVAL = THIS->GetZShadows();
		OUTPUT:
		RETVAL


static vtkCursor3D*
vtkCursor3D::New()
		CODE:
		RETVAL = vtkCursor3D::New();
		OUTPUT:
		RETVAL


void
vtkCursor3D::OutlineOff()
		CODE:
		THIS->OutlineOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::OutlineOn()
		CODE:
		THIS->OutlineOn();
		XSRETURN_EMPTY;


void
vtkCursor3D::SetAxes(arg1)
		int 	arg1
		CODE:
		THIS->SetAxes(arg1);
		XSRETURN_EMPTY;


void
vtkCursor3D::SetFocalPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetFocalPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCursor3D::SetFocalPoint\n");



void
vtkCursor3D::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetModelBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCursor3D::SetModelBounds\n");



void
vtkCursor3D::SetOutline(arg1)
		int 	arg1
		CODE:
		THIS->SetOutline(arg1);
		XSRETURN_EMPTY;


void
vtkCursor3D::SetWrap(arg1)
		int 	arg1
		CODE:
		THIS->SetWrap(arg1);
		XSRETURN_EMPTY;


void
vtkCursor3D::SetXShadows(arg1)
		int 	arg1
		CODE:
		THIS->SetXShadows(arg1);
		XSRETURN_EMPTY;


void
vtkCursor3D::SetYShadows(arg1)
		int 	arg1
		CODE:
		THIS->SetYShadows(arg1);
		XSRETURN_EMPTY;


void
vtkCursor3D::SetZShadows(arg1)
		int 	arg1
		CODE:
		THIS->SetZShadows(arg1);
		XSRETURN_EMPTY;


void
vtkCursor3D::WrapOff()
		CODE:
		THIS->WrapOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::WrapOn()
		CODE:
		THIS->WrapOn();
		XSRETURN_EMPTY;


void
vtkCursor3D::XShadowsOff()
		CODE:
		THIS->XShadowsOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::XShadowsOn()
		CODE:
		THIS->XShadowsOn();
		XSRETURN_EMPTY;


void
vtkCursor3D::YShadowsOff()
		CODE:
		THIS->YShadowsOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::YShadowsOn()
		CODE:
		THIS->YShadowsOn();
		XSRETURN_EMPTY;


void
vtkCursor3D::ZShadowsOff()
		CODE:
		THIS->ZShadowsOff();
		XSRETURN_EMPTY;


void
vtkCursor3D::ZShadowsOn()
		CODE:
		THIS->ZShadowsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Cutter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCutter::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkCutter::GenerateCutScalarsOff()
		CODE:
		THIS->GenerateCutScalarsOff();
		XSRETURN_EMPTY;


void
vtkCutter::GenerateCutScalarsOn()
		CODE:
		THIS->GenerateCutScalarsOn();
		XSRETURN_EMPTY;


void
vtkCutter::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCutter::GenerateValues\n");



const char *
vtkCutter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkCutter::GetCutFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetCutFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkCutter::GetGenerateCutScalars()
		CODE:
		RETVAL = THIS->GetGenerateCutScalars();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkCutter::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkCutter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkCutter::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


int
vtkCutter::GetSortBy()
		CODE:
		RETVAL = THIS->GetSortBy();
		OUTPUT:
		RETVAL


const char *
vtkCutter::GetSortByAsString()
		CODE:
		RETVAL = THIS->GetSortByAsString();
		OUTPUT:
		RETVAL


int
vtkCutter::GetSortByMaxValue()
		CODE:
		RETVAL = THIS->GetSortByMaxValue();
		OUTPUT:
		RETVAL


int
vtkCutter::GetSortByMinValue()
		CODE:
		RETVAL = THIS->GetSortByMinValue();
		OUTPUT:
		RETVAL


float
vtkCutter::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkCutter*
vtkCutter::New()
		CODE:
		RETVAL = vtkCutter::New();
		OUTPUT:
		RETVAL


void
vtkCutter::SetCutFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetCutFunction(arg1);
		XSRETURN_EMPTY;


void
vtkCutter::SetGenerateCutScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateCutScalars(arg1);
		XSRETURN_EMPTY;


void
vtkCutter::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkCutter::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkCutter::SetSortBy(arg1)
		int 	arg1
		CODE:
		THIS->SetSortBy(arg1);
		XSRETURN_EMPTY;


void
vtkCutter::SetSortByToSortByCell()
		CODE:
		THIS->SetSortByToSortByCell();
		XSRETURN_EMPTY;


void
vtkCutter::SetSortByToSortByValue()
		CODE:
		THIS->SetSortByToSortByValue();
		XSRETURN_EMPTY;


void
vtkCutter::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::CylinderSource PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCylinderSource::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkCylinderSource::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


int
vtkCylinderSource::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


float  *
vtkCylinderSource::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkCylinderSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkCylinderSource::GetHeight()
		CODE:
		RETVAL = THIS->GetHeight();
		OUTPUT:
		RETVAL


float
vtkCylinderSource::GetHeightMaxValue()
		CODE:
		RETVAL = THIS->GetHeightMaxValue();
		OUTPUT:
		RETVAL


float
vtkCylinderSource::GetHeightMinValue()
		CODE:
		RETVAL = THIS->GetHeightMinValue();
		OUTPUT:
		RETVAL


float
vtkCylinderSource::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkCylinderSource::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkCylinderSource::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkCylinderSource::GetResolution()
		CODE:
		RETVAL = THIS->GetResolution();
		OUTPUT:
		RETVAL


int
vtkCylinderSource::GetResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkCylinderSource::GetResolutionMinValue()
		CODE:
		RETVAL = THIS->GetResolutionMinValue();
		OUTPUT:
		RETVAL


static vtkCylinderSource*
vtkCylinderSource::New()
		CODE:
		RETVAL = vtkCylinderSource::New();
		OUTPUT:
		RETVAL


void
vtkCylinderSource::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkCylinderSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCylinderSource::SetCenter\n");



void
vtkCylinderSource::SetHeight(arg1)
		float 	arg1
		CODE:
		THIS->SetHeight(arg1);
		XSRETURN_EMPTY;


void
vtkCylinderSource::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkCylinderSource::SetResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DashedStreamLine PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDashedStreamLine::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkDashedStreamLine::GetDashFactor()
		CODE:
		RETVAL = THIS->GetDashFactor();
		OUTPUT:
		RETVAL


float
vtkDashedStreamLine::GetDashFactorMaxValue()
		CODE:
		RETVAL = THIS->GetDashFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkDashedStreamLine::GetDashFactorMinValue()
		CODE:
		RETVAL = THIS->GetDashFactorMinValue();
		OUTPUT:
		RETVAL


static vtkDashedStreamLine*
vtkDashedStreamLine::New()
		CODE:
		RETVAL = vtkDashedStreamLine::New();
		OUTPUT:
		RETVAL


void
vtkDashedStreamLine::SetDashFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetDashFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DataObjectToDataSetFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataObjectToDataSetFilter::DefaultNormalizeOff()
		CODE:
		THIS->DefaultNormalizeOff();
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::DefaultNormalizeOn()
		CODE:
		THIS->DefaultNormalizeOn();
		XSRETURN_EMPTY;


int
vtkDataObjectToDataSetFilter::GetCellConnectivityComponentArrayComponent()
		CODE:
		RETVAL = THIS->GetCellConnectivityComponentArrayComponent();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetCellConnectivityComponentArrayName()
		CODE:
		RETVAL = THIS->GetCellConnectivityComponentArrayName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetCellConnectivityComponentMaxRange()
		CODE:
		RETVAL = THIS->GetCellConnectivityComponentMaxRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetCellConnectivityComponentMinRange()
		CODE:
		RETVAL = THIS->GetCellConnectivityComponentMinRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetCellTypeComponentArrayComponent()
		CODE:
		RETVAL = THIS->GetCellTypeComponentArrayComponent();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetCellTypeComponentArrayName()
		CODE:
		RETVAL = THIS->GetCellTypeComponentArrayName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetCellTypeComponentMaxRange()
		CODE:
		RETVAL = THIS->GetCellTypeComponentMaxRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetCellTypeComponentMinRange()
		CODE:
		RETVAL = THIS->GetCellTypeComponentMinRange();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetDataSetType()
		CODE:
		RETVAL = THIS->GetDataSetType();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetDefaultNormalize()
		CODE:
		RETVAL = THIS->GetDefaultNormalize();
		OUTPUT:
		RETVAL


int  *
vtkDataObjectToDataSetFilter::GetDimensions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDimensions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkDataObject *
vtkDataObjectToDataSetFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetLinesComponentArrayComponent()
		CODE:
		RETVAL = THIS->GetLinesComponentArrayComponent();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetLinesComponentArrayName()
		CODE:
		RETVAL = THIS->GetLinesComponentArrayName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetLinesComponentMaxRange()
		CODE:
		RETVAL = THIS->GetLinesComponentMaxRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetLinesComponentMinRange()
		CODE:
		RETVAL = THIS->GetLinesComponentMinRange();
		OUTPUT:
		RETVAL


float  *
vtkDataObjectToDataSetFilter::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkDataSet *
vtkDataObjectToDataSetFilter::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::GetOutput\n");



int
vtkDataObjectToDataSetFilter::GetPointComponentArrayComponent(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetPointComponentArrayComponent(comp);
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetPointComponentArrayName(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetPointComponentArrayName(comp);
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetPointComponentMaxRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetPointComponentMaxRange(comp);
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetPointComponentMinRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetPointComponentMinRange(comp);
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetPointComponentNormailzeFlag(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetPointComponentNormailzeFlag(comp);
		OUTPUT:
		RETVAL


vtkPolyData *
vtkDataObjectToDataSetFilter::GetPolyDataOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetPolyDataOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetPolysComponentArrayComponent()
		CODE:
		RETVAL = THIS->GetPolysComponentArrayComponent();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetPolysComponentArrayName()
		CODE:
		RETVAL = THIS->GetPolysComponentArrayName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetPolysComponentMaxRange()
		CODE:
		RETVAL = THIS->GetPolysComponentMaxRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetPolysComponentMinRange()
		CODE:
		RETVAL = THIS->GetPolysComponentMinRange();
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkDataObjectToDataSetFilter::GetRectilinearGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetRectilinearGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkDataObjectToDataSetFilter::GetSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkDataObjectToDataSetFilter::GetStripsComponentArrayComponent()
		CODE:
		RETVAL = THIS->GetStripsComponentArrayComponent();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetStripsComponentArrayName()
		CODE:
		RETVAL = THIS->GetStripsComponentArrayName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetStripsComponentMaxRange()
		CODE:
		RETVAL = THIS->GetStripsComponentMaxRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetStripsComponentMinRange()
		CODE:
		RETVAL = THIS->GetStripsComponentMinRange();
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkDataObjectToDataSetFilter::GetStructuredGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetStructuredGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkDataObjectToDataSetFilter::GetStructuredPointsOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetStructuredPointsOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkDataObjectToDataSetFilter::GetUnstructuredGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetUnstructuredGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetVertsComponentArrayComponent()
		CODE:
		RETVAL = THIS->GetVertsComponentArrayComponent();
		OUTPUT:
		RETVAL


const char *
vtkDataObjectToDataSetFilter::GetVertsComponentArrayName()
		CODE:
		RETVAL = THIS->GetVertsComponentArrayName();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetVertsComponentMaxRange()
		CODE:
		RETVAL = THIS->GetVertsComponentMaxRange();
		OUTPUT:
		RETVAL


int
vtkDataObjectToDataSetFilter::GetVertsComponentMinRange()
		CODE:
		RETVAL = THIS->GetVertsComponentMinRange();
		OUTPUT:
		RETVAL


static vtkDataObjectToDataSetFilter*
vtkDataObjectToDataSetFilter::New()
		CODE:
		RETVAL = vtkDataObjectToDataSetFilter::New();
		OUTPUT:
		RETVAL


void
vtkDataObjectToDataSetFilter::SetCellConnectivityComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetCellConnectivityComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetCellConnectivityComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetCellConnectivityComponent\n");



void
vtkDataObjectToDataSetFilter::SetCellTypeComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetCellTypeComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetCellTypeComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetCellTypeComponent\n");



void
vtkDataObjectToDataSetFilter::SetDataSetType(arg1)
		int 	arg1
		CODE:
		THIS->SetDataSetType(arg1);
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDataSetTypeToPolyData()
		CODE:
		THIS->SetDataSetTypeToPolyData();
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDataSetTypeToRectilinearGrid()
		CODE:
		THIS->SetDataSetTypeToRectilinearGrid();
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDataSetTypeToStructuredGrid()
		CODE:
		THIS->SetDataSetTypeToStructuredGrid();
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDataSetTypeToStructuredPoints()
		CODE:
		THIS->SetDataSetTypeToStructuredPoints();
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDataSetTypeToUnstructuredGrid()
		CODE:
		THIS->SetDataSetTypeToUnstructuredGrid();
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDefaultNormalize(arg1)
		int 	arg1
		CODE:
		THIS->SetDefaultNormalize(arg1);
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetDimensions\n");



void
vtkDataObjectToDataSetFilter::SetDimensionsComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetDimensionsComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetDimensionsComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetDimensionsComponent\n");



void
vtkDataObjectToDataSetFilter::SetInput(input)
		vtkDataObject *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkDataObjectToDataSetFilter::SetLinesComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetLinesComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetLinesComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetLinesComponent\n");



void
vtkDataObjectToDataSetFilter::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetOrigin\n");



void
vtkDataObjectToDataSetFilter::SetOriginComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetOriginComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetOriginComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetOriginComponent\n");



void
vtkDataObjectToDataSetFilter::SetPointComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		char *	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetPointComponent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		char *	arg2
		int 	arg3
		CODE:
		THIS->SetPointComponent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetPointComponent\n");



void
vtkDataObjectToDataSetFilter::SetPolysComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetPolysComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetPolysComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetPolysComponent\n");



void
vtkDataObjectToDataSetFilter::SetSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetSpacing\n");



void
vtkDataObjectToDataSetFilter::SetSpacingComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetSpacingComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetSpacingComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetSpacingComponent\n");



void
vtkDataObjectToDataSetFilter::SetStripsComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetStripsComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetStripsComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetStripsComponent\n");



void
vtkDataObjectToDataSetFilter::SetVertsComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		char *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetVertsComponent(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		THIS->SetVertsComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectToDataSetFilter::SetVertsComponent\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DataSetSurfaceFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetSurfaceFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDataSetSurfaceFilter::GetUseStrips()
		CODE:
		RETVAL = THIS->GetUseStrips();
		OUTPUT:
		RETVAL


static vtkDataSetSurfaceFilter*
vtkDataSetSurfaceFilter::New()
		CODE:
		RETVAL = vtkDataSetSurfaceFilter::New();
		OUTPUT:
		RETVAL


void
vtkDataSetSurfaceFilter::SetUseStrips(arg1)
		int 	arg1
		CODE:
		THIS->SetUseStrips(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetSurfaceFilter::UseStripsOff()
		CODE:
		THIS->UseStripsOff();
		XSRETURN_EMPTY;


void
vtkDataSetSurfaceFilter::UseStripsOn()
		CODE:
		THIS->UseStripsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DataSetToDataObjectFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataSetToDataObjectFilter::CellDataOff()
		CODE:
		THIS->CellDataOff();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::CellDataOn()
		CODE:
		THIS->CellDataOn();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::FieldDataOff()
		CODE:
		THIS->FieldDataOff();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::FieldDataOn()
		CODE:
		THIS->FieldDataOn();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::GeometryOff()
		CODE:
		THIS->GeometryOff();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::GeometryOn()
		CODE:
		THIS->GeometryOn();
		XSRETURN_EMPTY;


int
vtkDataSetToDataObjectFilter::GetCellData()
		CODE:
		RETVAL = THIS->GetCellData();
		OUTPUT:
		RETVAL


const char *
vtkDataSetToDataObjectFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDataSetToDataObjectFilter::GetFieldData()
		CODE:
		RETVAL = THIS->GetFieldData();
		OUTPUT:
		RETVAL


int
vtkDataSetToDataObjectFilter::GetGeometry()
		CODE:
		RETVAL = THIS->GetGeometry();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetToDataObjectFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDataSetToDataObjectFilter::GetPointData()
		CODE:
		RETVAL = THIS->GetPointData();
		OUTPUT:
		RETVAL


int
vtkDataSetToDataObjectFilter::GetTopology()
		CODE:
		RETVAL = THIS->GetTopology();
		OUTPUT:
		RETVAL


static vtkDataSetToDataObjectFilter*
vtkDataSetToDataObjectFilter::New()
		CODE:
		RETVAL = vtkDataSetToDataObjectFilter::New();
		OUTPUT:
		RETVAL


void
vtkDataSetToDataObjectFilter::PointDataOff()
		CODE:
		THIS->PointDataOff();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::PointDataOn()
		CODE:
		THIS->PointDataOn();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::SetCellData(arg1)
		int 	arg1
		CODE:
		THIS->SetCellData(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::SetFieldData(arg1)
		int 	arg1
		CODE:
		THIS->SetFieldData(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::SetGeometry(arg1)
		int 	arg1
		CODE:
		THIS->SetGeometry(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::SetPointData(arg1)
		int 	arg1
		CODE:
		THIS->SetPointData(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::SetTopology(arg1)
		int 	arg1
		CODE:
		THIS->SetTopology(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::TopologyOff()
		CODE:
		THIS->TopologyOff();
		XSRETURN_EMPTY;


void
vtkDataSetToDataObjectFilter::TopologyOn()
		CODE:
		THIS->TopologyOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DataSetTriangleFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetTriangleFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkDataSetTriangleFilter*
vtkDataSetTriangleFilter::New()
		CODE:
		RETVAL = vtkDataSetTriangleFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DecimatePro PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDecimatePro::AccumulateErrorOff()
		CODE:
		THIS->AccumulateErrorOff();
		XSRETURN_EMPTY;


void
vtkDecimatePro::AccumulateErrorOn()
		CODE:
		THIS->AccumulateErrorOn();
		XSRETURN_EMPTY;


void
vtkDecimatePro::BoundaryVertexDeletionOff()
		CODE:
		THIS->BoundaryVertexDeletionOff();
		XSRETURN_EMPTY;


void
vtkDecimatePro::BoundaryVertexDeletionOn()
		CODE:
		THIS->BoundaryVertexDeletionOn();
		XSRETURN_EMPTY;


float
vtkDecimatePro::GetAbsoluteError()
		CODE:
		RETVAL = THIS->GetAbsoluteError();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetAbsoluteErrorMaxValue()
		CODE:
		RETVAL = THIS->GetAbsoluteErrorMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetAbsoluteErrorMinValue()
		CODE:
		RETVAL = THIS->GetAbsoluteErrorMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetAccumulateError()
		CODE:
		RETVAL = THIS->GetAccumulateError();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetBoundaryVertexDeletion()
		CODE:
		RETVAL = THIS->GetBoundaryVertexDeletion();
		OUTPUT:
		RETVAL


const char *
vtkDecimatePro::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetDegree()
		CODE:
		RETVAL = THIS->GetDegree();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetDegreeMaxValue()
		CODE:
		RETVAL = THIS->GetDegreeMaxValue();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetDegreeMinValue()
		CODE:
		RETVAL = THIS->GetDegreeMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetErrorIsAbsolute()
		CODE:
		RETVAL = THIS->GetErrorIsAbsolute();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetFeatureAngle()
		CODE:
		RETVAL = THIS->GetFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetInflectionPointRatio()
		CODE:
		RETVAL = THIS->GetInflectionPointRatio();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetInflectionPointRatioMaxValue()
		CODE:
		RETVAL = THIS->GetInflectionPointRatioMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetInflectionPointRatioMinValue()
		CODE:
		RETVAL = THIS->GetInflectionPointRatioMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetMaximumError()
		CODE:
		RETVAL = THIS->GetMaximumError();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetMaximumErrorMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumErrorMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetMaximumErrorMinValue()
		CODE:
		RETVAL = THIS->GetMaximumErrorMinValue();
		OUTPUT:
		RETVAL


long
vtkDecimatePro::GetNumberOfInflectionPoints()
		CODE:
		RETVAL = THIS->GetNumberOfInflectionPoints();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetPreSplitMesh()
		CODE:
		RETVAL = THIS->GetPreSplitMesh();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetPreserveTopology()
		CODE:
		RETVAL = THIS->GetPreserveTopology();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetSplitAngle()
		CODE:
		RETVAL = THIS->GetSplitAngle();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetSplitAngleMaxValue()
		CODE:
		RETVAL = THIS->GetSplitAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetSplitAngleMinValue()
		CODE:
		RETVAL = THIS->GetSplitAngleMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimatePro::GetSplitting()
		CODE:
		RETVAL = THIS->GetSplitting();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetTargetReduction()
		CODE:
		RETVAL = THIS->GetTargetReduction();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetTargetReductionMaxValue()
		CODE:
		RETVAL = THIS->GetTargetReductionMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimatePro::GetTargetReductionMinValue()
		CODE:
		RETVAL = THIS->GetTargetReductionMinValue();
		OUTPUT:
		RETVAL


static vtkDecimatePro*
vtkDecimatePro::New()
		CODE:
		RETVAL = vtkDecimatePro::New();
		OUTPUT:
		RETVAL


void
vtkDecimatePro::PreSplitMeshOff()
		CODE:
		THIS->PreSplitMeshOff();
		XSRETURN_EMPTY;


void
vtkDecimatePro::PreSplitMeshOn()
		CODE:
		THIS->PreSplitMeshOn();
		XSRETURN_EMPTY;


void
vtkDecimatePro::PreserveTopologyOff()
		CODE:
		THIS->PreserveTopologyOff();
		XSRETURN_EMPTY;


void
vtkDecimatePro::PreserveTopologyOn()
		CODE:
		THIS->PreserveTopologyOn();
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetAbsoluteError(arg1)
		float 	arg1
		CODE:
		THIS->SetAbsoluteError(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetAccumulateError(arg1)
		int 	arg1
		CODE:
		THIS->SetAccumulateError(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetBoundaryVertexDeletion(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundaryVertexDeletion(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetDegree(arg1)
		int 	arg1
		CODE:
		THIS->SetDegree(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetErrorIsAbsolute(arg1)
		int 	arg1
		CODE:
		THIS->SetErrorIsAbsolute(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetInflectionPointRatio(arg1)
		float 	arg1
		CODE:
		THIS->SetInflectionPointRatio(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetMaximumError(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumError(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetPreSplitMesh(arg1)
		int 	arg1
		CODE:
		THIS->SetPreSplitMesh(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetPreserveTopology(arg1)
		int 	arg1
		CODE:
		THIS->SetPreserveTopology(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetSplitAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetSplitAngle(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetSplitting(arg1)
		int 	arg1
		CODE:
		THIS->SetSplitting(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SetTargetReduction(arg1)
		float 	arg1
		CODE:
		THIS->SetTargetReduction(arg1);
		XSRETURN_EMPTY;


void
vtkDecimatePro::SplittingOff()
		CODE:
		THIS->SplittingOff();
		XSRETURN_EMPTY;


void
vtkDecimatePro::SplittingOn()
		CODE:
		THIS->SplittingOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Delaunay2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDelaunay2D::BoundingTriangulationOff()
		CODE:
		THIS->BoundingTriangulationOff();
		XSRETURN_EMPTY;


void
vtkDelaunay2D::BoundingTriangulationOn()
		CODE:
		THIS->BoundingTriangulationOn();
		XSRETURN_EMPTY;


double
vtkDelaunay2D::GetAlpha()
		CODE:
		RETVAL = THIS->GetAlpha();
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetAlphaMaxValue()
		CODE:
		RETVAL = THIS->GetAlphaMaxValue();
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetAlphaMinValue()
		CODE:
		RETVAL = THIS->GetAlphaMinValue();
		OUTPUT:
		RETVAL


int
vtkDelaunay2D::GetBoundingTriangulation()
		CODE:
		RETVAL = THIS->GetBoundingTriangulation();
		OUTPUT:
		RETVAL


const char *
vtkDelaunay2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPointSet *
vtkDelaunay2D::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkDelaunay2D::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetToleranceMaxValue();
		OUTPUT:
		RETVAL


double
vtkDelaunay2D::GetToleranceMinValue()
		CODE:
		RETVAL = THIS->GetToleranceMinValue();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkDelaunay2D::GetTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDelaunay2D*
vtkDelaunay2D::New()
		CODE:
		RETVAL = vtkDelaunay2D::New();
		OUTPUT:
		RETVAL


void
vtkDelaunay2D::SetAlpha(arg1)
		double 	arg1
		CODE:
		THIS->SetAlpha(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay2D::SetBoundingTriangulation(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundingTriangulation(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay2D::SetInput(input)
		vtkPointSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkDelaunay2D::SetOffset(arg1)
		double 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay2D::SetSource(arg1)
		vtkPolyData *	arg1
		CODE:
		THIS->SetSource(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay2D::SetTolerance(arg1)
		double 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay2D::SetTransform(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->SetTransform(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Delaunay3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDelaunay3D::BoundingTriangulationOff()
		CODE:
		THIS->BoundingTriangulationOff();
		XSRETURN_EMPTY;


void
vtkDelaunay3D::BoundingTriangulationOn()
		CODE:
		THIS->BoundingTriangulationOn();
		XSRETURN_EMPTY;


void
vtkDelaunay3D::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkDelaunay3D::EndPointInsertion()
		CODE:
		THIS->EndPointInsertion();
		XSRETURN_EMPTY;


float
vtkDelaunay3D::GetAlpha()
		CODE:
		RETVAL = THIS->GetAlpha();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetAlphaMaxValue()
		CODE:
		RETVAL = THIS->GetAlphaMaxValue();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetAlphaMinValue()
		CODE:
		RETVAL = THIS->GetAlphaMinValue();
		OUTPUT:
		RETVAL


int
vtkDelaunay3D::GetBoundingTriangulation()
		CODE:
		RETVAL = THIS->GetBoundingTriangulation();
		OUTPUT:
		RETVAL


const char *
vtkDelaunay3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPointSet *
vtkDelaunay3D::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkDelaunay3D::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkDelaunay3D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetToleranceMaxValue();
		OUTPUT:
		RETVAL


float
vtkDelaunay3D::GetToleranceMinValue()
		CODE:
		RETVAL = THIS->GetToleranceMinValue();
		OUTPUT:
		RETVAL


static vtkDelaunay3D*
vtkDelaunay3D::New()
		CODE:
		RETVAL = vtkDelaunay3D::New();
		OUTPUT:
		RETVAL


void
vtkDelaunay3D::SetAlpha(arg1)
		float 	arg1
		CODE:
		THIS->SetAlpha(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay3D::SetBoundingTriangulation(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundingTriangulation(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay3D::SetInput(input)
		vtkPointSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkDelaunay3D::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkDelaunay3D::SetOffset(arg1)
		float 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkDelaunay3D::SetTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Dicer PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDicer::FieldDataOff()
		CODE:
		THIS->FieldDataOff();
		XSRETURN_EMPTY;


void
vtkDicer::FieldDataOn()
		CODE:
		THIS->FieldDataOn();
		XSRETURN_EMPTY;


const char *
vtkDicer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDicer::GetDiceMode()
		CODE:
		RETVAL = THIS->GetDiceMode();
		OUTPUT:
		RETVAL


int
vtkDicer::GetDiceModeMaxValue()
		CODE:
		RETVAL = THIS->GetDiceModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkDicer::GetDiceModeMinValue()
		CODE:
		RETVAL = THIS->GetDiceModeMinValue();
		OUTPUT:
		RETVAL


int
vtkDicer::GetFieldData()
		CODE:
		RETVAL = THIS->GetFieldData();
		OUTPUT:
		RETVAL


unsigned long
vtkDicer::GetMemoryLimit()
		CODE:
		RETVAL = THIS->GetMemoryLimit();
		OUTPUT:
		RETVAL


unsigned
vtkDicer::GetMemoryLimitMaxValue()
		CODE:
		RETVAL = THIS->GetMemoryLimitMaxValue();
		OUTPUT:
		RETVAL


unsigned
vtkDicer::GetMemoryLimitMinValue()
		CODE:
		RETVAL = THIS->GetMemoryLimitMinValue();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfActualPieces()
		CODE:
		RETVAL = THIS->GetNumberOfActualPieces();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfPieces()
		CODE:
		RETVAL = THIS->GetNumberOfPieces();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfPiecesMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfPiecesMaxValue();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfPiecesMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfPiecesMinValue();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfPointsPerPiece()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerPiece();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfPointsPerPieceMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerPieceMaxValue();
		OUTPUT:
		RETVAL


int
vtkDicer::GetNumberOfPointsPerPieceMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerPieceMinValue();
		OUTPUT:
		RETVAL


void
vtkDicer::SetDiceMode(arg1)
		int 	arg1
		CODE:
		THIS->SetDiceMode(arg1);
		XSRETURN_EMPTY;


void
vtkDicer::SetDiceModeToMemoryLimitPerPiece()
		CODE:
		THIS->SetDiceModeToMemoryLimitPerPiece();
		XSRETURN_EMPTY;


void
vtkDicer::SetDiceModeToNumberOfPointsPerPiece()
		CODE:
		THIS->SetDiceModeToNumberOfPointsPerPiece();
		XSRETURN_EMPTY;


void
vtkDicer::SetDiceModeToSpecifiedNumberOfPieces()
		CODE:
		THIS->SetDiceModeToSpecifiedNumberOfPieces();
		XSRETURN_EMPTY;


void
vtkDicer::SetFieldData(arg1)
		int 	arg1
		CODE:
		THIS->SetFieldData(arg1);
		XSRETURN_EMPTY;


void
vtkDicer::SetMemoryLimit(arg1)
		unsigned long 	arg1
		CODE:
		THIS->SetMemoryLimit(arg1);
		XSRETURN_EMPTY;


void
vtkDicer::SetNumberOfPieces(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfPieces(arg1);
		XSRETURN_EMPTY;


void
vtkDicer::SetNumberOfPointsPerPiece(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfPointsPerPiece(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::DiskSource PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkDiskSource::GetCircumferentialResolution()
		CODE:
		RETVAL = THIS->GetCircumferentialResolution();
		OUTPUT:
		RETVAL


int
vtkDiskSource::GetCircumferentialResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetCircumferentialResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkDiskSource::GetCircumferentialResolutionMinValue()
		CODE:
		RETVAL = THIS->GetCircumferentialResolutionMinValue();
		OUTPUT:
		RETVAL


const char *
vtkDiskSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkDiskSource::GetInnerRadius()
		CODE:
		RETVAL = THIS->GetInnerRadius();
		OUTPUT:
		RETVAL


float
vtkDiskSource::GetInnerRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetInnerRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkDiskSource::GetInnerRadiusMinValue()
		CODE:
		RETVAL = THIS->GetInnerRadiusMinValue();
		OUTPUT:
		RETVAL


float
vtkDiskSource::GetOuterRadius()
		CODE:
		RETVAL = THIS->GetOuterRadius();
		OUTPUT:
		RETVAL


float
vtkDiskSource::GetOuterRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetOuterRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkDiskSource::GetOuterRadiusMinValue()
		CODE:
		RETVAL = THIS->GetOuterRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkDiskSource::GetRadialResolution()
		CODE:
		RETVAL = THIS->GetRadialResolution();
		OUTPUT:
		RETVAL


int
vtkDiskSource::GetRadialResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetRadialResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkDiskSource::GetRadialResolutionMinValue()
		CODE:
		RETVAL = THIS->GetRadialResolutionMinValue();
		OUTPUT:
		RETVAL


static vtkDiskSource*
vtkDiskSource::New()
		CODE:
		RETVAL = vtkDiskSource::New();
		OUTPUT:
		RETVAL


void
vtkDiskSource::SetCircumferentialResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetCircumferentialResolution(arg1);
		XSRETURN_EMPTY;


void
vtkDiskSource::SetInnerRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetInnerRadius(arg1);
		XSRETURN_EMPTY;


void
vtkDiskSource::SetOuterRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetOuterRadius(arg1);
		XSRETURN_EMPTY;


void
vtkDiskSource::SetRadialResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetRadialResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::EdgePoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEdgePoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkEdgePoints::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


static vtkEdgePoints*
vtkEdgePoints::New()
		CODE:
		RETVAL = vtkEdgePoints::New();
		OUTPUT:
		RETVAL


void
vtkEdgePoints::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ElevationFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkElevationFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkElevationFilter::GetHighPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetHighPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkElevationFilter::GetLowPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetLowPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkElevationFilter::GetScalarRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkElevationFilter*
vtkElevationFilter::New()
		CODE:
		RETVAL = vtkElevationFilter::New();
		OUTPUT:
		RETVAL


void
vtkElevationFilter::SetHighPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetHighPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkElevationFilter::SetHighPoint\n");



void
vtkElevationFilter::SetLowPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetLowPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkElevationFilter::SetLowPoint\n");



void
vtkElevationFilter::SetScalarRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetScalarRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkElevationFilter::SetScalarRange\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractEdges PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkExtractEdges::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


const char *
vtkExtractEdges::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkExtractEdges::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkExtractEdges::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


static vtkExtractEdges*
vtkExtractEdges::New()
		CODE:
		RETVAL = vtkExtractEdges::New();
		OUTPUT:
		RETVAL


void
vtkExtractEdges::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractGeometry PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkExtractGeometry::ExtractBoundaryCellsOff()
		CODE:
		THIS->ExtractBoundaryCellsOff();
		XSRETURN_EMPTY;


void
vtkExtractGeometry::ExtractBoundaryCellsOn()
		CODE:
		THIS->ExtractBoundaryCellsOn();
		XSRETURN_EMPTY;


void
vtkExtractGeometry::ExtractInsideOff()
		CODE:
		THIS->ExtractInsideOff();
		XSRETURN_EMPTY;


void
vtkExtractGeometry::ExtractInsideOn()
		CODE:
		THIS->ExtractInsideOn();
		XSRETURN_EMPTY;


const char *
vtkExtractGeometry::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkExtractGeometry::GetExtractBoundaryCells()
		CODE:
		RETVAL = THIS->GetExtractBoundaryCells();
		OUTPUT:
		RETVAL


int
vtkExtractGeometry::GetExtractInside()
		CODE:
		RETVAL = THIS->GetExtractInside();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkExtractGeometry::GetImplicitFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetImplicitFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkExtractGeometry::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


static vtkExtractGeometry*
vtkExtractGeometry::New()
		CODE:
		RETVAL = vtkExtractGeometry::New();
		OUTPUT:
		RETVAL


void
vtkExtractGeometry::SetExtractBoundaryCells(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractBoundaryCells(arg1);
		XSRETURN_EMPTY;


void
vtkExtractGeometry::SetExtractInside(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractInside(arg1);
		XSRETURN_EMPTY;


void
vtkExtractGeometry::SetImplicitFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetImplicitFunction(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractGrid PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkExtractGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkExtractGrid::GetIncludeBoundary()
		CODE:
		RETVAL = THIS->GetIncludeBoundary();
		OUTPUT:
		RETVAL


int  *
vtkExtractGrid::GetSampleRate()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSampleRate();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int  *
vtkExtractGrid::GetVOI()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVOI();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


void
vtkExtractGrid::IncludeBoundaryOff()
		CODE:
		THIS->IncludeBoundaryOff();
		XSRETURN_EMPTY;


void
vtkExtractGrid::IncludeBoundaryOn()
		CODE:
		THIS->IncludeBoundaryOn();
		XSRETURN_EMPTY;


static vtkExtractGrid*
vtkExtractGrid::New()
		CODE:
		RETVAL = vtkExtractGrid::New();
		OUTPUT:
		RETVAL


void
vtkExtractGrid::SetIncludeBoundary(arg1)
		int 	arg1
		CODE:
		THIS->SetIncludeBoundary(arg1);
		XSRETURN_EMPTY;


void
vtkExtractGrid::SetSampleRate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleRate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractGrid::SetSampleRate\n");



void
vtkExtractGrid::SetVOI(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetVOI(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractGrid::SetVOI\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractPolyDataGeometry PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkExtractPolyDataGeometry::ExtractBoundaryCellsOff()
		CODE:
		THIS->ExtractBoundaryCellsOff();
		XSRETURN_EMPTY;


void
vtkExtractPolyDataGeometry::ExtractBoundaryCellsOn()
		CODE:
		THIS->ExtractBoundaryCellsOn();
		XSRETURN_EMPTY;


void
vtkExtractPolyDataGeometry::ExtractInsideOff()
		CODE:
		THIS->ExtractInsideOff();
		XSRETURN_EMPTY;


void
vtkExtractPolyDataGeometry::ExtractInsideOn()
		CODE:
		THIS->ExtractInsideOn();
		XSRETURN_EMPTY;


const char *
vtkExtractPolyDataGeometry::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkExtractPolyDataGeometry::GetExtractBoundaryCells()
		CODE:
		RETVAL = THIS->GetExtractBoundaryCells();
		OUTPUT:
		RETVAL


int
vtkExtractPolyDataGeometry::GetExtractInside()
		CODE:
		RETVAL = THIS->GetExtractInside();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkExtractPolyDataGeometry::GetImplicitFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetImplicitFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkExtractPolyDataGeometry::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


static vtkExtractPolyDataGeometry*
vtkExtractPolyDataGeometry::New()
		CODE:
		RETVAL = vtkExtractPolyDataGeometry::New();
		OUTPUT:
		RETVAL


void
vtkExtractPolyDataGeometry::SetExtractBoundaryCells(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractBoundaryCells(arg1);
		XSRETURN_EMPTY;


void
vtkExtractPolyDataGeometry::SetExtractInside(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractInside(arg1);
		XSRETURN_EMPTY;


void
vtkExtractPolyDataGeometry::SetImplicitFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetImplicitFunction(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractTensorComponents PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkExtractTensorComponents::ExtractNormalsOff()
		CODE:
		THIS->ExtractNormalsOff();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractNormalsOn()
		CODE:
		THIS->ExtractNormalsOn();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractScalarsOff()
		CODE:
		THIS->ExtractScalarsOff();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractScalarsOn()
		CODE:
		THIS->ExtractScalarsOn();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractTCoordsOff()
		CODE:
		THIS->ExtractTCoordsOff();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractTCoordsOn()
		CODE:
		THIS->ExtractTCoordsOn();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractVectorsOff()
		CODE:
		THIS->ExtractVectorsOff();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ExtractVectorsOn()
		CODE:
		THIS->ExtractVectorsOn();
		XSRETURN_EMPTY;


const char *
vtkExtractTensorComponents::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetExtractNormals()
		CODE:
		RETVAL = THIS->GetExtractNormals();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetExtractScalars()
		CODE:
		RETVAL = THIS->GetExtractScalars();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetExtractTCoords()
		CODE:
		RETVAL = THIS->GetExtractTCoords();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetExtractVectors()
		CODE:
		RETVAL = THIS->GetExtractVectors();
		OUTPUT:
		RETVAL


int  *
vtkExtractTensorComponents::GetNormalComponents()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNormalComponents();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int
vtkExtractTensorComponents::GetNormalizeNormals()
		CODE:
		RETVAL = THIS->GetNormalizeNormals();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetNumberOfTCoords()
		CODE:
		RETVAL = THIS->GetNumberOfTCoords();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetNumberOfTCoordsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfTCoordsMaxValue();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetNumberOfTCoordsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfTCoordsMinValue();
		OUTPUT:
		RETVAL


int
vtkExtractTensorComponents::GetPassTensorsToOutput()
		CODE:
		RETVAL = THIS->GetPassTensorsToOutput();
		OUTPUT:
		RETVAL


int  *
vtkExtractTensorComponents::GetScalarComponents()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarComponents();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkExtractTensorComponents::GetScalarMode()
		CODE:
		RETVAL = THIS->GetScalarMode();
		OUTPUT:
		RETVAL


int  *
vtkExtractTensorComponents::GetTCoordComponents()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTCoordComponents();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int  *
vtkExtractTensorComponents::GetVectorComponents()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVectorComponents();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


static vtkExtractTensorComponents*
vtkExtractTensorComponents::New()
		CODE:
		RETVAL = vtkExtractTensorComponents::New();
		OUTPUT:
		RETVAL


void
vtkExtractTensorComponents::NormalizeNormalsOff()
		CODE:
		THIS->NormalizeNormalsOff();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::NormalizeNormalsOn()
		CODE:
		THIS->NormalizeNormalsOn();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::PassTensorsToOutputOff()
		CODE:
		THIS->PassTensorsToOutputOff();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::PassTensorsToOutputOn()
		CODE:
		THIS->PassTensorsToOutputOn();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ScalarIsComponent()
		CODE:
		THIS->ScalarIsComponent();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ScalarIsDeterminant()
		CODE:
		THIS->ScalarIsDeterminant();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::ScalarIsEffectiveStress()
		CODE:
		THIS->ScalarIsEffectiveStress();
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetExtractNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractNormals(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetExtractScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractScalars(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetExtractTCoords(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractTCoords(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetExtractVectors(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractVectors(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetNormalComponents(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetNormalComponents(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractTensorComponents::SetNormalComponents\n");



void
vtkExtractTensorComponents::SetNormalizeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetNormalizeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetNumberOfTCoords(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfTCoords(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetPassTensorsToOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetPassTensorsToOutput(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetScalarComponents(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetScalarComponents(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractTensorComponents::SetScalarComponents\n");



void
vtkExtractTensorComponents::SetScalarMode(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarMode(arg1);
		XSRETURN_EMPTY;


void
vtkExtractTensorComponents::SetTCoordComponents(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetTCoordComponents(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractTensorComponents::SetTCoordComponents\n");



void
vtkExtractTensorComponents::SetVectorComponents(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetVectorComponents(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractTensorComponents::SetVectorComponents\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractUnstructuredGrid PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkExtractUnstructuredGrid::CellClippingOff()
		CODE:
		THIS->CellClippingOff();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::CellClippingOn()
		CODE:
		THIS->CellClippingOn();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::ExtentClippingOff()
		CODE:
		THIS->ExtentClippingOff();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::ExtentClippingOn()
		CODE:
		THIS->ExtentClippingOn();
		XSRETURN_EMPTY;


int
vtkExtractUnstructuredGrid::GetCellClipping()
		CODE:
		RETVAL = THIS->GetCellClipping();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetCellMaximum()
		CODE:
		RETVAL = THIS->GetCellMaximum();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetCellMaximumMaxValue()
		CODE:
		RETVAL = THIS->GetCellMaximumMaxValue();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetCellMaximumMinValue()
		CODE:
		RETVAL = THIS->GetCellMaximumMinValue();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetCellMinimum()
		CODE:
		RETVAL = THIS->GetCellMinimum();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetCellMinimumMaxValue()
		CODE:
		RETVAL = THIS->GetCellMinimumMaxValue();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetCellMinimumMinValue()
		CODE:
		RETVAL = THIS->GetCellMinimumMinValue();
		OUTPUT:
		RETVAL


const char *
vtkExtractUnstructuredGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkExtractUnstructuredGrid::GetExtent()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int
vtkExtractUnstructuredGrid::GetExtentClipping()
		CODE:
		RETVAL = THIS->GetExtentClipping();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkExtractUnstructuredGrid::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkExtractUnstructuredGrid::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkExtractUnstructuredGrid::GetMerging()
		CODE:
		RETVAL = THIS->GetMerging();
		OUTPUT:
		RETVAL


int
vtkExtractUnstructuredGrid::GetPointClipping()
		CODE:
		RETVAL = THIS->GetPointClipping();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetPointMaximum()
		CODE:
		RETVAL = THIS->GetPointMaximum();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetPointMaximumMaxValue()
		CODE:
		RETVAL = THIS->GetPointMaximumMaxValue();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetPointMaximumMinValue()
		CODE:
		RETVAL = THIS->GetPointMaximumMinValue();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetPointMinimum()
		CODE:
		RETVAL = THIS->GetPointMinimum();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetPointMinimumMaxValue()
		CODE:
		RETVAL = THIS->GetPointMinimumMaxValue();
		OUTPUT:
		RETVAL


long
vtkExtractUnstructuredGrid::GetPointMinimumMinValue()
		CODE:
		RETVAL = THIS->GetPointMinimumMinValue();
		OUTPUT:
		RETVAL


void
vtkExtractUnstructuredGrid::MergingOff()
		CODE:
		THIS->MergingOff();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::MergingOn()
		CODE:
		THIS->MergingOn();
		XSRETURN_EMPTY;


static vtkExtractUnstructuredGrid*
vtkExtractUnstructuredGrid::New()
		CODE:
		RETVAL = vtkExtractUnstructuredGrid::New();
		OUTPUT:
		RETVAL


void
vtkExtractUnstructuredGrid::PointClippingOff()
		CODE:
		THIS->PointClippingOff();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::PointClippingOn()
		CODE:
		THIS->PointClippingOn();
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetCellClipping(arg1)
		int 	arg1
		CODE:
		THIS->SetCellClipping(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetCellMaximum(arg1)
		long 	arg1
		CODE:
		THIS->SetCellMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetCellMinimum(arg1)
		long 	arg1
		CODE:
		THIS->SetCellMinimum(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractUnstructuredGrid::SetExtent\n");



void
vtkExtractUnstructuredGrid::SetExtentClipping(arg1)
		int 	arg1
		CODE:
		THIS->SetExtentClipping(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetMerging(arg1)
		int 	arg1
		CODE:
		THIS->SetMerging(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetPointClipping(arg1)
		int 	arg1
		CODE:
		THIS->SetPointClipping(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetPointMaximum(arg1)
		long 	arg1
		CODE:
		THIS->SetPointMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkExtractUnstructuredGrid::SetPointMinimum(arg1)
		long 	arg1
		CODE:
		THIS->SetPointMinimum(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ExtractVectorComponents PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkExtractVectorComponents::ExtractToFieldDataOff()
		CODE:
		THIS->ExtractToFieldDataOff();
		XSRETURN_EMPTY;


void
vtkExtractVectorComponents::ExtractToFieldDataOn()
		CODE:
		THIS->ExtractToFieldDataOn();
		XSRETURN_EMPTY;


const char *
vtkExtractVectorComponents::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkExtractVectorComponents::GetExtractToFieldData()
		CODE:
		RETVAL = THIS->GetExtractToFieldData();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkExtractVectorComponents::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkExtractVectorComponents::GetOutput(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetOutput(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkExtractVectorComponents::GetVxComponent()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetVxComponent();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkExtractVectorComponents::GetVyComponent()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetVyComponent();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkExtractVectorComponents::GetVzComponent()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetVzComponent();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkExtractVectorComponents*
vtkExtractVectorComponents::New()
		CODE:
		RETVAL = vtkExtractVectorComponents::New();
		OUTPUT:
		RETVAL


void
vtkExtractVectorComponents::SetExtractToFieldData(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractToFieldData(arg1);
		XSRETURN_EMPTY;


void
vtkExtractVectorComponents::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::FeatureEdges PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkFeatureEdges::BoundaryEdgesOff()
		CODE:
		THIS->BoundaryEdgesOff();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::BoundaryEdgesOn()
		CODE:
		THIS->BoundaryEdgesOn();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::ColoringOff()
		CODE:
		THIS->ColoringOff();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::ColoringOn()
		CODE:
		THIS->ColoringOn();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::FeatureEdgesOff()
		CODE:
		THIS->FeatureEdgesOff();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::FeatureEdgesOn()
		CODE:
		THIS->FeatureEdgesOn();
		XSRETURN_EMPTY;


int
vtkFeatureEdges::GetBoundaryEdges()
		CODE:
		RETVAL = THIS->GetBoundaryEdges();
		OUTPUT:
		RETVAL


const char *
vtkFeatureEdges::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkFeatureEdges::GetColoring()
		CODE:
		RETVAL = THIS->GetColoring();
		OUTPUT:
		RETVAL


float
vtkFeatureEdges::GetFeatureAngle()
		CODE:
		RETVAL = THIS->GetFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkFeatureEdges::GetFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkFeatureEdges::GetFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMinValue();
		OUTPUT:
		RETVAL


int
vtkFeatureEdges::GetFeatureEdges()
		CODE:
		RETVAL = THIS->GetFeatureEdges();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkFeatureEdges::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkFeatureEdges::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkFeatureEdges::GetManifoldEdges()
		CODE:
		RETVAL = THIS->GetManifoldEdges();
		OUTPUT:
		RETVAL


int
vtkFeatureEdges::GetNonManifoldEdges()
		CODE:
		RETVAL = THIS->GetNonManifoldEdges();
		OUTPUT:
		RETVAL


void
vtkFeatureEdges::ManifoldEdgesOff()
		CODE:
		THIS->ManifoldEdgesOff();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::ManifoldEdgesOn()
		CODE:
		THIS->ManifoldEdgesOn();
		XSRETURN_EMPTY;


static vtkFeatureEdges*
vtkFeatureEdges::New()
		CODE:
		RETVAL = vtkFeatureEdges::New();
		OUTPUT:
		RETVAL


void
vtkFeatureEdges::NonManifoldEdgesOff()
		CODE:
		THIS->NonManifoldEdgesOff();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::NonManifoldEdgesOn()
		CODE:
		THIS->NonManifoldEdgesOn();
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetBoundaryEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundaryEdges(arg1);
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetColoring(arg1)
		int 	arg1
		CODE:
		THIS->SetColoring(arg1);
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetFeatureEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetFeatureEdges(arg1);
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetManifoldEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetManifoldEdges(arg1);
		XSRETURN_EMPTY;


void
vtkFeatureEdges::SetNonManifoldEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetNonManifoldEdges(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::FieldDataToAttributeDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkFieldDataToAttributeDataFilter::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


static int
vtkFieldDataToAttributeDataFilter::ConstructArray(da, comp, frray, fieldComp, min, max, normalize)
		vtkDataArray *	da
		int 	comp
		vtkDataArray *	frray
		int 	fieldComp
		long 	min
		long 	max
		int 	normalize
		CODE:
		RETVAL = vtkFieldDataToAttributeDataFilter::ConstructArray(da, comp, frray, fieldComp, min, max, normalize);
		OUTPUT:
		RETVAL


void
vtkFieldDataToAttributeDataFilter::DefaultNormalizeOff()
		CODE:
		THIS->DefaultNormalizeOff();
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::DefaultNormalizeOn()
		CODE:
		THIS->DefaultNormalizeOn();
		XSRETURN_EMPTY;


const char *
vtkFieldDataToAttributeDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetDefaultNormalize()
		CODE:
		RETVAL = THIS->GetDefaultNormalize();
		OUTPUT:
		RETVAL


static vtkDataArray *
vtkFieldDataToAttributeDataFilter::GetFieldArray(fd, name, comp)
		vtkFieldData *	fd
		char *	name
		int 	comp
		CODE:
		RETVAL = vtkFieldDataToAttributeDataFilter::GetFieldArray(fd, name, comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetInputField()
		CODE:
		RETVAL = THIS->GetInputField();
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetNormalComponentArrayComponent(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetNormalComponentArrayComponent(comp);
		OUTPUT:
		RETVAL


const char *
vtkFieldDataToAttributeDataFilter::GetNormalComponentArrayName(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetNormalComponentArrayName(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetNormalComponentMaxRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetNormalComponentMaxRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetNormalComponentMinRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetNormalComponentMinRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetNormalComponentNormalizeFlag(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetNormalComponentNormalizeFlag(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetOutputAttributeData()
		CODE:
		RETVAL = THIS->GetOutputAttributeData();
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetScalarComponentArrayComponent(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetScalarComponentArrayComponent(comp);
		OUTPUT:
		RETVAL


const char *
vtkFieldDataToAttributeDataFilter::GetScalarComponentArrayName(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetScalarComponentArrayName(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetScalarComponentMaxRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetScalarComponentMaxRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetScalarComponentMinRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetScalarComponentMinRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetScalarComponentNormalizeFlag(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetScalarComponentNormalizeFlag(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTCoordComponentArrayComponent(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTCoordComponentArrayComponent(comp);
		OUTPUT:
		RETVAL


const char *
vtkFieldDataToAttributeDataFilter::GetTCoordComponentArrayName(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTCoordComponentArrayName(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTCoordComponentMaxRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTCoordComponentMaxRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTCoordComponentMinRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTCoordComponentMinRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTCoordComponentNormalizeFlag(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTCoordComponentNormalizeFlag(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTensorComponentArrayComponent(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTensorComponentArrayComponent(comp);
		OUTPUT:
		RETVAL


const char *
vtkFieldDataToAttributeDataFilter::GetTensorComponentArrayName(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTensorComponentArrayName(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTensorComponentMaxRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTensorComponentMaxRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTensorComponentMinRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTensorComponentMinRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetTensorComponentNormalizeFlag(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetTensorComponentNormalizeFlag(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetVectorComponentArrayComponent(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetVectorComponentArrayComponent(comp);
		OUTPUT:
		RETVAL


const char *
vtkFieldDataToAttributeDataFilter::GetVectorComponentArrayName(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetVectorComponentArrayName(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetVectorComponentMaxRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetVectorComponentMaxRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetVectorComponentMinRange(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetVectorComponentMinRange(comp);
		OUTPUT:
		RETVAL


int
vtkFieldDataToAttributeDataFilter::GetVectorComponentNormalizeFlag(comp)
		int 	comp
		CODE:
		RETVAL = THIS->GetVectorComponentNormalizeFlag(comp);
		OUTPUT:
		RETVAL


static vtkFieldDataToAttributeDataFilter*
vtkFieldDataToAttributeDataFilter::New()
		CODE:
		RETVAL = vtkFieldDataToAttributeDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkFieldDataToAttributeDataFilter::SetDefaultNormalize(arg1)
		int 	arg1
		CODE:
		THIS->SetDefaultNormalize(arg1);
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetInputField(arg1)
		int 	arg1
		CODE:
		THIS->SetInputField(arg1);
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetInputFieldToCellDataField()
		CODE:
		THIS->SetInputFieldToCellDataField();
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetInputFieldToDataObjectField()
		CODE:
		THIS->SetInputFieldToDataObjectField();
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetInputFieldToPointDataField()
		CODE:
		THIS->SetInputFieldToPointDataField();
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetNormalComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		const char *	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetNormalComponent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		const char *	arg2
		int 	arg3
		CODE:
		THIS->SetNormalComponent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldDataToAttributeDataFilter::SetNormalComponent\n");



void
vtkFieldDataToAttributeDataFilter::SetOutputAttributeData(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputAttributeData(arg1);
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetOutputAttributeDataToCellData()
		CODE:
		THIS->SetOutputAttributeDataToCellData();
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetOutputAttributeDataToPointData()
		CODE:
		THIS->SetOutputAttributeDataToPointData();
		XSRETURN_EMPTY;


void
vtkFieldDataToAttributeDataFilter::SetScalarComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		const char *	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetScalarComponent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		const char *	arg2
		int 	arg3
		CODE:
		THIS->SetScalarComponent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldDataToAttributeDataFilter::SetScalarComponent\n");



void
vtkFieldDataToAttributeDataFilter::SetTCoordComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		const char *	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetTCoordComponent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		const char *	arg2
		int 	arg3
		CODE:
		THIS->SetTCoordComponent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldDataToAttributeDataFilter::SetTCoordComponent\n");



void
vtkFieldDataToAttributeDataFilter::SetTensorComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		const char *	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetTensorComponent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		const char *	arg2
		int 	arg3
		CODE:
		THIS->SetTensorComponent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldDataToAttributeDataFilter::SetTensorComponent\n");



void
vtkFieldDataToAttributeDataFilter::SetVectorComponent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		const char *	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetVectorComponent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		const char *	arg2
		int 	arg3
		CODE:
		THIS->SetVectorComponent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldDataToAttributeDataFilter::SetVectorComponent\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::GeometryFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGeometryFilter::CellClippingOff()
		CODE:
		THIS->CellClippingOff();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::CellClippingOn()
		CODE:
		THIS->CellClippingOn();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::ExtentClippingOff()
		CODE:
		THIS->ExtentClippingOff();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::ExtentClippingOn()
		CODE:
		THIS->ExtentClippingOn();
		XSRETURN_EMPTY;


int
vtkGeometryFilter::GetCellClipping()
		CODE:
		RETVAL = THIS->GetCellClipping();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetCellMaximum()
		CODE:
		RETVAL = THIS->GetCellMaximum();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetCellMaximumMaxValue()
		CODE:
		RETVAL = THIS->GetCellMaximumMaxValue();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetCellMaximumMinValue()
		CODE:
		RETVAL = THIS->GetCellMaximumMinValue();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetCellMinimum()
		CODE:
		RETVAL = THIS->GetCellMinimum();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetCellMinimumMaxValue()
		CODE:
		RETVAL = THIS->GetCellMinimumMaxValue();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetCellMinimumMinValue()
		CODE:
		RETVAL = THIS->GetCellMinimumMinValue();
		OUTPUT:
		RETVAL


const char *
vtkGeometryFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkGeometryFilter::GetExtent()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int
vtkGeometryFilter::GetExtentClipping()
		CODE:
		RETVAL = THIS->GetExtentClipping();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkGeometryFilter::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkGeometryFilter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkGeometryFilter::GetMerging()
		CODE:
		RETVAL = THIS->GetMerging();
		OUTPUT:
		RETVAL


int
vtkGeometryFilter::GetPointClipping()
		CODE:
		RETVAL = THIS->GetPointClipping();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetPointMaximum()
		CODE:
		RETVAL = THIS->GetPointMaximum();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetPointMaximumMaxValue()
		CODE:
		RETVAL = THIS->GetPointMaximumMaxValue();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetPointMaximumMinValue()
		CODE:
		RETVAL = THIS->GetPointMaximumMinValue();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetPointMinimum()
		CODE:
		RETVAL = THIS->GetPointMinimum();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetPointMinimumMaxValue()
		CODE:
		RETVAL = THIS->GetPointMinimumMaxValue();
		OUTPUT:
		RETVAL


long
vtkGeometryFilter::GetPointMinimumMinValue()
		CODE:
		RETVAL = THIS->GetPointMinimumMinValue();
		OUTPUT:
		RETVAL


void
vtkGeometryFilter::MergingOff()
		CODE:
		THIS->MergingOff();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::MergingOn()
		CODE:
		THIS->MergingOn();
		XSRETURN_EMPTY;


static vtkGeometryFilter*
vtkGeometryFilter::New()
		CODE:
		RETVAL = vtkGeometryFilter::New();
		OUTPUT:
		RETVAL


void
vtkGeometryFilter::PointClippingOff()
		CODE:
		THIS->PointClippingOff();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::PointClippingOn()
		CODE:
		THIS->PointClippingOn();
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetCellClipping(arg1)
		int 	arg1
		CODE:
		THIS->SetCellClipping(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetCellMaximum(arg1)
		long 	arg1
		CODE:
		THIS->SetCellMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetCellMinimum(arg1)
		long 	arg1
		CODE:
		THIS->SetCellMinimum(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGeometryFilter::SetExtent\n");



void
vtkGeometryFilter::SetExtentClipping(arg1)
		int 	arg1
		CODE:
		THIS->SetExtentClipping(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetMerging(arg1)
		int 	arg1
		CODE:
		THIS->SetMerging(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetPointClipping(arg1)
		int 	arg1
		CODE:
		THIS->SetPointClipping(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetPointMaximum(arg1)
		long 	arg1
		CODE:
		THIS->SetPointMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkGeometryFilter::SetPointMinimum(arg1)
		long 	arg1
		CODE:
		THIS->SetPointMinimum(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Glyph2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkGlyph2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkGlyph2D*
vtkGlyph2D::New()
		CODE:
		RETVAL = vtkGlyph2D::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Glyph3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGlyph3D::ClampingOff()
		CODE:
		THIS->ClampingOff();
		XSRETURN_EMPTY;


void
vtkGlyph3D::ClampingOn()
		CODE:
		THIS->ClampingOn();
		XSRETURN_EMPTY;


void
vtkGlyph3D::GeneratePointIdsOff()
		CODE:
		THIS->GeneratePointIdsOff();
		XSRETURN_EMPTY;


void
vtkGlyph3D::GeneratePointIdsOn()
		CODE:
		THIS->GeneratePointIdsOn();
		XSRETURN_EMPTY;


int
vtkGlyph3D::GetClamping()
		CODE:
		RETVAL = THIS->GetClamping();
		OUTPUT:
		RETVAL


const char *
vtkGlyph3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetColorMode()
		CODE:
		RETVAL = THIS->GetColorMode();
		OUTPUT:
		RETVAL


const char *
vtkGlyph3D::GetColorModeAsString()
		CODE:
		RETVAL = THIS->GetColorModeAsString();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetGeneratePointIds()
		CODE:
		RETVAL = THIS->GetGeneratePointIds();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetIndexMode()
		CODE:
		RETVAL = THIS->GetIndexMode();
		OUTPUT:
		RETVAL


const char *
vtkGlyph3D::GetIndexModeAsString()
		CODE:
		RETVAL = THIS->GetIndexModeAsString();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetNumberOfSources()
		CODE:
		RETVAL = THIS->GetNumberOfSources();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetOrient()
		CODE:
		RETVAL = THIS->GetOrient();
		OUTPUT:
		RETVAL


char *
vtkGlyph3D::GetPointIdsName()
		CODE:
		RETVAL = THIS->GetPointIdsName();
		OUTPUT:
		RETVAL


float  *
vtkGlyph3D::GetRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float
vtkGlyph3D::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetScaleMode()
		CODE:
		RETVAL = THIS->GetScaleMode();
		OUTPUT:
		RETVAL


const char *
vtkGlyph3D::GetScaleModeAsString()
		CODE:
		RETVAL = THIS->GetScaleModeAsString();
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetScaling()
		CODE:
		RETVAL = THIS->GetScaling();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkGlyph3D::GetSource(id)
		int 	id
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetSource(id);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkGlyph3D::GetVectorMode()
		CODE:
		RETVAL = THIS->GetVectorMode();
		OUTPUT:
		RETVAL


const char *
vtkGlyph3D::GetVectorModeAsString()
		CODE:
		RETVAL = THIS->GetVectorModeAsString();
		OUTPUT:
		RETVAL


static vtkGlyph3D*
vtkGlyph3D::New()
		CODE:
		RETVAL = vtkGlyph3D::New();
		OUTPUT:
		RETVAL


void
vtkGlyph3D::OrientOff()
		CODE:
		THIS->OrientOff();
		XSRETURN_EMPTY;


void
vtkGlyph3D::OrientOn()
		CODE:
		THIS->OrientOn();
		XSRETURN_EMPTY;


void
vtkGlyph3D::ScalingOff()
		CODE:
		THIS->ScalingOff();
		XSRETURN_EMPTY;


void
vtkGlyph3D::ScalingOn()
		CODE:
		THIS->ScalingOn();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetClamping(arg1)
		int 	arg1
		CODE:
		THIS->SetClamping(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetColorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetColorMode(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetColorModeToColorByScalar()
		CODE:
		THIS->SetColorModeToColorByScalar();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetColorModeToColorByScale()
		CODE:
		THIS->SetColorModeToColorByScale();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetColorModeToColorByVector()
		CODE:
		THIS->SetColorModeToColorByVector();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetGeneratePointIds(arg1)
		int 	arg1
		CODE:
		THIS->SetGeneratePointIds(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetIndexMode(arg1)
		int 	arg1
		CODE:
		THIS->SetIndexMode(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetIndexModeToOff()
		CODE:
		THIS->SetIndexModeToOff();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetIndexModeToScalar()
		CODE:
		THIS->SetIndexModeToScalar();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetIndexModeToVector()
		CODE:
		THIS->SetIndexModeToVector();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetNumberOfSources(num)
		int 	num
		CODE:
		THIS->SetNumberOfSources(num);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetOrient(arg1)
		int 	arg1
		CODE:
		THIS->SetOrient(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetPointIdsName(arg1)
		char *	arg1
		CODE:
		THIS->SetPointIdsName(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGlyph3D::SetRange\n");



void
vtkGlyph3D::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetScaleMode(arg1)
		int 	arg1
		CODE:
		THIS->SetScaleMode(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetScaleModeToDataScalingOff()
		CODE:
		THIS->SetScaleModeToDataScalingOff();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetScaleModeToScaleByScalar()
		CODE:
		THIS->SetScaleModeToScaleByScalar();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetScaleModeToScaleByVector()
		CODE:
		THIS->SetScaleModeToScaleByVector();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetScaleModeToScaleByVectorComponents()
		CODE:
		THIS->SetScaleModeToScaleByVectorComponents();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetScaling(arg1)
		int 	arg1
		CODE:
		THIS->SetScaling(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetSource(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		vtkPolyData *	arg2
		CODE:
		THIS->SetSource(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		vtkPolyData *	arg1
		CODE:
		THIS->SetSource(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGlyph3D::SetSource\n");



void
vtkGlyph3D::SetVectorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetVectorMode(arg1);
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetVectorModeToUseNormal()
		CODE:
		THIS->SetVectorModeToUseNormal();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetVectorModeToUseVector()
		CODE:
		THIS->SetVectorModeToUseVector();
		XSRETURN_EMPTY;


void
vtkGlyph3D::SetVectorModeToVectorRotationOff()
		CODE:
		THIS->SetVectorModeToVectorRotationOff();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::GlyphSource2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGlyphSource2D::CrossOff()
		CODE:
		THIS->CrossOff();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::CrossOn()
		CODE:
		THIS->CrossOn();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::DashOff()
		CODE:
		THIS->DashOff();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::DashOn()
		CODE:
		THIS->DashOn();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::FilledOff()
		CODE:
		THIS->FilledOff();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::FilledOn()
		CODE:
		THIS->FilledOn();
		XSRETURN_EMPTY;


float  *
vtkGlyphSource2D::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkGlyphSource2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkGlyphSource2D::GetColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkGlyphSource2D::GetCross()
		CODE:
		RETVAL = THIS->GetCross();
		OUTPUT:
		RETVAL


int
vtkGlyphSource2D::GetDash()
		CODE:
		RETVAL = THIS->GetDash();
		OUTPUT:
		RETVAL


int
vtkGlyphSource2D::GetFilled()
		CODE:
		RETVAL = THIS->GetFilled();
		OUTPUT:
		RETVAL


int
vtkGlyphSource2D::GetGlyphType()
		CODE:
		RETVAL = THIS->GetGlyphType();
		OUTPUT:
		RETVAL


int
vtkGlyphSource2D::GetGlyphTypeMaxValue()
		CODE:
		RETVAL = THIS->GetGlyphTypeMaxValue();
		OUTPUT:
		RETVAL


int
vtkGlyphSource2D::GetGlyphTypeMinValue()
		CODE:
		RETVAL = THIS->GetGlyphTypeMinValue();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetRotationAngle()
		CODE:
		RETVAL = THIS->GetRotationAngle();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetScale()
		CODE:
		RETVAL = THIS->GetScale();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetScale2()
		CODE:
		RETVAL = THIS->GetScale2();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetScale2MaxValue()
		CODE:
		RETVAL = THIS->GetScale2MaxValue();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetScale2MinValue()
		CODE:
		RETVAL = THIS->GetScale2MinValue();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetScaleMaxValue()
		CODE:
		RETVAL = THIS->GetScaleMaxValue();
		OUTPUT:
		RETVAL


float
vtkGlyphSource2D::GetScaleMinValue()
		CODE:
		RETVAL = THIS->GetScaleMinValue();
		OUTPUT:
		RETVAL


static vtkGlyphSource2D*
vtkGlyphSource2D::New()
		CODE:
		RETVAL = vtkGlyphSource2D::New();
		OUTPUT:
		RETVAL


void
vtkGlyphSource2D::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGlyphSource2D::SetCenter\n");



void
vtkGlyphSource2D::SetColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGlyphSource2D::SetColor\n");



void
vtkGlyphSource2D::SetCross(arg1)
		int 	arg1
		CODE:
		THIS->SetCross(arg1);
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetDash(arg1)
		int 	arg1
		CODE:
		THIS->SetDash(arg1);
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetFilled(arg1)
		int 	arg1
		CODE:
		THIS->SetFilled(arg1);
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphType(arg1)
		int 	arg1
		CODE:
		THIS->SetGlyphType(arg1);
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToArrow()
		CODE:
		THIS->SetGlyphTypeToArrow();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToCircle()
		CODE:
		THIS->SetGlyphTypeToCircle();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToCross()
		CODE:
		THIS->SetGlyphTypeToCross();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToDash()
		CODE:
		THIS->SetGlyphTypeToDash();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToDiamond()
		CODE:
		THIS->SetGlyphTypeToDiamond();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToHookedArrow()
		CODE:
		THIS->SetGlyphTypeToHookedArrow();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToNone()
		CODE:
		THIS->SetGlyphTypeToNone();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToSquare()
		CODE:
		THIS->SetGlyphTypeToSquare();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToThickArrow()
		CODE:
		THIS->SetGlyphTypeToThickArrow();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToThickCross()
		CODE:
		THIS->SetGlyphTypeToThickCross();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToTriangle()
		CODE:
		THIS->SetGlyphTypeToTriangle();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetGlyphTypeToVertex()
		CODE:
		THIS->SetGlyphTypeToVertex();
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetRotationAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetRotationAngle(arg1);
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetScale(arg1)
		float 	arg1
		CODE:
		THIS->SetScale(arg1);
		XSRETURN_EMPTY;


void
vtkGlyphSource2D::SetScale2(arg1)
		float 	arg1
		CODE:
		THIS->SetScale2(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::GraphLayoutFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGraphLayoutFilter::AutomaticBoundsComputationOff()
		CODE:
		THIS->AutomaticBoundsComputationOff();
		XSRETURN_EMPTY;


void
vtkGraphLayoutFilter::AutomaticBoundsComputationOn()
		CODE:
		THIS->AutomaticBoundsComputationOn();
		XSRETURN_EMPTY;


int
vtkGraphLayoutFilter::GetAutomaticBoundsComputation()
		CODE:
		RETVAL = THIS->GetAutomaticBoundsComputation();
		OUTPUT:
		RETVAL


const char *
vtkGraphLayoutFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkGraphLayoutFilter::GetCoolDownRate()
		CODE:
		RETVAL = THIS->GetCoolDownRate();
		OUTPUT:
		RETVAL


float
vtkGraphLayoutFilter::GetCoolDownRateMaxValue()
		CODE:
		RETVAL = THIS->GetCoolDownRateMaxValue();
		OUTPUT:
		RETVAL


float
vtkGraphLayoutFilter::GetCoolDownRateMinValue()
		CODE:
		RETVAL = THIS->GetCoolDownRateMinValue();
		OUTPUT:
		RETVAL


float  *
vtkGraphLayoutFilter::GetGraphBounds()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetGraphBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int
vtkGraphLayoutFilter::GetMaxNumberOfIterations()
		CODE:
		RETVAL = THIS->GetMaxNumberOfIterations();
		OUTPUT:
		RETVAL


int
vtkGraphLayoutFilter::GetMaxNumberOfIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetMaxNumberOfIterationsMaxValue();
		OUTPUT:
		RETVAL


int
vtkGraphLayoutFilter::GetMaxNumberOfIterationsMinValue()
		CODE:
		RETVAL = THIS->GetMaxNumberOfIterationsMinValue();
		OUTPUT:
		RETVAL


int
vtkGraphLayoutFilter::GetThreeDimensionalLayout()
		CODE:
		RETVAL = THIS->GetThreeDimensionalLayout();
		OUTPUT:
		RETVAL


static vtkGraphLayoutFilter*
vtkGraphLayoutFilter::New()
		CODE:
		RETVAL = vtkGraphLayoutFilter::New();
		OUTPUT:
		RETVAL


void
vtkGraphLayoutFilter::SetAutomaticBoundsComputation(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticBoundsComputation(arg1);
		XSRETURN_EMPTY;


void
vtkGraphLayoutFilter::SetCoolDownRate(arg1)
		float 	arg1
		CODE:
		THIS->SetCoolDownRate(arg1);
		XSRETURN_EMPTY;


void
vtkGraphLayoutFilter::SetGraphBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetGraphBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGraphLayoutFilter::SetGraphBounds\n");



void
vtkGraphLayoutFilter::SetMaxNumberOfIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetMaxNumberOfIterations(arg1);
		XSRETURN_EMPTY;


void
vtkGraphLayoutFilter::SetThreeDimensionalLayout(arg1)
		int 	arg1
		CODE:
		THIS->SetThreeDimensionalLayout(arg1);
		XSRETURN_EMPTY;


void
vtkGraphLayoutFilter::ThreeDimensionalLayoutOff()
		CODE:
		THIS->ThreeDimensionalLayoutOff();
		XSRETURN_EMPTY;


void
vtkGraphLayoutFilter::ThreeDimensionalLayoutOn()
		CODE:
		THIS->ThreeDimensionalLayoutOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::HedgeHog PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkHedgeHog::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkHedgeHog::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


int
vtkHedgeHog::GetVectorMode()
		CODE:
		RETVAL = THIS->GetVectorMode();
		OUTPUT:
		RETVAL


const char *
vtkHedgeHog::GetVectorModeAsString()
		CODE:
		RETVAL = THIS->GetVectorModeAsString();
		OUTPUT:
		RETVAL


static vtkHedgeHog*
vtkHedgeHog::New()
		CODE:
		RETVAL = vtkHedgeHog::New();
		OUTPUT:
		RETVAL


void
vtkHedgeHog::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkHedgeHog::SetVectorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetVectorMode(arg1);
		XSRETURN_EMPTY;


void
vtkHedgeHog::SetVectorModeToUseNormal()
		CODE:
		THIS->SetVectorModeToUseNormal();
		XSRETURN_EMPTY;


void
vtkHedgeHog::SetVectorModeToUseVector()
		CODE:
		THIS->SetVectorModeToUseVector();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Hull PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkHull::AddCubeEdgePlanes()
		CODE:
		THIS->AddCubeEdgePlanes();
		XSRETURN_EMPTY;


void
vtkHull::AddCubeFacePlanes()
		CODE:
		THIS->AddCubeFacePlanes();
		XSRETURN_EMPTY;


void
vtkHull::AddCubeVertexPlanes()
		CODE:
		THIS->AddCubeVertexPlanes();
		XSRETURN_EMPTY;


int
vtkHull::AddPlane(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		RETVAL = THIS->AddPlane(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->AddPlane(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkHull::AddPlane\n");



void
vtkHull::AddRecursiveSpherePlanes(level)
		int 	level
		CODE:
		THIS->AddRecursiveSpherePlanes(level);
		XSRETURN_EMPTY;


void
vtkHull::GenerateHull(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0, arg7 = 0)
	CASE: items == 8
		vtkPolyData *	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		float 	arg7
		CODE:
		THIS->GenerateHull(arg1, arg2, arg3, arg4, arg5, arg6, arg7);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkHull::GenerateHull\n");



const char *
vtkHull::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkHull::GetNumberOfPlanes()
		CODE:
		RETVAL = THIS->GetNumberOfPlanes();
		OUTPUT:
		RETVAL


static vtkHull*
vtkHull::New()
		CODE:
		RETVAL = vtkHull::New();
		OUTPUT:
		RETVAL


void
vtkHull::RemoveAllPlanes()
		CODE:
		THIS->RemoveAllPlanes();
		XSRETURN_EMPTY;


void
vtkHull::SetPlane(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		CODE:
		THIS->SetPlane(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE: items == 5
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetPlane(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkHull::SetPlane\n");



void
vtkHull::SetPlanes(planes)
		vtkPlanes *	planes
		CODE:
		THIS->SetPlanes(planes);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::HyperStreamline PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkHyperStreamline::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetIntegrationDirection()
		CODE:
		RETVAL = THIS->GetIntegrationDirection();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetIntegrationDirectionMaxValue()
		CODE:
		RETVAL = THIS->GetIntegrationDirectionMaxValue();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetIntegrationDirectionMinValue()
		CODE:
		RETVAL = THIS->GetIntegrationDirectionMinValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetIntegrationStepLength()
		CODE:
		RETVAL = THIS->GetIntegrationStepLength();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetIntegrationStepLengthMaxValue()
		CODE:
		RETVAL = THIS->GetIntegrationStepLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetIntegrationStepLengthMinValue()
		CODE:
		RETVAL = THIS->GetIntegrationStepLengthMinValue();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetLogScaling()
		CODE:
		RETVAL = THIS->GetLogScaling();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetMaximumPropagationDistance()
		CODE:
		RETVAL = THIS->GetMaximumPropagationDistance();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetMaximumPropagationDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumPropagationDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetMaximumPropagationDistanceMinValue()
		CODE:
		RETVAL = THIS->GetMaximumPropagationDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetNumberOfSides()
		CODE:
		RETVAL = THIS->GetNumberOfSides();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetNumberOfSidesMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfSidesMaxValue();
		OUTPUT:
		RETVAL


int
vtkHyperStreamline::GetNumberOfSidesMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfSidesMinValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


float *
vtkHyperStreamline::GetStartPosition()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetStartPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkHyperStreamline::GetStepLength()
		CODE:
		RETVAL = THIS->GetStepLength();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetStepLengthMaxValue()
		CODE:
		RETVAL = THIS->GetStepLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetStepLengthMinValue()
		CODE:
		RETVAL = THIS->GetStepLengthMinValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetTerminalEigenvalue()
		CODE:
		RETVAL = THIS->GetTerminalEigenvalue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetTerminalEigenvalueMaxValue()
		CODE:
		RETVAL = THIS->GetTerminalEigenvalueMaxValue();
		OUTPUT:
		RETVAL


float
vtkHyperStreamline::GetTerminalEigenvalueMinValue()
		CODE:
		RETVAL = THIS->GetTerminalEigenvalueMinValue();
		OUTPUT:
		RETVAL


void
vtkHyperStreamline::IntegrateMajorEigenvector()
		CODE:
		THIS->IntegrateMajorEigenvector();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::IntegrateMediumEigenvector()
		CODE:
		THIS->IntegrateMediumEigenvector();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::IntegrateMinorEigenvector()
		CODE:
		THIS->IntegrateMinorEigenvector();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::LogScalingOff()
		CODE:
		THIS->LogScalingOff();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::LogScalingOn()
		CODE:
		THIS->LogScalingOn();
		XSRETURN_EMPTY;


static vtkHyperStreamline*
vtkHyperStreamline::New()
		CODE:
		RETVAL = vtkHyperStreamline::New();
		OUTPUT:
		RETVAL


void
vtkHyperStreamline::SetIntegrationDirection(arg1)
		int 	arg1
		CODE:
		THIS->SetIntegrationDirection(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetIntegrationDirectionToBackward()
		CODE:
		THIS->SetIntegrationDirectionToBackward();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetIntegrationDirectionToForward()
		CODE:
		THIS->SetIntegrationDirectionToForward();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetIntegrationDirectionToIntegrateBothDirections()
		CODE:
		THIS->SetIntegrationDirectionToIntegrateBothDirections();
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetIntegrationStepLength(arg1)
		float 	arg1
		CODE:
		THIS->SetIntegrationStepLength(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetLogScaling(arg1)
		int 	arg1
		CODE:
		THIS->SetLogScaling(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetMaximumPropagationDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumPropagationDistance(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetNumberOfSides(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfSides(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetStartLocation(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		long 	arg1
		int 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		CODE:
		THIS->SetStartLocation(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkHyperStreamline::SetStartLocation\n");



void
vtkHyperStreamline::SetStartPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetStartPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkHyperStreamline::SetStartPosition\n");



void
vtkHyperStreamline::SetStepLength(arg1)
		float 	arg1
		CODE:
		THIS->SetStepLength(arg1);
		XSRETURN_EMPTY;


void
vtkHyperStreamline::SetTerminalEigenvalue(arg1)
		float 	arg1
		CODE:
		THIS->SetTerminalEigenvalue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::IdFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkIdFilter::CellIdsOff()
		CODE:
		THIS->CellIdsOff();
		XSRETURN_EMPTY;


void
vtkIdFilter::CellIdsOn()
		CODE:
		THIS->CellIdsOn();
		XSRETURN_EMPTY;


void
vtkIdFilter::FieldDataOff()
		CODE:
		THIS->FieldDataOff();
		XSRETURN_EMPTY;


void
vtkIdFilter::FieldDataOn()
		CODE:
		THIS->FieldDataOn();
		XSRETURN_EMPTY;


int
vtkIdFilter::GetCellIds()
		CODE:
		RETVAL = THIS->GetCellIds();
		OUTPUT:
		RETVAL


const char *
vtkIdFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkIdFilter::GetFieldData()
		CODE:
		RETVAL = THIS->GetFieldData();
		OUTPUT:
		RETVAL


char *
vtkIdFilter::GetIdsArrayName()
		CODE:
		RETVAL = THIS->GetIdsArrayName();
		OUTPUT:
		RETVAL


int
vtkIdFilter::GetPointIds()
		CODE:
		RETVAL = THIS->GetPointIds();
		OUTPUT:
		RETVAL


static vtkIdFilter*
vtkIdFilter::New()
		CODE:
		RETVAL = vtkIdFilter::New();
		OUTPUT:
		RETVAL


void
vtkIdFilter::PointIdsOff()
		CODE:
		THIS->PointIdsOff();
		XSRETURN_EMPTY;


void
vtkIdFilter::PointIdsOn()
		CODE:
		THIS->PointIdsOn();
		XSRETURN_EMPTY;


void
vtkIdFilter::SetCellIds(arg1)
		int 	arg1
		CODE:
		THIS->SetCellIds(arg1);
		XSRETURN_EMPTY;


void
vtkIdFilter::SetFieldData(arg1)
		int 	arg1
		CODE:
		THIS->SetFieldData(arg1);
		XSRETURN_EMPTY;


void
vtkIdFilter::SetIdsArrayName(arg1)
		char *	arg1
		CODE:
		THIS->SetIdsArrayName(arg1);
		XSRETURN_EMPTY;


void
vtkIdFilter::SetPointIds(arg1)
		int 	arg1
		CODE:
		THIS->SetPointIds(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ImageDataGeometryFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageDataGeometryFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageDataGeometryFilter*
vtkImageDataGeometryFilter::New()
		CODE:
		RETVAL = vtkImageDataGeometryFilter::New();
		OUTPUT:
		RETVAL


void
vtkImageDataGeometryFilter::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageDataGeometryFilter::SetExtent\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ImplicitTextureCoords PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImplicitTextureCoords::FlipTextureOff()
		CODE:
		THIS->FlipTextureOff();
		XSRETURN_EMPTY;


void
vtkImplicitTextureCoords::FlipTextureOn()
		CODE:
		THIS->FlipTextureOn();
		XSRETURN_EMPTY;


const char *
vtkImplicitTextureCoords::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImplicitTextureCoords::GetFlipTexture()
		CODE:
		RETVAL = THIS->GetFlipTexture();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkImplicitTextureCoords::GetRFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetRFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkImplicitTextureCoords::GetSFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetSFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkImplicitTextureCoords::GetTFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetTFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImplicitTextureCoords*
vtkImplicitTextureCoords::New()
		CODE:
		RETVAL = vtkImplicitTextureCoords::New();
		OUTPUT:
		RETVAL


void
vtkImplicitTextureCoords::SetFlipTexture(arg1)
		int 	arg1
		CODE:
		THIS->SetFlipTexture(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitTextureCoords::SetRFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetRFunction(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitTextureCoords::SetSFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetSFunction(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitTextureCoords::SetTFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetTFunction(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::InterpolateDataSetAttributes PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkInterpolateDataSetAttributes::AddInput(arg1 = 0)
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->AddInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkInterpolateDataSetAttributes::AddInput\n");



const char *
vtkInterpolateDataSetAttributes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSetCollection *
vtkInterpolateDataSetAttributes::GetInputList()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSetCollection";
		CODE:
		RETVAL = THIS->GetInputList();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkInterpolateDataSetAttributes::GetT()
		CODE:
		RETVAL = THIS->GetT();
		OUTPUT:
		RETVAL


float
vtkInterpolateDataSetAttributes::GetTMaxValue()
		CODE:
		RETVAL = THIS->GetTMaxValue();
		OUTPUT:
		RETVAL


float
vtkInterpolateDataSetAttributes::GetTMinValue()
		CODE:
		RETVAL = THIS->GetTMinValue();
		OUTPUT:
		RETVAL


static vtkInterpolateDataSetAttributes*
vtkInterpolateDataSetAttributes::New()
		CODE:
		RETVAL = vtkInterpolateDataSetAttributes::New();
		OUTPUT:
		RETVAL


void
vtkInterpolateDataSetAttributes::SetT(arg1)
		float 	arg1
		CODE:
		THIS->SetT(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::InterpolatingSubdivisionFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInterpolatingSubdivisionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkInterpolatingSubdivisionFilter::GetNumberOfSubdivisions()
		CODE:
		RETVAL = THIS->GetNumberOfSubdivisions();
		OUTPUT:
		RETVAL


void
vtkInterpolatingSubdivisionFilter::SetNumberOfSubdivisions(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfSubdivisions(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::LineSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLineSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkLineSource::GetPoint1()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint1();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkLineSource::GetPoint2()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint2();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkLineSource::GetResolution()
		CODE:
		RETVAL = THIS->GetResolution();
		OUTPUT:
		RETVAL


int
vtkLineSource::GetResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkLineSource::GetResolutionMinValue()
		CODE:
		RETVAL = THIS->GetResolutionMinValue();
		OUTPUT:
		RETVAL


static vtkLineSource*
vtkLineSource::New()
		CODE:
		RETVAL = vtkLineSource::New();
		OUTPUT:
		RETVAL


void
vtkLineSource::SetPoint1(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint1(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLineSource::SetPoint1\n");



void
vtkLineSource::SetPoint2(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint2(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLineSource::SetPoint2\n");



void
vtkLineSource::SetResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::LinearExtrusionFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLinearExtrusionFilter::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


int
vtkLinearExtrusionFilter::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkLinearExtrusionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkLinearExtrusionFilter::GetExtrusionPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtrusionPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkLinearExtrusionFilter::GetExtrusionType()
		CODE:
		RETVAL = THIS->GetExtrusionType();
		OUTPUT:
		RETVAL


int
vtkLinearExtrusionFilter::GetExtrusionTypeMaxValue()
		CODE:
		RETVAL = THIS->GetExtrusionTypeMaxValue();
		OUTPUT:
		RETVAL


int
vtkLinearExtrusionFilter::GetExtrusionTypeMinValue()
		CODE:
		RETVAL = THIS->GetExtrusionTypeMinValue();
		OUTPUT:
		RETVAL


float
vtkLinearExtrusionFilter::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


float  *
vtkLinearExtrusionFilter::GetVector()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVector();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkLinearExtrusionFilter*
vtkLinearExtrusionFilter::New()
		CODE:
		RETVAL = vtkLinearExtrusionFilter::New();
		OUTPUT:
		RETVAL


void
vtkLinearExtrusionFilter::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::SetExtrusionPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetExtrusionPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearExtrusionFilter::SetExtrusionPoint\n");



void
vtkLinearExtrusionFilter::SetExtrusionType(arg1)
		int 	arg1
		CODE:
		THIS->SetExtrusionType(arg1);
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::SetExtrusionTypeToNormalExtrusion()
		CODE:
		THIS->SetExtrusionTypeToNormalExtrusion();
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::SetExtrusionTypeToPointExtrusion()
		CODE:
		THIS->SetExtrusionTypeToPointExtrusion();
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::SetExtrusionTypeToVectorExtrusion()
		CODE:
		THIS->SetExtrusionTypeToVectorExtrusion();
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkLinearExtrusionFilter::SetVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetVector(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearExtrusionFilter::SetVector\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::LinearSubdivisionFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLinearSubdivisionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkLinearSubdivisionFilter*
vtkLinearSubdivisionFilter::New()
		CODE:
		RETVAL = vtkLinearSubdivisionFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::LinkEdgels PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLinkEdgels::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkLinkEdgels::GetGradientThreshold()
		CODE:
		RETVAL = THIS->GetGradientThreshold();
		OUTPUT:
		RETVAL


float
vtkLinkEdgels::GetLinkThreshold()
		CODE:
		RETVAL = THIS->GetLinkThreshold();
		OUTPUT:
		RETVAL


float
vtkLinkEdgels::GetPhiThreshold()
		CODE:
		RETVAL = THIS->GetPhiThreshold();
		OUTPUT:
		RETVAL


static vtkLinkEdgels*
vtkLinkEdgels::New()
		CODE:
		RETVAL = vtkLinkEdgels::New();
		OUTPUT:
		RETVAL


void
vtkLinkEdgels::SetGradientThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetGradientThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkLinkEdgels::SetLinkThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetLinkThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkLinkEdgels::SetPhiThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetPhiThreshold(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::LoopSubdivisionFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLoopSubdivisionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkLoopSubdivisionFilter*
vtkLoopSubdivisionFilter::New()
		CODE:
		RETVAL = vtkLoopSubdivisionFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::MaskPoints PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMaskPoints::GenerateVerticesOff()
		CODE:
		THIS->GenerateVerticesOff();
		XSRETURN_EMPTY;


void
vtkMaskPoints::GenerateVerticesOn()
		CODE:
		THIS->GenerateVerticesOn();
		XSRETURN_EMPTY;


const char *
vtkMaskPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMaskPoints::GetGenerateVertices()
		CODE:
		RETVAL = THIS->GetGenerateVertices();
		OUTPUT:
		RETVAL


long
vtkMaskPoints::GetMaximumNumberOfPoints()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfPoints();
		OUTPUT:
		RETVAL


long
vtkMaskPoints::GetMaximumNumberOfPointsMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfPointsMaxValue();
		OUTPUT:
		RETVAL


long
vtkMaskPoints::GetMaximumNumberOfPointsMinValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfPointsMinValue();
		OUTPUT:
		RETVAL


long
vtkMaskPoints::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


long
vtkMaskPoints::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


long
vtkMaskPoints::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


int
vtkMaskPoints::GetOnRatio()
		CODE:
		RETVAL = THIS->GetOnRatio();
		OUTPUT:
		RETVAL


int
vtkMaskPoints::GetOnRatioMaxValue()
		CODE:
		RETVAL = THIS->GetOnRatioMaxValue();
		OUTPUT:
		RETVAL


int
vtkMaskPoints::GetOnRatioMinValue()
		CODE:
		RETVAL = THIS->GetOnRatioMinValue();
		OUTPUT:
		RETVAL


int
vtkMaskPoints::GetRandomMode()
		CODE:
		RETVAL = THIS->GetRandomMode();
		OUTPUT:
		RETVAL


static vtkMaskPoints*
vtkMaskPoints::New()
		CODE:
		RETVAL = vtkMaskPoints::New();
		OUTPUT:
		RETVAL


void
vtkMaskPoints::RandomModeOff()
		CODE:
		THIS->RandomModeOff();
		XSRETURN_EMPTY;


void
vtkMaskPoints::RandomModeOn()
		CODE:
		THIS->RandomModeOn();
		XSRETURN_EMPTY;


void
vtkMaskPoints::SetGenerateVertices(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateVertices(arg1);
		XSRETURN_EMPTY;


void
vtkMaskPoints::SetMaximumNumberOfPoints(arg1)
		long 	arg1
		CODE:
		THIS->SetMaximumNumberOfPoints(arg1);
		XSRETURN_EMPTY;


void
vtkMaskPoints::SetOffset(arg1)
		long 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkMaskPoints::SetOnRatio(arg1)
		int 	arg1
		CODE:
		THIS->SetOnRatio(arg1);
		XSRETURN_EMPTY;


void
vtkMaskPoints::SetRandomMode(arg1)
		int 	arg1
		CODE:
		THIS->SetRandomMode(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::MaskPolyData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMaskPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


long
vtkMaskPolyData::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


long
vtkMaskPolyData::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


long
vtkMaskPolyData::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


int
vtkMaskPolyData::GetOnRatio()
		CODE:
		RETVAL = THIS->GetOnRatio();
		OUTPUT:
		RETVAL


int
vtkMaskPolyData::GetOnRatioMaxValue()
		CODE:
		RETVAL = THIS->GetOnRatioMaxValue();
		OUTPUT:
		RETVAL


int
vtkMaskPolyData::GetOnRatioMinValue()
		CODE:
		RETVAL = THIS->GetOnRatioMinValue();
		OUTPUT:
		RETVAL


static vtkMaskPolyData*
vtkMaskPolyData::New()
		CODE:
		RETVAL = vtkMaskPolyData::New();
		OUTPUT:
		RETVAL


void
vtkMaskPolyData::SetOffset(arg1)
		long 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkMaskPolyData::SetOnRatio(arg1)
		int 	arg1
		CODE:
		THIS->SetOnRatio(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::MassProperties PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMassProperties::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkMassProperties::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetKx()
		CODE:
		RETVAL = THIS->GetKx();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetKy()
		CODE:
		RETVAL = THIS->GetKy();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetKz()
		CODE:
		RETVAL = THIS->GetKz();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetNormalizedShapeIndex()
		CODE:
		RETVAL = THIS->GetNormalizedShapeIndex();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetSurfaceArea()
		CODE:
		RETVAL = THIS->GetSurfaceArea();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetVolume()
		CODE:
		RETVAL = THIS->GetVolume();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetVolumeX()
		CODE:
		RETVAL = THIS->GetVolumeX();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetVolumeY()
		CODE:
		RETVAL = THIS->GetVolumeY();
		OUTPUT:
		RETVAL


double
vtkMassProperties::GetVolumeZ()
		CODE:
		RETVAL = THIS->GetVolumeZ();
		OUTPUT:
		RETVAL


static vtkMassProperties*
vtkMassProperties::New()
		CODE:
		RETVAL = vtkMassProperties::New();
		OUTPUT:
		RETVAL


void
vtkMassProperties::SetInput(input)
		vtkPolyData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkMassProperties::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::MergeDataObjectFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMergeDataObjectFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkMergeDataObjectFilter::GetDataObject()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetDataObject();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkMergeDataObjectFilter::GetOutputField()
		CODE:
		RETVAL = THIS->GetOutputField();
		OUTPUT:
		RETVAL


static vtkMergeDataObjectFilter*
vtkMergeDataObjectFilter::New()
		CODE:
		RETVAL = vtkMergeDataObjectFilter::New();
		OUTPUT:
		RETVAL


void
vtkMergeDataObjectFilter::SetDataObject(object)
		vtkDataObject *	object
		CODE:
		THIS->SetDataObject(object);
		XSRETURN_EMPTY;


void
vtkMergeDataObjectFilter::SetOutputField(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputField(arg1);
		XSRETURN_EMPTY;


void
vtkMergeDataObjectFilter::SetOutputFieldToCellDataField()
		CODE:
		THIS->SetOutputFieldToCellDataField();
		XSRETURN_EMPTY;


void
vtkMergeDataObjectFilter::SetOutputFieldToDataObjectField()
		CODE:
		THIS->SetOutputFieldToDataObjectField();
		XSRETURN_EMPTY;


void
vtkMergeDataObjectFilter::SetOutputFieldToPointDataField()
		CODE:
		THIS->SetOutputFieldToPointDataField();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::MergeFields PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMergeFields::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkMergeFields::Merge(component, arrayName, sourceComp)
		int 	component
		const char *	arrayName
		int 	sourceComp
		CODE:
		THIS->Merge(component, arrayName, sourceComp);
		XSRETURN_EMPTY;


static vtkMergeFields*
vtkMergeFields::New()
		CODE:
		RETVAL = vtkMergeFields::New();
		OUTPUT:
		RETVAL


void
vtkMergeFields::SetNumberOfComponents(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfComponents(arg1);
		XSRETURN_EMPTY;


void
vtkMergeFields::SetOutputField(arg1 = 0, arg2 = 0)
	CASE: items == 3 && SvPOK(ST(2))
		const char *	arg1
		const char *	arg2
		CODE:
		THIS->SetOutputField(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && SvIOK(ST(2))
		const char *	arg1
		int 	arg2
		CODE:
		THIS->SetOutputField(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMergeFields::SetOutputField\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::MergeFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMergeFilter::AddField(name, input)
		const char *	name
		vtkDataSet *	input
		CODE:
		THIS->AddField(name, input);
		XSRETURN_EMPTY;


const char *
vtkMergeFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMergeFilter::GetGeometry()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetGeometry();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMergeFilter::GetNormals()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetNormals();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMergeFilter::GetScalars()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetScalars();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMergeFilter::GetTCoords()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetTCoords();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMergeFilter::GetTensors()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetTensors();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMergeFilter::GetVectors()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetVectors();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkMergeFilter*
vtkMergeFilter::New()
		CODE:
		RETVAL = vtkMergeFilter::New();
		OUTPUT:
		RETVAL


void
vtkMergeFilter::SetGeometry(input)
		vtkDataSet *	input
		CODE:
		THIS->SetGeometry(input);
		XSRETURN_EMPTY;


void
vtkMergeFilter::SetNormals(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetNormals(arg1);
		XSRETURN_EMPTY;


void
vtkMergeFilter::SetScalars(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetScalars(arg1);
		XSRETURN_EMPTY;


void
vtkMergeFilter::SetTCoords(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetTCoords(arg1);
		XSRETURN_EMPTY;


void
vtkMergeFilter::SetTensors(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetTensors(arg1);
		XSRETURN_EMPTY;


void
vtkMergeFilter::SetVectors(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetVectors(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::OBBDicer PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOBBDicer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOBBDicer*
vtkOBBDicer::New()
		CODE:
		RETVAL = vtkOBBDicer::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::OBBTree PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOBBTree::BuildLocator()
		CODE:
		THIS->BuildLocator();
		XSRETURN_EMPTY;


void
vtkOBBTree::FreeSearchStructure()
		CODE:
		THIS->FreeSearchStructure();
		XSRETURN_EMPTY;


void
vtkOBBTree::GenerateRepresentation(level, pd)
		int 	level
		vtkPolyData *	pd
		CODE:
		THIS->GenerateRepresentation(level, pd);
		XSRETURN_EMPTY;


const char *
vtkOBBTree::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL



static vtkOBBTree*
vtkOBBTree::New()
		CODE:
		RETVAL = vtkOBBTree::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::OutlineCornerFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOutlineCornerFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkOutlineCornerFilter::GetCornerFactor()
		CODE:
		RETVAL = THIS->GetCornerFactor();
		OUTPUT:
		RETVAL


float
vtkOutlineCornerFilter::GetCornerFactorMaxValue()
		CODE:
		RETVAL = THIS->GetCornerFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkOutlineCornerFilter::GetCornerFactorMinValue()
		CODE:
		RETVAL = THIS->GetCornerFactorMinValue();
		OUTPUT:
		RETVAL


static vtkOutlineCornerFilter*
vtkOutlineCornerFilter::New()
		CODE:
		RETVAL = vtkOutlineCornerFilter::New();
		OUTPUT:
		RETVAL


void
vtkOutlineCornerFilter::SetCornerFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetCornerFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::OutlineCornerSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOutlineCornerSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkOutlineCornerSource::GetCornerFactor()
		CODE:
		RETVAL = THIS->GetCornerFactor();
		OUTPUT:
		RETVAL


float
vtkOutlineCornerSource::GetCornerFactorMaxValue()
		CODE:
		RETVAL = THIS->GetCornerFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkOutlineCornerSource::GetCornerFactorMinValue()
		CODE:
		RETVAL = THIS->GetCornerFactorMinValue();
		OUTPUT:
		RETVAL


static vtkOutlineCornerSource*
vtkOutlineCornerSource::New()
		CODE:
		RETVAL = vtkOutlineCornerSource::New();
		OUTPUT:
		RETVAL


void
vtkOutlineCornerSource::SetCornerFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetCornerFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::OutlineFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOutlineFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOutlineFilter*
vtkOutlineFilter::New()
		CODE:
		RETVAL = vtkOutlineFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::OutlineSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkOutlineSource::GetBounds()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


const char *
vtkOutlineSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOutlineSource*
vtkOutlineSource::New()
		CODE:
		RETVAL = vtkOutlineSource::New();
		OUTPUT:
		RETVAL


void
vtkOutlineSource::SetBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkOutlineSource::SetBounds\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::PlaneSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkPlaneSource::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkPlaneSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkPlaneSource::GetNormal()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkPlaneSource::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkPlaneSource::GetPoint1()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint1();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkPlaneSource::GetPoint2()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint2();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


void
vtkPlaneSource::GetResolution(xR, yR)
		int 	xR
		int 	yR
		CODE:
		THIS->GetResolution(xR, yR);
		XSRETURN_EMPTY;
		OUTPUT:
		xR
		yR


int
vtkPlaneSource::GetXResolution()
		CODE:
		RETVAL = THIS->GetXResolution();
		OUTPUT:
		RETVAL


int
vtkPlaneSource::GetYResolution()
		CODE:
		RETVAL = THIS->GetYResolution();
		OUTPUT:
		RETVAL


static vtkPlaneSource*
vtkPlaneSource::New()
		CODE:
		RETVAL = vtkPlaneSource::New();
		OUTPUT:
		RETVAL


void
vtkPlaneSource::Push(distance)
		float 	distance
		CODE:
		THIS->Push(distance);
		XSRETURN_EMPTY;


void
vtkPlaneSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlaneSource::SetCenter\n");



void
vtkPlaneSource::SetNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlaneSource::SetNormal\n");



void
vtkPlaneSource::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlaneSource::SetOrigin\n");



void
vtkPlaneSource::SetPoint1(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint1(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlaneSource::SetPoint1\n");



void
vtkPlaneSource::SetPoint2(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint2(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlaneSource::SetPoint2\n");



void
vtkPlaneSource::SetResolution(xR, yR)
		const int 	xR
		const int 	yR
		CODE:
		THIS->SetResolution(xR, yR);
		XSRETURN_EMPTY;


void
vtkPlaneSource::SetXResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetXResolution(arg1);
		XSRETURN_EMPTY;


void
vtkPlaneSource::SetYResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetYResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::PointDataToCellData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPointDataToCellData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPointDataToCellData::GetPassPointData()
		CODE:
		RETVAL = THIS->GetPassPointData();
		OUTPUT:
		RETVAL


static vtkPointDataToCellData*
vtkPointDataToCellData::New()
		CODE:
		RETVAL = vtkPointDataToCellData::New();
		OUTPUT:
		RETVAL


void
vtkPointDataToCellData::PassPointDataOff()
		CODE:
		THIS->PassPointDataOff();
		XSRETURN_EMPTY;


void
vtkPointDataToCellData::PassPointDataOn()
		CODE:
		THIS->PassPointDataOn();
		XSRETURN_EMPTY;


void
vtkPointDataToCellData::SetPassPointData(arg1)
		int 	arg1
		CODE:
		THIS->SetPassPointData(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::PointSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkPointSource::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkPointSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPointSource::GetDistribution()
		CODE:
		RETVAL = THIS->GetDistribution();
		OUTPUT:
		RETVAL


long
vtkPointSource::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


long
vtkPointSource::GetNumberOfPointsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsMaxValue();
		OUTPUT:
		RETVAL


long
vtkPointSource::GetNumberOfPointsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsMinValue();
		OUTPUT:
		RETVAL


float
vtkPointSource::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkPointSource::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkPointSource::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


static vtkPointSource*
vtkPointSource::New()
		CODE:
		RETVAL = vtkPointSource::New();
		OUTPUT:
		RETVAL


void
vtkPointSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointSource::SetCenter\n");



void
vtkPointSource::SetDistribution(arg1)
		int 	arg1
		CODE:
		THIS->SetDistribution(arg1);
		XSRETURN_EMPTY;


void
vtkPointSource::SetDistributionToShell()
		CODE:
		THIS->SetDistributionToShell();
		XSRETURN_EMPTY;


void
vtkPointSource::SetDistributionToUniform()
		CODE:
		THIS->SetDistributionToUniform();
		XSRETURN_EMPTY;


void
vtkPointSource::SetNumberOfPoints(arg1)
		long 	arg1
		CODE:
		THIS->SetNumberOfPoints(arg1);
		XSRETURN_EMPTY;


void
vtkPointSource::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::PolyDataConnectivityFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyDataConnectivityFilter::AddSeed(id)
		int 	id
		CODE:
		THIS->AddSeed(id);
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::AddSpecifiedRegion(id)
		int 	id
		CODE:
		THIS->AddSpecifiedRegion(id);
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::ColorRegionsOff()
		CODE:
		THIS->ColorRegionsOff();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::ColorRegionsOn()
		CODE:
		THIS->ColorRegionsOn();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::DeleteSeed(id)
		int 	id
		CODE:
		THIS->DeleteSeed(id);
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::DeleteSpecifiedRegion(id)
		int 	id
		CODE:
		THIS->DeleteSpecifiedRegion(id);
		XSRETURN_EMPTY;


const char *
vtkPolyDataConnectivityFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkPolyDataConnectivityFilter::GetClosestPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetClosestPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkPolyDataConnectivityFilter::GetColorRegions()
		CODE:
		RETVAL = THIS->GetColorRegions();
		OUTPUT:
		RETVAL


int
vtkPolyDataConnectivityFilter::GetExtractionMode()
		CODE:
		RETVAL = THIS->GetExtractionMode();
		OUTPUT:
		RETVAL


const char *
vtkPolyDataConnectivityFilter::GetExtractionModeAsString()
		CODE:
		RETVAL = THIS->GetExtractionModeAsString();
		OUTPUT:
		RETVAL


int
vtkPolyDataConnectivityFilter::GetExtractionModeMaxValue()
		CODE:
		RETVAL = THIS->GetExtractionModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkPolyDataConnectivityFilter::GetExtractionModeMinValue()
		CODE:
		RETVAL = THIS->GetExtractionModeMinValue();
		OUTPUT:
		RETVAL


int
vtkPolyDataConnectivityFilter::GetNumberOfExtractedRegions()
		CODE:
		RETVAL = THIS->GetNumberOfExtractedRegions();
		OUTPUT:
		RETVAL


int
vtkPolyDataConnectivityFilter::GetScalarConnectivity()
		CODE:
		RETVAL = THIS->GetScalarConnectivity();
		OUTPUT:
		RETVAL


float  *
vtkPolyDataConnectivityFilter::GetScalarRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


void
vtkPolyDataConnectivityFilter::InitializeSeedList()
		CODE:
		THIS->InitializeSeedList();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::InitializeSpecifiedRegionList()
		CODE:
		THIS->InitializeSpecifiedRegionList();
		XSRETURN_EMPTY;


static vtkPolyDataConnectivityFilter*
vtkPolyDataConnectivityFilter::New()
		CODE:
		RETVAL = vtkPolyDataConnectivityFilter::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataConnectivityFilter::ScalarConnectivityOff()
		CODE:
		THIS->ScalarConnectivityOff();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::ScalarConnectivityOn()
		CODE:
		THIS->ScalarConnectivityOn();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetClosestPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetClosestPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyDataConnectivityFilter::SetClosestPoint\n");



void
vtkPolyDataConnectivityFilter::SetColorRegions(arg1)
		int 	arg1
		CODE:
		THIS->SetColorRegions(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionMode(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractionMode(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionModeToAllRegions()
		CODE:
		THIS->SetExtractionModeToAllRegions();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionModeToCellSeededRegions()
		CODE:
		THIS->SetExtractionModeToCellSeededRegions();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionModeToClosestPointRegion()
		CODE:
		THIS->SetExtractionModeToClosestPointRegion();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionModeToLargestRegion()
		CODE:
		THIS->SetExtractionModeToLargestRegion();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionModeToPointSeededRegions()
		CODE:
		THIS->SetExtractionModeToPointSeededRegions();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetExtractionModeToSpecifiedRegions()
		CODE:
		THIS->SetExtractionModeToSpecifiedRegions();
		XSRETURN_EMPTY;


void
vtkPolyDataConnectivityFilter::SetScalarConnectivity(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarConnectivity(arg1);
		XSRETURN_EMPTY;


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::PolyDataNormals PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyDataNormals::ComputeCellNormalsOff()
		CODE:
		THIS->ComputeCellNormalsOff();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::ComputeCellNormalsOn()
		CODE:
		THIS->ComputeCellNormalsOn();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::ComputePointNormalsOff()
		CODE:
		THIS->ComputePointNormalsOff();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::ComputePointNormalsOn()
		CODE:
		THIS->ComputePointNormalsOn();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::ConsistencyOff()
		CODE:
		THIS->ConsistencyOff();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::ConsistencyOn()
		CODE:
		THIS->ConsistencyOn();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::FlipNormalsOff()
		CODE:
		THIS->FlipNormalsOff();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::FlipNormalsOn()
		CODE:
		THIS->FlipNormalsOn();
		XSRETURN_EMPTY;


const char *
vtkPolyDataNormals::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetComputeCellNormals()
		CODE:
		RETVAL = THIS->GetComputeCellNormals();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetComputePointNormals()
		CODE:
		RETVAL = THIS->GetComputePointNormals();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetConsistency()
		CODE:
		RETVAL = THIS->GetConsistency();
		OUTPUT:
		RETVAL


float
vtkPolyDataNormals::GetFeatureAngle()
		CODE:
		RETVAL = THIS->GetFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkPolyDataNormals::GetFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkPolyDataNormals::GetFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMinValue();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetFlipNormals()
		CODE:
		RETVAL = THIS->GetFlipNormals();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetMaxRecursionDepth()
		CODE:
		RETVAL = THIS->GetMaxRecursionDepth();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetNonManifoldTraversal()
		CODE:
		RETVAL = THIS->GetNonManifoldTraversal();
		OUTPUT:
		RETVAL


int
vtkPolyDataNormals::GetSplitting()
		CODE:
		RETVAL = THIS->GetSplitting();
		OUTPUT:
		RETVAL


static vtkPolyDataNormals*
vtkPolyDataNormals::New()
		CODE:
		RETVAL = vtkPolyDataNormals::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataNormals::NonManifoldTraversalOff()
		CODE:
		THIS->NonManifoldTraversalOff();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::NonManifoldTraversalOn()
		CODE:
		THIS->NonManifoldTraversalOn();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetComputeCellNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeCellNormals(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetComputePointNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputePointNormals(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetConsistency(arg1)
		int 	arg1
		CODE:
		THIS->SetConsistency(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetFlipNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetFlipNormals(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetNonManifoldTraversal(arg1)
		int 	arg1
		CODE:
		THIS->SetNonManifoldTraversal(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SetSplitting(arg1)
		int 	arg1
		CODE:
		THIS->SetSplitting(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SplittingOff()
		CODE:
		THIS->SplittingOff();
		XSRETURN_EMPTY;


void
vtkPolyDataNormals::SplittingOn()
		CODE:
		THIS->SplittingOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::PolyDataStreamer PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyDataStreamer::ColorByPieceOff()
		CODE:
		THIS->ColorByPieceOff();
		XSRETURN_EMPTY;


void
vtkPolyDataStreamer::ColorByPieceOn()
		CODE:
		THIS->ColorByPieceOn();
		XSRETURN_EMPTY;


const char *
vtkPolyDataStreamer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPolyDataStreamer::GetColorByPiece()
		CODE:
		RETVAL = THIS->GetColorByPiece();
		OUTPUT:
		RETVAL


int
vtkPolyDataStreamer::GetNumberOfStreamDivisions()
		CODE:
		RETVAL = THIS->GetNumberOfStreamDivisions();
		OUTPUT:
		RETVAL


static vtkPolyDataStreamer*
vtkPolyDataStreamer::New()
		CODE:
		RETVAL = vtkPolyDataStreamer::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataStreamer::SetColorByPiece(arg1)
		int 	arg1
		CODE:
		THIS->SetColorByPiece(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataStreamer::SetNumberOfStreamDivisions(num)
		int 	num
		CODE:
		THIS->SetNumberOfStreamDivisions(num);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProbeFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkProbeFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkProbeFilter::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkProbeFilter::GetSpatialMatch()
		CODE:
		RETVAL = THIS->GetSpatialMatch();
		OUTPUT:
		RETVAL


vtkIdTypeArray *
vtkProbeFilter::GetValidPoints()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkIdTypeArray";
		CODE:
		RETVAL = THIS->GetValidPoints();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkProbeFilter*
vtkProbeFilter::New()
		CODE:
		RETVAL = vtkProbeFilter::New();
		OUTPUT:
		RETVAL


void
vtkProbeFilter::SetSource(source)
		vtkDataSet *	source
		CODE:
		THIS->SetSource(source);
		XSRETURN_EMPTY;


void
vtkProbeFilter::SetSpatialMatch(arg1)
		int 	arg1
		CODE:
		THIS->SetSpatialMatch(arg1);
		XSRETURN_EMPTY;


void
vtkProbeFilter::SpatialMatchOff()
		CODE:
		THIS->SpatialMatchOff();
		XSRETURN_EMPTY;


void
vtkProbeFilter::SpatialMatchOn()
		CODE:
		THIS->SpatialMatchOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProgrammableAttributeDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProgrammableAttributeDataFilter::AddInput(arg1 = 0)
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->AddInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProgrammableAttributeDataFilter::AddInput\n");



const char *
vtkProgrammableAttributeDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSetCollection *
vtkProgrammableAttributeDataFilter::GetInputList()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSetCollection";
		CODE:
		RETVAL = THIS->GetInputList();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkProgrammableAttributeDataFilter*
vtkProgrammableAttributeDataFilter::New()
		CODE:
		RETVAL = vtkProgrammableAttributeDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkProgrammableAttributeDataFilter::RemoveInput(arg1 = 0)
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->RemoveInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProgrammableAttributeDataFilter::RemoveInput\n");



void
vtkProgrammableAttributeDataFilter::SetExecuteMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetExecuteMethod",0), newRV(func), 0);
		}
		THIS->SetExecuteMethod(callperlsub, func);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProgrammableDataObjectSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkProgrammableDataObjectSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkProgrammableDataObjectSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProgrammableDataObjectSource::GetOutput\n");



static vtkProgrammableDataObjectSource*
vtkProgrammableDataObjectSource::New()
		CODE:
		RETVAL = vtkProgrammableDataObjectSource::New();
		OUTPUT:
		RETVAL


void
vtkProgrammableDataObjectSource::SetExecuteMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetExecuteMethod",0), newRV(func), 0);
		}
		THIS->SetExecuteMethod(callperlsub, func);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProgrammableFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkProgrammableFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkProgrammableFilter::GetPolyDataInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetPolyDataInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkProgrammableFilter::GetRectilinearGridInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetRectilinearGridInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkProgrammableFilter::GetStructuredGridInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetStructuredGridInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkProgrammableFilter::GetStructuredPointsInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetStructuredPointsInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkProgrammableFilter::GetUnstructuredGridInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetUnstructuredGridInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkProgrammableFilter*
vtkProgrammableFilter::New()
		CODE:
		RETVAL = vtkProgrammableFilter::New();
		OUTPUT:
		RETVAL


void
vtkProgrammableFilter::SetExecuteMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetExecuteMethod",0), newRV(func), 0);
		}
		THIS->SetExecuteMethod(callperlsub, func);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProgrammableGlyphFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkProgrammableGlyphFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkProgrammableGlyphFilter::GetColorMode()
		CODE:
		RETVAL = THIS->GetColorMode();
		OUTPUT:
		RETVAL


const char *
vtkProgrammableGlyphFilter::GetColorModeAsString()
		CODE:
		RETVAL = THIS->GetColorModeAsString();
		OUTPUT:
		RETVAL


float  *
vtkProgrammableGlyphFilter::GetPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkPointData *
vtkProgrammableGlyphFilter::GetPointData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointData";
		CODE:
		RETVAL = THIS->GetPointData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


long
vtkProgrammableGlyphFilter::GetPointId()
		CODE:
		RETVAL = THIS->GetPointId();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkProgrammableGlyphFilter::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkProgrammableGlyphFilter*
vtkProgrammableGlyphFilter::New()
		CODE:
		RETVAL = vtkProgrammableGlyphFilter::New();
		OUTPUT:
		RETVAL


void
vtkProgrammableGlyphFilter::SetColorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetColorMode(arg1);
		XSRETURN_EMPTY;


void
vtkProgrammableGlyphFilter::SetColorModeToColorByInput()
		CODE:
		THIS->SetColorModeToColorByInput();
		XSRETURN_EMPTY;


void
vtkProgrammableGlyphFilter::SetColorModeToColorBySource()
		CODE:
		THIS->SetColorModeToColorBySource();
		XSRETURN_EMPTY;


void
vtkProgrammableGlyphFilter::SetGlyphMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetGlyphMethod",0), newRV(func), 0);
		}
		THIS->SetGlyphMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkProgrammableGlyphFilter::SetSource(source)
		vtkPolyData *	source
		CODE:
		THIS->SetSource(source);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProgrammableSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkProgrammableSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkProgrammableSource::GetPolyDataOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetPolyDataOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkProgrammableSource::GetRectilinearGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetRectilinearGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkProgrammableSource::GetStructuredGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetStructuredGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkProgrammableSource::GetStructuredPointsOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetStructuredPointsOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkProgrammableSource::GetUnstructuredGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetUnstructuredGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkProgrammableSource*
vtkProgrammableSource::New()
		CODE:
		RETVAL = vtkProgrammableSource::New();
		OUTPUT:
		RETVAL


void
vtkProgrammableSource::SetExecuteMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetExecuteMethod",0), newRV(func), 0);
		}
		THIS->SetExecuteMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkProgrammableSource::UpdateData(output)
		vtkDataObject *	output
		CODE:
		THIS->UpdateData(output);
		XSRETURN_EMPTY;


void
vtkProgrammableSource::UpdateInformation()
		CODE:
		THIS->UpdateInformation();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ProjectedTexture PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkProjectedTexture::GetAspectRatio()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAspectRatio();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkProjectedTexture::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkProjectedTexture::GetFocalPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFocalPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkProjectedTexture::GetOrientation()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkProjectedTexture::GetPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkProjectedTexture::GetSRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkProjectedTexture::GetTRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkProjectedTexture::GetUp()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetUp();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkProjectedTexture*
vtkProjectedTexture::New()
		CODE:
		RETVAL = vtkProjectedTexture::New();
		OUTPUT:
		RETVAL


void
vtkProjectedTexture::SetAspectRatio(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetAspectRatio(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProjectedTexture::SetAspectRatio\n");



void
vtkProjectedTexture::SetFocalPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetFocalPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProjectedTexture::SetFocalPoint\n");



void
vtkProjectedTexture::SetPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProjectedTexture::SetPosition\n");



void
vtkProjectedTexture::SetSRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetSRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProjectedTexture::SetSRange\n");



void
vtkProjectedTexture::SetTRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetTRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProjectedTexture::SetTRange\n");



void
vtkProjectedTexture::SetUp(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetUp(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProjectedTexture::SetUp\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::QuadricClustering PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkQuadricClustering::Append(piece)
		vtkPolyData *	piece
		CODE:
		THIS->Append(piece);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::CopyCellDataOff()
		CODE:
		THIS->CopyCellDataOff();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::CopyCellDataOn()
		CODE:
		THIS->CopyCellDataOn();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::EndAppend()
		CODE:
		THIS->EndAppend();
		XSRETURN_EMPTY;


const char *
vtkQuadricClustering::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetCopyCellData()
		CODE:
		RETVAL = THIS->GetCopyCellData();
		OUTPUT:
		RETVAL


float  *
vtkQuadricClustering::GetDivisionOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDivisionOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkQuadricClustering::GetDivisionSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDivisionSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkFeatureEdges *
vtkQuadricClustering::GetFeatureEdges()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkFeatureEdges";
		CODE:
		RETVAL = THIS->GetFeatureEdges();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkQuadricClustering::GetFeaturePointsAngle()
		CODE:
		RETVAL = THIS->GetFeaturePointsAngle();
		OUTPUT:
		RETVAL


float
vtkQuadricClustering::GetFeaturePointsAngleMaxValue()
		CODE:
		RETVAL = THIS->GetFeaturePointsAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkQuadricClustering::GetFeaturePointsAngleMinValue()
		CODE:
		RETVAL = THIS->GetFeaturePointsAngleMinValue();
		OUTPUT:
		RETVAL


int *
vtkQuadricClustering::GetNumberOfDivisions()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNumberOfDivisions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkQuadricClustering::GetNumberOfDivisions\n");



int
vtkQuadricClustering::GetNumberOfXDivisions()
		CODE:
		RETVAL = THIS->GetNumberOfXDivisions();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetNumberOfYDivisions()
		CODE:
		RETVAL = THIS->GetNumberOfYDivisions();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetNumberOfZDivisions()
		CODE:
		RETVAL = THIS->GetNumberOfZDivisions();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetUseFeatureEdges()
		CODE:
		RETVAL = THIS->GetUseFeatureEdges();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetUseFeaturePoints()
		CODE:
		RETVAL = THIS->GetUseFeaturePoints();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetUseInputPoints()
		CODE:
		RETVAL = THIS->GetUseInputPoints();
		OUTPUT:
		RETVAL


int
vtkQuadricClustering::GetUseInternalTriangles()
		CODE:
		RETVAL = THIS->GetUseInternalTriangles();
		OUTPUT:
		RETVAL


static vtkQuadricClustering*
vtkQuadricClustering::New()
		CODE:
		RETVAL = vtkQuadricClustering::New();
		OUTPUT:
		RETVAL


void
vtkQuadricClustering::SetCopyCellData(arg1)
		int 	arg1
		CODE:
		THIS->SetCopyCellData(arg1);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetDivisionOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDivisionOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkQuadricClustering::SetDivisionOrigin\n");



void
vtkQuadricClustering::SetDivisionSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDivisionSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkQuadricClustering::SetDivisionSpacing\n");



void
vtkQuadricClustering::SetFeaturePointsAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetFeaturePointsAngle(arg1);
		XSRETURN_EMPTY;



void
vtkQuadricClustering::SetNumberOfXDivisions(num)
		int 	num
		CODE:
		THIS->SetNumberOfXDivisions(num);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetNumberOfYDivisions(num)
		int 	num
		CODE:
		THIS->SetNumberOfYDivisions(num);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetNumberOfZDivisions(num)
		int 	num
		CODE:
		THIS->SetNumberOfZDivisions(num);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetUseFeatureEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetUseFeatureEdges(arg1);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetUseFeaturePoints(arg1)
		int 	arg1
		CODE:
		THIS->SetUseFeaturePoints(arg1);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetUseInputPoints(arg1)
		int 	arg1
		CODE:
		THIS->SetUseInputPoints(arg1);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::SetUseInternalTriangles(arg1)
		int 	arg1
		CODE:
		THIS->SetUseInternalTriangles(arg1);
		XSRETURN_EMPTY;


void
vtkQuadricClustering::StartAppend(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->StartAppend(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkQuadricClustering::StartAppend\n");



void
vtkQuadricClustering::UseFeatureEdgesOff()
		CODE:
		THIS->UseFeatureEdgesOff();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseFeatureEdgesOn()
		CODE:
		THIS->UseFeatureEdgesOn();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseFeaturePointsOff()
		CODE:
		THIS->UseFeaturePointsOff();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseFeaturePointsOn()
		CODE:
		THIS->UseFeaturePointsOn();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseInputPointsOff()
		CODE:
		THIS->UseInputPointsOff();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseInputPointsOn()
		CODE:
		THIS->UseInputPointsOn();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseInternalTrianglesOff()
		CODE:
		THIS->UseInternalTrianglesOff();
		XSRETURN_EMPTY;


void
vtkQuadricClustering::UseInternalTrianglesOn()
		CODE:
		THIS->UseInternalTrianglesOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::QuadricDecimation PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkQuadricDecimation::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkQuadricDecimation::GetMaximumCollapsedEdges()
		CODE:
		RETVAL = THIS->GetMaximumCollapsedEdges();
		OUTPUT:
		RETVAL


float
vtkQuadricDecimation::GetMaximumCost()
		CODE:
		RETVAL = THIS->GetMaximumCost();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkQuadricDecimation::GetTestOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetTestOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkQuadricDecimation*
vtkQuadricDecimation::New()
		CODE:
		RETVAL = vtkQuadricDecimation::New();
		OUTPUT:
		RETVAL


void
vtkQuadricDecimation::SetMaximumCollapsedEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumCollapsedEdges(arg1);
		XSRETURN_EMPTY;


void
vtkQuadricDecimation::SetMaximumCost(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumCost(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::QuantizePolyDataPoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkQuantizePolyDataPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkQuantizePolyDataPoints::GetQFactor()
		CODE:
		RETVAL = THIS->GetQFactor();
		OUTPUT:
		RETVAL


float
vtkQuantizePolyDataPoints::GetQFactorMaxValue()
		CODE:
		RETVAL = THIS->GetQFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkQuantizePolyDataPoints::GetQFactorMinValue()
		CODE:
		RETVAL = THIS->GetQFactorMinValue();
		OUTPUT:
		RETVAL


static vtkQuantizePolyDataPoints*
vtkQuantizePolyDataPoints::New()
		CODE:
		RETVAL = vtkQuantizePolyDataPoints::New();
		OUTPUT:
		RETVAL


void
vtkQuantizePolyDataPoints::SetQFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetQFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::RearrangeFields PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkRearrangeFields::AddOperation(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5 && SvPOK(ST(1))
		const char *	arg1
		const char *	arg2
		const char *	arg3
		const char *	arg4
		CODE:
		RETVAL = THIS->AddOperation(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 5 && SvIOK(ST(2))
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		RETVAL = THIS->AddOperation(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRearrangeFields::AddOperation\n");



const char *
vtkRearrangeFields::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkRearrangeFields*
vtkRearrangeFields::New()
		CODE:
		RETVAL = vtkRearrangeFields::New();
		OUTPUT:
		RETVAL


void
vtkRearrangeFields::RemoveAllOperations()
		CODE:
		THIS->RemoveAllOperations();
		XSRETURN_EMPTY;


int
vtkRearrangeFields::RemoveOperation(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5 && SvPOK(ST(1))
		const char *	arg1
		const char *	arg2
		const char *	arg3
		const char *	arg4
		CODE:
		RETVAL = THIS->RemoveOperation(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 5 && SvIOK(ST(2))
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		RETVAL = THIS->RemoveOperation(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->RemoveOperation(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRearrangeFields::RemoveOperation\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::RectilinearGridGeometryFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRectilinearGridGeometryFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkRectilinearGridGeometryFilter::GetExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


static vtkRectilinearGridGeometryFilter*
vtkRectilinearGridGeometryFilter::New()
		CODE:
		RETVAL = vtkRectilinearGridGeometryFilter::New();
		OUTPUT:
		RETVAL


void
vtkRectilinearGridGeometryFilter::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGridGeometryFilter::SetExtent\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::RecursiveDividingCubes PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRecursiveDividingCubes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkRecursiveDividingCubes::GetDistance()
		CODE:
		RETVAL = THIS->GetDistance();
		OUTPUT:
		RETVAL


float
vtkRecursiveDividingCubes::GetDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkRecursiveDividingCubes::GetDistanceMinValue()
		CODE:
		RETVAL = THIS->GetDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkRecursiveDividingCubes::GetIncrement()
		CODE:
		RETVAL = THIS->GetIncrement();
		OUTPUT:
		RETVAL


int
vtkRecursiveDividingCubes::GetIncrementMaxValue()
		CODE:
		RETVAL = THIS->GetIncrementMaxValue();
		OUTPUT:
		RETVAL


int
vtkRecursiveDividingCubes::GetIncrementMinValue()
		CODE:
		RETVAL = THIS->GetIncrementMinValue();
		OUTPUT:
		RETVAL


float
vtkRecursiveDividingCubes::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


static vtkRecursiveDividingCubes*
vtkRecursiveDividingCubes::New()
		CODE:
		RETVAL = vtkRecursiveDividingCubes::New();
		OUTPUT:
		RETVAL


void
vtkRecursiveDividingCubes::SetDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetDistance(arg1);
		XSRETURN_EMPTY;


void
vtkRecursiveDividingCubes::SetIncrement(arg1)
		int 	arg1
		CODE:
		THIS->SetIncrement(arg1);
		XSRETURN_EMPTY;


void
vtkRecursiveDividingCubes::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ReverseSense PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkReverseSense::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkReverseSense::GetReverseCells()
		CODE:
		RETVAL = THIS->GetReverseCells();
		OUTPUT:
		RETVAL


int
vtkReverseSense::GetReverseNormals()
		CODE:
		RETVAL = THIS->GetReverseNormals();
		OUTPUT:
		RETVAL


static vtkReverseSense*
vtkReverseSense::New()
		CODE:
		RETVAL = vtkReverseSense::New();
		OUTPUT:
		RETVAL


void
vtkReverseSense::ReverseCellsOff()
		CODE:
		THIS->ReverseCellsOff();
		XSRETURN_EMPTY;


void
vtkReverseSense::ReverseCellsOn()
		CODE:
		THIS->ReverseCellsOn();
		XSRETURN_EMPTY;


void
vtkReverseSense::ReverseNormalsOff()
		CODE:
		THIS->ReverseNormalsOff();
		XSRETURN_EMPTY;


void
vtkReverseSense::ReverseNormalsOn()
		CODE:
		THIS->ReverseNormalsOn();
		XSRETURN_EMPTY;


void
vtkReverseSense::SetReverseCells(arg1)
		int 	arg1
		CODE:
		THIS->SetReverseCells(arg1);
		XSRETURN_EMPTY;


void
vtkReverseSense::SetReverseNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetReverseNormals(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::RibbonFilter PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkRibbonFilter::GetAngle()
		CODE:
		RETVAL = THIS->GetAngle();
		OUTPUT:
		RETVAL


float
vtkRibbonFilter::GetAngleMaxValue()
		CODE:
		RETVAL = THIS->GetAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkRibbonFilter::GetAngleMinValue()
		CODE:
		RETVAL = THIS->GetAngleMinValue();
		OUTPUT:
		RETVAL


const char *
vtkRibbonFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkRibbonFilter::GetDefaultNormal()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDefaultNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkRibbonFilter::GetUseDefaultNormal()
		CODE:
		RETVAL = THIS->GetUseDefaultNormal();
		OUTPUT:
		RETVAL


int
vtkRibbonFilter::GetVaryWidth()
		CODE:
		RETVAL = THIS->GetVaryWidth();
		OUTPUT:
		RETVAL


float
vtkRibbonFilter::GetWidth()
		CODE:
		RETVAL = THIS->GetWidth();
		OUTPUT:
		RETVAL


float
vtkRibbonFilter::GetWidthFactor()
		CODE:
		RETVAL = THIS->GetWidthFactor();
		OUTPUT:
		RETVAL


float
vtkRibbonFilter::GetWidthMaxValue()
		CODE:
		RETVAL = THIS->GetWidthMaxValue();
		OUTPUT:
		RETVAL


float
vtkRibbonFilter::GetWidthMinValue()
		CODE:
		RETVAL = THIS->GetWidthMinValue();
		OUTPUT:
		RETVAL


static vtkRibbonFilter*
vtkRibbonFilter::New()
		CODE:
		RETVAL = vtkRibbonFilter::New();
		OUTPUT:
		RETVAL


void
vtkRibbonFilter::SetAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetAngle(arg1);
		XSRETURN_EMPTY;


void
vtkRibbonFilter::SetDefaultNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDefaultNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRibbonFilter::SetDefaultNormal\n");



void
vtkRibbonFilter::SetUseDefaultNormal(arg1)
		int 	arg1
		CODE:
		THIS->SetUseDefaultNormal(arg1);
		XSRETURN_EMPTY;


void
vtkRibbonFilter::SetVaryWidth(arg1)
		int 	arg1
		CODE:
		THIS->SetVaryWidth(arg1);
		XSRETURN_EMPTY;


void
vtkRibbonFilter::SetWidth(arg1)
		float 	arg1
		CODE:
		THIS->SetWidth(arg1);
		XSRETURN_EMPTY;


void
vtkRibbonFilter::SetWidthFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetWidthFactor(arg1);
		XSRETURN_EMPTY;


void
vtkRibbonFilter::UseDefaultNormalOff()
		CODE:
		THIS->UseDefaultNormalOff();
		XSRETURN_EMPTY;


void
vtkRibbonFilter::UseDefaultNormalOn()
		CODE:
		THIS->UseDefaultNormalOn();
		XSRETURN_EMPTY;


void
vtkRibbonFilter::VaryWidthOff()
		CODE:
		THIS->VaryWidthOff();
		XSRETURN_EMPTY;


void
vtkRibbonFilter::VaryWidthOn()
		CODE:
		THIS->VaryWidthOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::RotationalExtrusionFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRotationalExtrusionFilter::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkRotationalExtrusionFilter::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


float
vtkRotationalExtrusionFilter::GetAngle()
		CODE:
		RETVAL = THIS->GetAngle();
		OUTPUT:
		RETVAL


int
vtkRotationalExtrusionFilter::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkRotationalExtrusionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkRotationalExtrusionFilter::GetDeltaRadius()
		CODE:
		RETVAL = THIS->GetDeltaRadius();
		OUTPUT:
		RETVAL


int
vtkRotationalExtrusionFilter::GetResolution()
		CODE:
		RETVAL = THIS->GetResolution();
		OUTPUT:
		RETVAL


int
vtkRotationalExtrusionFilter::GetResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkRotationalExtrusionFilter::GetResolutionMinValue()
		CODE:
		RETVAL = THIS->GetResolutionMinValue();
		OUTPUT:
		RETVAL


float
vtkRotationalExtrusionFilter::GetTranslation()
		CODE:
		RETVAL = THIS->GetTranslation();
		OUTPUT:
		RETVAL


static vtkRotationalExtrusionFilter*
vtkRotationalExtrusionFilter::New()
		CODE:
		RETVAL = vtkRotationalExtrusionFilter::New();
		OUTPUT:
		RETVAL


void
vtkRotationalExtrusionFilter::SetAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetAngle(arg1);
		XSRETURN_EMPTY;


void
vtkRotationalExtrusionFilter::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkRotationalExtrusionFilter::SetDeltaRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetDeltaRadius(arg1);
		XSRETURN_EMPTY;


void
vtkRotationalExtrusionFilter::SetResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetResolution(arg1);
		XSRETURN_EMPTY;


void
vtkRotationalExtrusionFilter::SetTranslation(arg1)
		float 	arg1
		CODE:
		THIS->SetTranslation(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::RuledSurfaceFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRuledSurfaceFilter::CloseSurfaceOff()
		CODE:
		THIS->CloseSurfaceOff();
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::CloseSurfaceOn()
		CODE:
		THIS->CloseSurfaceOn();
		XSRETURN_EMPTY;


const char *
vtkRuledSurfaceFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetCloseSurface()
		CODE:
		RETVAL = THIS->GetCloseSurface();
		OUTPUT:
		RETVAL


float
vtkRuledSurfaceFilter::GetDistanceFactor()
		CODE:
		RETVAL = THIS->GetDistanceFactor();
		OUTPUT:
		RETVAL


float
vtkRuledSurfaceFilter::GetDistanceFactorMaxValue()
		CODE:
		RETVAL = THIS->GetDistanceFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkRuledSurfaceFilter::GetDistanceFactorMinValue()
		CODE:
		RETVAL = THIS->GetDistanceFactorMinValue();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetOnRatio()
		CODE:
		RETVAL = THIS->GetOnRatio();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetOnRatioMaxValue()
		CODE:
		RETVAL = THIS->GetOnRatioMaxValue();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetOnRatioMinValue()
		CODE:
		RETVAL = THIS->GetOnRatioMinValue();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetPassLines()
		CODE:
		RETVAL = THIS->GetPassLines();
		OUTPUT:
		RETVAL


int  *
vtkRuledSurfaceFilter::GetResolution()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetResolution();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkRuledSurfaceFilter::GetRuledMode()
		CODE:
		RETVAL = THIS->GetRuledMode();
		OUTPUT:
		RETVAL


const char *
vtkRuledSurfaceFilter::GetRuledModeAsString()
		CODE:
		RETVAL = THIS->GetRuledModeAsString();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetRuledModeMaxValue()
		CODE:
		RETVAL = THIS->GetRuledModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkRuledSurfaceFilter::GetRuledModeMinValue()
		CODE:
		RETVAL = THIS->GetRuledModeMinValue();
		OUTPUT:
		RETVAL


static vtkRuledSurfaceFilter*
vtkRuledSurfaceFilter::New()
		CODE:
		RETVAL = vtkRuledSurfaceFilter::New();
		OUTPUT:
		RETVAL


void
vtkRuledSurfaceFilter::PassLinesOff()
		CODE:
		THIS->PassLinesOff();
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::PassLinesOn()
		CODE:
		THIS->PassLinesOn();
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetCloseSurface(arg1)
		int 	arg1
		CODE:
		THIS->SetCloseSurface(arg1);
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetDistanceFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetDistanceFactor(arg1);
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetOffset(arg1)
		int 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetOnRatio(arg1)
		int 	arg1
		CODE:
		THIS->SetOnRatio(arg1);
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetPassLines(arg1)
		int 	arg1
		CODE:
		THIS->SetPassLines(arg1);
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetResolution(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetResolution(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRuledSurfaceFilter::SetResolution\n");



void
vtkRuledSurfaceFilter::SetRuledMode(arg1)
		int 	arg1
		CODE:
		THIS->SetRuledMode(arg1);
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetRuledModeToPointWalk()
		CODE:
		THIS->SetRuledModeToPointWalk();
		XSRETURN_EMPTY;


void
vtkRuledSurfaceFilter::SetRuledModeToResample()
		CODE:
		THIS->SetRuledModeToResample();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SelectPolyData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSelectPolyData::GenerateSelectionScalarsOff()
		CODE:
		THIS->GenerateSelectionScalarsOff();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::GenerateSelectionScalarsOn()
		CODE:
		THIS->GenerateSelectionScalarsOn();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::GenerateUnselectedOutputOff()
		CODE:
		THIS->GenerateUnselectedOutputOff();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::GenerateUnselectedOutputOn()
		CODE:
		THIS->GenerateUnselectedOutputOn();
		XSRETURN_EMPTY;


const char *
vtkSelectPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::GetGenerateSelectionScalars()
		CODE:
		RETVAL = THIS->GetGenerateSelectionScalars();
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::GetGenerateUnselectedOutput()
		CODE:
		RETVAL = THIS->GetGenerateUnselectedOutput();
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::GetInsideOut()
		CODE:
		RETVAL = THIS->GetInsideOut();
		OUTPUT:
		RETVAL


vtkPoints *
vtkSelectPolyData::GetLoop()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetLoop();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkSelectPolyData::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkSelectPolyData::GetSelectionEdges()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetSelectionEdges();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::GetSelectionMode()
		CODE:
		RETVAL = THIS->GetSelectionMode();
		OUTPUT:
		RETVAL


const char *
vtkSelectPolyData::GetSelectionModeAsString()
		CODE:
		RETVAL = THIS->GetSelectionModeAsString();
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::GetSelectionModeMaxValue()
		CODE:
		RETVAL = THIS->GetSelectionModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::GetSelectionModeMinValue()
		CODE:
		RETVAL = THIS->GetSelectionModeMinValue();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkSelectPolyData::GetUnselectedOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetUnselectedOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkSelectPolyData::InRegisterLoop(arg1)
		vtkObject *	arg1
		CODE:
		RETVAL = THIS->InRegisterLoop(arg1);
		OUTPUT:
		RETVAL


void
vtkSelectPolyData::InsideOutOff()
		CODE:
		THIS->InsideOutOff();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::InsideOutOn()
		CODE:
		THIS->InsideOutOn();
		XSRETURN_EMPTY;


static vtkSelectPolyData*
vtkSelectPolyData::New()
		CODE:
		RETVAL = vtkSelectPolyData::New();
		OUTPUT:
		RETVAL


void
vtkSelectPolyData::SetGenerateSelectionScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateSelectionScalars(arg1);
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetGenerateUnselectedOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateUnselectedOutput(arg1);
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetInsideOut(arg1)
		int 	arg1
		CODE:
		THIS->SetInsideOut(arg1);
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetLoop(arg1)
		vtkPoints *	arg1
		CODE:
		THIS->SetLoop(arg1);
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetSelectionMode(arg1)
		int 	arg1
		CODE:
		THIS->SetSelectionMode(arg1);
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetSelectionModeToClosestPointRegion()
		CODE:
		THIS->SetSelectionModeToClosestPointRegion();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetSelectionModeToLargestRegion()
		CODE:
		THIS->SetSelectionModeToLargestRegion();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::SetSelectionModeToSmallestRegion()
		CODE:
		THIS->SetSelectionModeToSmallestRegion();
		XSRETURN_EMPTY;


void
vtkSelectPolyData::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ShrinkFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkShrinkFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkShrinkFilter::GetShrinkFactor()
		CODE:
		RETVAL = THIS->GetShrinkFactor();
		OUTPUT:
		RETVAL


float
vtkShrinkFilter::GetShrinkFactorMaxValue()
		CODE:
		RETVAL = THIS->GetShrinkFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkShrinkFilter::GetShrinkFactorMinValue()
		CODE:
		RETVAL = THIS->GetShrinkFactorMinValue();
		OUTPUT:
		RETVAL


static vtkShrinkFilter*
vtkShrinkFilter::New()
		CODE:
		RETVAL = vtkShrinkFilter::New();
		OUTPUT:
		RETVAL


void
vtkShrinkFilter::SetShrinkFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetShrinkFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ShrinkPolyData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkShrinkPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkShrinkPolyData::GetShrinkFactor()
		CODE:
		RETVAL = THIS->GetShrinkFactor();
		OUTPUT:
		RETVAL


float
vtkShrinkPolyData::GetShrinkFactorMaxValue()
		CODE:
		RETVAL = THIS->GetShrinkFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkShrinkPolyData::GetShrinkFactorMinValue()
		CODE:
		RETVAL = THIS->GetShrinkFactorMinValue();
		OUTPUT:
		RETVAL


static vtkShrinkPolyData*
vtkShrinkPolyData::New()
		CODE:
		RETVAL = vtkShrinkPolyData::New();
		OUTPUT:
		RETVAL


void
vtkShrinkPolyData::SetShrinkFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetShrinkFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SimpleElevationFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSimpleElevationFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkSimpleElevationFilter::GetVector()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVector();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkSimpleElevationFilter*
vtkSimpleElevationFilter::New()
		CODE:
		RETVAL = vtkSimpleElevationFilter::New();
		OUTPUT:
		RETVAL


void
vtkSimpleElevationFilter::SetVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetVector(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSimpleElevationFilter::SetVector\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SmoothPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSmoothPolyDataFilter::BoundarySmoothingOff()
		CODE:
		THIS->BoundarySmoothingOff();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::BoundarySmoothingOn()
		CODE:
		THIS->BoundarySmoothingOn();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::FeatureEdgeSmoothingOff()
		CODE:
		THIS->FeatureEdgeSmoothingOff();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::FeatureEdgeSmoothingOn()
		CODE:
		THIS->FeatureEdgeSmoothingOn();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::GenerateErrorScalarsOff()
		CODE:
		THIS->GenerateErrorScalarsOff();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::GenerateErrorScalarsOn()
		CODE:
		THIS->GenerateErrorScalarsOn();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::GenerateErrorVectorsOff()
		CODE:
		THIS->GenerateErrorVectorsOff();
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::GenerateErrorVectorsOn()
		CODE:
		THIS->GenerateErrorVectorsOn();
		XSRETURN_EMPTY;


int
vtkSmoothPolyDataFilter::GetBoundarySmoothing()
		CODE:
		RETVAL = THIS->GetBoundarySmoothing();
		OUTPUT:
		RETVAL


const char *
vtkSmoothPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetConvergence()
		CODE:
		RETVAL = THIS->GetConvergence();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetConvergenceMaxValue()
		CODE:
		RETVAL = THIS->GetConvergenceMaxValue();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetConvergenceMinValue()
		CODE:
		RETVAL = THIS->GetConvergenceMinValue();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetEdgeAngle()
		CODE:
		RETVAL = THIS->GetEdgeAngle();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetEdgeAngleMaxValue()
		CODE:
		RETVAL = THIS->GetEdgeAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetEdgeAngleMinValue()
		CODE:
		RETVAL = THIS->GetEdgeAngleMinValue();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetFeatureAngle()
		CODE:
		RETVAL = THIS->GetFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMinValue();
		OUTPUT:
		RETVAL


int
vtkSmoothPolyDataFilter::GetFeatureEdgeSmoothing()
		CODE:
		RETVAL = THIS->GetFeatureEdgeSmoothing();
		OUTPUT:
		RETVAL


int
vtkSmoothPolyDataFilter::GetGenerateErrorScalars()
		CODE:
		RETVAL = THIS->GetGenerateErrorScalars();
		OUTPUT:
		RETVAL


int
vtkSmoothPolyDataFilter::GetGenerateErrorVectors()
		CODE:
		RETVAL = THIS->GetGenerateErrorVectors();
		OUTPUT:
		RETVAL


int
vtkSmoothPolyDataFilter::GetNumberOfIterations()
		CODE:
		RETVAL = THIS->GetNumberOfIterations();
		OUTPUT:
		RETVAL


int
vtkSmoothPolyDataFilter::GetNumberOfIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfIterationsMaxValue();
		OUTPUT:
		RETVAL


int
vtkSmoothPolyDataFilter::GetNumberOfIterationsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfIterationsMinValue();
		OUTPUT:
		RETVAL


float
vtkSmoothPolyDataFilter::GetRelaxationFactor()
		CODE:
		RETVAL = THIS->GetRelaxationFactor();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkSmoothPolyDataFilter::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkSmoothPolyDataFilter*
vtkSmoothPolyDataFilter::New()
		CODE:
		RETVAL = vtkSmoothPolyDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkSmoothPolyDataFilter::SetBoundarySmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundarySmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetConvergence(arg1)
		float 	arg1
		CODE:
		THIS->SetConvergence(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetEdgeAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetEdgeAngle(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetFeatureEdgeSmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetFeatureEdgeSmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetGenerateErrorScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateErrorScalars(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetGenerateErrorVectors(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateErrorVectors(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetNumberOfIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfIterations(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetRelaxationFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetRelaxationFactor(arg1);
		XSRETURN_EMPTY;


void
vtkSmoothPolyDataFilter::SetSource(source)
		vtkPolyData *	source
		CODE:
		THIS->SetSource(source);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SpatialRepresentationFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSpatialRepresentationFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkSpatialRepresentationFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkSpatialRepresentationFilter::GetLevel()
		CODE:
		RETVAL = THIS->GetLevel();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkSpatialRepresentationFilter::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSpatialRepresentationFilter::GetOutput\n");



vtkLocator *
vtkSpatialRepresentationFilter::GetSpatialRepresentation()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLocator";
		CODE:
		RETVAL = THIS->GetSpatialRepresentation();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkSpatialRepresentationFilter*
vtkSpatialRepresentationFilter::New()
		CODE:
		RETVAL = vtkSpatialRepresentationFilter::New();
		OUTPUT:
		RETVAL


void
vtkSpatialRepresentationFilter::ResetOutput()
		CODE:
		THIS->ResetOutput();
		XSRETURN_EMPTY;


void
vtkSpatialRepresentationFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkSpatialRepresentationFilter::SetSpatialRepresentation(arg1)
		vtkLocator *	arg1
		CODE:
		THIS->SetSpatialRepresentation(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SphereSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkSphereSource::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkSphereSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetEndPhi()
		CODE:
		RETVAL = THIS->GetEndPhi();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetEndPhiMaxValue()
		CODE:
		RETVAL = THIS->GetEndPhiMaxValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetEndPhiMinValue()
		CODE:
		RETVAL = THIS->GetEndPhiMinValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetEndTheta()
		CODE:
		RETVAL = THIS->GetEndTheta();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetEndThetaMaxValue()
		CODE:
		RETVAL = THIS->GetEndThetaMaxValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetEndThetaMinValue()
		CODE:
		RETVAL = THIS->GetEndThetaMinValue();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetLatLongTessellation()
		CODE:
		RETVAL = THIS->GetLatLongTessellation();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetPhiResolution()
		CODE:
		RETVAL = THIS->GetPhiResolution();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetPhiResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetPhiResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetPhiResolutionMinValue()
		CODE:
		RETVAL = THIS->GetPhiResolutionMinValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetStartPhi()
		CODE:
		RETVAL = THIS->GetStartPhi();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetStartPhiMaxValue()
		CODE:
		RETVAL = THIS->GetStartPhiMaxValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetStartPhiMinValue()
		CODE:
		RETVAL = THIS->GetStartPhiMinValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetStartTheta()
		CODE:
		RETVAL = THIS->GetStartTheta();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetStartThetaMaxValue()
		CODE:
		RETVAL = THIS->GetStartThetaMaxValue();
		OUTPUT:
		RETVAL


float
vtkSphereSource::GetStartThetaMinValue()
		CODE:
		RETVAL = THIS->GetStartThetaMinValue();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetThetaResolution()
		CODE:
		RETVAL = THIS->GetThetaResolution();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetThetaResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetThetaResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkSphereSource::GetThetaResolutionMinValue()
		CODE:
		RETVAL = THIS->GetThetaResolutionMinValue();
		OUTPUT:
		RETVAL


void
vtkSphereSource::LatLongTessellationOff()
		CODE:
		THIS->LatLongTessellationOff();
		XSRETURN_EMPTY;


void
vtkSphereSource::LatLongTessellationOn()
		CODE:
		THIS->LatLongTessellationOn();
		XSRETURN_EMPTY;


static vtkSphereSource*
vtkSphereSource::New()
		CODE:
		RETVAL = vtkSphereSource::New();
		OUTPUT:
		RETVAL


void
vtkSphereSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSphereSource::SetCenter\n");



void
vtkSphereSource::SetEndPhi(arg1)
		float 	arg1
		CODE:
		THIS->SetEndPhi(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetEndTheta(arg1)
		float 	arg1
		CODE:
		THIS->SetEndTheta(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetLatLongTessellation(arg1)
		int 	arg1
		CODE:
		THIS->SetLatLongTessellation(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetPhiResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetPhiResolution(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetStartPhi(arg1)
		float 	arg1
		CODE:
		THIS->SetStartPhi(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetStartTheta(arg1)
		float 	arg1
		CODE:
		THIS->SetStartTheta(arg1);
		XSRETURN_EMPTY;


void
vtkSphereSource::SetThetaResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetThetaResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SplitField PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSplitField::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkSplitField*
vtkSplitField::New()
		CODE:
		RETVAL = vtkSplitField::New();
		OUTPUT:
		RETVAL


void
vtkSplitField::SetInputField(arg1 = 0, arg2 = 0)
	CASE: items == 3 && SvPOK(ST(2))
		const char *	arg1
		const char *	arg2
		CODE:
		THIS->SetInputField(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && SvIOK(ST(1))
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetInputField(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSplitField::SetInputField\n");



void
vtkSplitField::Split(component, arrayName)
		int 	component
		const char *	arrayName
		CODE:
		THIS->Split(component, arrayName);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::StreamLine PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStreamLine::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkStreamLine::GetStepLength()
		CODE:
		RETVAL = THIS->GetStepLength();
		OUTPUT:
		RETVAL


float
vtkStreamLine::GetStepLengthMaxValue()
		CODE:
		RETVAL = THIS->GetStepLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkStreamLine::GetStepLengthMinValue()
		CODE:
		RETVAL = THIS->GetStepLengthMinValue();
		OUTPUT:
		RETVAL


static vtkStreamLine*
vtkStreamLine::New()
		CODE:
		RETVAL = vtkStreamLine::New();
		OUTPUT:
		RETVAL


void
vtkStreamLine::SetStepLength(arg1)
		float 	arg1
		CODE:
		THIS->SetStepLength(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::StreamPoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStreamPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkStreamPoints::GetTimeIncrement()
		CODE:
		RETVAL = THIS->GetTimeIncrement();
		OUTPUT:
		RETVAL


float
vtkStreamPoints::GetTimeIncrementMaxValue()
		CODE:
		RETVAL = THIS->GetTimeIncrementMaxValue();
		OUTPUT:
		RETVAL


float
vtkStreamPoints::GetTimeIncrementMinValue()
		CODE:
		RETVAL = THIS->GetTimeIncrementMinValue();
		OUTPUT:
		RETVAL


static vtkStreamPoints*
vtkStreamPoints::New()
		CODE:
		RETVAL = vtkStreamPoints::New();
		OUTPUT:
		RETVAL


void
vtkStreamPoints::SetTimeIncrement(arg1)
		float 	arg1
		CODE:
		THIS->SetTimeIncrement(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Streamer PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStreamer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkStreamer::GetIntegrationDirection()
		CODE:
		RETVAL = THIS->GetIntegrationDirection();
		OUTPUT:
		RETVAL


const char *
vtkStreamer::GetIntegrationDirectionAsString()
		CODE:
		RETVAL = THIS->GetIntegrationDirectionAsString();
		OUTPUT:
		RETVAL


int
vtkStreamer::GetIntegrationDirectionMaxValue()
		CODE:
		RETVAL = THIS->GetIntegrationDirectionMaxValue();
		OUTPUT:
		RETVAL


int
vtkStreamer::GetIntegrationDirectionMinValue()
		CODE:
		RETVAL = THIS->GetIntegrationDirectionMinValue();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetIntegrationStepLength()
		CODE:
		RETVAL = THIS->GetIntegrationStepLength();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetIntegrationStepLengthMaxValue()
		CODE:
		RETVAL = THIS->GetIntegrationStepLengthMaxValue();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetIntegrationStepLengthMinValue()
		CODE:
		RETVAL = THIS->GetIntegrationStepLengthMinValue();
		OUTPUT:
		RETVAL


vtkInitialValueProblemSolver *
vtkStreamer::GetIntegrator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkInitialValueProblemSolver";
		CODE:
		RETVAL = THIS->GetIntegrator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkStreamer::GetMaximumPropagationTime()
		CODE:
		RETVAL = THIS->GetMaximumPropagationTime();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetMaximumPropagationTimeMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumPropagationTimeMaxValue();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetMaximumPropagationTimeMinValue()
		CODE:
		RETVAL = THIS->GetMaximumPropagationTimeMinValue();
		OUTPUT:
		RETVAL


int
vtkStreamer::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkStreamer::GetOrientationScalars()
		CODE:
		RETVAL = THIS->GetOrientationScalars();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetSavePointInterval()
		CODE:
		RETVAL = THIS->GetSavePointInterval();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkStreamer::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkStreamer::GetSpeedScalars()
		CODE:
		RETVAL = THIS->GetSpeedScalars();
		OUTPUT:
		RETVAL


float *
vtkStreamer::GetStartPosition()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetStartPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkStreamer::GetTerminalSpeed()
		CODE:
		RETVAL = THIS->GetTerminalSpeed();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetTerminalSpeedMaxValue()
		CODE:
		RETVAL = THIS->GetTerminalSpeedMaxValue();
		OUTPUT:
		RETVAL


float
vtkStreamer::GetTerminalSpeedMinValue()
		CODE:
		RETVAL = THIS->GetTerminalSpeedMinValue();
		OUTPUT:
		RETVAL


int
vtkStreamer::GetVorticity()
		CODE:
		RETVAL = THIS->GetVorticity();
		OUTPUT:
		RETVAL


static vtkStreamer*
vtkStreamer::New()
		CODE:
		RETVAL = vtkStreamer::New();
		OUTPUT:
		RETVAL


void
vtkStreamer::OrientationScalarsOff()
		CODE:
		THIS->OrientationScalarsOff();
		XSRETURN_EMPTY;


void
vtkStreamer::OrientationScalarsOn()
		CODE:
		THIS->OrientationScalarsOn();
		XSRETURN_EMPTY;


void
vtkStreamer::SetIntegrationDirection(arg1)
		int 	arg1
		CODE:
		THIS->SetIntegrationDirection(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetIntegrationDirectionToBackward()
		CODE:
		THIS->SetIntegrationDirectionToBackward();
		XSRETURN_EMPTY;


void
vtkStreamer::SetIntegrationDirectionToForward()
		CODE:
		THIS->SetIntegrationDirectionToForward();
		XSRETURN_EMPTY;


void
vtkStreamer::SetIntegrationDirectionToIntegrateBothDirections()
		CODE:
		THIS->SetIntegrationDirectionToIntegrateBothDirections();
		XSRETURN_EMPTY;


void
vtkStreamer::SetIntegrationStepLength(arg1)
		float 	arg1
		CODE:
		THIS->SetIntegrationStepLength(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetIntegrator(arg1)
		vtkInitialValueProblemSolver *	arg1
		CODE:
		THIS->SetIntegrator(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetMaximumPropagationTime(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumPropagationTime(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetOrientationScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetOrientationScalars(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetSavePointInterval(arg1)
		float 	arg1
		CODE:
		THIS->SetSavePointInterval(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetSource(source)
		vtkDataSet *	source
		CODE:
		THIS->SetSource(source);
		XSRETURN_EMPTY;


void
vtkStreamer::SetSpeedScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetSpeedScalars(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetStartLocation(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		long 	arg1
		int 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		CODE:
		THIS->SetStartLocation(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStreamer::SetStartLocation\n");



void
vtkStreamer::SetStartPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetStartPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStreamer::SetStartPosition\n");



void
vtkStreamer::SetTerminalSpeed(arg1)
		float 	arg1
		CODE:
		THIS->SetTerminalSpeed(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SetVorticity(arg1)
		int 	arg1
		CODE:
		THIS->SetVorticity(arg1);
		XSRETURN_EMPTY;


void
vtkStreamer::SpeedScalarsOff()
		CODE:
		THIS->SpeedScalarsOff();
		XSRETURN_EMPTY;


void
vtkStreamer::SpeedScalarsOn()
		CODE:
		THIS->SpeedScalarsOn();
		XSRETURN_EMPTY;


void
vtkStreamer::VorticityOff()
		CODE:
		THIS->VorticityOff();
		XSRETURN_EMPTY;


void
vtkStreamer::VorticityOn()
		CODE:
		THIS->VorticityOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Stripper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStripper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkStripper::GetMaximumLength()
		CODE:
		RETVAL = THIS->GetMaximumLength();
		OUTPUT:
		RETVAL


int
vtkStripper::GetMaximumLengthMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumLengthMaxValue();
		OUTPUT:
		RETVAL


int
vtkStripper::GetMaximumLengthMinValue()
		CODE:
		RETVAL = THIS->GetMaximumLengthMinValue();
		OUTPUT:
		RETVAL


static vtkStripper*
vtkStripper::New()
		CODE:
		RETVAL = vtkStripper::New();
		OUTPUT:
		RETVAL


void
vtkStripper::SetMaximumLength(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumLength(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::StructuredGridGeometryFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridGeometryFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkStructuredGridGeometryFilter::GetExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


static vtkStructuredGridGeometryFilter*
vtkStructuredGridGeometryFilter::New()
		CODE:
		RETVAL = vtkStructuredGridGeometryFilter::New();
		OUTPUT:
		RETVAL


void
vtkStructuredGridGeometryFilter::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGridGeometryFilter::SetExtent\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::StructuredGridOutlineFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridOutlineFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkStructuredGridOutlineFilter*
vtkStructuredGridOutlineFilter::New()
		CODE:
		RETVAL = vtkStructuredGridOutlineFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::StructuredPointsGeometryFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsGeometryFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkStructuredPointsGeometryFilter*
vtkStructuredPointsGeometryFilter::New()
		CODE:
		RETVAL = vtkStructuredPointsGeometryFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SubPixelPositionEdgels PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSubPixelPositionEdgels::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkSubPixelPositionEdgels::GetGradMaps()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetGradMaps();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkSubPixelPositionEdgels::GetTargetFlag()
		CODE:
		RETVAL = THIS->GetTargetFlag();
		OUTPUT:
		RETVAL


float
vtkSubPixelPositionEdgels::GetTargetValue()
		CODE:
		RETVAL = THIS->GetTargetValue();
		OUTPUT:
		RETVAL


static vtkSubPixelPositionEdgels*
vtkSubPixelPositionEdgels::New()
		CODE:
		RETVAL = vtkSubPixelPositionEdgels::New();
		OUTPUT:
		RETVAL


void
vtkSubPixelPositionEdgels::SetGradMaps(gm)
		vtkStructuredPoints *	gm
		CODE:
		THIS->SetGradMaps(gm);
		XSRETURN_EMPTY;


void
vtkSubPixelPositionEdgels::SetTargetFlag(arg1)
		int 	arg1
		CODE:
		THIS->SetTargetFlag(arg1);
		XSRETURN_EMPTY;


void
vtkSubPixelPositionEdgels::SetTargetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetTargetValue(arg1);
		XSRETURN_EMPTY;


void
vtkSubPixelPositionEdgels::TargetFlagOff()
		CODE:
		THIS->TargetFlagOff();
		XSRETURN_EMPTY;


void
vtkSubPixelPositionEdgels::TargetFlagOn()
		CODE:
		THIS->TargetFlagOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SubdivideTetra PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSubdivideTetra::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkSubdivideTetra*
vtkSubdivideTetra::New()
		CODE:
		RETVAL = vtkSubdivideTetra::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::SuperquadricSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkSuperquadricSource::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkSuperquadricSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSuperquadricSource::GetPhiResolution()
		CODE:
		RETVAL = THIS->GetPhiResolution();
		OUTPUT:
		RETVAL


float
vtkSuperquadricSource::GetPhiRoundness()
		CODE:
		RETVAL = THIS->GetPhiRoundness();
		OUTPUT:
		RETVAL


float  *
vtkSuperquadricSource::GetScale()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScale();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkSuperquadricSource::GetSize()
		CODE:
		RETVAL = THIS->GetSize();
		OUTPUT:
		RETVAL


int
vtkSuperquadricSource::GetThetaResolution()
		CODE:
		RETVAL = THIS->GetThetaResolution();
		OUTPUT:
		RETVAL


float
vtkSuperquadricSource::GetThetaRoundness()
		CODE:
		RETVAL = THIS->GetThetaRoundness();
		OUTPUT:
		RETVAL


float
vtkSuperquadricSource::GetThickness()
		CODE:
		RETVAL = THIS->GetThickness();
		OUTPUT:
		RETVAL


float
vtkSuperquadricSource::GetThicknessMaxValue()
		CODE:
		RETVAL = THIS->GetThicknessMaxValue();
		OUTPUT:
		RETVAL


float
vtkSuperquadricSource::GetThicknessMinValue()
		CODE:
		RETVAL = THIS->GetThicknessMinValue();
		OUTPUT:
		RETVAL


int
vtkSuperquadricSource::GetToroidal()
		CODE:
		RETVAL = THIS->GetToroidal();
		OUTPUT:
		RETVAL


static vtkSuperquadricSource*
vtkSuperquadricSource::New()
		CODE:
		RETVAL = vtkSuperquadricSource::New();
		OUTPUT:
		RETVAL


void
vtkSuperquadricSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSuperquadricSource::SetCenter\n");



void
vtkSuperquadricSource::SetPhiResolution(i)
		int 	i
		CODE:
		THIS->SetPhiResolution(i);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::SetPhiRoundness(e)
		float 	e
		CODE:
		THIS->SetPhiRoundness(e);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::SetScale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetScale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSuperquadricSource::SetScale\n");



void
vtkSuperquadricSource::SetSize(arg1)
		float 	arg1
		CODE:
		THIS->SetSize(arg1);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::SetThetaResolution(i)
		int 	i
		CODE:
		THIS->SetThetaResolution(i);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::SetThetaRoundness(e)
		float 	e
		CODE:
		THIS->SetThetaRoundness(e);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::SetThickness(arg1)
		float 	arg1
		CODE:
		THIS->SetThickness(arg1);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::SetToroidal(arg1)
		int 	arg1
		CODE:
		THIS->SetToroidal(arg1);
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::ToroidalOff()
		CODE:
		THIS->ToroidalOff();
		XSRETURN_EMPTY;


void
vtkSuperquadricSource::ToroidalOn()
		CODE:
		THIS->ToroidalOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TensorGlyph PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTensorGlyph::ClampScalingOff()
		CODE:
		THIS->ClampScalingOff();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::ClampScalingOn()
		CODE:
		THIS->ClampScalingOn();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::ColorGlyphsOff()
		CODE:
		THIS->ColorGlyphsOff();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::ColorGlyphsOn()
		CODE:
		THIS->ColorGlyphsOn();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::ExtractEigenvaluesOff()
		CODE:
		THIS->ExtractEigenvaluesOff();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::ExtractEigenvaluesOn()
		CODE:
		THIS->ExtractEigenvaluesOn();
		XSRETURN_EMPTY;


int
vtkTensorGlyph::GetClampScaling()
		CODE:
		RETVAL = THIS->GetClampScaling();
		OUTPUT:
		RETVAL


const char *
vtkTensorGlyph::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkTensorGlyph::GetColorGlyphs()
		CODE:
		RETVAL = THIS->GetColorGlyphs();
		OUTPUT:
		RETVAL


int
vtkTensorGlyph::GetExtractEigenvalues()
		CODE:
		RETVAL = THIS->GetExtractEigenvalues();
		OUTPUT:
		RETVAL


float
vtkTensorGlyph::GetMaxScaleFactor()
		CODE:
		RETVAL = THIS->GetMaxScaleFactor();
		OUTPUT:
		RETVAL


float
vtkTensorGlyph::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


int
vtkTensorGlyph::GetScaling()
		CODE:
		RETVAL = THIS->GetScaling();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkTensorGlyph::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkTensorGlyph*
vtkTensorGlyph::New()
		CODE:
		RETVAL = vtkTensorGlyph::New();
		OUTPUT:
		RETVAL


void
vtkTensorGlyph::ScalingOff()
		CODE:
		THIS->ScalingOff();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::ScalingOn()
		CODE:
		THIS->ScalingOn();
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetClampScaling(arg1)
		int 	arg1
		CODE:
		THIS->SetClampScaling(arg1);
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetColorGlyphs(arg1)
		int 	arg1
		CODE:
		THIS->SetColorGlyphs(arg1);
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetExtractEigenvalues(arg1)
		int 	arg1
		CODE:
		THIS->SetExtractEigenvalues(arg1);
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetMaxScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetMaxScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetScaling(arg1)
		int 	arg1
		CODE:
		THIS->SetScaling(arg1);
		XSRETURN_EMPTY;


void
vtkTensorGlyph::SetSource(source)
		vtkPolyData *	source
		CODE:
		THIS->SetSource(source);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TextSource PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTextSource::BackingOff()
		CODE:
		THIS->BackingOff();
		XSRETURN_EMPTY;


void
vtkTextSource::BackingOn()
		CODE:
		THIS->BackingOn();
		XSRETURN_EMPTY;


float  *
vtkTextSource::GetBackgroundColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBackgroundColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkTextSource::GetBacking()
		CODE:
		RETVAL = THIS->GetBacking();
		OUTPUT:
		RETVAL


const char *
vtkTextSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkTextSource::GetForegroundColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetForegroundColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


char *
vtkTextSource::GetText()
		CODE:
		RETVAL = THIS->GetText();
		OUTPUT:
		RETVAL


static vtkTextSource*
vtkTextSource::New()
		CODE:
		RETVAL = vtkTextSource::New();
		OUTPUT:
		RETVAL


void
vtkTextSource::SetBackgroundColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetBackgroundColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextSource::SetBackgroundColor\n");



void
vtkTextSource::SetBacking(arg1)
		int 	arg1
		CODE:
		THIS->SetBacking(arg1);
		XSRETURN_EMPTY;


void
vtkTextSource::SetForegroundColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetForegroundColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextSource::SetForegroundColor\n");



void
vtkTextSource::SetText(arg1)
		char *	arg1
		CODE:
		THIS->SetText(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TextureMapToCylinder PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTextureMapToCylinder::AutomaticCylinderGenerationOff()
		CODE:
		THIS->AutomaticCylinderGenerationOff();
		XSRETURN_EMPTY;


void
vtkTextureMapToCylinder::AutomaticCylinderGenerationOn()
		CODE:
		THIS->AutomaticCylinderGenerationOn();
		XSRETURN_EMPTY;


int
vtkTextureMapToCylinder::GetAutomaticCylinderGeneration()
		CODE:
		RETVAL = THIS->GetAutomaticCylinderGeneration();
		OUTPUT:
		RETVAL


const char *
vtkTextureMapToCylinder::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkTextureMapToCylinder::GetPoint1()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint1();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTextureMapToCylinder::GetPoint2()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint2();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkTextureMapToCylinder::GetPreventSeam()
		CODE:
		RETVAL = THIS->GetPreventSeam();
		OUTPUT:
		RETVAL


static vtkTextureMapToCylinder*
vtkTextureMapToCylinder::New()
		CODE:
		RETVAL = vtkTextureMapToCylinder::New();
		OUTPUT:
		RETVAL


void
vtkTextureMapToCylinder::PreventSeamOff()
		CODE:
		THIS->PreventSeamOff();
		XSRETURN_EMPTY;


void
vtkTextureMapToCylinder::PreventSeamOn()
		CODE:
		THIS->PreventSeamOn();
		XSRETURN_EMPTY;


void
vtkTextureMapToCylinder::SetAutomaticCylinderGeneration(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticCylinderGeneration(arg1);
		XSRETURN_EMPTY;


void
vtkTextureMapToCylinder::SetPoint1(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint1(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToCylinder::SetPoint1\n");



void
vtkTextureMapToCylinder::SetPoint2(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint2(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToCylinder::SetPoint2\n");



void
vtkTextureMapToCylinder::SetPreventSeam(arg1)
		int 	arg1
		CODE:
		THIS->SetPreventSeam(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TextureMapToPlane PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTextureMapToPlane::AutomaticPlaneGenerationOff()
		CODE:
		THIS->AutomaticPlaneGenerationOff();
		XSRETURN_EMPTY;


void
vtkTextureMapToPlane::AutomaticPlaneGenerationOn()
		CODE:
		THIS->AutomaticPlaneGenerationOn();
		XSRETURN_EMPTY;


int
vtkTextureMapToPlane::GetAutomaticPlaneGeneration()
		CODE:
		RETVAL = THIS->GetAutomaticPlaneGeneration();
		OUTPUT:
		RETVAL


const char *
vtkTextureMapToPlane::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkTextureMapToPlane::GetNormal()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTextureMapToPlane::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTextureMapToPlane::GetPoint1()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint1();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTextureMapToPlane::GetPoint2()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint2();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTextureMapToPlane::GetSRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkTextureMapToPlane::GetTRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkTextureMapToPlane*
vtkTextureMapToPlane::New()
		CODE:
		RETVAL = vtkTextureMapToPlane::New();
		OUTPUT:
		RETVAL


void
vtkTextureMapToPlane::SetAutomaticPlaneGeneration(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticPlaneGeneration(arg1);
		XSRETURN_EMPTY;


void
vtkTextureMapToPlane::SetNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToPlane::SetNormal\n");



void
vtkTextureMapToPlane::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToPlane::SetOrigin\n");



void
vtkTextureMapToPlane::SetPoint1(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint1(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToPlane::SetPoint1\n");



void
vtkTextureMapToPlane::SetPoint2(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPoint2(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToPlane::SetPoint2\n");



void
vtkTextureMapToPlane::SetSRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetSRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToPlane::SetSRange\n");



void
vtkTextureMapToPlane::SetTRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetTRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToPlane::SetTRange\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TextureMapToSphere PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTextureMapToSphere::AutomaticSphereGenerationOff()
		CODE:
		THIS->AutomaticSphereGenerationOff();
		XSRETURN_EMPTY;


void
vtkTextureMapToSphere::AutomaticSphereGenerationOn()
		CODE:
		THIS->AutomaticSphereGenerationOn();
		XSRETURN_EMPTY;


int
vtkTextureMapToSphere::GetAutomaticSphereGeneration()
		CODE:
		RETVAL = THIS->GetAutomaticSphereGeneration();
		OUTPUT:
		RETVAL


float  *
vtkTextureMapToSphere::GetCenter()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkTextureMapToSphere::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkTextureMapToSphere::GetPreventSeam()
		CODE:
		RETVAL = THIS->GetPreventSeam();
		OUTPUT:
		RETVAL


static vtkTextureMapToSphere*
vtkTextureMapToSphere::New()
		CODE:
		RETVAL = vtkTextureMapToSphere::New();
		OUTPUT:
		RETVAL


void
vtkTextureMapToSphere::PreventSeamOff()
		CODE:
		THIS->PreventSeamOff();
		XSRETURN_EMPTY;


void
vtkTextureMapToSphere::PreventSeamOn()
		CODE:
		THIS->PreventSeamOn();
		XSRETURN_EMPTY;


void
vtkTextureMapToSphere::SetAutomaticSphereGeneration(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticSphereGeneration(arg1);
		XSRETURN_EMPTY;


void
vtkTextureMapToSphere::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextureMapToSphere::SetCenter\n");



void
vtkTextureMapToSphere::SetPreventSeam(arg1)
		int 	arg1
		CODE:
		THIS->SetPreventSeam(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TexturedSphereSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTexturedSphereSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetPhi()
		CODE:
		RETVAL = THIS->GetPhi();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetPhiMaxValue()
		CODE:
		RETVAL = THIS->GetPhiMaxValue();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetPhiMinValue()
		CODE:
		RETVAL = THIS->GetPhiMinValue();
		OUTPUT:
		RETVAL


int
vtkTexturedSphereSource::GetPhiResolution()
		CODE:
		RETVAL = THIS->GetPhiResolution();
		OUTPUT:
		RETVAL


int
vtkTexturedSphereSource::GetPhiResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetPhiResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkTexturedSphereSource::GetPhiResolutionMinValue()
		CODE:
		RETVAL = THIS->GetPhiResolutionMinValue();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetTheta()
		CODE:
		RETVAL = THIS->GetTheta();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetThetaMaxValue()
		CODE:
		RETVAL = THIS->GetThetaMaxValue();
		OUTPUT:
		RETVAL


float
vtkTexturedSphereSource::GetThetaMinValue()
		CODE:
		RETVAL = THIS->GetThetaMinValue();
		OUTPUT:
		RETVAL


int
vtkTexturedSphereSource::GetThetaResolution()
		CODE:
		RETVAL = THIS->GetThetaResolution();
		OUTPUT:
		RETVAL


int
vtkTexturedSphereSource::GetThetaResolutionMaxValue()
		CODE:
		RETVAL = THIS->GetThetaResolutionMaxValue();
		OUTPUT:
		RETVAL


int
vtkTexturedSphereSource::GetThetaResolutionMinValue()
		CODE:
		RETVAL = THIS->GetThetaResolutionMinValue();
		OUTPUT:
		RETVAL


static vtkTexturedSphereSource*
vtkTexturedSphereSource::New()
		CODE:
		RETVAL = vtkTexturedSphereSource::New();
		OUTPUT:
		RETVAL


void
vtkTexturedSphereSource::SetPhi(arg1)
		float 	arg1
		CODE:
		THIS->SetPhi(arg1);
		XSRETURN_EMPTY;


void
vtkTexturedSphereSource::SetPhiResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetPhiResolution(arg1);
		XSRETURN_EMPTY;


void
vtkTexturedSphereSource::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkTexturedSphereSource::SetTheta(arg1)
		float 	arg1
		CODE:
		THIS->SetTheta(arg1);
		XSRETURN_EMPTY;


void
vtkTexturedSphereSource::SetThetaResolution(arg1)
		int 	arg1
		CODE:
		THIS->SetThetaResolution(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::Threshold PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkThreshold::AllScalarsOff()
		CODE:
		THIS->AllScalarsOff();
		XSRETURN_EMPTY;


void
vtkThreshold::AllScalarsOn()
		CODE:
		THIS->AllScalarsOn();
		XSRETURN_EMPTY;


int
vtkThreshold::GetAllScalars()
		CODE:
		RETVAL = THIS->GetAllScalars();
		OUTPUT:
		RETVAL


char *
vtkThreshold::GetArrayName()
		CODE:
		RETVAL = THIS->GetArrayName();
		OUTPUT:
		RETVAL


int
vtkThreshold::GetAttributeMode()
		CODE:
		RETVAL = THIS->GetAttributeMode();
		OUTPUT:
		RETVAL


const char *
vtkThreshold::GetAttributeModeAsString()
		CODE:
		RETVAL = THIS->GetAttributeModeAsString();
		OUTPUT:
		RETVAL


const char *
vtkThreshold::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkThreshold::GetLowerThreshold()
		CODE:
		RETVAL = THIS->GetLowerThreshold();
		OUTPUT:
		RETVAL


float
vtkThreshold::GetUpperThreshold()
		CODE:
		RETVAL = THIS->GetUpperThreshold();
		OUTPUT:
		RETVAL


static vtkThreshold*
vtkThreshold::New()
		CODE:
		RETVAL = vtkThreshold::New();
		OUTPUT:
		RETVAL


void
vtkThreshold::SetAllScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetAllScalars(arg1);
		XSRETURN_EMPTY;


void
vtkThreshold::SetArrayName(arg1)
		char *	arg1
		CODE:
		THIS->SetArrayName(arg1);
		XSRETURN_EMPTY;


void
vtkThreshold::SetAttributeMode(arg1)
		int 	arg1
		CODE:
		THIS->SetAttributeMode(arg1);
		XSRETURN_EMPTY;


void
vtkThreshold::SetAttributeModeToDefault()
		CODE:
		THIS->SetAttributeModeToDefault();
		XSRETURN_EMPTY;


void
vtkThreshold::SetAttributeModeToUseCellData()
		CODE:
		THIS->SetAttributeModeToUseCellData();
		XSRETURN_EMPTY;


void
vtkThreshold::SetAttributeModeToUsePointData()
		CODE:
		THIS->SetAttributeModeToUsePointData();
		XSRETURN_EMPTY;


void
vtkThreshold::ThresholdBetween(lower, upper)
		float 	lower
		float 	upper
		CODE:
		THIS->ThresholdBetween(lower, upper);
		XSRETURN_EMPTY;


void
vtkThreshold::ThresholdByLower(lower)
		float 	lower
		CODE:
		THIS->ThresholdByLower(lower);
		XSRETURN_EMPTY;


void
vtkThreshold::ThresholdByUpper(upper)
		float 	upper
		CODE:
		THIS->ThresholdByUpper(upper);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ThresholdPoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkThresholdPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkThresholdPoints::GetLowerThreshold()
		CODE:
		RETVAL = THIS->GetLowerThreshold();
		OUTPUT:
		RETVAL


float
vtkThresholdPoints::GetUpperThreshold()
		CODE:
		RETVAL = THIS->GetUpperThreshold();
		OUTPUT:
		RETVAL


static vtkThresholdPoints*
vtkThresholdPoints::New()
		CODE:
		RETVAL = vtkThresholdPoints::New();
		OUTPUT:
		RETVAL


void
vtkThresholdPoints::ThresholdBetween(lower, upper)
		float 	lower
		float 	upper
		CODE:
		THIS->ThresholdBetween(lower, upper);
		XSRETURN_EMPTY;


void
vtkThresholdPoints::ThresholdByLower(lower)
		float 	lower
		CODE:
		THIS->ThresholdByLower(lower);
		XSRETURN_EMPTY;


void
vtkThresholdPoints::ThresholdByUpper(upper)
		float 	upper
		CODE:
		THIS->ThresholdByUpper(upper);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::ThresholdTextureCoords PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkThresholdTextureCoords::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkThresholdTextureCoords::GetInTextureCoord()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetInTextureCoord();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkThresholdTextureCoords::GetLowerThreshold()
		CODE:
		RETVAL = THIS->GetLowerThreshold();
		OUTPUT:
		RETVAL


float  *
vtkThresholdTextureCoords::GetOutTextureCoord()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutTextureCoord();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkThresholdTextureCoords::GetTextureDimension()
		CODE:
		RETVAL = THIS->GetTextureDimension();
		OUTPUT:
		RETVAL


int
vtkThresholdTextureCoords::GetTextureDimensionMaxValue()
		CODE:
		RETVAL = THIS->GetTextureDimensionMaxValue();
		OUTPUT:
		RETVAL


int
vtkThresholdTextureCoords::GetTextureDimensionMinValue()
		CODE:
		RETVAL = THIS->GetTextureDimensionMinValue();
		OUTPUT:
		RETVAL


float
vtkThresholdTextureCoords::GetUpperThreshold()
		CODE:
		RETVAL = THIS->GetUpperThreshold();
		OUTPUT:
		RETVAL


static vtkThresholdTextureCoords*
vtkThresholdTextureCoords::New()
		CODE:
		RETVAL = vtkThresholdTextureCoords::New();
		OUTPUT:
		RETVAL


void
vtkThresholdTextureCoords::SetInTextureCoord(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetInTextureCoord(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkThresholdTextureCoords::SetInTextureCoord\n");



void
vtkThresholdTextureCoords::SetOutTextureCoord(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutTextureCoord(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkThresholdTextureCoords::SetOutTextureCoord\n");



void
vtkThresholdTextureCoords::SetTextureDimension(arg1)
		int 	arg1
		CODE:
		THIS->SetTextureDimension(arg1);
		XSRETURN_EMPTY;


void
vtkThresholdTextureCoords::ThresholdBetween(lower, upper)
		float 	lower
		float 	upper
		CODE:
		THIS->ThresholdBetween(lower, upper);
		XSRETURN_EMPTY;


void
vtkThresholdTextureCoords::ThresholdByLower(lower)
		float 	lower
		CODE:
		THIS->ThresholdByLower(lower);
		XSRETURN_EMPTY;


void
vtkThresholdTextureCoords::ThresholdByUpper(upper)
		float 	upper
		CODE:
		THIS->ThresholdByUpper(upper);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TransformFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTransformFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkTransformFilter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkTransformFilter::GetTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkTransformFilter*
vtkTransformFilter::New()
		CODE:
		RETVAL = vtkTransformFilter::New();
		OUTPUT:
		RETVAL


void
vtkTransformFilter::SetTransform(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->SetTransform(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TransformPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTransformPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkTransformPolyDataFilter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkTransformPolyDataFilter::GetTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkTransformPolyDataFilter*
vtkTransformPolyDataFilter::New()
		CODE:
		RETVAL = vtkTransformPolyDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkTransformPolyDataFilter::SetTransform(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->SetTransform(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TransformTextureCoords PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTransformTextureCoords::AddPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->AddPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformTextureCoords::AddPosition\n");



void
vtkTransformTextureCoords::FlipROff()
		CODE:
		THIS->FlipROff();
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::FlipROn()
		CODE:
		THIS->FlipROn();
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::FlipSOff()
		CODE:
		THIS->FlipSOff();
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::FlipSOn()
		CODE:
		THIS->FlipSOn();
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::FlipTOff()
		CODE:
		THIS->FlipTOff();
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::FlipTOn()
		CODE:
		THIS->FlipTOn();
		XSRETURN_EMPTY;


const char *
vtkTransformTextureCoords::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkTransformTextureCoords::GetFlipR()
		CODE:
		RETVAL = THIS->GetFlipR();
		OUTPUT:
		RETVAL


int
vtkTransformTextureCoords::GetFlipS()
		CODE:
		RETVAL = THIS->GetFlipS();
		OUTPUT:
		RETVAL


int
vtkTransformTextureCoords::GetFlipT()
		CODE:
		RETVAL = THIS->GetFlipT();
		OUTPUT:
		RETVAL


float  *
vtkTransformTextureCoords::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTransformTextureCoords::GetPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkTransformTextureCoords::GetScale()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScale();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkTransformTextureCoords*
vtkTransformTextureCoords::New()
		CODE:
		RETVAL = vtkTransformTextureCoords::New();
		OUTPUT:
		RETVAL


void
vtkTransformTextureCoords::SetFlipR(arg1)
		int 	arg1
		CODE:
		THIS->SetFlipR(arg1);
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::SetFlipS(arg1)
		int 	arg1
		CODE:
		THIS->SetFlipS(arg1);
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::SetFlipT(arg1)
		int 	arg1
		CODE:
		THIS->SetFlipT(arg1);
		XSRETURN_EMPTY;


void
vtkTransformTextureCoords::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformTextureCoords::SetOrigin\n");



void
vtkTransformTextureCoords::SetPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformTextureCoords::SetPosition\n");



void
vtkTransformTextureCoords::SetScale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetScale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformTextureCoords::SetScale\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TriangleFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTriangleFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkTriangleFilter::GetPassLines()
		CODE:
		RETVAL = THIS->GetPassLines();
		OUTPUT:
		RETVAL


int
vtkTriangleFilter::GetPassVerts()
		CODE:
		RETVAL = THIS->GetPassVerts();
		OUTPUT:
		RETVAL


static vtkTriangleFilter*
vtkTriangleFilter::New()
		CODE:
		RETVAL = vtkTriangleFilter::New();
		OUTPUT:
		RETVAL


void
vtkTriangleFilter::PassLinesOff()
		CODE:
		THIS->PassLinesOff();
		XSRETURN_EMPTY;


void
vtkTriangleFilter::PassLinesOn()
		CODE:
		THIS->PassLinesOn();
		XSRETURN_EMPTY;


void
vtkTriangleFilter::PassVertsOff()
		CODE:
		THIS->PassVertsOff();
		XSRETURN_EMPTY;


void
vtkTriangleFilter::PassVertsOn()
		CODE:
		THIS->PassVertsOn();
		XSRETURN_EMPTY;


void
vtkTriangleFilter::SetPassLines(arg1)
		int 	arg1
		CODE:
		THIS->SetPassLines(arg1);
		XSRETURN_EMPTY;


void
vtkTriangleFilter::SetPassVerts(arg1)
		int 	arg1
		CODE:
		THIS->SetPassVerts(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TriangularTCoords PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTriangularTCoords::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkTriangularTCoords*
vtkTriangularTCoords::New()
		CODE:
		RETVAL = vtkTriangularTCoords::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::TubeFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTubeFilter::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkTubeFilter::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


int
vtkTubeFilter::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkTubeFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkTubeFilter::GetDefaultNormal()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDefaultNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkTubeFilter::GetNumberOfSides()
		CODE:
		RETVAL = THIS->GetNumberOfSides();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetNumberOfSidesMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfSidesMaxValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetNumberOfSidesMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfSidesMinValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetOnRatio()
		CODE:
		RETVAL = THIS->GetOnRatio();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetOnRatioMaxValue()
		CODE:
		RETVAL = THIS->GetOnRatioMaxValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetOnRatioMinValue()
		CODE:
		RETVAL = THIS->GetOnRatioMinValue();
		OUTPUT:
		RETVAL


float
vtkTubeFilter::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkTubeFilter::GetRadiusFactor()
		CODE:
		RETVAL = THIS->GetRadiusFactor();
		OUTPUT:
		RETVAL


float
vtkTubeFilter::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkTubeFilter::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetUseDefaultNormal()
		CODE:
		RETVAL = THIS->GetUseDefaultNormal();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetVaryRadius()
		CODE:
		RETVAL = THIS->GetVaryRadius();
		OUTPUT:
		RETVAL


const char *
vtkTubeFilter::GetVaryRadiusAsString()
		CODE:
		RETVAL = THIS->GetVaryRadiusAsString();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetVaryRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetVaryRadiusMaxValue();
		OUTPUT:
		RETVAL


int
vtkTubeFilter::GetVaryRadiusMinValue()
		CODE:
		RETVAL = THIS->GetVaryRadiusMinValue();
		OUTPUT:
		RETVAL


static vtkTubeFilter*
vtkTubeFilter::New()
		CODE:
		RETVAL = vtkTubeFilter::New();
		OUTPUT:
		RETVAL


void
vtkTubeFilter::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetDefaultNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDefaultNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTubeFilter::SetDefaultNormal\n");



void
vtkTubeFilter::SetNumberOfSides(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfSides(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetOffset(arg1)
		int 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetOnRatio(arg1)
		int 	arg1
		CODE:
		THIS->SetOnRatio(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetRadiusFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetRadiusFactor(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetUseDefaultNormal(arg1)
		int 	arg1
		CODE:
		THIS->SetUseDefaultNormal(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetVaryRadius(arg1)
		int 	arg1
		CODE:
		THIS->SetVaryRadius(arg1);
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetVaryRadiusToVaryRadiusByScalar()
		CODE:
		THIS->SetVaryRadiusToVaryRadiusByScalar();
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetVaryRadiusToVaryRadiusByVector()
		CODE:
		THIS->SetVaryRadiusToVaryRadiusByVector();
		XSRETURN_EMPTY;


void
vtkTubeFilter::SetVaryRadiusToVaryRadiusOff()
		CODE:
		THIS->SetVaryRadiusToVaryRadiusOff();
		XSRETURN_EMPTY;


void
vtkTubeFilter::UseDefaultNormalOff()
		CODE:
		THIS->UseDefaultNormalOff();
		XSRETURN_EMPTY;


void
vtkTubeFilter::UseDefaultNormalOn()
		CODE:
		THIS->UseDefaultNormalOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::VectorDot PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVectorDot::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkVectorDot::GetScalarRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkVectorDot*
vtkVectorDot::New()
		CODE:
		RETVAL = vtkVectorDot::New();
		OUTPUT:
		RETVAL


void
vtkVectorDot::SetScalarRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetScalarRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVectorDot::SetScalarRange\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::VectorNorm PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkVectorNorm::GetAttributeMode()
		CODE:
		RETVAL = THIS->GetAttributeMode();
		OUTPUT:
		RETVAL


const char *
vtkVectorNorm::GetAttributeModeAsString()
		CODE:
		RETVAL = THIS->GetAttributeModeAsString();
		OUTPUT:
		RETVAL


const char *
vtkVectorNorm::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVectorNorm::GetNormalize()
		CODE:
		RETVAL = THIS->GetNormalize();
		OUTPUT:
		RETVAL


static vtkVectorNorm*
vtkVectorNorm::New()
		CODE:
		RETVAL = vtkVectorNorm::New();
		OUTPUT:
		RETVAL


void
vtkVectorNorm::NormalizeOff()
		CODE:
		THIS->NormalizeOff();
		XSRETURN_EMPTY;


void
vtkVectorNorm::NormalizeOn()
		CODE:
		THIS->NormalizeOn();
		XSRETURN_EMPTY;


void
vtkVectorNorm::SetAttributeMode(arg1)
		int 	arg1
		CODE:
		THIS->SetAttributeMode(arg1);
		XSRETURN_EMPTY;


void
vtkVectorNorm::SetAttributeModeToDefault()
		CODE:
		THIS->SetAttributeModeToDefault();
		XSRETURN_EMPTY;


void
vtkVectorNorm::SetAttributeModeToUseCellData()
		CODE:
		THIS->SetAttributeModeToUseCellData();
		XSRETURN_EMPTY;


void
vtkVectorNorm::SetAttributeModeToUsePointData()
		CODE:
		THIS->SetAttributeModeToUsePointData();
		XSRETURN_EMPTY;


void
vtkVectorNorm::SetNormalize(arg1)
		int 	arg1
		CODE:
		THIS->SetNormalize(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::VoxelContoursToSurfaceFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVoxelContoursToSurfaceFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVoxelContoursToSurfaceFilter::GetMemoryLimitInBytes()
		CODE:
		RETVAL = THIS->GetMemoryLimitInBytes();
		OUTPUT:
		RETVAL


float  *
vtkVoxelContoursToSurfaceFilter::GetSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkVoxelContoursToSurfaceFilter*
vtkVoxelContoursToSurfaceFilter::New()
		CODE:
		RETVAL = vtkVoxelContoursToSurfaceFilter::New();
		OUTPUT:
		RETVAL


void
vtkVoxelContoursToSurfaceFilter::SetMemoryLimitInBytes(arg1)
		int 	arg1
		CODE:
		THIS->SetMemoryLimitInBytes(arg1);
		XSRETURN_EMPTY;


void
vtkVoxelContoursToSurfaceFilter::SetSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVoxelContoursToSurfaceFilter::SetSpacing\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::WarpLens PREFIX = vtk

PROTOTYPES: DISABLE



float *
vtkWarpLens::GetCenter()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


const char *
vtkWarpLens::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetFormatHeight()
		CODE:
		RETVAL = THIS->GetFormatHeight();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetFormatWidth()
		CODE:
		RETVAL = THIS->GetFormatWidth();
		OUTPUT:
		RETVAL


int
vtkWarpLens::GetImageHeight()
		CODE:
		RETVAL = THIS->GetImageHeight();
		OUTPUT:
		RETVAL


int
vtkWarpLens::GetImageWidth()
		CODE:
		RETVAL = THIS->GetImageWidth();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetK1()
		CODE:
		RETVAL = THIS->GetK1();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetK2()
		CODE:
		RETVAL = THIS->GetK2();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetKappa()
		CODE:
		RETVAL = THIS->GetKappa();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetP1()
		CODE:
		RETVAL = THIS->GetP1();
		OUTPUT:
		RETVAL


float
vtkWarpLens::GetP2()
		CODE:
		RETVAL = THIS->GetP2();
		OUTPUT:
		RETVAL


float  *
vtkWarpLens::GetPrincipalPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPrincipalPoint();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkWarpLens*
vtkWarpLens::New()
		CODE:
		RETVAL = vtkWarpLens::New();
		OUTPUT:
		RETVAL


void
vtkWarpLens::SetCenter(centerX, centerY)
		float 	centerX
		float 	centerY
		CODE:
		THIS->SetCenter(centerX, centerY);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetFormatHeight(arg1)
		float 	arg1
		CODE:
		THIS->SetFormatHeight(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetFormatWidth(arg1)
		float 	arg1
		CODE:
		THIS->SetFormatWidth(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetImageHeight(arg1)
		int 	arg1
		CODE:
		THIS->SetImageHeight(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetImageWidth(arg1)
		int 	arg1
		CODE:
		THIS->SetImageWidth(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetK1(arg1)
		float 	arg1
		CODE:
		THIS->SetK1(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetK2(arg1)
		float 	arg1
		CODE:
		THIS->SetK2(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetKappa(kappa)
		float 	kappa
		CODE:
		THIS->SetKappa(kappa);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetP1(arg1)
		float 	arg1
		CODE:
		THIS->SetP1(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetP2(arg1)
		float 	arg1
		CODE:
		THIS->SetP2(arg1);
		XSRETURN_EMPTY;


void
vtkWarpLens::SetPrincipalPoint(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetPrincipalPoint(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWarpLens::SetPrincipalPoint\n");


MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::WarpScalar PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWarpScalar::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkWarpScalar::GetNormal()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkWarpScalar::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


int
vtkWarpScalar::GetUseNormal()
		CODE:
		RETVAL = THIS->GetUseNormal();
		OUTPUT:
		RETVAL


int
vtkWarpScalar::GetXYPlane()
		CODE:
		RETVAL = THIS->GetXYPlane();
		OUTPUT:
		RETVAL


static vtkWarpScalar*
vtkWarpScalar::New()
		CODE:
		RETVAL = vtkWarpScalar::New();
		OUTPUT:
		RETVAL


void
vtkWarpScalar::SetNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWarpScalar::SetNormal\n");



void
vtkWarpScalar::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkWarpScalar::SetUseNormal(arg1)
		int 	arg1
		CODE:
		THIS->SetUseNormal(arg1);
		XSRETURN_EMPTY;


void
vtkWarpScalar::SetXYPlane(arg1)
		int 	arg1
		CODE:
		THIS->SetXYPlane(arg1);
		XSRETURN_EMPTY;


void
vtkWarpScalar::UseNormalOff()
		CODE:
		THIS->UseNormalOff();
		XSRETURN_EMPTY;


void
vtkWarpScalar::UseNormalOn()
		CODE:
		THIS->UseNormalOn();
		XSRETURN_EMPTY;


void
vtkWarpScalar::XYPlaneOff()
		CODE:
		THIS->XYPlaneOff();
		XSRETURN_EMPTY;


void
vtkWarpScalar::XYPlaneOn()
		CODE:
		THIS->XYPlaneOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::WarpTo PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWarpTo::AbsoluteOff()
		CODE:
		THIS->AbsoluteOff();
		XSRETURN_EMPTY;


void
vtkWarpTo::AbsoluteOn()
		CODE:
		THIS->AbsoluteOn();
		XSRETURN_EMPTY;


int
vtkWarpTo::GetAbsolute()
		CODE:
		RETVAL = THIS->GetAbsolute();
		OUTPUT:
		RETVAL


const char *
vtkWarpTo::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkWarpTo::GetPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkWarpTo::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


static vtkWarpTo*
vtkWarpTo::New()
		CODE:
		RETVAL = vtkWarpTo::New();
		OUTPUT:
		RETVAL


void
vtkWarpTo::SetAbsolute(arg1)
		int 	arg1
		CODE:
		THIS->SetAbsolute(arg1);
		XSRETURN_EMPTY;


void
vtkWarpTo::SetPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWarpTo::SetPosition\n");



void
vtkWarpTo::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::WarpVector PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWarpVector::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkWarpVector::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


static vtkWarpVector*
vtkWarpVector::New()
		CODE:
		RETVAL = vtkWarpVector::New();
		OUTPUT:
		RETVAL


void
vtkWarpVector::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Graphics	PACKAGE = Graphics::VTK::WindowedSincPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWindowedSincPolyDataFilter::BoundarySmoothingOff()
		CODE:
		THIS->BoundarySmoothingOff();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::BoundarySmoothingOn()
		CODE:
		THIS->BoundarySmoothingOn();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::FeatureEdgeSmoothingOff()
		CODE:
		THIS->FeatureEdgeSmoothingOff();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::FeatureEdgeSmoothingOn()
		CODE:
		THIS->FeatureEdgeSmoothingOn();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::GenerateErrorScalarsOff()
		CODE:
		THIS->GenerateErrorScalarsOff();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::GenerateErrorScalarsOn()
		CODE:
		THIS->GenerateErrorScalarsOn();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::GenerateErrorVectorsOff()
		CODE:
		THIS->GenerateErrorVectorsOff();
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::GenerateErrorVectorsOn()
		CODE:
		THIS->GenerateErrorVectorsOn();
		XSRETURN_EMPTY;


int
vtkWindowedSincPolyDataFilter::GetBoundarySmoothing()
		CODE:
		RETVAL = THIS->GetBoundarySmoothing();
		OUTPUT:
		RETVAL


const char *
vtkWindowedSincPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetEdgeAngle()
		CODE:
		RETVAL = THIS->GetEdgeAngle();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetEdgeAngleMaxValue()
		CODE:
		RETVAL = THIS->GetEdgeAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetEdgeAngleMinValue()
		CODE:
		RETVAL = THIS->GetEdgeAngleMinValue();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetFeatureAngle()
		CODE:
		RETVAL = THIS->GetFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleMinValue();
		OUTPUT:
		RETVAL


int
vtkWindowedSincPolyDataFilter::GetFeatureEdgeSmoothing()
		CODE:
		RETVAL = THIS->GetFeatureEdgeSmoothing();
		OUTPUT:
		RETVAL


int
vtkWindowedSincPolyDataFilter::GetGenerateErrorScalars()
		CODE:
		RETVAL = THIS->GetGenerateErrorScalars();
		OUTPUT:
		RETVAL


int
vtkWindowedSincPolyDataFilter::GetGenerateErrorVectors()
		CODE:
		RETVAL = THIS->GetGenerateErrorVectors();
		OUTPUT:
		RETVAL


int
vtkWindowedSincPolyDataFilter::GetNumberOfIterations()
		CODE:
		RETVAL = THIS->GetNumberOfIterations();
		OUTPUT:
		RETVAL


int
vtkWindowedSincPolyDataFilter::GetNumberOfIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfIterationsMaxValue();
		OUTPUT:
		RETVAL


int
vtkWindowedSincPolyDataFilter::GetNumberOfIterationsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfIterationsMinValue();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetPassBand()
		CODE:
		RETVAL = THIS->GetPassBand();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetPassBandMaxValue()
		CODE:
		RETVAL = THIS->GetPassBandMaxValue();
		OUTPUT:
		RETVAL


float
vtkWindowedSincPolyDataFilter::GetPassBandMinValue()
		CODE:
		RETVAL = THIS->GetPassBandMinValue();
		OUTPUT:
		RETVAL


static vtkWindowedSincPolyDataFilter*
vtkWindowedSincPolyDataFilter::New()
		CODE:
		RETVAL = vtkWindowedSincPolyDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkWindowedSincPolyDataFilter::SetBoundarySmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundarySmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetEdgeAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetEdgeAngle(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetFeatureEdgeSmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetFeatureEdgeSmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetGenerateErrorScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateErrorScalars(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetGenerateErrorVectors(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateErrorVectors(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetNumberOfIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfIterations(arg1);
		XSRETURN_EMPTY;


void
vtkWindowedSincPolyDataFilter::SetPassBand(arg1)
		float 	arg1
		CODE:
		THIS->SetPassBand(arg1);
		XSRETURN_EMPTY;


