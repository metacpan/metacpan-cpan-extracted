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
#include "vtkBooleanTexture.h"
#include "vtkExtractVOI.h"
#include "vtkGaussianSplatter.h"
#include "vtkImageAccumulate.h"
#include "vtkImageAnisotropicDiffusion2D.h"
#include "vtkImageAnisotropicDiffusion3D.h"
#include "vtkImageAppend.h"
#include "vtkImageAppendComponents.h"
#include "vtkImageBlend.h"
#include "vtkImageButterworthHighPass.h"
#include "vtkImageButterworthLowPass.h"
#include "vtkImageCacheFilter.h"
#include "vtkImageCanvasSource2D.h"
#include "vtkImageCast.h"
#include "vtkImageChangeInformation.h"
#include "vtkImageCheckerboard.h"
#include "vtkImageCityBlockDistance.h"
#include "vtkImageClip.h"
#include "vtkImageConnector.h"
#include "vtkImageConstantPad.h"
#include "vtkImageContinuousDilate3D.h"
#include "vtkImageContinuousErode3D.h"
#include "vtkImageConvolve.h"
#include "vtkImageCorrelation.h"
#include "vtkImageCursor3D.h"
#include "vtkImageDataStreamer.h"
#include "vtkImageDecomposeFilter.h"
#include "vtkImageDifference.h"
#include "vtkImageDilateErode3D.h"
#include "vtkImageDivergence.h"
#include "vtkImageDotProduct.h"
#include "vtkImageEllipsoidSource.h"
#include "vtkImageEuclideanDistance.h"
#include "vtkImageEuclideanToPolar.h"
#include "vtkImageExport.h"
#include "vtkImageExtractComponents.h"
#include "vtkImageFFT.h"
#include "vtkImageFlip.h"
#include "vtkImageFourierCenter.h"
#include "vtkImageFourierFilter.h"
#include "vtkImageGaussianSmooth.h"
#include "vtkImageGaussianSource.h"
#include "vtkImageGradient.h"
#include "vtkImageGradientMagnitude.h"
#include "vtkImageGridSource.h"
#include "vtkImageHSVToRGB.h"
#include "vtkImageHybridMedian2D.h"
#include "vtkImageIdealHighPass.h"
#include "vtkImageIdealLowPass.h"
#include "vtkImageImport.h"
#include "vtkImageIslandRemoval2D.h"
#include "vtkImageIterateFilter.h"
#include "vtkImageLaplacian.h"
#include "vtkImageLogarithmicScale.h"
#include "vtkImageLogic.h"
#include "vtkImageLuminance.h"
#include "vtkImageMagnify.h"
#include "vtkImageMagnitude.h"
#include "vtkImageMandelbrotSource.h"
#include "vtkImageMapToColors.h"
#include "vtkImageMapToRGBA.h"
#include "vtkImageMapToWindowLevelColors.h"
#include "vtkImageMask.h"
#include "vtkImageMaskBits.h"
#include "vtkImageMathematics.h"
#include "vtkImageMedian3D.h"
#include "vtkImageMirrorPad.h"
#include "vtkImageNoiseSource.h"
#include "vtkImageNonMaximumSuppression.h"
#include "vtkImageNormalize.h"
#include "vtkImageOpenClose3D.h"
#include "vtkImagePadFilter.h"
#include "vtkImagePermute.h"
#include "vtkImageQuantizeRGBToIndex.h"
#include "vtkImageRFFT.h"
#include "vtkImageRGBToHSV.h"
#include "vtkImageRange3D.h"
#include "vtkImageResample.h"
#include "vtkImageReslice.h"
#include "vtkImageSeedConnectivity.h"
#include "vtkImageShiftScale.h"
#include "vtkImageShrink3D.h"
#include "vtkImageSinusoidSource.h"
#include "vtkImageSkeleton2D.h"
#include "vtkImageSobel2D.h"
#include "vtkImageSobel3D.h"
#include "vtkImageSpatialFilter.h"
#include "vtkImageStencil.h"
#include "vtkImageStencilData.h"
#include "vtkImageStencilSource.h"
#include "vtkImageThreshold.h"
#include "vtkImageToImageStencil.h"
#include "vtkImageTranslateExtent.h"
#include "vtkImageVariance3D.h"
#include "vtkImageWrapPad.h"
#include "vtkImplicitFunctionToImageStencil.h"
#include "vtkPointLoad.h"
#include "vtkSampleFunction.h"
#include "vtkShepardMethod.h"
#include "vtkSimpleImageFilterExample.h"
#include "vtkSurfaceReconstructionFilter.h"
#include "vtkTriangularTexture.h"
#include "vtkVoxelModeller.h"
#include "vtkWindowToImageFilter.h"
#include "vtkWindow.h"
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

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::BooleanTexture PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkBooleanTexture::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned char  *
vtkBooleanTexture::GetInIn()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetInIn();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetInOn()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetInOn();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetInOut()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetInOut();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetOnIn()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOnIn();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetOnOn()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOnOn();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetOnOut()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOnOut();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetOutIn()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutIn();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetOutOn()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutOn();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned char  *
vtkBooleanTexture::GetOutOut()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutOut();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkBooleanTexture::GetThickness()
		CODE:
		RETVAL = THIS->GetThickness();
		OUTPUT:
		RETVAL


int
vtkBooleanTexture::GetXSize()
		CODE:
		RETVAL = THIS->GetXSize();
		OUTPUT:
		RETVAL


int
vtkBooleanTexture::GetYSize()
		CODE:
		RETVAL = THIS->GetYSize();
		OUTPUT:
		RETVAL


static vtkBooleanTexture*
vtkBooleanTexture::New()
		CODE:
		RETVAL = vtkBooleanTexture::New();
		OUTPUT:
		RETVAL


void
vtkBooleanTexture::SetInIn(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetInIn(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetInIn\n");



void
vtkBooleanTexture::SetInOn(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetInOn(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetInOn\n");



void
vtkBooleanTexture::SetInOut(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetInOut(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetInOut\n");



void
vtkBooleanTexture::SetOnIn(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetOnIn(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetOnIn\n");



void
vtkBooleanTexture::SetOnOn(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetOnOn(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetOnOn\n");



void
vtkBooleanTexture::SetOnOut(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetOnOut(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetOnOut\n");



void
vtkBooleanTexture::SetOutIn(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetOutIn(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetOutIn\n");



void
vtkBooleanTexture::SetOutOn(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetOutOn(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetOutOn\n");



void
vtkBooleanTexture::SetOutOut(arg1 = 0, arg2 = 0)
	CASE: items == 3
		unsigned char 	arg1
		unsigned char 	arg2
		CODE:
		THIS->SetOutOut(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBooleanTexture::SetOutOut\n");



void
vtkBooleanTexture::SetThickness(arg1)
		int 	arg1
		CODE:
		THIS->SetThickness(arg1);
		XSRETURN_EMPTY;


void
vtkBooleanTexture::SetXSize(arg1)
		int 	arg1
		CODE:
		THIS->SetXSize(arg1);
		XSRETURN_EMPTY;


void
vtkBooleanTexture::SetYSize(arg1)
		int 	arg1
		CODE:
		THIS->SetYSize(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ExtractVOI PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkExtractVOI::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkExtractVOI::GetSampleRate()
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
vtkExtractVOI::GetVOI()
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


static vtkExtractVOI*
vtkExtractVOI::New()
		CODE:
		RETVAL = vtkExtractVOI::New();
		OUTPUT:
		RETVAL


void
vtkExtractVOI::SetSampleRate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleRate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtractVOI::SetSampleRate\n");



void
vtkExtractVOI::SetVOI(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkExtractVOI::SetVOI\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::GaussianSplatter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGaussianSplatter::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::ComputeModelBounds()
		CODE:
		THIS->ComputeModelBounds();
		XSRETURN_EMPTY;


int
vtkGaussianSplatter::GetAccumulationMode()
		CODE:
		RETVAL = THIS->GetAccumulationMode();
		OUTPUT:
		RETVAL


const char *
vtkGaussianSplatter::GetAccumulationModeAsString()
		CODE:
		RETVAL = THIS->GetAccumulationModeAsString();
		OUTPUT:
		RETVAL


int
vtkGaussianSplatter::GetAccumulationModeMaxValue()
		CODE:
		RETVAL = THIS->GetAccumulationModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkGaussianSplatter::GetAccumulationModeMinValue()
		CODE:
		RETVAL = THIS->GetAccumulationModeMinValue();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetCapValue()
		CODE:
		RETVAL = THIS->GetCapValue();
		OUTPUT:
		RETVAL


int
vtkGaussianSplatter::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkGaussianSplatter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetEccentricity()
		CODE:
		RETVAL = THIS->GetEccentricity();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetEccentricityMaxValue()
		CODE:
		RETVAL = THIS->GetEccentricityMaxValue();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetEccentricityMinValue()
		CODE:
		RETVAL = THIS->GetEccentricityMinValue();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetExponentFactor()
		CODE:
		RETVAL = THIS->GetExponentFactor();
		OUTPUT:
		RETVAL


float  *
vtkGaussianSplatter::GetModelBounds()
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
vtkGaussianSplatter::GetNormalWarping()
		CODE:
		RETVAL = THIS->GetNormalWarping();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetNullValue()
		CODE:
		RETVAL = THIS->GetNullValue();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetRadius()
		CODE:
		RETVAL = THIS->GetRadius();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetRadiusMaxValue()
		CODE:
		RETVAL = THIS->GetRadiusMaxValue();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetRadiusMinValue()
		CODE:
		RETVAL = THIS->GetRadiusMinValue();
		OUTPUT:
		RETVAL


int  *
vtkGaussianSplatter::GetSampleDimensions()
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


int
vtkGaussianSplatter::GetScalarWarping()
		CODE:
		RETVAL = THIS->GetScalarWarping();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetScaleFactorMaxValue()
		CODE:
		RETVAL = THIS->GetScaleFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkGaussianSplatter::GetScaleFactorMinValue()
		CODE:
		RETVAL = THIS->GetScaleFactorMinValue();
		OUTPUT:
		RETVAL


static vtkGaussianSplatter*
vtkGaussianSplatter::New()
		CODE:
		RETVAL = vtkGaussianSplatter::New();
		OUTPUT:
		RETVAL


void
vtkGaussianSplatter::NormalWarpingOff()
		CODE:
		THIS->NormalWarpingOff();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::NormalWarpingOn()
		CODE:
		THIS->NormalWarpingOn();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::ScalarWarpingOff()
		CODE:
		THIS->ScalarWarpingOff();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::ScalarWarpingOn()
		CODE:
		THIS->ScalarWarpingOn();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetAccumulationMode(arg1)
		int 	arg1
		CODE:
		THIS->SetAccumulationMode(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetAccumulationModeToMax()
		CODE:
		THIS->SetAccumulationModeToMax();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetAccumulationModeToMin()
		CODE:
		THIS->SetAccumulationModeToMin();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetAccumulationModeToSum()
		CODE:
		THIS->SetAccumulationModeToSum();
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetCapValue(arg1)
		float 	arg1
		CODE:
		THIS->SetCapValue(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetEccentricity(arg1)
		float 	arg1
		CODE:
		THIS->SetEccentricity(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetExponentFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetExponentFactor(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkGaussianSplatter::SetModelBounds\n");



void
vtkGaussianSplatter::SetNormalWarping(arg1)
		int 	arg1
		CODE:
		THIS->SetNormalWarping(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetNullValue(arg1)
		float 	arg1
		CODE:
		THIS->SetNullValue(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetRadius(arg1)
		float 	arg1
		CODE:
		THIS->SetRadius(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGaussianSplatter::SetSampleDimensions\n");



void
vtkGaussianSplatter::SetScalarWarping(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarWarping(arg1);
		XSRETURN_EMPTY;


void
vtkGaussianSplatter::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageAccumulate PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageAccumulate::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int *
vtkImageAccumulate::GetComponentExtent()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComponentExtent();
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
		croak("Unsupported number of args and/or types supplied to vtkImageAccumulate::GetComponentExtent\n");



float  *
vtkImageAccumulate::GetComponentOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComponentOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageAccumulate::GetComponentSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComponentSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double  *
vtkImageAccumulate::GetMax()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMax();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double  *
vtkImageAccumulate::GetMean()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMean();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double  *
vtkImageAccumulate::GetMin()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageAccumulate::GetReverseStencil()
		CODE:
		RETVAL = THIS->GetReverseStencil();
		OUTPUT:
		RETVAL


double  *
vtkImageAccumulate::GetStandardDeviation()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetStandardDeviation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkImageStencilData *
vtkImageAccumulate::GetStencil()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageStencilData";
		CODE:
		RETVAL = THIS->GetStencil();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


long
vtkImageAccumulate::GetVoxelCount()
		CODE:
		RETVAL = THIS->GetVoxelCount();
		OUTPUT:
		RETVAL


static vtkImageAccumulate*
vtkImageAccumulate::New()
		CODE:
		RETVAL = vtkImageAccumulate::New();
		OUTPUT:
		RETVAL


void
vtkImageAccumulate::ReverseStencilOff()
		CODE:
		THIS->ReverseStencilOff();
		XSRETURN_EMPTY;


void
vtkImageAccumulate::ReverseStencilOn()
		CODE:
		THIS->ReverseStencilOn();
		XSRETURN_EMPTY;


void
vtkImageAccumulate::SetComponentExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetComponentExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageAccumulate::SetComponentExtent\n");



void
vtkImageAccumulate::SetComponentOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetComponentOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageAccumulate::SetComponentOrigin\n");



void
vtkImageAccumulate::SetComponentSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetComponentSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageAccumulate::SetComponentSpacing\n");



void
vtkImageAccumulate::SetReverseStencil(arg1)
		int 	arg1
		CODE:
		THIS->SetReverseStencil(arg1);
		XSRETURN_EMPTY;


void
vtkImageAccumulate::SetStencil(stencil)
		vtkImageStencilData *	stencil
		CODE:
		THIS->SetStencil(stencil);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageAnisotropicDiffusion2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageAnisotropicDiffusion2D::CornersOff()
		CODE:
		THIS->CornersOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::CornersOn()
		CODE:
		THIS->CornersOn();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::EdgesOff()
		CODE:
		THIS->EdgesOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::EdgesOn()
		CODE:
		THIS->EdgesOn();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::FacesOff()
		CODE:
		THIS->FacesOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::FacesOn()
		CODE:
		THIS->FacesOn();
		XSRETURN_EMPTY;


const char *
vtkImageAnisotropicDiffusion2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion2D::GetCorners()
		CODE:
		RETVAL = THIS->GetCorners();
		OUTPUT:
		RETVAL


float
vtkImageAnisotropicDiffusion2D::GetDiffusionFactor()
		CODE:
		RETVAL = THIS->GetDiffusionFactor();
		OUTPUT:
		RETVAL


float
vtkImageAnisotropicDiffusion2D::GetDiffusionThreshold()
		CODE:
		RETVAL = THIS->GetDiffusionThreshold();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion2D::GetEdges()
		CODE:
		RETVAL = THIS->GetEdges();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion2D::GetFaces()
		CODE:
		RETVAL = THIS->GetFaces();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion2D::GetGradientMagnitudeThreshold()
		CODE:
		RETVAL = THIS->GetGradientMagnitudeThreshold();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion2D::GetNumberOfIterations()
		CODE:
		RETVAL = THIS->GetNumberOfIterations();
		OUTPUT:
		RETVAL


void
vtkImageAnisotropicDiffusion2D::GradientMagnitudeThresholdOff()
		CODE:
		THIS->GradientMagnitudeThresholdOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::GradientMagnitudeThresholdOn()
		CODE:
		THIS->GradientMagnitudeThresholdOn();
		XSRETURN_EMPTY;


static vtkImageAnisotropicDiffusion2D*
vtkImageAnisotropicDiffusion2D::New()
		CODE:
		RETVAL = vtkImageAnisotropicDiffusion2D::New();
		OUTPUT:
		RETVAL


void
vtkImageAnisotropicDiffusion2D::SetCorners(arg1)
		int 	arg1
		CODE:
		THIS->SetCorners(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::SetDiffusionFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetDiffusionFactor(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::SetDiffusionThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetDiffusionThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::SetEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetEdges(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::SetFaces(arg1)
		int 	arg1
		CODE:
		THIS->SetFaces(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::SetGradientMagnitudeThreshold(arg1)
		int 	arg1
		CODE:
		THIS->SetGradientMagnitudeThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion2D::SetNumberOfIterations(num)
		int 	num
		CODE:
		THIS->SetNumberOfIterations(num);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageAnisotropicDiffusion3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageAnisotropicDiffusion3D::CornersOff()
		CODE:
		THIS->CornersOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::CornersOn()
		CODE:
		THIS->CornersOn();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::EdgesOff()
		CODE:
		THIS->EdgesOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::EdgesOn()
		CODE:
		THIS->EdgesOn();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::FacesOff()
		CODE:
		THIS->FacesOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::FacesOn()
		CODE:
		THIS->FacesOn();
		XSRETURN_EMPTY;


const char *
vtkImageAnisotropicDiffusion3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion3D::GetCorners()
		CODE:
		RETVAL = THIS->GetCorners();
		OUTPUT:
		RETVAL


float
vtkImageAnisotropicDiffusion3D::GetDiffusionFactor()
		CODE:
		RETVAL = THIS->GetDiffusionFactor();
		OUTPUT:
		RETVAL


float
vtkImageAnisotropicDiffusion3D::GetDiffusionThreshold()
		CODE:
		RETVAL = THIS->GetDiffusionThreshold();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion3D::GetEdges()
		CODE:
		RETVAL = THIS->GetEdges();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion3D::GetFaces()
		CODE:
		RETVAL = THIS->GetFaces();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion3D::GetGradientMagnitudeThreshold()
		CODE:
		RETVAL = THIS->GetGradientMagnitudeThreshold();
		OUTPUT:
		RETVAL


int
vtkImageAnisotropicDiffusion3D::GetNumberOfIterations()
		CODE:
		RETVAL = THIS->GetNumberOfIterations();
		OUTPUT:
		RETVAL


void
vtkImageAnisotropicDiffusion3D::GradientMagnitudeThresholdOff()
		CODE:
		THIS->GradientMagnitudeThresholdOff();
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::GradientMagnitudeThresholdOn()
		CODE:
		THIS->GradientMagnitudeThresholdOn();
		XSRETURN_EMPTY;


static vtkImageAnisotropicDiffusion3D*
vtkImageAnisotropicDiffusion3D::New()
		CODE:
		RETVAL = vtkImageAnisotropicDiffusion3D::New();
		OUTPUT:
		RETVAL


void
vtkImageAnisotropicDiffusion3D::SetCorners(arg1)
		int 	arg1
		CODE:
		THIS->SetCorners(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::SetDiffusionFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetDiffusionFactor(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::SetDiffusionThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetDiffusionThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::SetEdges(arg1)
		int 	arg1
		CODE:
		THIS->SetEdges(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::SetFaces(arg1)
		int 	arg1
		CODE:
		THIS->SetFaces(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::SetGradientMagnitudeThreshold(arg1)
		int 	arg1
		CODE:
		THIS->SetGradientMagnitudeThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageAnisotropicDiffusion3D::SetNumberOfIterations(num)
		int 	num
		CODE:
		THIS->SetNumberOfIterations(num);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageAppend PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkImageAppend::GetAppendAxis()
		CODE:
		RETVAL = THIS->GetAppendAxis();
		OUTPUT:
		RETVAL


const char *
vtkImageAppend::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageAppend::GetPreserveExtents()
		CODE:
		RETVAL = THIS->GetPreserveExtents();
		OUTPUT:
		RETVAL


static vtkImageAppend*
vtkImageAppend::New()
		CODE:
		RETVAL = vtkImageAppend::New();
		OUTPUT:
		RETVAL


void
vtkImageAppend::PreserveExtentsOff()
		CODE:
		THIS->PreserveExtentsOff();
		XSRETURN_EMPTY;


void
vtkImageAppend::PreserveExtentsOn()
		CODE:
		THIS->PreserveExtentsOn();
		XSRETURN_EMPTY;


void
vtkImageAppend::SetAppendAxis(arg1)
		int 	arg1
		CODE:
		THIS->SetAppendAxis(arg1);
		XSRETURN_EMPTY;


void
vtkImageAppend::SetPreserveExtents(arg1)
		int 	arg1
		CODE:
		THIS->SetPreserveExtents(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageAppendComponents PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageAppendComponents::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageAppendComponents*
vtkImageAppendComponents::New()
		CODE:
		RETVAL = vtkImageAppendComponents::New();
		OUTPUT:
		RETVAL


void
vtkImageAppendComponents::SetInput2(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput2(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageBlend PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkImageBlend::GetBlendMode()
		CODE:
		RETVAL = THIS->GetBlendMode();
		OUTPUT:
		RETVAL


const char *
vtkImageBlend::GetBlendModeAsString()
		CODE:
		RETVAL = THIS->GetBlendModeAsString();
		OUTPUT:
		RETVAL


int
vtkImageBlend::GetBlendModeMaxValue()
		CODE:
		RETVAL = THIS->GetBlendModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageBlend::GetBlendModeMinValue()
		CODE:
		RETVAL = THIS->GetBlendModeMinValue();
		OUTPUT:
		RETVAL


const char *
vtkImageBlend::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageBlend::GetCompoundThreshold()
		CODE:
		RETVAL = THIS->GetCompoundThreshold();
		OUTPUT:
		RETVAL


double
vtkImageBlend::GetOpacity(idx)
		int 	idx
		CODE:
		RETVAL = THIS->GetOpacity(idx);
		OUTPUT:
		RETVAL


vtkImageStencilData *
vtkImageBlend::GetStencil()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageStencilData";
		CODE:
		RETVAL = THIS->GetStencil();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageBlend*
vtkImageBlend::New()
		CODE:
		RETVAL = vtkImageBlend::New();
		OUTPUT:
		RETVAL


void
vtkImageBlend::SetBlendMode(arg1)
		int 	arg1
		CODE:
		THIS->SetBlendMode(arg1);
		XSRETURN_EMPTY;


void
vtkImageBlend::SetBlendModeToCompound()
		CODE:
		THIS->SetBlendModeToCompound();
		XSRETURN_EMPTY;


void
vtkImageBlend::SetBlendModeToNormal()
		CODE:
		THIS->SetBlendModeToNormal();
		XSRETURN_EMPTY;


void
vtkImageBlend::SetCompoundThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetCompoundThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageBlend::SetOpacity(idx, opacity)
		int 	idx
		double 	opacity
		CODE:
		THIS->SetOpacity(idx, opacity);
		XSRETURN_EMPTY;


void
vtkImageBlend::SetStencil(arg1)
		vtkImageStencilData *	arg1
		CODE:
		THIS->SetStencil(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageButterworthHighPass PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageButterworthHighPass::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkImageButterworthHighPass::GetCutOff()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCutOff();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageButterworthHighPass::GetOrder()
		CODE:
		RETVAL = THIS->GetOrder();
		OUTPUT:
		RETVAL


float
vtkImageButterworthHighPass::GetXCutOff()
		CODE:
		RETVAL = THIS->GetXCutOff();
		OUTPUT:
		RETVAL


float
vtkImageButterworthHighPass::GetYCutOff()
		CODE:
		RETVAL = THIS->GetYCutOff();
		OUTPUT:
		RETVAL


float
vtkImageButterworthHighPass::GetZCutOff()
		CODE:
		RETVAL = THIS->GetZCutOff();
		OUTPUT:
		RETVAL


static vtkImageButterworthHighPass*
vtkImageButterworthHighPass::New()
		CODE:
		RETVAL = vtkImageButterworthHighPass::New();
		OUTPUT:
		RETVAL


void
vtkImageButterworthHighPass::SetCutOff(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCutOff(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetCutOff(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageButterworthHighPass::SetCutOff\n");



void
vtkImageButterworthHighPass::SetOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetOrder(arg1);
		XSRETURN_EMPTY;


void
vtkImageButterworthHighPass::SetXCutOff(v)
		float 	v
		CODE:
		THIS->SetXCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageButterworthHighPass::SetYCutOff(v)
		float 	v
		CODE:
		THIS->SetYCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageButterworthHighPass::SetZCutOff(v)
		float 	v
		CODE:
		THIS->SetZCutOff(v);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageButterworthLowPass PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageButterworthLowPass::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkImageButterworthLowPass::GetCutOff()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCutOff();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageButterworthLowPass::GetOrder()
		CODE:
		RETVAL = THIS->GetOrder();
		OUTPUT:
		RETVAL


float
vtkImageButterworthLowPass::GetXCutOff()
		CODE:
		RETVAL = THIS->GetXCutOff();
		OUTPUT:
		RETVAL


float
vtkImageButterworthLowPass::GetYCutOff()
		CODE:
		RETVAL = THIS->GetYCutOff();
		OUTPUT:
		RETVAL


float
vtkImageButterworthLowPass::GetZCutOff()
		CODE:
		RETVAL = THIS->GetZCutOff();
		OUTPUT:
		RETVAL


static vtkImageButterworthLowPass*
vtkImageButterworthLowPass::New()
		CODE:
		RETVAL = vtkImageButterworthLowPass::New();
		OUTPUT:
		RETVAL


void
vtkImageButterworthLowPass::SetCutOff(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCutOff(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetCutOff(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageButterworthLowPass::SetCutOff\n");



void
vtkImageButterworthLowPass::SetOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetOrder(arg1);
		XSRETURN_EMPTY;


void
vtkImageButterworthLowPass::SetXCutOff(v)
		float 	v
		CODE:
		THIS->SetXCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageButterworthLowPass::SetYCutOff(v)
		float 	v
		CODE:
		THIS->SetYCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageButterworthLowPass::SetZCutOff(v)
		float 	v
		CODE:
		THIS->SetZCutOff(v);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCacheFilter PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkImageCacheFilter::GetCacheSize()
		CODE:
		RETVAL = THIS->GetCacheSize();
		OUTPUT:
		RETVAL


const char *
vtkImageCacheFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageCacheFilter*
vtkImageCacheFilter::New()
		CODE:
		RETVAL = vtkImageCacheFilter::New();
		OUTPUT:
		RETVAL


void
vtkImageCacheFilter::SetCacheSize(size)
		int 	size
		CODE:
		THIS->SetCacheSize(size);
		XSRETURN_EMPTY;


void
vtkImageCacheFilter::UpdateData(outData)
		vtkDataObject *	outData
		CODE:
		THIS->UpdateData(outData);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCanvasSource2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageCanvasSource2D::DrawCircle(c0, c1, radius)
		int 	c0
		int 	c1
		float 	radius
		CODE:
		THIS->DrawCircle(c0, c1, radius);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::DrawPoint(p0, p1)
		int 	p0
		int 	p1
		CODE:
		THIS->DrawPoint(p0, p1);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::DrawSegment(x0, y0, x1, y1)
		int 	x0
		int 	y0
		int 	x1
		int 	y1
		CODE:
		THIS->DrawSegment(x0, y0, x1, y1);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::DrawSegment3D(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->DrawSegment3D(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageCanvasSource2D::DrawSegment3D\n");



void
vtkImageCanvasSource2D::FillBox(min0, max0, min1, max1)
		int 	min0
		int 	max0
		int 	min1
		int 	max1
		CODE:
		THIS->FillBox(min0, max0, min1, max1);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::FillPixel(x, y)
		int 	x
		int 	y
		CODE:
		THIS->FillPixel(x, y);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::FillTriangle(x0, y0, x1, y1, x2, y2)
		int 	x0
		int 	y0
		int 	x1
		int 	y1
		int 	x2
		int 	y2
		CODE:
		THIS->FillTriangle(x0, y0, x1, y1, x2, y2);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::FillTube(x0, y0, x1, y1, radius)
		int 	x0
		int 	y0
		int 	x1
		int 	y1
		float 	radius
		CODE:
		THIS->FillTube(x0, y0, x1, y1, radius);
		XSRETURN_EMPTY;


const char *
vtkImageCanvasSource2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageCanvasSource2D::GetDefaultZ()
		CODE:
		RETVAL = THIS->GetDefaultZ();
		OUTPUT:
		RETVAL


float  *
vtkImageCanvasSource2D::GetDrawColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDrawColor();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


vtkImageData *
vtkImageCanvasSource2D::GetImageData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetImageData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageCanvasSource2D::GetOutput()
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


static vtkImageCanvasSource2D*
vtkImageCanvasSource2D::New()
		CODE:
		RETVAL = vtkImageCanvasSource2D::New();
		OUTPUT:
		RETVAL


void
vtkImageCanvasSource2D::SetDefaultZ(arg1)
		int 	arg1
		CODE:
		THIS->SetDefaultZ(arg1);
		XSRETURN_EMPTY;


void
vtkImageCanvasSource2D::SetDrawColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetDrawColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDrawColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetDrawColor(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetDrawColor(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageCanvasSource2D::SetDrawColor\n");



void
vtkImageCanvasSource2D::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkImageCanvasSource2D::SetExtent\n");



void
vtkImageCanvasSource2D::SetImageData(image)
		vtkImageData *	image
		CODE:
		THIS->SetImageData(image);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCast PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageCast::ClampOverflowOff()
		CODE:
		THIS->ClampOverflowOff();
		XSRETURN_EMPTY;


void
vtkImageCast::ClampOverflowOn()
		CODE:
		THIS->ClampOverflowOn();
		XSRETURN_EMPTY;


int
vtkImageCast::GetClampOverflow()
		CODE:
		RETVAL = THIS->GetClampOverflow();
		OUTPUT:
		RETVAL


const char *
vtkImageCast::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageCast::GetOutputScalarType()
		CODE:
		RETVAL = THIS->GetOutputScalarType();
		OUTPUT:
		RETVAL


static vtkImageCast*
vtkImageCast::New()
		CODE:
		RETVAL = vtkImageCast::New();
		OUTPUT:
		RETVAL


void
vtkImageCast::SetClampOverflow(arg1)
		int 	arg1
		CODE:
		THIS->SetClampOverflow(arg1);
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToChar()
		CODE:
		THIS->SetOutputScalarTypeToChar();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToDouble()
		CODE:
		THIS->SetOutputScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToFloat()
		CODE:
		THIS->SetOutputScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToInt()
		CODE:
		THIS->SetOutputScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToLong()
		CODE:
		THIS->SetOutputScalarTypeToLong();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToShort()
		CODE:
		THIS->SetOutputScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToUnsignedChar()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToUnsignedInt()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedInt();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToUnsignedLong()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedLong();
		XSRETURN_EMPTY;


void
vtkImageCast::SetOutputScalarTypeToUnsignedShort()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageChangeInformation PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageChangeInformation::CenterImageOff()
		CODE:
		THIS->CenterImageOff();
		XSRETURN_EMPTY;


void
vtkImageChangeInformation::CenterImageOn()
		CODE:
		THIS->CenterImageOn();
		XSRETURN_EMPTY;


int
vtkImageChangeInformation::GetCenterImage()
		CODE:
		RETVAL = THIS->GetCenterImage();
		OUTPUT:
		RETVAL


const char *
vtkImageChangeInformation::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImageChangeInformation::GetExtentTranslation()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtentTranslation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkImageData *
vtkImageChangeInformation::GetInformationInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInformationInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkImageChangeInformation::GetOriginScale()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOriginScale();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageChangeInformation::GetOriginTranslation()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOriginTranslation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int  *
vtkImageChangeInformation::GetOutputExtentStart()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputExtentStart();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageChangeInformation::GetOutputOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageChangeInformation::GetOutputSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageChangeInformation::GetSpacingScale()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSpacingScale();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImageChangeInformation*
vtkImageChangeInformation::New()
		CODE:
		RETVAL = vtkImageChangeInformation::New();
		OUTPUT:
		RETVAL


void
vtkImageChangeInformation::SetCenterImage(arg1)
		int 	arg1
		CODE:
		THIS->SetCenterImage(arg1);
		XSRETURN_EMPTY;


void
vtkImageChangeInformation::SetExtentTranslation(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetExtentTranslation(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetExtentTranslation\n");



void
vtkImageChangeInformation::SetInformationInput(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetInformationInput(arg1);
		XSRETURN_EMPTY;


void
vtkImageChangeInformation::SetOriginScale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOriginScale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetOriginScale\n");



void
vtkImageChangeInformation::SetOriginTranslation(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOriginTranslation(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetOriginTranslation\n");



void
vtkImageChangeInformation::SetOutputExtentStart(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetOutputExtentStart(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetOutputExtentStart\n");



void
vtkImageChangeInformation::SetOutputOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutputOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetOutputOrigin\n");



void
vtkImageChangeInformation::SetOutputSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutputSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetOutputSpacing\n");



void
vtkImageChangeInformation::SetSpacingScale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetSpacingScale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageChangeInformation::SetSpacingScale\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCheckerboard PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageCheckerboard::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImageCheckerboard::GetNumberOfDivisions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNumberOfDivisions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImageCheckerboard*
vtkImageCheckerboard::New()
		CODE:
		RETVAL = vtkImageCheckerboard::New();
		OUTPUT:
		RETVAL


void
vtkImageCheckerboard::SetNumberOfDivisions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetNumberOfDivisions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageCheckerboard::SetNumberOfDivisions\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCityBlockDistance PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageCityBlockDistance::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageCityBlockDistance*
vtkImageCityBlockDistance::New()
		CODE:
		RETVAL = vtkImageCityBlockDistance::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageClip PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageClip::ClipDataOff()
		CODE:
		THIS->ClipDataOff();
		XSRETURN_EMPTY;


void
vtkImageClip::ClipDataOn()
		CODE:
		THIS->ClipDataOn();
		XSRETURN_EMPTY;


const char *
vtkImageClip::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageClip::GetClipData()
		CODE:
		RETVAL = THIS->GetClipData();
		OUTPUT:
		RETVAL


int *
vtkImageClip::GetOutputWholeExtent()
	CASE: items == 1
		PREINIT:
		int * retval;
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
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageClip::GetOutputWholeExtent\n");



static vtkImageClip*
vtkImageClip::New()
		CODE:
		RETVAL = vtkImageClip::New();
		OUTPUT:
		RETVAL


void
vtkImageClip::ResetOutputWholeExtent()
		CODE:
		THIS->ResetOutputWholeExtent();
		XSRETURN_EMPTY;


void
vtkImageClip::SetClipData(arg1)
		int 	arg1
		CODE:
		THIS->SetClipData(arg1);
		XSRETURN_EMPTY;


void
vtkImageClip::SetOutputWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetOutputWholeExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageClip::SetOutputWholeExtent\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageConnector PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageConnector::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned char
vtkImageConnector::GetConnectedValue()
		CODE:
		RETVAL = THIS->GetConnectedValue();
		OUTPUT:
		RETVAL


unsigned char
vtkImageConnector::GetUnconnectedValue()
		CODE:
		RETVAL = THIS->GetUnconnectedValue();
		OUTPUT:
		RETVAL


static vtkImageConnector*
vtkImageConnector::New()
		CODE:
		RETVAL = vtkImageConnector::New();
		OUTPUT:
		RETVAL


void
vtkImageConnector::RemoveAllSeeds()
		CODE:
		THIS->RemoveAllSeeds();
		XSRETURN_EMPTY;


void
vtkImageConnector::SetConnectedValue(arg1)
		unsigned char 	arg1
		CODE:
		THIS->SetConnectedValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageConnector::SetUnconnectedValue(arg1)
		unsigned char 	arg1
		CODE:
		THIS->SetUnconnectedValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageConstantPad PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageConstantPad::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageConstantPad::GetConstant()
		CODE:
		RETVAL = THIS->GetConstant();
		OUTPUT:
		RETVAL


static vtkImageConstantPad*
vtkImageConstantPad::New()
		CODE:
		RETVAL = vtkImageConstantPad::New();
		OUTPUT:
		RETVAL


void
vtkImageConstantPad::SetConstant(arg1)
		float 	arg1
		CODE:
		THIS->SetConstant(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageContinuousDilate3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageContinuousDilate3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageContinuousDilate3D*
vtkImageContinuousDilate3D::New()
		CODE:
		RETVAL = vtkImageContinuousDilate3D::New();
		OUTPUT:
		RETVAL


void
vtkImageContinuousDilate3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageContinuousErode3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageContinuousErode3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageContinuousErode3D*
vtkImageContinuousErode3D::New()
		CODE:
		RETVAL = vtkImageContinuousErode3D::New();
		OUTPUT:
		RETVAL


void
vtkImageContinuousErode3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageConvolve PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageConvolve::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkImageConvolve::GetKernel3x3()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKernel3x3();
		EXTEND(SP, 9);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUSHs(sv_2mortal(newSVnv(retval[6])));
		PUSHs(sv_2mortal(newSVnv(retval[7])));
		PUSHs(sv_2mortal(newSVnv(retval[8])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageConvolve::GetKernel3x3\n");



float *
vtkImageConvolve::GetKernel3x3x3()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKernel3x3x3();
		EXTEND(SP, 27);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUSHs(sv_2mortal(newSVnv(retval[6])));
		PUSHs(sv_2mortal(newSVnv(retval[7])));
		PUSHs(sv_2mortal(newSVnv(retval[8])));
		PUSHs(sv_2mortal(newSVnv(retval[9])));
		PUSHs(sv_2mortal(newSVnv(retval[10])));
		PUSHs(sv_2mortal(newSVnv(retval[11])));
		PUSHs(sv_2mortal(newSVnv(retval[12])));
		PUSHs(sv_2mortal(newSVnv(retval[13])));
		PUSHs(sv_2mortal(newSVnv(retval[14])));
		PUSHs(sv_2mortal(newSVnv(retval[15])));
		PUSHs(sv_2mortal(newSVnv(retval[16])));
		PUSHs(sv_2mortal(newSVnv(retval[17])));
		PUSHs(sv_2mortal(newSVnv(retval[18])));
		PUSHs(sv_2mortal(newSVnv(retval[19])));
		PUSHs(sv_2mortal(newSVnv(retval[20])));
		PUSHs(sv_2mortal(newSVnv(retval[21])));
		PUSHs(sv_2mortal(newSVnv(retval[22])));
		PUSHs(sv_2mortal(newSVnv(retval[23])));
		PUSHs(sv_2mortal(newSVnv(retval[24])));
		PUSHs(sv_2mortal(newSVnv(retval[25])));
		PUSHs(sv_2mortal(newSVnv(retval[26])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageConvolve::GetKernel3x3x3\n");



float *
vtkImageConvolve::GetKernel5x5()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKernel5x5();
		EXTEND(SP, 25);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUSHs(sv_2mortal(newSVnv(retval[6])));
		PUSHs(sv_2mortal(newSVnv(retval[7])));
		PUSHs(sv_2mortal(newSVnv(retval[8])));
		PUSHs(sv_2mortal(newSVnv(retval[9])));
		PUSHs(sv_2mortal(newSVnv(retval[10])));
		PUSHs(sv_2mortal(newSVnv(retval[11])));
		PUSHs(sv_2mortal(newSVnv(retval[12])));
		PUSHs(sv_2mortal(newSVnv(retval[13])));
		PUSHs(sv_2mortal(newSVnv(retval[14])));
		PUSHs(sv_2mortal(newSVnv(retval[15])));
		PUSHs(sv_2mortal(newSVnv(retval[16])));
		PUSHs(sv_2mortal(newSVnv(retval[17])));
		PUSHs(sv_2mortal(newSVnv(retval[18])));
		PUSHs(sv_2mortal(newSVnv(retval[19])));
		PUSHs(sv_2mortal(newSVnv(retval[20])));
		PUSHs(sv_2mortal(newSVnv(retval[21])));
		PUSHs(sv_2mortal(newSVnv(retval[22])));
		PUSHs(sv_2mortal(newSVnv(retval[23])));
		PUSHs(sv_2mortal(newSVnv(retval[24])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageConvolve::GetKernel5x5\n");



int  *
vtkImageConvolve::GetKernelSize()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKernelSize();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImageConvolve*
vtkImageConvolve::New()
		CODE:
		RETVAL = vtkImageConvolve::New();
		OUTPUT:
		RETVAL




MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCorrelation PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageCorrelation::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageCorrelation::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageCorrelation::GetDimensionalityMaxValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageCorrelation::GetDimensionalityMinValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMinValue();
		OUTPUT:
		RETVAL


static vtkImageCorrelation*
vtkImageCorrelation::New()
		CODE:
		RETVAL = vtkImageCorrelation::New();
		OUTPUT:
		RETVAL


void
vtkImageCorrelation::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageCursor3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageCursor3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkImageCursor3D::GetCursorPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCursorPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageCursor3D::GetCursorRadius()
		CODE:
		RETVAL = THIS->GetCursorRadius();
		OUTPUT:
		RETVAL


float
vtkImageCursor3D::GetCursorValue()
		CODE:
		RETVAL = THIS->GetCursorValue();
		OUTPUT:
		RETVAL


static vtkImageCursor3D*
vtkImageCursor3D::New()
		CODE:
		RETVAL = vtkImageCursor3D::New();
		OUTPUT:
		RETVAL


void
vtkImageCursor3D::SetCursorPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCursorPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageCursor3D::SetCursorPosition\n");



void
vtkImageCursor3D::SetCursorRadius(arg1)
		int 	arg1
		CODE:
		THIS->SetCursorRadius(arg1);
		XSRETURN_EMPTY;


void
vtkImageCursor3D::SetCursorValue(arg1)
		float 	arg1
		CODE:
		THIS->SetCursorValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageDataStreamer PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageDataStreamer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkExtentTranslator *
vtkImageDataStreamer::GetExtentTranslator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkExtentTranslator";
		CODE:
		RETVAL = THIS->GetExtentTranslator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageDataStreamer::GetNumberOfStreamDivisions()
		CODE:
		RETVAL = THIS->GetNumberOfStreamDivisions();
		OUTPUT:
		RETVAL


static vtkImageDataStreamer*
vtkImageDataStreamer::New()
		CODE:
		RETVAL = vtkImageDataStreamer::New();
		OUTPUT:
		RETVAL


void
vtkImageDataStreamer::SetExtentTranslator(arg1)
		vtkExtentTranslator *	arg1
		CODE:
		THIS->SetExtentTranslator(arg1);
		XSRETURN_EMPTY;


void
vtkImageDataStreamer::SetNumberOfStreamDivisions(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfStreamDivisions(arg1);
		XSRETURN_EMPTY;


void
vtkImageDataStreamer::UpdateData(out)
		vtkDataObject *	out
		CODE:
		THIS->UpdateData(out);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageDecomposeFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageDecomposeFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageDecomposeFilter::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


void
vtkImageDecomposeFilter::SetDimensionality(dim)
		int 	dim
		CODE:
		THIS->SetDimensionality(dim);
		XSRETURN_EMPTY;


void
vtkImageDecomposeFilter::SetFilteredAxes(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetFilteredAxes(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetFilteredAxes(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		int 	arg1
		CODE:
		THIS->SetFilteredAxes(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageDecomposeFilter::SetFilteredAxes\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageDifference PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageDifference::AllowShiftOff()
		CODE:
		THIS->AllowShiftOff();
		XSRETURN_EMPTY;


void
vtkImageDifference::AllowShiftOn()
		CODE:
		THIS->AllowShiftOn();
		XSRETURN_EMPTY;


void
vtkImageDifference::AveragingOff()
		CODE:
		THIS->AveragingOff();
		XSRETURN_EMPTY;


void
vtkImageDifference::AveragingOn()
		CODE:
		THIS->AveragingOn();
		XSRETURN_EMPTY;


int
vtkImageDifference::GetAllowShift()
		CODE:
		RETVAL = THIS->GetAllowShift();
		OUTPUT:
		RETVAL


int
vtkImageDifference::GetAveraging()
		CODE:
		RETVAL = THIS->GetAveraging();
		OUTPUT:
		RETVAL


const char *
vtkImageDifference::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageDifference::GetError()
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetError();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageDifference::GetError\n");



vtkImageData *
vtkImageDifference::GetImage()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetImage();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageDifference::GetThreshold()
		CODE:
		RETVAL = THIS->GetThreshold();
		OUTPUT:
		RETVAL


float
vtkImageDifference::GetThresholdedError()
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetThresholdedError();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageDifference::GetThresholdedError\n");



static vtkImageDifference*
vtkImageDifference::New()
		CODE:
		RETVAL = vtkImageDifference::New();
		OUTPUT:
		RETVAL


void
vtkImageDifference::SetAllowShift(arg1)
		int 	arg1
		CODE:
		THIS->SetAllowShift(arg1);
		XSRETURN_EMPTY;


void
vtkImageDifference::SetAveraging(arg1)
		int 	arg1
		CODE:
		THIS->SetAveraging(arg1);
		XSRETURN_EMPTY;


void
vtkImageDifference::SetImage(image)
		vtkImageData *	image
		CODE:
		THIS->SetImage(image);
		XSRETURN_EMPTY;


void
vtkImageDifference::SetInput(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		vtkImageData *	arg2
		CODE:
		THIS->SetInput(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		vtkImageData *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageDifference::SetInput\n");



void
vtkImageDifference::SetThreshold(arg1)
		int 	arg1
		CODE:
		THIS->SetThreshold(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageDilateErode3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageDilateErode3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageDilateErode3D::GetDilateValue()
		CODE:
		RETVAL = THIS->GetDilateValue();
		OUTPUT:
		RETVAL


float
vtkImageDilateErode3D::GetErodeValue()
		CODE:
		RETVAL = THIS->GetErodeValue();
		OUTPUT:
		RETVAL


static vtkImageDilateErode3D*
vtkImageDilateErode3D::New()
		CODE:
		RETVAL = vtkImageDilateErode3D::New();
		OUTPUT:
		RETVAL


void
vtkImageDilateErode3D::SetDilateValue(arg1)
		float 	arg1
		CODE:
		THIS->SetDilateValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageDilateErode3D::SetErodeValue(arg1)
		float 	arg1
		CODE:
		THIS->SetErodeValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageDilateErode3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageDivergence PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageDivergence::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageDivergence*
vtkImageDivergence::New()
		CODE:
		RETVAL = vtkImageDivergence::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageDotProduct PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageDotProduct::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageDotProduct*
vtkImageDotProduct::New()
		CODE:
		RETVAL = vtkImageDotProduct::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageEllipsoidSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkImageEllipsoidSource::GetCenter()
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
vtkImageEllipsoidSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageEllipsoidSource::GetInValue()
		CODE:
		RETVAL = THIS->GetInValue();
		OUTPUT:
		RETVAL


float
vtkImageEllipsoidSource::GetOutValue()
		CODE:
		RETVAL = THIS->GetOutValue();
		OUTPUT:
		RETVAL


int
vtkImageEllipsoidSource::GetOutputScalarType()
		CODE:
		RETVAL = THIS->GetOutputScalarType();
		OUTPUT:
		RETVAL


float  *
vtkImageEllipsoidSource::GetRadius()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetRadius();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int *
vtkImageEllipsoidSource::GetWholeExtent()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWholeExtent();
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
		croak("Unsupported number of args and/or types supplied to vtkImageEllipsoidSource::GetWholeExtent\n");



static vtkImageEllipsoidSource*
vtkImageEllipsoidSource::New()
		CODE:
		RETVAL = vtkImageEllipsoidSource::New();
		OUTPUT:
		RETVAL


void
vtkImageEllipsoidSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageEllipsoidSource::SetCenter\n");



void
vtkImageEllipsoidSource::SetInValue(arg1)
		float 	arg1
		CODE:
		THIS->SetInValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutValue(arg1)
		float 	arg1
		CODE:
		THIS->SetOutValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToChar()
		CODE:
		THIS->SetOutputScalarTypeToChar();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToDouble()
		CODE:
		THIS->SetOutputScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToFloat()
		CODE:
		THIS->SetOutputScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToInt()
		CODE:
		THIS->SetOutputScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToLong()
		CODE:
		THIS->SetOutputScalarTypeToLong();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToShort()
		CODE:
		THIS->SetOutputScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToUnsignedChar()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToUnsignedInt()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedInt();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToUnsignedLong()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedLong();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetOutputScalarTypeToUnsignedShort()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageEllipsoidSource::SetRadius(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetRadius(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageEllipsoidSource::SetRadius\n");



void
vtkImageEllipsoidSource::SetWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetWholeExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageEllipsoidSource::SetWholeExtent\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageEuclideanDistance PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageEuclideanDistance::ConsiderAnisotropyOff()
		CODE:
		THIS->ConsiderAnisotropyOff();
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::ConsiderAnisotropyOn()
		CODE:
		THIS->ConsiderAnisotropyOn();
		XSRETURN_EMPTY;


int
vtkImageEuclideanDistance::GetAlgorithm()
		CODE:
		RETVAL = THIS->GetAlgorithm();
		OUTPUT:
		RETVAL


const char *
vtkImageEuclideanDistance::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageEuclideanDistance::GetConsiderAnisotropy()
		CODE:
		RETVAL = THIS->GetConsiderAnisotropy();
		OUTPUT:
		RETVAL


int
vtkImageEuclideanDistance::GetInitialize()
		CODE:
		RETVAL = THIS->GetInitialize();
		OUTPUT:
		RETVAL


float
vtkImageEuclideanDistance::GetMaximumDistance()
		CODE:
		RETVAL = THIS->GetMaximumDistance();
		OUTPUT:
		RETVAL


void
vtkImageEuclideanDistance::InitializeOff()
		CODE:
		THIS->InitializeOff();
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::InitializeOn()
		CODE:
		THIS->InitializeOn();
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::IterativeExecuteData(in, out)
		vtkImageData *	in
		vtkImageData *	out
		CODE:
		THIS->IterativeExecuteData(in, out);
		XSRETURN_EMPTY;


static vtkImageEuclideanDistance*
vtkImageEuclideanDistance::New()
		CODE:
		RETVAL = vtkImageEuclideanDistance::New();
		OUTPUT:
		RETVAL


void
vtkImageEuclideanDistance::SetAlgorithm(arg1)
		int 	arg1
		CODE:
		THIS->SetAlgorithm(arg1);
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::SetAlgorithmToSaito()
		CODE:
		THIS->SetAlgorithmToSaito();
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::SetAlgorithmToSaitoCached()
		CODE:
		THIS->SetAlgorithmToSaitoCached();
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::SetConsiderAnisotropy(arg1)
		int 	arg1
		CODE:
		THIS->SetConsiderAnisotropy(arg1);
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::SetInitialize(arg1)
		int 	arg1
		CODE:
		THIS->SetInitialize(arg1);
		XSRETURN_EMPTY;


void
vtkImageEuclideanDistance::SetMaximumDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumDistance(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageEuclideanToPolar PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageEuclideanToPolar::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageEuclideanToPolar::GetThetaMaximum()
		CODE:
		RETVAL = THIS->GetThetaMaximum();
		OUTPUT:
		RETVAL


static vtkImageEuclideanToPolar*
vtkImageEuclideanToPolar::New()
		CODE:
		RETVAL = vtkImageEuclideanToPolar::New();
		OUTPUT:
		RETVAL


void
vtkImageEuclideanToPolar::SetThetaMaximum(arg1)
		float 	arg1
		CODE:
		THIS->SetThetaMaximum(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageExport PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageExport::Export()
	CASE: items == 1
		CODE:
		THIS->Export();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageExport::Export\n");



const char *
vtkImageExport::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int *
vtkImageExport::GetDataDimensions()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataDimensions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageExport::GetDataDimensions\n");



int *
vtkImageExport::GetDataExtent()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataExtent();
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
		croak("Unsupported number of args and/or types supplied to vtkImageExport::GetDataExtent\n");



int
vtkImageExport::GetDataMemorySize()
		CODE:
		RETVAL = THIS->GetDataMemorySize();
		OUTPUT:
		RETVAL


int
vtkImageExport::GetDataNumberOfScalarComponents()
		CODE:
		RETVAL = THIS->GetDataNumberOfScalarComponents();
		OUTPUT:
		RETVAL


float *
vtkImageExport::GetDataOrigin()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageExport::GetDataOrigin\n");



int
vtkImageExport::GetDataScalarType()
		CODE:
		RETVAL = THIS->GetDataScalarType();
		OUTPUT:
		RETVAL


const char *
vtkImageExport::GetDataScalarTypeAsString()
		CODE:
		RETVAL = THIS->GetDataScalarTypeAsString();
		OUTPUT:
		RETVAL


float *
vtkImageExport::GetDataSpacing()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageExport::GetDataSpacing\n");



int
vtkImageExport::GetImageLowerLeft()
		CODE:
		RETVAL = THIS->GetImageLowerLeft();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageExport::GetInput()
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
vtkImageExport::ImageLowerLeftOff()
		CODE:
		THIS->ImageLowerLeftOff();
		XSRETURN_EMPTY;


void
vtkImageExport::ImageLowerLeftOn()
		CODE:
		THIS->ImageLowerLeftOn();
		XSRETURN_EMPTY;


static vtkImageExport*
vtkImageExport::New()
		CODE:
		RETVAL = vtkImageExport::New();
		OUTPUT:
		RETVAL


void
vtkImageExport::SetImageLowerLeft(arg1)
		int 	arg1
		CODE:
		THIS->SetImageLowerLeft(arg1);
		XSRETURN_EMPTY;


void
vtkImageExport::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageExtractComponents PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageExtractComponents::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImageExtractComponents::GetComponents()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComponents();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageExtractComponents::GetNumberOfComponents()
		CODE:
		RETVAL = THIS->GetNumberOfComponents();
		OUTPUT:
		RETVAL


static vtkImageExtractComponents*
vtkImageExtractComponents::New()
		CODE:
		RETVAL = vtkImageExtractComponents::New();
		OUTPUT:
		RETVAL


void
vtkImageExtractComponents::SetComponents(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetComponents(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetComponents(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		int 	arg1
		CODE:
		THIS->SetComponents(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageExtractComponents::SetComponents\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageFFT PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageFFT::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkImageFFT::IterativeExecuteData(in, out)
		vtkImageData *	in
		vtkImageData *	out
		CODE:
		THIS->IterativeExecuteData(in, out);
		XSRETURN_EMPTY;


static vtkImageFFT*
vtkImageFFT::New()
		CODE:
		RETVAL = vtkImageFFT::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageFlip PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageFlip::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageFlip::GetFilteredAxis()
		CODE:
		RETVAL = THIS->GetFilteredAxis();
		OUTPUT:
		RETVAL


int
vtkImageFlip::GetPreserveImageExtent()
		CODE:
		RETVAL = THIS->GetPreserveImageExtent();
		OUTPUT:
		RETVAL


static vtkImageFlip*
vtkImageFlip::New()
		CODE:
		RETVAL = vtkImageFlip::New();
		OUTPUT:
		RETVAL


void
vtkImageFlip::PreserveImageExtentOff()
		CODE:
		THIS->PreserveImageExtentOff();
		XSRETURN_EMPTY;


void
vtkImageFlip::PreserveImageExtentOn()
		CODE:
		THIS->PreserveImageExtentOn();
		XSRETURN_EMPTY;


void
vtkImageFlip::SetFilteredAxes(axis)
		int 	axis
		CODE:
		THIS->SetFilteredAxes(axis);
		XSRETURN_EMPTY;


void
vtkImageFlip::SetFilteredAxis(arg1)
		int 	arg1
		CODE:
		THIS->SetFilteredAxis(arg1);
		XSRETURN_EMPTY;


void
vtkImageFlip::SetPreserveImageExtent(arg1)
		int 	arg1
		CODE:
		THIS->SetPreserveImageExtent(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageFourierCenter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageFourierCenter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkImageFourierCenter::IterativeExecuteData(in, out)
		vtkImageData *	in
		vtkImageData *	out
		CODE:
		THIS->IterativeExecuteData(in, out);
		XSRETURN_EMPTY;


static vtkImageFourierCenter*
vtkImageFourierCenter::New()
		CODE:
		RETVAL = vtkImageFourierCenter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageFourierFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageFourierFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageGaussianSmooth PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageGaussianSmooth::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageGaussianSmooth::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


float  *
vtkImageGaussianSmooth::GetRadiusFactors()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetRadiusFactors();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageGaussianSmooth::GetStandardDeviations()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetStandardDeviations();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImageGaussianSmooth*
vtkImageGaussianSmooth::New()
		CODE:
		RETVAL = vtkImageGaussianSmooth::New();
		OUTPUT:
		RETVAL


void
vtkImageGaussianSmooth::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageGaussianSmooth::SetRadiusFactor(f)
		float 	f
		CODE:
		THIS->SetRadiusFactor(f);
		XSRETURN_EMPTY;


void
vtkImageGaussianSmooth::SetRadiusFactors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetRadiusFactors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetRadiusFactors(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGaussianSmooth::SetRadiusFactors\n");



void
vtkImageGaussianSmooth::SetStandardDeviation(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetStandardDeviation(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetStandardDeviation(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetStandardDeviation(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGaussianSmooth::SetStandardDeviation\n");



void
vtkImageGaussianSmooth::SetStandardDeviations(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetStandardDeviations(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetStandardDeviations(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGaussianSmooth::SetStandardDeviations\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageGaussianSource PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkImageGaussianSource::GetCenter()
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
vtkImageGaussianSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageGaussianSource::GetMaximum()
		CODE:
		RETVAL = THIS->GetMaximum();
		OUTPUT:
		RETVAL


float
vtkImageGaussianSource::GetStandardDeviation()
		CODE:
		RETVAL = THIS->GetStandardDeviation();
		OUTPUT:
		RETVAL


static vtkImageGaussianSource*
vtkImageGaussianSource::New()
		CODE:
		RETVAL = vtkImageGaussianSource::New();
		OUTPUT:
		RETVAL


void
vtkImageGaussianSource::SetCenter(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCenter(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGaussianSource::SetCenter\n");



void
vtkImageGaussianSource::SetMaximum(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkImageGaussianSource::SetStandardDeviation(arg1)
		float 	arg1
		CODE:
		THIS->SetStandardDeviation(arg1);
		XSRETURN_EMPTY;


void
vtkImageGaussianSource::SetWholeExtent(xMinx, xMax, yMin, yMax, zMin, zMax)
		int 	xMinx
		int 	xMax
		int 	yMin
		int 	yMax
		int 	zMin
		int 	zMax
		CODE:
		THIS->SetWholeExtent(xMinx, xMax, yMin, yMax, zMin, zMax);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageGradient PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageGradient::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageGradient::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageGradient::GetDimensionalityMaxValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageGradient::GetDimensionalityMinValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMinValue();
		OUTPUT:
		RETVAL


int
vtkImageGradient::GetHandleBoundaries()
		CODE:
		RETVAL = THIS->GetHandleBoundaries();
		OUTPUT:
		RETVAL


void
vtkImageGradient::HandleBoundariesOff()
		CODE:
		THIS->HandleBoundariesOff();
		XSRETURN_EMPTY;


void
vtkImageGradient::HandleBoundariesOn()
		CODE:
		THIS->HandleBoundariesOn();
		XSRETURN_EMPTY;


static vtkImageGradient*
vtkImageGradient::New()
		CODE:
		RETVAL = vtkImageGradient::New();
		OUTPUT:
		RETVAL


void
vtkImageGradient::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageGradient::SetHandleBoundaries(arg1)
		int 	arg1
		CODE:
		THIS->SetHandleBoundaries(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageGradientMagnitude PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageGradientMagnitude::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageGradientMagnitude::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageGradientMagnitude::GetDimensionalityMaxValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageGradientMagnitude::GetDimensionalityMinValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMinValue();
		OUTPUT:
		RETVAL


int
vtkImageGradientMagnitude::GetHandleBoundaries()
		CODE:
		RETVAL = THIS->GetHandleBoundaries();
		OUTPUT:
		RETVAL


void
vtkImageGradientMagnitude::HandleBoundariesOff()
		CODE:
		THIS->HandleBoundariesOff();
		XSRETURN_EMPTY;


void
vtkImageGradientMagnitude::HandleBoundariesOn()
		CODE:
		THIS->HandleBoundariesOn();
		XSRETURN_EMPTY;


static vtkImageGradientMagnitude*
vtkImageGradientMagnitude::New()
		CODE:
		RETVAL = vtkImageGradientMagnitude::New();
		OUTPUT:
		RETVAL


void
vtkImageGradientMagnitude::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageGradientMagnitude::SetHandleBoundaries(arg1)
		int 	arg1
		CODE:
		THIS->SetHandleBoundaries(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageGridSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageGridSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImageGridSource::GetDataExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataExtent();
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
vtkImageGridSource::GetDataOrigin()
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


int
vtkImageGridSource::GetDataScalarType()
		CODE:
		RETVAL = THIS->GetDataScalarType();
		OUTPUT:
		RETVAL


const char *
vtkImageGridSource::GetDataScalarTypeAsString()
		CODE:
		RETVAL = THIS->GetDataScalarTypeAsString();
		OUTPUT:
		RETVAL


float  *
vtkImageGridSource::GetDataSpacing()
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


float
vtkImageGridSource::GetFillValue()
		CODE:
		RETVAL = THIS->GetFillValue();
		OUTPUT:
		RETVAL


int  *
vtkImageGridSource::GetGridOrigin()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetGridOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int  *
vtkImageGridSource::GetGridSpacing()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetGridSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkImageGridSource::GetLineValue()
		CODE:
		RETVAL = THIS->GetLineValue();
		OUTPUT:
		RETVAL


static vtkImageGridSource*
vtkImageGridSource::New()
		CODE:
		RETVAL = vtkImageGridSource::New();
		OUTPUT:
		RETVAL


void
vtkImageGridSource::SetDataExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetDataExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGridSource::SetDataExtent\n");



void
vtkImageGridSource::SetDataOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGridSource::SetDataOrigin\n");



void
vtkImageGridSource::SetDataScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetDataScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetDataScalarTypeToFloat()
		CODE:
		THIS->SetDataScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetDataScalarTypeToInt()
		CODE:
		THIS->SetDataScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetDataScalarTypeToShort()
		CODE:
		THIS->SetDataScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetDataScalarTypeToUnsignedChar()
		CODE:
		THIS->SetDataScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetDataScalarTypeToUnsignedShort()
		CODE:
		THIS->SetDataScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetDataSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGridSource::SetDataSpacing\n");



void
vtkImageGridSource::SetFillValue(arg1)
		float 	arg1
		CODE:
		THIS->SetFillValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageGridSource::SetGridOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetGridOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGridSource::SetGridOrigin\n");



void
vtkImageGridSource::SetGridSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetGridSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageGridSource::SetGridSpacing\n");



void
vtkImageGridSource::SetLineValue(arg1)
		float 	arg1
		CODE:
		THIS->SetLineValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageHSVToRGB PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageHSVToRGB::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageHSVToRGB::GetMaximum()
		CODE:
		RETVAL = THIS->GetMaximum();
		OUTPUT:
		RETVAL


static vtkImageHSVToRGB*
vtkImageHSVToRGB::New()
		CODE:
		RETVAL = vtkImageHSVToRGB::New();
		OUTPUT:
		RETVAL


void
vtkImageHSVToRGB::SetMaximum(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximum(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageHybridMedian2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageHybridMedian2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageHybridMedian2D*
vtkImageHybridMedian2D::New()
		CODE:
		RETVAL = vtkImageHybridMedian2D::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageIdealHighPass PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageIdealHighPass::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkImageIdealHighPass::GetCutOff()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCutOff();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkImageIdealHighPass::GetXCutOff()
		CODE:
		RETVAL = THIS->GetXCutOff();
		OUTPUT:
		RETVAL


float
vtkImageIdealHighPass::GetYCutOff()
		CODE:
		RETVAL = THIS->GetYCutOff();
		OUTPUT:
		RETVAL


float
vtkImageIdealHighPass::GetZCutOff()
		CODE:
		RETVAL = THIS->GetZCutOff();
		OUTPUT:
		RETVAL


static vtkImageIdealHighPass*
vtkImageIdealHighPass::New()
		CODE:
		RETVAL = vtkImageIdealHighPass::New();
		OUTPUT:
		RETVAL


void
vtkImageIdealHighPass::SetCutOff(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCutOff(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetCutOff(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageIdealHighPass::SetCutOff\n");



void
vtkImageIdealHighPass::SetXCutOff(v)
		float 	v
		CODE:
		THIS->SetXCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageIdealHighPass::SetYCutOff(v)
		float 	v
		CODE:
		THIS->SetYCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageIdealHighPass::SetZCutOff(v)
		float 	v
		CODE:
		THIS->SetZCutOff(v);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageIdealLowPass PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageIdealLowPass::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkImageIdealLowPass::GetCutOff()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCutOff();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkImageIdealLowPass::GetXCutOff()
		CODE:
		RETVAL = THIS->GetXCutOff();
		OUTPUT:
		RETVAL


float
vtkImageIdealLowPass::GetYCutOff()
		CODE:
		RETVAL = THIS->GetYCutOff();
		OUTPUT:
		RETVAL


float
vtkImageIdealLowPass::GetZCutOff()
		CODE:
		RETVAL = THIS->GetZCutOff();
		OUTPUT:
		RETVAL


static vtkImageIdealLowPass*
vtkImageIdealLowPass::New()
		CODE:
		RETVAL = vtkImageIdealLowPass::New();
		OUTPUT:
		RETVAL


void
vtkImageIdealLowPass::SetCutOff(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetCutOff(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetCutOff(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageIdealLowPass::SetCutOff\n");



void
vtkImageIdealLowPass::SetXCutOff(v)
		float 	v
		CODE:
		THIS->SetXCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageIdealLowPass::SetYCutOff(v)
		float 	v
		CODE:
		THIS->SetYCutOff(v);
		XSRETURN_EMPTY;


void
vtkImageIdealLowPass::SetZCutOff(v)
		float 	v
		CODE:
		THIS->SetZCutOff(v);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageImport PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageImport::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImageImport::GetDataExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataExtent();
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
vtkImageImport::GetDataOrigin()
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


int
vtkImageImport::GetDataScalarType()
		CODE:
		RETVAL = THIS->GetDataScalarType();
		OUTPUT:
		RETVAL


const char *
vtkImageImport::GetDataScalarTypeAsString()
		CODE:
		RETVAL = THIS->GetDataScalarTypeAsString();
		OUTPUT:
		RETVAL


float  *
vtkImageImport::GetDataSpacing()
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
vtkImageImport::GetNumberOfScalarComponents()
		CODE:
		RETVAL = THIS->GetNumberOfScalarComponents();
		OUTPUT:
		RETVAL


int  *
vtkImageImport::GetWholeExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWholeExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


static vtkImageImport*
vtkImageImport::New()
		CODE:
		RETVAL = vtkImageImport::New();
		OUTPUT:
		RETVAL


void
vtkImageImport::PropagateUpdateExtent(output)
		vtkDataObject *	output
		CODE:
		THIS->PropagateUpdateExtent(output);
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetDataExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageImport::SetDataExtent\n");



void
vtkImageImport::SetDataExtentToWholeExtent()
		CODE:
		THIS->SetDataExtentToWholeExtent();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageImport::SetDataOrigin\n");



void
vtkImageImport::SetDataScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetDataScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataScalarTypeToDouble()
		CODE:
		THIS->SetDataScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataScalarTypeToFloat()
		CODE:
		THIS->SetDataScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataScalarTypeToInt()
		CODE:
		THIS->SetDataScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataScalarTypeToShort()
		CODE:
		THIS->SetDataScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataScalarTypeToUnsignedChar()
		CODE:
		THIS->SetDataScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataScalarTypeToUnsignedShort()
		CODE:
		THIS->SetDataScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageImport::SetDataSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageImport::SetDataSpacing\n");



void
vtkImageImport::SetNumberOfScalarComponents(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfScalarComponents(arg1);
		XSRETURN_EMPTY;


void
vtkImageImport::SetWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetWholeExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageImport::SetWholeExtent\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageIslandRemoval2D PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkImageIslandRemoval2D::GetAreaThreshold()
		CODE:
		RETVAL = THIS->GetAreaThreshold();
		OUTPUT:
		RETVAL


const char *
vtkImageIslandRemoval2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageIslandRemoval2D::GetIslandValue()
		CODE:
		RETVAL = THIS->GetIslandValue();
		OUTPUT:
		RETVAL


float
vtkImageIslandRemoval2D::GetReplaceValue()
		CODE:
		RETVAL = THIS->GetReplaceValue();
		OUTPUT:
		RETVAL


int
vtkImageIslandRemoval2D::GetSquareNeighborhood()
		CODE:
		RETVAL = THIS->GetSquareNeighborhood();
		OUTPUT:
		RETVAL


static vtkImageIslandRemoval2D*
vtkImageIslandRemoval2D::New()
		CODE:
		RETVAL = vtkImageIslandRemoval2D::New();
		OUTPUT:
		RETVAL


void
vtkImageIslandRemoval2D::SetAreaThreshold(arg1)
		int 	arg1
		CODE:
		THIS->SetAreaThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageIslandRemoval2D::SetIslandValue(arg1)
		float 	arg1
		CODE:
		THIS->SetIslandValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageIslandRemoval2D::SetReplaceValue(arg1)
		float 	arg1
		CODE:
		THIS->SetReplaceValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageIslandRemoval2D::SetSquareNeighborhood(arg1)
		int 	arg1
		CODE:
		THIS->SetSquareNeighborhood(arg1);
		XSRETURN_EMPTY;


void
vtkImageIslandRemoval2D::SquareNeighborhoodOff()
		CODE:
		THIS->SquareNeighborhoodOff();
		XSRETURN_EMPTY;


void
vtkImageIslandRemoval2D::SquareNeighborhoodOn()
		CODE:
		THIS->SquareNeighborhoodOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageIterateFilter PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageIterateFilter::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


const char *
vtkImageIterateFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageIterateFilter::GetIteration()
		CODE:
		RETVAL = THIS->GetIteration();
		OUTPUT:
		RETVAL


int
vtkImageIterateFilter::GetNumberOfIterations()
		CODE:
		RETVAL = THIS->GetNumberOfIterations();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageLaplacian PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageLaplacian::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageLaplacian::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageLaplacian::GetDimensionalityMaxValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageLaplacian::GetDimensionalityMinValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMinValue();
		OUTPUT:
		RETVAL


static vtkImageLaplacian*
vtkImageLaplacian::New()
		CODE:
		RETVAL = vtkImageLaplacian::New();
		OUTPUT:
		RETVAL


void
vtkImageLaplacian::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageLogarithmicScale PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageLogarithmicScale::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageLogarithmicScale::GetConstant()
		CODE:
		RETVAL = THIS->GetConstant();
		OUTPUT:
		RETVAL


static vtkImageLogarithmicScale*
vtkImageLogarithmicScale::New()
		CODE:
		RETVAL = vtkImageLogarithmicScale::New();
		OUTPUT:
		RETVAL


void
vtkImageLogarithmicScale::SetConstant(arg1)
		float 	arg1
		CODE:
		THIS->SetConstant(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageLogic PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageLogic::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageLogic::GetOperation()
		CODE:
		RETVAL = THIS->GetOperation();
		OUTPUT:
		RETVAL


float
vtkImageLogic::GetOutputTrueValue()
		CODE:
		RETVAL = THIS->GetOutputTrueValue();
		OUTPUT:
		RETVAL


static vtkImageLogic*
vtkImageLogic::New()
		CODE:
		RETVAL = vtkImageLogic::New();
		OUTPUT:
		RETVAL


void
vtkImageLogic::SetOperation(arg1)
		int 	arg1
		CODE:
		THIS->SetOperation(arg1);
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOperationToAnd()
		CODE:
		THIS->SetOperationToAnd();
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOperationToNand()
		CODE:
		THIS->SetOperationToNand();
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOperationToNor()
		CODE:
		THIS->SetOperationToNor();
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOperationToNot()
		CODE:
		THIS->SetOperationToNot();
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOperationToOr()
		CODE:
		THIS->SetOperationToOr();
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOperationToXor()
		CODE:
		THIS->SetOperationToXor();
		XSRETURN_EMPTY;


void
vtkImageLogic::SetOutputTrueValue(arg1)
		float 	arg1
		CODE:
		THIS->SetOutputTrueValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageLuminance PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageLuminance::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageLuminance*
vtkImageLuminance::New()
		CODE:
		RETVAL = vtkImageLuminance::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMagnify PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMagnify::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageMagnify::GetInterpolate()
		CODE:
		RETVAL = THIS->GetInterpolate();
		OUTPUT:
		RETVAL


int  *
vtkImageMagnify::GetMagnificationFactors()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMagnificationFactors();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


void
vtkImageMagnify::InterpolateOff()
		CODE:
		THIS->InterpolateOff();
		XSRETURN_EMPTY;


void
vtkImageMagnify::InterpolateOn()
		CODE:
		THIS->InterpolateOn();
		XSRETURN_EMPTY;


static vtkImageMagnify*
vtkImageMagnify::New()
		CODE:
		RETVAL = vtkImageMagnify::New();
		OUTPUT:
		RETVAL


void
vtkImageMagnify::SetInterpolate(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolate(arg1);
		XSRETURN_EMPTY;


void
vtkImageMagnify::SetMagnificationFactors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetMagnificationFactors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMagnify::SetMagnificationFactors\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMagnitude PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMagnitude::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageMagnitude*
vtkImageMagnitude::New()
		CODE:
		RETVAL = vtkImageMagnitude::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMandelbrotSource PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageMandelbrotSource::CopyOriginAndSample(source)
		vtkImageMandelbrotSource *	source
		CODE:
		THIS->CopyOriginAndSample(source);
		XSRETURN_EMPTY;


const char *
vtkImageMandelbrotSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned short
vtkImageMandelbrotSource::GetMaximumNumberOfIterations()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfIterations();
		OUTPUT:
		RETVAL


unsigned
vtkImageMandelbrotSource::GetMaximumNumberOfIterationsMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfIterationsMaxValue();
		OUTPUT:
		RETVAL


unsigned
vtkImageMandelbrotSource::GetMaximumNumberOfIterationsMinValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfIterationsMinValue();
		OUTPUT:
		RETVAL


double  *
vtkImageMandelbrotSource::GetOriginCX()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOriginCX();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


int  *
vtkImageMandelbrotSource::GetProjectionAxes()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetProjectionAxes();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double  *
vtkImageMandelbrotSource::GetSampleCX()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSampleCX();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


int  *
vtkImageMandelbrotSource::GetWholeExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWholeExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


static vtkImageMandelbrotSource*
vtkImageMandelbrotSource::New()
		CODE:
		RETVAL = vtkImageMandelbrotSource::New();
		OUTPUT:
		RETVAL


void
vtkImageMandelbrotSource::Pan(x, y, z)
		double 	x
		double 	y
		double 	z
		CODE:
		THIS->Pan(x, y, z);
		XSRETURN_EMPTY;


void
vtkImageMandelbrotSource::SetMaximumNumberOfIterations(arg1)
		unsigned short 	arg1
		CODE:
		THIS->SetMaximumNumberOfIterations(arg1);
		XSRETURN_EMPTY;


void
vtkImageMandelbrotSource::SetOriginCX(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->SetOriginCX(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMandelbrotSource::SetOriginCX\n");



void
vtkImageMandelbrotSource::SetProjectionAxes(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetProjectionAxes(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMandelbrotSource::SetProjectionAxes\n");



void
vtkImageMandelbrotSource::SetSample(v)
		double 	v
		CODE:
		THIS->SetSample(v);
		XSRETURN_EMPTY;


void
vtkImageMandelbrotSource::SetSampleCX(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->SetSampleCX(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMandelbrotSource::SetSampleCX\n");



void
vtkImageMandelbrotSource::SetWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetWholeExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMandelbrotSource::SetWholeExtent\n");



void
vtkImageMandelbrotSource::Zoom(factor)
		double 	factor
		CODE:
		THIS->Zoom(factor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMapToColors PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkImageMapToColors::GetActiveComponent()
		CODE:
		RETVAL = THIS->GetActiveComponent();
		OUTPUT:
		RETVAL


const char *
vtkImageMapToColors::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkScalarsToColors *
vtkImageMapToColors::GetLookupTable()
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


unsigned long
vtkImageMapToColors::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkImageMapToColors::GetOutputFormat()
		CODE:
		RETVAL = THIS->GetOutputFormat();
		OUTPUT:
		RETVAL


int
vtkImageMapToColors::GetPassAlphaToOutput()
		CODE:
		RETVAL = THIS->GetPassAlphaToOutput();
		OUTPUT:
		RETVAL


static vtkImageMapToColors*
vtkImageMapToColors::New()
		CODE:
		RETVAL = vtkImageMapToColors::New();
		OUTPUT:
		RETVAL


void
vtkImageMapToColors::PassAlphaToOutputOff()
		CODE:
		THIS->PassAlphaToOutputOff();
		XSRETURN_EMPTY;


void
vtkImageMapToColors::PassAlphaToOutputOn()
		CODE:
		THIS->PassAlphaToOutputOn();
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetActiveComponent(arg1)
		int 	arg1
		CODE:
		THIS->SetActiveComponent(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetLookupTable(arg1)
		vtkScalarsToColors *	arg1
		CODE:
		THIS->SetLookupTable(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetOutputFormat(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputFormat(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetOutputFormatToLuminance()
		CODE:
		THIS->SetOutputFormatToLuminance();
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetOutputFormatToLuminanceAlpha()
		CODE:
		THIS->SetOutputFormatToLuminanceAlpha();
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetOutputFormatToRGB()
		CODE:
		THIS->SetOutputFormatToRGB();
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetOutputFormatToRGBA()
		CODE:
		THIS->SetOutputFormatToRGBA();
		XSRETURN_EMPTY;


void
vtkImageMapToColors::SetPassAlphaToOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetPassAlphaToOutput(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMapToRGBA PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMapToRGBA::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageMapToRGBA*
vtkImageMapToRGBA::New()
		CODE:
		RETVAL = vtkImageMapToRGBA::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMapToWindowLevelColors PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMapToWindowLevelColors::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageMapToWindowLevelColors::GetLevel()
		CODE:
		RETVAL = THIS->GetLevel();
		OUTPUT:
		RETVAL


float
vtkImageMapToWindowLevelColors::GetWindow()
		CODE:
		RETVAL = THIS->GetWindow();
		OUTPUT:
		RETVAL


static vtkImageMapToWindowLevelColors*
vtkImageMapToWindowLevelColors::New()
		CODE:
		RETVAL = vtkImageMapToWindowLevelColors::New();
		OUTPUT:
		RETVAL


void
vtkImageMapToWindowLevelColors::SetLevel(arg1)
		float 	arg1
		CODE:
		THIS->SetLevel(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapToWindowLevelColors::SetWindow(arg1)
		float 	arg1
		CODE:
		THIS->SetWindow(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMask PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMask::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageMask::GetMaskedOutputValueLength()
		CODE:
		RETVAL = THIS->GetMaskedOutputValueLength();
		OUTPUT:
		RETVAL


int
vtkImageMask::GetNotMask()
		CODE:
		RETVAL = THIS->GetNotMask();
		OUTPUT:
		RETVAL


static vtkImageMask*
vtkImageMask::New()
		CODE:
		RETVAL = vtkImageMask::New();
		OUTPUT:
		RETVAL


void
vtkImageMask::NotMaskOff()
		CODE:
		THIS->NotMaskOff();
		XSRETURN_EMPTY;


void
vtkImageMask::NotMaskOn()
		CODE:
		THIS->NotMaskOn();
		XSRETURN_EMPTY;


void
vtkImageMask::SetImageInput(in)
		vtkImageData *	in
		CODE:
		THIS->SetImageInput(in);
		XSRETURN_EMPTY;


void
vtkImageMask::SetMaskInput(in)
		vtkImageData *	in
		CODE:
		THIS->SetMaskInput(in);
		XSRETURN_EMPTY;


void
vtkImageMask::SetMaskedOutputValue(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetMaskedOutputValue(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetMaskedOutputValue(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetMaskedOutputValue(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMask::SetMaskedOutputValue\n");



void
vtkImageMask::SetNotMask(arg1)
		int 	arg1
		CODE:
		THIS->SetNotMask(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMaskBits PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMaskBits::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned int  *
vtkImageMaskBits::GetMasks()
		PREINIT:
		unsigned int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMasks();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


int
vtkImageMaskBits::GetOperation()
		CODE:
		RETVAL = THIS->GetOperation();
		OUTPUT:
		RETVAL


static vtkImageMaskBits*
vtkImageMaskBits::New()
		CODE:
		RETVAL = vtkImageMaskBits::New();
		OUTPUT:
		RETVAL


void
vtkImageMaskBits::SetMask(mask)
		unsigned int 	mask
		CODE:
		THIS->SetMask(mask);
		XSRETURN_EMPTY;


void
vtkImageMaskBits::SetMasks(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		unsigned int 	arg1
		unsigned int 	arg2
		unsigned int 	arg3
		unsigned int 	arg4
		CODE:
		THIS->SetMasks(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 4
		unsigned int 	arg1
		unsigned int 	arg2
		unsigned int 	arg3
		CODE:
		THIS->SetMasks(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		unsigned int 	arg1
		unsigned int 	arg2
		CODE:
		THIS->SetMasks(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageMaskBits::SetMasks\n");



void
vtkImageMaskBits::SetOperation(arg1)
		int 	arg1
		CODE:
		THIS->SetOperation(arg1);
		XSRETURN_EMPTY;


void
vtkImageMaskBits::SetOperationToAnd()
		CODE:
		THIS->SetOperationToAnd();
		XSRETURN_EMPTY;


void
vtkImageMaskBits::SetOperationToNand()
		CODE:
		THIS->SetOperationToNand();
		XSRETURN_EMPTY;


void
vtkImageMaskBits::SetOperationToNor()
		CODE:
		THIS->SetOperationToNor();
		XSRETURN_EMPTY;


void
vtkImageMaskBits::SetOperationToOr()
		CODE:
		THIS->SetOperationToOr();
		XSRETURN_EMPTY;


void
vtkImageMaskBits::SetOperationToXor()
		CODE:
		THIS->SetOperationToXor();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMathematics PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMathematics::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


double
vtkImageMathematics::GetConstantC()
		CODE:
		RETVAL = THIS->GetConstantC();
		OUTPUT:
		RETVAL


double
vtkImageMathematics::GetConstantK()
		CODE:
		RETVAL = THIS->GetConstantK();
		OUTPUT:
		RETVAL


int
vtkImageMathematics::GetOperation()
		CODE:
		RETVAL = THIS->GetOperation();
		OUTPUT:
		RETVAL


static vtkImageMathematics*
vtkImageMathematics::New()
		CODE:
		RETVAL = vtkImageMathematics::New();
		OUTPUT:
		RETVAL


void
vtkImageMathematics::SetConstantC(arg1)
		double 	arg1
		CODE:
		THIS->SetConstantC(arg1);
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetConstantK(arg1)
		double 	arg1
		CODE:
		THIS->SetConstantK(arg1);
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperation(arg1)
		int 	arg1
		CODE:
		THIS->SetOperation(arg1);
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToATAN()
		CODE:
		THIS->SetOperationToATAN();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToATAN2()
		CODE:
		THIS->SetOperationToATAN2();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToAbsoluteValue()
		CODE:
		THIS->SetOperationToAbsoluteValue();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToAdd()
		CODE:
		THIS->SetOperationToAdd();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToAddConstant()
		CODE:
		THIS->SetOperationToAddConstant();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToComplexMultiply()
		CODE:
		THIS->SetOperationToComplexMultiply();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToConjugate()
		CODE:
		THIS->SetOperationToConjugate();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToCos()
		CODE:
		THIS->SetOperationToCos();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToDivide()
		CODE:
		THIS->SetOperationToDivide();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToExp()
		CODE:
		THIS->SetOperationToExp();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToInvert()
		CODE:
		THIS->SetOperationToInvert();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToLog()
		CODE:
		THIS->SetOperationToLog();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToMax()
		CODE:
		THIS->SetOperationToMax();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToMin()
		CODE:
		THIS->SetOperationToMin();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToMultiply()
		CODE:
		THIS->SetOperationToMultiply();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToMultiplyByK()
		CODE:
		THIS->SetOperationToMultiplyByK();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToReplaceCByK()
		CODE:
		THIS->SetOperationToReplaceCByK();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToSin()
		CODE:
		THIS->SetOperationToSin();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToSquare()
		CODE:
		THIS->SetOperationToSquare();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToSquareRoot()
		CODE:
		THIS->SetOperationToSquareRoot();
		XSRETURN_EMPTY;


void
vtkImageMathematics::SetOperationToSubtract()
		CODE:
		THIS->SetOperationToSubtract();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMedian3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMedian3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageMedian3D::GetNumberOfElements()
		CODE:
		RETVAL = THIS->GetNumberOfElements();
		OUTPUT:
		RETVAL


static vtkImageMedian3D*
vtkImageMedian3D::New()
		CODE:
		RETVAL = vtkImageMedian3D::New();
		OUTPUT:
		RETVAL


void
vtkImageMedian3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageMirrorPad PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMirrorPad::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageMirrorPad*
vtkImageMirrorPad::New()
		CODE:
		RETVAL = vtkImageMirrorPad::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageNoiseSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageNoiseSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageNoiseSource::GetMaximum()
		CODE:
		RETVAL = THIS->GetMaximum();
		OUTPUT:
		RETVAL


float
vtkImageNoiseSource::GetMinimum()
		CODE:
		RETVAL = THIS->GetMinimum();
		OUTPUT:
		RETVAL


static vtkImageNoiseSource*
vtkImageNoiseSource::New()
		CODE:
		RETVAL = vtkImageNoiseSource::New();
		OUTPUT:
		RETVAL


void
vtkImageNoiseSource::SetMaximum(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkImageNoiseSource::SetMinimum(arg1)
		float 	arg1
		CODE:
		THIS->SetMinimum(arg1);
		XSRETURN_EMPTY;


void
vtkImageNoiseSource::SetWholeExtent(xMinx, xMax, yMin, yMax, zMin, zMax)
		int 	xMinx
		int 	xMax
		int 	yMin
		int 	yMax
		int 	zMin
		int 	zMax
		CODE:
		THIS->SetWholeExtent(xMinx, xMax, yMin, yMax, zMin, zMax);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageNonMaximumSuppression PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageNonMaximumSuppression::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageNonMaximumSuppression::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageNonMaximumSuppression::GetDimensionalityMaxValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageNonMaximumSuppression::GetDimensionalityMinValue()
		CODE:
		RETVAL = THIS->GetDimensionalityMinValue();
		OUTPUT:
		RETVAL


int
vtkImageNonMaximumSuppression::GetHandleBoundaries()
		CODE:
		RETVAL = THIS->GetHandleBoundaries();
		OUTPUT:
		RETVAL


void
vtkImageNonMaximumSuppression::HandleBoundariesOff()
		CODE:
		THIS->HandleBoundariesOff();
		XSRETURN_EMPTY;


void
vtkImageNonMaximumSuppression::HandleBoundariesOn()
		CODE:
		THIS->HandleBoundariesOn();
		XSRETURN_EMPTY;


static vtkImageNonMaximumSuppression*
vtkImageNonMaximumSuppression::New()
		CODE:
		RETVAL = vtkImageNonMaximumSuppression::New();
		OUTPUT:
		RETVAL


void
vtkImageNonMaximumSuppression::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageNonMaximumSuppression::SetHandleBoundaries(arg1)
		int 	arg1
		CODE:
		THIS->SetHandleBoundaries(arg1);
		XSRETURN_EMPTY;


void
vtkImageNonMaximumSuppression::SetMagnitudeInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetMagnitudeInput(input);
		XSRETURN_EMPTY;


void
vtkImageNonMaximumSuppression::SetVectorInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetVectorInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageNormalize PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageNormalize::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageNormalize*
vtkImageNormalize::New()
		CODE:
		RETVAL = vtkImageNormalize::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageOpenClose3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageOpenClose3D::DebugOff()
		CODE:
		THIS->DebugOff();
		XSRETURN_EMPTY;


void
vtkImageOpenClose3D::DebugOn()
		CODE:
		THIS->DebugOn();
		XSRETURN_EMPTY;


const char *
vtkImageOpenClose3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageOpenClose3D::GetCloseValue()
		CODE:
		RETVAL = THIS->GetCloseValue();
		OUTPUT:
		RETVAL


vtkImageDilateErode3D *
vtkImageOpenClose3D::GetFilter0()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageDilateErode3D";
		CODE:
		RETVAL = THIS->GetFilter0();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageDilateErode3D *
vtkImageOpenClose3D::GetFilter1()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageDilateErode3D";
		CODE:
		RETVAL = THIS->GetFilter1();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkImageOpenClose3D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkImageOpenClose3D::GetOpenValue()
		CODE:
		RETVAL = THIS->GetOpenValue();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageOpenClose3D::GetOutput(arg1 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkImageOpenClose3D::GetOutput\n");



void
vtkImageOpenClose3D::Modified()
		CODE:
		THIS->Modified();
		XSRETURN_EMPTY;


static vtkImageOpenClose3D*
vtkImageOpenClose3D::New()
		CODE:
		RETVAL = vtkImageOpenClose3D::New();
		OUTPUT:
		RETVAL


void
vtkImageOpenClose3D::SetCloseValue(value)
		float 	value
		CODE:
		THIS->SetCloseValue(value);
		XSRETURN_EMPTY;


void
vtkImageOpenClose3D::SetInput(Input)
		vtkImageData *	Input
		CODE:
		THIS->SetInput(Input);
		XSRETURN_EMPTY;


void
vtkImageOpenClose3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;


void
vtkImageOpenClose3D::SetOpenValue(value)
		float 	value
		CODE:
		THIS->SetOpenValue(value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImagePadFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImagePadFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImagePadFilter::GetOutputNumberOfScalarComponents()
		CODE:
		RETVAL = THIS->GetOutputNumberOfScalarComponents();
		OUTPUT:
		RETVAL


int *
vtkImagePadFilter::GetOutputWholeExtent()
	CASE: items == 1
		PREINIT:
		int * retval;
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
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImagePadFilter::GetOutputWholeExtent\n");



static vtkImagePadFilter*
vtkImagePadFilter::New()
		CODE:
		RETVAL = vtkImagePadFilter::New();
		OUTPUT:
		RETVAL


void
vtkImagePadFilter::SetOutputNumberOfScalarComponents(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputNumberOfScalarComponents(arg1);
		XSRETURN_EMPTY;


void
vtkImagePadFilter::SetOutputWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkImagePadFilter::SetOutputWholeExtent\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImagePermute PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImagePermute::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImagePermute::GetFilteredAxes()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFilteredAxes();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImagePermute*
vtkImagePermute::New()
		CODE:
		RETVAL = vtkImagePermute::New();
		OUTPUT:
		RETVAL


void
vtkImagePermute::SetFilteredAxes(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetFilteredAxes(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImagePermute::SetFilteredAxes\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageQuantizeRGBToIndex PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImageQuantizeRGBToIndex::GetBuildTreeExecuteTime()
		CODE:
		RETVAL = THIS->GetBuildTreeExecuteTime();
		OUTPUT:
		RETVAL


const char *
vtkImageQuantizeRGBToIndex::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageQuantizeRGBToIndex::GetInitializeExecuteTime()
		CODE:
		RETVAL = THIS->GetInitializeExecuteTime();
		OUTPUT:
		RETVAL


float
vtkImageQuantizeRGBToIndex::GetLookupIndexExecuteTime()
		CODE:
		RETVAL = THIS->GetLookupIndexExecuteTime();
		OUTPUT:
		RETVAL


vtkLookupTable *
vtkImageQuantizeRGBToIndex::GetLookupTable()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLookupTable";
		CODE:
		RETVAL = THIS->GetLookupTable();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageQuantizeRGBToIndex::GetNumberOfColors()
		CODE:
		RETVAL = THIS->GetNumberOfColors();
		OUTPUT:
		RETVAL


int
vtkImageQuantizeRGBToIndex::GetNumberOfColorsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfColorsMaxValue();
		OUTPUT:
		RETVAL


int
vtkImageQuantizeRGBToIndex::GetNumberOfColorsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfColorsMinValue();
		OUTPUT:
		RETVAL


static vtkImageQuantizeRGBToIndex*
vtkImageQuantizeRGBToIndex::New()
		CODE:
		RETVAL = vtkImageQuantizeRGBToIndex::New();
		OUTPUT:
		RETVAL


void
vtkImageQuantizeRGBToIndex::SetNumberOfColors(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfColors(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageRFFT PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageRFFT::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkImageRFFT::IterativeExecuteData(in, out)
		vtkImageData *	in
		vtkImageData *	out
		CODE:
		THIS->IterativeExecuteData(in, out);
		XSRETURN_EMPTY;


static vtkImageRFFT*
vtkImageRFFT::New()
		CODE:
		RETVAL = vtkImageRFFT::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageRGBToHSV PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageRGBToHSV::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageRGBToHSV::GetMaximum()
		CODE:
		RETVAL = THIS->GetMaximum();
		OUTPUT:
		RETVAL


static vtkImageRGBToHSV*
vtkImageRGBToHSV::New()
		CODE:
		RETVAL = vtkImageRGBToHSV::New();
		OUTPUT:
		RETVAL


void
vtkImageRGBToHSV::SetMaximum(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximum(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageRange3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageRange3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageRange3D*
vtkImageRange3D::New()
		CODE:
		RETVAL = vtkImageRange3D::New();
		OUTPUT:
		RETVAL


void
vtkImageRange3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageResample PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImageResample::GetAxisMagnificationFactor(axis)
		int 	axis
		CODE:
		RETVAL = THIS->GetAxisMagnificationFactor(axis);
		OUTPUT:
		RETVAL


const char *
vtkImageResample::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageResample::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageResample::GetInterpolate()
		CODE:
		RETVAL = THIS->GetInterpolate();
		OUTPUT:
		RETVAL


void
vtkImageResample::InterpolateOff()
		CODE:
		THIS->InterpolateOff();
		XSRETURN_EMPTY;


void
vtkImageResample::InterpolateOn()
		CODE:
		THIS->InterpolateOn();
		XSRETURN_EMPTY;


static vtkImageResample*
vtkImageResample::New()
		CODE:
		RETVAL = vtkImageResample::New();
		OUTPUT:
		RETVAL


void
vtkImageResample::SetAxisMagnificationFactor(axis, factor)
		int 	axis
		float 	factor
		CODE:
		THIS->SetAxisMagnificationFactor(axis, factor);
		XSRETURN_EMPTY;


void
vtkImageResample::SetAxisOutputSpacing(axis, spacing)
		int 	axis
		float 	spacing
		CODE:
		THIS->SetAxisOutputSpacing(axis, spacing);
		XSRETURN_EMPTY;


void
vtkImageResample::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageResample::SetInterpolate(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolate(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageReslice PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageReslice::AutoCropOutputOff()
		CODE:
		THIS->AutoCropOutputOff();
		XSRETURN_EMPTY;


void
vtkImageReslice::AutoCropOutputOn()
		CODE:
		THIS->AutoCropOutputOn();
		XSRETURN_EMPTY;


int
vtkImageReslice::GetAutoCropOutput()
		CODE:
		RETVAL = THIS->GetAutoCropOutput();
		OUTPUT:
		RETVAL


float  *
vtkImageReslice::GetBackgroundColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBackgroundColor();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


float
vtkImageReslice::GetBackgroundLevel()
		CODE:
		RETVAL = THIS->GetBackgroundLevel();
		OUTPUT:
		RETVAL


const char *
vtkImageReslice::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageReslice::GetInformationInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInformationInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetInterpolate()
		CODE:
		RETVAL = THIS->GetInterpolate();
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetInterpolationMode()
		CODE:
		RETVAL = THIS->GetInterpolationMode();
		OUTPUT:
		RETVAL


const char *
vtkImageReslice::GetInterpolationModeAsString()
		CODE:
		RETVAL = THIS->GetInterpolationModeAsString();
		OUTPUT:
		RETVAL


unsigned long
vtkImageReslice::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetMirror()
		CODE:
		RETVAL = THIS->GetMirror();
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetOptimization()
		CODE:
		RETVAL = THIS->GetOptimization();
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetOutputDimensionality()
		CODE:
		RETVAL = THIS->GetOutputDimensionality();
		OUTPUT:
		RETVAL


int  *
vtkImageReslice::GetOutputExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputExtent();
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
vtkImageReslice::GetOutputOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageReslice::GetOutputSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOutputSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkMatrix4x4 *
vtkImageReslice::GetResliceAxes()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetResliceAxes();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double *
vtkImageReslice::GetResliceAxesDirectionCosines()
	CASE: items == 1
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->GetResliceAxesDirectionCosines();
		EXTEND(SP, 9);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUSHs(sv_2mortal(newSVnv(retval[6])));
		PUSHs(sv_2mortal(newSVnv(retval[7])));
		PUSHs(sv_2mortal(newSVnv(retval[8])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::GetResliceAxesDirectionCosines\n");



double *
vtkImageReslice::GetResliceAxesOrigin()
	CASE: items == 1
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->GetResliceAxesOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::GetResliceAxesOrigin\n");



vtkAbstractTransform *
vtkImageReslice::GetResliceTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetResliceTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageStencilData *
vtkImageReslice::GetStencil()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageStencilData";
		CODE:
		RETVAL = THIS->GetStencil();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetTransformInputSampling()
		CODE:
		RETVAL = THIS->GetTransformInputSampling();
		OUTPUT:
		RETVAL


int
vtkImageReslice::GetWrap()
		CODE:
		RETVAL = THIS->GetWrap();
		OUTPUT:
		RETVAL


void
vtkImageReslice::InterpolateOff()
		CODE:
		THIS->InterpolateOff();
		XSRETURN_EMPTY;


void
vtkImageReslice::InterpolateOn()
		CODE:
		THIS->InterpolateOn();
		XSRETURN_EMPTY;


void
vtkImageReslice::MirrorOff()
		CODE:
		THIS->MirrorOff();
		XSRETURN_EMPTY;


void
vtkImageReslice::MirrorOn()
		CODE:
		THIS->MirrorOn();
		XSRETURN_EMPTY;


static vtkImageReslice*
vtkImageReslice::New()
		CODE:
		RETVAL = vtkImageReslice::New();
		OUTPUT:
		RETVAL


void
vtkImageReslice::OptimizationOff()
		CODE:
		THIS->OptimizationOff();
		XSRETURN_EMPTY;


void
vtkImageReslice::OptimizationOn()
		CODE:
		THIS->OptimizationOn();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetAutoCropOutput(arg1)
		int 	arg1
		CODE:
		THIS->SetAutoCropOutput(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetBackgroundColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetBackgroundColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::SetBackgroundColor\n");



void
vtkImageReslice::SetBackgroundLevel(v)
		float 	v
		CODE:
		THIS->SetBackgroundLevel(v);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetInformationInput(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetInformationInput(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetInterpolate(t)
		int 	t
		CODE:
		THIS->SetInterpolate(t);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetInterpolationMode(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolationMode(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetInterpolationModeToCubic()
		CODE:
		THIS->SetInterpolationModeToCubic();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetInterpolationModeToLinear()
		CODE:
		THIS->SetInterpolationModeToLinear();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetInterpolationModeToNearestNeighbor()
		CODE:
		THIS->SetInterpolationModeToNearestNeighbor();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetMirror(arg1)
		int 	arg1
		CODE:
		THIS->SetMirror(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetOptimization(arg1)
		int 	arg1
		CODE:
		THIS->SetOptimization(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetOutputDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetOutputExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetOutputExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::SetOutputExtent\n");



void
vtkImageReslice::SetOutputExtentToDefault()
		CODE:
		THIS->SetOutputExtentToDefault();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetOutputOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutputOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::SetOutputOrigin\n");



void
vtkImageReslice::SetOutputOriginToDefault()
		CODE:
		THIS->SetOutputOriginToDefault();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetOutputSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOutputSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::SetOutputSpacing\n");



void
vtkImageReslice::SetOutputSpacingToDefault()
		CODE:
		THIS->SetOutputSpacingToDefault();
		XSRETURN_EMPTY;


void
vtkImageReslice::SetResliceAxes(arg1)
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->SetResliceAxes(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetResliceAxesDirectionCosines(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0, arg7 = 0, arg8 = 0, arg9 = 0)
	CASE: items == 10
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		double 	arg5
		double 	arg6
		double 	arg7
		double 	arg8
		double 	arg9
		CODE:
		THIS->SetResliceAxesDirectionCosines(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::SetResliceAxesDirectionCosines\n");



void
vtkImageReslice::SetResliceAxesOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetResliceAxesOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReslice::SetResliceAxesOrigin\n");



void
vtkImageReslice::SetResliceTransform(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->SetResliceTransform(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetStencil(stencil)
		vtkImageStencilData *	stencil
		CODE:
		THIS->SetStencil(stencil);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetTransformInputSampling(arg1)
		int 	arg1
		CODE:
		THIS->SetTransformInputSampling(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::SetWrap(arg1)
		int 	arg1
		CODE:
		THIS->SetWrap(arg1);
		XSRETURN_EMPTY;


void
vtkImageReslice::TransformInputSamplingOff()
		CODE:
		THIS->TransformInputSamplingOff();
		XSRETURN_EMPTY;


void
vtkImageReslice::TransformInputSamplingOn()
		CODE:
		THIS->TransformInputSamplingOn();
		XSRETURN_EMPTY;


void
vtkImageReslice::WrapOff()
		CODE:
		THIS->WrapOff();
		XSRETURN_EMPTY;


void
vtkImageReslice::WrapOn()
		CODE:
		THIS->WrapOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageSeedConnectivity PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageSeedConnectivity::AddSeed(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->AddSeed(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->AddSeed(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageSeedConnectivity::AddSeed\n");



const char *
vtkImageSeedConnectivity::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageConnector *
vtkImageSeedConnectivity::GetConnector()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageConnector";
		CODE:
		RETVAL = THIS->GetConnector();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageSeedConnectivity::GetDimensionality()
		CODE:
		RETVAL = THIS->GetDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageSeedConnectivity::GetInputConnectValue()
		CODE:
		RETVAL = THIS->GetInputConnectValue();
		OUTPUT:
		RETVAL


int
vtkImageSeedConnectivity::GetOutputConnectedValue()
		CODE:
		RETVAL = THIS->GetOutputConnectedValue();
		OUTPUT:
		RETVAL


int
vtkImageSeedConnectivity::GetOutputUnconnectedValue()
		CODE:
		RETVAL = THIS->GetOutputUnconnectedValue();
		OUTPUT:
		RETVAL


static vtkImageSeedConnectivity*
vtkImageSeedConnectivity::New()
		CODE:
		RETVAL = vtkImageSeedConnectivity::New();
		OUTPUT:
		RETVAL


void
vtkImageSeedConnectivity::RemoveAllSeeds()
		CODE:
		THIS->RemoveAllSeeds();
		XSRETURN_EMPTY;


void
vtkImageSeedConnectivity::SetDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageSeedConnectivity::SetInputConnectValue(arg1)
		int 	arg1
		CODE:
		THIS->SetInputConnectValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageSeedConnectivity::SetOutputConnectedValue(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputConnectedValue(arg1);
		XSRETURN_EMPTY;


void
vtkImageSeedConnectivity::SetOutputUnconnectedValue(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputUnconnectedValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageShiftScale PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageShiftScale::ClampOverflowOff()
		CODE:
		THIS->ClampOverflowOff();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::ClampOverflowOn()
		CODE:
		THIS->ClampOverflowOn();
		XSRETURN_EMPTY;


int
vtkImageShiftScale::GetClampOverflow()
		CODE:
		RETVAL = THIS->GetClampOverflow();
		OUTPUT:
		RETVAL


const char *
vtkImageShiftScale::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageShiftScale::GetOutputScalarType()
		CODE:
		RETVAL = THIS->GetOutputScalarType();
		OUTPUT:
		RETVAL


float
vtkImageShiftScale::GetScale()
		CODE:
		RETVAL = THIS->GetScale();
		OUTPUT:
		RETVAL


float
vtkImageShiftScale::GetShift()
		CODE:
		RETVAL = THIS->GetShift();
		OUTPUT:
		RETVAL


static vtkImageShiftScale*
vtkImageShiftScale::New()
		CODE:
		RETVAL = vtkImageShiftScale::New();
		OUTPUT:
		RETVAL


void
vtkImageShiftScale::SetClampOverflow(arg1)
		int 	arg1
		CODE:
		THIS->SetClampOverflow(arg1);
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToChar()
		CODE:
		THIS->SetOutputScalarTypeToChar();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToDouble()
		CODE:
		THIS->SetOutputScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToFloat()
		CODE:
		THIS->SetOutputScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToInt()
		CODE:
		THIS->SetOutputScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToLong()
		CODE:
		THIS->SetOutputScalarTypeToLong();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToShort()
		CODE:
		THIS->SetOutputScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToUnsignedChar()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToUnsignedInt()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedInt();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToUnsignedLong()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedLong();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetOutputScalarTypeToUnsignedShort()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetScale(arg1)
		float 	arg1
		CODE:
		THIS->SetScale(arg1);
		XSRETURN_EMPTY;


void
vtkImageShiftScale::SetShift(arg1)
		float 	arg1
		CODE:
		THIS->SetShift(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageShrink3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageShrink3D::AveragingOff()
		CODE:
		THIS->AveragingOff();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::AveragingOn()
		CODE:
		THIS->AveragingOn();
		XSRETURN_EMPTY;


int
vtkImageShrink3D::GetAveraging()
		CODE:
		RETVAL = THIS->GetAveraging();
		OUTPUT:
		RETVAL


const char *
vtkImageShrink3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageShrink3D::GetMaximum()
		CODE:
		RETVAL = THIS->GetMaximum();
		OUTPUT:
		RETVAL


int
vtkImageShrink3D::GetMean()
		CODE:
		RETVAL = THIS->GetMean();
		OUTPUT:
		RETVAL


int
vtkImageShrink3D::GetMedian()
		CODE:
		RETVAL = THIS->GetMedian();
		OUTPUT:
		RETVAL


int
vtkImageShrink3D::GetMinimum()
		CODE:
		RETVAL = THIS->GetMinimum();
		OUTPUT:
		RETVAL


int  *
vtkImageShrink3D::GetShift()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetShift();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int  *
vtkImageShrink3D::GetShrinkFactors()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetShrinkFactors();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


void
vtkImageShrink3D::MaximumOff()
		CODE:
		THIS->MaximumOff();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MaximumOn()
		CODE:
		THIS->MaximumOn();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MeanOff()
		CODE:
		THIS->MeanOff();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MeanOn()
		CODE:
		THIS->MeanOn();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MedianOff()
		CODE:
		THIS->MedianOff();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MedianOn()
		CODE:
		THIS->MedianOn();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MinimumOff()
		CODE:
		THIS->MinimumOff();
		XSRETURN_EMPTY;


void
vtkImageShrink3D::MinimumOn()
		CODE:
		THIS->MinimumOn();
		XSRETURN_EMPTY;


static vtkImageShrink3D*
vtkImageShrink3D::New()
		CODE:
		RETVAL = vtkImageShrink3D::New();
		OUTPUT:
		RETVAL


void
vtkImageShrink3D::SetAveraging(arg1)
		int 	arg1
		CODE:
		THIS->SetAveraging(arg1);
		XSRETURN_EMPTY;


void
vtkImageShrink3D::SetMaximum(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximum(arg1);
		XSRETURN_EMPTY;


void
vtkImageShrink3D::SetMean(arg1)
		int 	arg1
		CODE:
		THIS->SetMean(arg1);
		XSRETURN_EMPTY;


void
vtkImageShrink3D::SetMedian(arg1)
		int 	arg1
		CODE:
		THIS->SetMedian(arg1);
		XSRETURN_EMPTY;


void
vtkImageShrink3D::SetMinimum(arg1)
		int 	arg1
		CODE:
		THIS->SetMinimum(arg1);
		XSRETURN_EMPTY;


void
vtkImageShrink3D::SetShift(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetShift(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageShrink3D::SetShift\n");



void
vtkImageShrink3D::SetShrinkFactors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetShrinkFactors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageShrink3D::SetShrinkFactors\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageSinusoidSource PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImageSinusoidSource::GetAmplitude()
		CODE:
		RETVAL = THIS->GetAmplitude();
		OUTPUT:
		RETVAL


const char *
vtkImageSinusoidSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkImageSinusoidSource::GetDirection()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDirection();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkImageSinusoidSource::GetPeriod()
		CODE:
		RETVAL = THIS->GetPeriod();
		OUTPUT:
		RETVAL


float
vtkImageSinusoidSource::GetPhase()
		CODE:
		RETVAL = THIS->GetPhase();
		OUTPUT:
		RETVAL


static vtkImageSinusoidSource*
vtkImageSinusoidSource::New()
		CODE:
		RETVAL = vtkImageSinusoidSource::New();
		OUTPUT:
		RETVAL


void
vtkImageSinusoidSource::SetAmplitude(arg1)
		float 	arg1
		CODE:
		THIS->SetAmplitude(arg1);
		XSRETURN_EMPTY;


void
vtkImageSinusoidSource::SetDirection(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDirection(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageSinusoidSource::SetDirection\n");



void
vtkImageSinusoidSource::SetPeriod(arg1)
		float 	arg1
		CODE:
		THIS->SetPeriod(arg1);
		XSRETURN_EMPTY;


void
vtkImageSinusoidSource::SetPhase(arg1)
		float 	arg1
		CODE:
		THIS->SetPhase(arg1);
		XSRETURN_EMPTY;


void
vtkImageSinusoidSource::SetWholeExtent(xMinx, xMax, yMin, yMax, zMin, zMax)
		int 	xMinx
		int 	xMax
		int 	yMin
		int 	yMax
		int 	zMin
		int 	zMax
		CODE:
		THIS->SetWholeExtent(xMinx, xMax, yMin, yMax, zMin, zMax);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageSkeleton2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageSkeleton2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageSkeleton2D::GetPrune()
		CODE:
		RETVAL = THIS->GetPrune();
		OUTPUT:
		RETVAL


void
vtkImageSkeleton2D::IterativeExecuteData(in, out)
		vtkImageData *	in
		vtkImageData *	out
		CODE:
		THIS->IterativeExecuteData(in, out);
		XSRETURN_EMPTY;


static vtkImageSkeleton2D*
vtkImageSkeleton2D::New()
		CODE:
		RETVAL = vtkImageSkeleton2D::New();
		OUTPUT:
		RETVAL


void
vtkImageSkeleton2D::PruneOff()
		CODE:
		THIS->PruneOff();
		XSRETURN_EMPTY;


void
vtkImageSkeleton2D::PruneOn()
		CODE:
		THIS->PruneOn();
		XSRETURN_EMPTY;


void
vtkImageSkeleton2D::SetNumberOfIterations(num)
		int 	num
		CODE:
		THIS->SetNumberOfIterations(num);
		XSRETURN_EMPTY;


void
vtkImageSkeleton2D::SetPrune(arg1)
		int 	arg1
		CODE:
		THIS->SetPrune(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageSobel2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageSobel2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageSobel2D*
vtkImageSobel2D::New()
		CODE:
		RETVAL = vtkImageSobel2D::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageSobel3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageSobel3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageSobel3D*
vtkImageSobel3D::New()
		CODE:
		RETVAL = vtkImageSobel3D::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageSpatialFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageSpatialFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int *
vtkImageSpatialFilter::GetKernelMiddle()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKernelMiddle();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int *
vtkImageSpatialFilter::GetKernelSize()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKernelSize();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImageSpatialFilter*
vtkImageSpatialFilter::New()
		CODE:
		RETVAL = vtkImageSpatialFilter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageStencil PREFIX = vtk

PROTOTYPES: DISABLE



float  *
vtkImageStencil::GetBackgroundColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBackgroundColor();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


vtkImageData *
vtkImageStencil::GetBackgroundInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetBackgroundInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkImageStencil::GetBackgroundValue()
		CODE:
		RETVAL = THIS->GetBackgroundValue();
		OUTPUT:
		RETVAL


const char *
vtkImageStencil::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageStencil::GetReverseStencil()
		CODE:
		RETVAL = THIS->GetReverseStencil();
		OUTPUT:
		RETVAL


vtkImageStencilData *
vtkImageStencil::GetStencil()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageStencilData";
		CODE:
		RETVAL = THIS->GetStencil();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageStencil*
vtkImageStencil::New()
		CODE:
		RETVAL = vtkImageStencil::New();
		OUTPUT:
		RETVAL


void
vtkImageStencil::ReverseStencilOff()
		CODE:
		THIS->ReverseStencilOff();
		XSRETURN_EMPTY;


void
vtkImageStencil::ReverseStencilOn()
		CODE:
		THIS->ReverseStencilOn();
		XSRETURN_EMPTY;


void
vtkImageStencil::SetBackgroundColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetBackgroundColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageStencil::SetBackgroundColor\n");



void
vtkImageStencil::SetBackgroundInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetBackgroundInput(input);
		XSRETURN_EMPTY;


void
vtkImageStencil::SetBackgroundValue(val)
		float 	val
		CODE:
		THIS->SetBackgroundValue(val);
		XSRETURN_EMPTY;


void
vtkImageStencil::SetReverseStencil(arg1)
		int 	arg1
		CODE:
		THIS->SetReverseStencil(arg1);
		XSRETURN_EMPTY;


void
vtkImageStencil::SetStencil(stencil)
		vtkImageStencilData *	stencil
		CODE:
		THIS->SetStencil(stencil);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageStencilData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageStencilData::AllocateExtents()
		CODE:
		THIS->AllocateExtents();
		XSRETURN_EMPTY;


void
vtkImageStencilData::DeepCopy(o)
		vtkDataObject *	o
		CODE:
		THIS->DeepCopy(o);
		XSRETURN_EMPTY;


const char *
vtkImageStencilData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageStencilData::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int  *
vtkImageStencilData::GetExtent()
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


int
vtkImageStencilData::GetExtentType()
		CODE:
		RETVAL = THIS->GetExtentType();
		OUTPUT:
		RETVAL


int
vtkImageStencilData::GetNextExtent(r1, r2, xMin, xMax, yIdx, zIdx, iter)
		int 	r1
		int 	r2
		int 	xMin
		int 	xMax
		int 	yIdx
		int 	zIdx
		int 	iter
		CODE:
		RETVAL = THIS->GetNextExtent(r1, r2, xMin, xMax, yIdx, zIdx, iter);
		OUTPUT:
		r1
		r2
		iter
		RETVAL


float  *
vtkImageStencilData::GetOldOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOldOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageStencilData::GetOldSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOldSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkImageStencilData::GetOrigin()
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
vtkImageStencilData::GetSpacing()
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


void
vtkImageStencilData::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkImageStencilData::InsertNextExtent(r1, r2, yIdx, zIdx)
		int 	r1
		int 	r2
		int 	yIdx
		int 	zIdx
		CODE:
		THIS->InsertNextExtent(r1, r2, yIdx, zIdx);
		XSRETURN_EMPTY;


void
vtkImageStencilData::InternalImageStencilDataCopy(s)
		vtkImageStencilData *	s
		CODE:
		THIS->InternalImageStencilDataCopy(s);
		XSRETURN_EMPTY;


static vtkImageStencilData*
vtkImageStencilData::New()
		CODE:
		RETVAL = vtkImageStencilData::New();
		OUTPUT:
		RETVAL


void
vtkImageStencilData::PropagateUpdateExtent()
		CODE:
		THIS->PropagateUpdateExtent();
		XSRETURN_EMPTY;


void
vtkImageStencilData::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkImageStencilData::SetExtent\n");



void
vtkImageStencilData::SetOldOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOldOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageStencilData::SetOldOrigin\n");



void
vtkImageStencilData::SetOldSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOldSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageStencilData::SetOldSpacing\n");



void
vtkImageStencilData::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageStencilData::SetOrigin\n");



void
vtkImageStencilData::SetSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageStencilData::SetSpacing\n");



void
vtkImageStencilData::ShallowCopy(f)
		vtkDataObject *	f
		CODE:
		THIS->ShallowCopy(f);
		XSRETURN_EMPTY;


void
vtkImageStencilData::TriggerAsynchronousUpdate()
		CODE:
		THIS->TriggerAsynchronousUpdate();
		XSRETURN_EMPTY;


void
vtkImageStencilData::UpdateData()
		CODE:
		THIS->UpdateData();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageStencilSource PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageStencilSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageStencilData *
vtkImageStencilSource::GetOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageStencilData";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageStencilSource*
vtkImageStencilSource::New()
		CODE:
		RETVAL = vtkImageStencilSource::New();
		OUTPUT:
		RETVAL


void
vtkImageStencilSource::SetOutput(output)
		vtkImageStencilData *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageThreshold PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageThreshold::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageThreshold::GetInValue()
		CODE:
		RETVAL = THIS->GetInValue();
		OUTPUT:
		RETVAL


float
vtkImageThreshold::GetLowerThreshold()
		CODE:
		RETVAL = THIS->GetLowerThreshold();
		OUTPUT:
		RETVAL


float
vtkImageThreshold::GetOutValue()
		CODE:
		RETVAL = THIS->GetOutValue();
		OUTPUT:
		RETVAL


int
vtkImageThreshold::GetOutputScalarType()
		CODE:
		RETVAL = THIS->GetOutputScalarType();
		OUTPUT:
		RETVAL


int
vtkImageThreshold::GetReplaceIn()
		CODE:
		RETVAL = THIS->GetReplaceIn();
		OUTPUT:
		RETVAL


int
vtkImageThreshold::GetReplaceOut()
		CODE:
		RETVAL = THIS->GetReplaceOut();
		OUTPUT:
		RETVAL


float
vtkImageThreshold::GetUpperThreshold()
		CODE:
		RETVAL = THIS->GetUpperThreshold();
		OUTPUT:
		RETVAL


static vtkImageThreshold*
vtkImageThreshold::New()
		CODE:
		RETVAL = vtkImageThreshold::New();
		OUTPUT:
		RETVAL


void
vtkImageThreshold::ReplaceInOff()
		CODE:
		THIS->ReplaceInOff();
		XSRETURN_EMPTY;


void
vtkImageThreshold::ReplaceInOn()
		CODE:
		THIS->ReplaceInOn();
		XSRETURN_EMPTY;


void
vtkImageThreshold::ReplaceOutOff()
		CODE:
		THIS->ReplaceOutOff();
		XSRETURN_EMPTY;


void
vtkImageThreshold::ReplaceOutOn()
		CODE:
		THIS->ReplaceOutOn();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetInValue(val)
		float 	val
		CODE:
		THIS->SetInValue(val);
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutValue(val)
		float 	val
		CODE:
		THIS->SetOutValue(val);
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetOutputScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToChar()
		CODE:
		THIS->SetOutputScalarTypeToChar();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToDouble()
		CODE:
		THIS->SetOutputScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToFloat()
		CODE:
		THIS->SetOutputScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToInt()
		CODE:
		THIS->SetOutputScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToLong()
		CODE:
		THIS->SetOutputScalarTypeToLong();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToShort()
		CODE:
		THIS->SetOutputScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToUnsignedChar()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToUnsignedInt()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedInt();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToUnsignedLong()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedLong();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetOutputScalarTypeToUnsignedShort()
		CODE:
		THIS->SetOutputScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetReplaceIn(arg1)
		int 	arg1
		CODE:
		THIS->SetReplaceIn(arg1);
		XSRETURN_EMPTY;


void
vtkImageThreshold::SetReplaceOut(arg1)
		int 	arg1
		CODE:
		THIS->SetReplaceOut(arg1);
		XSRETURN_EMPTY;


void
vtkImageThreshold::ThresholdBetween(lower, upper)
		float 	lower
		float 	upper
		CODE:
		THIS->ThresholdBetween(lower, upper);
		XSRETURN_EMPTY;


void
vtkImageThreshold::ThresholdByLower(thresh)
		float 	thresh
		CODE:
		THIS->ThresholdByLower(thresh);
		XSRETURN_EMPTY;


void
vtkImageThreshold::ThresholdByUpper(thresh)
		float 	thresh
		CODE:
		THIS->ThresholdByUpper(thresh);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageToImageStencil PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageToImageStencil::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageToImageStencil::GetInput()
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


float
vtkImageToImageStencil::GetLowerThreshold()
		CODE:
		RETVAL = THIS->GetLowerThreshold();
		OUTPUT:
		RETVAL


float
vtkImageToImageStencil::GetUpperThreshold()
		CODE:
		RETVAL = THIS->GetUpperThreshold();
		OUTPUT:
		RETVAL


static vtkImageToImageStencil*
vtkImageToImageStencil::New()
		CODE:
		RETVAL = vtkImageToImageStencil::New();
		OUTPUT:
		RETVAL


void
vtkImageToImageStencil::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkImageToImageStencil::SetLowerThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetLowerThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageToImageStencil::SetUpperThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetUpperThreshold(arg1);
		XSRETURN_EMPTY;


void
vtkImageToImageStencil::ThresholdBetween(lower, upper)
		float 	lower
		float 	upper
		CODE:
		THIS->ThresholdBetween(lower, upper);
		XSRETURN_EMPTY;


void
vtkImageToImageStencil::ThresholdByLower(thresh)
		float 	thresh
		CODE:
		THIS->ThresholdByLower(thresh);
		XSRETURN_EMPTY;


void
vtkImageToImageStencil::ThresholdByUpper(thresh)
		float 	thresh
		CODE:
		THIS->ThresholdByUpper(thresh);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageTranslateExtent PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageTranslateExtent::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkImageTranslateExtent::GetTranslation()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTranslation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkImageTranslateExtent*
vtkImageTranslateExtent::New()
		CODE:
		RETVAL = vtkImageTranslateExtent::New();
		OUTPUT:
		RETVAL


void
vtkImageTranslateExtent::SetTranslation(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetTranslation(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageTranslateExtent::SetTranslation\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageVariance3D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageVariance3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageVariance3D*
vtkImageVariance3D::New()
		CODE:
		RETVAL = vtkImageVariance3D::New();
		OUTPUT:
		RETVAL


void
vtkImageVariance3D::SetKernelSize(size0, size1, size2)
		int 	size0
		int 	size1
		int 	size2
		CODE:
		THIS->SetKernelSize(size0, size1, size2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImageWrapPad PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageWrapPad::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImageWrapPad*
vtkImageWrapPad::New()
		CODE:
		RETVAL = vtkImageWrapPad::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ImplicitFunctionToImageStencil PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImplicitFunctionToImageStencil::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkImplicitFunctionToImageStencil::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkImplicitFunctionToImageStencil::GetThreshold()
		CODE:
		RETVAL = THIS->GetThreshold();
		OUTPUT:
		RETVAL


static vtkImplicitFunctionToImageStencil*
vtkImplicitFunctionToImageStencil::New()
		CODE:
		RETVAL = vtkImplicitFunctionToImageStencil::New();
		OUTPUT:
		RETVAL


void
vtkImplicitFunctionToImageStencil::SetInput(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkImplicitFunctionToImageStencil::SetThreshold(arg1)
		float 	arg1
		CODE:
		THIS->SetThreshold(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::PointLoad PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPointLoad::ComputeEffectiveStressOff()
		CODE:
		THIS->ComputeEffectiveStressOff();
		XSRETURN_EMPTY;


void
vtkPointLoad::ComputeEffectiveStressOn()
		CODE:
		THIS->ComputeEffectiveStressOn();
		XSRETURN_EMPTY;


const char *
vtkPointLoad::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPointLoad::GetComputeEffectiveStress()
		CODE:
		RETVAL = THIS->GetComputeEffectiveStress();
		OUTPUT:
		RETVAL


float
vtkPointLoad::GetLoadValue()
		CODE:
		RETVAL = THIS->GetLoadValue();
		OUTPUT:
		RETVAL


float  *
vtkPointLoad::GetModelBounds()
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


float
vtkPointLoad::GetPoissonsRatio()
		CODE:
		RETVAL = THIS->GetPoissonsRatio();
		OUTPUT:
		RETVAL


int  *
vtkPointLoad::GetSampleDimensions()
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


static vtkPointLoad*
vtkPointLoad::New()
		CODE:
		RETVAL = vtkPointLoad::New();
		OUTPUT:
		RETVAL


void
vtkPointLoad::SetComputeEffectiveStress(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeEffectiveStress(arg1);
		XSRETURN_EMPTY;


void
vtkPointLoad::SetLoadValue(arg1)
		float 	arg1
		CODE:
		THIS->SetLoadValue(arg1);
		XSRETURN_EMPTY;


void
vtkPointLoad::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkPointLoad::SetModelBounds\n");



void
vtkPointLoad::SetPoissonsRatio(arg1)
		float 	arg1
		CODE:
		THIS->SetPoissonsRatio(arg1);
		XSRETURN_EMPTY;


void
vtkPointLoad::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLoad::SetSampleDimensions\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::SampleFunction PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSampleFunction::CappingOff()
		CODE:
		THIS->CappingOff();
		XSRETURN_EMPTY;


void
vtkSampleFunction::CappingOn()
		CODE:
		THIS->CappingOn();
		XSRETURN_EMPTY;


void
vtkSampleFunction::ComputeNormalsOff()
		CODE:
		THIS->ComputeNormalsOff();
		XSRETURN_EMPTY;


void
vtkSampleFunction::ComputeNormalsOn()
		CODE:
		THIS->ComputeNormalsOn();
		XSRETURN_EMPTY;


float
vtkSampleFunction::GetCapValue()
		CODE:
		RETVAL = THIS->GetCapValue();
		OUTPUT:
		RETVAL


int
vtkSampleFunction::GetCapping()
		CODE:
		RETVAL = THIS->GetCapping();
		OUTPUT:
		RETVAL


const char *
vtkSampleFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSampleFunction::GetComputeNormals()
		CODE:
		RETVAL = THIS->GetComputeNormals();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkSampleFunction::GetImplicitFunction()
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
vtkSampleFunction::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float  *
vtkSampleFunction::GetModelBounds()
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


int  *
vtkSampleFunction::GetSampleDimensions()
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


static vtkSampleFunction*
vtkSampleFunction::New()
		CODE:
		RETVAL = vtkSampleFunction::New();
		OUTPUT:
		RETVAL


void
vtkSampleFunction::SetCapValue(arg1)
		float 	arg1
		CODE:
		THIS->SetCapValue(arg1);
		XSRETURN_EMPTY;


void
vtkSampleFunction::SetCapping(arg1)
		int 	arg1
		CODE:
		THIS->SetCapping(arg1);
		XSRETURN_EMPTY;


void
vtkSampleFunction::SetComputeNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeNormals(arg1);
		XSRETURN_EMPTY;


void
vtkSampleFunction::SetImplicitFunction(arg1)
		vtkImplicitFunction *	arg1
		CODE:
		THIS->SetImplicitFunction(arg1);
		XSRETURN_EMPTY;


void
vtkSampleFunction::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkSampleFunction::SetModelBounds\n");



void
vtkSampleFunction::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSampleFunction::SetSampleDimensions\n");



void
vtkSampleFunction::SetScalars(arg1)
		vtkDataArray *	arg1
		CODE:
		THIS->SetScalars(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::ShepardMethod PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkShepardMethod::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkShepardMethod::GetMaximumDistance()
		CODE:
		RETVAL = THIS->GetMaximumDistance();
		OUTPUT:
		RETVAL


float
vtkShepardMethod::GetMaximumDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkShepardMethod::GetMaximumDistanceMinValue()
		CODE:
		RETVAL = THIS->GetMaximumDistanceMinValue();
		OUTPUT:
		RETVAL


float  *
vtkShepardMethod::GetModelBounds()
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


float
vtkShepardMethod::GetNullValue()
		CODE:
		RETVAL = THIS->GetNullValue();
		OUTPUT:
		RETVAL


int  *
vtkShepardMethod::GetSampleDimensions()
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


static vtkShepardMethod*
vtkShepardMethod::New()
		CODE:
		RETVAL = vtkShepardMethod::New();
		OUTPUT:
		RETVAL


void
vtkShepardMethod::SetMaximumDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumDistance(arg1);
		XSRETURN_EMPTY;


void
vtkShepardMethod::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkShepardMethod::SetModelBounds\n");



void
vtkShepardMethod::SetNullValue(arg1)
		float 	arg1
		CODE:
		THIS->SetNullValue(arg1);
		XSRETURN_EMPTY;


void
vtkShepardMethod::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkShepardMethod::SetSampleDimensions\n");


MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::SimpleImageFilterExample PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSimpleImageFilterExample::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkSimpleImageFilterExample*
vtkSimpleImageFilterExample::New()
		CODE:
		RETVAL = vtkSimpleImageFilterExample::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::SurfaceReconstructionFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSurfaceReconstructionFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSurfaceReconstructionFilter::GetNeighborhoodSize()
		CODE:
		RETVAL = THIS->GetNeighborhoodSize();
		OUTPUT:
		RETVAL


float
vtkSurfaceReconstructionFilter::GetSampleSpacing()
		CODE:
		RETVAL = THIS->GetSampleSpacing();
		OUTPUT:
		RETVAL


static vtkSurfaceReconstructionFilter*
vtkSurfaceReconstructionFilter::New()
		CODE:
		RETVAL = vtkSurfaceReconstructionFilter::New();
		OUTPUT:
		RETVAL


void
vtkSurfaceReconstructionFilter::SetNeighborhoodSize(arg1)
		int 	arg1
		CODE:
		THIS->SetNeighborhoodSize(arg1);
		XSRETURN_EMPTY;


void
vtkSurfaceReconstructionFilter::SetSampleSpacing(arg1)
		float 	arg1
		CODE:
		THIS->SetSampleSpacing(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::TriangularTexture PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTriangularTexture::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkTriangularTexture::GetScaleFactor()
		CODE:
		RETVAL = THIS->GetScaleFactor();
		OUTPUT:
		RETVAL


int
vtkTriangularTexture::GetTexturePattern()
		CODE:
		RETVAL = THIS->GetTexturePattern();
		OUTPUT:
		RETVAL


int
vtkTriangularTexture::GetTexturePatternMaxValue()
		CODE:
		RETVAL = THIS->GetTexturePatternMaxValue();
		OUTPUT:
		RETVAL


int
vtkTriangularTexture::GetTexturePatternMinValue()
		CODE:
		RETVAL = THIS->GetTexturePatternMinValue();
		OUTPUT:
		RETVAL


int
vtkTriangularTexture::GetXSize()
		CODE:
		RETVAL = THIS->GetXSize();
		OUTPUT:
		RETVAL


int
vtkTriangularTexture::GetYSize()
		CODE:
		RETVAL = THIS->GetYSize();
		OUTPUT:
		RETVAL


static vtkTriangularTexture*
vtkTriangularTexture::New()
		CODE:
		RETVAL = vtkTriangularTexture::New();
		OUTPUT:
		RETVAL


void
vtkTriangularTexture::SetScaleFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetScaleFactor(arg1);
		XSRETURN_EMPTY;


void
vtkTriangularTexture::SetTexturePattern(arg1)
		int 	arg1
		CODE:
		THIS->SetTexturePattern(arg1);
		XSRETURN_EMPTY;


void
vtkTriangularTexture::SetXSize(arg1)
		int 	arg1
		CODE:
		THIS->SetXSize(arg1);
		XSRETURN_EMPTY;


void
vtkTriangularTexture::SetYSize(arg1)
		int 	arg1
		CODE:
		THIS->SetYSize(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::VoxelModeller PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVoxelModeller::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkVoxelModeller::GetMaximumDistance()
		CODE:
		RETVAL = THIS->GetMaximumDistance();
		OUTPUT:
		RETVAL


float
vtkVoxelModeller::GetMaximumDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkVoxelModeller::GetMaximumDistanceMinValue()
		CODE:
		RETVAL = THIS->GetMaximumDistanceMinValue();
		OUTPUT:
		RETVAL


float  *
vtkVoxelModeller::GetModelBounds()
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


int  *
vtkVoxelModeller::GetSampleDimensions()
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


static vtkVoxelModeller*
vtkVoxelModeller::New()
		CODE:
		RETVAL = vtkVoxelModeller::New();
		OUTPUT:
		RETVAL


void
vtkVoxelModeller::SetMaximumDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumDistance(arg1);
		XSRETURN_EMPTY;


void
vtkVoxelModeller::SetModelBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
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
		croak("Unsupported number of args and/or types supplied to vtkVoxelModeller::SetModelBounds\n");



void
vtkVoxelModeller::SetSampleDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetSampleDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVoxelModeller::SetSampleDimensions\n");



void
vtkVoxelModeller::Write(arg1)
		char *	arg1
		CODE:
		THIS->Write(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Imaging	PACKAGE = Graphics::VTK::WindowToImageFilter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWindowToImageFilter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkWindow *
vtkWindowToImageFilter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkWindow";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkWindowToImageFilter*
vtkWindowToImageFilter::New()
		CODE:
		RETVAL = vtkWindowToImageFilter::New();
		OUTPUT:
		RETVAL


void
vtkWindowToImageFilter::SetInput(input)
		vtkWindow *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


