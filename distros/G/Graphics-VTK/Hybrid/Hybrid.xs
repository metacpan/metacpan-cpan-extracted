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

/* avoid some nasty defines on win32 that cause c++ compilation to fail */
#ifdef WIN32
#undef yylex
#endif

#include "vtkPerl.h"
#include "vtk3DSImporter.h"
#include "vtkArcPlotter.h"
#include "vtkCaptionActor2D.h"
#include "vtkCubeAxesActor2D.h"
#include "vtkDepthSortPolyData.h"
#include "vtkEarthSource.h"
#include "vtkGridTransform.h"
#include "vtkImageToPolyDataFilter.h"
#include "vtkImplicitModeller.h"
#include "vtkIterativeClosestPointTransform.h"
#include "vtkLandmarkTransform.h"
#include "vtkLegendBoxActor.h"
#include "vtkPolyDataToImageStencil.h"
#include "vtkRIBExporter.h"
#include "vtkRIBLight.h"
#include "vtkRIBProperty.h"
#include "vtkRenderLargeImage.h"
#include "vtkThinPlateSplineTransform.h"
#include "vtkTransformToGrid.h"
#include "vtkVRMLImporter.h"
#include "vtkVectorText.h"
#include "vtkVideoSource.h"
#include "vtkWeightedTransformFilter.h"
#include "vtkXYPlotActor.h"
#include "vtkRectilinearGrid.h"
#include "vtkStructuredGrid.h"
#include "vtkDataObjectCollection.h"
#include "vtkDataSetCollection.h"
#include "vtkGlyphSource2D.h"
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

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::3DSImporter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtk3DSImporter::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtk3DSImporter::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


const char *
vtk3DSImporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtk3DSImporter::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


FILE *
vtk3DSImporter::GetFileFD()
		CODE:
		RETVAL = THIS->GetFileFD();
		OUTPUT:
		RETVAL


char *
vtk3DSImporter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


static vtk3DSImporter*
vtk3DSImporter::New()
		CODE:
		RETVAL = vtk3DSImporter::New();
		OUTPUT:
		RETVAL


void
vtk3DSImporter::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtk3DSImporter::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::ArcPlotter PREFIX = vtk

PROTOTYPES: DISABLE



vtkCamera *
vtkArcPlotter::GetCamera()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCamera";
		CODE:
		RETVAL = THIS->GetCamera();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkArcPlotter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkArcPlotter::GetDefaultNormal()
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
vtkArcPlotter::GetFieldDataArray()
		CODE:
		RETVAL = THIS->GetFieldDataArray();
		OUTPUT:
		RETVAL


int
vtkArcPlotter::GetFieldDataArrayMaxValue()
		CODE:
		RETVAL = THIS->GetFieldDataArrayMaxValue();
		OUTPUT:
		RETVAL


int
vtkArcPlotter::GetFieldDataArrayMinValue()
		CODE:
		RETVAL = THIS->GetFieldDataArrayMinValue();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetHeight()
		CODE:
		RETVAL = THIS->GetHeight();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetHeightMaxValue()
		CODE:
		RETVAL = THIS->GetHeightMaxValue();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetHeightMinValue()
		CODE:
		RETVAL = THIS->GetHeightMinValue();
		OUTPUT:
		RETVAL


unsigned long
vtkArcPlotter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetOffset()
		CODE:
		RETVAL = THIS->GetOffset();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetOffsetMaxValue();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetOffsetMinValue()
		CODE:
		RETVAL = THIS->GetOffsetMinValue();
		OUTPUT:
		RETVAL


int
vtkArcPlotter::GetPlotComponent()
		CODE:
		RETVAL = THIS->GetPlotComponent();
		OUTPUT:
		RETVAL


int
vtkArcPlotter::GetPlotMode()
		CODE:
		RETVAL = THIS->GetPlotMode();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkArcPlotter::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


int
vtkArcPlotter::GetUseDefaultNormal()
		CODE:
		RETVAL = THIS->GetUseDefaultNormal();
		OUTPUT:
		RETVAL


static vtkArcPlotter*
vtkArcPlotter::New()
		CODE:
		RETVAL = vtkArcPlotter::New();
		OUTPUT:
		RETVAL


void
vtkArcPlotter::SetCamera(arg1)
		vtkCamera *	arg1
		CODE:
		THIS->SetCamera(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetDefaultNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDefaultNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkArcPlotter::SetDefaultNormal\n");



void
vtkArcPlotter::SetFieldDataArray(arg1)
		int 	arg1
		CODE:
		THIS->SetFieldDataArray(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetHeight(arg1)
		float 	arg1
		CODE:
		THIS->SetHeight(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetOffset(arg1)
		float 	arg1
		CODE:
		THIS->SetOffset(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotComponent(arg1)
		int 	arg1
		CODE:
		THIS->SetPlotComponent(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotMode(arg1)
		int 	arg1
		CODE:
		THIS->SetPlotMode(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotModeToPlotFieldData()
		CODE:
		THIS->SetPlotModeToPlotFieldData();
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotModeToPlotNormals()
		CODE:
		THIS->SetPlotModeToPlotNormals();
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotModeToPlotScalars()
		CODE:
		THIS->SetPlotModeToPlotScalars();
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotModeToPlotTCoords()
		CODE:
		THIS->SetPlotModeToPlotTCoords();
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotModeToPlotTensors()
		CODE:
		THIS->SetPlotModeToPlotTensors();
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetPlotModeToPlotVectors()
		CODE:
		THIS->SetPlotModeToPlotVectors();
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::SetUseDefaultNormal(arg1)
		int 	arg1
		CODE:
		THIS->SetUseDefaultNormal(arg1);
		XSRETURN_EMPTY;


void
vtkArcPlotter::UseDefaultNormalOff()
		CODE:
		THIS->UseDefaultNormalOff();
		XSRETURN_EMPTY;


void
vtkArcPlotter::UseDefaultNormalOn()
		CODE:
		THIS->UseDefaultNormalOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::CaptionActor2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCaptionActor2D::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::BorderOff()
		CODE:
		THIS->BorderOff();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::BorderOn()
		CODE:
		THIS->BorderOn();
		XSRETURN_EMPTY;


float *
vtkCaptionActor2D::GetAttachmentPoint()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAttachmentPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkCoordinate *
vtkCaptionActor2D::GetAttachmentPointCoordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetAttachmentPointCoordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetBorder()
		CODE:
		RETVAL = THIS->GetBorder();
		OUTPUT:
		RETVAL


char *
vtkCaptionActor2D::GetCaption()
		CODE:
		RETVAL = THIS->GetCaption();
		OUTPUT:
		RETVAL


const char *
vtkCaptionActor2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetJustification()
		CODE:
		RETVAL = THIS->GetJustification();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetJustificationMaxValue()
		CODE:
		RETVAL = THIS->GetJustificationMaxValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetJustificationMinValue()
		CODE:
		RETVAL = THIS->GetJustificationMinValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetLeader()
		CODE:
		RETVAL = THIS->GetLeader();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkCaptionActor2D::GetLeaderGlyph()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetLeaderGlyph();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkCaptionActor2D::GetLeaderGlyphSize()
		CODE:
		RETVAL = THIS->GetLeaderGlyphSize();
		OUTPUT:
		RETVAL


float
vtkCaptionActor2D::GetLeaderGlyphSizeMaxValue()
		CODE:
		RETVAL = THIS->GetLeaderGlyphSizeMaxValue();
		OUTPUT:
		RETVAL


float
vtkCaptionActor2D::GetLeaderGlyphSizeMinValue()
		CODE:
		RETVAL = THIS->GetLeaderGlyphSizeMinValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetMaximumLeaderGlyphSize()
		CODE:
		RETVAL = THIS->GetMaximumLeaderGlyphSize();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetMaximumLeaderGlyphSizeMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumLeaderGlyphSizeMaxValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetMaximumLeaderGlyphSizeMinValue()
		CODE:
		RETVAL = THIS->GetMaximumLeaderGlyphSizeMinValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetPadding()
		CODE:
		RETVAL = THIS->GetPadding();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetPaddingMaxValue()
		CODE:
		RETVAL = THIS->GetPaddingMaxValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetPaddingMinValue()
		CODE:
		RETVAL = THIS->GetPaddingMinValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetThreeDimensionalLeader()
		CODE:
		RETVAL = THIS->GetThreeDimensionalLeader();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetVerticalJustification()
		CODE:
		RETVAL = THIS->GetVerticalJustification();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetVerticalJustificationMaxValue()
		CODE:
		RETVAL = THIS->GetVerticalJustificationMaxValue();
		OUTPUT:
		RETVAL


int
vtkCaptionActor2D::GetVerticalJustificationMinValue()
		CODE:
		RETVAL = THIS->GetVerticalJustificationMinValue();
		OUTPUT:
		RETVAL


void
vtkCaptionActor2D::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::LeaderOff()
		CODE:
		THIS->LeaderOff();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::LeaderOn()
		CODE:
		THIS->LeaderOn();
		XSRETURN_EMPTY;


static vtkCaptionActor2D*
vtkCaptionActor2D::New()
		CODE:
		RETVAL = vtkCaptionActor2D::New();
		OUTPUT:
		RETVAL


void
vtkCaptionActor2D::SetAttachmentPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float	arg1
		float	arg2
		float	arg3
		CODE:
		THIS->SetAttachmentPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCaptionActor2D::SetAttachmentPoint\n");



void
vtkCaptionActor2D::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetBorder(arg1)
		int 	arg1
		CODE:
		THIS->SetBorder(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetCaption(arg1)
		char *	arg1
		CODE:
		THIS->SetCaption(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetJustification(arg1)
		int 	arg1
		CODE:
		THIS->SetJustification(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetJustificationToCentered()
		CODE:
		THIS->SetJustificationToCentered();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetJustificationToLeft()
		CODE:
		THIS->SetJustificationToLeft();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetJustificationToRight()
		CODE:
		THIS->SetJustificationToRight();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetLeader(arg1)
		int 	arg1
		CODE:
		THIS->SetLeader(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetLeaderGlyph(arg1)
		vtkPolyData *	arg1
		CODE:
		THIS->SetLeaderGlyph(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetLeaderGlyphSize(arg1)
		float 	arg1
		CODE:
		THIS->SetLeaderGlyphSize(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetMaximumLeaderGlyphSize(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumLeaderGlyphSize(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetPadding(arg1)
		int 	arg1
		CODE:
		THIS->SetPadding(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetThreeDimensionalLeader(arg1)
		int 	arg1
		CODE:
		THIS->SetThreeDimensionalLeader(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetVerticalJustification(arg1)
		int 	arg1
		CODE:
		THIS->SetVerticalJustification(arg1);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetVerticalJustificationToBottom()
		CODE:
		THIS->SetVerticalJustificationToBottom();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetVerticalJustificationToCentered()
		CODE:
		THIS->SetVerticalJustificationToCentered();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::SetVerticalJustificationToTop()
		CODE:
		THIS->SetVerticalJustificationToTop();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::ThreeDimensionalLeaderOff()
		CODE:
		THIS->ThreeDimensionalLeaderOff();
		XSRETURN_EMPTY;


void
vtkCaptionActor2D::ThreeDimensionalLeaderOn()
		CODE:
		THIS->ThreeDimensionalLeaderOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::CubeAxesActor2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCubeAxesActor2D::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


int
vtkCubeAxesActor2D::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


float *
vtkCubeAxesActor2D::GetBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->GetBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
		arg4
		arg5
		arg6
	CASE: items == 1
		PREINIT:
		float * retval;
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
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCubeAxesActor2D::GetBounds\n");



vtkCamera *
vtkCubeAxesActor2D::GetCamera()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCamera";
		CODE:
		RETVAL = THIS->GetCamera();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkCubeAxesActor2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkCubeAxesActor2D::GetCornerOffset()
		CODE:
		RETVAL = THIS->GetCornerOffset();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetFlyMode()
		CODE:
		RETVAL = THIS->GetFlyMode();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetFlyModeMaxValue()
		CODE:
		RETVAL = THIS->GetFlyModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetFlyModeMinValue()
		CODE:
		RETVAL = THIS->GetFlyModeMinValue();
		OUTPUT:
		RETVAL


float
vtkCubeAxesActor2D::GetFontFactor()
		CODE:
		RETVAL = THIS->GetFontFactor();
		OUTPUT:
		RETVAL


float
vtkCubeAxesActor2D::GetFontFactorMaxValue()
		CODE:
		RETVAL = THIS->GetFontFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkCubeAxesActor2D::GetFontFactorMinValue()
		CODE:
		RETVAL = THIS->GetFontFactorMinValue();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


float
vtkCubeAxesActor2D::GetInertia()
		CODE:
		RETVAL = THIS->GetInertia();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetInertiaMaxValue()
		CODE:
		RETVAL = THIS->GetInertiaMaxValue();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetInertiaMinValue()
		CODE:
		RETVAL = THIS->GetInertiaMinValue();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkCubeAxesActor2D::GetInput()
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
vtkCubeAxesActor2D::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


char *
vtkCubeAxesActor2D::GetLabelFormat()
		CODE:
		RETVAL = THIS->GetLabelFormat();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetNumberOfLabels()
		CODE:
		RETVAL = THIS->GetNumberOfLabels();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetNumberOfLabelsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMaxValue();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetNumberOfLabelsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMinValue();
		OUTPUT:
		RETVAL


vtkProp *
vtkCubeAxesActor2D::GetProp()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp";
		CODE:
		RETVAL = THIS->GetProp();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkCubeAxesActor2D::GetRanges(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->GetRanges(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
		arg4
		arg5
		arg6
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCubeAxesActor2D::GetRanges\n");



int
vtkCubeAxesActor2D::GetScaling()
		CODE:
		RETVAL = THIS->GetScaling();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetUseRanges()
		CODE:
		RETVAL = THIS->GetUseRanges();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetXAxisVisibility()
		CODE:
		RETVAL = THIS->GetXAxisVisibility();
		OUTPUT:
		RETVAL


char *
vtkCubeAxesActor2D::GetXLabel()
		CODE:
		RETVAL = THIS->GetXLabel();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetYAxisVisibility()
		CODE:
		RETVAL = THIS->GetYAxisVisibility();
		OUTPUT:
		RETVAL


char *
vtkCubeAxesActor2D::GetYLabel()
		CODE:
		RETVAL = THIS->GetYLabel();
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::GetZAxisVisibility()
		CODE:
		RETVAL = THIS->GetZAxisVisibility();
		OUTPUT:
		RETVAL


char *
vtkCubeAxesActor2D::GetZLabel()
		CODE:
		RETVAL = THIS->GetZLabel();
		OUTPUT:
		RETVAL


void
vtkCubeAxesActor2D::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


static vtkCubeAxesActor2D*
vtkCubeAxesActor2D::New()
		CODE:
		RETVAL = vtkCubeAxesActor2D::New();
		OUTPUT:
		RETVAL


void
vtkCubeAxesActor2D::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


int
vtkCubeAxesActor2D::RenderOpaqueGeometry(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(arg1);
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::RenderOverlay(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderOverlay(arg1);
		OUTPUT:
		RETVAL


int
vtkCubeAxesActor2D::RenderTranslucentGeometry(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(arg1);
		OUTPUT:
		RETVAL


void
vtkCubeAxesActor2D::ScalingOff()
		CODE:
		THIS->ScalingOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ScalingOn()
		CODE:
		THIS->ScalingOn();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkCubeAxesActor2D::SetBounds\n");



void
vtkCubeAxesActor2D::SetCamera(arg1)
		vtkCamera *	arg1
		CODE:
		THIS->SetCamera(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetCornerOffset(arg1)
		float 	arg1
		CODE:
		THIS->SetCornerOffset(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFlyMode(arg1)
		int 	arg1
		CODE:
		THIS->SetFlyMode(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFlyModeToClosestTriad()
		CODE:
		THIS->SetFlyModeToClosestTriad();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFlyModeToOuterEdges()
		CODE:
		THIS->SetFlyModeToOuterEdges();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFontFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetFontFactor(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetInertia(arg1)
		int 	arg1
		CODE:
		THIS->SetInertia(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetInput(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetLabelFormat(arg1)
		char *	arg1
		CODE:
		THIS->SetLabelFormat(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetNumberOfLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfLabels(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetProp(arg1)
		vtkProp *	arg1
		CODE:
		THIS->SetProp(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetRanges(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetRanges(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCubeAxesActor2D::SetRanges\n");



void
vtkCubeAxesActor2D::SetScaling(arg1)
		int 	arg1
		CODE:
		THIS->SetScaling(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetUseRanges(arg1)
		int 	arg1
		CODE:
		THIS->SetUseRanges(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetXAxisVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetXAxisVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetXLabel(arg1)
		char *	arg1
		CODE:
		THIS->SetXLabel(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetYAxisVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetYAxisVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetYLabel(arg1)
		char *	arg1
		CODE:
		THIS->SetYLabel(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetZAxisVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetZAxisVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::SetZLabel(arg1)
		char *	arg1
		CODE:
		THIS->SetZLabel(arg1);
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ShallowCopy(arg1 = 0)
	CASE: items == 2
		vtkCubeAxesActor2D *	arg1
		CODE:
		THIS->ShallowCopy(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCubeAxesActor2D::ShallowCopy\n");



void
vtkCubeAxesActor2D::UseRangesOff()
		CODE:
		THIS->UseRangesOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::UseRangesOn()
		CODE:
		THIS->UseRangesOn();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::XAxisVisibilityOff()
		CODE:
		THIS->XAxisVisibilityOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::XAxisVisibilityOn()
		CODE:
		THIS->XAxisVisibilityOn();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::YAxisVisibilityOff()
		CODE:
		THIS->YAxisVisibilityOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::YAxisVisibilityOn()
		CODE:
		THIS->YAxisVisibilityOn();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ZAxisVisibilityOff()
		CODE:
		THIS->ZAxisVisibilityOff();
		XSRETURN_EMPTY;


void
vtkCubeAxesActor2D::ZAxisVisibilityOn()
		CODE:
		THIS->ZAxisVisibilityOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::DepthSortPolyData PREFIX = vtk

PROTOTYPES: DISABLE



vtkCamera *
vtkDepthSortPolyData::GetCamera()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCamera";
		CODE:
		RETVAL = THIS->GetCamera();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkDepthSortPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDepthSortPolyData::GetDepthSortMode()
		CODE:
		RETVAL = THIS->GetDepthSortMode();
		OUTPUT:
		RETVAL


int
vtkDepthSortPolyData::GetDirection()
		CODE:
		RETVAL = THIS->GetDirection();
		OUTPUT:
		RETVAL


unsigned long
vtkDepthSortPolyData::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


double  *
vtkDepthSortPolyData::GetOrigin()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkProp3D *
vtkDepthSortPolyData::GetProp3D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp3D";
		CODE:
		RETVAL = THIS->GetProp3D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDepthSortPolyData::GetSortScalars()
		CODE:
		RETVAL = THIS->GetSortScalars();
		OUTPUT:
		RETVAL


double  *
vtkDepthSortPolyData::GetVector()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVector();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkDepthSortPolyData*
vtkDepthSortPolyData::New()
		CODE:
		RETVAL = vtkDepthSortPolyData::New();
		OUTPUT:
		RETVAL


void
vtkDepthSortPolyData::SetCamera(arg1)
		vtkCamera *	arg1
		CODE:
		THIS->SetCamera(arg1);
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDepthSortMode(arg1)
		int 	arg1
		CODE:
		THIS->SetDepthSortMode(arg1);
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDepthSortModeToBoundsCenter()
		CODE:
		THIS->SetDepthSortModeToBoundsCenter();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDepthSortModeToFirstPoint()
		CODE:
		THIS->SetDepthSortModeToFirstPoint();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDepthSortModeToParametricCenter()
		CODE:
		THIS->SetDepthSortModeToParametricCenter();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDirection(arg1)
		int 	arg1
		CODE:
		THIS->SetDirection(arg1);
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDirectionToBackToFront()
		CODE:
		THIS->SetDirectionToBackToFront();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDirectionToFrontToBack()
		CODE:
		THIS->SetDirectionToFrontToBack();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetDirectionToSpecifiedVector()
		CODE:
		THIS->SetDirectionToSpecifiedVector();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDepthSortPolyData::SetOrigin\n");



void
vtkDepthSortPolyData::SetProp3D(arg1)
		vtkProp3D *	arg1
		CODE:
		THIS->SetProp3D(arg1);
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetSortScalars(arg1)
		int 	arg1
		CODE:
		THIS->SetSortScalars(arg1);
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SetVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetVector(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDepthSortPolyData::SetVector\n");



void
vtkDepthSortPolyData::SortScalarsOff()
		CODE:
		THIS->SortScalarsOff();
		XSRETURN_EMPTY;


void
vtkDepthSortPolyData::SortScalarsOn()
		CODE:
		THIS->SortScalarsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::EarthSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEarthSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkEarthSource::GetOnRatio()
		CODE:
		RETVAL = THIS->GetOnRatio();
		OUTPUT:
		RETVAL


int
vtkEarthSource::GetOnRatioMaxValue()
		CODE:
		RETVAL = THIS->GetOnRatioMaxValue();
		OUTPUT:
		RETVAL


int
vtkEarthSource::GetOnRatioMinValue()
		CODE:
		RETVAL = THIS->GetOnRatioMinValue();
		OUTPUT:
		RETVAL


int
vtkEarthSource::GetOutline()
		CODE:
		RETVAL = THIS->GetOutline();
		OUTPUT:
		RETVAL


float
vtkEarthSource::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkEarthSource::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkEarthSource::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


static vtkEarthSource*
vtkEarthSource::New()
		CODE:
		RETVAL = vtkEarthSource::New();
		OUTPUT:
		RETVAL


void
vtkEarthSource::OutlineOff()
		CODE:
		THIS->OutlineOff();
		XSRETURN_EMPTY;


void
vtkEarthSource::OutlineOn()
		CODE:
		THIS->OutlineOn();
		XSRETURN_EMPTY;


void
vtkEarthSource::SetOnRatio(arg1)
		int 	arg1
		CODE:
		THIS->SetOnRatio(arg1);
		XSRETURN_EMPTY;


void
vtkEarthSource::SetOutline(arg1)
		int 	arg1
		CODE:
		THIS->SetOutline(arg1);
		XSRETURN_EMPTY;


void
vtkEarthSource::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::GridTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkGridTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkGridTransform::GetDisplacementGrid()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetDisplacementGrid();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkGridTransform::GetDisplacementScale()
		CODE:
		RETVAL = THIS->GetDisplacementScale();
		OUTPUT:
		RETVAL


float
vtkGridTransform::GetDisplacementShift()
		CODE:
		RETVAL = THIS->GetDisplacementShift();
		OUTPUT:
		RETVAL


int
vtkGridTransform::GetInterpolationMode()
		CODE:
		RETVAL = THIS->GetInterpolationMode();
		OUTPUT:
		RETVAL


const char *
vtkGridTransform::GetInterpolationModeAsString()
		CODE:
		RETVAL = THIS->GetInterpolationModeAsString();
		OUTPUT:
		RETVAL


unsigned long
vtkGridTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkGridTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkGridTransform*
vtkGridTransform::New()
		CODE:
		RETVAL = vtkGridTransform::New();
		OUTPUT:
		RETVAL


void
vtkGridTransform::SetDisplacementGrid(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetDisplacementGrid(arg1);
		XSRETURN_EMPTY;


void
vtkGridTransform::SetDisplacementScale(arg1)
		float 	arg1
		CODE:
		THIS->SetDisplacementScale(arg1);
		XSRETURN_EMPTY;


void
vtkGridTransform::SetDisplacementShift(arg1)
		float 	arg1
		CODE:
		THIS->SetDisplacementShift(arg1);
		XSRETURN_EMPTY;


void
vtkGridTransform::SetInterpolationMode(mode)
		int 	mode
		CODE:
		THIS->SetInterpolationMode(mode);
		XSRETURN_EMPTY;


void
vtkGridTransform::SetInterpolationModeToCubic()
		CODE:
		THIS->SetInterpolationModeToCubic();
		XSRETURN_EMPTY;


void
vtkGridTransform::SetInterpolationModeToLinear()
		CODE:
		THIS->SetInterpolationModeToLinear();
		XSRETURN_EMPTY;


void
vtkGridTransform::SetInterpolationModeToNearestNeighbor()
		CODE:
		THIS->SetInterpolationModeToNearestNeighbor();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::ImageToPolyDataFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageToPolyDataFilter::DecimationOff()
		CODE:
		THIS->DecimationOff();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::DecimationOn()
		CODE:
		THIS->DecimationOn();
		XSRETURN_EMPTY;


const char *
vtkImageToPolyDataFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetColorMode()
		CODE:
		RETVAL = THIS->GetColorMode();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetColorModeMaxValue()
		CODE:
		RETVAL = THIS->GetColorModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetColorModeMinValue()
		CODE:
		RETVAL = THIS->GetColorModeMinValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetDecimation()
		CODE:
		RETVAL = THIS->GetDecimation();
		OUTPUT:
		RETVAL


float
vtkImageToPolyDataFilter::GetDecimationError()
		CODE:
		RETVAL = THIS->GetDecimationError();
		OUTPUT:
		RETVAL


float
vtkImageToPolyDataFilter::GetDecimationErrorMaxValue()
		CODE:
		RETVAL = THIS->GetDecimationErrorMaxValue();
		OUTPUT:
		RETVAL


float
vtkImageToPolyDataFilter::GetDecimationErrorMinValue()
		CODE:
		RETVAL = THIS->GetDecimationErrorMinValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetError()
		CODE:
		RETVAL = THIS->GetError();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetErrorMaxValue()
		CODE:
		RETVAL = THIS->GetErrorMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetErrorMinValue()
		CODE:
		RETVAL = THIS->GetErrorMinValue();
		OUTPUT:
		RETVAL


vtkScalarsToColors *
vtkImageToPolyDataFilter::GetLookupTable()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkScalarsToColors";
		CODE:
		RETVAL = THIS->GetLookupTable();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetNumberOfSmoothingIterations()
		CODE:
		RETVAL = THIS->GetNumberOfSmoothingIterations();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetNumberOfSmoothingIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfSmoothingIterationsMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetNumberOfSmoothingIterationsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfSmoothingIterationsMinValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetOutputStyle()
		CODE:
		RETVAL = THIS->GetOutputStyle();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetOutputStyleMaxValue()
		CODE:
		RETVAL = THIS->GetOutputStyleMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetOutputStyleMinValue()
		CODE:
		RETVAL = THIS->GetOutputStyleMinValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetSmoothing()
		CODE:
		RETVAL = THIS->GetSmoothing();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetSubImageSize()
		CODE:
		RETVAL = THIS->GetSubImageSize();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetSubImageSizeMaxValue()
		CODE:
		RETVAL = THIS->GetSubImageSizeMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageToPolyDataFilter::GetSubImageSizeMinValue()
		CODE:
		RETVAL = THIS->GetSubImageSizeMinValue();
		OUTPUT:
		RETVAL


static vtkImageToPolyDataFilter*
vtkImageToPolyDataFilter::New()
		CODE:
		RETVAL = vtkImageToPolyDataFilter::New();
		OUTPUT:
		RETVAL


void
vtkImageToPolyDataFilter::SetColorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetColorMode(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetColorModeToLUT()
		CODE:
		THIS->SetColorModeToLUT();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetColorModeToLinear256()
		CODE:
		THIS->SetColorModeToLinear256();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetDecimation(arg1)
		int 	arg1
		CODE:
		THIS->SetDecimation(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetDecimationError(arg1)
		float 	arg1
		CODE:
		THIS->SetDecimationError(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetError(arg1)
		int 	arg1
		CODE:
		THIS->SetError(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetLookupTable(arg1)
		vtkScalarsToColors *	arg1
		CODE:
		THIS->SetLookupTable(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetNumberOfSmoothingIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfSmoothingIterations(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetOutputStyle(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputStyle(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetOutputStyleToPixelize()
		CODE:
		THIS->SetOutputStyleToPixelize();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetOutputStyleToPolygonalize()
		CODE:
		THIS->SetOutputStyleToPolygonalize();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetOutputStyleToRunLength()
		CODE:
		THIS->SetOutputStyleToRunLength();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetSmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetSmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SetSubImageSize(arg1)
		int 	arg1
		CODE:
		THIS->SetSubImageSize(arg1);
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SmoothingOff()
		CODE:
		THIS->SmoothingOff();
		XSRETURN_EMPTY;


void
vtkImageToPolyDataFilter::SmoothingOn()
		CODE:
		THIS->SmoothingOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::ImplicitModeller PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImplicitModeller::AdjustBoundsOff()
		CODE:
		THIS->AdjustBoundsOff();
		XSRETURN_EMPTY;


void
vtkImplicitModeller::AdjustBoundsOn()
		CODE:
		THIS->AdjustBoundsOn();
		XSRETURN_EMPTY;


void
vtkImplicitModeller::Append(input)
		vtkDataSet *	input
		CODE:
		THIS->Append(input);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkImplicitModeller::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


float
vtkImplicitModeller::ComputeModelBounds(inputNULL)
		vtkDataSet *	inputNULL
		CODE:
		RETVAL = THIS->ComputeModelBounds(inputNULL);
		OUTPUT:
		RETVAL


void
vtkImplicitModeller::EndAppend()
		CODE:
		THIS->EndAppend();
		XSRETURN_EMPTY;


int
vtkImplicitModeller::GetAdjustBounds()
		CODE:
		RETVAL = THIS->GetAdjustBounds();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetAdjustDistance()
		CODE:
		RETVAL = THIS->GetAdjustDistance();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetAdjustDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetAdjustDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetAdjustDistanceMinValue()
		CODE:
		RETVAL = THIS->GetAdjustDistanceMinValue();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetCapValue()
		CODE:
		RETVAL = THIS->GetCapValue();
		OUTPUT:
		RETVAL


int
vtkImplicitModeller::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkImplicitModeller::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImplicitModeller::GetLocatorMaxLevel()
		CODE:
		RETVAL = THIS->GetLocatorMaxLevel();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetMaximumDistance()
		CODE:
		RETVAL = THIS->GetMaximumDistance();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetMaximumDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkImplicitModeller::GetMaximumDistanceMinValue()
		CODE:
		RETVAL = THIS->GetMaximumDistanceMinValue();
		OUTPUT:
		RETVAL


float  *
vtkImplicitModeller::GetModelBounds()
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
vtkImplicitModeller::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkImplicitModeller::GetProcessMode()
		CODE:
		RETVAL = THIS->GetProcessMode();
		OUTPUT:
		RETVAL


const char *
vtkImplicitModeller::GetProcessModeAsString()
		CODE:
		RETVAL = THIS->GetProcessModeAsString();
		OUTPUT:
		RETVAL


int
vtkImplicitModeller::GetProcessModeMaxValue()
		CODE:
		RETVAL = THIS->GetProcessModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkImplicitModeller::GetProcessModeMinValue()
		CODE:
		RETVAL = THIS->GetProcessModeMinValue();
		OUTPUT:
		RETVAL


int  *
vtkImplicitModeller::GetSampleDimensions()
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


static vtkImplicitModeller*
vtkImplicitModeller::New()
		CODE:
		RETVAL = vtkImplicitModeller::New();
		OUTPUT:
		RETVAL


void
vtkImplicitModeller::SetAdjustBounds(arg1)
		int 	arg1
		CODE:
		THIS->SetAdjustBounds(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetAdjustDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetAdjustDistance(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetCapValue(arg1)
		float 	arg1
		CODE:
		THIS->SetCapValue(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetLocatorMaxLevel(arg1)
		int 	arg1
		CODE:
		THIS->SetLocatorMaxLevel(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetMaximumDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumDistance(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkImplicitModeller::SetModelBounds\n");



void
vtkImplicitModeller::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetProcessMode(arg1)
		int 	arg1
		CODE:
		THIS->SetProcessMode(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetProcessModeToPerCell()
		CODE:
		THIS->SetProcessModeToPerCell();
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetProcessModeToPerVoxel()
		CODE:
		THIS->SetProcessModeToPerVoxel();
		XSRETURN_EMPTY;


void
vtkImplicitModeller::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitModeller::SetSampleDimensions\n");



void
vtkImplicitModeller::StartAppend()
		CODE:
		THIS->StartAppend();
		XSRETURN_EMPTY;


void
vtkImplicitModeller::UpdateData(output)
		vtkDataObject *	output
		CODE:
		THIS->UpdateData(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::IterativeClosestPointTransform PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkIterativeClosestPointTransform::CheckMeanDistanceOff()
		CODE:
		THIS->CheckMeanDistanceOff();
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::CheckMeanDistanceOn()
		CODE:
		THIS->CheckMeanDistanceOn();
		XSRETURN_EMPTY;


int
vtkIterativeClosestPointTransform::GetCheckMeanDistance()
		CODE:
		RETVAL = THIS->GetCheckMeanDistance();
		OUTPUT:
		RETVAL


const char *
vtkIterativeClosestPointTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkLandmarkTransform *
vtkIterativeClosestPointTransform::GetLandmarkTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLandmarkTransform";
		CODE:
		RETVAL = THIS->GetLandmarkTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCellLocator *
vtkIterativeClosestPointTransform::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkIterativeClosestPointTransform::GetMaximumMeanDistance()
		CODE:
		RETVAL = THIS->GetMaximumMeanDistance();
		OUTPUT:
		RETVAL


int
vtkIterativeClosestPointTransform::GetMaximumNumberOfIterations()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfIterations();
		OUTPUT:
		RETVAL


int
vtkIterativeClosestPointTransform::GetMaximumNumberOfLandmarks()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfLandmarks();
		OUTPUT:
		RETVAL


float
vtkIterativeClosestPointTransform::GetMeanDistance()
		CODE:
		RETVAL = THIS->GetMeanDistance();
		OUTPUT:
		RETVAL


int
vtkIterativeClosestPointTransform::GetMeanDistanceMode()
		CODE:
		RETVAL = THIS->GetMeanDistanceMode();
		OUTPUT:
		RETVAL


const char *
vtkIterativeClosestPointTransform::GetMeanDistanceModeAsString()
		CODE:
		RETVAL = THIS->GetMeanDistanceModeAsString();
		OUTPUT:
		RETVAL


int
vtkIterativeClosestPointTransform::GetMeanDistanceModeMaxValue()
		CODE:
		RETVAL = THIS->GetMeanDistanceModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkIterativeClosestPointTransform::GetMeanDistanceModeMinValue()
		CODE:
		RETVAL = THIS->GetMeanDistanceModeMinValue();
		OUTPUT:
		RETVAL


int
vtkIterativeClosestPointTransform::GetNumberOfIterations()
		CODE:
		RETVAL = THIS->GetNumberOfIterations();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkIterativeClosestPointTransform::GetSource()
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
vtkIterativeClosestPointTransform::GetStartByMatchingCentroids()
		CODE:
		RETVAL = THIS->GetStartByMatchingCentroids();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkIterativeClosestPointTransform::GetTarget()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetTarget();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkIterativeClosestPointTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkIterativeClosestPointTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkIterativeClosestPointTransform*
vtkIterativeClosestPointTransform::New()
		CODE:
		RETVAL = vtkIterativeClosestPointTransform::New();
		OUTPUT:
		RETVAL


void
vtkIterativeClosestPointTransform::SetCheckMeanDistance(arg1)
		int 	arg1
		CODE:
		THIS->SetCheckMeanDistance(arg1);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetLocator(locator)
		vtkCellLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetMaximumMeanDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumMeanDistance(arg1);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetMaximumNumberOfIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfIterations(arg1);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetMaximumNumberOfLandmarks(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfLandmarks(arg1);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetMeanDistanceMode(arg1)
		int 	arg1
		CODE:
		THIS->SetMeanDistanceMode(arg1);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetMeanDistanceModeToAbsoluteValue()
		CODE:
		THIS->SetMeanDistanceModeToAbsoluteValue();
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetMeanDistanceModeToRMS()
		CODE:
		THIS->SetMeanDistanceModeToRMS();
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetSource(source)
		vtkDataSet *	source
		CODE:
		THIS->SetSource(source);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetStartByMatchingCentroids(arg1)
		int 	arg1
		CODE:
		THIS->SetStartByMatchingCentroids(arg1);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::SetTarget(target)
		vtkDataSet *	target
		CODE:
		THIS->SetTarget(target);
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::StartByMatchingCentroidsOff()
		CODE:
		THIS->StartByMatchingCentroidsOff();
		XSRETURN_EMPTY;


void
vtkIterativeClosestPointTransform::StartByMatchingCentroidsOn()
		CODE:
		THIS->StartByMatchingCentroidsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::LandmarkTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLandmarkTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkLandmarkTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkLandmarkTransform::GetMode()
		CODE:
		RETVAL = THIS->GetMode();
		OUTPUT:
		RETVAL


const char *
vtkLandmarkTransform::GetModeAsString()
		CODE:
		RETVAL = THIS->GetModeAsString();
		OUTPUT:
		RETVAL


vtkPoints *
vtkLandmarkTransform::GetSourceLandmarks()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetSourceLandmarks();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPoints *
vtkLandmarkTransform::GetTargetLandmarks()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetTargetLandmarks();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkLandmarkTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkLandmarkTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkLandmarkTransform*
vtkLandmarkTransform::New()
		CODE:
		RETVAL = vtkLandmarkTransform::New();
		OUTPUT:
		RETVAL


void
vtkLandmarkTransform::SetMode(arg1)
		int 	arg1
		CODE:
		THIS->SetMode(arg1);
		XSRETURN_EMPTY;


void
vtkLandmarkTransform::SetModeToAffine()
		CODE:
		THIS->SetModeToAffine();
		XSRETURN_EMPTY;


void
vtkLandmarkTransform::SetModeToRigidBody()
		CODE:
		THIS->SetModeToRigidBody();
		XSRETURN_EMPTY;


void
vtkLandmarkTransform::SetModeToSimilarity()
		CODE:
		THIS->SetModeToSimilarity();
		XSRETURN_EMPTY;


void
vtkLandmarkTransform::SetSourceLandmarks(points)
		vtkPoints *	points
		CODE:
		THIS->SetSourceLandmarks(points);
		XSRETURN_EMPTY;


void
vtkLandmarkTransform::SetTargetLandmarks(points)
		vtkPoints *	points
		CODE:
		THIS->SetTargetLandmarks(points);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::LegendBoxActor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLegendBoxActor::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::BorderOff()
		CODE:
		THIS->BorderOff();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::BorderOn()
		CODE:
		THIS->BorderOn();
		XSRETURN_EMPTY;


int
vtkLegendBoxActor::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetBorder()
		CODE:
		RETVAL = THIS->GetBorder();
		OUTPUT:
		RETVAL


const char *
vtkLegendBoxActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkLegendBoxActor::GetEntryColor(i)
		int 	i
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetEntryColor(i);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkLegendBoxActor::GetEntryString(i)
		int 	i
		CODE:
		RETVAL = THIS->GetEntryString(i);
		OUTPUT:
		RETVAL


vtkPolyData *
vtkLegendBoxActor::GetEntrySymbol(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetEntrySymbol(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetLockBorder()
		CODE:
		RETVAL = THIS->GetLockBorder();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetNumberOfEntries()
		CODE:
		RETVAL = THIS->GetNumberOfEntries();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetPadding()
		CODE:
		RETVAL = THIS->GetPadding();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetPaddingMaxValue()
		CODE:
		RETVAL = THIS->GetPaddingMaxValue();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetPaddingMinValue()
		CODE:
		RETVAL = THIS->GetPaddingMinValue();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetScalarVisibility()
		CODE:
		RETVAL = THIS->GetScalarVisibility();
		OUTPUT:
		RETVAL


int
vtkLegendBoxActor::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


void
vtkLegendBoxActor::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::LockBorderOff()
		CODE:
		THIS->LockBorderOff();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::LockBorderOn()
		CODE:
		THIS->LockBorderOn();
		XSRETURN_EMPTY;


static vtkLegendBoxActor*
vtkLegendBoxActor::New()
		CODE:
		RETVAL = vtkLegendBoxActor::New();
		OUTPUT:
		RETVAL


void
vtkLegendBoxActor::ScalarVisibilityOff()
		CODE:
		THIS->ScalarVisibilityOff();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::ScalarVisibilityOn()
		CODE:
		THIS->ScalarVisibilityOn();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetBorder(arg1)
		int 	arg1
		CODE:
		THIS->SetBorder(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetEntryColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetEntryColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLegendBoxActor::SetEntryColor\n");



void
vtkLegendBoxActor::SetEntryString(i, string)
		int 	i
		const char *	string
		CODE:
		THIS->SetEntryString(i, string);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetEntrySymbol(i, symbol)
		int 	i
		vtkPolyData *	symbol
		CODE:
		THIS->SetEntrySymbol(i, symbol);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetLockBorder(arg1)
		int 	arg1
		CODE:
		THIS->SetLockBorder(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetNumberOfEntries(num)
		int 	num
		CODE:
		THIS->SetNumberOfEntries(num);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetPadding(arg1)
		int 	arg1
		CODE:
		THIS->SetPadding(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetScalarVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkLegendBoxActor::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::PolyDataToImageStencil PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPolyDataToImageStencil::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataToImageStencil::GetInput()
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


float
vtkPolyDataToImageStencil::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


static vtkPolyDataToImageStencil*
vtkPolyDataToImageStencil::New()
		CODE:
		RETVAL = vtkPolyDataToImageStencil::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataToImageStencil::SetInput(input)
		vtkPolyData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkPolyDataToImageStencil::SetTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::RIBExporter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRIBExporter::BackgroundOff()
		CODE:
		THIS->BackgroundOff();
		XSRETURN_EMPTY;


void
vtkRIBExporter::BackgroundOn()
		CODE:
		THIS->BackgroundOn();
		XSRETURN_EMPTY;


int
vtkRIBExporter::GetBackground()
		CODE:
		RETVAL = THIS->GetBackground();
		OUTPUT:
		RETVAL


const char *
vtkRIBExporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkRIBExporter::GetFilePrefix()
		CODE:
		RETVAL = THIS->GetFilePrefix();
		OUTPUT:
		RETVAL


int  *
vtkRIBExporter::GetPixelSamples()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPixelSamples();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int  *
vtkRIBExporter::GetSize()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


char *
vtkRIBExporter::GetTexturePrefix()
		CODE:
		RETVAL = THIS->GetTexturePrefix();
		OUTPUT:
		RETVAL


static vtkRIBExporter*
vtkRIBExporter::New()
		CODE:
		RETVAL = vtkRIBExporter::New();
		OUTPUT:
		RETVAL


void
vtkRIBExporter::SetBackground(arg1)
		int 	arg1
		CODE:
		THIS->SetBackground(arg1);
		XSRETURN_EMPTY;


void
vtkRIBExporter::SetFilePrefix(arg1)
		char *	arg1
		CODE:
		THIS->SetFilePrefix(arg1);
		XSRETURN_EMPTY;


void
vtkRIBExporter::SetPixelSamples(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPixelSamples(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRIBExporter::SetPixelSamples\n");



void
vtkRIBExporter::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRIBExporter::SetSize\n");



void
vtkRIBExporter::SetTexturePrefix(arg1)
		char *	arg1
		CODE:
		THIS->SetTexturePrefix(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::RIBLight PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRIBLight::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkRIBLight::GetShadows()
		CODE:
		RETVAL = THIS->GetShadows();
		OUTPUT:
		RETVAL


static vtkRIBLight*
vtkRIBLight::New()
		CODE:
		RETVAL = vtkRIBLight::New();
		OUTPUT:
		RETVAL


void
vtkRIBLight::Render(ren, index)
		vtkRenderer *	ren
		int 	index
		CODE:
		THIS->Render(ren, index);
		XSRETURN_EMPTY;


void
vtkRIBLight::SetShadows(arg1)
		int 	arg1
		CODE:
		THIS->SetShadows(arg1);
		XSRETURN_EMPTY;


void
vtkRIBLight::ShadowsOff()
		CODE:
		THIS->ShadowsOff();
		XSRETURN_EMPTY;


void
vtkRIBLight::ShadowsOn()
		CODE:
		THIS->ShadowsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::RIBProperty PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRIBProperty::AddParameter(parameter, value)
		char *	parameter
		char *	value
		CODE:
		THIS->AddParameter(parameter, value);
		XSRETURN_EMPTY;


void
vtkRIBProperty::AddVariable(variable, declaration)
		char *	variable
		char *	declaration
		CODE:
		THIS->AddVariable(variable, declaration);
		XSRETURN_EMPTY;


const char *
vtkRIBProperty::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkRIBProperty::GetDeclarations()
		CODE:
		RETVAL = THIS->GetDeclarations();
		OUTPUT:
		RETVAL


char *
vtkRIBProperty::GetDisplacementShader()
		CODE:
		RETVAL = THIS->GetDisplacementShader();
		OUTPUT:
		RETVAL


char *
vtkRIBProperty::GetParameters()
		CODE:
		RETVAL = THIS->GetParameters();
		OUTPUT:
		RETVAL


char *
vtkRIBProperty::GetSurfaceShader()
		CODE:
		RETVAL = THIS->GetSurfaceShader();
		OUTPUT:
		RETVAL


static vtkRIBProperty*
vtkRIBProperty::New()
		CODE:
		RETVAL = vtkRIBProperty::New();
		OUTPUT:
		RETVAL


void
vtkRIBProperty::SetDisplacementShader(arg1)
		char *	arg1
		CODE:
		THIS->SetDisplacementShader(arg1);
		XSRETURN_EMPTY;


void
vtkRIBProperty::SetParameter(parameter, value)
		char *	parameter
		char *	value
		CODE:
		THIS->SetParameter(parameter, value);
		XSRETURN_EMPTY;


void
vtkRIBProperty::SetSurfaceShader(arg1)
		char *	arg1
		CODE:
		THIS->SetSurfaceShader(arg1);
		XSRETURN_EMPTY;


void
vtkRIBProperty::SetVariable(variable, declaration)
		char *	variable
		char *	declaration
		CODE:
		THIS->SetVariable(variable, declaration);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::RenderLargeImage PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRenderLargeImage::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRenderer *
vtkRenderLargeImage::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkRenderLargeImage::GetMagnification()
		CODE:
		RETVAL = THIS->GetMagnification();
		OUTPUT:
		RETVAL


static vtkRenderLargeImage*
vtkRenderLargeImage::New()
		CODE:
		RETVAL = vtkRenderLargeImage::New();
		OUTPUT:
		RETVAL


void
vtkRenderLargeImage::SetInput(arg1)
		vtkRenderer *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkRenderLargeImage::SetMagnification(arg1)
		int 	arg1
		CODE:
		THIS->SetMagnification(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::ThinPlateSplineTransform PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkThinPlateSplineTransform::GetBasis()
		CODE:
		RETVAL = THIS->GetBasis();
		OUTPUT:
		RETVAL


const char *
vtkThinPlateSplineTransform::GetBasisAsString()
		CODE:
		RETVAL = THIS->GetBasisAsString();
		OUTPUT:
		RETVAL


const char *
vtkThinPlateSplineTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkThinPlateSplineTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


double
vtkThinPlateSplineTransform::GetSigma()
		CODE:
		RETVAL = THIS->GetSigma();
		OUTPUT:
		RETVAL


vtkPoints *
vtkThinPlateSplineTransform::GetSourceLandmarks()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetSourceLandmarks();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPoints *
vtkThinPlateSplineTransform::GetTargetLandmarks()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetTargetLandmarks();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkThinPlateSplineTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkThinPlateSplineTransform*
vtkThinPlateSplineTransform::New()
		CODE:
		RETVAL = vtkThinPlateSplineTransform::New();
		OUTPUT:
		RETVAL


void
vtkThinPlateSplineTransform::SetBasis(basis)
		int 	basis
		CODE:
		THIS->SetBasis(basis);
		XSRETURN_EMPTY;


void
vtkThinPlateSplineTransform::SetBasisToR()
		CODE:
		THIS->SetBasisToR();
		XSRETURN_EMPTY;


void
vtkThinPlateSplineTransform::SetBasisToR2LogR()
		CODE:
		THIS->SetBasisToR2LogR();
		XSRETURN_EMPTY;


void
vtkThinPlateSplineTransform::SetSigma(arg1)
		double 	arg1
		CODE:
		THIS->SetSigma(arg1);
		XSRETURN_EMPTY;


void
vtkThinPlateSplineTransform::SetSourceLandmarks(source)
		vtkPoints *	source
		CODE:
		THIS->SetSourceLandmarks(source);
		XSRETURN_EMPTY;


void
vtkThinPlateSplineTransform::SetTargetLandmarks(target)
		vtkPoints *	target
		CODE:
		THIS->SetTargetLandmarks(target);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::TransformToGrid PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTransformToGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkTransformToGrid::GetDisplacementScale()
		CODE:
		RETVAL = THIS->GetDisplacementScale();
		OUTPUT:
		RETVAL


float
vtkTransformToGrid::GetDisplacementShift()
		CODE:
		RETVAL = THIS->GetDisplacementShift();
		OUTPUT:
		RETVAL


int  *
vtkTransformToGrid::GetGridExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetGridExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


float  *
vtkTransformToGrid::GetGridOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetGridOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkTransformToGrid::GetGridScalarType()
		CODE:
		RETVAL = THIS->GetGridScalarType();
		OUTPUT:
		RETVAL


float  *
vtkTransformToGrid::GetGridSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetGridSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkAbstractTransform *
vtkTransformToGrid::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkTransformToGrid*
vtkTransformToGrid::New()
		CODE:
		RETVAL = vtkTransformToGrid::New();
		OUTPUT:
		RETVAL


void
vtkTransformToGrid::SetGridExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetGridExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformToGrid::SetGridExtent\n");



void
vtkTransformToGrid::SetGridOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetGridOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformToGrid::SetGridOrigin\n");



void
vtkTransformToGrid::SetGridScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetGridScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkTransformToGrid::SetGridScalarTypeToChar()
		CODE:
		THIS->SetGridScalarTypeToChar();
		XSRETURN_EMPTY;


void
vtkTransformToGrid::SetGridScalarTypeToFloat()
		CODE:
		THIS->SetGridScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkTransformToGrid::SetGridScalarTypeToShort()
		CODE:
		THIS->SetGridScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkTransformToGrid::SetGridScalarTypeToUnsignedChar()
		CODE:
		THIS->SetGridScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkTransformToGrid::SetGridScalarTypeToUnsignedShort()
		CODE:
		THIS->SetGridScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkTransformToGrid::SetGridSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetGridSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformToGrid::SetGridSpacing\n");



void
vtkTransformToGrid::SetInput(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::VRMLImporter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVRMLImporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


FILE *
vtkVRMLImporter::GetFileFD()
		CODE:
		RETVAL = THIS->GetFileFD();
		OUTPUT:
		RETVAL


char *
vtkVRMLImporter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


vtkObject *
vtkVRMLImporter::GetVRMLDEFObject(name)
		const char *	name
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkObject";
		CODE:
		RETVAL = THIS->GetVRMLDEFObject(name);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkVRMLImporter*
vtkVRMLImporter::New()
		CODE:
		RETVAL = vtkVRMLImporter::New();
		OUTPUT:
		RETVAL


void
vtkVRMLImporter::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkVRMLImporter::enterField(arg1)
		const char *	arg1
		CODE:
		THIS->enterField(arg1);
		XSRETURN_EMPTY;


void
vtkVRMLImporter::enterNode(arg1)
		const char *	arg1
		CODE:
		THIS->enterNode(arg1);
		XSRETURN_EMPTY;


void
vtkVRMLImporter::exitField()
		CODE:
		THIS->exitField();
		XSRETURN_EMPTY;


void
vtkVRMLImporter::exitNode()
		CODE:
		THIS->exitNode();
		XSRETURN_EMPTY;


void
vtkVRMLImporter::useNode(arg1)
		const char *	arg1
		CODE:
		THIS->useNode(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::VectorText PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVectorText::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkVectorText::GetText()
		CODE:
		RETVAL = THIS->GetText();
		OUTPUT:
		RETVAL


static vtkVectorText*
vtkVectorText::New()
		CODE:
		RETVAL = vtkVectorText::New();
		OUTPUT:
		RETVAL


void
vtkVectorText::SetText(arg1)
		char *	arg1
		CODE:
		THIS->SetText(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::VideoSource PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVideoSource::AutoAdvanceOff()
		CODE:
		THIS->AutoAdvanceOff();
		XSRETURN_EMPTY;


void
vtkVideoSource::AutoAdvanceOn()
		CODE:
		THIS->AutoAdvanceOn();
		XSRETURN_EMPTY;


void
vtkVideoSource::FastForward()
		CODE:
		THIS->FastForward();
		XSRETURN_EMPTY;


int
vtkVideoSource::GetAutoAdvance()
		CODE:
		RETVAL = THIS->GetAutoAdvance();
		OUTPUT:
		RETVAL


const char *
vtkVideoSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkVideoSource::GetClipRegion()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetClipRegion();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


float  *
vtkVideoSource::GetDataOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkVideoSource::GetDataSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkVideoSource::GetFrameBufferSize()
		CODE:
		RETVAL = THIS->GetFrameBufferSize();
		OUTPUT:
		RETVAL


int
vtkVideoSource::GetFrameCount()
		CODE:
		RETVAL = THIS->GetFrameCount();
		OUTPUT:
		RETVAL


int
vtkVideoSource::GetFrameIndex()
		CODE:
		RETVAL = THIS->GetFrameIndex();
		OUTPUT:
		RETVAL


float
vtkVideoSource::GetFrameRate()
		CODE:
		RETVAL = THIS->GetFrameRate();
		OUTPUT:
		RETVAL


int  *
vtkVideoSource::GetFrameSize()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFrameSize();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double
vtkVideoSource::GetFrameTimeStamp(arg1 = 0)
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetFrameTimeStamp(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetFrameTimeStamp();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVideoSource::GetFrameTimeStamp\n");



int
vtkVideoSource::GetInitialized()
		CODE:
		RETVAL = THIS->GetInitialized();
		OUTPUT:
		RETVAL


int
vtkVideoSource::GetNumberOfOutputFrames()
		CODE:
		RETVAL = THIS->GetNumberOfOutputFrames();
		OUTPUT:
		RETVAL


float
vtkVideoSource::GetOpacity()
		CODE:
		RETVAL = THIS->GetOpacity();
		OUTPUT:
		RETVAL


int
vtkVideoSource::GetOutputFormat()
		CODE:
		RETVAL = THIS->GetOutputFormat();
		OUTPUT:
		RETVAL


int  *
vtkVideoSource::GetOutputWholeExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputWholeExtent();
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
vtkVideoSource::GetPlaying()
		CODE:
		RETVAL = THIS->GetPlaying();
		OUTPUT:
		RETVAL


int
vtkVideoSource::GetRecording()
		CODE:
		RETVAL = THIS->GetRecording();
		OUTPUT:
		RETVAL


void
vtkVideoSource::Grab()
		CODE:
		THIS->Grab();
		XSRETURN_EMPTY;


void
vtkVideoSource::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkVideoSource::InternalGrab()
		CODE:
		THIS->InternalGrab();
		XSRETURN_EMPTY;


static vtkVideoSource*
vtkVideoSource::New()
		CODE:
		RETVAL = vtkVideoSource::New();
		OUTPUT:
		RETVAL


void
vtkVideoSource::Play()
		CODE:
		THIS->Play();
		XSRETURN_EMPTY;


void
vtkVideoSource::Record()
		CODE:
		THIS->Record();
		XSRETURN_EMPTY;


void
vtkVideoSource::ReleaseSystemResources()
		CODE:
		THIS->ReleaseSystemResources();
		XSRETURN_EMPTY;


void
vtkVideoSource::Rewind()
		CODE:
		THIS->Rewind();
		XSRETURN_EMPTY;


void
vtkVideoSource::Seek(n)
		int 	n
		CODE:
		THIS->Seek(n);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetAutoAdvance(arg1)
		int 	arg1
		CODE:
		THIS->SetAutoAdvance(arg1);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetClipRegion(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetClipRegion(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVideoSource::SetClipRegion\n");



void
vtkVideoSource::SetDataOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVideoSource::SetDataOrigin\n");



void
vtkVideoSource::SetDataSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVideoSource::SetDataSpacing\n");



void
vtkVideoSource::SetFrameBufferSize(FrameBufferSize)
		int 	FrameBufferSize
		CODE:
		THIS->SetFrameBufferSize(FrameBufferSize);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetFrameCount(arg1)
		int 	arg1
		CODE:
		THIS->SetFrameCount(arg1);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetFrameRate(rate)
		float 	rate
		CODE:
		THIS->SetFrameRate(rate);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetFrameSize(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetFrameSize(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVideoSource::SetFrameSize\n");



void
vtkVideoSource::SetNumberOfOutputFrames(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfOutputFrames(arg1);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetOpacity(arg1)
		float 	arg1
		CODE:
		THIS->SetOpacity(arg1);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetOutputFormat(format)
		int 	format
		CODE:
		THIS->SetOutputFormat(format);
		XSRETURN_EMPTY;


void
vtkVideoSource::SetOutputFormatToLuminance()
		CODE:
		THIS->SetOutputFormatToLuminance();
		XSRETURN_EMPTY;


void
vtkVideoSource::SetOutputFormatToRGB()
		CODE:
		THIS->SetOutputFormatToRGB();
		XSRETURN_EMPTY;


void
vtkVideoSource::SetOutputFormatToRGBA()
		CODE:
		THIS->SetOutputFormatToRGBA();
		XSRETURN_EMPTY;


void
vtkVideoSource::SetOutputWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetOutputWholeExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVideoSource::SetOutputWholeExtent\n");



void
vtkVideoSource::Stop()
		CODE:
		THIS->Stop();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::WeightedTransformFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWeightedTransformFilter::AddInputValuesOff()
		CODE:
		THIS->AddInputValuesOff();
		XSRETURN_EMPTY;


void
vtkWeightedTransformFilter::AddInputValuesOn()
		CODE:
		THIS->AddInputValuesOn();
		XSRETURN_EMPTY;


int
vtkWeightedTransformFilter::GetAddInputValues()
		CODE:
		RETVAL = THIS->GetAddInputValues();
		OUTPUT:
		RETVAL


char *
vtkWeightedTransformFilter::GetCellDataWeightArray()
		CODE:
		RETVAL = THIS->GetCellDataWeightArray();
		OUTPUT:
		RETVAL


const char *
vtkWeightedTransformFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkWeightedTransformFilter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkWeightedTransformFilter::GetNumberOfTransforms()
		CODE:
		RETVAL = THIS->GetNumberOfTransforms();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkWeightedTransformFilter::GetTransform(num)
		int 	num
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetTransform(num);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


char *
vtkWeightedTransformFilter::GetWeightArray()
		CODE:
		RETVAL = THIS->GetWeightArray();
		OUTPUT:
		RETVAL


static vtkWeightedTransformFilter*
vtkWeightedTransformFilter::New()
		CODE:
		RETVAL = vtkWeightedTransformFilter::New();
		OUTPUT:
		RETVAL


void
vtkWeightedTransformFilter::SetAddInputValues(arg1)
		int 	arg1
		CODE:
		THIS->SetAddInputValues(arg1);
		XSRETURN_EMPTY;


void
vtkWeightedTransformFilter::SetCellDataWeightArray(arg1)
		char *	arg1
		CODE:
		THIS->SetCellDataWeightArray(arg1);
		XSRETURN_EMPTY;


void
vtkWeightedTransformFilter::SetNumberOfTransforms(num)
		int 	num
		CODE:
		THIS->SetNumberOfTransforms(num);
		XSRETURN_EMPTY;


void
vtkWeightedTransformFilter::SetTransform(transform, num)
		vtkAbstractTransform *	transform
		int 	num
		CODE:
		THIS->SetTransform(transform, num);
		XSRETURN_EMPTY;


void
vtkWeightedTransformFilter::SetWeightArray(arg1)
		char *	arg1
		CODE:
		THIS->SetWeightArray(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Hybrid	PACKAGE = Graphics::VTK::XYPlotActor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkXYPlotActor::AddDataObjectInput(in)
		vtkDataObject *	in
		CODE:
		THIS->AddDataObjectInput(in);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::AddInput(in)
		vtkDataSet *	in
		CODE:
		THIS->AddInput(in);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ExchangeAxesOff()
		CODE:
		THIS->ExchangeAxesOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ExchangeAxesOn()
		CODE:
		THIS->ExchangeAxesOn();
		XSRETURN_EMPTY;


int
vtkXYPlotActor::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetBorder()
		CODE:
		RETVAL = THIS->GetBorder();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetBorderMaxValue()
		CODE:
		RETVAL = THIS->GetBorderMaxValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetBorderMinValue()
		CODE:
		RETVAL = THIS->GetBorderMinValue();
		OUTPUT:
		RETVAL


const char *
vtkXYPlotActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataObjectCollection *
vtkXYPlotActor::GetDataObjectInputList()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObjectCollection";
		CODE:
		RETVAL = THIS->GetDataObjectInputList();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetDataObjectPlotMode()
		CODE:
		RETVAL = THIS->GetDataObjectPlotMode();
		OUTPUT:
		RETVAL


const char *
vtkXYPlotActor::GetDataObjectPlotModeAsString()
		CODE:
		RETVAL = THIS->GetDataObjectPlotModeAsString();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetDataObjectPlotModeMaxValue()
		CODE:
		RETVAL = THIS->GetDataObjectPlotModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetDataObjectPlotModeMinValue()
		CODE:
		RETVAL = THIS->GetDataObjectPlotModeMinValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetDataObjectXComponent(i)
		int 	i
		CODE:
		RETVAL = THIS->GetDataObjectXComponent(i);
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetDataObjectYComponent(i)
		int 	i
		CODE:
		RETVAL = THIS->GetDataObjectYComponent(i);
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetExchangeAxes()
		CODE:
		RETVAL = THIS->GetExchangeAxes();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


float
vtkXYPlotActor::GetGlyphSize()
		CODE:
		RETVAL = THIS->GetGlyphSize();
		OUTPUT:
		RETVAL


float
vtkXYPlotActor::GetGlyphSizeMaxValue()
		CODE:
		RETVAL = THIS->GetGlyphSizeMaxValue();
		OUTPUT:
		RETVAL


float
vtkXYPlotActor::GetGlyphSizeMinValue()
		CODE:
		RETVAL = THIS->GetGlyphSizeMinValue();
		OUTPUT:
		RETVAL


vtkGlyphSource2D *
vtkXYPlotActor::GetGlyphSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkGlyphSource2D";
		CODE:
		RETVAL = THIS->GetGlyphSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSetCollection *
vtkXYPlotActor::GetInputList()
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


int
vtkXYPlotActor::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


char *
vtkXYPlotActor::GetLabelFormat()
		CODE:
		RETVAL = THIS->GetLabelFormat();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetLegend()
		CODE:
		RETVAL = THIS->GetLegend();
		OUTPUT:
		RETVAL


vtkLegendBoxActor *
vtkXYPlotActor::GetLegendBoxActor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLegendBoxActor";
		CODE:
		RETVAL = THIS->GetLegendBoxActor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkXYPlotActor::GetLegendPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetLegendPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkXYPlotActor::GetLegendPosition2()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetLegendPosition2();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkXYPlotActor::GetLogx()
		CODE:
		RETVAL = THIS->GetLogx();
		OUTPUT:
		RETVAL


unsigned long
vtkXYPlotActor::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetNumberOfXLabels()
		CODE:
		RETVAL = THIS->GetNumberOfXLabels();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetNumberOfXLabelsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfXLabelsMaxValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetNumberOfXLabelsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfXLabelsMinValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetNumberOfYLabels()
		CODE:
		RETVAL = THIS->GetNumberOfYLabels();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetNumberOfYLabelsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfYLabelsMaxValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetNumberOfYLabelsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfYLabelsMinValue();
		OUTPUT:
		RETVAL


float *
vtkXYPlotActor::GetPlotColor(i)
		int 	i
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPlotColor(i);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkXYPlotActor::GetPlotCoordinate()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPlotCoordinate();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkXYPlotActor::GetPlotCurveLines()
		CODE:
		RETVAL = THIS->GetPlotCurveLines();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetPlotCurvePoints()
		CODE:
		RETVAL = THIS->GetPlotCurvePoints();
		OUTPUT:
		RETVAL


const char *
vtkXYPlotActor::GetPlotLabel(i)
		int 	i
		CODE:
		RETVAL = THIS->GetPlotLabel(i);
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetPlotLines(arg1 = 0)
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetPlotLines(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetPlotLines();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::GetPlotLines\n");



int
vtkXYPlotActor::GetPlotPoints(arg1 = 0)
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetPlotPoints(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetPlotPoints();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::GetPlotPoints\n");



vtkPolyData *
vtkXYPlotActor::GetPlotSymbol(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetPlotSymbol(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetPointComponent(i)
		int 	i
		CODE:
		RETVAL = THIS->GetPointComponent(i);
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetReverseXAxis()
		CODE:
		RETVAL = THIS->GetReverseXAxis();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetReverseYAxis()
		CODE:
		RETVAL = THIS->GetReverseYAxis();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


char *
vtkXYPlotActor::GetTitle()
		CODE:
		RETVAL = THIS->GetTitle();
		OUTPUT:
		RETVAL


float  *
vtkXYPlotActor::GetViewportCoordinate()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetViewportCoordinate();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkXYPlotActor::GetXRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetXRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


char *
vtkXYPlotActor::GetXTitle()
		CODE:
		RETVAL = THIS->GetXTitle();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetXValues()
		CODE:
		RETVAL = THIS->GetXValues();
		OUTPUT:
		RETVAL


const char *
vtkXYPlotActor::GetXValuesAsString()
		CODE:
		RETVAL = THIS->GetXValuesAsString();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetXValuesMaxValue()
		CODE:
		RETVAL = THIS->GetXValuesMaxValue();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::GetXValuesMinValue()
		CODE:
		RETVAL = THIS->GetXValuesMinValue();
		OUTPUT:
		RETVAL


float  *
vtkXYPlotActor::GetYRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetYRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


char *
vtkXYPlotActor::GetYTitle()
		CODE:
		RETVAL = THIS->GetYTitle();
		OUTPUT:
		RETVAL


int
vtkXYPlotActor::IsInPlot(viewport, u, v)
		vtkViewport *	viewport
		float 	u
		float 	v
		CODE:
		RETVAL = THIS->IsInPlot(viewport, u, v);
		OUTPUT:
		RETVAL


void
vtkXYPlotActor::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::LegendOff()
		CODE:
		THIS->LegendOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::LegendOn()
		CODE:
		THIS->LegendOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::LogxOff()
		CODE:
		THIS->LogxOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::LogxOn()
		CODE:
		THIS->LogxOn();
		XSRETURN_EMPTY;


static vtkXYPlotActor*
vtkXYPlotActor::New()
		CODE:
		RETVAL = vtkXYPlotActor::New();
		OUTPUT:
		RETVAL


void
vtkXYPlotActor::PlotCurveLinesOff()
		CODE:
		THIS->PlotCurveLinesOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotCurveLinesOn()
		CODE:
		THIS->PlotCurveLinesOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotCurvePointsOff()
		CODE:
		THIS->PlotCurvePointsOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotCurvePointsOn()
		CODE:
		THIS->PlotCurvePointsOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotLinesOff()
		CODE:
		THIS->PlotLinesOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotLinesOn()
		CODE:
		THIS->PlotLinesOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotPointsOff()
		CODE:
		THIS->PlotPointsOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotPointsOn()
		CODE:
		THIS->PlotPointsOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::PlotToViewportCoordinate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		vtkViewport *	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->PlotToViewportCoordinate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg2
		arg3
	CASE: items == 2
		vtkViewport *	arg1
		CODE:
		THIS->PlotToViewportCoordinate(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::PlotToViewportCoordinate\n");



void
vtkXYPlotActor::RemoveDataObjectInput(in)
		vtkDataObject *	in
		CODE:
		THIS->RemoveDataObjectInput(in);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::RemoveInput(in)
		vtkDataSet *	in
		CODE:
		THIS->RemoveInput(in);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ReverseXAxisOff()
		CODE:
		THIS->ReverseXAxisOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ReverseXAxisOn()
		CODE:
		THIS->ReverseXAxisOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ReverseYAxisOff()
		CODE:
		THIS->ReverseYAxisOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ReverseYAxisOn()
		CODE:
		THIS->ReverseYAxisOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetBorder(arg1)
		int 	arg1
		CODE:
		THIS->SetBorder(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetDataObjectPlotMode(arg1)
		int 	arg1
		CODE:
		THIS->SetDataObjectPlotMode(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetDataObjectPlotModeToColumns()
		CODE:
		THIS->SetDataObjectPlotModeToColumns();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetDataObjectPlotModeToRows()
		CODE:
		THIS->SetDataObjectPlotModeToRows();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetDataObjectXComponent(i, comp)
		int 	i
		int 	comp
		CODE:
		THIS->SetDataObjectXComponent(i, comp);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetDataObjectYComponent(i, comp)
		int 	i
		int 	comp
		CODE:
		THIS->SetDataObjectYComponent(i, comp);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetExchangeAxes(arg1)
		int 	arg1
		CODE:
		THIS->SetExchangeAxes(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetGlyphSize(arg1)
		float 	arg1
		CODE:
		THIS->SetGlyphSize(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetLabelFormat(arg1)
		char *	arg1
		CODE:
		THIS->SetLabelFormat(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetLegend(arg1)
		int 	arg1
		CODE:
		THIS->SetLegend(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetLegendPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetLegendPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetLegendPosition\n");



void
vtkXYPlotActor::SetLegendPosition2(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetLegendPosition2(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetLegendPosition2\n");



void
vtkXYPlotActor::SetLogx(arg1)
		int 	arg1
		CODE:
		THIS->SetLogx(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetNumberOfLabels(num)
		int 	num
		CODE:
		THIS->SetNumberOfLabels(num);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetNumberOfXLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfXLabels(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetNumberOfYLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfYLabels(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetPlotColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetPlotColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetPlotColor\n");



void
vtkXYPlotActor::SetPlotCoordinate(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetPlotCoordinate(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetPlotCoordinate\n");



void
vtkXYPlotActor::SetPlotCurveLines(arg1)
		int 	arg1
		CODE:
		THIS->SetPlotCurveLines(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetPlotCurvePoints(arg1)
		int 	arg1
		CODE:
		THIS->SetPlotCurvePoints(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetPlotLabel(i, label)
		int 	i
		const char *	label
		CODE:
		THIS->SetPlotLabel(i, label);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetPlotLines(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPlotLines(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		int 	arg1
		CODE:
		THIS->SetPlotLines(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetPlotLines\n");



void
vtkXYPlotActor::SetPlotPoints(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPlotPoints(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		int 	arg1
		CODE:
		THIS->SetPlotPoints(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetPlotPoints\n");



void
vtkXYPlotActor::SetPlotRange(xmin, ymin, xmax, ymax)
		float 	xmin
		float 	ymin
		float 	xmax
		float 	ymax
		CODE:
		THIS->SetPlotRange(xmin, ymin, xmax, ymax);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetPlotSymbol(i, input)
		int 	i
		vtkPolyData *	input
		CODE:
		THIS->SetPlotSymbol(i, input);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetPointComponent(i, comp)
		int 	i
		int 	comp
		CODE:
		THIS->SetPointComponent(i, comp);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetReverseXAxis(arg1)
		int 	arg1
		CODE:
		THIS->SetReverseXAxis(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetReverseYAxis(arg1)
		int 	arg1
		CODE:
		THIS->SetReverseYAxis(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetTitle(arg1)
		char *	arg1
		CODE:
		THIS->SetTitle(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetViewportCoordinate(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetViewportCoordinate(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetViewportCoordinate\n");



void
vtkXYPlotActor::SetXRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetXRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetXRange\n");



void
vtkXYPlotActor::SetXTitle(arg1)
		char *	arg1
		CODE:
		THIS->SetXTitle(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetXValues(arg1)
		int 	arg1
		CODE:
		THIS->SetXValues(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetXValuesToArcLength()
		CODE:
		THIS->SetXValuesToArcLength();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetXValuesToIndex()
		CODE:
		THIS->SetXValuesToIndex();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetXValuesToNormalizedArcLength()
		CODE:
		THIS->SetXValuesToNormalizedArcLength();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetXValuesToValue()
		CODE:
		THIS->SetXValuesToValue();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::SetYRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetYRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::SetYRange\n");



void
vtkXYPlotActor::SetYTitle(arg1)
		char *	arg1
		CODE:
		THIS->SetYTitle(arg1);
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkXYPlotActor::ViewportToPlotCoordinate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		vtkViewport *	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->ViewportToPlotCoordinate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg2
		arg3
	CASE: items == 2
		vtkViewport *	arg1
		CODE:
		THIS->ViewportToPlotCoordinate(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXYPlotActor::ViewportToPlotCoordinate\n");



