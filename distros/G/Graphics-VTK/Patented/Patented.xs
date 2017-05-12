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
#include "vtkDecimate.h"
#include "vtkDividingCubes.h"
#include "vtkGridSynchronizedTemplates3D.h"
#include "vtkImageMarchingCubes.h"
#include "vtkKitwareContourFilter.h"
#include "vtkMarchingContourFilter.h"
#include "vtkMarchingCubes.h"
#include "vtkMarchingSquares.h"
#include "vtkSliceCubes.h"
#include "vtkSweptSurface.h"
#include "vtkSynchronizedTemplates2D.h"
#include "vtkSynchronizedTemplates3D.h"
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

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::Decimate PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDecimate::BoundaryVertexDeletionOff()
		CODE:
		THIS->BoundaryVertexDeletionOff();
		XSRETURN_EMPTY;


void
vtkDecimate::BoundaryVertexDeletionOn()
		CODE:
		THIS->BoundaryVertexDeletionOn();
		XSRETURN_EMPTY;


void
vtkDecimate::GenerateErrorScalarsOff()
		CODE:
		THIS->GenerateErrorScalarsOff();
		XSRETURN_EMPTY;


void
vtkDecimate::GenerateErrorScalarsOn()
		CODE:
		THIS->GenerateErrorScalarsOn();
		XSRETURN_EMPTY;


float
vtkDecimate::GetAspectRatio()
		CODE:
		RETVAL = THIS->GetAspectRatio();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetAspectRatioMaxValue()
		CODE:
		RETVAL = THIS->GetAspectRatioMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetAspectRatioMinValue()
		CODE:
		RETVAL = THIS->GetAspectRatioMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetBoundaryVertexDeletion()
		CODE:
		RETVAL = THIS->GetBoundaryVertexDeletion();
		OUTPUT:
		RETVAL


const char *
vtkDecimate::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetDegree()
		CODE:
		RETVAL = THIS->GetDegree();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetDegreeMaxValue()
		CODE:
		RETVAL = THIS->GetDegreeMaxValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetDegreeMinValue()
		CODE:
		RETVAL = THIS->GetDegreeMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetErrorIncrement()
		CODE:
		RETVAL = THIS->GetErrorIncrement();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetErrorIncrementMaxValue()
		CODE:
		RETVAL = THIS->GetErrorIncrementMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetErrorIncrementMinValue()
		CODE:
		RETVAL = THIS->GetErrorIncrementMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetFeatureAngleIncrement()
		CODE:
		RETVAL = THIS->GetFeatureAngleIncrement();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetFeatureAngleIncrementMaxValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleIncrementMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetFeatureAngleIncrementMinValue()
		CODE:
		RETVAL = THIS->GetFeatureAngleIncrementMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetGenerateErrorScalars()
		CODE:
		RETVAL = THIS->GetGenerateErrorScalars();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetInitialError()
		CODE:
		RETVAL = THIS->GetInitialError();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetInitialErrorMaxValue()
		CODE:
		RETVAL = THIS->GetInitialErrorMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetInitialErrorMinValue()
		CODE:
		RETVAL = THIS->GetInitialErrorMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetInitialFeatureAngle()
		CODE:
		RETVAL = THIS->GetInitialFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetInitialFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetInitialFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetInitialFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetInitialFeatureAngleMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetMaximumError()
		CODE:
		RETVAL = THIS->GetMaximumError();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetMaximumErrorMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumErrorMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetMaximumErrorMinValue()
		CODE:
		RETVAL = THIS->GetMaximumErrorMinValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetMaximumFeatureAngle()
		CODE:
		RETVAL = THIS->GetMaximumFeatureAngle();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetMaximumFeatureAngleMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumFeatureAngleMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetMaximumFeatureAngleMinValue()
		CODE:
		RETVAL = THIS->GetMaximumFeatureAngleMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumIterations()
		CODE:
		RETVAL = THIS->GetMaximumIterations();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumIterationsMaxValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumIterationsMinValue()
		CODE:
		RETVAL = THIS->GetMaximumIterationsMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumNumberOfSquawks()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfSquawks();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumNumberOfSquawksMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfSquawksMaxValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumNumberOfSquawksMinValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfSquawksMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumSubIterations()
		CODE:
		RETVAL = THIS->GetMaximumSubIterations();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumSubIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumSubIterationsMaxValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetMaximumSubIterationsMinValue()
		CODE:
		RETVAL = THIS->GetMaximumSubIterationsMinValue();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetPreserveEdges()
		CODE:
		RETVAL = THIS->GetPreserveEdges();
		OUTPUT:
		RETVAL


int
vtkDecimate::GetPreserveTopology()
		CODE:
		RETVAL = THIS->GetPreserveTopology();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetTargetReduction()
		CODE:
		RETVAL = THIS->GetTargetReduction();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetTargetReductionMaxValue()
		CODE:
		RETVAL = THIS->GetTargetReductionMaxValue();
		OUTPUT:
		RETVAL


float
vtkDecimate::GetTargetReductionMinValue()
		CODE:
		RETVAL = THIS->GetTargetReductionMinValue();
		OUTPUT:
		RETVAL


static vtkDecimate*
vtkDecimate::New()
		CODE:
		RETVAL = vtkDecimate::New();
		OUTPUT:
		RETVAL


void
vtkDecimate::PreserveEdgesOff()
		CODE:
		THIS->PreserveEdgesOff();
		XSRETURN_EMPTY;


void
vtkDecimate::PreserveEdgesOn()
		CODE:
		THIS->PreserveEdgesOn();
		XSRETURN_EMPTY;


void
vtkDecimate::PreserveTopologyOff()
		CODE:
		THIS->PreserveTopologyOff();
		XSRETURN_EMPTY;


void
vtkDecimate::PreserveTopologyOn()
		CODE:
		THIS->PreserveTopologyOn();
		XSRETURN_EMPTY;


void
vtkDecimate::SetAspectRatio(arg1)
		float 	arg1
		CODE:
		THIS->SetAspectRatio(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetBoundaryVertexDeletion(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundaryVertexDeletion(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetDegree(arg1)
		int 	arg1
		CODE:
		THIS->SetDegree(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetErrorIncrement(arg1)
		float 	arg1
		CODE:
		THIS->SetErrorIncrement(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetFeatureAngleIncrement(arg1)
		float 	arg1
		CODE:
		THIS->SetFeatureAngleIncrement(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetGenerateErrorScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetGenerateErrorScalars(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetInitialError(arg1)
		float 	arg1
		CODE:
		THIS->SetInitialError(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetInitialFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetInitialFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetMaximumError(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumError(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetMaximumFeatureAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumFeatureAngle(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetMaximumIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumIterations(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetMaximumNumberOfSquawks(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfSquawks(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetMaximumSubIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumSubIterations(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetPreserveEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetPreserveEdges(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetPreserveTopology(arg1)
		int 	arg1
		CODE:
		THIS->SetPreserveTopology(arg1);
		XSRETURN_EMPTY;


void
vtkDecimate::SetTargetReduction(arg1)
		float 	arg1
		CODE:
		THIS->SetTargetReduction(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::DividingCubes PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDividingCubes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkDividingCubes::GetDistance()
		CODE:
		RETVAL = THIS->GetDistance();
		OUTPUT:
		RETVAL


float
vtkDividingCubes::GetDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkDividingCubes::GetDistanceMinValue()
		CODE:
		RETVAL = THIS->GetDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkDividingCubes::GetIncrement()
		CODE:
		RETVAL = THIS->GetIncrement();
		OUTPUT:
		RETVAL


int
vtkDividingCubes::GetIncrementMaxValue()
		CODE:
		RETVAL = THIS->GetIncrementMaxValue();
		OUTPUT:
		RETVAL


int
vtkDividingCubes::GetIncrementMinValue()
		CODE:
		RETVAL = THIS->GetIncrementMinValue();
		OUTPUT:
		RETVAL


float
vtkDividingCubes::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


static vtkDividingCubes*
vtkDividingCubes::New()
		CODE:
		RETVAL = vtkDividingCubes::New();
		OUTPUT:
		RETVAL


void
vtkDividingCubes::SetDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetDistance(arg1);
		XSRETURN_EMPTY;


void
vtkDividingCubes::SetIncrement(arg1)
		int 	arg1
		CODE:
		THIS->SetIncrement(arg1);
		XSRETURN_EMPTY;


void
vtkDividingCubes::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::GridSynchronizedTemplates3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGridSynchronizedTemplates3D::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGridSynchronizedTemplates3D::GenerateValues\n");



const char *
vtkGridSynchronizedTemplates3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


int *
vtkGridSynchronizedTemplates3D::GetExecuteExtent()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExecuteExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


unsigned long
vtkGridSynchronizedTemplates3D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetNumberOfThreadsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMaxValue();
		OUTPUT:
		RETVAL


int
vtkGridSynchronizedTemplates3D::GetNumberOfThreadsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMinValue();
		OUTPUT:
		RETVAL


float
vtkGridSynchronizedTemplates3D::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkGridSynchronizedTemplates3D*
vtkGridSynchronizedTemplates3D::New()
		CODE:
		RETVAL = vtkGridSynchronizedTemplates3D::New();
		OUTPUT:
		RETVAL


void
vtkGridSynchronizedTemplates3D::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::SetInputMemoryLimit(limit)
		long 	limit
		CODE:
		THIS->SetInputMemoryLimit(limit);
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;


void
vtkGridSynchronizedTemplates3D::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::ImageMarchingCubes PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageMarchingCubes::AddLocatorPoint(cellX, cellY, edge, ptId)
		int 	cellX
		int 	cellY
		int 	edge
		int 	ptId
		CODE:
		THIS->AddLocatorPoint(cellX, cellY, edge, ptId);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMarchingCubes::GenerateValues\n");



const char *
vtkImageMarchingCubes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageMarchingCubes::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkImageMarchingCubes::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkImageMarchingCubes::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageMarchingCubes::GetInput()
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


int
vtkImageMarchingCubes::GetInputMemoryLimit()
		CODE:
		RETVAL = THIS->GetInputMemoryLimit();
		OUTPUT:
		RETVAL


int
vtkImageMarchingCubes::GetLocatorPoint(cellX, cellY, edge)
		int 	cellX
		int 	cellY
		int 	edge
		CODE:
		RETVAL = THIS->GetLocatorPoint(cellX, cellY, edge);
		OUTPUT:
		RETVAL


unsigned long
vtkImageMarchingCubes::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkImageMarchingCubes::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


float
vtkImageMarchingCubes::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


void
vtkImageMarchingCubes::IncrementLocatorZ()
		CODE:
		THIS->IncrementLocatorZ();
		XSRETURN_EMPTY;


static vtkImageMarchingCubes*
vtkImageMarchingCubes::New()
		CODE:
		RETVAL = vtkImageMarchingCubes::New();
		OUTPUT:
		RETVAL


void
vtkImageMarchingCubes::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::SetInputMemoryLimit(arg1)
		int 	arg1
		CODE:
		THIS->SetInputMemoryLimit(arg1);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;


void
vtkImageMarchingCubes::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::KitwareContourFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkKitwareContourFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkKitwareContourFilter*
vtkKitwareContourFilter::New()
		CODE:
		RETVAL = vtkKitwareContourFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::MarchingContourFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMarchingContourFilter::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMarchingContourFilter::GenerateValues\n");



const char *
vtkMarchingContourFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMarchingContourFilter::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkMarchingContourFilter::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkMarchingContourFilter::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkMarchingContourFilter::GetLocator()
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
vtkMarchingContourFilter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkMarchingContourFilter::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


int
vtkMarchingContourFilter::GetUseScalarTree()
		CODE:
		RETVAL = THIS->GetUseScalarTree();
		OUTPUT:
		RETVAL


float
vtkMarchingContourFilter::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkMarchingContourFilter*
vtkMarchingContourFilter::New()
		CODE:
		RETVAL = vtkMarchingContourFilter::New();
		OUTPUT:
		RETVAL


void
vtkMarchingContourFilter::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::SetUseScalarTree(arg1)
		int 	arg1
		CODE:
		THIS->SetUseScalarTree(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::UseScalarTreeOff()
		CODE:
		THIS->UseScalarTreeOff();
		XSRETURN_EMPTY;


void
vtkMarchingContourFilter::UseScalarTreeOn()
		CODE:
		THIS->UseScalarTreeOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::MarchingCubes PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMarchingCubes::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkMarchingCubes::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMarchingCubes::GenerateValues\n");



const char *
vtkMarchingCubes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMarchingCubes::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkMarchingCubes::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkMarchingCubes::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkMarchingCubes::GetLocator()
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
vtkMarchingCubes::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkMarchingCubes::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


float
vtkMarchingCubes::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkMarchingCubes*
vtkMarchingCubes::New()
		CODE:
		RETVAL = vtkMarchingCubes::New();
		OUTPUT:
		RETVAL


void
vtkMarchingCubes::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingCubes::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingCubes::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkMarchingCubes::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkMarchingCubes::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkMarchingCubes::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::MarchingSquares PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMarchingSquares::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkMarchingSquares::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMarchingSquares::GenerateValues\n");



const char *
vtkMarchingSquares::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkMarchingSquares::GetImageRange()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetImageRange();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


vtkImageData *
vtkMarchingSquares::GetInput()
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


vtkPointLocator *
vtkMarchingSquares::GetLocator()
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
vtkMarchingSquares::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkMarchingSquares::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


float
vtkMarchingSquares::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkMarchingSquares*
vtkMarchingSquares::New()
		CODE:
		RETVAL = vtkMarchingSquares::New();
		OUTPUT:
		RETVAL


void
vtkMarchingSquares::SetImageRange(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetImageRange(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMarchingSquares::SetImageRange\n");



void
vtkMarchingSquares::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkMarchingSquares::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkMarchingSquares::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkMarchingSquares::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::SliceCubes PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSliceCubes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkSliceCubes::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


char *
vtkSliceCubes::GetLimitsFileName()
		CODE:
		RETVAL = THIS->GetLimitsFileName();
		OUTPUT:
		RETVAL


vtkVolumeReader *
vtkSliceCubes::GetReader()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolumeReader";
		CODE:
		RETVAL = THIS->GetReader();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkSliceCubes::GetValue()
		CODE:
		RETVAL = THIS->GetValue();
		OUTPUT:
		RETVAL


static vtkSliceCubes*
vtkSliceCubes::New()
		CODE:
		RETVAL = vtkSliceCubes::New();
		OUTPUT:
		RETVAL


void
vtkSliceCubes::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkSliceCubes::SetLimitsFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetLimitsFileName(arg1);
		XSRETURN_EMPTY;


void
vtkSliceCubes::SetReader(arg1)
		vtkVolumeReader *	arg1
		CODE:
		THIS->SetReader(arg1);
		XSRETURN_EMPTY;


void
vtkSliceCubes::SetValue(arg1)
		float 	arg1
		CODE:
		THIS->SetValue(arg1);
		XSRETURN_EMPTY;


void
vtkSliceCubes::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkSliceCubes::Write()
		CODE:
		THIS->Write();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::SweptSurface PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSweptSurface::AdjustBoundsOff()
		CODE:
		THIS->AdjustBoundsOff();
		XSRETURN_EMPTY;


void
vtkSweptSurface::AdjustBoundsOn()
		CODE:
		THIS->AdjustBoundsOn();
		XSRETURN_EMPTY;


void
vtkSweptSurface::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkSweptSurface::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


int
vtkSweptSurface::GetAdjustBounds()
		CODE:
		RETVAL = THIS->GetAdjustBounds();
		OUTPUT:
		RETVAL


float
vtkSweptSurface::GetAdjustDistance()
		CODE:
		RETVAL = THIS->GetAdjustDistance();
		OUTPUT:
		RETVAL


float
vtkSweptSurface::GetAdjustDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetAdjustDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkSweptSurface::GetAdjustDistanceMinValue()
		CODE:
		RETVAL = THIS->GetAdjustDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkSweptSurface::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkSweptSurface::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkSweptSurface::GetFillValue()
		CODE:
		RETVAL = THIS->GetFillValue();
		OUTPUT:
		RETVAL


unsigned long
vtkSweptSurface::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkSweptSurface::GetMaximumNumberOfInterpolationSteps()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfInterpolationSteps();
		OUTPUT:
		RETVAL


float  *
vtkSweptSurface::GetModelBounds()
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
vtkSweptSurface::GetNumberOfInterpolationSteps()
		CODE:
		RETVAL = THIS->GetNumberOfInterpolationSteps();
		OUTPUT:
		RETVAL


int  *
vtkSweptSurface::GetSampleDimensions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSampleDimensions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkTransformCollection *
vtkSweptSurface::GetTransforms()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkTransformCollection";
		CODE:
		RETVAL = THIS->GetTransforms();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkSweptSurface*
vtkSweptSurface::New()
		CODE:
		RETVAL = vtkSweptSurface::New();
		OUTPUT:
		RETVAL


void
vtkSweptSurface::SetAdjustBounds(arg1)
		int 	arg1
		CODE:
		THIS->SetAdjustBounds(arg1);
		XSRETURN_EMPTY;


void
vtkSweptSurface::SetAdjustDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetAdjustDistance(arg1);
		XSRETURN_EMPTY;


void
vtkSweptSurface::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkSweptSurface::SetFillValue(arg1)
		float 	arg1
		CODE:
		THIS->SetFillValue(arg1);
		XSRETURN_EMPTY;


void
vtkSweptSurface::SetMaximumNumberOfInterpolationSteps(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfInterpolationSteps(arg1);
		XSRETURN_EMPTY;


void
vtkSweptSurface::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkSweptSurface::SetModelBounds\n");



void
vtkSweptSurface::SetNumberOfInterpolationSteps(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfInterpolationSteps(arg1);
		XSRETURN_EMPTY;


void
vtkSweptSurface::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSweptSurface::SetSampleDimensions\n");



void
vtkSweptSurface::SetTransforms(arg1)
		vtkTransformCollection *	arg1
		CODE:
		THIS->SetTransforms(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::SynchronizedTemplates2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSynchronizedTemplates2D::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates2D::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates2D::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSynchronizedTemplates2D::GenerateValues\n");



const char *
vtkSynchronizedTemplates2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates2D::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


vtkImageData *
vtkSynchronizedTemplates2D::GetInput()
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


unsigned long
vtkSynchronizedTemplates2D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates2D::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


float
vtkSynchronizedTemplates2D::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkSynchronizedTemplates2D*
vtkSynchronizedTemplates2D::New()
		CODE:
		RETVAL = vtkSynchronizedTemplates2D::New();
		OUTPUT:
		RETVAL


void
vtkSynchronizedTemplates2D::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates2D::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates2D::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates2D::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Patented	PACKAGE = Graphics::VTK::SynchronizedTemplates3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSynchronizedTemplates3D::ComputeGradientsOff()
		CODE:
		THIS->ComputeGradientsOff();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::ComputeGradientsOn()
		CODE:
		THIS->ComputeGradientsOn();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::ComputeScalarsOff()
		CODE:
		THIS->ComputeScalarsOff();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::ComputeScalarsOn()
		CODE:
		THIS->ComputeScalarsOn();
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSynchronizedTemplates3D::GenerateValues\n");



const char *
vtkSynchronizedTemplates3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetComputeGradients()
		CODE:
		RETVAL = THIS->GetComputeGradients();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetComputeScalars()
		CODE:
		RETVAL = THIS->GetComputeScalars();
		OUTPUT:
		RETVAL


int *
vtkSynchronizedTemplates3D::GetExecuteExtent()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExecuteExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


vtkImageData *
vtkSynchronizedTemplates3D::GetInput()
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


unsigned long
vtkSynchronizedTemplates3D::GetInputMemoryLimit()
		CODE:
		RETVAL = THIS->GetInputMemoryLimit();
		OUTPUT:
		RETVAL


unsigned long
vtkSynchronizedTemplates3D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetNumberOfThreadsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMaxValue();
		OUTPUT:
		RETVAL


int
vtkSynchronizedTemplates3D::GetNumberOfThreadsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMinValue();
		OUTPUT:
		RETVAL


float
vtkSynchronizedTemplates3D::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkSynchronizedTemplates3D*
vtkSynchronizedTemplates3D::New()
		CODE:
		RETVAL = vtkSynchronizedTemplates3D::New();
		OUTPUT:
		RETVAL


void
vtkSynchronizedTemplates3D::SetComputeGradients(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradients(arg1);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetComputeScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeScalars(arg1);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetInputMemoryLimit(limit)
		unsigned long 	limit
		CODE:
		THIS->SetInputMemoryLimit(limit);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetNumberOfContours(number)
		int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;


void
vtkSynchronizedTemplates3D::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;


