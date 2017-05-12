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
#include "vtkCardinalSpline.h"
#include "vtkCastToConcrete.h"
#include "vtkCellLocator.h"
#include "vtkColorTransferFunction.h"
#include "vtkCone.h"
#include "vtkCylinder.h"
#include "vtkDataObjectSource.h"
#include "vtkDataSetSource.h"
#include "vtkDataSetToDataSetFilter.h"
#include "vtkDataSetToPolyDataFilter.h"
#include "vtkDataSetToStructuredGridFilter.h"
#include "vtkDataSetToStructuredPointsFilter.h"
#include "vtkDataSetToUnstructuredGridFilter.h"
#include "vtkImageInPlaceFilter.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkImageMultipleInputOutputFilter.h"
#include "vtkImageSource.h"
#include "vtkImageToImageFilter.h"
#include "vtkImageToStructuredPoints.h"
#include "vtkImageTwoInputFilter.h"
#include "vtkImplicitBoolean.h"
#include "vtkImplicitDataSet.h"
#include "vtkImplicitSelectionLoop.h"
#include "vtkImplicitVolume.h"
#include "vtkImplicitWindowFunction.h"
#include "vtkKochanekSpline.h"
#include "vtkMergePoints.h"
#include "vtkMergePoints2D.h"
#include "vtkPiecewiseFunction.h"
#include "vtkPointSetSource.h"
#include "vtkPointSetToPointSetFilter.h"
#include "vtkPolyDataCollection.h"
#include "vtkPolyDataSource.h"
#include "vtkPolyDataToPolyDataFilter.h"
#include "vtkRectilinearGridSource.h"
#include "vtkRectilinearGridToPolyDataFilter.h"
#include "vtkScalarTree.h"
#include "vtkSimpleImageToImageFilter.h"
#include "vtkSphere.h"
#include "vtkSpline.h"
#include "vtkStructuredGridSource.h"
#include "vtkStructuredGridToPolyDataFilter.h"
#include "vtkStructuredGridToStructuredGridFilter.h"
#include "vtkStructuredPointsCollection.h"
#include "vtkStructuredPointsSource.h"
#include "vtkStructuredPointsToPolyDataFilter.h"
#include "vtkStructuredPointsToStructuredPointsFilter.h"
#include "vtkStructuredPointsToUnstructuredGridFilter.h"
#include "vtkSuperquadric.h"
#include "vtkUnstructuredGridSource.h"
#include "vtkUnstructuredGridToPolyDataFilter.h"
#include "vtkUnstructuredGridToUnstructuredGridFilter.h"
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

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::CardinalSpline PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCardinalSpline::Compute()
		CODE:
		THIS->Compute();
		XSRETURN_EMPTY;


float
vtkCardinalSpline::Evaluate(t)
		float 	t
		CODE:
		RETVAL = THIS->Evaluate(t);
		OUTPUT:
		RETVAL


const char *
vtkCardinalSpline::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkCardinalSpline*
vtkCardinalSpline::New()
		CODE:
		RETVAL = vtkCardinalSpline::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::CastToConcrete PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCastToConcrete::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkCastToConcrete*
vtkCastToConcrete::New()
		CODE:
		RETVAL = vtkCastToConcrete::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::CellLocator PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCellLocator::BuildLocator()
		CODE:
		THIS->BuildLocator();
		XSRETURN_EMPTY;


void
vtkCellLocator::CacheCellBoundsOff()
		CODE:
		THIS->CacheCellBoundsOff();
		XSRETURN_EMPTY;


void
vtkCellLocator::CacheCellBoundsOn()
		CODE:
		THIS->CacheCellBoundsOn();
		XSRETURN_EMPTY;


void
vtkCellLocator::FreeSearchStructure()
		CODE:
		THIS->FreeSearchStructure();
		XSRETURN_EMPTY;


void
vtkCellLocator::GenerateRepresentation(level, pd)
		int 	level
		vtkPolyData *	pd
		CODE:
		THIS->GenerateRepresentation(level, pd);
		XSRETURN_EMPTY;


int
vtkCellLocator::GetCacheCellBounds()
		CODE:
		RETVAL = THIS->GetCacheCellBounds();
		OUTPUT:
		RETVAL


vtkIdList *
vtkCellLocator::GetCells(bucket)
		int 	bucket
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkIdList";
		CODE:
		RETVAL = THIS->GetCells(bucket);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkCellLocator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCellLocator::GetNumberOfBuckets()
		CODE:
		RETVAL = THIS->GetNumberOfBuckets();
		OUTPUT:
		RETVAL


int
vtkCellLocator::GetNumberOfCellsPerBucket()
		CODE:
		RETVAL = THIS->GetNumberOfCellsPerBucket();
		OUTPUT:
		RETVAL


int
vtkCellLocator::GetNumberOfCellsPerBucketMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfCellsPerBucketMaxValue();
		OUTPUT:
		RETVAL


int
vtkCellLocator::GetNumberOfCellsPerBucketMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfCellsPerBucketMinValue();
		OUTPUT:
		RETVAL


static vtkCellLocator*
vtkCellLocator::New()
		CODE:
		RETVAL = vtkCellLocator::New();
		OUTPUT:
		RETVAL


void
vtkCellLocator::SetCacheCellBounds(arg1)
		int 	arg1
		CODE:
		THIS->SetCacheCellBounds(arg1);
		XSRETURN_EMPTY;


void
vtkCellLocator::SetNumberOfCellsPerBucket(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfCellsPerBucket(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ColorTransferFunction PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkColorTransferFunction::AddHSVPoint(x, h, s, v)
		float 	x
		float 	h
		float 	s
		float 	v
		CODE:
		THIS->AddHSVPoint(x, h, s, v);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::AddHSVSegment(x1, h1, s1, v1, x2, h2, s2, v2)
		float 	x1
		float 	h1
		float 	s1
		float 	v1
		float 	x2
		float 	h2
		float 	s2
		float 	v2
		CODE:
		THIS->AddHSVSegment(x1, h1, s1, v1, x2, h2, s2, v2);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::AddRGBPoint(x, r, g, b)
		float 	x
		float 	r
		float 	g
		float 	b
		CODE:
		THIS->AddRGBPoint(x, r, g, b);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::AddRGBSegment(x1, r1, g1, b1, x2, r2, g2, b2)
		float 	x1
		float 	r1
		float 	g1
		float 	b1
		float 	x2
		float 	r2
		float 	g2
		float 	b2
		CODE:
		THIS->AddRGBSegment(x1, r1, g1, b1, x2, r2, g2, b2);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::ClampingOff()
		CODE:
		THIS->ClampingOff();
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::ClampingOn()
		CODE:
		THIS->ClampingOn();
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::DeepCopy(f)
		vtkColorTransferFunction *	f
		CODE:
		THIS->DeepCopy(f);
		XSRETURN_EMPTY;


float
vtkColorTransferFunction::GetBlueValue(x)
		float 	x
		CODE:
		RETVAL = THIS->GetBlueValue(x);
		OUTPUT:
		RETVAL


int
vtkColorTransferFunction::GetClamping()
		CODE:
		RETVAL = THIS->GetClamping();
		OUTPUT:
		RETVAL


int
vtkColorTransferFunction::GetClampingMaxValue()
		CODE:
		RETVAL = THIS->GetClampingMaxValue();
		OUTPUT:
		RETVAL


int
vtkColorTransferFunction::GetClampingMinValue()
		CODE:
		RETVAL = THIS->GetClampingMinValue();
		OUTPUT:
		RETVAL


const char *
vtkColorTransferFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkColorTransferFunction::GetColor(arg1 = 0)
	CASE: items == 2
		float 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColor(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkColorTransferFunction::GetColor\n");



int
vtkColorTransferFunction::GetColorSpace()
		CODE:
		RETVAL = THIS->GetColorSpace();
		OUTPUT:
		RETVAL


int
vtkColorTransferFunction::GetColorSpaceMaxValue()
		CODE:
		RETVAL = THIS->GetColorSpaceMaxValue();
		OUTPUT:
		RETVAL


int
vtkColorTransferFunction::GetColorSpaceMinValue()
		CODE:
		RETVAL = THIS->GetColorSpaceMinValue();
		OUTPUT:
		RETVAL


float
vtkColorTransferFunction::GetGreenValue(x)
		float 	x
		CODE:
		RETVAL = THIS->GetGreenValue(x);
		OUTPUT:
		RETVAL


float  *
vtkColorTransferFunction::GetRange()
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
vtkColorTransferFunction::GetRedValue(x)
		float 	x
		CODE:
		RETVAL = THIS->GetRedValue(x);
		OUTPUT:
		RETVAL


int
vtkColorTransferFunction::GetSize()
		CODE:
		RETVAL = THIS->GetSize();
		OUTPUT:
		RETVAL


static vtkColorTransferFunction*
vtkColorTransferFunction::New()
		CODE:
		RETVAL = vtkColorTransferFunction::New();
		OUTPUT:
		RETVAL


void
vtkColorTransferFunction::RemoveAllPoints()
		CODE:
		THIS->RemoveAllPoints();
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::RemovePoint(x)
		float 	x
		CODE:
		THIS->RemovePoint(x);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::SetClamping(arg1)
		int 	arg1
		CODE:
		THIS->SetClamping(arg1);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::SetColorSpace(arg1)
		int 	arg1
		CODE:
		THIS->SetColorSpace(arg1);
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::SetColorSpaceToHSV()
		CODE:
		THIS->SetColorSpaceToHSV();
		XSRETURN_EMPTY;


void
vtkColorTransferFunction::SetColorSpaceToRGB()
		CODE:
		THIS->SetColorSpaceToRGB();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::Cone PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkCone::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCone::EvaluateFunction\n");



float
vtkCone::GetAngle()
		CODE:
		RETVAL = THIS->GetAngle();
		OUTPUT:
		RETVAL


float
vtkCone::GetAngleMaxValue()
		CODE:
		RETVAL = THIS->GetAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkCone::GetAngleMinValue()
		CODE:
		RETVAL = THIS->GetAngleMinValue();
		OUTPUT:
		RETVAL


const char *
vtkCone::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkCone*
vtkCone::New()
		CODE:
		RETVAL = vtkCone::New();
		OUTPUT:
		RETVAL


void
vtkCone::SetAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetAngle(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::Cylinder PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkCylinder::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCylinder::EvaluateFunction\n");



float  *
vtkCylinder::GetCenter()
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
vtkCylinder::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkCylinder::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


static vtkCylinder*
vtkCylinder::New()
		CODE:
		RETVAL = vtkCylinder::New();
		OUTPUT:
		RETVAL


void
vtkCylinder::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCylinder::SetCenter\n");



void
vtkCylinder::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataObjectSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataObjectSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkDataObjectSource::GetOutput(arg1 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkDataObjectSource::GetOutput\n");



static vtkDataObjectSource*
vtkDataObjectSource::New()
		CODE:
		RETVAL = vtkDataObjectSource::New();
		OUTPUT:
		RETVAL


void
vtkDataObjectSource::SetOutput(arg1)
		vtkDataObject *	arg1
		CODE:
		THIS->SetOutput(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataSetSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetSource::GetOutput(arg1 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkDataSetSource::GetOutput\n");



static vtkDataSetSource*
vtkDataSetSource::New()
		CODE:
		RETVAL = vtkDataSetSource::New();
		OUTPUT:
		RETVAL


void
vtkDataSetSource::SetOutput(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetOutput(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataSetToDataSetFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataSetToDataSetFilter::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


const char *
vtkDataSetToDataSetFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetToDataSetFilter::GetInput()
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
vtkDataSetToDataSetFilter::GetOutput(arg1 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkDataSetToDataSetFilter::GetOutput\n");



vtkPolyData *
vtkDataSetToDataSetFilter::GetPolyDataOutput()
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
vtkDataSetToDataSetFilter::GetRectilinearGridOutput()
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
vtkDataSetToDataSetFilter::GetStructuredGridOutput()
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
vtkDataSetToDataSetFilter::GetStructuredPointsOutput()
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
vtkDataSetToDataSetFilter::GetUnstructuredGridOutput()
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


void
vtkDataSetToDataSetFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataSetToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataSetToPolyDataFilter::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


const char *
vtkDataSetToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetToPolyDataFilter::GetInput()
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


void
vtkDataSetToPolyDataFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataSetToStructuredGridFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetToStructuredGridFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetToStructuredGridFilter::GetInput()
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


void
vtkDataSetToStructuredGridFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataSetToStructuredPointsFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetToStructuredPointsFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetToStructuredPointsFilter::GetInput()
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


void
vtkDataSetToStructuredPointsFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::DataSetToUnstructuredGridFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetToUnstructuredGridFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetToUnstructuredGridFilter::GetInput()
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


void
vtkDataSetToUnstructuredGridFilter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageInPlaceFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageInPlaceFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageInPlaceFilter*
vtkImageInPlaceFilter::New()
		CODE:
		RETVAL = vtkImageInPlaceFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageMultipleInputFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageMultipleInputFilter::AddInput(arg1 = 0)
	CASE: items == 2
		vtkImageData *	arg1
		CODE:
		THIS->AddInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMultipleInputFilter::AddInput\n");



void
vtkImageMultipleInputFilter::BypassOff()
		CODE:
		THIS->BypassOff();
		XSRETURN_EMPTY;


void
vtkImageMultipleInputFilter::BypassOn()
		CODE:
		THIS->BypassOn();
		XSRETURN_EMPTY;


int
vtkImageMultipleInputFilter::GetBypass()
		CODE:
		RETVAL = THIS->GetBypass();
		OUTPUT:
		RETVAL


const char *
vtkImageMultipleInputFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageMultipleInputFilter::GetInput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
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
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
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
		croak("Unsupported number of args and/or types supplied to vtkImageMultipleInputFilter::GetInput\n");



int
vtkImageMultipleInputFilter::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkImageMultipleInputFilter::GetNumberOfThreadsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageMultipleInputFilter::GetNumberOfThreadsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMinValue();
		OUTPUT:
		RETVAL


static vtkImageMultipleInputFilter*
vtkImageMultipleInputFilter::New()
		CODE:
		RETVAL = vtkImageMultipleInputFilter::New();
		OUTPUT:
		RETVAL


void
vtkImageMultipleInputFilter::RemoveInput(arg1 = 0)
	CASE: items == 2
		vtkImageData *	arg1
		CODE:
		THIS->RemoveInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMultipleInputFilter::RemoveInput\n");



void
vtkImageMultipleInputFilter::SetBypass(arg1)
		int 	arg1
		CODE:
		THIS->SetBypass(arg1);
		XSRETURN_EMPTY;


void
vtkImageMultipleInputFilter::SetInput(num, input)
		int 	num
		vtkImageData *	input
		CODE:
		THIS->SetInput(num, input);
		XSRETURN_EMPTY;


void
vtkImageMultipleInputFilter::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageMultipleInputOutputFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMultipleInputOutputFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageMultipleInputOutputFilter::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
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
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
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
		croak("Unsupported number of args and/or types supplied to vtkImageMultipleInputOutputFilter::GetOutput\n");



static vtkImageMultipleInputOutputFilter*
vtkImageMultipleInputOutputFilter::New()
		CODE:
		RETVAL = vtkImageMultipleInputOutputFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
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
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
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
		croak("Unsupported number of args and/or types supplied to vtkImageSource::GetOutput\n");



static vtkImageSource*
vtkImageSource::New()
		CODE:
		RETVAL = vtkImageSource::New();
		OUTPUT:
		RETVAL


void
vtkImageSource::SetOutput(output)
		vtkImageData *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageToImageFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageToImageFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageToImageFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


long
vtkImageToImageFilter::GetInputMemoryLimit()
		CODE:
		RETVAL = THIS->GetInputMemoryLimit();
		OUTPUT:
		RETVAL


int
vtkImageToImageFilter::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkImageToImageFilter::GetNumberOfThreadsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageToImageFilter::GetNumberOfThreadsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMinValue();
		OUTPUT:
		RETVAL


static vtkImageToImageFilter*
vtkImageToImageFilter::New()
		CODE:
		RETVAL = vtkImageToImageFilter::New();
		OUTPUT:
		RETVAL


void
vtkImageToImageFilter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkImageToImageFilter::SetInputMemoryLimit(arg1)
		int 	arg1
		CODE:
		THIS->SetInputMemoryLimit(arg1);
		XSRETURN_EMPTY;


void
vtkImageToImageFilter::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageToStructuredPoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageToStructuredPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageToStructuredPoints::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkImageToStructuredPoints::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
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
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
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
		croak("Unsupported number of args and/or types supplied to vtkImageToStructuredPoints::GetOutput\n");



vtkImageData *
vtkImageToStructuredPoints::GetVectorInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetVectorInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageToStructuredPoints*
vtkImageToStructuredPoints::New()
		CODE:
		RETVAL = vtkImageToStructuredPoints::New();
		OUTPUT:
		RETVAL


void
vtkImageToStructuredPoints::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkImageToStructuredPoints::SetVectorInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetVectorInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImageTwoInputFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageTwoInputFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageTwoInputFilter::GetInput1()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput1();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageTwoInputFilter::GetInput2()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput2();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageTwoInputFilter*
vtkImageTwoInputFilter::New()
		CODE:
		RETVAL = vtkImageTwoInputFilter::New();
		OUTPUT:
		RETVAL


void
vtkImageTwoInputFilter::SetInput1(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput1(input);
		XSRETURN_EMPTY;


void
vtkImageTwoInputFilter::SetInput2(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput2(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImplicitBoolean PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImplicitBoolean::AddFunction(in)
		vtkImplicitFunction *	in
		CODE:
		THIS->AddFunction(in);
		XSRETURN_EMPTY;


float
vtkImplicitBoolean::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitBoolean::EvaluateFunction\n");



const char *
vtkImplicitBoolean::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunctionCollection *
vtkImplicitBoolean::GetFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunctionCollection";
		CODE:
		RETVAL = THIS->GetFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkImplicitBoolean::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkImplicitBoolean::GetOperationType()
		CODE:
		RETVAL = THIS->GetOperationType();
		OUTPUT:
		RETVAL


const char *
vtkImplicitBoolean::GetOperationTypeAsString()
		CODE:
		RETVAL = THIS->GetOperationTypeAsString();
		OUTPUT:
		RETVAL


int
vtkImplicitBoolean::GetOperationTypeMaxValue()
		CODE:
		RETVAL = THIS->GetOperationTypeMaxValue();
		OUTPUT:
		RETVAL


int
vtkImplicitBoolean::GetOperationTypeMinValue()
		CODE:
		RETVAL = THIS->GetOperationTypeMinValue();
		OUTPUT:
		RETVAL


static vtkImplicitBoolean*
vtkImplicitBoolean::New()
		CODE:
		RETVAL = vtkImplicitBoolean::New();
		OUTPUT:
		RETVAL


void
vtkImplicitBoolean::RemoveFunction(in)
		vtkImplicitFunction *	in
		CODE:
		THIS->RemoveFunction(in);
		XSRETURN_EMPTY;


void
vtkImplicitBoolean::SetOperationType(arg1)
		int 	arg1
		CODE:
		THIS->SetOperationType(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitBoolean::SetOperationTypeToDifference()
		CODE:
		THIS->SetOperationTypeToDifference();
		XSRETURN_EMPTY;


void
vtkImplicitBoolean::SetOperationTypeToIntersection()
		CODE:
		THIS->SetOperationTypeToIntersection();
		XSRETURN_EMPTY;


void
vtkImplicitBoolean::SetOperationTypeToUnion()
		CODE:
		THIS->SetOperationTypeToUnion();
		XSRETURN_EMPTY;


void
vtkImplicitBoolean::SetOperationTypeToUnionOfMagnitudes()
		CODE:
		THIS->SetOperationTypeToUnionOfMagnitudes();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImplicitDataSet PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImplicitDataSet::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitDataSet::EvaluateFunction\n");



const char *
vtkImplicitDataSet::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkImplicitDataSet::GetDataSet()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetDataSet();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkImplicitDataSet::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float  *
vtkImplicitDataSet::GetOutGradient()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutGradient();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkImplicitDataSet::GetOutValue()
		CODE:
		RETVAL = THIS->GetOutValue();
		OUTPUT:
		RETVAL


static vtkImplicitDataSet*
vtkImplicitDataSet::New()
		CODE:
		RETVAL = vtkImplicitDataSet::New();
		OUTPUT:
		RETVAL


void
vtkImplicitDataSet::SetDataSet(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetDataSet(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitDataSet::SetOutGradient(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutGradient(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitDataSet::SetOutGradient\n");



void
vtkImplicitDataSet::SetOutValue(arg1)
		float 	arg1
		CODE:
		THIS->SetOutValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImplicitSelectionLoop PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImplicitSelectionLoop::AutomaticNormalGenerationOff()
		CODE:
		THIS->AutomaticNormalGenerationOff();
		XSRETURN_EMPTY;


void
vtkImplicitSelectionLoop::AutomaticNormalGenerationOn()
		CODE:
		THIS->AutomaticNormalGenerationOn();
		XSRETURN_EMPTY;


float
vtkImplicitSelectionLoop::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitSelectionLoop::EvaluateFunction\n");



int
vtkImplicitSelectionLoop::GetAutomaticNormalGeneration()
		CODE:
		RETVAL = THIS->GetAutomaticNormalGeneration();
		OUTPUT:
		RETVAL


const char *
vtkImplicitSelectionLoop::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPoints *
vtkImplicitSelectionLoop::GetLoop()
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
vtkImplicitSelectionLoop::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float  *
vtkImplicitSelectionLoop::GetNormal()
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


static vtkImplicitSelectionLoop*
vtkImplicitSelectionLoop::New()
		CODE:
		RETVAL = vtkImplicitSelectionLoop::New();
		OUTPUT:
		RETVAL


void
vtkImplicitSelectionLoop::SetAutomaticNormalGeneration(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticNormalGeneration(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitSelectionLoop::SetLoop(arg1)
		vtkPoints *	arg1
		CODE:
		THIS->SetLoop(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitSelectionLoop::SetNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitSelectionLoop::SetNormal\n");


MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImplicitVolume PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImplicitVolume::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitVolume::EvaluateFunction\n");



const char *
vtkImplicitVolume::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkImplicitVolume::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float  *
vtkImplicitVolume::GetOutGradient()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutGradient();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkImplicitVolume::GetOutValue()
		CODE:
		RETVAL = THIS->GetOutValue();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImplicitVolume::GetVolume()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetVolume();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImplicitVolume*
vtkImplicitVolume::New()
		CODE:
		RETVAL = vtkImplicitVolume::New();
		OUTPUT:
		RETVAL


void
vtkImplicitVolume::SetOutGradient(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutGradient(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitVolume::SetOutGradient\n");



void
vtkImplicitVolume::SetOutValue(arg1)
		float 	arg1
		CODE:
		THIS->SetOutValue(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitVolume::SetVolume(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetVolume(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ImplicitWindowFunction PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImplicitWindowFunction::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitWindowFunction::EvaluateFunction\n");



const char *
vtkImplicitWindowFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkImplicitWindowFunction::GetImplicitFunction()
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
vtkImplicitWindowFunction::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float  *
vtkImplicitWindowFunction::GetWindowRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWindowRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkImplicitWindowFunction::GetWindowValues()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWindowValues();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkImplicitWindowFunction*
vtkImplicitWindowFunction::New()
		CODE:
		RETVAL = vtkImplicitWindowFunction::New();
		OUTPUT:
		RETVAL


void
vtkImplicitWindowFunction::SetImplicitFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetImplicitFunction(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitWindowFunction::SetWindowRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetWindowRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitWindowFunction::SetWindowRange\n");



void
vtkImplicitWindowFunction::SetWindowValues(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetWindowValues(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitWindowFunction::SetWindowValues\n");


MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::KochanekSpline PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkKochanekSpline::Compute()
		CODE:
		THIS->Compute();
		XSRETURN_EMPTY;


float
vtkKochanekSpline::Evaluate(t)
		float 	t
		CODE:
		RETVAL = THIS->Evaluate(t);
		OUTPUT:
		RETVAL


const char *
vtkKochanekSpline::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkKochanekSpline::GetDefaultBias()
		CODE:
		RETVAL = THIS->GetDefaultBias();
		OUTPUT:
		RETVAL


float
vtkKochanekSpline::GetDefaultContinuity()
		CODE:
		RETVAL = THIS->GetDefaultContinuity();
		OUTPUT:
		RETVAL


float
vtkKochanekSpline::GetDefaultTension()
		CODE:
		RETVAL = THIS->GetDefaultTension();
		OUTPUT:
		RETVAL


static vtkKochanekSpline*
vtkKochanekSpline::New()
		CODE:
		RETVAL = vtkKochanekSpline::New();
		OUTPUT:
		RETVAL


void
vtkKochanekSpline::SetDefaultBias(arg1)
		float 	arg1
		CODE:
		THIS->SetDefaultBias(arg1);
		XSRETURN_EMPTY;


void
vtkKochanekSpline::SetDefaultContinuity(arg1)
		float 	arg1
		CODE:
		THIS->SetDefaultContinuity(arg1);
		XSRETURN_EMPTY;


void
vtkKochanekSpline::SetDefaultTension(arg1)
		float 	arg1
		CODE:
		THIS->SetDefaultTension(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::MergePoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMergePoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


long
vtkMergePoints::IsInsertedPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->IsInsertedPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMergePoints::IsInsertedPoint\n");



static vtkMergePoints*
vtkMergePoints::New()
		CODE:
		RETVAL = vtkMergePoints::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::MergePoints2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMergePoints2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL



static vtkMergePoints2D*
vtkMergePoints2D::New()
		CODE:
		RETVAL = vtkMergePoints2D::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::PiecewiseFunction PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPiecewiseFunction::AddPoint(x, val)
		float 	x
		float 	val
		CODE:
		THIS->AddPoint(x, val);
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::AddSegment(x1, val1, x2, val2)
		float 	x1
		float 	val1
		float 	x2
		float 	val2
		CODE:
		THIS->AddSegment(x1, val1, x2, val2);
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::ClampingOff()
		CODE:
		THIS->ClampingOff();
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::ClampingOn()
		CODE:
		THIS->ClampingOn();
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::DeepCopy(f)
		vtkDataObject *	f
		CODE:
		THIS->DeepCopy(f);
		XSRETURN_EMPTY;


int
vtkPiecewiseFunction::GetClamping()
		CODE:
		RETVAL = THIS->GetClamping();
		OUTPUT:
		RETVAL


const char *
vtkPiecewiseFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPiecewiseFunction::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


float
vtkPiecewiseFunction::GetFirstNonZeroValue()
		CODE:
		RETVAL = THIS->GetFirstNonZeroValue();
		OUTPUT:
		RETVAL


unsigned long
vtkPiecewiseFunction::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float *
vtkPiecewiseFunction::GetRange()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkPiecewiseFunction::GetSize()
		CODE:
		RETVAL = THIS->GetSize();
		OUTPUT:
		RETVAL


const char *
vtkPiecewiseFunction::GetType()
		CODE:
		RETVAL = THIS->GetType();
		OUTPUT:
		RETVAL


float
vtkPiecewiseFunction::GetValue(x)
		float 	x
		CODE:
		RETVAL = THIS->GetValue(x);
		OUTPUT:
		RETVAL


void
vtkPiecewiseFunction::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


static vtkPiecewiseFunction*
vtkPiecewiseFunction::New()
		CODE:
		RETVAL = vtkPiecewiseFunction::New();
		OUTPUT:
		RETVAL


void
vtkPiecewiseFunction::RemoveAllPoints()
		CODE:
		THIS->RemoveAllPoints();
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::RemovePoint(x)
		float 	x
		CODE:
		THIS->RemovePoint(x);
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::SetClamping(arg1)
		int 	arg1
		CODE:
		THIS->SetClamping(arg1);
		XSRETURN_EMPTY;


void
vtkPiecewiseFunction::ShallowCopy(f)
		vtkDataObject *	f
		CODE:
		THIS->ShallowCopy(f);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::PointSetSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPointSetSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPointSet *
vtkPointSetSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointSet";
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
		char  CLASS[80] = "Graphics::VTK::vtkPointSet";
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
		croak("Unsupported number of args and/or types supplied to vtkPointSetSource::GetOutput\n");



static vtkPointSetSource*
vtkPointSetSource::New()
		CODE:
		RETVAL = vtkPointSetSource::New();
		OUTPUT:
		RETVAL


void
vtkPointSetSource::SetOutput(output)
		vtkPointSet *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::PointSetToPointSetFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPointSetToPointSetFilter::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


const char *
vtkPointSetToPointSetFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPointSet *
vtkPointSetToPointSetFilter::GetInput()
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


vtkPointSet *
vtkPointSetToPointSetFilter::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointSet";
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
		char  CLASS[80] = "Graphics::VTK::vtkPointSet";
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
		croak("Unsupported number of args and/or types supplied to vtkPointSetToPointSetFilter::GetOutput\n");



vtkPolyData *
vtkPointSetToPointSetFilter::GetPolyDataOutput()
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


vtkStructuredGrid *
vtkPointSetToPointSetFilter::GetStructuredGridOutput()
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


vtkUnstructuredGrid *
vtkPointSetToPointSetFilter::GetUnstructuredGridOutput()
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


void
vtkPointSetToPointSetFilter::SetInput(input)
		vtkPointSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::PolyDataCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyDataCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkPolyData *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyDataCollection::AddItem\n");



const char *
vtkPolyDataCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPolyDataCollection*
vtkPolyDataCollection::New()
		CODE:
		RETVAL = vtkPolyDataCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::PolyDataSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPolyDataSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataSource::GetOutput(arg1 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkPolyDataSource::GetOutput\n");



static vtkPolyDataSource*
vtkPolyDataSource::New()
		CODE:
		RETVAL = vtkPolyDataSource::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataSource::SetOutput(output)
		vtkPolyData *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::PolyDataToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPolyDataToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataToPolyDataFilter::GetInput()
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


void
vtkPolyDataToPolyDataFilter::SetInput(input)
		vtkPolyData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::RectilinearGridSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRectilinearGridSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkRectilinearGridSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
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
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
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
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGridSource::GetOutput\n");



static vtkRectilinearGridSource*
vtkRectilinearGridSource::New()
		CODE:
		RETVAL = vtkRectilinearGridSource::New();
		OUTPUT:
		RETVAL


void
vtkRectilinearGridSource::SetOutput(output)
		vtkRectilinearGrid *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::RectilinearGridToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRectilinearGridToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkRectilinearGridToPolyDataFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkRectilinearGridToPolyDataFilter::SetInput(input)
		vtkRectilinearGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::ScalarTree PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkScalarTree::BuildTree()
		CODE:
		THIS->BuildTree();
		XSRETURN_EMPTY;


int
vtkScalarTree::GetBranchingFactor()
		CODE:
		RETVAL = THIS->GetBranchingFactor();
		OUTPUT:
		RETVAL


int
vtkScalarTree::GetBranchingFactorMaxValue()
		CODE:
		RETVAL = THIS->GetBranchingFactorMaxValue();
		OUTPUT:
		RETVAL


int
vtkScalarTree::GetBranchingFactorMinValue()
		CODE:
		RETVAL = THIS->GetBranchingFactorMinValue();
		OUTPUT:
		RETVAL


const char *
vtkScalarTree::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkScalarTree::GetDataSet()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetDataSet();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkScalarTree::GetLevel()
		CODE:
		RETVAL = THIS->GetLevel();
		OUTPUT:
		RETVAL


int
vtkScalarTree::GetMaxLevel()
		CODE:
		RETVAL = THIS->GetMaxLevel();
		OUTPUT:
		RETVAL


int
vtkScalarTree::GetMaxLevelMaxValue()
		CODE:
		RETVAL = THIS->GetMaxLevelMaxValue();
		OUTPUT:
		RETVAL


int
vtkScalarTree::GetMaxLevelMinValue()
		CODE:
		RETVAL = THIS->GetMaxLevelMinValue();
		OUTPUT:
		RETVAL


void
vtkScalarTree::InitTraversal(scalarValue)
		float 	scalarValue
		CODE:
		THIS->InitTraversal(scalarValue);
		XSRETURN_EMPTY;


void
vtkScalarTree::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


static vtkScalarTree*
vtkScalarTree::New()
		CODE:
		RETVAL = vtkScalarTree::New();
		OUTPUT:
		RETVAL


void
vtkScalarTree::SetBranchingFactor(arg1)
		int 	arg1
		CODE:
		THIS->SetBranchingFactor(arg1);
		XSRETURN_EMPTY;


void
vtkScalarTree::SetDataSet(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetDataSet(arg1);
		XSRETURN_EMPTY;


void
vtkScalarTree::SetMaxLevel(arg1)
		int 	arg1
		CODE:
		THIS->SetMaxLevel(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::SimpleImageToImageFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSimpleImageToImageFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkSimpleImageToImageFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkSimpleImageToImageFilter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::Sphere PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkSphere::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSphere::EvaluateFunction\n");



float  *
vtkSphere::GetCenter()
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
vtkSphere::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkSphere::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


static vtkSphere*
vtkSphere::New()
		CODE:
		RETVAL = vtkSphere::New();
		OUTPUT:
		RETVAL


void
vtkSphere::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSphere::SetCenter\n");



void
vtkSphere::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::Spline PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSpline::AddPoint(t, x)
		float 	t
		float 	x
		CODE:
		THIS->AddPoint(t, x);
		XSRETURN_EMPTY;


void
vtkSpline::ClampValueOff()
		CODE:
		THIS->ClampValueOff();
		XSRETURN_EMPTY;


void
vtkSpline::ClampValueOn()
		CODE:
		THIS->ClampValueOn();
		XSRETURN_EMPTY;


void
vtkSpline::ClosedOff()
		CODE:
		THIS->ClosedOff();
		XSRETURN_EMPTY;


void
vtkSpline::ClosedOn()
		CODE:
		THIS->ClosedOn();
		XSRETURN_EMPTY;


void
vtkSpline::Compute()
		CODE:
		THIS->Compute();
		XSRETURN_EMPTY;


int
vtkSpline::GetClampValue()
		CODE:
		RETVAL = THIS->GetClampValue();
		OUTPUT:
		RETVAL


const char *
vtkSpline::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSpline::GetClosed()
		CODE:
		RETVAL = THIS->GetClosed();
		OUTPUT:
		RETVAL


int
vtkSpline::GetLeftConstraint()
		CODE:
		RETVAL = THIS->GetLeftConstraint();
		OUTPUT:
		RETVAL


int
vtkSpline::GetLeftConstraintMaxValue()
		CODE:
		RETVAL = THIS->GetLeftConstraintMaxValue();
		OUTPUT:
		RETVAL


int
vtkSpline::GetLeftConstraintMinValue()
		CODE:
		RETVAL = THIS->GetLeftConstraintMinValue();
		OUTPUT:
		RETVAL


float
vtkSpline::GetLeftValue()
		CODE:
		RETVAL = THIS->GetLeftValue();
		OUTPUT:
		RETVAL


unsigned long
vtkSpline::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkSpline::GetRightConstraint()
		CODE:
		RETVAL = THIS->GetRightConstraint();
		OUTPUT:
		RETVAL


int
vtkSpline::GetRightConstraintMaxValue()
		CODE:
		RETVAL = THIS->GetRightConstraintMaxValue();
		OUTPUT:
		RETVAL


int
vtkSpline::GetRightConstraintMinValue()
		CODE:
		RETVAL = THIS->GetRightConstraintMinValue();
		OUTPUT:
		RETVAL


float
vtkSpline::GetRightValue()
		CODE:
		RETVAL = THIS->GetRightValue();
		OUTPUT:
		RETVAL


void
vtkSpline::RemoveAllPoints()
		CODE:
		THIS->RemoveAllPoints();
		XSRETURN_EMPTY;


void
vtkSpline::RemovePoint(t)
		float 	t
		CODE:
		THIS->RemovePoint(t);
		XSRETURN_EMPTY;


void
vtkSpline::SetClampValue(arg1)
		int 	arg1
		CODE:
		THIS->SetClampValue(arg1);
		XSRETURN_EMPTY;


void
vtkSpline::SetClosed(arg1)
		int 	arg1
		CODE:
		THIS->SetClosed(arg1);
		XSRETURN_EMPTY;


void
vtkSpline::SetLeftConstraint(arg1)
		int 	arg1
		CODE:
		THIS->SetLeftConstraint(arg1);
		XSRETURN_EMPTY;


void
vtkSpline::SetLeftValue(arg1)
		float 	arg1
		CODE:
		THIS->SetLeftValue(arg1);
		XSRETURN_EMPTY;


void
vtkSpline::SetRightConstraint(arg1)
		int 	arg1
		CODE:
		THIS->SetRightConstraint(arg1);
		XSRETURN_EMPTY;


void
vtkSpline::SetRightValue(arg1)
		float 	arg1
		CODE:
		THIS->SetRightValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredGridSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkStructuredGridSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
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
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
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
		croak("Unsupported number of args and/or types supplied to vtkStructuredGridSource::GetOutput\n");



static vtkStructuredGridSource*
vtkStructuredGridSource::New()
		CODE:
		RETVAL = vtkStructuredGridSource::New();
		OUTPUT:
		RETVAL


void
vtkStructuredGridSource::SetOutput(output)
		vtkStructuredGrid *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredGridToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkStructuredGridToPolyDataFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkStructuredGridToPolyDataFilter::SetInput(input)
		vtkStructuredGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredGridToStructuredGridFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridToStructuredGridFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkStructuredGridToStructuredGridFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkStructuredGridToStructuredGridFilter::SetInput(input)
		vtkStructuredGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredPointsCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkStructuredPointsCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkStructuredPoints *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredPointsCollection::AddItem\n");



const char *
vtkStructuredPointsCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkStructuredPointsCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkStructuredPointsCollection*
vtkStructuredPointsCollection::New()
		CODE:
		RETVAL = vtkStructuredPointsCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredPointsSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkStructuredPointsSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
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
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
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
		croak("Unsupported number of args and/or types supplied to vtkStructuredPointsSource::GetOutput\n");



static vtkStructuredPointsSource*
vtkStructuredPointsSource::New()
		CODE:
		RETVAL = vtkStructuredPointsSource::New();
		OUTPUT:
		RETVAL


void
vtkStructuredPointsSource::SetOutput(output)
		vtkStructuredPoints *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredPointsToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkStructuredPointsToPolyDataFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkStructuredPointsToPolyDataFilter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredPointsToStructuredPointsFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsToStructuredPointsFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkStructuredPointsToStructuredPointsFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkStructuredPointsToStructuredPointsFilter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::StructuredPointsToUnstructuredGridFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsToUnstructuredGridFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkStructuredPointsToUnstructuredGridFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkStructuredPointsToUnstructuredGridFilter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::Superquadric PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkSuperquadric::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSuperquadric::EvaluateFunction\n");



float  *
vtkSuperquadric::GetCenter()
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
vtkSuperquadric::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkSuperquadric::GetPhiRoundness()
		CODE:
		RETVAL = THIS->GetPhiRoundness();
		OUTPUT:
		RETVAL


float  *
vtkSuperquadric::GetScale()
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
vtkSuperquadric::GetSize()
		CODE:
		RETVAL = THIS->GetSize();
		OUTPUT:
		RETVAL


float
vtkSuperquadric::GetThetaRoundness()
		CODE:
		RETVAL = THIS->GetThetaRoundness();
		OUTPUT:
		RETVAL


float
vtkSuperquadric::GetThickness()
		CODE:
		RETVAL = THIS->GetThickness();
		OUTPUT:
		RETVAL


float
vtkSuperquadric::GetThicknessMaxValue()
		CODE:
		RETVAL = THIS->GetThicknessMaxValue();
		OUTPUT:
		RETVAL


float
vtkSuperquadric::GetThicknessMinValue()
		CODE:
		RETVAL = THIS->GetThicknessMinValue();
		OUTPUT:
		RETVAL


int
vtkSuperquadric::GetToroidal()
		CODE:
		RETVAL = THIS->GetToroidal();
		OUTPUT:
		RETVAL


static vtkSuperquadric*
vtkSuperquadric::New()
		CODE:
		RETVAL = vtkSuperquadric::New();
		OUTPUT:
		RETVAL


void
vtkSuperquadric::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSuperquadric::SetCenter\n");



void
vtkSuperquadric::SetPhiRoundness(e)
		float 	e
		CODE:
		THIS->SetPhiRoundness(e);
		XSRETURN_EMPTY;


void
vtkSuperquadric::SetScale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetScale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSuperquadric::SetScale\n");



void
vtkSuperquadric::SetSize(arg1)
		float 	arg1
		CODE:
		THIS->SetSize(arg1);
		XSRETURN_EMPTY;


void
vtkSuperquadric::SetThetaRoundness(e)
		float 	e
		CODE:
		THIS->SetThetaRoundness(e);
		XSRETURN_EMPTY;


void
vtkSuperquadric::SetThickness(arg1)
		float 	arg1
		CODE:
		THIS->SetThickness(arg1);
		XSRETURN_EMPTY;


void
vtkSuperquadric::SetToroidal(arg1)
		int 	arg1
		CODE:
		THIS->SetToroidal(arg1);
		XSRETURN_EMPTY;


void
vtkSuperquadric::ToroidalOff()
		CODE:
		THIS->ToroidalOff();
		XSRETURN_EMPTY;


void
vtkSuperquadric::ToroidalOn()
		CODE:
		THIS->ToroidalOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::UnstructuredGridSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkUnstructuredGridSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkUnstructuredGridSource::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
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
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
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
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGridSource::GetOutput\n");



static vtkUnstructuredGridSource*
vtkUnstructuredGridSource::New()
		CODE:
		RETVAL = vtkUnstructuredGridSource::New();
		OUTPUT:
		RETVAL


void
vtkUnstructuredGridSource::SetOutput(output)
		vtkUnstructuredGrid *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::UnstructuredGridToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkUnstructuredGridToPolyDataFilter::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


const char *
vtkUnstructuredGridToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkUnstructuredGridToPolyDataFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkUnstructuredGridToPolyDataFilter::SetInput(input)
		vtkUnstructuredGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Filtering	PACKAGE = Graphics::VTK::UnstructuredGridToUnstructuredGridFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkUnstructuredGridToUnstructuredGridFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkUnstructuredGridToUnstructuredGridFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkUnstructuredGridToUnstructuredGridFilter::SetInput(input)
		vtkUnstructuredGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


