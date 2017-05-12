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
#include "vtkOpenGLRenderWindow.h"
#include "vtkAbstractMapper3D.h"
#include "vtkAbstractPicker.h"
#include "vtkAbstractPropPicker.h"
#include "vtkActor.h"
#include "vtkActorCollection.h"
#include "vtkAssembly.h"
#include "vtkAxisActor2D.h"
#include "vtkCamera.h"
#include "vtkCellPicker.h"
#include "vtkCuller.h"
#include "vtkCullerCollection.h"
#include "vtkDataSetMapper.h"
#include "vtkDirectionEncoder.h"
#include "vtkEncodedGradientEstimator.h"
#include "vtkEncodedGradientShader.h"
#include "vtkExporter.h"
#include "vtkFiniteDifferenceGradientEstimator.h"
#include "vtkFollower.h"
#include "vtkFrustumCoverageCuller.h"
#include "vtkGraphicsFactory.h"
#include "vtkIVExporter.h"
#include "vtkImageActor.h"
#include "vtkImageMapper.h"
#include "vtkImageViewer.h"
#include "vtkImageViewer2.h"
#include "vtkImageWindow.h"
#include "vtkImager.h"
#include "vtkImagerCollection.h"
#include "vtkImagingFactory.h"
#include "vtkImporter.h"
#include "vtkInteractorStyle.h"
#include "vtkInteractorStyleFlight.h"
#include "vtkInteractorStyleImage.h"
#include "vtkInteractorStyleJoystickActor.h"
#include "vtkInteractorStyleJoystickCamera.h"
#include "vtkInteractorStyleSwitch.h"
#include "vtkInteractorStyleTrackball.h"
#include "vtkInteractorStyleTrackballActor.h"
#include "vtkInteractorStyleTrackballCamera.h"
#include "vtkInteractorStyleUnicam.h"
#include "vtkInteractorStyleUser.h"
#include "vtkLODActor.h"
#include "vtkLODProp3D.h"
#include "vtkLabeledDataMapper.h"
#include "vtkLight.h"
#include "vtkLightCollection.h"
#include "vtkLightKit.h"
#include "vtkMapper.h"
#include "vtkMapperCollection.h"
#include "vtkOBJExporter.h"
#include "vtkOOGLExporter.h"
#include "vtkParallelCoordinatesActor.h"
#include "vtkPicker.h"
#include "vtkPointPicker.h"
#include "vtkPolyDataMapper.h"
#include "vtkPolyDataMapper2D.h"
#include "vtkProp3D.h"
#include "vtkProp3DCollection.h"
#include "vtkPropPicker.h"
#include "vtkProperty.h"
#include "vtkRayCaster.h"
#include "vtkRecursiveSphereDirectionEncoder.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowCollection.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkRenderer.h"
#include "vtkRendererCollection.h"
#include "vtkRendererSource.h"
#include "vtkScalarBarActor.h"
#include "vtkScaledTextActor.h"
#include "vtkSelectVisiblePoints.h"
#include "vtkTextMapper.h"
#include "vtkTexture.h"
#include "vtkVRMLExporter.h"
#include "vtkVolume.h"
#include "vtkVolumeCollection.h"
#include "vtkVolumeMapper.h"
#include "vtkVolumeProMapper.h"
#include "vtkVolumeProperty.h"
#include "vtkVolumeRayCastCompositeFunction.h"
#include "vtkVolumeRayCastFunction.h"
#include "vtkVolumeRayCastIsosurfaceFunction.h"
#include "vtkVolumeRayCastMIPFunction.h"
#include "vtkVolumeRayCastMapper.h"
#include "vtkVolumeTextureMapper.h"
#include "vtkVolumeTextureMapper2D.h"
#include "vtkWorldPointPicker.h"
#ifdef USE_MESA
#include "vtkMesaActor.h"
#include "vtkMesaCamera.h"
#include "vtkMesaImageActor.h"
#include "vtkMesaImageMapper.h"
#include "vtkMesaImageWindow.h"
#include "vtkMesaImager.h"
#include "vtkMesaLight.h"
#include "vtkMesaPolyDataMapper.h"
#include "vtkMesaPolyDataMapper2D.h"
#include "vtkMesaProperty.h"
#include "vtkMesaRenderWindow.h"
#include "vtkMesaRenderer.h"
#include "vtkMesaTexture.h"
#include "vtkMesaVolumeRayCastMapper.h"
#include "vtkMesaVolumeTextureMapper2D.h"
#include "vtkXMesaRenderWindow.h"
#include "vtkXMesaTextMapper.h"
#endif
#ifndef USE_MESA
#include "vtkOpenGLActor.h"
#include "vtkOpenGLCamera.h"
#include "vtkOpenGLImageActor.h"
#include "vtkOpenGLImageMapper.h"
#include "vtkOpenGLImager.h"
#include "vtkOpenGLLight.h"
#include "vtkOpenGLPolyDataMapper.h"
#include "vtkOpenGLPolyDataMapper2D.h"
#include "vtkOpenGLProperty.h"
#include "vtkOpenGLRenderer.h"
#include "vtkOpenGLTexture.h"
#include "vtkOpenGLVolumeRayCastMapper.h"
#include "vtkOpenGLVolumeTextureMapper2D.h"
#endif
#ifndef WIN32
#include "vtkOpenGLImageWindow.h"
#include "vtkXImageWindow.h"
#include "vtkXOpenGLRenderWindow.h"
#include "vtkXOpenGLTextMapper.h"
#include "vtkXRenderWindowInteractor.h"
#include "vtkXTextMapper.h"
#endif
#ifdef WIN32
#include "vtkWin32OpenGLImageWindow.h"
#include "vtkWin32OpenGLRenderWindow.h"
#include "vtkWin32OpenGLTextMapper.h"
#include "vtkWin32RenderWindowInteractor.h"
#include "vtkWin32TextMapper.h"
#endif
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

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLRenderWindow PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLRenderWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkOpenGLRenderWindow::GetDepthBufferSize()
		CODE:
		RETVAL = THIS->GetDepthBufferSize();
		OUTPUT:
		RETVAL


static int
vtkOpenGLRenderWindow::GetGlobalMaximumNumberOfMultiSamples()
		CODE:
		RETVAL = vtkOpenGLRenderWindow::GetGlobalMaximumNumberOfMultiSamples();
		OUTPUT:
		RETVAL


int
vtkOpenGLRenderWindow::GetMultiSamples()
		CODE:
		RETVAL = THIS->GetMultiSamples();
		OUTPUT:
		RETVAL


void
vtkOpenGLRenderWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


void
vtkOpenGLRenderWindow::OpenGLInit()
		CODE:
		THIS->OpenGLInit();
		XSRETURN_EMPTY;


void
vtkOpenGLRenderWindow::RegisterTextureResource(id)
		GLuint 	id
		CODE:
		THIS->RegisterTextureResource(id);
		XSRETURN_EMPTY;


static void
vtkOpenGLRenderWindow::SetGlobalMaximumNumberOfMultiSamples(val)
		int 	val
		CODE:
		vtkOpenGLRenderWindow::SetGlobalMaximumNumberOfMultiSamples(val);
		XSRETURN_EMPTY;


void
vtkOpenGLRenderWindow::SetMultiSamples(arg1)
		int 	arg1
		CODE:
		THIS->SetMultiSamples(arg1);
		XSRETURN_EMPTY;


void
vtkOpenGLRenderWindow::StereoUpdate()
		CODE:
		THIS->StereoUpdate();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::AbstractMapper3D PREFIX = vtk

PROTOTYPES: DISABLE



float *
vtkAbstractMapper3D::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkAbstractMapper3D::GetBounds\n");



float *
vtkAbstractMapper3D::GetCenter()
		PREINIT:
		float * retval;
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
vtkAbstractMapper3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkAbstractMapper3D::GetLength()
		CODE:
		RETVAL = THIS->GetLength();
		OUTPUT:
		RETVAL


int
vtkAbstractMapper3D::IsARayCastMapper()
		CODE:
		RETVAL = THIS->IsARayCastMapper();
		OUTPUT:
		RETVAL


int
vtkAbstractMapper3D::IsARenderIntoImageMapper()
		CODE:
		RETVAL = THIS->IsARenderIntoImageMapper();
		OUTPUT:
		RETVAL


void
vtkAbstractMapper3D::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::AbstractPicker PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAbstractPicker::AddPickList(arg1)
		vtkProp *	arg1
		CODE:
		THIS->AddPickList(arg1);
		XSRETURN_EMPTY;


void
vtkAbstractPicker::DeletePickList(arg1)
		vtkProp *	arg1
		CODE:
		THIS->DeletePickList(arg1);
		XSRETURN_EMPTY;


const char *
vtkAbstractPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkAbstractPicker::GetPickFromList()
		CODE:
		RETVAL = THIS->GetPickFromList();
		OUTPUT:
		RETVAL


vtkPropCollection *
vtkAbstractPicker::GetPickList()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPropCollection";
		CODE:
		RETVAL = THIS->GetPickList();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkAbstractPicker::GetPickPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPickPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkRenderer *
vtkAbstractPicker::GetRenderer()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetRenderer();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkAbstractPicker::GetSelectionPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSelectionPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


void
vtkAbstractPicker::InitializePickList()
		CODE:
		THIS->InitializePickList();
		XSRETURN_EMPTY;


int
vtkAbstractPicker::Pick(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		vtkRenderer *	arg4
		CODE:
		RETVAL = THIS->Pick(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAbstractPicker::Pick\n");



void
vtkAbstractPicker::PickFromListOff()
		CODE:
		THIS->PickFromListOff();
		XSRETURN_EMPTY;


void
vtkAbstractPicker::PickFromListOn()
		CODE:
		THIS->PickFromListOn();
		XSRETURN_EMPTY;


void
vtkAbstractPicker::SetEndPickMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetEndPickMethod",0), newRV(func), 0);
		}
		THIS->SetEndPickMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkAbstractPicker::SetPickFromList(arg1)
		int 	arg1
		CODE:
		THIS->SetPickFromList(arg1);
		XSRETURN_EMPTY;


void
vtkAbstractPicker::SetPickMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetPickMethod",0), newRV(func), 0);
		}
		THIS->SetPickMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkAbstractPicker::SetStartPickMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetStartPickMethod",0), newRV(func), 0);
		}
		THIS->SetStartPickMethod(callperlsub, func);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::AbstractPropPicker PREFIX = vtk

PROTOTYPES: DISABLE



vtkActor *
vtkAbstractPropPicker::GetActor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor";
		CODE:
		RETVAL = THIS->GetActor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor2D *
vtkAbstractPropPicker::GetActor2D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2D";
		CODE:
		RETVAL = THIS->GetActor2D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAssembly *
vtkAbstractPropPicker::GetAssembly()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssembly";
		CODE:
		RETVAL = THIS->GetAssembly();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkAbstractPropPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkAbstractPropPicker::GetPath()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->GetPath();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkProp *
vtkAbstractPropPicker::GetProp()
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


vtkProp3D *
vtkAbstractPropPicker::GetProp3D()
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


vtkPropAssembly *
vtkAbstractPropPicker::GetPropAssembly()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPropAssembly";
		CODE:
		RETVAL = THIS->GetPropAssembly();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkVolume *
vtkAbstractPropPicker::GetVolume()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolume";
		CODE:
		RETVAL = THIS->GetVolume();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkAbstractPropPicker::SetPath(arg1)
		vtkAssemblyPath *	arg1
		CODE:
		THIS->SetPath(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Actor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkActor::ApplyProperties()
		CODE:
		THIS->ApplyProperties();
		XSRETURN_EMPTY;


void
vtkActor::GetActors(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetActors(arg1);
		XSRETURN_EMPTY;


vtkProperty *
vtkActor::GetBackfaceProperty()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProperty";
		CODE:
		RETVAL = THIS->GetBackfaceProperty();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkActor::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkActor::GetBounds\n");



const char *
vtkActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkActor::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkMapper *
vtkActor::GetMapper()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMapper";
		CODE:
		RETVAL = THIS->GetMapper();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor *
vtkActor::GetNextPart()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor";
		CODE:
		RETVAL = THIS->GetNextPart();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkActor::GetNumberOfParts()
		CODE:
		RETVAL = THIS->GetNumberOfParts();
		OUTPUT:
		RETVAL


vtkProperty *
vtkActor::GetProperty()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProperty";
		CODE:
		RETVAL = THIS->GetProperty();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkActor::GetRedrawMTime()
		CODE:
		RETVAL = THIS->GetRedrawMTime();
		OUTPUT:
		RETVAL


vtkTexture *
vtkActor::GetTexture()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkTexture";
		CODE:
		RETVAL = THIS->GetTexture();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkActor::InitPartTraversal()
		CODE:
		THIS->InitPartTraversal();
		XSRETURN_EMPTY;


vtkProperty *
vtkActor::MakeProperty()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProperty";
		CODE:
		RETVAL = THIS->MakeProperty();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkActor*
vtkActor::New()
		CODE:
		RETVAL = vtkActor::New();
		OUTPUT:
		RETVAL


void
vtkActor::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkActor::Render(arg1, arg2)
		vtkRenderer *	arg1
		vtkMapper *	arg2
		CODE:
		THIS->Render(arg1, arg2);
		XSRETURN_EMPTY;


int
vtkActor::RenderOpaqueGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(viewport);
		OUTPUT:
		RETVAL


int
vtkActor::RenderTranslucentGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(viewport);
		OUTPUT:
		RETVAL


void
vtkActor::SetBackfaceProperty(lut)
		vtkProperty *	lut
		CODE:
		THIS->SetBackfaceProperty(lut);
		XSRETURN_EMPTY;


void
vtkActor::SetMapper(arg1)
		vtkMapper *	arg1
		CODE:
		THIS->SetMapper(arg1);
		XSRETURN_EMPTY;


void
vtkActor::SetProperty(lut)
		vtkProperty *	lut
		CODE:
		THIS->SetProperty(lut);
		XSRETURN_EMPTY;


void
vtkActor::SetTexture(arg1)
		vtkTexture *	arg1
		CODE:
		THIS->SetTexture(arg1);
		XSRETURN_EMPTY;


void
vtkActor::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ActorCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkActorCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkActor *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkActorCollection::AddItem\n");



void
vtkActorCollection::ApplyProperties(p)
		vtkProperty *	p
		CODE:
		THIS->ApplyProperties(p);
		XSRETURN_EMPTY;


const char *
vtkActorCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkActor *
vtkActorCollection::GetLastActor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor";
		CODE:
		RETVAL = THIS->GetLastActor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor *
vtkActorCollection::GetLastItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor";
		CODE:
		RETVAL = THIS->GetLastItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor *
vtkActorCollection::GetNextActor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor";
		CODE:
		RETVAL = THIS->GetNextActor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor *
vtkActorCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkActorCollection*
vtkActorCollection::New()
		CODE:
		RETVAL = vtkActorCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Assembly PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAssembly::AddPart(arg1)
		vtkProp3D *	arg1
		CODE:
		THIS->AddPart(arg1);
		XSRETURN_EMPTY;


void
vtkAssembly::GetActors(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetActors(arg1);
		XSRETURN_EMPTY;


float *
vtkAssembly::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkAssembly::GetBounds\n");



const char *
vtkAssembly::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkAssembly::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkAssembly::GetNextPath()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->GetNextPath();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkAssembly::GetNumberOfPaths()
		CODE:
		RETVAL = THIS->GetNumberOfPaths();
		OUTPUT:
		RETVAL


vtkProp3DCollection *
vtkAssembly::GetParts()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp3DCollection";
		CODE:
		RETVAL = THIS->GetParts();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkAssembly::GetVolumes(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetVolumes(arg1);
		XSRETURN_EMPTY;


void
vtkAssembly::InitPathTraversal()
		CODE:
		THIS->InitPathTraversal();
		XSRETURN_EMPTY;


static vtkAssembly*
vtkAssembly::New()
		CODE:
		RETVAL = vtkAssembly::New();
		OUTPUT:
		RETVAL


void
vtkAssembly::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkAssembly::RemovePart(arg1)
		vtkProp3D *	arg1
		CODE:
		THIS->RemovePart(arg1);
		XSRETURN_EMPTY;


int
vtkAssembly::RenderOpaqueGeometry(ren)
		vtkViewport *	ren
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(ren);
		OUTPUT:
		RETVAL


int
vtkAssembly::RenderTranslucentGeometry(ren)
		vtkViewport *	ren
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(ren);
		OUTPUT:
		RETVAL


void
vtkAssembly::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::AxisActor2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAxisActor2D::AdjustLabelsOff()
		CODE:
		THIS->AdjustLabelsOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::AdjustLabelsOn()
		CODE:
		THIS->AdjustLabelsOn();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::AxisVisibilityOff()
		CODE:
		THIS->AxisVisibilityOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::AxisVisibilityOn()
		CODE:
		THIS->AxisVisibilityOn();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


int
vtkAxisActor2D::GetAdjustLabels()
		CODE:
		RETVAL = THIS->GetAdjustLabels();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetAxisVisibility()
		CODE:
		RETVAL = THIS->GetAxisVisibility();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


const char *
vtkAxisActor2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkAxisActor2D::GetFontFactor()
		CODE:
		RETVAL = THIS->GetFontFactor();
		OUTPUT:
		RETVAL


float
vtkAxisActor2D::GetFontFactorMaxValue()
		CODE:
		RETVAL = THIS->GetFontFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkAxisActor2D::GetFontFactorMinValue()
		CODE:
		RETVAL = THIS->GetFontFactorMinValue();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


float
vtkAxisActor2D::GetLabelFactor()
		CODE:
		RETVAL = THIS->GetLabelFactor();
		OUTPUT:
		RETVAL


float
vtkAxisActor2D::GetLabelFactorMaxValue()
		CODE:
		RETVAL = THIS->GetLabelFactorMaxValue();
		OUTPUT:
		RETVAL


float
vtkAxisActor2D::GetLabelFactorMinValue()
		CODE:
		RETVAL = THIS->GetLabelFactorMinValue();
		OUTPUT:
		RETVAL


char *
vtkAxisActor2D::GetLabelFormat()
		CODE:
		RETVAL = THIS->GetLabelFormat();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetLabelVisibility()
		CODE:
		RETVAL = THIS->GetLabelVisibility();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetNumberOfLabels()
		CODE:
		RETVAL = THIS->GetNumberOfLabels();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetNumberOfLabelsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMaxValue();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetNumberOfLabelsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMinValue();
		OUTPUT:
		RETVAL


float *
vtkAxisActor2D::GetPoint1()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint1();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


vtkCoordinate *
vtkAxisActor2D::GetPoint1Coordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetPoint1Coordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkAxisActor2D::GetPoint2()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint2();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


vtkCoordinate *
vtkAxisActor2D::GetPoint2Coordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetPoint2Coordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkAxisActor2D::GetRange()
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


int
vtkAxisActor2D::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickLength()
		CODE:
		RETVAL = THIS->GetTickLength();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickLengthMaxValue()
		CODE:
		RETVAL = THIS->GetTickLengthMaxValue();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickLengthMinValue()
		CODE:
		RETVAL = THIS->GetTickLengthMinValue();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickOffset()
		CODE:
		RETVAL = THIS->GetTickOffset();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickOffsetMaxValue()
		CODE:
		RETVAL = THIS->GetTickOffsetMaxValue();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickOffsetMinValue()
		CODE:
		RETVAL = THIS->GetTickOffsetMinValue();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTickVisibility()
		CODE:
		RETVAL = THIS->GetTickVisibility();
		OUTPUT:
		RETVAL


char *
vtkAxisActor2D::GetTitle()
		CODE:
		RETVAL = THIS->GetTitle();
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::GetTitleVisibility()
		CODE:
		RETVAL = THIS->GetTitleVisibility();
		OUTPUT:
		RETVAL


void
vtkAxisActor2D::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::LabelVisibilityOff()
		CODE:
		THIS->LabelVisibilityOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::LabelVisibilityOn()
		CODE:
		THIS->LabelVisibilityOn();
		XSRETURN_EMPTY;


static vtkAxisActor2D*
vtkAxisActor2D::New()
		CODE:
		RETVAL = vtkAxisActor2D::New();
		OUTPUT:
		RETVAL


void
vtkAxisActor2D::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


int
vtkAxisActor2D::RenderOpaqueGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(viewport);
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::RenderOverlay(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOverlay(viewport);
		OUTPUT:
		RETVAL


int
vtkAxisActor2D::RenderTranslucentGeometry(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(arg1);
		OUTPUT:
		RETVAL


void
vtkAxisActor2D::SetAdjustLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetAdjustLabels(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetAxisVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetAxisVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetFontFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetFontFactor(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetLabelFactor(arg1)
		float 	arg1
		CODE:
		THIS->SetLabelFactor(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetLabelFormat(arg1)
		char *	arg1
		CODE:
		THIS->SetLabelFormat(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetLabelVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetLabelVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetNumberOfLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfLabels(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetPoint1(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float	arg1
		float	arg2
		CODE:
		THIS->SetPoint1(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAxisActor2D::SetPoint1\n");



void
vtkAxisActor2D::SetPoint2(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float	arg1
		float	arg2
		CODE:
		THIS->SetPoint2(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAxisActor2D::SetPoint2\n");



void
vtkAxisActor2D::SetRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAxisActor2D::SetRange\n");



void
vtkAxisActor2D::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetTickLength(arg1)
		int 	arg1
		CODE:
		THIS->SetTickLength(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetTickOffset(arg1)
		int 	arg1
		CODE:
		THIS->SetTickOffset(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetTickVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetTickVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetTitle(arg1)
		char *	arg1
		CODE:
		THIS->SetTitle(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::SetTitleVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetTitleVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;


void
vtkAxisActor2D::TickVisibilityOff()
		CODE:
		THIS->TickVisibilityOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::TickVisibilityOn()
		CODE:
		THIS->TickVisibilityOn();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::TitleVisibilityOff()
		CODE:
		THIS->TitleVisibilityOff();
		XSRETURN_EMPTY;


void
vtkAxisActor2D::TitleVisibilityOn()
		CODE:
		THIS->TitleVisibilityOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Camera PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCamera::Azimuth(angle)
		double 	angle
		CODE:
		THIS->Azimuth(angle);
		XSRETURN_EMPTY;


void
vtkCamera::ComputeViewPlaneNormal()
		CODE:
		THIS->ComputeViewPlaneNormal();
		XSRETURN_EMPTY;


void
vtkCamera::Dolly(distance)
		double 	distance
		CODE:
		THIS->Dolly(distance);
		XSRETURN_EMPTY;


void
vtkCamera::Elevation(angle)
		double 	angle
		CODE:
		THIS->Elevation(angle);
		XSRETURN_EMPTY;


vtkMatrix4x4 *
vtkCamera::GetCameraLightTransformMatrix()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetCameraLightTransformMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkCamera::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetClippingRange()
	CASE: items == 1
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetClippingRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::GetClippingRange\n");



vtkMatrix4x4  *
vtkCamera::GetCompositePerspectiveTransform(aspect, nearz, farz)
		double 	aspect
		double 	nearz
		double 	farz
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = &(THIS)->GetCompositePerspectiveTransform(aspect, nearz, farz);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkCamera::GetCompositePerspectiveTransformMatrix(aspect, nearz, farz)
		double 	aspect
		double 	nearz
		double 	farz
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetCompositePerspectiveTransformMatrix(aspect, nearz, farz);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetDirectionOfProjection()
	CASE: items == 1
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDirectionOfProjection();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::GetDirectionOfProjection\n");



double
vtkCamera::GetDistance()
		CODE:
		RETVAL = THIS->GetDistance();
		OUTPUT:
		RETVAL


double
vtkCamera::GetEyeAngle()
		CODE:
		RETVAL = THIS->GetEyeAngle();
		OUTPUT:
		RETVAL


double
vtkCamera::GetFocalDisk()
		CODE:
		RETVAL = THIS->GetFocalDisk();
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetFocalPoint()
	CASE: items == 1
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFocalPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::GetFocalPoint\n");



float *
vtkCamera::GetOrientation()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float *
vtkCamera::GetOrientationWXYZ()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientationWXYZ();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


int
vtkCamera::GetParallelProjection()
		CODE:
		RETVAL = THIS->GetParallelProjection();
		OUTPUT:
		RETVAL


double
vtkCamera::GetParallelScale()
		CODE:
		RETVAL = THIS->GetParallelScale();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkCamera::GetPerspectiveTransformMatrix(aspect, nearz, farz)
		double 	aspect
		double 	nearz
		double 	farz
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetPerspectiveTransformMatrix(aspect, nearz, farz);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetPosition()
	CASE: items == 1
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::GetPosition\n");



double
vtkCamera::GetRoll()
		CODE:
		RETVAL = THIS->GetRoll();
		OUTPUT:
		RETVAL


double
vtkCamera::GetThickness()
		CODE:
		RETVAL = THIS->GetThickness();
		OUTPUT:
		RETVAL


double
vtkCamera::GetViewAngle()
		CODE:
		RETVAL = THIS->GetViewAngle();
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetViewPlaneNormal()
	CASE: items == 1
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetViewPlaneNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::GetViewPlaneNormal\n");



double  *
vtkCamera::GetViewShear()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetViewShear();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkMatrix4x4 *
vtkCamera::GetViewTransformMatrix()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetViewTransformMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkTransform *
vtkCamera::GetViewTransformObject()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkTransform";
		CODE:
		RETVAL = THIS->GetViewTransformObject();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetViewUp()
	CASE: items == 1
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetViewUp();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::GetViewUp\n");



unsigned long
vtkCamera::GetViewingRaysMTime()
		CODE:
		RETVAL = THIS->GetViewingRaysMTime();
		OUTPUT:
		RETVAL


double  *
vtkCamera::GetWindowCenter()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWindowCenter();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkCamera*
vtkCamera::New()
		CODE:
		RETVAL = vtkCamera::New();
		OUTPUT:
		RETVAL


void
vtkCamera::OrthogonalizeViewUp()
		CODE:
		THIS->OrthogonalizeViewUp();
		XSRETURN_EMPTY;


void
vtkCamera::ParallelProjectionOff()
		CODE:
		THIS->ParallelProjectionOff();
		XSRETURN_EMPTY;


void
vtkCamera::ParallelProjectionOn()
		CODE:
		THIS->ParallelProjectionOn();
		XSRETURN_EMPTY;


void
vtkCamera::Pitch(angle)
		double 	angle
		CODE:
		THIS->Pitch(angle);
		XSRETURN_EMPTY;


void
vtkCamera::Render(arg1)
		vtkRenderer *	arg1
		CODE:
		THIS->Render(arg1);
		XSRETURN_EMPTY;


void
vtkCamera::Roll(angle)
		double 	angle
		CODE:
		THIS->Roll(angle);
		XSRETURN_EMPTY;


void
vtkCamera::SetClippingRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		double 	arg1
		double 	arg2
		CODE:
		THIS->SetClippingRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::SetClippingRange\n");



void
vtkCamera::SetDistance(arg1)
		double 	arg1
		CODE:
		THIS->SetDistance(arg1);
		XSRETURN_EMPTY;


void
vtkCamera::SetEyeAngle(arg1)
		double 	arg1
		CODE:
		THIS->SetEyeAngle(arg1);
		XSRETURN_EMPTY;


void
vtkCamera::SetFocalDisk(arg1)
		double 	arg1
		CODE:
		THIS->SetFocalDisk(arg1);
		XSRETURN_EMPTY;


void
vtkCamera::SetFocalPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetFocalPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::SetFocalPoint\n");



void
vtkCamera::SetObliqueAngles(alpha, beta)
		double 	alpha
		double 	beta
		CODE:
		THIS->SetObliqueAngles(alpha, beta);
		XSRETURN_EMPTY;


void
vtkCamera::SetParallelProjection(flag)
		int 	flag
		CODE:
		THIS->SetParallelProjection(flag);
		XSRETURN_EMPTY;


void
vtkCamera::SetParallelScale(scale)
		double 	scale
		CODE:
		THIS->SetParallelScale(scale);
		XSRETURN_EMPTY;


void
vtkCamera::SetPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::SetPosition\n");



void
vtkCamera::SetRoll(angle)
		double 	angle
		CODE:
		THIS->SetRoll(angle);
		XSRETURN_EMPTY;


void
vtkCamera::SetThickness(arg1)
		double 	arg1
		CODE:
		THIS->SetThickness(arg1);
		XSRETURN_EMPTY;


void
vtkCamera::SetViewAngle(angle)
		double 	angle
		CODE:
		THIS->SetViewAngle(angle);
		XSRETURN_EMPTY;


void
vtkCamera::SetViewPlaneNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetViewPlaneNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::SetViewPlaneNormal\n");



void
vtkCamera::SetViewShear(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetViewShear(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::SetViewShear\n");



void
vtkCamera::SetViewUp(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetViewUp(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCamera::SetViewUp\n");



void
vtkCamera::SetWindowCenter(x, y)
		double 	x
		double 	y
		CODE:
		THIS->SetWindowCenter(x, y);
		XSRETURN_EMPTY;


void
vtkCamera::ViewingRaysModified()
		CODE:
		THIS->ViewingRaysModified();
		XSRETURN_EMPTY;


void
vtkCamera::Yaw(angle)
		double 	angle
		CODE:
		THIS->Yaw(angle);
		XSRETURN_EMPTY;


void
vtkCamera::Zoom(factor)
		double 	factor
		CODE:
		THIS->Zoom(factor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::CellPicker PREFIX = vtk

PROTOTYPES: DISABLE



long
vtkCellPicker::GetCellId()
		CODE:
		RETVAL = THIS->GetCellId();
		OUTPUT:
		RETVAL


const char *
vtkCellPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkCellPicker::GetPCoords()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPCoords();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkCellPicker::GetSubId()
		CODE:
		RETVAL = THIS->GetSubId();
		OUTPUT:
		RETVAL


static vtkCellPicker*
vtkCellPicker::New()
		CODE:
		RETVAL = vtkCellPicker::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Culler PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCuller::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::CullerCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCullerCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkCuller *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCullerCollection::AddItem\n");



const char *
vtkCullerCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCuller *
vtkCullerCollection::GetLastItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCuller";
		CODE:
		RETVAL = THIS->GetLastItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCuller *
vtkCullerCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCuller";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkCullerCollection*
vtkCullerCollection::New()
		CODE:
		RETVAL = vtkCullerCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::DataSetMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetMapper::GetInput()
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


unsigned long
vtkDataSetMapper::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkPolyDataMapper *
vtkDataSetMapper::GetPolyDataMapper()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyDataMapper";
		CODE:
		RETVAL = THIS->GetPolyDataMapper();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDataSetMapper*
vtkDataSetMapper::New()
		CODE:
		RETVAL = vtkDataSetMapper::New();
		OUTPUT:
		RETVAL


void
vtkDataSetMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkDataSetMapper::Render(ren, act)
		vtkRenderer *	ren
		vtkActor *	act
		CODE:
		THIS->Render(ren, act);
		XSRETURN_EMPTY;


void
vtkDataSetMapper::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::DirectionEncoder PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDirectionEncoder::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL



int
vtkDirectionEncoder::GetNumberOfEncodedDirections()
		CODE:
		RETVAL = THIS->GetNumberOfEncodedDirections();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::EncodedGradientEstimator PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkEncodedGradientEstimator::BoundsClipOff()
		CODE:
		THIS->BoundsClipOff();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::BoundsClipOn()
		CODE:
		THIS->BoundsClipOn();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::ComputeGradientMagnitudesOff()
		CODE:
		THIS->ComputeGradientMagnitudesOff();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::ComputeGradientMagnitudesOn()
		CODE:
		THIS->ComputeGradientMagnitudesOn();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::CylinderClipOff()
		CODE:
		THIS->CylinderClipOff();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::CylinderClipOn()
		CODE:
		THIS->CylinderClipOn();
		XSRETURN_EMPTY;


int  *
vtkEncodedGradientEstimator::GetBounds()
		PREINIT:
		int  * retval;
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


int
vtkEncodedGradientEstimator::GetBoundsClip()
		CODE:
		RETVAL = THIS->GetBoundsClip();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetBoundsClipMaxValue()
		CODE:
		RETVAL = THIS->GetBoundsClipMaxValue();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetBoundsClipMinValue()
		CODE:
		RETVAL = THIS->GetBoundsClipMinValue();
		OUTPUT:
		RETVAL


const char *
vtkEncodedGradientEstimator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetComputeGradientMagnitudes()
		CODE:
		RETVAL = THIS->GetComputeGradientMagnitudes();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetCylinderClip()
		CODE:
		RETVAL = THIS->GetCylinderClip();
		OUTPUT:
		RETVAL


vtkDirectionEncoder *
vtkEncodedGradientEstimator::GetDirectionEncoder()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDirectionEncoder";
		CODE:
		RETVAL = THIS->GetDirectionEncoder();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetEncodedNormalIndex(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		RETVAL = THIS->GetEncodedNormalIndex(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetEncodedNormalIndex(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkEncodedGradientEstimator::GetEncodedNormalIndex\n");



float
vtkEncodedGradientEstimator::GetGradientMagnitudeBias()
		CODE:
		RETVAL = THIS->GetGradientMagnitudeBias();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientEstimator::GetGradientMagnitudeScale()
		CODE:
		RETVAL = THIS->GetGradientMagnitudeScale();
		OUTPUT:
		RETVAL


vtkImageData *
vtkEncodedGradientEstimator::GetInput()
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
vtkEncodedGradientEstimator::GetLastUpdateTimeInCPUSeconds()
		CODE:
		RETVAL = THIS->GetLastUpdateTimeInCPUSeconds();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientEstimator::GetLastUpdateTimeInSeconds()
		CODE:
		RETVAL = THIS->GetLastUpdateTimeInSeconds();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetNumberOfThreadsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMaxValue();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetNumberOfThreadsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMinValue();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetUseCylinderClip()
		CODE:
		RETVAL = THIS->GetUseCylinderClip();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientEstimator::GetZeroNormalThreshold()
		CODE:
		RETVAL = THIS->GetZeroNormalThreshold();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetZeroPad()
		CODE:
		RETVAL = THIS->GetZeroPad();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetZeroPadMaxValue()
		CODE:
		RETVAL = THIS->GetZeroPadMaxValue();
		OUTPUT:
		RETVAL


int
vtkEncodedGradientEstimator::GetZeroPadMinValue()
		CODE:
		RETVAL = THIS->GetZeroPadMinValue();
		OUTPUT:
		RETVAL


void
vtkEncodedGradientEstimator::SetBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkEncodedGradientEstimator::SetBounds\n");



void
vtkEncodedGradientEstimator::SetBoundsClip(arg1)
		int 	arg1
		CODE:
		THIS->SetBoundsClip(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetComputeGradientMagnitudes(arg1)
		int 	arg1
		CODE:
		THIS->SetComputeGradientMagnitudes(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetCylinderClip(arg1)
		int 	arg1
		CODE:
		THIS->SetCylinderClip(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetDirectionEncoder(direnc)
		vtkDirectionEncoder *	direnc
		CODE:
		THIS->SetDirectionEncoder(direnc);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetGradientMagnitudeBias(arg1)
		float 	arg1
		CODE:
		THIS->SetGradientMagnitudeBias(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetGradientMagnitudeScale(arg1)
		float 	arg1
		CODE:
		THIS->SetGradientMagnitudeScale(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetInput(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetZeroNormalThreshold(v)
		float 	v
		CODE:
		THIS->SetZeroNormalThreshold(v);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::SetZeroPad(arg1)
		int 	arg1
		CODE:
		THIS->SetZeroPad(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::ZeroPadOff()
		CODE:
		THIS->ZeroPadOff();
		XSRETURN_EMPTY;


void
vtkEncodedGradientEstimator::ZeroPadOn()
		CODE:
		THIS->ZeroPadOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::EncodedGradientShader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEncodedGradientShader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientShader::GetZeroNormalDiffuseIntensity()
		CODE:
		RETVAL = THIS->GetZeroNormalDiffuseIntensity();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientShader::GetZeroNormalDiffuseIntensityMaxValue()
		CODE:
		RETVAL = THIS->GetZeroNormalDiffuseIntensityMaxValue();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientShader::GetZeroNormalDiffuseIntensityMinValue()
		CODE:
		RETVAL = THIS->GetZeroNormalDiffuseIntensityMinValue();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientShader::GetZeroNormalSpecularIntensity()
		CODE:
		RETVAL = THIS->GetZeroNormalSpecularIntensity();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientShader::GetZeroNormalSpecularIntensityMaxValue()
		CODE:
		RETVAL = THIS->GetZeroNormalSpecularIntensityMaxValue();
		OUTPUT:
		RETVAL


float
vtkEncodedGradientShader::GetZeroNormalSpecularIntensityMinValue()
		CODE:
		RETVAL = THIS->GetZeroNormalSpecularIntensityMinValue();
		OUTPUT:
		RETVAL


static vtkEncodedGradientShader*
vtkEncodedGradientShader::New()
		CODE:
		RETVAL = vtkEncodedGradientShader::New();
		OUTPUT:
		RETVAL


void
vtkEncodedGradientShader::SetZeroNormalDiffuseIntensity(arg1)
		float 	arg1
		CODE:
		THIS->SetZeroNormalDiffuseIntensity(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientShader::SetZeroNormalSpecularIntensity(arg1)
		float 	arg1
		CODE:
		THIS->SetZeroNormalSpecularIntensity(arg1);
		XSRETURN_EMPTY;


void
vtkEncodedGradientShader::UpdateShadingTable(ren, vol, gradest)
		vtkRenderer *	ren
		vtkVolume *	vol
		vtkEncodedGradientEstimator *	gradest
		CODE:
		THIS->UpdateShadingTable(ren, vol, gradest);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Exporter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkExporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRenderWindow *
vtkExporter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkExporter::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkRenderWindow *
vtkExporter::GetRenderWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetRenderWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkExporter::SetEndWrite(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetEndWrite",0), newRV(func), 0);
		}
		THIS->SetEndWrite(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkExporter::SetInput(renWin)
		vtkRenderWindow *	renWin
		CODE:
		THIS->SetInput(renWin);
		XSRETURN_EMPTY;


void
vtkExporter::SetRenderWindow(arg1)
		vtkRenderWindow *	arg1
		CODE:
		THIS->SetRenderWindow(arg1);
		XSRETURN_EMPTY;


void
vtkExporter::SetStartWrite(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetStartWrite",0), newRV(func), 0);
		}
		THIS->SetStartWrite(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkExporter::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkExporter::Write()
		CODE:
		THIS->Write();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::FiniteDifferenceGradientEstimator PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkFiniteDifferenceGradientEstimator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkFiniteDifferenceGradientEstimator::GetSampleSpacingInVoxels()
		CODE:
		RETVAL = THIS->GetSampleSpacingInVoxels();
		OUTPUT:
		RETVAL


static vtkFiniteDifferenceGradientEstimator*
vtkFiniteDifferenceGradientEstimator::New()
		CODE:
		RETVAL = vtkFiniteDifferenceGradientEstimator::New();
		OUTPUT:
		RETVAL


void
vtkFiniteDifferenceGradientEstimator::SetSampleSpacingInVoxels(arg1)
		int 	arg1
		CODE:
		THIS->SetSampleSpacingInVoxels(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Follower PREFIX = vtk

PROTOTYPES: DISABLE



vtkCamera *
vtkFollower::GetCamera()
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
vtkFollower::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkFollower::GetMatrix(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->GetMatrix(arg1);
		XSRETURN_EMPTY;
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFollower::GetMatrix\n");



static vtkFollower*
vtkFollower::New()
		CODE:
		RETVAL = vtkFollower::New();
		OUTPUT:
		RETVAL


void
vtkFollower::Render(arg1 = 0)
	CASE: items == 2
		vtkRenderer *	arg1
		CODE:
		THIS->Render(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFollower::Render\n");



int
vtkFollower::RenderOpaqueGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(viewport);
		OUTPUT:
		RETVAL


int
vtkFollower::RenderTranslucentGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(viewport);
		OUTPUT:
		RETVAL


void
vtkFollower::SetCamera(arg1)
		vtkCamera *	arg1
		CODE:
		THIS->SetCamera(arg1);
		XSRETURN_EMPTY;


void
vtkFollower::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::FrustumCoverageCuller PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkFrustumCoverageCuller::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkFrustumCoverageCuller::GetMaximumCoverage()
		CODE:
		RETVAL = THIS->GetMaximumCoverage();
		OUTPUT:
		RETVAL


float
vtkFrustumCoverageCuller::GetMinimumCoverage()
		CODE:
		RETVAL = THIS->GetMinimumCoverage();
		OUTPUT:
		RETVAL


int
vtkFrustumCoverageCuller::GetSortingStyle()
		CODE:
		RETVAL = THIS->GetSortingStyle();
		OUTPUT:
		RETVAL


const char *
vtkFrustumCoverageCuller::GetSortingStyleAsString()
		CODE:
		RETVAL = THIS->GetSortingStyleAsString();
		OUTPUT:
		RETVAL


int
vtkFrustumCoverageCuller::GetSortingStyleMaxValue()
		CODE:
		RETVAL = THIS->GetSortingStyleMaxValue();
		OUTPUT:
		RETVAL


int
vtkFrustumCoverageCuller::GetSortingStyleMinValue()
		CODE:
		RETVAL = THIS->GetSortingStyleMinValue();
		OUTPUT:
		RETVAL


static vtkFrustumCoverageCuller*
vtkFrustumCoverageCuller::New()
		CODE:
		RETVAL = vtkFrustumCoverageCuller::New();
		OUTPUT:
		RETVAL


void
vtkFrustumCoverageCuller::SetMaximumCoverage(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumCoverage(arg1);
		XSRETURN_EMPTY;


void
vtkFrustumCoverageCuller::SetMinimumCoverage(arg1)
		float 	arg1
		CODE:
		THIS->SetMinimumCoverage(arg1);
		XSRETURN_EMPTY;


void
vtkFrustumCoverageCuller::SetSortingStyle(arg1)
		int 	arg1
		CODE:
		THIS->SetSortingStyle(arg1);
		XSRETURN_EMPTY;


void
vtkFrustumCoverageCuller::SetSortingStyleToBackToFront()
		CODE:
		THIS->SetSortingStyleToBackToFront();
		XSRETURN_EMPTY;


void
vtkFrustumCoverageCuller::SetSortingStyleToFrontToBack()
		CODE:
		THIS->SetSortingStyleToFrontToBack();
		XSRETURN_EMPTY;


void
vtkFrustumCoverageCuller::SetSortingStyleToNone()
		CODE:
		THIS->SetSortingStyleToNone();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::GraphicsFactory PREFIX = vtk

PROTOTYPES: DISABLE



static vtkObject *
vtkGraphicsFactory::CreateInstance(vtkclassname)
		const char *	vtkclassname
		CODE:
		RETVAL = vtkGraphicsFactory::CreateInstance(vtkclassname);
		OUTPUT:
		RETVAL


const char *
vtkGraphicsFactory::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static const char *
vtkGraphicsFactory::GetRenderLibrary()
		CODE:
		RETVAL = vtkGraphicsFactory::GetRenderLibrary();
		OUTPUT:
		RETVAL


static vtkGraphicsFactory*
vtkGraphicsFactory::New()
		CODE:
		RETVAL = vtkGraphicsFactory::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::IVExporter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkIVExporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkIVExporter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


static vtkIVExporter*
vtkIVExporter::New()
		CODE:
		RETVAL = vtkIVExporter::New();
		OUTPUT:
		RETVAL


void
vtkIVExporter::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImageActor PREFIX = vtk

PROTOTYPES: DISABLE



float *
vtkImageActor::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkImageActor::GetBounds\n");



const char *
vtkImageActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int *
vtkImageActor::GetDisplayExtent()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDisplayExtent();
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
		croak("Unsupported number of args and/or types supplied to vtkImageActor::GetDisplayExtent\n");



vtkImageData *
vtkImageActor::GetInput()
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
vtkImageActor::GetInterpolate()
		CODE:
		RETVAL = THIS->GetInterpolate();
		OUTPUT:
		RETVAL


int
vtkImageActor::GetSliceNumber()
		CODE:
		RETVAL = THIS->GetSliceNumber();
		OUTPUT:
		RETVAL


int
vtkImageActor::GetWholeZMax()
		CODE:
		RETVAL = THIS->GetWholeZMax();
		OUTPUT:
		RETVAL


int
vtkImageActor::GetWholeZMin()
		CODE:
		RETVAL = THIS->GetWholeZMin();
		OUTPUT:
		RETVAL


int
vtkImageActor::GetZSlice()
		CODE:
		RETVAL = THIS->GetZSlice();
		OUTPUT:
		RETVAL


void
vtkImageActor::InterpolateOff()
		CODE:
		THIS->InterpolateOff();
		XSRETURN_EMPTY;


void
vtkImageActor::InterpolateOn()
		CODE:
		THIS->InterpolateOn();
		XSRETURN_EMPTY;


static vtkImageActor*
vtkImageActor::New()
		CODE:
		RETVAL = vtkImageActor::New();
		OUTPUT:
		RETVAL


void
vtkImageActor::SetDisplayExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetDisplayExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageActor::SetDisplayExtent\n");



void
vtkImageActor::SetInput(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkImageActor::SetInterpolate(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolate(arg1);
		XSRETURN_EMPTY;


void
vtkImageActor::SetZSlice(z)
		int 	z
		CODE:
		THIS->SetZSlice(z);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImageMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageMapper::GetColorLevel()
		CODE:
		RETVAL = THIS->GetColorLevel();
		OUTPUT:
		RETVAL


float
vtkImageMapper::GetColorScale()
		CODE:
		RETVAL = THIS->GetColorScale();
		OUTPUT:
		RETVAL


float
vtkImageMapper::GetColorShift()
		CODE:
		RETVAL = THIS->GetColorShift();
		OUTPUT:
		RETVAL


float
vtkImageMapper::GetColorWindow()
		CODE:
		RETVAL = THIS->GetColorWindow();
		OUTPUT:
		RETVAL


int  *
vtkImageMapper::GetCustomDisplayExtents()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCustomDisplayExtents();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


vtkImageData *
vtkImageMapper::GetInput()
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
vtkImageMapper::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkImageMapper::GetRenderToRectangle()
		CODE:
		RETVAL = THIS->GetRenderToRectangle();
		OUTPUT:
		RETVAL


int
vtkImageMapper::GetUseCustomExtents()
		CODE:
		RETVAL = THIS->GetUseCustomExtents();
		OUTPUT:
		RETVAL


int
vtkImageMapper::GetWholeZMax()
		CODE:
		RETVAL = THIS->GetWholeZMax();
		OUTPUT:
		RETVAL


int
vtkImageMapper::GetWholeZMin()
		CODE:
		RETVAL = THIS->GetWholeZMin();
		OUTPUT:
		RETVAL


int
vtkImageMapper::GetZSlice()
		CODE:
		RETVAL = THIS->GetZSlice();
		OUTPUT:
		RETVAL


static vtkImageMapper*
vtkImageMapper::New()
		CODE:
		RETVAL = vtkImageMapper::New();
		OUTPUT:
		RETVAL


void
vtkImageMapper::RenderData(arg1, arg2, arg3)
		vtkViewport *	arg1
		vtkImageData *	arg2
		vtkActor2D *	arg3
		CODE:
		THIS->RenderData(arg1, arg2, arg3);
		XSRETURN_EMPTY;


void
vtkImageMapper::RenderStart(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderStart(viewport, actor);
		XSRETURN_EMPTY;


void
vtkImageMapper::RenderToRectangleOff()
		CODE:
		THIS->RenderToRectangleOff();
		XSRETURN_EMPTY;


void
vtkImageMapper::RenderToRectangleOn()
		CODE:
		THIS->RenderToRectangleOn();
		XSRETURN_EMPTY;


void
vtkImageMapper::SetColorLevel(arg1)
		float 	arg1
		CODE:
		THIS->SetColorLevel(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapper::SetColorWindow(arg1)
		float 	arg1
		CODE:
		THIS->SetColorWindow(arg1);
		XSRETURN_EMPTY;



void
vtkImageMapper::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkImageMapper::SetRenderToRectangle(arg1)
		int 	arg1
		CODE:
		THIS->SetRenderToRectangle(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapper::SetUseCustomExtents(arg1)
		int 	arg1
		CODE:
		THIS->SetUseCustomExtents(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapper::SetZSlice(arg1)
		int 	arg1
		CODE:
		THIS->SetZSlice(arg1);
		XSRETURN_EMPTY;


void
vtkImageMapper::UseCustomExtentsOff()
		CODE:
		THIS->UseCustomExtentsOff();
		XSRETURN_EMPTY;


void
vtkImageMapper::UseCustomExtentsOn()
		CODE:
		THIS->UseCustomExtentsOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImageViewer PREFIX = vtk

PROTOTYPES: DISABLE



vtkActor2D *
vtkImageViewer::GetActor2D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2D";
		CODE:
		RETVAL = THIS->GetActor2D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkImageViewer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageViewer::GetColorLevel()
		CODE:
		RETVAL = THIS->GetColorLevel();
		OUTPUT:
		RETVAL


float
vtkImageViewer::GetColorWindow()
		CODE:
		RETVAL = THIS->GetColorWindow();
		OUTPUT:
		RETVAL


int
vtkImageViewer::GetGrayScaleHint()
		CODE:
		RETVAL = THIS->GetGrayScaleHint();
		OUTPUT:
		RETVAL


vtkImageMapper *
vtkImageViewer::GetImageMapper()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageMapper";
		CODE:
		RETVAL = THIS->GetImageMapper();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageWindow *
vtkImageViewer::GetImageWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageWindow";
		CODE:
		RETVAL = THIS->GetImageWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImager *
vtkImageViewer::GetImager()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImager";
		CODE:
		RETVAL = THIS->GetImager();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageViewer::GetInput()
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


int *
vtkImageViewer::GetPosition()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


vtkRenderWindow *
vtkImageViewer::GetRenderWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetRenderWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRenderer *
vtkImageViewer::GetRenderer()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetRenderer();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int *
vtkImageViewer::GetSize()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkImageViewer::GetWholeZMax()
		CODE:
		RETVAL = THIS->GetWholeZMax();
		OUTPUT:
		RETVAL


int
vtkImageViewer::GetWholeZMin()
		CODE:
		RETVAL = THIS->GetWholeZMin();
		OUTPUT:
		RETVAL


char *
vtkImageViewer::GetWindowName()
		CODE:
		RETVAL = THIS->GetWindowName();
		OUTPUT:
		RETVAL


int
vtkImageViewer::GetZSlice()
		CODE:
		RETVAL = THIS->GetZSlice();
		OUTPUT:
		RETVAL


void
vtkImageViewer::GrayScaleHintOff()
		CODE:
		THIS->GrayScaleHintOff();
		XSRETURN_EMPTY;


void
vtkImageViewer::GrayScaleHintOn()
		CODE:
		THIS->GrayScaleHintOn();
		XSRETURN_EMPTY;


static vtkImageViewer*
vtkImageViewer::New()
		CODE:
		RETVAL = vtkImageViewer::New();
		OUTPUT:
		RETVAL


void
vtkImageViewer::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkImageViewer::SetColorLevel(s)
		float 	s
		CODE:
		THIS->SetColorLevel(s);
		XSRETURN_EMPTY;


void
vtkImageViewer::SetColorWindow(s)
		float 	s
		CODE:
		THIS->SetColorWindow(s);
		XSRETURN_EMPTY;


void
vtkImageViewer::SetGrayScaleHint(a)
		int 	a
		CODE:
		THIS->SetGrayScaleHint(a);
		XSRETURN_EMPTY;


void
vtkImageViewer::SetInput(in)
		vtkImageData *	in
		CODE:
		THIS->SetInput(in);
		XSRETURN_EMPTY;


void
vtkImageViewer::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageViewer::SetPosition\n");



void
vtkImageViewer::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageViewer::SetSize\n");



void
vtkImageViewer::SetZSlice(s)
		int 	s
		CODE:
		THIS->SetZSlice(s);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImageViewer2 PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageViewer2::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkImageViewer2::GetColorLevel()
		CODE:
		RETVAL = THIS->GetColorLevel();
		OUTPUT:
		RETVAL


float
vtkImageViewer2::GetColorWindow()
		CODE:
		RETVAL = THIS->GetColorWindow();
		OUTPUT:
		RETVAL


vtkImageActor *
vtkImageViewer2::GetImageActor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageActor";
		CODE:
		RETVAL = THIS->GetImageActor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageViewer2::GetInput()
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


vtkRenderWindow *
vtkImageViewer2::GetRenderWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetRenderWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRenderer *
vtkImageViewer2::GetRenderer()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetRenderer();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImageViewer2::GetWholeZMax()
		CODE:
		RETVAL = THIS->GetWholeZMax();
		OUTPUT:
		RETVAL


int
vtkImageViewer2::GetWholeZMin()
		CODE:
		RETVAL = THIS->GetWholeZMin();
		OUTPUT:
		RETVAL


vtkImageMapToWindowLevelColors *
vtkImageViewer2::GetWindowLevel()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageMapToWindowLevelColors";
		CODE:
		RETVAL = THIS->GetWindowLevel();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


char *
vtkImageViewer2::GetWindowName()
		CODE:
		RETVAL = THIS->GetWindowName();
		OUTPUT:
		RETVAL


int
vtkImageViewer2::GetZSlice()
		CODE:
		RETVAL = THIS->GetZSlice();
		OUTPUT:
		RETVAL


static vtkImageViewer2*
vtkImageViewer2::New()
		CODE:
		RETVAL = vtkImageViewer2::New();
		OUTPUT:
		RETVAL


void
vtkImageViewer2::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkImageViewer2::SetColorLevel(s)
		float 	s
		CODE:
		THIS->SetColorLevel(s);
		XSRETURN_EMPTY;


void
vtkImageViewer2::SetColorWindow(s)
		float 	s
		CODE:
		THIS->SetColorWindow(s);
		XSRETURN_EMPTY;


void
vtkImageViewer2::SetInput(in)
		vtkImageData *	in
		CODE:
		THIS->SetInput(in);
		XSRETURN_EMPTY;


void
vtkImageViewer2::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageViewer2::SetPosition\n");



void
vtkImageViewer2::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageViewer2::SetSize\n");



void
vtkImageViewer2::SetZSlice(s)
		int 	s
		CODE:
		THIS->SetZSlice(s);
		XSRETURN_EMPTY;


void
vtkImageViewer2::SetupInteractor(arg1)
		vtkRenderWindowInteractor *	arg1
		CODE:
		THIS->SetupInteractor(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImageWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageWindow::AddImager(im)
		vtkImager *	im
		CODE:
		THIS->AddImager(im);
		XSRETURN_EMPTY;


void
vtkImageWindow::ClosePPMImageFile()
		CODE:
		THIS->ClosePPMImageFile();
		XSRETURN_EMPTY;


void
vtkImageWindow::EraseWindow()
		CODE:
		THIS->EraseWindow();
		XSRETURN_EMPTY;


void
vtkImageWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkImageWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkImageWindow::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkImageWindow::GetGrayScaleHint()
		CODE:
		RETVAL = THIS->GetGrayScaleHint();
		OUTPUT:
		RETVAL


vtkImagerCollection *
vtkImageWindow::GetImagers()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImagerCollection";
		CODE:
		RETVAL = THIS->GetImagers();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkImageWindow::GrayScaleHintOff()
		CODE:
		THIS->GrayScaleHintOff();
		XSRETURN_EMPTY;


void
vtkImageWindow::GrayScaleHintOn()
		CODE:
		THIS->GrayScaleHintOn();
		XSRETURN_EMPTY;


void
vtkImageWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


static vtkImageWindow*
vtkImageWindow::New()
		CODE:
		RETVAL = vtkImageWindow::New();
		OUTPUT:
		RETVAL


int
vtkImageWindow::OpenPPMImageFile()
		CODE:
		RETVAL = THIS->OpenPPMImageFile();
		OUTPUT:
		RETVAL


void
vtkImageWindow::RemoveImager(im)
		vtkImager *	im
		CODE:
		THIS->RemoveImager(im);
		XSRETURN_EMPTY;


void
vtkImageWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkImageWindow::SaveImageAsPPM()
		CODE:
		THIS->SaveImageAsPPM();
		XSRETURN_EMPTY;


void
vtkImageWindow::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkImageWindow::SetGrayScaleHint(arg1)
		int 	arg1
		CODE:
		THIS->SetGrayScaleHint(arg1);
		XSRETURN_EMPTY;


void
vtkImageWindow::SetParentInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetParentInfo(arg1);
		XSRETURN_EMPTY;


void
vtkImageWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageWindow::SetPosition\n");



void
vtkImageWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageWindow::SetSize\n");



void
vtkImageWindow::SetWindowInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowInfo(arg1);
		XSRETURN_EMPTY;


void
vtkImageWindow::SwapBuffers()
		CODE:
		THIS->SwapBuffers();
		XSRETURN_EMPTY;


void
vtkImageWindow::WritePPMImageFile()
		CODE:
		THIS->WritePPMImageFile();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Imager PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImager::Erase()
		CODE:
		THIS->Erase();
		XSRETURN_EMPTY;


const char *
vtkImager::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageWindow *
vtkImager::GetImageWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageWindow";
		CODE:
		RETVAL = THIS->GetImageWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkImager::GetPickedZ()
		CODE:
		RETVAL = THIS->GetPickedZ();
		OUTPUT:
		RETVAL


vtkWindow *
vtkImager::GetVTKWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkWindow";
		CODE:
		RETVAL = THIS->GetVTKWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImager*
vtkImager::New()
		CODE:
		RETVAL = vtkImager::New();
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkImager::PickProp(selectionX, selectionY)
		float 	selectionX
		float 	selectionY
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->PickProp(selectionX, selectionY);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkImager::RenderOpaqueGeometry()
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry();
		OUTPUT:
		RETVAL


int
vtkImager::RenderOverlay()
		CODE:
		RETVAL = THIS->RenderOverlay();
		OUTPUT:
		RETVAL


int
vtkImager::RenderTranslucentGeometry()
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImagerCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImagerCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkImager *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImagerCollection::AddItem\n");



const char *
vtkImagerCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImager *
vtkImagerCollection::GetLastItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImager";
		CODE:
		RETVAL = THIS->GetLastItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkImager *
vtkImagerCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImager";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImagerCollection*
vtkImagerCollection::New()
		CODE:
		RETVAL = vtkImagerCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ImagingFactory PREFIX = vtk

PROTOTYPES: DISABLE



static vtkObject *
vtkImagingFactory::CreateInstance(vtkclassname)
		const char *	vtkclassname
		CODE:
		RETVAL = vtkImagingFactory::CreateInstance(vtkclassname);
		OUTPUT:
		RETVAL


const char *
vtkImagingFactory::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkImagingFactory*
vtkImagingFactory::New()
		CODE:
		RETVAL = vtkImagingFactory::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Importer PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRenderWindow *
vtkImporter::GetRenderWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetRenderWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRenderer *
vtkImporter::GetRenderer()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetRenderer();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkImporter::Read()
		CODE:
		THIS->Read();
		XSRETURN_EMPTY;


void
vtkImporter::SetRenderWindow(arg1)
		vtkRenderWindow *	arg1
		CODE:
		THIS->SetRenderWindow(arg1);
		XSRETURN_EMPTY;


void
vtkImporter::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyle PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkInteractorStyle::AutoAdjustCameraClippingRangeOff()
		CODE:
		THIS->AutoAdjustCameraClippingRangeOff();
		XSRETURN_EMPTY;


void
vtkInteractorStyle::AutoAdjustCameraClippingRangeOn()
		CODE:
		THIS->AutoAdjustCameraClippingRangeOn();
		XSRETURN_EMPTY;


void
vtkInteractorStyle::FindPokedCamera(arg1, arg2)
		int 	arg1
		int 	arg2
		CODE:
		THIS->FindPokedCamera(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::FindPokedRenderer(arg1, arg2)
		int 	arg1
		int 	arg2
		CODE:
		THIS->FindPokedRenderer(arg1, arg2);
		XSRETURN_EMPTY;


int
vtkInteractorStyle::GetAutoAdjustCameraClippingRange()
		CODE:
		RETVAL = THIS->GetAutoAdjustCameraClippingRange();
		OUTPUT:
		RETVAL


int
vtkInteractorStyle::GetAutoAdjustCameraClippingRangeMaxValue()
		CODE:
		RETVAL = THIS->GetAutoAdjustCameraClippingRangeMaxValue();
		OUTPUT:
		RETVAL


int
vtkInteractorStyle::GetAutoAdjustCameraClippingRangeMinValue()
		CODE:
		RETVAL = THIS->GetAutoAdjustCameraClippingRangeMinValue();
		OUTPUT:
		RETVAL


const char *
vtkInteractorStyle::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRenderWindowInteractor *
vtkInteractorStyle::GetInteractor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindowInteractor";
		CODE:
		RETVAL = THIS->GetInteractor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkInteractorStyle::GetPickColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPickColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


void
vtkInteractorStyle::HighlightActor2D(actor2D)
		vtkActor2D *	actor2D
		CODE:
		THIS->HighlightActor2D(actor2D);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::HighlightProp(prop)
		vtkProp *	prop
		CODE:
		THIS->HighlightProp(prop);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::HighlightProp3D(prop3D)
		vtkProp3D *	prop3D
		CODE:
		THIS->HighlightProp3D(prop3D);
		XSRETURN_EMPTY;


static vtkInteractorStyle*
vtkInteractorStyle::New()
		CODE:
		RETVAL = vtkInteractorStyle::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyle::OnChar(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnChar(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnConfigure(width, height)
		int 	width
		int 	height
		CODE:
		THIS->OnConfigure(width, height);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnEnter(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnEnter(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnKeyDown(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnKeyDown(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnKeyPress(ctrl, shift, keycode, keysym, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		char *	keysym
		int 	repeatcount
		CODE:
		THIS->OnKeyPress(ctrl, shift, keycode, keysym, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnKeyRelease(ctrl, shift, keycode, keysym, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		char *	keysym
		int 	repeatcount
		CODE:
		THIS->OnKeyRelease(ctrl, shift, keycode, keysym, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnKeyUp(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnKeyUp(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnLeave(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeave(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnLeftButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnLeftButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnMiddleButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnMiddleButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnMouseMove(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMouseMove(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnRightButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnRightButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetAutoAdjustCameraClippingRange(arg1)
		int 	arg1
		CODE:
		THIS->SetAutoAdjustCameraClippingRange(arg1);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetInteractor(interactor)
		vtkRenderWindowInteractor *	interactor
		CODE:
		THIS->SetInteractor(interactor);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetLeftButtonPressMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetLeftButtonPressMethod",0), newRV(func), 0);
		}
		THIS->SetLeftButtonPressMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetLeftButtonReleaseMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetLeftButtonReleaseMethod",0), newRV(func), 0);
		}
		THIS->SetLeftButtonReleaseMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetMiddleButtonPressMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetMiddleButtonPressMethod",0), newRV(func), 0);
		}
		THIS->SetMiddleButtonPressMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetMiddleButtonReleaseMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetMiddleButtonReleaseMethod",0), newRV(func), 0);
		}
		THIS->SetMiddleButtonReleaseMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetPickColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPickColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkInteractorStyle::SetPickColor\n");



void
vtkInteractorStyle::SetRightButtonPressMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetRightButtonPressMethod",0), newRV(func), 0);
		}
		THIS->SetRightButtonPressMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyle::SetRightButtonReleaseMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetRightButtonReleaseMethod",0), newRV(func), 0);
		}
		THIS->SetRightButtonReleaseMethod(callperlsub, func);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleFlight PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkInteractorStyleFlight::DisableMotionOff()
		CODE:
		THIS->DisableMotionOff();
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::DisableMotionOn()
		CODE:
		THIS->DisableMotionOn();
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::FixUpVectorOff()
		CODE:
		THIS->FixUpVectorOff();
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::FixUpVectorOn()
		CODE:
		THIS->FixUpVectorOn();
		XSRETURN_EMPTY;


double
vtkInteractorStyleFlight::GetAngleAccelerationFactor()
		CODE:
		RETVAL = THIS->GetAngleAccelerationFactor();
		OUTPUT:
		RETVAL


double
vtkInteractorStyleFlight::GetAngleStepSize()
		CODE:
		RETVAL = THIS->GetAngleStepSize();
		OUTPUT:
		RETVAL


const char *
vtkInteractorStyleFlight::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkInteractorStyleFlight::GetDisableMotion()
		CODE:
		RETVAL = THIS->GetDisableMotion();
		OUTPUT:
		RETVAL


int
vtkInteractorStyleFlight::GetFixUpVector()
		CODE:
		RETVAL = THIS->GetFixUpVector();
		OUTPUT:
		RETVAL


double  *
vtkInteractorStyleFlight::GetFixedUpVector()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFixedUpVector();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double
vtkInteractorStyleFlight::GetMotionAccelerationFactor()
		CODE:
		RETVAL = THIS->GetMotionAccelerationFactor();
		OUTPUT:
		RETVAL


double
vtkInteractorStyleFlight::GetMotionStepSize()
		CODE:
		RETVAL = THIS->GetMotionStepSize();
		OUTPUT:
		RETVAL


static vtkInteractorStyleFlight*
vtkInteractorStyleFlight::New()
		CODE:
		RETVAL = vtkInteractorStyleFlight::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleFlight::OnChar(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnChar(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnKeyDown(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnKeyDown(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnKeyUp(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnKeyUp(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnLeftButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnLeftButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnMiddleButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnMiddleButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnMouseMove(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMouseMove(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnRightButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnRightButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::PerformAzimuthalScan(numsteps)
		int 	numsteps
		CODE:
		THIS->PerformAzimuthalScan(numsteps);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::SetAngleAccelerationFactor(arg1)
		double 	arg1
		CODE:
		THIS->SetAngleAccelerationFactor(arg1);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::SetAngleStepSize(arg1)
		double 	arg1
		CODE:
		THIS->SetAngleStepSize(arg1);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::SetDisableMotion(arg1)
		int 	arg1
		CODE:
		THIS->SetDisableMotion(arg1);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::SetFixUpVector(arg1)
		int 	arg1
		CODE:
		THIS->SetFixUpVector(arg1);
		XSRETURN_EMPTY;



void
vtkInteractorStyleFlight::SetMotionAccelerationFactor(arg1)
		double 	arg1
		CODE:
		THIS->SetMotionAccelerationFactor(arg1);
		XSRETURN_EMPTY;


void
vtkInteractorStyleFlight::SetMotionStepSize(arg1)
		double 	arg1
		CODE:
		THIS->SetMotionStepSize(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleImage PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleImage::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkInteractorStyleImage::GetWindowLevelCurrentPosition()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWindowLevelCurrentPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int  *
vtkInteractorStyleImage::GetWindowLevelStartPosition()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWindowLevelStartPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkInteractorStyleImage*
vtkInteractorStyleImage::New()
		CODE:
		RETVAL = vtkInteractorStyleImage::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleImage::OnLeftButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleImage::OnLeftButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleImage::OnMiddleButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleImage::OnMiddleButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleImage::OnMouseMove(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMouseMove(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleImage::OnRightButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleImage::OnRightButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleJoystickActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleJoystickActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkInteractorStyleJoystickActor*
vtkInteractorStyleJoystickActor::New()
		CODE:
		RETVAL = vtkInteractorStyleJoystickActor::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleJoystickActor::OnLeftButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnLeftButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnMiddleButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnMiddleButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnMouseMove(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMouseMove(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnRightButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnRightButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickActor::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleJoystickCamera PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleJoystickCamera::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkInteractorStyleJoystickCamera*
vtkInteractorStyleJoystickCamera::New()
		CODE:
		RETVAL = vtkInteractorStyleJoystickCamera::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleJoystickCamera::OnLeftButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnLeftButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnMiddleButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnMiddleButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnMouseMove(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMouseMove(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnRightButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnRightButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleJoystickCamera::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleSwitch PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleSwitch::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkInteractorStyleSwitch*
vtkInteractorStyleSwitch::New()
		CODE:
		RETVAL = vtkInteractorStyleSwitch::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleSwitch::OnChar(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnChar(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnLeftButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnLeftButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnMiddleButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnMiddleButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnMouseMove(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMouseMove(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnRightButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnRightButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::SetAutoAdjustCameraClippingRange(value)
		int 	value
		CODE:
		THIS->SetAutoAdjustCameraClippingRange(value);
		XSRETURN_EMPTY;


void
vtkInteractorStyleSwitch::SetInteractor(iren)
		vtkRenderWindowInteractor *	iren
		CODE:
		THIS->SetInteractor(iren);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleTrackball PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkInteractorStyleTrackball::GetActorMode()
		CODE:
		RETVAL = THIS->GetActorMode();
		OUTPUT:
		RETVAL


const char *
vtkInteractorStyleTrackball::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkInteractorStyleTrackball::GetTrackballMode()
		CODE:
		RETVAL = THIS->GetTrackballMode();
		OUTPUT:
		RETVAL


static vtkInteractorStyleTrackball*
vtkInteractorStyleTrackball::New()
		CODE:
		RETVAL = vtkInteractorStyleTrackball::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleTrackball::OnChar(ctrl, shift, keycode, repeatcount)
		int 	ctrl
		int 	shift
		char 	keycode
		int 	repeatcount
		CODE:
		THIS->OnChar(ctrl, shift, keycode, repeatcount);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnLeftButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnLeftButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnMiddleButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnMiddleButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnRightButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnRightButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::SetActorModeToActor()
		CODE:
		THIS->SetActorModeToActor();
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::SetActorModeToCamera()
		CODE:
		THIS->SetActorModeToCamera();
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::SetTrackballModeToJoystick()
		CODE:
		THIS->SetTrackballModeToJoystick();
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackball::SetTrackballModeToTrackball()
		CODE:
		THIS->SetTrackballModeToTrackball();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleTrackballActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleTrackballActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkInteractorStyleTrackballActor*
vtkInteractorStyleTrackballActor::New()
		CODE:
		RETVAL = vtkInteractorStyleTrackballActor::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleTrackballActor::OnLeftButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballActor::OnLeftButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballActor::OnMiddleButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballActor::OnMiddleButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballActor::OnMouseMove(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMouseMove(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballActor::OnRightButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballActor::OnRightButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleTrackballCamera PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleTrackballCamera::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkInteractorStyleTrackballCamera*
vtkInteractorStyleTrackballCamera::New()
		CODE:
		RETVAL = vtkInteractorStyleTrackballCamera::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleTrackballCamera::OnLeftButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballCamera::OnLeftButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballCamera::OnMiddleButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballCamera::OnMiddleButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMiddleButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballCamera::OnMouseMove(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnMouseMove(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballCamera::OnRightButtonDown(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonDown(ctrl, shift, x, y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleTrackballCamera::OnRightButtonUp(ctrl, shift, x, y)
		int 	ctrl
		int 	shift
		int 	x
		int 	y
		CODE:
		THIS->OnRightButtonUp(ctrl, shift, x, y);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleUnicam PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInteractorStyleUnicam::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkInteractorStyleUnicam::GetWorldUpVector()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWorldUpVector();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkInteractorStyleUnicam*
vtkInteractorStyleUnicam::New()
		CODE:
		RETVAL = vtkInteractorStyleUnicam::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleUnicam::OnLeftButtonDown(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonDown(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::OnLeftButtonMove(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonMove(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::OnLeftButtonUp(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnLeftButtonUp(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::OnMiddleButtonMove(arg1, arg2, arg3, arg4)
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->OnMiddleButtonMove(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::OnMouseMove(ctrl, shift, X, Y)
		int 	ctrl
		int 	shift
		int 	X
		int 	Y
		CODE:
		THIS->OnMouseMove(ctrl, shift, X, Y);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::OnRightButtonMove(arg1, arg2, arg3, arg4)
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->OnRightButtonMove(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::OnTimer()
		CODE:
		THIS->OnTimer();
		XSRETURN_EMPTY;


void
vtkInteractorStyleUnicam::SetWorldUpVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetWorldUpVector(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkInteractorStyleUnicam::SetWorldUpVector\n");


MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::InteractorStyleUser PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkInteractorStyleUser::GetButton()
		CODE:
		RETVAL = THIS->GetButton();
		OUTPUT:
		RETVAL


int
vtkInteractorStyleUser::GetChar()
		CODE:
		RETVAL = THIS->GetChar();
		OUTPUT:
		RETVAL


const char *
vtkInteractorStyleUser::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkInteractorStyleUser::GetCtrlKey()
		CODE:
		RETVAL = THIS->GetCtrlKey();
		OUTPUT:
		RETVAL


char *
vtkInteractorStyleUser::GetKeySym()
		CODE:
		RETVAL = THIS->GetKeySym();
		OUTPUT:
		RETVAL


int  *
vtkInteractorStyleUser::GetOldPos()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOldPos();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkInteractorStyleUser::GetShiftKey()
		CODE:
		RETVAL = THIS->GetShiftKey();
		OUTPUT:
		RETVAL


static vtkInteractorStyleUser*
vtkInteractorStyleUser::New()
		CODE:
		RETVAL = vtkInteractorStyleUser::New();
		OUTPUT:
		RETVAL


void
vtkInteractorStyleUser::SetButtonPressMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetButtonPressMethod",0), newRV(func), 0);
		}
		THIS->SetButtonPressMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetButtonReleaseMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetButtonReleaseMethod",0), newRV(func), 0);
		}
		THIS->SetButtonReleaseMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetCharMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetCharMethod",0), newRV(func), 0);
		}
		THIS->SetCharMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetConfigureMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetConfigureMethod",0), newRV(func), 0);
		}
		THIS->SetConfigureMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetEnterMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetEnterMethod",0), newRV(func), 0);
		}
		THIS->SetEnterMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetKeyPressMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetKeyPressMethod",0), newRV(func), 0);
		}
		THIS->SetKeyPressMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetKeyReleaseMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetKeyReleaseMethod",0), newRV(func), 0);
		}
		THIS->SetKeyReleaseMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetLeaveMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetLeaveMethod",0), newRV(func), 0);
		}
		THIS->SetLeaveMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetMouseMoveMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetMouseMoveMethod",0), newRV(func), 0);
		}
		THIS->SetMouseMoveMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkInteractorStyleUser::SetTimerMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetTimerMethod",0), newRV(func), 0);
		}
		THIS->SetTimerMethod(callperlsub, func);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::LODActor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLODActor::AddLODMapper(mapper)
		vtkMapper *	mapper
		CODE:
		THIS->AddLODMapper(mapper);
		XSRETURN_EMPTY;


const char *
vtkLODActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkMapperCollection *
vtkLODActor::GetLODMappers()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMapperCollection";
		CODE:
		RETVAL = THIS->GetLODMappers();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkLODActor::GetNumberOfCloudPoints()
		CODE:
		RETVAL = THIS->GetNumberOfCloudPoints();
		OUTPUT:
		RETVAL


void
vtkLODActor::Modified()
		CODE:
		THIS->Modified();
		XSRETURN_EMPTY;


static vtkLODActor*
vtkLODActor::New()
		CODE:
		RETVAL = vtkLODActor::New();
		OUTPUT:
		RETVAL


void
vtkLODActor::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkLODActor::Render(arg1, arg2)
		vtkRenderer *	arg1
		vtkMapper *	arg2
		CODE:
		THIS->Render(arg1, arg2);
		XSRETURN_EMPTY;


int
vtkLODActor::RenderOpaqueGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(viewport);
		OUTPUT:
		RETVAL


void
vtkLODActor::SetNumberOfCloudPoints(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfCloudPoints(arg1);
		XSRETURN_EMPTY;


void
vtkLODActor::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::LODProp3D PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkLODProp3D::AddLOD(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		vtkMapper *	arg1
		vtkProperty *	arg2
		vtkProperty *	arg3
		vtkTexture *	arg4
		float 	arg5
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2, arg3, arg4, arg5);
		OUTPUT:
		RETVAL
	CASE: items == 5 && sv_isobject(ST(3)) && sv_derived_from(ST(3),"Graphics::VTK::Texture")
		vtkMapper *	arg1
		vtkProperty *	arg2
		vtkTexture *	arg3
		float 	arg4
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 5 && sv_isobject(ST(3)) && sv_derived_from(ST(3),"Graphics::VTK::Property")
		vtkMapper *	arg1
		vtkProperty *	arg2
		vtkProperty *	arg3
		float 	arg4
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 4 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::VolumeProperty")
		vtkVolumeMapper *	arg1
		vtkVolumeProperty *	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE: items == 4 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::Texture")
		vtkMapper *	arg1
		vtkTexture *	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE: items == 4 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::Property")
		vtkMapper *	arg1
		vtkProperty *	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE: items == 3 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::VolumeMapper")
		vtkVolumeMapper *	arg1
		float 	arg2
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 3 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Mapper")
		vtkMapper *	arg1
		float 	arg2
		CODE:
		RETVAL = THIS->AddLOD(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLODProp3D::AddLOD\n");



void
vtkLODProp3D::AutomaticLODSelectionOff()
		CODE:
		THIS->AutomaticLODSelectionOff();
		XSRETURN_EMPTY;


void
vtkLODProp3D::AutomaticLODSelectionOn()
		CODE:
		THIS->AutomaticLODSelectionOn();
		XSRETURN_EMPTY;


void
vtkLODProp3D::AutomaticPickLODSelectionOff()
		CODE:
		THIS->AutomaticPickLODSelectionOff();
		XSRETURN_EMPTY;


void
vtkLODProp3D::AutomaticPickLODSelectionOn()
		CODE:
		THIS->AutomaticPickLODSelectionOn();
		XSRETURN_EMPTY;


void
vtkLODProp3D::DisableLOD(id)
		int 	id
		CODE:
		THIS->DisableLOD(id);
		XSRETURN_EMPTY;


void
vtkLODProp3D::EnableLOD(id)
		int 	id
		CODE:
		THIS->EnableLOD(id);
		XSRETURN_EMPTY;


void
vtkLODProp3D::GetActors(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetActors(arg1);
		XSRETURN_EMPTY;


int
vtkLODProp3D::GetAutomaticLODSelection()
		CODE:
		RETVAL = THIS->GetAutomaticLODSelection();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetAutomaticLODSelectionMaxValue()
		CODE:
		RETVAL = THIS->GetAutomaticLODSelectionMaxValue();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetAutomaticLODSelectionMinValue()
		CODE:
		RETVAL = THIS->GetAutomaticLODSelectionMinValue();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetAutomaticPickLODSelection()
		CODE:
		RETVAL = THIS->GetAutomaticPickLODSelection();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetAutomaticPickLODSelectionMaxValue()
		CODE:
		RETVAL = THIS->GetAutomaticPickLODSelectionMaxValue();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetAutomaticPickLODSelectionMinValue()
		CODE:
		RETVAL = THIS->GetAutomaticPickLODSelectionMinValue();
		OUTPUT:
		RETVAL


float *
vtkLODProp3D::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkLODProp3D::GetBounds\n");



const char *
vtkLODProp3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkLODProp3D::GetLODEstimatedRenderTime(id)
		int 	id
		CODE:
		RETVAL = THIS->GetLODEstimatedRenderTime(id);
		OUTPUT:
		RETVAL


float
vtkLODProp3D::GetLODIndexEstimatedRenderTime(index)
		int 	index
		CODE:
		RETVAL = THIS->GetLODIndexEstimatedRenderTime(index);
		OUTPUT:
		RETVAL


float
vtkLODProp3D::GetLODIndexLevel(index)
		int 	index
		CODE:
		RETVAL = THIS->GetLODIndexLevel(index);
		OUTPUT:
		RETVAL


float
vtkLODProp3D::GetLODLevel(id)
		int 	id
		CODE:
		RETVAL = THIS->GetLODLevel(id);
		OUTPUT:
		RETVAL


vtkAbstractMapper3D *
vtkLODProp3D::GetLODMapper(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractMapper3D";
		CODE:
		RETVAL = THIS->GetLODMapper(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLODProp3D::GetLODMapper\n");



int
vtkLODProp3D::GetLastRenderedLODID()
		CODE:
		RETVAL = THIS->GetLastRenderedLODID();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetPickLODID()
		CODE:
		RETVAL = THIS->GetPickLODID();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetSelectedLODID()
		CODE:
		RETVAL = THIS->GetSelectedLODID();
		OUTPUT:
		RETVAL


int
vtkLODProp3D::GetSelectedPickLODID()
		CODE:
		RETVAL = THIS->GetSelectedPickLODID();
		OUTPUT:
		RETVAL


static vtkLODProp3D*
vtkLODProp3D::New()
		CODE:
		RETVAL = vtkLODProp3D::New();
		OUTPUT:
		RETVAL


void
vtkLODProp3D::RemoveLOD(id)
		int 	id
		CODE:
		THIS->RemoveLOD(id);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetAutomaticLODSelection(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticLODSelection(arg1);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetAutomaticPickLODSelection(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomaticPickLODSelection(arg1);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetLODBackfaceProperty(id, t)
		int 	id
		vtkProperty *	t
		CODE:
		THIS->SetLODBackfaceProperty(id, t);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetLODLevel(id, level)
		int 	id
		float 	level
		CODE:
		THIS->SetLODLevel(id, level);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetLODMapper(arg1 = 0, arg2 = 0)
	CASE: items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::VolumeMapper")
		int 	arg1
		vtkVolumeMapper *	arg2
		CODE:
		THIS->SetLODMapper(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::Mapper")
		int 	arg1
		vtkMapper *	arg2
		CODE:
		THIS->SetLODMapper(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLODProp3D::SetLODMapper\n");



void
vtkLODProp3D::SetLODProperty(arg1 = 0, arg2 = 0)
	CASE: items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::VolumeProperty")
		int 	arg1
		vtkVolumeProperty *	arg2
		CODE:
		THIS->SetLODProperty(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::Property")
		int 	arg1
		vtkProperty *	arg2
		CODE:
		THIS->SetLODProperty(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLODProp3D::SetLODProperty\n");



void
vtkLODProp3D::SetLODTexture(id, t)
		int 	id
		vtkTexture *	t
		CODE:
		THIS->SetLODTexture(id, t);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetPickMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetPickMethod",0), newRV(func), 0);
		}
		THIS->SetPickMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetSelectedLODID(arg1)
		int 	arg1
		CODE:
		THIS->SetSelectedLODID(arg1);
		XSRETURN_EMPTY;


void
vtkLODProp3D::SetSelectedPickLODID(id)
		int 	id
		CODE:
		THIS->SetSelectedPickLODID(id);
		XSRETURN_EMPTY;


void
vtkLODProp3D::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::LabeledDataMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLabeledDataMapper::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


int
vtkLabeledDataMapper::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


const char *
vtkLabeledDataMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFieldDataArray()
		CODE:
		RETVAL = THIS->GetFieldDataArray();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFieldDataArrayMaxValue()
		CODE:
		RETVAL = THIS->GetFieldDataArrayMaxValue();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFieldDataArrayMinValue()
		CODE:
		RETVAL = THIS->GetFieldDataArrayMinValue();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFontSize()
		CODE:
		RETVAL = THIS->GetFontSize();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFontSizeMaxValue()
		CODE:
		RETVAL = THIS->GetFontSizeMaxValue();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetFontSizeMinValue()
		CODE:
		RETVAL = THIS->GetFontSizeMinValue();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkLabeledDataMapper::GetInput()
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
vtkLabeledDataMapper::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


char *
vtkLabeledDataMapper::GetLabelFormat()
		CODE:
		RETVAL = THIS->GetLabelFormat();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetLabelMode()
		CODE:
		RETVAL = THIS->GetLabelMode();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetLabeledComponent()
		CODE:
		RETVAL = THIS->GetLabeledComponent();
		OUTPUT:
		RETVAL


int
vtkLabeledDataMapper::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


void
vtkLabeledDataMapper::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


static vtkLabeledDataMapper*
vtkLabeledDataMapper::New()
		CODE:
		RETVAL = vtkLabeledDataMapper::New();
		OUTPUT:
		RETVAL


void
vtkLabeledDataMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::RenderOverlay(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOverlay(viewport, actor);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetFieldDataArray(arg1)
		int 	arg1
		CODE:
		THIS->SetFieldDataArray(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetFontSize(arg1)
		int 	arg1
		CODE:
		THIS->SetFontSize(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetInput(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelFormat(arg1)
		char *	arg1
		CODE:
		THIS->SetLabelFormat(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelMode(arg1)
		int 	arg1
		CODE:
		THIS->SetLabelMode(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelFieldData()
		CODE:
		THIS->SetLabelModeToLabelFieldData();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelIds()
		CODE:
		THIS->SetLabelModeToLabelIds();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelNormals()
		CODE:
		THIS->SetLabelModeToLabelNormals();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelScalars()
		CODE:
		THIS->SetLabelModeToLabelScalars();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelTCoords()
		CODE:
		THIS->SetLabelModeToLabelTCoords();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelTensors()
		CODE:
		THIS->SetLabelModeToLabelTensors();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabelModeToLabelVectors()
		CODE:
		THIS->SetLabelModeToLabelVectors();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetLabeledComponent(arg1)
		int 	arg1
		CODE:
		THIS->SetLabeledComponent(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkLabeledDataMapper::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Light PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLight::DeepCopy(light)
		vtkLight *	light
		CODE:
		THIS->DeepCopy(light);
		XSRETURN_EMPTY;


float  *
vtkLight::GetAttenuationValues()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAttenuationValues();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


const char *
vtkLight::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkLight::GetColor()
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


float
vtkLight::GetConeAngle()
		CODE:
		RETVAL = THIS->GetConeAngle();
		OUTPUT:
		RETVAL


float
vtkLight::GetExponent()
		CODE:
		RETVAL = THIS->GetExponent();
		OUTPUT:
		RETVAL


float  *
vtkLight::GetFocalPoint()
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


float
vtkLight::GetIntensity()
		CODE:
		RETVAL = THIS->GetIntensity();
		OUTPUT:
		RETVAL


int
vtkLight::GetLightType()
		CODE:
		RETVAL = THIS->GetLightType();
		OUTPUT:
		RETVAL


float  *
vtkLight::GetPosition()
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


int
vtkLight::GetPositional()
		CODE:
		RETVAL = THIS->GetPositional();
		OUTPUT:
		RETVAL


int
vtkLight::GetSwitch()
		CODE:
		RETVAL = THIS->GetSwitch();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkLight::GetTransformMatrix()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetTransformMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkLight::GetTransformedFocalPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GetTransformedFocalPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTransformedFocalPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::GetTransformedFocalPoint\n");



float *
vtkLight::GetTransformedPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GetTransformedPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTransformedPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::GetTransformedPosition\n");



int
vtkLight::LightTypeIsCameraLight()
		CODE:
		RETVAL = THIS->LightTypeIsCameraLight();
		OUTPUT:
		RETVAL


int
vtkLight::LightTypeIsHeadlight()
		CODE:
		RETVAL = THIS->LightTypeIsHeadlight();
		OUTPUT:
		RETVAL


int
vtkLight::LightTypeIsSceneLight()
		CODE:
		RETVAL = THIS->LightTypeIsSceneLight();
		OUTPUT:
		RETVAL


static vtkLight*
vtkLight::New()
		CODE:
		RETVAL = vtkLight::New();
		OUTPUT:
		RETVAL


void
vtkLight::PositionalOff()
		CODE:
		THIS->PositionalOff();
		XSRETURN_EMPTY;


void
vtkLight::PositionalOn()
		CODE:
		THIS->PositionalOn();
		XSRETURN_EMPTY;


void
vtkLight::Render(arg1, arg2)
		vtkRenderer *	arg1
		int 	arg2
		CODE:
		THIS->Render(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkLight::SetAttenuationValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetAttenuationValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::SetAttenuationValues\n");



void
vtkLight::SetColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::SetColor\n");



void
vtkLight::SetConeAngle(arg1)
		float 	arg1
		CODE:
		THIS->SetConeAngle(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SetDirectionAngle(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetDirectionAngle(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::SetDirectionAngle\n");



void
vtkLight::SetExponent(arg1)
		float 	arg1
		CODE:
		THIS->SetExponent(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SetFocalPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetFocalPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::SetFocalPoint\n");



void
vtkLight::SetIntensity(arg1)
		float 	arg1
		CODE:
		THIS->SetIntensity(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SetLightType(arg1)
		int 	arg1
		CODE:
		THIS->SetLightType(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SetLightTypeToCameraLight()
		CODE:
		THIS->SetLightTypeToCameraLight();
		XSRETURN_EMPTY;


void
vtkLight::SetLightTypeToHeadlight()
		CODE:
		THIS->SetLightTypeToHeadlight();
		XSRETURN_EMPTY;


void
vtkLight::SetLightTypeToSceneLight()
		CODE:
		THIS->SetLightTypeToSceneLight();
		XSRETURN_EMPTY;


void
vtkLight::SetPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLight::SetPosition\n");



void
vtkLight::SetPositional(arg1)
		int 	arg1
		CODE:
		THIS->SetPositional(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SetSwitch(arg1)
		int 	arg1
		CODE:
		THIS->SetSwitch(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SetTransformMatrix(arg1)
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->SetTransformMatrix(arg1);
		XSRETURN_EMPTY;


void
vtkLight::SwitchOff()
		CODE:
		THIS->SwitchOff();
		XSRETURN_EMPTY;


void
vtkLight::SwitchOn()
		CODE:
		THIS->SwitchOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::LightCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLightCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkLight *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLightCollection::AddItem\n");



const char *
vtkLightCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkLight *
vtkLightCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLight";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkLightCollection*
vtkLightCollection::New()
		CODE:
		RETVAL = vtkLightCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::LightKit PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLightKit::AddLightsToRenderer(renderer)
		vtkRenderer *	renderer
		CODE:
		THIS->AddLightsToRenderer(renderer);
		XSRETURN_EMPTY;


void
vtkLightKit::DeepCopy(kit)
		vtkLightKit *	kit
		CODE:
		THIS->DeepCopy(kit);
		XSRETURN_EMPTY;


const char *
vtkLightKit::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkLightKit::GetFillLightAngle()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFillLightAngle();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float
vtkLightKit::GetFillLightAzimuth()
		CODE:
		RETVAL = THIS->GetFillLightAzimuth();
		OUTPUT:
		RETVAL


float  *
vtkLightKit::GetFillLightColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetFillLightColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkLightKit::GetFillLightElevation()
		CODE:
		RETVAL = THIS->GetFillLightElevation();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetFillLightWarmth()
		CODE:
		RETVAL = THIS->GetFillLightWarmth();
		OUTPUT:
		RETVAL


float  *
vtkLightKit::GetHeadlightColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetHeadlightColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkLightKit::GetHeadlightWarmth()
		CODE:
		RETVAL = THIS->GetHeadlightWarmth();
		OUTPUT:
		RETVAL


float  *
vtkLightKit::GetKeyLightAngle()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKeyLightAngle();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float
vtkLightKit::GetKeyLightAzimuth()
		CODE:
		RETVAL = THIS->GetKeyLightAzimuth();
		OUTPUT:
		RETVAL


float  *
vtkLightKit::GetKeyLightColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetKeyLightColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkLightKit::GetKeyLightElevation()
		CODE:
		RETVAL = THIS->GetKeyLightElevation();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyLightIntensity()
		CODE:
		RETVAL = THIS->GetKeyLightIntensity();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyLightWarmth()
		CODE:
		RETVAL = THIS->GetKeyLightWarmth();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyToFillRatio()
		CODE:
		RETVAL = THIS->GetKeyToFillRatio();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyToFillRatioMaxValue()
		CODE:
		RETVAL = THIS->GetKeyToFillRatioMaxValue();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyToFillRatioMinValue()
		CODE:
		RETVAL = THIS->GetKeyToFillRatioMinValue();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyToHeadRatio()
		CODE:
		RETVAL = THIS->GetKeyToHeadRatio();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyToHeadRatioMaxValue()
		CODE:
		RETVAL = THIS->GetKeyToHeadRatioMaxValue();
		OUTPUT:
		RETVAL


float
vtkLightKit::GetKeyToHeadRatioMinValue()
		CODE:
		RETVAL = THIS->GetKeyToHeadRatioMinValue();
		OUTPUT:
		RETVAL


int
vtkLightKit::GetMaintainLuminance()
		CODE:
		RETVAL = THIS->GetMaintainLuminance();
		OUTPUT:
		RETVAL


void
vtkLightKit::MaintainLuminanceOff()
		CODE:
		THIS->MaintainLuminanceOff();
		XSRETURN_EMPTY;


void
vtkLightKit::MaintainLuminanceOn()
		CODE:
		THIS->MaintainLuminanceOn();
		XSRETURN_EMPTY;


void
vtkLightKit::Modified()
		CODE:
		THIS->Modified();
		XSRETURN_EMPTY;


static vtkLightKit*
vtkLightKit::New()
		CODE:
		RETVAL = vtkLightKit::New();
		OUTPUT:
		RETVAL


void
vtkLightKit::RemoveLightsFromRenderer(renderer)
		vtkRenderer *	renderer
		CODE:
		THIS->RemoveLightsFromRenderer(renderer);
		XSRETURN_EMPTY;


void
vtkLightKit::SetFillLightAngle(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetFillLightAngle(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLightKit::SetFillLightAngle\n");



void
vtkLightKit::SetFillLightAzimuth(x)
		float 	x
		CODE:
		THIS->SetFillLightAzimuth(x);
		XSRETURN_EMPTY;


void
vtkLightKit::SetFillLightElevation(x)
		float 	x
		CODE:
		THIS->SetFillLightElevation(x);
		XSRETURN_EMPTY;


void
vtkLightKit::SetFillLightWarmth(arg1)
		float 	arg1
		CODE:
		THIS->SetFillLightWarmth(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::SetHeadlightWarmth(arg1)
		float 	arg1
		CODE:
		THIS->SetHeadlightWarmth(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::SetKeyLightAngle(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetKeyLightAngle(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLightKit::SetKeyLightAngle\n");



void
vtkLightKit::SetKeyLightAzimuth(x)
		float 	x
		CODE:
		THIS->SetKeyLightAzimuth(x);
		XSRETURN_EMPTY;


void
vtkLightKit::SetKeyLightElevation(x)
		float 	x
		CODE:
		THIS->SetKeyLightElevation(x);
		XSRETURN_EMPTY;


void
vtkLightKit::SetKeyLightIntensity(arg1)
		float 	arg1
		CODE:
		THIS->SetKeyLightIntensity(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::SetKeyLightWarmth(arg1)
		float 	arg1
		CODE:
		THIS->SetKeyLightWarmth(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::SetKeyToFillRatio(arg1)
		float 	arg1
		CODE:
		THIS->SetKeyToFillRatio(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::SetKeyToHeadRatio(arg1)
		float 	arg1
		CODE:
		THIS->SetKeyToHeadRatio(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::SetMaintainLuminance(arg1)
		int 	arg1
		CODE:
		THIS->SetMaintainLuminance(arg1);
		XSRETURN_EMPTY;


void
vtkLightKit::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Mapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMapper::ColorByArrayComponent(arg1 = 0, arg2 = 0)
	CASE: items == 3 && SvPOK(ST(1))
		char *	arg1
		int 	arg2
		CODE:
		THIS->ColorByArrayComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && SvIOK(ST(1))
		int 	arg1
		int 	arg2
		CODE:
		THIS->ColorByArrayComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMapper::ColorByArrayComponent\n");



void
vtkMapper::CreateDefaultLookupTable()
		CODE:
		THIS->CreateDefaultLookupTable();
		XSRETURN_EMPTY;


int
vtkMapper::GetArrayAccessMode()
		CODE:
		RETVAL = THIS->GetArrayAccessMode();
		OUTPUT:
		RETVAL


int
vtkMapper::GetArrayComponent()
		CODE:
		RETVAL = THIS->GetArrayComponent();
		OUTPUT:
		RETVAL


int
vtkMapper::GetArrayId()
		CODE:
		RETVAL = THIS->GetArrayId();
		OUTPUT:
		RETVAL


char *
vtkMapper::GetArrayName()
		CODE:
		RETVAL = THIS->GetArrayName();
		OUTPUT:
		RETVAL


float *
vtkMapper::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkMapper::GetBounds\n");



const char *
vtkMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMapper::GetColorMode()
		CODE:
		RETVAL = THIS->GetColorMode();
		OUTPUT:
		RETVAL


const char *
vtkMapper::GetColorModeAsString()
		CODE:
		RETVAL = THIS->GetColorModeAsString();
		OUTPUT:
		RETVAL


static int
vtkMapper::GetGlobalImmediateModeRendering()
		CODE:
		RETVAL = vtkMapper::GetGlobalImmediateModeRendering();
		OUTPUT:
		RETVAL


int
vtkMapper::GetImmediateModeRendering()
		CODE:
		RETVAL = THIS->GetImmediateModeRendering();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkMapper::GetInputAsDataSet()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInputAsDataSet();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkScalarsToColors *
vtkMapper::GetLookupTable()
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
vtkMapper::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkMapper::GetRenderTime()
		CODE:
		RETVAL = THIS->GetRenderTime();
		OUTPUT:
		RETVAL


static int
vtkMapper::GetResolveCoincidentTopology()
		CODE:
		RETVAL = vtkMapper::GetResolveCoincidentTopology();
		OUTPUT:
		RETVAL


static void
vtkMapper::GetResolveCoincidentTopologyPolygonOffsetParameters(factor, units)
		float 	factor
		float 	units
		CODE:
		vtkMapper::GetResolveCoincidentTopologyPolygonOffsetParameters(factor, units);
		XSRETURN_EMPTY;
		OUTPUT:
		factor
		units


static double
vtkMapper::GetResolveCoincidentTopologyZShift()
		CODE:
		RETVAL = vtkMapper::GetResolveCoincidentTopologyZShift();
		OUTPUT:
		RETVAL


int
vtkMapper::GetScalarMode()
		CODE:
		RETVAL = THIS->GetScalarMode();
		OUTPUT:
		RETVAL


const char *
vtkMapper::GetScalarModeAsString()
		CODE:
		RETVAL = THIS->GetScalarModeAsString();
		OUTPUT:
		RETVAL


float  *
vtkMapper::GetScalarRange()
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


int
vtkMapper::GetScalarVisibility()
		CODE:
		RETVAL = THIS->GetScalarVisibility();
		OUTPUT:
		RETVAL


int
vtkMapper::GetUseLookupTableScalarRange()
		CODE:
		RETVAL = THIS->GetUseLookupTableScalarRange();
		OUTPUT:
		RETVAL


static void
vtkMapper::GlobalImmediateModeRenderingOff()
		CODE:
		vtkMapper::GlobalImmediateModeRenderingOff();
		XSRETURN_EMPTY;


static void
vtkMapper::GlobalImmediateModeRenderingOn()
		CODE:
		vtkMapper::GlobalImmediateModeRenderingOn();
		XSRETURN_EMPTY;


void
vtkMapper::ImmediateModeRenderingOff()
		CODE:
		THIS->ImmediateModeRenderingOff();
		XSRETURN_EMPTY;


void
vtkMapper::ImmediateModeRenderingOn()
		CODE:
		THIS->ImmediateModeRenderingOn();
		XSRETURN_EMPTY;


vtkUnsignedCharArray *
vtkMapper::MapScalars(alpha)
		float 	alpha
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnsignedCharArray";
		CODE:
		RETVAL = THIS->MapScalars(alpha);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkMapper::Render(ren, a)
		vtkRenderer *	ren
		vtkActor *	a
		CODE:
		THIS->Render(ren, a);
		XSRETURN_EMPTY;


void
vtkMapper::ScalarVisibilityOff()
		CODE:
		THIS->ScalarVisibilityOff();
		XSRETURN_EMPTY;


void
vtkMapper::ScalarVisibilityOn()
		CODE:
		THIS->ScalarVisibilityOn();
		XSRETURN_EMPTY;


void
vtkMapper::SetColorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetColorMode(arg1);
		XSRETURN_EMPTY;


void
vtkMapper::SetColorModeToDefault()
		CODE:
		THIS->SetColorModeToDefault();
		XSRETURN_EMPTY;


void
vtkMapper::SetColorModeToMapScalars()
		CODE:
		THIS->SetColorModeToMapScalars();
		XSRETURN_EMPTY;


static void
vtkMapper::SetGlobalImmediateModeRendering(val)
		int 	val
		CODE:
		vtkMapper::SetGlobalImmediateModeRendering(val);
		XSRETURN_EMPTY;


void
vtkMapper::SetImmediateModeRendering(arg1)
		int 	arg1
		CODE:
		THIS->SetImmediateModeRendering(arg1);
		XSRETURN_EMPTY;


void
vtkMapper::SetLookupTable(lut)
		vtkScalarsToColors *	lut
		CODE:
		THIS->SetLookupTable(lut);
		XSRETURN_EMPTY;


void
vtkMapper::SetRenderTime(time)
		float 	time
		CODE:
		THIS->SetRenderTime(time);
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopology(val)
		int 	val
		CODE:
		vtkMapper::SetResolveCoincidentTopology(val);
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopologyPolygonOffsetParameters(factor, units)
		float 	factor
		float 	units
		CODE:
		vtkMapper::SetResolveCoincidentTopologyPolygonOffsetParameters(factor, units);
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopologyToDefault()
		CODE:
		vtkMapper::SetResolveCoincidentTopologyToDefault();
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopologyToOff()
		CODE:
		vtkMapper::SetResolveCoincidentTopologyToOff();
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopologyToPolygonOffset()
		CODE:
		vtkMapper::SetResolveCoincidentTopologyToPolygonOffset();
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopologyToShiftZBuffer()
		CODE:
		vtkMapper::SetResolveCoincidentTopologyToShiftZBuffer();
		XSRETURN_EMPTY;


static void
vtkMapper::SetResolveCoincidentTopologyZShift(val)
		double 	val
		CODE:
		vtkMapper::SetResolveCoincidentTopologyZShift(val);
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarMode(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarMode(arg1);
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarModeToDefault()
		CODE:
		THIS->SetScalarModeToDefault();
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarModeToUseCellData()
		CODE:
		THIS->SetScalarModeToUseCellData();
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarModeToUseCellFieldData()
		CODE:
		THIS->SetScalarModeToUseCellFieldData();
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarModeToUsePointData()
		CODE:
		THIS->SetScalarModeToUsePointData();
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarModeToUsePointFieldData()
		CODE:
		THIS->SetScalarModeToUsePointFieldData();
		XSRETURN_EMPTY;


void
vtkMapper::SetScalarRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetScalarRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMapper::SetScalarRange\n");



void
vtkMapper::SetScalarVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkMapper::SetUseLookupTableScalarRange(arg1)
		int 	arg1
		CODE:
		THIS->SetUseLookupTableScalarRange(arg1);
		XSRETURN_EMPTY;


void
vtkMapper::ShallowCopy(m)
		vtkAbstractMapper *	m
		CODE:
		THIS->ShallowCopy(m);
		XSRETURN_EMPTY;


void
vtkMapper::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkMapper::UseLookupTableScalarRangeOff()
		CODE:
		THIS->UseLookupTableScalarRangeOff();
		XSRETURN_EMPTY;


void
vtkMapper::UseLookupTableScalarRangeOn()
		CODE:
		THIS->UseLookupTableScalarRangeOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MapperCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMapperCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkMapper *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMapperCollection::AddItem\n");



const char *
vtkMapperCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkMapper *
vtkMapperCollection::GetLastItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMapper";
		CODE:
		RETVAL = THIS->GetLastItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkMapper *
vtkMapperCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMapper";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkMapperCollection*
vtkMapperCollection::New()
		CODE:
		RETVAL = vtkMapperCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OBJExporter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOBJExporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkOBJExporter::GetFilePrefix()
		CODE:
		RETVAL = THIS->GetFilePrefix();
		OUTPUT:
		RETVAL


static vtkOBJExporter*
vtkOBJExporter::New()
		CODE:
		RETVAL = vtkOBJExporter::New();
		OUTPUT:
		RETVAL


void
vtkOBJExporter::SetFilePrefix(arg1)
		char *	arg1
		CODE:
		THIS->SetFilePrefix(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OOGLExporter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOOGLExporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkOOGLExporter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


static vtkOOGLExporter*
vtkOOGLExporter::New()
		CODE:
		RETVAL = vtkOOGLExporter::New();
		OUTPUT:
		RETVAL


void
vtkOOGLExporter::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ParallelCoordinatesActor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkParallelCoordinatesActor::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


int
vtkParallelCoordinatesActor::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


const char *
vtkParallelCoordinatesActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetIndependentVariables()
		CODE:
		RETVAL = THIS->GetIndependentVariables();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetIndependentVariablesMaxValue()
		CODE:
		RETVAL = THIS->GetIndependentVariablesMaxValue();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetIndependentVariablesMinValue()
		CODE:
		RETVAL = THIS->GetIndependentVariablesMinValue();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkParallelCoordinatesActor::GetInput()
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
vtkParallelCoordinatesActor::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


char *
vtkParallelCoordinatesActor::GetLabelFormat()
		CODE:
		RETVAL = THIS->GetLabelFormat();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetNumberOfLabels()
		CODE:
		RETVAL = THIS->GetNumberOfLabels();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetNumberOfLabelsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMaxValue();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetNumberOfLabelsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMinValue();
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


char *
vtkParallelCoordinatesActor::GetTitle()
		CODE:
		RETVAL = THIS->GetTitle();
		OUTPUT:
		RETVAL


void
vtkParallelCoordinatesActor::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


static vtkParallelCoordinatesActor*
vtkParallelCoordinatesActor::New()
		CODE:
		RETVAL = vtkParallelCoordinatesActor::New();
		OUTPUT:
		RETVAL


void
vtkParallelCoordinatesActor::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


int
vtkParallelCoordinatesActor::RenderOpaqueGeometry(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(arg1);
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::RenderOverlay(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderOverlay(arg1);
		OUTPUT:
		RETVAL


int
vtkParallelCoordinatesActor::RenderTranslucentGeometry(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(arg1);
		OUTPUT:
		RETVAL


void
vtkParallelCoordinatesActor::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetIndependentVariables(arg1)
		int 	arg1
		CODE:
		THIS->SetIndependentVariables(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetIndependentVariablesToColumns()
		CODE:
		THIS->SetIndependentVariablesToColumns();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetIndependentVariablesToRows()
		CODE:
		THIS->SetIndependentVariablesToRows();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetInput(arg1)
		vtkDataObject *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetLabelFormat(arg1)
		char *	arg1
		CODE:
		THIS->SetLabelFormat(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetNumberOfLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfLabels(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::SetTitle(arg1)
		char *	arg1
		CODE:
		THIS->SetTitle(arg1);
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkParallelCoordinatesActor::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Picker PREFIX = vtk

PROTOTYPES: DISABLE



vtkActorCollection *
vtkPicker::GetActors()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActorCollection";
		CODE:
		RETVAL = THIS->GetActors();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkPicker::GetDataSet()
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


vtkAbstractMapper3D *
vtkPicker::GetMapper()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractMapper3D";
		CODE:
		RETVAL = THIS->GetMapper();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkPicker::GetMapperPosition()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMapperPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkPoints *
vtkPicker::GetPickedPositions()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetPickedPositions();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkProp3DCollection *
vtkPicker::GetProp3Ds()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp3DCollection";
		CODE:
		RETVAL = THIS->GetProp3Ds();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkPicker::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


static vtkPicker*
vtkPicker::New()
		CODE:
		RETVAL = vtkPicker::New();
		OUTPUT:
		RETVAL


int
vtkPicker::Pick(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		vtkRenderer *	arg4
		CODE:
		RETVAL = THIS->Pick(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPicker::Pick\n");



void
vtkPicker::SetTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::PointPicker PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPointPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


long
vtkPointPicker::GetPointId()
		CODE:
		RETVAL = THIS->GetPointId();
		OUTPUT:
		RETVAL


static vtkPointPicker*
vtkPointPicker::New()
		CODE:
		RETVAL = vtkPointPicker::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::PolyDataMapper PREFIX = vtk

PROTOTYPES: DISABLE



float *
vtkPolyDataMapper::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkPolyDataMapper::GetBounds\n");



const char *
vtkPolyDataMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper::GetGhostLevel()
		CODE:
		RETVAL = THIS->GetGhostLevel();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataMapper::GetInput()
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


int
vtkPolyDataMapper::GetNumberOfPieces()
		CODE:
		RETVAL = THIS->GetNumberOfPieces();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper::GetNumberOfSubPieces()
		CODE:
		RETVAL = THIS->GetNumberOfSubPieces();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper::GetPiece()
		CODE:
		RETVAL = THIS->GetPiece();
		OUTPUT:
		RETVAL


static vtkPolyDataMapper*
vtkPolyDataMapper::New()
		CODE:
		RETVAL = vtkPolyDataMapper::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataMapper::Render(ren, act)
		vtkRenderer *	ren
		vtkActor *	act
		CODE:
		THIS->Render(ren, act);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::RenderPiece(ren, act)
		vtkRenderer *	ren
		vtkActor *	act
		CODE:
		THIS->RenderPiece(ren, act);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::SetGhostLevel(arg1)
		int 	arg1
		CODE:
		THIS->SetGhostLevel(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::SetInput(in)
		vtkPolyData *	in
		CODE:
		THIS->SetInput(in);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::SetNumberOfPieces(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfPieces(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::SetNumberOfSubPieces(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfSubPieces(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::SetPiece(arg1)
		int 	arg1
		CODE:
		THIS->SetPiece(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::ShallowCopy(m)
		vtkAbstractMapper *	m
		CODE:
		THIS->ShallowCopy(m);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::PolyDataMapper2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyDataMapper2D::ColorByArrayComponent(arg1 = 0, arg2 = 0)
	CASE: items == 3 && SvPOK(ST(1))
		char *	arg1
		int 	arg2
		CODE:
		THIS->ColorByArrayComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && SvIOK(ST(1))
		int 	arg1
		int 	arg2
		CODE:
		THIS->ColorByArrayComponent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyDataMapper2D::ColorByArrayComponent\n");



void
vtkPolyDataMapper2D::CreateDefaultLookupTable()
		CODE:
		THIS->CreateDefaultLookupTable();
		XSRETURN_EMPTY;


int
vtkPolyDataMapper2D::GetArrayAccessMode()
		CODE:
		RETVAL = THIS->GetArrayAccessMode();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper2D::GetArrayComponent()
		CODE:
		RETVAL = THIS->GetArrayComponent();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper2D::GetArrayId()
		CODE:
		RETVAL = THIS->GetArrayId();
		OUTPUT:
		RETVAL


char *
vtkPolyDataMapper2D::GetArrayName()
		CODE:
		RETVAL = THIS->GetArrayName();
		OUTPUT:
		RETVAL


const char *
vtkPolyDataMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper2D::GetColorMode()
		CODE:
		RETVAL = THIS->GetColorMode();
		OUTPUT:
		RETVAL


const char *
vtkPolyDataMapper2D::GetColorModeAsString()
		CODE:
		RETVAL = THIS->GetColorModeAsString();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataMapper2D::GetInput()
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


vtkScalarsToColors *
vtkPolyDataMapper2D::GetLookupTable()
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
vtkPolyDataMapper2D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper2D::GetScalarMode()
		CODE:
		RETVAL = THIS->GetScalarMode();
		OUTPUT:
		RETVAL


float  *
vtkPolyDataMapper2D::GetScalarRange()
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


int
vtkPolyDataMapper2D::GetScalarVisibility()
		CODE:
		RETVAL = THIS->GetScalarVisibility();
		OUTPUT:
		RETVAL


vtkCoordinate *
vtkPolyDataMapper2D::GetTransformCoordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetTransformCoordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPolyDataMapper2D::GetUseLookupTableScalarRange()
		CODE:
		RETVAL = THIS->GetUseLookupTableScalarRange();
		OUTPUT:
		RETVAL


vtkUnsignedCharArray *
vtkPolyDataMapper2D::MapScalars(alpha)
		float 	alpha
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnsignedCharArray";
		CODE:
		RETVAL = THIS->MapScalars(alpha);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPolyDataMapper2D*
vtkPolyDataMapper2D::New()
		CODE:
		RETVAL = vtkPolyDataMapper2D::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataMapper2D::ScalarVisibilityOff()
		CODE:
		THIS->ScalarVisibilityOff();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::ScalarVisibilityOn()
		CODE:
		THIS->ScalarVisibilityOn();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetColorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetColorMode(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetColorModeToDefault()
		CODE:
		THIS->SetColorModeToDefault();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetColorModeToMapScalars()
		CODE:
		THIS->SetColorModeToMapScalars();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetInput(arg1)
		vtkPolyData *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetLookupTable(lut)
		vtkScalarsToColors *	lut
		CODE:
		THIS->SetLookupTable(lut);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarMode(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarMode(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarModeToDefault()
		CODE:
		THIS->SetScalarModeToDefault();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarModeToUseCellData()
		CODE:
		THIS->SetScalarModeToUseCellData();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarModeToUseCellFieldData()
		CODE:
		THIS->SetScalarModeToUseCellFieldData();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarModeToUsePointData()
		CODE:
		THIS->SetScalarModeToUsePointData();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarModeToUsePointFieldData()
		CODE:
		THIS->SetScalarModeToUsePointFieldData();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetScalarRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetScalarRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyDataMapper2D::SetScalarRange\n");



void
vtkPolyDataMapper2D::SetScalarVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetTransformCoordinate(arg1)
		vtkCoordinate *	arg1
		CODE:
		THIS->SetTransformCoordinate(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::SetUseLookupTableScalarRange(arg1)
		int 	arg1
		CODE:
		THIS->SetUseLookupTableScalarRange(arg1);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::ShallowCopy(m)
		vtkAbstractMapper *	m
		CODE:
		THIS->ShallowCopy(m);
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::UseLookupTableScalarRangeOff()
		CODE:
		THIS->UseLookupTableScalarRangeOff();
		XSRETURN_EMPTY;


void
vtkPolyDataMapper2D::UseLookupTableScalarRangeOn()
		CODE:
		THIS->UseLookupTableScalarRangeOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Prop3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProp3D::AddOrientation(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->AddOrientation(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::AddOrientation\n");



void
vtkProp3D::AddPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->AddPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::AddPosition\n");



void
vtkProp3D::ComputeMatrix()
		CODE:
		THIS->ComputeMatrix();
		XSRETURN_EMPTY;


float *
vtkProp3D::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkProp3D::GetBounds\n");



float *
vtkProp3D::GetCenter()
		PREINIT:
		float * retval;
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
vtkProp3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkProp3D::GetIsIdentity()
		CODE:
		RETVAL = THIS->GetIsIdentity();
		OUTPUT:
		RETVAL


float
vtkProp3D::GetLength()
		CODE:
		RETVAL = THIS->GetLength();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkProp3D::GetMatrix(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->GetMatrix(arg1);
		XSRETURN_EMPTY;
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::GetMatrix\n");



float *
vtkProp3D::GetOrientation()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::GetOrientation\n");



float *
vtkProp3D::GetOrientationWXYZ()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientationWXYZ();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


float  *
vtkProp3D::GetOrigin()
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
vtkProp3D::GetPosition()
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
vtkProp3D::GetScale()
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


vtkMatrix4x4 *
vtkProp3D::GetUserMatrix()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetUserMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkLinearTransform *
vtkProp3D::GetUserTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLinearTransform";
		CODE:
		RETVAL = THIS->GetUserTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkProp3D::GetXRange()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetXRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkProp3D::GetYRange()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetYRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkProp3D::GetZRange()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetZRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


void
vtkProp3D::InitPathTraversal()
		CODE:
		THIS->InitPathTraversal();
		XSRETURN_EMPTY;


void
vtkProp3D::PokeMatrix(matrix)
		vtkMatrix4x4 *	matrix
		CODE:
		THIS->PokeMatrix(matrix);
		XSRETURN_EMPTY;


void
vtkProp3D::RotateWXYZ(arg1, arg2, arg3, arg4)
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->RotateWXYZ(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;


void
vtkProp3D::RotateX(arg1)
		float 	arg1
		CODE:
		THIS->RotateX(arg1);
		XSRETURN_EMPTY;


void
vtkProp3D::RotateY(arg1)
		float 	arg1
		CODE:
		THIS->RotateY(arg1);
		XSRETURN_EMPTY;


void
vtkProp3D::RotateZ(arg1)
		float 	arg1
		CODE:
		THIS->RotateZ(arg1);
		XSRETURN_EMPTY;


void
vtkProp3D::SetOrientation(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrientation(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::SetOrientation\n");



void
vtkProp3D::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::SetOrigin\n");



void
vtkProp3D::SetPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::SetPosition\n");



void
vtkProp3D::SetScale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetScale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 2
		float 	arg1
		CODE:
		THIS->SetScale(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3D::SetScale\n");



void
vtkProp3D::SetUserMatrix(matrix)
		vtkMatrix4x4 *	matrix
		CODE:
		THIS->SetUserMatrix(matrix);
		XSRETURN_EMPTY;


void
vtkProp3D::SetUserTransform(transform)
		vtkLinearTransform *	transform
		CODE:
		THIS->SetUserTransform(transform);
		XSRETURN_EMPTY;


void
vtkProp3D::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Prop3DCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProp3DCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkProp3D *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProp3DCollection::AddItem\n");



const char *
vtkProp3DCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkProp3D *
vtkProp3DCollection::GetLastProp3D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp3D";
		CODE:
		RETVAL = THIS->GetLastProp3D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkProp3D *
vtkProp3DCollection::GetNextProp3D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp3D";
		CODE:
		RETVAL = THIS->GetNextProp3D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkProp3DCollection*
vtkProp3DCollection::New()
		CODE:
		RETVAL = vtkProp3DCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::PropPicker PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPropPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPropPicker*
vtkPropPicker::New()
		CODE:
		RETVAL = vtkPropPicker::New();
		OUTPUT:
		RETVAL


int
vtkPropPicker::Pick(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		vtkRenderer *	arg4
		CODE:
		RETVAL = THIS->Pick(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPropPicker::Pick\n");



int
vtkPropPicker::PickProp(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		vtkRenderer *	arg3
		vtkPropCollection *	arg4
		CODE:
		RETVAL = THIS->PickProp(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE: items == 4
		float 	arg1
		float 	arg2
		vtkRenderer *	arg3
		CODE:
		RETVAL = THIS->PickProp(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPropPicker::PickProp\n");


MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Property PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProperty::BackfaceCullingOff()
		CODE:
		THIS->BackfaceCullingOff();
		XSRETURN_EMPTY;


void
vtkProperty::BackfaceCullingOn()
		CODE:
		THIS->BackfaceCullingOn();
		XSRETURN_EMPTY;


void
vtkProperty::BackfaceRender(arg1, arg2)
		vtkActor *	arg1
		vtkRenderer *	arg2
		CODE:
		THIS->BackfaceRender(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkProperty::DeepCopy(p)
		vtkProperty *	p
		CODE:
		THIS->DeepCopy(p);
		XSRETURN_EMPTY;


void
vtkProperty::EdgeVisibilityOff()
		CODE:
		THIS->EdgeVisibilityOff();
		XSRETURN_EMPTY;


void
vtkProperty::EdgeVisibilityOn()
		CODE:
		THIS->EdgeVisibilityOn();
		XSRETURN_EMPTY;


void
vtkProperty::FrontfaceCullingOff()
		CODE:
		THIS->FrontfaceCullingOff();
		XSRETURN_EMPTY;


void
vtkProperty::FrontfaceCullingOn()
		CODE:
		THIS->FrontfaceCullingOn();
		XSRETURN_EMPTY;


float
vtkProperty::GetAmbient()
		CODE:
		RETVAL = THIS->GetAmbient();
		OUTPUT:
		RETVAL


float  *
vtkProperty::GetAmbientColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAmbientColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkProperty::GetAmbientMaxValue()
		CODE:
		RETVAL = THIS->GetAmbientMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetAmbientMinValue()
		CODE:
		RETVAL = THIS->GetAmbientMinValue();
		OUTPUT:
		RETVAL


int
vtkProperty::GetBackfaceCulling()
		CODE:
		RETVAL = THIS->GetBackfaceCulling();
		OUTPUT:
		RETVAL


const char *
vtkProperty::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkProperty::GetColor()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty::GetColor\n");



float
vtkProperty::GetDiffuse()
		CODE:
		RETVAL = THIS->GetDiffuse();
		OUTPUT:
		RETVAL


float  *
vtkProperty::GetDiffuseColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDiffuseColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkProperty::GetDiffuseMaxValue()
		CODE:
		RETVAL = THIS->GetDiffuseMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetDiffuseMinValue()
		CODE:
		RETVAL = THIS->GetDiffuseMinValue();
		OUTPUT:
		RETVAL


float  *
vtkProperty::GetEdgeColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetEdgeColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkProperty::GetEdgeVisibility()
		CODE:
		RETVAL = THIS->GetEdgeVisibility();
		OUTPUT:
		RETVAL


int
vtkProperty::GetFrontfaceCulling()
		CODE:
		RETVAL = THIS->GetFrontfaceCulling();
		OUTPUT:
		RETVAL


int
vtkProperty::GetInterpolation()
		CODE:
		RETVAL = THIS->GetInterpolation();
		OUTPUT:
		RETVAL


char *
vtkProperty::GetInterpolationAsString()
		CODE:
		RETVAL = THIS->GetInterpolationAsString();
		OUTPUT:
		RETVAL


int
vtkProperty::GetInterpolationMaxValue()
		CODE:
		RETVAL = THIS->GetInterpolationMaxValue();
		OUTPUT:
		RETVAL


int
vtkProperty::GetInterpolationMinValue()
		CODE:
		RETVAL = THIS->GetInterpolationMinValue();
		OUTPUT:
		RETVAL


int
vtkProperty::GetLineStipplePattern()
		CODE:
		RETVAL = THIS->GetLineStipplePattern();
		OUTPUT:
		RETVAL


int
vtkProperty::GetLineStippleRepeatFactor()
		CODE:
		RETVAL = THIS->GetLineStippleRepeatFactor();
		OUTPUT:
		RETVAL


int
vtkProperty::GetLineStippleRepeatFactorMaxValue()
		CODE:
		RETVAL = THIS->GetLineStippleRepeatFactorMaxValue();
		OUTPUT:
		RETVAL


int
vtkProperty::GetLineStippleRepeatFactorMinValue()
		CODE:
		RETVAL = THIS->GetLineStippleRepeatFactorMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetLineWidth()
		CODE:
		RETVAL = THIS->GetLineWidth();
		OUTPUT:
		RETVAL


float
vtkProperty::GetLineWidthMaxValue()
		CODE:
		RETVAL = THIS->GetLineWidthMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetLineWidthMinValue()
		CODE:
		RETVAL = THIS->GetLineWidthMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetOpacity()
		CODE:
		RETVAL = THIS->GetOpacity();
		OUTPUT:
		RETVAL


float
vtkProperty::GetOpacityMaxValue()
		CODE:
		RETVAL = THIS->GetOpacityMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetOpacityMinValue()
		CODE:
		RETVAL = THIS->GetOpacityMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetPointSize()
		CODE:
		RETVAL = THIS->GetPointSize();
		OUTPUT:
		RETVAL


float
vtkProperty::GetPointSizeMaxValue()
		CODE:
		RETVAL = THIS->GetPointSizeMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetPointSizeMinValue()
		CODE:
		RETVAL = THIS->GetPointSizeMinValue();
		OUTPUT:
		RETVAL


int
vtkProperty::GetRepresentation()
		CODE:
		RETVAL = THIS->GetRepresentation();
		OUTPUT:
		RETVAL


char *
vtkProperty::GetRepresentationAsString()
		CODE:
		RETVAL = THIS->GetRepresentationAsString();
		OUTPUT:
		RETVAL


int
vtkProperty::GetRepresentationMaxValue()
		CODE:
		RETVAL = THIS->GetRepresentationMaxValue();
		OUTPUT:
		RETVAL


int
vtkProperty::GetRepresentationMinValue()
		CODE:
		RETVAL = THIS->GetRepresentationMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetSpecular()
		CODE:
		RETVAL = THIS->GetSpecular();
		OUTPUT:
		RETVAL


float  *
vtkProperty::GetSpecularColor()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSpecularColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkProperty::GetSpecularMaxValue()
		CODE:
		RETVAL = THIS->GetSpecularMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetSpecularMinValue()
		CODE:
		RETVAL = THIS->GetSpecularMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetSpecularPower()
		CODE:
		RETVAL = THIS->GetSpecularPower();
		OUTPUT:
		RETVAL


float
vtkProperty::GetSpecularPowerMaxValue()
		CODE:
		RETVAL = THIS->GetSpecularPowerMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty::GetSpecularPowerMinValue()
		CODE:
		RETVAL = THIS->GetSpecularPowerMinValue();
		OUTPUT:
		RETVAL


static vtkProperty*
vtkProperty::New()
		CODE:
		RETVAL = vtkProperty::New();
		OUTPUT:
		RETVAL


void
vtkProperty::Render(arg1, arg2)
		vtkActor *	arg1
		vtkRenderer *	arg2
		CODE:
		THIS->Render(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkProperty::SetAmbient(arg1)
		float 	arg1
		CODE:
		THIS->SetAmbient(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetAmbientColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetAmbientColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty::SetAmbientColor\n");



void
vtkProperty::SetBackfaceCulling(arg1)
		int 	arg1
		CODE:
		THIS->SetBackfaceCulling(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty::SetColor\n");



void
vtkProperty::SetDiffuse(arg1)
		float 	arg1
		CODE:
		THIS->SetDiffuse(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetDiffuseColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDiffuseColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty::SetDiffuseColor\n");



void
vtkProperty::SetEdgeColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetEdgeColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty::SetEdgeColor\n");



void
vtkProperty::SetEdgeVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetEdgeVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetFrontfaceCulling(arg1)
		int 	arg1
		CODE:
		THIS->SetFrontfaceCulling(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetInterpolation(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolation(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetInterpolationToFlat()
		CODE:
		THIS->SetInterpolationToFlat();
		XSRETURN_EMPTY;


void
vtkProperty::SetInterpolationToGouraud()
		CODE:
		THIS->SetInterpolationToGouraud();
		XSRETURN_EMPTY;


void
vtkProperty::SetInterpolationToPhong()
		CODE:
		THIS->SetInterpolationToPhong();
		XSRETURN_EMPTY;


void
vtkProperty::SetLineStipplePattern(arg1)
		int 	arg1
		CODE:
		THIS->SetLineStipplePattern(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetLineStippleRepeatFactor(arg1)
		int 	arg1
		CODE:
		THIS->SetLineStippleRepeatFactor(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetLineWidth(arg1)
		float 	arg1
		CODE:
		THIS->SetLineWidth(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetOpacity(arg1)
		float 	arg1
		CODE:
		THIS->SetOpacity(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetPointSize(arg1)
		float 	arg1
		CODE:
		THIS->SetPointSize(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetRepresentation(arg1)
		int 	arg1
		CODE:
		THIS->SetRepresentation(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetRepresentationToPoints()
		CODE:
		THIS->SetRepresentationToPoints();
		XSRETURN_EMPTY;


void
vtkProperty::SetRepresentationToSurface()
		CODE:
		THIS->SetRepresentationToSurface();
		XSRETURN_EMPTY;


void
vtkProperty::SetRepresentationToWireframe()
		CODE:
		THIS->SetRepresentationToWireframe();
		XSRETURN_EMPTY;


void
vtkProperty::SetSpecular(arg1)
		float 	arg1
		CODE:
		THIS->SetSpecular(arg1);
		XSRETURN_EMPTY;


void
vtkProperty::SetSpecularColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetSpecularColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty::SetSpecularColor\n");



void
vtkProperty::SetSpecularPower(arg1)
		float 	arg1
		CODE:
		THIS->SetSpecularPower(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RayCaster PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRayCaster::AutomaticScaleAdjustmentOff()
		CODE:
		THIS->AutomaticScaleAdjustmentOff();
		XSRETURN_EMPTY;


void
vtkRayCaster::AutomaticScaleAdjustmentOn()
		CODE:
		THIS->AutomaticScaleAdjustmentOn();
		XSRETURN_EMPTY;


void
vtkRayCaster::BilinearImageZoomOff()
		CODE:
		THIS->BilinearImageZoomOff();
		XSRETURN_EMPTY;


void
vtkRayCaster::BilinearImageZoomOn()
		CODE:
		THIS->BilinearImageZoomOn();
		XSRETURN_EMPTY;


int
vtkRayCaster::GetAutomaticScaleAdjustment()
		CODE:
		RETVAL = THIS->GetAutomaticScaleAdjustment();
		OUTPUT:
		RETVAL


float
vtkRayCaster::GetAutomaticScaleLowerLimit()
		CODE:
		RETVAL = THIS->GetAutomaticScaleLowerLimit();
		OUTPUT:
		RETVAL


int
vtkRayCaster::GetBilinearImageZoom()
		CODE:
		RETVAL = THIS->GetBilinearImageZoom();
		OUTPUT:
		RETVAL


const char *
vtkRayCaster::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkRayCaster::GetImageScale(level)
		int 	level
		CODE:
		RETVAL = THIS->GetImageScale(level);
		OUTPUT:
		RETVAL


int
vtkRayCaster::GetImageScaleCount()
		CODE:
		RETVAL = THIS->GetImageScaleCount();
		OUTPUT:
		RETVAL


int
vtkRayCaster::GetNumberOfSamplesTaken()
		CODE:
		RETVAL = THIS->GetNumberOfSamplesTaken();
		OUTPUT:
		RETVAL


int
vtkRayCaster::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


float *
vtkRayCaster::GetParallelIncrements()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetParallelIncrements();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkRayCaster::GetParallelStartPosition()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetParallelStartPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkRayCaster::GetSelectedImageScaleIndex(level)
		int 	level
		CODE:
		RETVAL = THIS->GetSelectedImageScaleIndex(level);
		OUTPUT:
		RETVAL


float
vtkRayCaster::GetTotalRenderTime()
		CODE:
		RETVAL = THIS->GetTotalRenderTime();
		OUTPUT:
		RETVAL



float
vtkRayCaster::GetViewRaysStepSize(level)
		int 	level
		CODE:
		RETVAL = THIS->GetViewRaysStepSize(level);
		OUTPUT:
		RETVAL


static vtkRayCaster*
vtkRayCaster::New()
		CODE:
		RETVAL = vtkRayCaster::New();
		OUTPUT:
		RETVAL


void
vtkRayCaster::SetAutomaticScaleLowerLimit(scale)
		float 	scale
		CODE:
		THIS->SetAutomaticScaleLowerLimit(scale);
		XSRETURN_EMPTY;


void
vtkRayCaster::SetBilinearImageZoom(val)
		int 	val
		CODE:
		THIS->SetBilinearImageZoom(val);
		XSRETURN_EMPTY;


void
vtkRayCaster::SetImageScale(level, scale)
		int 	level
		float 	scale
		CODE:
		THIS->SetImageScale(level, scale);
		XSRETURN_EMPTY;


void
vtkRayCaster::SetNumberOfThreads(val)
		int 	val
		CODE:
		THIS->SetNumberOfThreads(val);
		XSRETURN_EMPTY;


void
vtkRayCaster::SetSelectedImageScaleIndex(level, scale)
		int 	level
		float 	scale
		CODE:
		THIS->SetSelectedImageScaleIndex(level, scale);
		XSRETURN_EMPTY;


void
vtkRayCaster::SetViewRaysStepSize(level, scale)
		int 	level
		float 	scale
		CODE:
		THIS->SetViewRaysStepSize(level, scale);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RecursiveSphereDirectionEncoder PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRecursiveSphereDirectionEncoder::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkRecursiveSphereDirectionEncoder::GetDecodedGradient(value)
		int 	value
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDecodedGradient(value);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;



int
vtkRecursiveSphereDirectionEncoder::GetNumberOfEncodedDirections()
		CODE:
		RETVAL = THIS->GetNumberOfEncodedDirections();
		OUTPUT:
		RETVAL


int
vtkRecursiveSphereDirectionEncoder::GetRecursionDepth()
		CODE:
		RETVAL = THIS->GetRecursionDepth();
		OUTPUT:
		RETVAL


int
vtkRecursiveSphereDirectionEncoder::GetRecursionDepthMaxValue()
		CODE:
		RETVAL = THIS->GetRecursionDepthMaxValue();
		OUTPUT:
		RETVAL


int
vtkRecursiveSphereDirectionEncoder::GetRecursionDepthMinValue()
		CODE:
		RETVAL = THIS->GetRecursionDepthMinValue();
		OUTPUT:
		RETVAL


static vtkRecursiveSphereDirectionEncoder*
vtkRecursiveSphereDirectionEncoder::New()
		CODE:
		RETVAL = vtkRecursiveSphereDirectionEncoder::New();
		OUTPUT:
		RETVAL


void
vtkRecursiveSphereDirectionEncoder::SetRecursionDepth(arg1)
		int 	arg1
		CODE:
		THIS->SetRecursionDepth(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RenderWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRenderWindow::AddRenderer(arg1)
		vtkRenderer *	arg1
		CODE:
		THIS->AddRenderer(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::BordersOff()
		CODE:
		THIS->BordersOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::BordersOn()
		CODE:
		THIS->BordersOn();
		XSRETURN_EMPTY;


int
vtkRenderWindow::CheckAbortStatus()
		CODE:
		RETVAL = THIS->CheckAbortStatus();
		OUTPUT:
		RETVAL


void
vtkRenderWindow::CopyResultFrame()
		CODE:
		THIS->CopyResultFrame();
		XSRETURN_EMPTY;


void
vtkRenderWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


void
vtkRenderWindow::FullScreenOff()
		CODE:
		THIS->FullScreenOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::FullScreenOn()
		CODE:
		THIS->FullScreenOn();
		XSRETURN_EMPTY;


int
vtkRenderWindow::GetAAFrames()
		CODE:
		RETVAL = THIS->GetAAFrames();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetAbortRender()
		CODE:
		RETVAL = THIS->GetAbortRender();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetBorders()
		CODE:
		RETVAL = THIS->GetBorders();
		OUTPUT:
		RETVAL


const char *
vtkRenderWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetDepthBufferSize()
		CODE:
		RETVAL = THIS->GetDepthBufferSize();
		OUTPUT:
		RETVAL


float
vtkRenderWindow::GetDesiredUpdateRate()
		CODE:
		RETVAL = THIS->GetDesiredUpdateRate();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetEventPending()
		CODE:
		RETVAL = THIS->GetEventPending();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetFDFrames()
		CODE:
		RETVAL = THIS->GetFDFrames();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetFullScreen()
		CODE:
		RETVAL = THIS->GetFullScreen();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetInAbortCheck()
		CODE:
		RETVAL = THIS->GetInAbortCheck();
		OUTPUT:
		RETVAL


vtkRenderWindowInteractor *
vtkRenderWindow::GetInteractor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindowInteractor";
		CODE:
		RETVAL = THIS->GetInteractor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetLineSmoothing()
		CODE:
		RETVAL = THIS->GetLineSmoothing();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetNeverRendered()
		CODE:
		RETVAL = THIS->GetNeverRendered();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetNumberOfLayers()
		CODE:
		RETVAL = THIS->GetNumberOfLayers();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetNumberOfLayersMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfLayersMaxValue();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetNumberOfLayersMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfLayersMinValue();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetPointSmoothing()
		CODE:
		RETVAL = THIS->GetPointSmoothing();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetPolygonSmoothing()
		CODE:
		RETVAL = THIS->GetPolygonSmoothing();
		OUTPUT:
		RETVAL


static const char *
vtkRenderWindow::GetRenderLibrary()
		CODE:
		RETVAL = vtkRenderWindow::GetRenderLibrary();
		OUTPUT:
		RETVAL


vtkRendererCollection *
vtkRenderWindow::GetRenderers()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRendererCollection";
		CODE:
		RETVAL = THIS->GetRenderers();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetStereoCapableWindow()
		CODE:
		RETVAL = THIS->GetStereoCapableWindow();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetStereoRender()
		CODE:
		RETVAL = THIS->GetStereoRender();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetStereoType()
		CODE:
		RETVAL = THIS->GetStereoType();
		OUTPUT:
		RETVAL


char *
vtkRenderWindow::GetStereoTypeAsString()
		CODE:
		RETVAL = THIS->GetStereoTypeAsString();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetSubFrames()
		CODE:
		RETVAL = THIS->GetSubFrames();
		OUTPUT:
		RETVAL


int
vtkRenderWindow::GetSwapBuffers()
		CODE:
		RETVAL = THIS->GetSwapBuffers();
		OUTPUT:
		RETVAL


void
vtkRenderWindow::HideCursor()
		CODE:
		THIS->HideCursor();
		XSRETURN_EMPTY;


void
vtkRenderWindow::LineSmoothingOff()
		CODE:
		THIS->LineSmoothingOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::LineSmoothingOn()
		CODE:
		THIS->LineSmoothingOn();
		XSRETURN_EMPTY;


void
vtkRenderWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


vtkRenderWindowInteractor *
vtkRenderWindow::MakeRenderWindowInteractor()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindowInteractor";
		CODE:
		RETVAL = THIS->MakeRenderWindowInteractor();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkRenderWindow*
vtkRenderWindow::New()
		CODE:
		RETVAL = vtkRenderWindow::New();
		OUTPUT:
		RETVAL


void
vtkRenderWindow::PointSmoothingOff()
		CODE:
		THIS->PointSmoothingOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::PointSmoothingOn()
		CODE:
		THIS->PointSmoothingOn();
		XSRETURN_EMPTY;


void
vtkRenderWindow::PolygonSmoothingOff()
		CODE:
		THIS->PolygonSmoothingOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::PolygonSmoothingOn()
		CODE:
		THIS->PolygonSmoothingOn();
		XSRETURN_EMPTY;


void
vtkRenderWindow::RemoveRenderer(arg1)
		vtkRenderer *	arg1
		CODE:
		THIS->RemoveRenderer(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetAAFrames(arg1)
		int 	arg1
		CODE:
		THIS->SetAAFrames(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetAbortCheckMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetAbortCheckMethod",0), newRV(func), 0);
		}
		THIS->SetAbortCheckMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetAbortRender(arg1)
		int 	arg1
		CODE:
		THIS->SetAbortRender(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetBorders(arg1)
		int 	arg1
		CODE:
		THIS->SetBorders(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetDesiredUpdateRate(arg1)
		float 	arg1
		CODE:
		THIS->SetDesiredUpdateRate(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetFDFrames(arg1)
		int 	arg1
		CODE:
		THIS->SetFDFrames(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetFullScreen(arg1)
		int 	arg1
		CODE:
		THIS->SetFullScreen(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetInAbortCheck(arg1)
		int 	arg1
		CODE:
		THIS->SetInAbortCheck(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetInteractor(arg1)
		vtkRenderWindowInteractor *	arg1
		CODE:
		THIS->SetInteractor(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetLineSmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetLineSmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetNumberOfLayers(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfLayers(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetParentInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetParentInfo(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetPointSmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetPointSmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetPolygonSmoothing(arg1)
		int 	arg1
		CODE:
		THIS->SetPolygonSmoothing(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoCapableWindow(capable)
		int 	capable
		CODE:
		THIS->SetStereoCapableWindow(capable);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoRender(stereo)
		int 	stereo
		CODE:
		THIS->SetStereoRender(stereo);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoType(arg1)
		int 	arg1
		CODE:
		THIS->SetStereoType(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoTypeToCrystalEyes()
		CODE:
		THIS->SetStereoTypeToCrystalEyes();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoTypeToDresden()
		CODE:
		THIS->SetStereoTypeToDresden();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoTypeToInterlaced()
		CODE:
		THIS->SetStereoTypeToInterlaced();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoTypeToLeft()
		CODE:
		THIS->SetStereoTypeToLeft();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoTypeToRedBlue()
		CODE:
		THIS->SetStereoTypeToRedBlue();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetStereoTypeToRight()
		CODE:
		THIS->SetStereoTypeToRight();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetSubFrames(arg1)
		int 	arg1
		CODE:
		THIS->SetSubFrames(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetSwapBuffers(arg1)
		int 	arg1
		CODE:
		THIS->SetSwapBuffers(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::SetWindowInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowInfo(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindow::ShowCursor()
		CODE:
		THIS->ShowCursor();
		XSRETURN_EMPTY;


void
vtkRenderWindow::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoCapableWindowOff()
		CODE:
		THIS->StereoCapableWindowOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoCapableWindowOn()
		CODE:
		THIS->StereoCapableWindowOn();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoMidpoint()
		CODE:
		THIS->StereoMidpoint();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoRenderComplete()
		CODE:
		THIS->StereoRenderComplete();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoRenderOff()
		CODE:
		THIS->StereoRenderOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoRenderOn()
		CODE:
		THIS->StereoRenderOn();
		XSRETURN_EMPTY;


void
vtkRenderWindow::StereoUpdate()
		CODE:
		THIS->StereoUpdate();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SwapBuffersOff()
		CODE:
		THIS->SwapBuffersOff();
		XSRETURN_EMPTY;


void
vtkRenderWindow::SwapBuffersOn()
		CODE:
		THIS->SwapBuffersOn();
		XSRETURN_EMPTY;


void
vtkRenderWindow::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;


void
vtkRenderWindow::WindowRemap()
		CODE:
		THIS->WindowRemap();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RenderWindowCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRenderWindowCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkRenderWindow *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderWindowCollection::AddItem\n");



const char *
vtkRenderWindowCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRenderWindow *
vtkRenderWindowCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkRenderWindowCollection*
vtkRenderWindowCollection::New()
		CODE:
		RETVAL = vtkRenderWindowCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RenderWindowInteractor PREFIX = vtk

PROTOTYPES: DISABLE



vtkAbstractPropPicker *
vtkRenderWindowInteractor::CreateDefaultPicker()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractPropPicker";
		CODE:
		RETVAL = THIS->CreateDefaultPicker();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::CreateTimer(arg1)
		int 	arg1
		CODE:
		RETVAL = THIS->CreateTimer(arg1);
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::DestroyTimer()
		CODE:
		RETVAL = THIS->DestroyTimer();
		OUTPUT:
		RETVAL


void
vtkRenderWindowInteractor::Disable()
		CODE:
		THIS->Disable();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::Enable()
		CODE:
		THIS->Enable();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::EndPickCallback()
		CODE:
		THIS->EndPickCallback();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::ExitCallback()
		CODE:
		THIS->ExitCallback();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::FlyTo(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		vtkRenderer *	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->FlyTo(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderWindowInteractor::FlyTo\n");



const char *
vtkRenderWindowInteractor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkRenderWindowInteractor::GetDesiredUpdateRate()
		CODE:
		RETVAL = THIS->GetDesiredUpdateRate();
		OUTPUT:
		RETVAL


float
vtkRenderWindowInteractor::GetDesiredUpdateRateMaxValue()
		CODE:
		RETVAL = THIS->GetDesiredUpdateRateMaxValue();
		OUTPUT:
		RETVAL


float
vtkRenderWindowInteractor::GetDesiredUpdateRateMinValue()
		CODE:
		RETVAL = THIS->GetDesiredUpdateRateMinValue();
		OUTPUT:
		RETVAL


float
vtkRenderWindowInteractor::GetDolly()
		CODE:
		RETVAL = THIS->GetDolly();
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::GetEnabled()
		CODE:
		RETVAL = THIS->GetEnabled();
		OUTPUT:
		RETVAL


int  *
vtkRenderWindowInteractor::GetEventPosition()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetEventPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkRenderWindowInteractor::GetInitialized()
		CODE:
		RETVAL = THIS->GetInitialized();
		OUTPUT:
		RETVAL


vtkInteractorStyle *
vtkRenderWindowInteractor::GetInteractorStyle()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkInteractorStyle";
		CODE:
		RETVAL = THIS->GetInteractorStyle();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::GetLightFollowCamera()
		CODE:
		RETVAL = THIS->GetLightFollowCamera();
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::GetNumberOfFlyFrames()
		CODE:
		RETVAL = THIS->GetNumberOfFlyFrames();
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::GetNumberOfFlyFramesMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfFlyFramesMaxValue();
		OUTPUT:
		RETVAL


int
vtkRenderWindowInteractor::GetNumberOfFlyFramesMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfFlyFramesMinValue();
		OUTPUT:
		RETVAL


vtkAbstractPicker *
vtkRenderWindowInteractor::GetPicker()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractPicker";
		CODE:
		RETVAL = THIS->GetPicker();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRenderWindow *
vtkRenderWindowInteractor::GetRenderWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetRenderWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int  *
vtkRenderWindowInteractor::GetSize()
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


float
vtkRenderWindowInteractor::GetStillUpdateRate()
		CODE:
		RETVAL = THIS->GetStillUpdateRate();
		OUTPUT:
		RETVAL


float
vtkRenderWindowInteractor::GetStillUpdateRateMaxValue()
		CODE:
		RETVAL = THIS->GetStillUpdateRateMaxValue();
		OUTPUT:
		RETVAL


float
vtkRenderWindowInteractor::GetStillUpdateRateMinValue()
		CODE:
		RETVAL = THIS->GetStillUpdateRateMinValue();
		OUTPUT:
		RETVAL


void
vtkRenderWindowInteractor::HideCursor()
		CODE:
		THIS->HideCursor();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::LightFollowCameraOff()
		CODE:
		THIS->LightFollowCameraOff();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::LightFollowCameraOn()
		CODE:
		THIS->LightFollowCameraOn();
		XSRETURN_EMPTY;


static vtkRenderWindowInteractor*
vtkRenderWindowInteractor::New()
		CODE:
		RETVAL = vtkRenderWindowInteractor::New();
		OUTPUT:
		RETVAL


void
vtkRenderWindowInteractor::ReInitialize()
		CODE:
		THIS->ReInitialize();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetDesiredUpdateRate(arg1)
		float 	arg1
		CODE:
		THIS->SetDesiredUpdateRate(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetDolly(arg1)
		float 	arg1
		CODE:
		THIS->SetDolly(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetEndPickMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetEndPickMethod",0), newRV(func), 0);
		}
		THIS->SetEndPickMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetEventPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetEventPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderWindowInteractor::SetEventPosition\n");



void
vtkRenderWindowInteractor::SetExitMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetExitMethod",0), newRV(func), 0);
		}
		THIS->SetExitMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetInteractorStyle(arg1)
		vtkInteractorStyle *	arg1
		CODE:
		THIS->SetInteractorStyle(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetLightFollowCamera(arg1)
		int 	arg1
		CODE:
		THIS->SetLightFollowCamera(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetNumberOfFlyFrames(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfFlyFrames(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetPicker(arg1)
		vtkAbstractPicker *	arg1
		CODE:
		THIS->SetPicker(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetRenderWindow(aren)
		vtkRenderWindow *	aren
		CODE:
		THIS->SetRenderWindow(aren);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderWindowInteractor::SetSize\n");



void
vtkRenderWindowInteractor::SetStartPickMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetStartPickMethod",0), newRV(func), 0);
		}
		THIS->SetStartPickMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetStillUpdateRate(arg1)
		float 	arg1
		CODE:
		THIS->SetStillUpdateRate(arg1);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::SetUserMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetUserMethod",0), newRV(func), 0);
		}
		THIS->SetUserMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::ShowCursor()
		CODE:
		THIS->ShowCursor();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::StartPickCallback()
		CODE:
		THIS->StartPickCallback();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::TerminateApp()
		CODE:
		THIS->TerminateApp();
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::UpdateSize(x, y)
		int 	x
		int 	y
		CODE:
		THIS->UpdateSize(x, y);
		XSRETURN_EMPTY;


void
vtkRenderWindowInteractor::UserCallback()
		CODE:
		THIS->UserCallback();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Renderer PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRenderer::AddActor(p)
		vtkProp *	p
		CODE:
		THIS->AddActor(p);
		XSRETURN_EMPTY;


void
vtkRenderer::AddCuller(arg1)
		vtkCuller *	arg1
		CODE:
		THIS->AddCuller(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::AddLight(arg1)
		vtkLight *	arg1
		CODE:
		THIS->AddLight(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::AddVolume(p)
		vtkProp *	p
		CODE:
		THIS->AddVolume(p);
		XSRETURN_EMPTY;


void
vtkRenderer::BackingStoreOff()
		CODE:
		THIS->BackingStoreOff();
		XSRETURN_EMPTY;


void
vtkRenderer::BackingStoreOn()
		CODE:
		THIS->BackingStoreOn();
		XSRETURN_EMPTY;


void
vtkRenderer::Clear()
		CODE:
		THIS->Clear();
		XSRETURN_EMPTY;



void
vtkRenderer::CreateLight()
		CODE:
		THIS->CreateLight();
		XSRETURN_EMPTY;


void
vtkRenderer::DeviceRender()
		CODE:
		THIS->DeviceRender();
		XSRETURN_EMPTY;


vtkCamera *
vtkRenderer::GetActiveCamera()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCamera";
		CODE:
		RETVAL = THIS->GetActiveCamera();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActorCollection *
vtkRenderer::GetActors()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActorCollection";
		CODE:
		RETVAL = THIS->GetActors();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkRenderer::GetAllocatedRenderTime()
		CODE:
		RETVAL = THIS->GetAllocatedRenderTime();
		OUTPUT:
		RETVAL


float  *
vtkRenderer::GetAmbient()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAmbient();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkRenderer::GetBackingStore()
		CODE:
		RETVAL = THIS->GetBackingStore();
		OUTPUT:
		RETVAL


const char *
vtkRenderer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCullerCollection *
vtkRenderer::GetCullers()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCullerCollection";
		CODE:
		RETVAL = THIS->GetCullers();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkRenderer::GetInteractive()
		CODE:
		RETVAL = THIS->GetInteractive();
		OUTPUT:
		RETVAL


float
vtkRenderer::GetLastRenderTimeInSeconds()
		CODE:
		RETVAL = THIS->GetLastRenderTimeInSeconds();
		OUTPUT:
		RETVAL


int
vtkRenderer::GetLayer()
		CODE:
		RETVAL = THIS->GetLayer();
		OUTPUT:
		RETVAL


int
vtkRenderer::GetLightFollowCamera()
		CODE:
		RETVAL = THIS->GetLightFollowCamera();
		OUTPUT:
		RETVAL


vtkLightCollection *
vtkRenderer::GetLights()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLightCollection";
		CODE:
		RETVAL = THIS->GetLights();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkRenderer::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkRenderer::GetNumberOfPropsRenderedAsGeometry()
		CODE:
		RETVAL = THIS->GetNumberOfPropsRenderedAsGeometry();
		OUTPUT:
		RETVAL


vtkRayCaster *
vtkRenderer::GetRayCaster()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRayCaster";
		CODE:
		RETVAL = THIS->GetRayCaster();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRenderWindow *
vtkRenderer::GetRenderWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderWindow";
		CODE:
		RETVAL = THIS->GetRenderWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkRenderer::GetTimeFactor()
		CODE:
		RETVAL = THIS->GetTimeFactor();
		OUTPUT:
		RETVAL


int
vtkRenderer::GetTwoSidedLighting()
		CODE:
		RETVAL = THIS->GetTwoSidedLighting();
		OUTPUT:
		RETVAL


vtkWindow *
vtkRenderer::GetVTKWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkWindow";
		CODE:
		RETVAL = THIS->GetVTKWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkVolumeCollection *
vtkRenderer::GetVolumes()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolumeCollection";
		CODE:
		RETVAL = THIS->GetVolumes();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkRenderer::GetZ(x, y)
		int 	x
		int 	y
		CODE:
		RETVAL = THIS->GetZ(x, y);
		OUTPUT:
		RETVAL


void
vtkRenderer::InteractiveOff()
		CODE:
		THIS->InteractiveOff();
		XSRETURN_EMPTY;


void
vtkRenderer::InteractiveOn()
		CODE:
		THIS->InteractiveOn();
		XSRETURN_EMPTY;


void
vtkRenderer::LightFollowCameraOff()
		CODE:
		THIS->LightFollowCameraOff();
		XSRETURN_EMPTY;


void
vtkRenderer::LightFollowCameraOn()
		CODE:
		THIS->LightFollowCameraOn();
		XSRETURN_EMPTY;


vtkCamera *
vtkRenderer::MakeCamera()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCamera";
		CODE:
		RETVAL = THIS->MakeCamera();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkLight *
vtkRenderer::MakeLight()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLight";
		CODE:
		RETVAL = THIS->MakeLight();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkRenderer*
vtkRenderer::New()
		CODE:
		RETVAL = vtkRenderer::New();
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkRenderer::PickProp(selectionX, selectionY)
		float 	selectionX
		float 	selectionY
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->PickProp(selectionX, selectionY);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkRenderer::RemoveActor(p)
		vtkProp *	p
		CODE:
		THIS->RemoveActor(p);
		XSRETURN_EMPTY;


void
vtkRenderer::RemoveCuller(arg1)
		vtkCuller *	arg1
		CODE:
		THIS->RemoveCuller(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::RemoveLight(arg1)
		vtkLight *	arg1
		CODE:
		THIS->RemoveLight(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::RemoveVolume(p)
		vtkProp *	p
		CODE:
		THIS->RemoveVolume(p);
		XSRETURN_EMPTY;


void
vtkRenderer::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkRenderer::RenderOverlay()
		CODE:
		THIS->RenderOverlay();
		XSRETURN_EMPTY;


void
vtkRenderer::ResetCamera(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->ResetCamera(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 1
		CODE:
		THIS->ResetCamera();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderer::ResetCamera\n");



void
vtkRenderer::ResetCameraClippingRange(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->ResetCameraClippingRange(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 1
		CODE:
		THIS->ResetCameraClippingRange();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderer::ResetCameraClippingRange\n");



void
vtkRenderer::SetActiveCamera(arg1)
		vtkCamera *	arg1
		CODE:
		THIS->SetActiveCamera(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetAllocatedRenderTime(arg1)
		float 	arg1
		CODE:
		THIS->SetAllocatedRenderTime(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetAmbient(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetAmbient(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderer::SetAmbient\n");



void
vtkRenderer::SetBackingStore(arg1)
		int 	arg1
		CODE:
		THIS->SetBackingStore(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetInteractive(arg1)
		int 	arg1
		CODE:
		THIS->SetInteractive(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetLayer(arg1)
		int 	arg1
		CODE:
		THIS->SetLayer(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetLightFollowCamera(arg1)
		int 	arg1
		CODE:
		THIS->SetLightFollowCamera(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetRenderWindow(arg1)
		vtkRenderWindow *	arg1
		CODE:
		THIS->SetRenderWindow(arg1);
		XSRETURN_EMPTY;


void
vtkRenderer::SetTwoSidedLighting(arg1)
		int 	arg1
		CODE:
		THIS->SetTwoSidedLighting(arg1);
		XSRETURN_EMPTY;


int
vtkRenderer::Transparent()
		CODE:
		RETVAL = THIS->Transparent();
		OUTPUT:
		RETVAL


void
vtkRenderer::TwoSidedLightingOff()
		CODE:
		THIS->TwoSidedLightingOff();
		XSRETURN_EMPTY;


void
vtkRenderer::TwoSidedLightingOn()
		CODE:
		THIS->TwoSidedLightingOn();
		XSRETURN_EMPTY;


void
vtkRenderer::ViewToWorld(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->ViewToWorld(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		CODE:
		THIS->ViewToWorld();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderer::ViewToWorld\n");



int
vtkRenderer::VisibleActorCount()
		CODE:
		RETVAL = THIS->VisibleActorCount();
		OUTPUT:
		RETVAL


int
vtkRenderer::VisibleVolumeCount()
		CODE:
		RETVAL = THIS->VisibleVolumeCount();
		OUTPUT:
		RETVAL


void
vtkRenderer::WorldToView(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->WorldToView(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		CODE:
		THIS->WorldToView();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRenderer::WorldToView\n");


MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RendererCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRendererCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkRenderer *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRendererCollection::AddItem\n");



const char *
vtkRendererCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRenderer *
vtkRendererCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkRendererCollection*
vtkRendererCollection::New()
		CODE:
		RETVAL = vtkRendererCollection::New();
		OUTPUT:
		RETVAL


void
vtkRendererCollection::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkRendererCollection::RenderOverlay()
		CODE:
		THIS->RenderOverlay();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::RendererSource PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRendererSource::DepthValuesOff()
		CODE:
		THIS->DepthValuesOff();
		XSRETURN_EMPTY;


void
vtkRendererSource::DepthValuesOn()
		CODE:
		THIS->DepthValuesOn();
		XSRETURN_EMPTY;


const char *
vtkRendererSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkRendererSource::GetDepthValues()
		CODE:
		RETVAL = THIS->GetDepthValues();
		OUTPUT:
		RETVAL


vtkRenderer *
vtkRendererSource::GetInput()
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


unsigned long
vtkRendererSource::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkRendererSource::GetRenderFlag()
		CODE:
		RETVAL = THIS->GetRenderFlag();
		OUTPUT:
		RETVAL


int
vtkRendererSource::GetWholeWindow()
		CODE:
		RETVAL = THIS->GetWholeWindow();
		OUTPUT:
		RETVAL


static vtkRendererSource*
vtkRendererSource::New()
		CODE:
		RETVAL = vtkRendererSource::New();
		OUTPUT:
		RETVAL


void
vtkRendererSource::RenderFlagOff()
		CODE:
		THIS->RenderFlagOff();
		XSRETURN_EMPTY;


void
vtkRendererSource::RenderFlagOn()
		CODE:
		THIS->RenderFlagOn();
		XSRETURN_EMPTY;


void
vtkRendererSource::SetDepthValues(arg1)
		int 	arg1
		CODE:
		THIS->SetDepthValues(arg1);
		XSRETURN_EMPTY;


void
vtkRendererSource::SetInput(arg1)
		vtkRenderer *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkRendererSource::SetRenderFlag(arg1)
		int 	arg1
		CODE:
		THIS->SetRenderFlag(arg1);
		XSRETURN_EMPTY;


void
vtkRendererSource::SetWholeWindow(arg1)
		int 	arg1
		CODE:
		THIS->SetWholeWindow(arg1);
		XSRETURN_EMPTY;


void
vtkRendererSource::WholeWindowOff()
		CODE:
		THIS->WholeWindowOff();
		XSRETURN_EMPTY;


void
vtkRendererSource::WholeWindowOn()
		CODE:
		THIS->WholeWindowOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ScalarBarActor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkScalarBarActor::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


int
vtkScalarBarActor::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


const char *
vtkScalarBarActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


char *
vtkScalarBarActor::GetLabelFormat()
		CODE:
		RETVAL = THIS->GetLabelFormat();
		OUTPUT:
		RETVAL


vtkScalarsToColors *
vtkScalarBarActor::GetLookupTable()
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
vtkScalarBarActor::GetMaximumNumberOfColors()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfColors();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetMaximumNumberOfColorsMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfColorsMaxValue();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetMaximumNumberOfColorsMinValue()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfColorsMinValue();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetNumberOfLabels()
		CODE:
		RETVAL = THIS->GetNumberOfLabels();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetNumberOfLabelsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMaxValue();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetNumberOfLabelsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfLabelsMinValue();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetOrientation()
		CODE:
		RETVAL = THIS->GetOrientation();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetOrientationMaxValue()
		CODE:
		RETVAL = THIS->GetOrientationMaxValue();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetOrientationMinValue()
		CODE:
		RETVAL = THIS->GetOrientationMinValue();
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


char *
vtkScalarBarActor::GetTitle()
		CODE:
		RETVAL = THIS->GetTitle();
		OUTPUT:
		RETVAL


void
vtkScalarBarActor::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


static vtkScalarBarActor*
vtkScalarBarActor::New()
		CODE:
		RETVAL = vtkScalarBarActor::New();
		OUTPUT:
		RETVAL


void
vtkScalarBarActor::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


int
vtkScalarBarActor::RenderOpaqueGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(viewport);
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::RenderOverlay(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOverlay(viewport);
		OUTPUT:
		RETVAL


int
vtkScalarBarActor::RenderTranslucentGeometry(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(arg1);
		OUTPUT:
		RETVAL


void
vtkScalarBarActor::SetBold(arg1)
		int 	arg1
		CODE:
		THIS->SetBold(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetFontFamily(arg1)
		int 	arg1
		CODE:
		THIS->SetFontFamily(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetItalic(arg1)
		int 	arg1
		CODE:
		THIS->SetItalic(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetLabelFormat(arg1)
		char *	arg1
		CODE:
		THIS->SetLabelFormat(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetLookupTable(arg1)
		vtkScalarsToColors *	arg1
		CODE:
		THIS->SetLookupTable(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetMaximumNumberOfColors(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfColors(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetNumberOfLabels(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfLabels(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetOrientation(arg1)
		int 	arg1
		CODE:
		THIS->SetOrientation(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetOrientationToHorizontal()
		CODE:
		THIS->SetOrientationToHorizontal();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetOrientationToVertical()
		CODE:
		THIS->SetOrientationToVertical();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetShadow(arg1)
		int 	arg1
		CODE:
		THIS->SetShadow(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::SetTitle(arg1)
		char *	arg1
		CODE:
		THIS->SetTitle(arg1);
		XSRETURN_EMPTY;


void
vtkScalarBarActor::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkScalarBarActor::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::ScaledTextActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkScaledTextActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkScaledTextActor::GetMaximumLineHeight()
		CODE:
		RETVAL = THIS->GetMaximumLineHeight();
		OUTPUT:
		RETVAL


int  *
vtkScaledTextActor::GetMinimumSize()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMinimumSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkScaledTextActor*
vtkScaledTextActor::New()
		CODE:
		RETVAL = vtkScaledTextActor::New();
		OUTPUT:
		RETVAL


void
vtkScaledTextActor::SetMapper(arg1 = 0)
	CASE: items == 2
		vtkTextMapper *	arg1
		CODE:
		THIS->SetMapper(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkScaledTextActor::SetMapper\n");



void
vtkScaledTextActor::SetMaximumLineHeight(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumLineHeight(arg1);
		XSRETURN_EMPTY;


void
vtkScaledTextActor::SetMinimumSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetMinimumSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkScaledTextActor::SetMinimumSize\n");



void
vtkScaledTextActor::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::SelectVisiblePoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSelectVisiblePoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkSelectVisiblePoints::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkRenderer *
vtkSelectVisiblePoints::GetRenderer()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRenderer";
		CODE:
		RETVAL = THIS->GetRenderer();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkSelectVisiblePoints::GetSelectInvisible()
		CODE:
		RETVAL = THIS->GetSelectInvisible();
		OUTPUT:
		RETVAL


int  *
vtkSelectVisiblePoints::GetSelection()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSelection();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


int
vtkSelectVisiblePoints::GetSelectionWindow()
		CODE:
		RETVAL = THIS->GetSelectionWindow();
		OUTPUT:
		RETVAL


float
vtkSelectVisiblePoints::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


float
vtkSelectVisiblePoints::GetToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetToleranceMaxValue();
		OUTPUT:
		RETVAL


float
vtkSelectVisiblePoints::GetToleranceMinValue()
		CODE:
		RETVAL = THIS->GetToleranceMinValue();
		OUTPUT:
		RETVAL


static vtkSelectVisiblePoints*
vtkSelectVisiblePoints::New()
		CODE:
		RETVAL = vtkSelectVisiblePoints::New();
		OUTPUT:
		RETVAL


void
vtkSelectVisiblePoints::SelectInvisibleOff()
		CODE:
		THIS->SelectInvisibleOff();
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SelectInvisibleOn()
		CODE:
		THIS->SelectInvisibleOn();
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SelectionWindowOff()
		CODE:
		THIS->SelectionWindowOff();
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SelectionWindowOn()
		CODE:
		THIS->SelectionWindowOn();
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SetRenderer(ren)
		vtkRenderer *	ren
		CODE:
		THIS->SetRenderer(ren);
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SetSelectInvisible(arg1)
		int 	arg1
		CODE:
		THIS->SetSelectInvisible(arg1);
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SetSelection(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetSelection(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkSelectVisiblePoints::SetSelection\n");



void
vtkSelectVisiblePoints::SetSelectionWindow(arg1)
		int 	arg1
		CODE:
		THIS->SetSelectionWindow(arg1);
		XSRETURN_EMPTY;


void
vtkSelectVisiblePoints::SetTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::TextMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTextMapper::BoldOff()
		CODE:
		THIS->BoldOff();
		XSRETURN_EMPTY;


void
vtkTextMapper::BoldOn()
		CODE:
		THIS->BoldOn();
		XSRETURN_EMPTY;


int
vtkTextMapper::GetBold()
		CODE:
		RETVAL = THIS->GetBold();
		OUTPUT:
		RETVAL


const char *
vtkTextMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetFontFamily()
		CODE:
		RETVAL = THIS->GetFontFamily();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetFontSize()
		CODE:
		RETVAL = THIS->GetFontSize();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetHeight(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->GetHeight(arg1);
		OUTPUT:
		RETVAL


char *
vtkTextMapper::GetInput()
		CODE:
		RETVAL = THIS->GetInput();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetItalic()
		CODE:
		RETVAL = THIS->GetItalic();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetJustification()
		CODE:
		RETVAL = THIS->GetJustification();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetJustificationMaxValue()
		CODE:
		RETVAL = THIS->GetJustificationMaxValue();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetJustificationMinValue()
		CODE:
		RETVAL = THIS->GetJustificationMinValue();
		OUTPUT:
		RETVAL


float
vtkTextMapper::GetLineOffset()
		CODE:
		RETVAL = THIS->GetLineOffset();
		OUTPUT:
		RETVAL


float
vtkTextMapper::GetLineSpacing()
		CODE:
		RETVAL = THIS->GetLineSpacing();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetNumberOfLines(arg1 = 0)
	CASE: items == 2
		const char *	arg1
		CODE:
		RETVAL = THIS->GetNumberOfLines(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetNumberOfLines();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTextMapper::GetNumberOfLines\n");



int
vtkTextMapper::GetShadow()
		CODE:
		RETVAL = THIS->GetShadow();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetVerticalJustification()
		CODE:
		RETVAL = THIS->GetVerticalJustification();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetVerticalJustificationMaxValue()
		CODE:
		RETVAL = THIS->GetVerticalJustificationMaxValue();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetVerticalJustificationMinValue()
		CODE:
		RETVAL = THIS->GetVerticalJustificationMinValue();
		OUTPUT:
		RETVAL


int
vtkTextMapper::GetWidth(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->GetWidth(arg1);
		OUTPUT:
		RETVAL


void
vtkTextMapper::ItalicOff()
		CODE:
		THIS->ItalicOff();
		XSRETURN_EMPTY;


void
vtkTextMapper::ItalicOn()
		CODE:
		THIS->ItalicOn();
		XSRETURN_EMPTY;


static vtkTextMapper*
vtkTextMapper::New()
		CODE:
		RETVAL = vtkTextMapper::New();
		OUTPUT:
		RETVAL


void
vtkTextMapper::SetBold(val)
		int 	val
		CODE:
		THIS->SetBold(val);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetFontFamily(val)
		int 	val
		CODE:
		THIS->SetFontFamily(val);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetFontFamilyToArial()
		CODE:
		THIS->SetFontFamilyToArial();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetFontFamilyToCourier()
		CODE:
		THIS->SetFontFamilyToCourier();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetFontFamilyToTimes()
		CODE:
		THIS->SetFontFamilyToTimes();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetFontSize(size)
		int 	size
		CODE:
		THIS->SetFontSize(size);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetInput(inputString)
		const char *	inputString
		CODE:
		THIS->SetInput(inputString);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetItalic(val)
		int 	val
		CODE:
		THIS->SetItalic(val);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetJustification(arg1)
		int 	arg1
		CODE:
		THIS->SetJustification(arg1);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetJustificationToCentered()
		CODE:
		THIS->SetJustificationToCentered();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetJustificationToLeft()
		CODE:
		THIS->SetJustificationToLeft();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetJustificationToRight()
		CODE:
		THIS->SetJustificationToRight();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetLineOffset(arg1)
		float 	arg1
		CODE:
		THIS->SetLineOffset(arg1);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetLineSpacing(arg1)
		float 	arg1
		CODE:
		THIS->SetLineSpacing(arg1);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetShadow(val)
		int 	val
		CODE:
		THIS->SetShadow(val);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetVerticalJustification(arg1)
		int 	arg1
		CODE:
		THIS->SetVerticalJustification(arg1);
		XSRETURN_EMPTY;


void
vtkTextMapper::SetVerticalJustificationToBottom()
		CODE:
		THIS->SetVerticalJustificationToBottom();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetVerticalJustificationToCentered()
		CODE:
		THIS->SetVerticalJustificationToCentered();
		XSRETURN_EMPTY;


void
vtkTextMapper::SetVerticalJustificationToTop()
		CODE:
		THIS->SetVerticalJustificationToTop();
		XSRETURN_EMPTY;


void
vtkTextMapper::ShadowOff()
		CODE:
		THIS->ShadowOff();
		XSRETURN_EMPTY;


void
vtkTextMapper::ShadowOn()
		CODE:
		THIS->ShadowOn();
		XSRETURN_EMPTY;


void
vtkTextMapper::ShallowCopy(tm)
		vtkTextMapper *	tm
		CODE:
		THIS->ShallowCopy(tm);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Texture PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTexture::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkTexture::GetInput()
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
vtkTexture::GetInterpolate()
		CODE:
		RETVAL = THIS->GetInterpolate();
		OUTPUT:
		RETVAL


vtkLookupTable *
vtkTexture::GetLookupTable()
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
vtkTexture::GetMapColorScalarsThroughLookupTable()
		CODE:
		RETVAL = THIS->GetMapColorScalarsThroughLookupTable();
		OUTPUT:
		RETVAL


vtkUnsignedCharArray *
vtkTexture::GetMappedScalars()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnsignedCharArray";
		CODE:
		RETVAL = THIS->GetMappedScalars();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkTexture::GetQuality()
		CODE:
		RETVAL = THIS->GetQuality();
		OUTPUT:
		RETVAL


int
vtkTexture::GetRepeat()
		CODE:
		RETVAL = THIS->GetRepeat();
		OUTPUT:
		RETVAL


void
vtkTexture::InterpolateOff()
		CODE:
		THIS->InterpolateOff();
		XSRETURN_EMPTY;


void
vtkTexture::InterpolateOn()
		CODE:
		THIS->InterpolateOn();
		XSRETURN_EMPTY;


void
vtkTexture::Load(arg1)
		vtkRenderer *	arg1
		CODE:
		THIS->Load(arg1);
		XSRETURN_EMPTY;


void
vtkTexture::MapColorScalarsThroughLookupTableOff()
		CODE:
		THIS->MapColorScalarsThroughLookupTableOff();
		XSRETURN_EMPTY;


void
vtkTexture::MapColorScalarsThroughLookupTableOn()
		CODE:
		THIS->MapColorScalarsThroughLookupTableOn();
		XSRETURN_EMPTY;


static vtkTexture*
vtkTexture::New()
		CODE:
		RETVAL = vtkTexture::New();
		OUTPUT:
		RETVAL


void
vtkTexture::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkTexture::Render(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Render(ren);
		XSRETURN_EMPTY;


void
vtkTexture::RepeatOff()
		CODE:
		THIS->RepeatOff();
		XSRETURN_EMPTY;


void
vtkTexture::RepeatOn()
		CODE:
		THIS->RepeatOn();
		XSRETURN_EMPTY;


void
vtkTexture::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkTexture::SetInterpolate(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolate(arg1);
		XSRETURN_EMPTY;


void
vtkTexture::SetLookupTable(arg1)
		vtkLookupTable *	arg1
		CODE:
		THIS->SetLookupTable(arg1);
		XSRETURN_EMPTY;


void
vtkTexture::SetMapColorScalarsThroughLookupTable(arg1)
		int 	arg1
		CODE:
		THIS->SetMapColorScalarsThroughLookupTable(arg1);
		XSRETURN_EMPTY;


void
vtkTexture::SetQuality(arg1)
		int 	arg1
		CODE:
		THIS->SetQuality(arg1);
		XSRETURN_EMPTY;


void
vtkTexture::SetQualityTo16Bit()
		CODE:
		THIS->SetQualityTo16Bit();
		XSRETURN_EMPTY;


void
vtkTexture::SetQualityTo32Bit()
		CODE:
		THIS->SetQualityTo32Bit();
		XSRETURN_EMPTY;


void
vtkTexture::SetQualityToDefault()
		CODE:
		THIS->SetQualityToDefault();
		XSRETURN_EMPTY;


void
vtkTexture::SetRepeat(arg1)
		int 	arg1
		CODE:
		THIS->SetRepeat(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VRMLExporter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVRMLExporter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkVRMLExporter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


float
vtkVRMLExporter::GetSpeed()
		CODE:
		RETVAL = THIS->GetSpeed();
		OUTPUT:
		RETVAL


static vtkVRMLExporter*
vtkVRMLExporter::New()
		CODE:
		RETVAL = vtkVRMLExporter::New();
		OUTPUT:
		RETVAL


void
vtkVRMLExporter::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkVRMLExporter::SetSpeed(arg1)
		float 	arg1
		CODE:
		THIS->SetSpeed(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Volume PREFIX = vtk

PROTOTYPES: DISABLE



float *
vtkVolume::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkVolume::GetBounds\n");



const char *
vtkVolume::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkVolume::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkVolumeMapper *
vtkVolume::GetMapper()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolumeMapper";
		CODE:
		RETVAL = THIS->GetMapper();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkVolume::GetMaxXBound()
		CODE:
		RETVAL = THIS->GetMaxXBound();
		OUTPUT:
		RETVAL


float
vtkVolume::GetMaxYBound()
		CODE:
		RETVAL = THIS->GetMaxYBound();
		OUTPUT:
		RETVAL


float
vtkVolume::GetMaxZBound()
		CODE:
		RETVAL = THIS->GetMaxZBound();
		OUTPUT:
		RETVAL


float
vtkVolume::GetMinXBound()
		CODE:
		RETVAL = THIS->GetMinXBound();
		OUTPUT:
		RETVAL


float
vtkVolume::GetMinYBound()
		CODE:
		RETVAL = THIS->GetMinYBound();
		OUTPUT:
		RETVAL


float
vtkVolume::GetMinZBound()
		CODE:
		RETVAL = THIS->GetMinZBound();
		OUTPUT:
		RETVAL


vtkVolumeProperty *
vtkVolume::GetProperty()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolumeProperty";
		CODE:
		RETVAL = THIS->GetProperty();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkVolume::GetRedrawMTime()
		CODE:
		RETVAL = THIS->GetRedrawMTime();
		OUTPUT:
		RETVAL


void
vtkVolume::GetVolumes(vc)
		vtkPropCollection *	vc
		CODE:
		THIS->GetVolumes(vc);
		XSRETURN_EMPTY;


static vtkVolume*
vtkVolume::New()
		CODE:
		RETVAL = vtkVolume::New();
		OUTPUT:
		RETVAL


void
vtkVolume::SetMapper(mapper)
		vtkVolumeMapper *	mapper
		CODE:
		THIS->SetMapper(mapper);
		XSRETURN_EMPTY;


void
vtkVolume::SetProperty(property)
		vtkVolumeProperty *	property
		CODE:
		THIS->SetProperty(property);
		XSRETURN_EMPTY;


void
vtkVolume::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;


void
vtkVolume::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVolumeCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkVolume *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeCollection::AddItem\n");



const char *
vtkVolumeCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkVolume *
vtkVolumeCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolume";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkVolume *
vtkVolumeCollection::GetNextVolume()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolume";
		CODE:
		RETVAL = THIS->GetNextVolume();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkVolumeCollection*
vtkVolumeCollection::New()
		CODE:
		RETVAL = vtkVolumeCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVolumeMapper::CroppingOff()
		CODE:
		THIS->CroppingOff();
		XSRETURN_EMPTY;


void
vtkVolumeMapper::CroppingOn()
		CODE:
		THIS->CroppingOn();
		XSRETURN_EMPTY;


float *
vtkVolumeMapper::GetBounds()
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
		croak("Unsupported number of args and/or types supplied to vtkVolumeMapper::GetBounds\n");



const char *
vtkVolumeMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolumeMapper::GetCropping()
		CODE:
		RETVAL = THIS->GetCropping();
		OUTPUT:
		RETVAL


int
vtkVolumeMapper::GetCroppingRegionFlags()
		CODE:
		RETVAL = THIS->GetCroppingRegionFlags();
		OUTPUT:
		RETVAL


int
vtkVolumeMapper::GetCroppingRegionFlagsMaxValue()
		CODE:
		RETVAL = THIS->GetCroppingRegionFlagsMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeMapper::GetCroppingRegionFlagsMinValue()
		CODE:
		RETVAL = THIS->GetCroppingRegionFlagsMinValue();
		OUTPUT:
		RETVAL


float  *
vtkVolumeMapper::GetCroppingRegionPlanes()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCroppingRegionPlanes();
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
vtkVolumeMapper::GetInput()
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


vtkImageData *
vtkVolumeMapper::GetRGBTextureInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetRGBTextureInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkVolumeMapper::GetVoxelCroppingRegionPlanes()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVoxelCroppingRegionPlanes();
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
vtkVolumeMapper::SetCropping(arg1)
		int 	arg1
		CODE:
		THIS->SetCropping(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionFlags(arg1)
		int 	arg1
		CODE:
		THIS->SetCroppingRegionFlags(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionFlagsToCross()
		CODE:
		THIS->SetCroppingRegionFlagsToCross();
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionFlagsToFence()
		CODE:
		THIS->SetCroppingRegionFlagsToFence();
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionFlagsToInvertedCross()
		CODE:
		THIS->SetCroppingRegionFlagsToInvertedCross();
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionFlagsToInvertedFence()
		CODE:
		THIS->SetCroppingRegionFlagsToInvertedFence();
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionFlagsToSubVolume()
		CODE:
		THIS->SetCroppingRegionFlagsToSubVolume();
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetCroppingRegionPlanes(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetCroppingRegionPlanes(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeMapper::SetCroppingRegionPlanes\n");



void
vtkVolumeMapper::SetInput(arg1)
		vtkImageData *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeMapper::SetRGBTextureInput(rgbTexture)
		vtkImageData *	rgbTexture
		CODE:
		THIS->SetRGBTextureInput(rgbTexture);
		XSRETURN_EMPTY;


void
vtkVolumeMapper::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeProMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVolumeProMapper::CursorOff()
		CODE:
		THIS->CursorOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::CursorOn()
		CODE:
		THIS->CursorOn();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::CutPlaneOff()
		CODE:
		THIS->CutPlaneOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::CutPlaneOn()
		CODE:
		THIS->CutPlaneOn();
		XSRETURN_EMPTY;


int
vtkVolumeProMapper::GetAvailableBoardMemory()
		CODE:
		RETVAL = THIS->GetAvailableBoardMemory();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetBlendMode()
		CODE:
		RETVAL = THIS->GetBlendMode();
		OUTPUT:
		RETVAL


const char *
vtkVolumeProMapper::GetBlendModeAsString()
		CODE:
		RETVAL = THIS->GetBlendModeAsString();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetBlendModeMaxValue()
		CODE:
		RETVAL = THIS->GetBlendModeMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetBlendModeMinValue()
		CODE:
		RETVAL = THIS->GetBlendModeMinValue();
		OUTPUT:
		RETVAL


const char *
vtkVolumeProMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCursor()
		CODE:
		RETVAL = THIS->GetCursor();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCursorMaxValue()
		CODE:
		RETVAL = THIS->GetCursorMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCursorMinValue()
		CODE:
		RETVAL = THIS->GetCursorMinValue();
		OUTPUT:
		RETVAL


double  *
vtkVolumeProMapper::GetCursorPosition()
		PREINIT:
		double  * retval;
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
vtkVolumeProMapper::GetCursorType()
		CODE:
		RETVAL = THIS->GetCursorType();
		OUTPUT:
		RETVAL


const char *
vtkVolumeProMapper::GetCursorTypeAsString()
		CODE:
		RETVAL = THIS->GetCursorTypeAsString();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCursorTypeMaxValue()
		CODE:
		RETVAL = THIS->GetCursorTypeMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCursorTypeMinValue()
		CODE:
		RETVAL = THIS->GetCursorTypeMinValue();
		OUTPUT:
		RETVAL


double  *
vtkVolumeProMapper::GetCursorXAxisColor()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCursorXAxisColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double  *
vtkVolumeProMapper::GetCursorYAxisColor()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCursorYAxisColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


double  *
vtkVolumeProMapper::GetCursorZAxisColor()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCursorZAxisColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkVolumeProMapper::GetCutPlane()
		CODE:
		RETVAL = THIS->GetCutPlane();
		OUTPUT:
		RETVAL


double  *
vtkVolumeProMapper::GetCutPlaneEquation()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCutPlaneEquation();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


int
vtkVolumeProMapper::GetCutPlaneFallOffDistance()
		CODE:
		RETVAL = THIS->GetCutPlaneFallOffDistance();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCutPlaneFallOffDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetCutPlaneFallOffDistanceMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCutPlaneFallOffDistanceMinValue()
		CODE:
		RETVAL = THIS->GetCutPlaneFallOffDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCutPlaneMaxValue()
		CODE:
		RETVAL = THIS->GetCutPlaneMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetCutPlaneMinValue()
		CODE:
		RETVAL = THIS->GetCutPlaneMinValue();
		OUTPUT:
		RETVAL


double
vtkVolumeProMapper::GetCutPlaneThickness()
		CODE:
		RETVAL = THIS->GetCutPlaneThickness();
		OUTPUT:
		RETVAL


double
vtkVolumeProMapper::GetCutPlaneThicknessMaxValue()
		CODE:
		RETVAL = THIS->GetCutPlaneThicknessMaxValue();
		OUTPUT:
		RETVAL


double
vtkVolumeProMapper::GetCutPlaneThicknessMinValue()
		CODE:
		RETVAL = THIS->GetCutPlaneThicknessMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientDiffuseModulation()
		CODE:
		RETVAL = THIS->GetGradientDiffuseModulation();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientDiffuseModulationMaxValue()
		CODE:
		RETVAL = THIS->GetGradientDiffuseModulationMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientDiffuseModulationMinValue()
		CODE:
		RETVAL = THIS->GetGradientDiffuseModulationMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientOpacityModulation()
		CODE:
		RETVAL = THIS->GetGradientOpacityModulation();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientOpacityModulationMaxValue()
		CODE:
		RETVAL = THIS->GetGradientOpacityModulationMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientOpacityModulationMinValue()
		CODE:
		RETVAL = THIS->GetGradientOpacityModulationMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientSpecularModulation()
		CODE:
		RETVAL = THIS->GetGradientSpecularModulation();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientSpecularModulationMaxValue()
		CODE:
		RETVAL = THIS->GetGradientSpecularModulationMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetGradientSpecularModulationMinValue()
		CODE:
		RETVAL = THIS->GetGradientSpecularModulationMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetIntermixIntersectingGeometry()
		CODE:
		RETVAL = THIS->GetIntermixIntersectingGeometry();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetIntermixIntersectingGeometryMaxValue()
		CODE:
		RETVAL = THIS->GetIntermixIntersectingGeometryMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetIntermixIntersectingGeometryMinValue()
		CODE:
		RETVAL = THIS->GetIntermixIntersectingGeometryMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetMajorBoardVersion()
		CODE:
		RETVAL = THIS->GetMajorBoardVersion();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetMinorBoardVersion()
		CODE:
		RETVAL = THIS->GetMinorBoardVersion();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetNoHardware()
		CODE:
		RETVAL = THIS->GetNoHardware();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetNumberOfBoards()
		CODE:
		RETVAL = THIS->GetNumberOfBoards();
		OUTPUT:
		RETVAL


int  *
vtkVolumeProMapper::GetSubVolume()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSubVolume();
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
vtkVolumeProMapper::GetSuperSampling()
		CODE:
		RETVAL = THIS->GetSuperSampling();
		OUTPUT:
		RETVAL


double  *
vtkVolumeProMapper::GetSuperSamplingFactor()
		PREINIT:
		double  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSuperSamplingFactor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkVolumeProMapper::GetSuperSamplingMaxValue()
		CODE:
		RETVAL = THIS->GetSuperSamplingMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetSuperSamplingMinValue()
		CODE:
		RETVAL = THIS->GetSuperSamplingMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProMapper::GetWrongVLIVersion()
		CODE:
		RETVAL = THIS->GetWrongVLIVersion();
		OUTPUT:
		RETVAL


void
vtkVolumeProMapper::GradientDiffuseModulationOff()
		CODE:
		THIS->GradientDiffuseModulationOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::GradientDiffuseModulationOn()
		CODE:
		THIS->GradientDiffuseModulationOn();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::GradientOpacityModulationOff()
		CODE:
		THIS->GradientOpacityModulationOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::GradientOpacityModulationOn()
		CODE:
		THIS->GradientOpacityModulationOn();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::GradientSpecularModulationOff()
		CODE:
		THIS->GradientSpecularModulationOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::GradientSpecularModulationOn()
		CODE:
		THIS->GradientSpecularModulationOn();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::IntermixIntersectingGeometryOff()
		CODE:
		THIS->IntermixIntersectingGeometryOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::IntermixIntersectingGeometryOn()
		CODE:
		THIS->IntermixIntersectingGeometryOn();
		XSRETURN_EMPTY;


static vtkVolumeProMapper*
vtkVolumeProMapper::New()
		CODE:
		RETVAL = vtkVolumeProMapper::New();
		OUTPUT:
		RETVAL


void
vtkVolumeProMapper::Render(arg1, arg2)
		vtkRenderer *	arg1
		vtkVolume *	arg2
		CODE:
		THIS->Render(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetBlendMode(arg1)
		int 	arg1
		CODE:
		THIS->SetBlendMode(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetBlendModeToComposite()
		CODE:
		THIS->SetBlendModeToComposite();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetBlendModeToMaximumIntensity()
		CODE:
		THIS->SetBlendModeToMaximumIntensity();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetBlendModeToMinimumIntensity()
		CODE:
		THIS->SetBlendModeToMinimumIntensity();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCursor(arg1)
		int 	arg1
		CODE:
		THIS->SetCursor(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCursorPosition(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetCursorPosition(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetCursorPosition\n");



void
vtkVolumeProMapper::SetCursorType(arg1)
		int 	arg1
		CODE:
		THIS->SetCursorType(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCursorTypeToCrossHair()
		CODE:
		THIS->SetCursorTypeToCrossHair();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCursorTypeToPlane()
		CODE:
		THIS->SetCursorTypeToPlane();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCursorXAxisColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetCursorXAxisColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetCursorXAxisColor\n");



void
vtkVolumeProMapper::SetCursorYAxisColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetCursorYAxisColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetCursorYAxisColor\n");



void
vtkVolumeProMapper::SetCursorZAxisColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetCursorZAxisColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetCursorZAxisColor\n");



void
vtkVolumeProMapper::SetCutPlane(arg1)
		int 	arg1
		CODE:
		THIS->SetCutPlane(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCutPlaneEquation(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->SetCutPlaneEquation(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetCutPlaneEquation\n");



void
vtkVolumeProMapper::SetCutPlaneFallOffDistance(arg1)
		int 	arg1
		CODE:
		THIS->SetCutPlaneFallOffDistance(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetCutPlaneThickness(arg1)
		double 	arg1
		CODE:
		THIS->SetCutPlaneThickness(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetGradientDiffuseModulation(arg1)
		int 	arg1
		CODE:
		THIS->SetGradientDiffuseModulation(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetGradientOpacityModulation(arg1)
		int 	arg1
		CODE:
		THIS->SetGradientOpacityModulation(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetGradientSpecularModulation(arg1)
		int 	arg1
		CODE:
		THIS->SetGradientSpecularModulation(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetIntermixIntersectingGeometry(arg1)
		int 	arg1
		CODE:
		THIS->SetIntermixIntersectingGeometry(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetSubVolume(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetSubVolume(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetSubVolume\n");



void
vtkVolumeProMapper::SetSuperSampling(arg1)
		int 	arg1
		CODE:
		THIS->SetSuperSampling(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SetSuperSamplingFactor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->SetSuperSamplingFactor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProMapper::SetSuperSamplingFactor\n");



void
vtkVolumeProMapper::SuperSamplingOff()
		CODE:
		THIS->SuperSamplingOff();
		XSRETURN_EMPTY;


void
vtkVolumeProMapper::SuperSamplingOn()
		CODE:
		THIS->SuperSamplingOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeProperty PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkVolumeProperty::GetAmbient()
		CODE:
		RETVAL = THIS->GetAmbient();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetAmbientMaxValue()
		CODE:
		RETVAL = THIS->GetAmbientMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetAmbientMinValue()
		CODE:
		RETVAL = THIS->GetAmbientMinValue();
		OUTPUT:
		RETVAL


const char *
vtkVolumeProperty::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolumeProperty::GetColorChannels()
		CODE:
		RETVAL = THIS->GetColorChannels();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetDiffuse()
		CODE:
		RETVAL = THIS->GetDiffuse();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetDiffuseMaxValue()
		CODE:
		RETVAL = THIS->GetDiffuseMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetDiffuseMinValue()
		CODE:
		RETVAL = THIS->GetDiffuseMinValue();
		OUTPUT:
		RETVAL


vtkPiecewiseFunction *
vtkVolumeProperty::GetGradientOpacity()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPiecewiseFunction";
		CODE:
		RETVAL = THIS->GetGradientOpacity();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPiecewiseFunction *
vtkVolumeProperty::GetGrayTransferFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPiecewiseFunction";
		CODE:
		RETVAL = THIS->GetGrayTransferFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkVolumeProperty::GetInterpolationType()
		CODE:
		RETVAL = THIS->GetInterpolationType();
		OUTPUT:
		RETVAL


const char *
vtkVolumeProperty::GetInterpolationTypeAsString()
		CODE:
		RETVAL = THIS->GetInterpolationTypeAsString();
		OUTPUT:
		RETVAL


int
vtkVolumeProperty::GetInterpolationTypeMaxValue()
		CODE:
		RETVAL = THIS->GetInterpolationTypeMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeProperty::GetInterpolationTypeMinValue()
		CODE:
		RETVAL = THIS->GetInterpolationTypeMinValue();
		OUTPUT:
		RETVAL


unsigned long
vtkVolumeProperty::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetRGBTextureCoefficient()
		CODE:
		RETVAL = THIS->GetRGBTextureCoefficient();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetRGBTextureCoefficientMaxValue()
		CODE:
		RETVAL = THIS->GetRGBTextureCoefficientMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetRGBTextureCoefficientMinValue()
		CODE:
		RETVAL = THIS->GetRGBTextureCoefficientMinValue();
		OUTPUT:
		RETVAL


vtkColorTransferFunction *
vtkVolumeProperty::GetRGBTransferFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkColorTransferFunction";
		CODE:
		RETVAL = THIS->GetRGBTransferFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPiecewiseFunction *
vtkVolumeProperty::GetScalarOpacity()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPiecewiseFunction";
		CODE:
		RETVAL = THIS->GetScalarOpacity();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkVolumeProperty::GetShade()
		CODE:
		RETVAL = THIS->GetShade();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetSpecular()
		CODE:
		RETVAL = THIS->GetSpecular();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetSpecularMaxValue()
		CODE:
		RETVAL = THIS->GetSpecularMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetSpecularMinValue()
		CODE:
		RETVAL = THIS->GetSpecularMinValue();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetSpecularPower()
		CODE:
		RETVAL = THIS->GetSpecularPower();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetSpecularPowerMaxValue()
		CODE:
		RETVAL = THIS->GetSpecularPowerMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeProperty::GetSpecularPowerMinValue()
		CODE:
		RETVAL = THIS->GetSpecularPowerMinValue();
		OUTPUT:
		RETVAL


static vtkVolumeProperty*
vtkVolumeProperty::New()
		CODE:
		RETVAL = vtkVolumeProperty::New();
		OUTPUT:
		RETVAL


void
vtkVolumeProperty::SetAmbient(arg1)
		float 	arg1
		CODE:
		THIS->SetAmbient(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetColor(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::PiecewiseFunction")
		vtkPiecewiseFunction *	arg1
		CODE:
		THIS->SetColor(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::ColorTransferFunction")
		vtkColorTransferFunction *	arg1
		CODE:
		THIS->SetColor(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeProperty::SetColor\n");



void
vtkVolumeProperty::SetDiffuse(arg1)
		float 	arg1
		CODE:
		THIS->SetDiffuse(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetGradientOpacity(function)
		vtkPiecewiseFunction *	function
		CODE:
		THIS->SetGradientOpacity(function);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetInterpolationType(arg1)
		int 	arg1
		CODE:
		THIS->SetInterpolationType(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetInterpolationTypeToLinear()
		CODE:
		THIS->SetInterpolationTypeToLinear();
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetInterpolationTypeToNearest()
		CODE:
		THIS->SetInterpolationTypeToNearest();
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetRGBTextureCoefficient(arg1)
		float 	arg1
		CODE:
		THIS->SetRGBTextureCoefficient(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetScalarOpacity(function)
		vtkPiecewiseFunction *	function
		CODE:
		THIS->SetScalarOpacity(function);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetShade(arg1)
		int 	arg1
		CODE:
		THIS->SetShade(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetSpecular(arg1)
		float 	arg1
		CODE:
		THIS->SetSpecular(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::SetSpecularPower(arg1)
		float 	arg1
		CODE:
		THIS->SetSpecularPower(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeProperty::ShadeOff()
		CODE:
		THIS->ShadeOff();
		XSRETURN_EMPTY;


void
vtkVolumeProperty::ShadeOn()
		CODE:
		THIS->ShadeOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeRayCastCompositeFunction PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeRayCastCompositeFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastCompositeFunction::GetCompositeMethod()
		CODE:
		RETVAL = THIS->GetCompositeMethod();
		OUTPUT:
		RETVAL


const char *
vtkVolumeRayCastCompositeFunction::GetCompositeMethodAsString()
		CODE:
		RETVAL = THIS->GetCompositeMethodAsString();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastCompositeFunction::GetCompositeMethodMaxValue()
		CODE:
		RETVAL = THIS->GetCompositeMethodMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastCompositeFunction::GetCompositeMethodMinValue()
		CODE:
		RETVAL = THIS->GetCompositeMethodMinValue();
		OUTPUT:
		RETVAL


static vtkVolumeRayCastCompositeFunction*
vtkVolumeRayCastCompositeFunction::New()
		CODE:
		RETVAL = vtkVolumeRayCastCompositeFunction::New();
		OUTPUT:
		RETVAL


void
vtkVolumeRayCastCompositeFunction::SetCompositeMethod(arg1)
		int 	arg1
		CODE:
		THIS->SetCompositeMethod(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastCompositeFunction::SetCompositeMethodToClassifyFirst()
		CODE:
		THIS->SetCompositeMethodToClassifyFirst();
		XSRETURN_EMPTY;


void
vtkVolumeRayCastCompositeFunction::SetCompositeMethodToInterpolateFirst()
		CODE:
		THIS->SetCompositeMethodToInterpolateFirst();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeRayCastFunction PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeRayCastFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastFunction::GetZeroOpacityThreshold(vol)
		vtkVolume *	vol
		CODE:
		RETVAL = THIS->GetZeroOpacityThreshold(vol);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeRayCastIsosurfaceFunction PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeRayCastIsosurfaceFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastIsosurfaceFunction::GetIsoValue()
		CODE:
		RETVAL = THIS->GetIsoValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastIsosurfaceFunction::GetZeroOpacityThreshold(vol)
		vtkVolume *	vol
		CODE:
		RETVAL = THIS->GetZeroOpacityThreshold(vol);
		OUTPUT:
		RETVAL


static vtkVolumeRayCastIsosurfaceFunction*
vtkVolumeRayCastIsosurfaceFunction::New()
		CODE:
		RETVAL = vtkVolumeRayCastIsosurfaceFunction::New();
		OUTPUT:
		RETVAL


void
vtkVolumeRayCastIsosurfaceFunction::SetIsoValue(arg1)
		float 	arg1
		CODE:
		THIS->SetIsoValue(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeRayCastMIPFunction PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeRayCastMIPFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMIPFunction::GetMaximizeMethod()
		CODE:
		RETVAL = THIS->GetMaximizeMethod();
		OUTPUT:
		RETVAL


const char *
vtkVolumeRayCastMIPFunction::GetMaximizeMethodAsString()
		CODE:
		RETVAL = THIS->GetMaximizeMethodAsString();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMIPFunction::GetMaximizeMethodMaxValue()
		CODE:
		RETVAL = THIS->GetMaximizeMethodMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMIPFunction::GetMaximizeMethodMinValue()
		CODE:
		RETVAL = THIS->GetMaximizeMethodMinValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMIPFunction::GetZeroOpacityThreshold(vol)
		vtkVolume *	vol
		CODE:
		RETVAL = THIS->GetZeroOpacityThreshold(vol);
		OUTPUT:
		RETVAL


static vtkVolumeRayCastMIPFunction*
vtkVolumeRayCastMIPFunction::New()
		CODE:
		RETVAL = vtkVolumeRayCastMIPFunction::New();
		OUTPUT:
		RETVAL


void
vtkVolumeRayCastMIPFunction::SetMaximizeMethod(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximizeMethod(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMIPFunction::SetMaximizeMethodToOpacity()
		CODE:
		THIS->SetMaximizeMethodToOpacity();
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMIPFunction::SetMaximizeMethodToScalarValue()
		CODE:
		THIS->SetMaximizeMethodToScalarValue();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeRayCastMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVolumeRayCastMapper::AutoAdjustSampleDistancesOff()
		CODE:
		THIS->AutoAdjustSampleDistancesOff();
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::AutoAdjustSampleDistancesOn()
		CODE:
		THIS->AutoAdjustSampleDistancesOn();
		XSRETURN_EMPTY;


int
vtkVolumeRayCastMapper::GetAutoAdjustSampleDistances()
		CODE:
		RETVAL = THIS->GetAutoAdjustSampleDistances();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMapper::GetAutoAdjustSampleDistancesMaxValue()
		CODE:
		RETVAL = THIS->GetAutoAdjustSampleDistancesMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMapper::GetAutoAdjustSampleDistancesMinValue()
		CODE:
		RETVAL = THIS->GetAutoAdjustSampleDistancesMinValue();
		OUTPUT:
		RETVAL


const char *
vtkVolumeRayCastMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkEncodedGradientEstimator *
vtkVolumeRayCastMapper::GetGradientEstimator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkEncodedGradientEstimator";
		CODE:
		RETVAL = THIS->GetGradientEstimator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkEncodedGradientShader *
vtkVolumeRayCastMapper::GetGradientShader()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkEncodedGradientShader";
		CODE:
		RETVAL = THIS->GetGradientShader();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetImageSampleDistance()
		CODE:
		RETVAL = THIS->GetImageSampleDistance();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetImageSampleDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetImageSampleDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetImageSampleDistanceMinValue()
		CODE:
		RETVAL = THIS->GetImageSampleDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMapper::GetIntermixIntersectingGeometry()
		CODE:
		RETVAL = THIS->GetIntermixIntersectingGeometry();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMapper::GetIntermixIntersectingGeometryMaxValue()
		CODE:
		RETVAL = THIS->GetIntermixIntersectingGeometryMaxValue();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMapper::GetIntermixIntersectingGeometryMinValue()
		CODE:
		RETVAL = THIS->GetIntermixIntersectingGeometryMinValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetMaximumImageSampleDistance()
		CODE:
		RETVAL = THIS->GetMaximumImageSampleDistance();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetMaximumImageSampleDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetMaximumImageSampleDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetMaximumImageSampleDistanceMinValue()
		CODE:
		RETVAL = THIS->GetMaximumImageSampleDistanceMinValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetMinimumImageSampleDistance()
		CODE:
		RETVAL = THIS->GetMinimumImageSampleDistance();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetMinimumImageSampleDistanceMaxValue()
		CODE:
		RETVAL = THIS->GetMinimumImageSampleDistanceMaxValue();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetMinimumImageSampleDistanceMinValue()
		CODE:
		RETVAL = THIS->GetMinimumImageSampleDistanceMinValue();
		OUTPUT:
		RETVAL


int
vtkVolumeRayCastMapper::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


float
vtkVolumeRayCastMapper::GetSampleDistance()
		CODE:
		RETVAL = THIS->GetSampleDistance();
		OUTPUT:
		RETVAL


vtkVolumeRayCastFunction *
vtkVolumeRayCastMapper::GetVolumeRayCastFunction()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkVolumeRayCastFunction";
		CODE:
		RETVAL = THIS->GetVolumeRayCastFunction();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkVolumeRayCastMapper::IntermixIntersectingGeometryOff()
		CODE:
		THIS->IntermixIntersectingGeometryOff();
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::IntermixIntersectingGeometryOn()
		CODE:
		THIS->IntermixIntersectingGeometryOn();
		XSRETURN_EMPTY;


static vtkVolumeRayCastMapper*
vtkVolumeRayCastMapper::New()
		CODE:
		RETVAL = vtkVolumeRayCastMapper::New();
		OUTPUT:
		RETVAL


void
vtkVolumeRayCastMapper::SetAutoAdjustSampleDistances(arg1)
		int 	arg1
		CODE:
		THIS->SetAutoAdjustSampleDistances(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetGradientEstimator(gradest)
		vtkEncodedGradientEstimator *	gradest
		CODE:
		THIS->SetGradientEstimator(gradest);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetImageSampleDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetImageSampleDistance(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetIntermixIntersectingGeometry(arg1)
		int 	arg1
		CODE:
		THIS->SetIntermixIntersectingGeometry(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetMaximumImageSampleDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMaximumImageSampleDistance(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetMinimumImageSampleDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetMinimumImageSampleDistance(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetNumberOfThreads(num)
		int 	num
		CODE:
		THIS->SetNumberOfThreads(num);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetSampleDistance(arg1)
		float 	arg1
		CODE:
		THIS->SetSampleDistance(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeRayCastMapper::SetVolumeRayCastFunction(arg1)
		vtkVolumeRayCastFunction *	arg1
		CODE:
		THIS->SetVolumeRayCastFunction(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeTextureMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeTextureMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkEncodedGradientEstimator *
vtkVolumeTextureMapper::GetGradientEstimator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkEncodedGradientEstimator";
		CODE:
		RETVAL = THIS->GetGradientEstimator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkEncodedGradientShader *
vtkVolumeTextureMapper::GetGradientShader()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkEncodedGradientShader";
		CODE:
		RETVAL = THIS->GetGradientShader();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkVolumeTextureMapper::SetGradientEstimator(gradest)
		vtkEncodedGradientEstimator *	gradest
		CODE:
		THIS->SetGradientEstimator(gradest);
		XSRETURN_EMPTY;


void
vtkVolumeTextureMapper::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::VolumeTextureMapper2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeTextureMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolumeTextureMapper2D::GetMaximumNumberOfPlanes()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfPlanes();
		OUTPUT:
		RETVAL


int
vtkVolumeTextureMapper2D::GetMaximumStorageSize()
		CODE:
		RETVAL = THIS->GetMaximumStorageSize();
		OUTPUT:
		RETVAL


int  *
vtkVolumeTextureMapper2D::GetTargetTextureSize()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTargetTextureSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkVolumeTextureMapper2D*
vtkVolumeTextureMapper2D::New()
		CODE:
		RETVAL = vtkVolumeTextureMapper2D::New();
		OUTPUT:
		RETVAL


void
vtkVolumeTextureMapper2D::SetMaximumNumberOfPlanes(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfPlanes(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeTextureMapper2D::SetMaximumStorageSize(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumStorageSize(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeTextureMapper2D::SetTargetTextureSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetTargetTextureSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeTextureMapper2D::SetTargetTextureSize\n");


MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::WorldPointPicker PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWorldPointPicker::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkWorldPointPicker*
vtkWorldPointPicker::New()
		CODE:
		RETVAL = vtkWorldPointPicker::New();
		OUTPUT:
		RETVAL


int
vtkWorldPointPicker::Pick(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		vtkRenderer *	arg4
		CODE:
		RETVAL = THIS->Pick(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWorldPointPicker::Pick\n");


#ifdef USE_MESA

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkProperty *
vtkMesaActor::MakeProperty()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProperty";
		CODE:
		RETVAL = THIS->MakeProperty();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkMesaActor*
vtkMesaActor::New()
		CODE:
		RETVAL = vtkMesaActor::New();
		OUTPUT:
		RETVAL


void
vtkMesaActor::Render(ren, mapper)
		vtkRenderer *	ren
		vtkMapper *	mapper
		CODE:
		THIS->Render(ren, mapper);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaCamera PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaCamera::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaCamera*
vtkMesaCamera::New()
		CODE:
		RETVAL = vtkMesaCamera::New();
		OUTPUT:
		RETVAL


void
vtkMesaCamera::Render(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Render(ren);
		XSRETURN_EMPTY;


void
vtkMesaCamera::UpdateViewport(ren)
		vtkRenderer *	ren
		CODE:
		THIS->UpdateViewport(ren);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaImageActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaImageActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkMesaImageActor::Load(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Load(ren);
		XSRETURN_EMPTY;


static vtkMesaImageActor*
vtkMesaImageActor::New()
		CODE:
		RETVAL = vtkMesaImageActor::New();
		OUTPUT:
		RETVAL


void
vtkMesaImageActor::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaImageMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaImageMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaImageMapper*
vtkMesaImageMapper::New()
		CODE:
		RETVAL = vtkMesaImageMapper::New();
		OUTPUT:
		RETVAL


void
vtkMesaImageMapper::RenderData(viewport, data, actor)
		vtkViewport *	viewport
		vtkImageData *	data
		vtkActor2D *	actor
		CODE:
		THIS->RenderData(viewport, data, actor);
		XSRETURN_EMPTY;


void
vtkMesaImageMapper::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaImageWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMesaImageWindow::EraseWindow()
		CODE:
		THIS->EraseWindow();
		XSRETURN_EMPTY;


void
vtkMesaImageWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkMesaImageWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMesaImageWindow::GetDesiredDepth()
		CODE:
		RETVAL = THIS->GetDesiredDepth();
		OUTPUT:
		RETVAL


void
vtkMesaImageWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


void
vtkMesaImageWindow::MakeDefaultWindow()
		CODE:
		THIS->MakeDefaultWindow();
		XSRETURN_EMPTY;


static vtkMesaImageWindow*
vtkMesaImageWindow::New()
		CODE:
		RETVAL = vtkMesaImageWindow::New();
		OUTPUT:
		RETVAL


void
vtkMesaImageWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkMesaImageWindow::SetOffScreenRendering(i)
		int 	i
		CODE:
		THIS->SetOffScreenRendering(i);
		XSRETURN_EMPTY;


void
vtkMesaImageWindow::SwapBuffers()
		CODE:
		THIS->SwapBuffers();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaImager PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMesaImager::Erase()
		CODE:
		THIS->Erase();
		XSRETURN_EMPTY;


const char *
vtkMesaImager::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaImager*
vtkMesaImager::New()
		CODE:
		RETVAL = vtkMesaImager::New();
		OUTPUT:
		RETVAL


int
vtkMesaImager::RenderOpaqueGeometry()
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaLight PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaLight::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaLight*
vtkMesaLight::New()
		CODE:
		RETVAL = vtkMesaLight::New();
		OUTPUT:
		RETVAL


void
vtkMesaLight::Render(ren, light_index)
		vtkRenderer *	ren
		int 	light_index
		CODE:
		THIS->Render(ren, light_index);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaPolyDataMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMesaPolyDataMapper::Draw(ren, a)
		vtkRenderer *	ren
		vtkActor *	a
		CODE:
		THIS->Draw(ren, a);
		XSRETURN_EMPTY;


const char *
vtkMesaPolyDataMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaPolyDataMapper*
vtkMesaPolyDataMapper::New()
		CODE:
		RETVAL = vtkMesaPolyDataMapper::New();
		OUTPUT:
		RETVAL


void
vtkMesaPolyDataMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkMesaPolyDataMapper::RenderPiece(ren, a)
		vtkRenderer *	ren
		vtkActor *	a
		CODE:
		THIS->RenderPiece(ren, a);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaPolyDataMapper2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaPolyDataMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaPolyDataMapper2D*
vtkMesaPolyDataMapper2D::New()
		CODE:
		RETVAL = vtkMesaPolyDataMapper2D::New();
		OUTPUT:
		RETVAL


void
vtkMesaPolyDataMapper2D::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaProperty PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMesaProperty::BackfaceRender(a, ren)
		vtkActor *	a
		vtkRenderer *	ren
		CODE:
		THIS->BackfaceRender(a, ren);
		XSRETURN_EMPTY;


const char *
vtkMesaProperty::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaProperty*
vtkMesaProperty::New()
		CODE:
		RETVAL = vtkMesaProperty::New();
		OUTPUT:
		RETVAL


void
vtkMesaProperty::Render(a, ren)
		vtkActor *	a
		vtkRenderer *	ren
		CODE:
		THIS->Render(a, ren);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaRenderWindow PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaRenderWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMesaRenderWindow::GetDepthBufferSize()
		CODE:
		RETVAL = THIS->GetDepthBufferSize();
		OUTPUT:
		RETVAL


static int
vtkMesaRenderWindow::GetGlobalMaximumNumberOfMultiSamples()
		CODE:
		RETVAL = vtkMesaRenderWindow::GetGlobalMaximumNumberOfMultiSamples();
		OUTPUT:
		RETVAL


int
vtkMesaRenderWindow::GetMultiSamples()
		CODE:
		RETVAL = THIS->GetMultiSamples();
		OUTPUT:
		RETVAL


void
vtkMesaRenderWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


static vtkMesaRenderWindow*
vtkMesaRenderWindow::New()
		CODE:
		RETVAL = vtkMesaRenderWindow::New();
		OUTPUT:
		RETVAL


void
vtkMesaRenderWindow::OpenGLInit()
		CODE:
		THIS->OpenGLInit();
		XSRETURN_EMPTY;


void
vtkMesaRenderWindow::RegisterTextureResource(id)
		GLuint 	id
		CODE:
		THIS->RegisterTextureResource(id);
		XSRETURN_EMPTY;


static void
vtkMesaRenderWindow::SetGlobalMaximumNumberOfMultiSamples(val)
		int 	val
		CODE:
		vtkMesaRenderWindow::SetGlobalMaximumNumberOfMultiSamples(val);
		XSRETURN_EMPTY;


void
vtkMesaRenderWindow::SetMultiSamples(arg1)
		int 	arg1
		CODE:
		THIS->SetMultiSamples(arg1);
		XSRETURN_EMPTY;


void
vtkMesaRenderWindow::StereoUpdate()
		CODE:
		THIS->StereoUpdate();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaRenderer PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMesaRenderer::Clear()
		CODE:
		THIS->Clear();
		XSRETURN_EMPTY;


void
vtkMesaRenderer::ClearLights()
		CODE:
		THIS->ClearLights();
		XSRETURN_EMPTY;


void
vtkMesaRenderer::DeviceRender()
		CODE:
		THIS->DeviceRender();
		XSRETURN_EMPTY;


const char *
vtkMesaRenderer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCamera *
vtkMesaRenderer::MakeCamera()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCamera";
		CODE:
		RETVAL = THIS->MakeCamera();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkLight *
vtkMesaRenderer::MakeLight()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLight";
		CODE:
		RETVAL = THIS->MakeLight();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkMesaRenderer*
vtkMesaRenderer::New()
		CODE:
		RETVAL = vtkMesaRenderer::New();
		OUTPUT:
		RETVAL


int
vtkMesaRenderer::UpdateLights()
		CODE:
		RETVAL = THIS->UpdateLights();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaTexture PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaTexture::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkMesaTexture::Load(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Load(ren);
		XSRETURN_EMPTY;


static vtkMesaTexture*
vtkMesaTexture::New()
		CODE:
		RETVAL = vtkMesaTexture::New();
		OUTPUT:
		RETVAL


void
vtkMesaTexture::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaVolumeRayCastMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaVolumeRayCastMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaVolumeRayCastMapper*
vtkMesaVolumeRayCastMapper::New()
		CODE:
		RETVAL = vtkMesaVolumeRayCastMapper::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::MesaVolumeTextureMapper2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMesaVolumeTextureMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMesaVolumeTextureMapper2D*
vtkMesaVolumeTextureMapper2D::New()
		CODE:
		RETVAL = vtkMesaVolumeTextureMapper2D::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XMesaRenderWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkXMesaRenderWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkXMesaRenderWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkXMesaRenderWindow::GetDesiredDepth()
		CODE:
		RETVAL = THIS->GetDesiredDepth();
		OUTPUT:
		RETVAL


int
vtkXMesaRenderWindow::GetEventPending()
		CODE:
		RETVAL = THIS->GetEventPending();
		OUTPUT:
		RETVAL


void
vtkXMesaRenderWindow::HideCursor()
		CODE:
		THIS->HideCursor();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


static vtkXMesaRenderWindow*
vtkXMesaRenderWindow::New()
		CODE:
		RETVAL = vtkXMesaRenderWindow::New();
		OUTPUT:
		RETVAL


void
vtkXMesaRenderWindow::PrefFullScreen()
		CODE:
		THIS->PrefFullScreen();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetFullScreen(arg1)
		int 	arg1
		CODE:
		THIS->SetFullScreen(arg1);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetNextWindowId(arg1)
		Window 	arg1
		CODE:
		THIS->SetNextWindowId(arg1);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetOffScreenRendering(i)
		int 	i
		CODE:
		THIS->SetOffScreenRendering(i);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetParentId(arg1 = 0)
	CASE: items == 2
		Window 	arg1
		CODE:
		THIS->SetParentId(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXMesaRenderWindow::SetParentId\n");



void
vtkXMesaRenderWindow::SetParentInfo(info)
		char *	info
		CODE:
		THIS->SetParentInfo(info);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXMesaRenderWindow::SetPosition\n");



void
vtkXMesaRenderWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXMesaRenderWindow::SetSize\n");



void
vtkXMesaRenderWindow::SetStereoCapableWindow(capable)
		int 	capable
		CODE:
		THIS->SetStereoCapableWindow(capable);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetWindowId(arg1 = 0)
	CASE: items == 2
		Window 	arg1
		CODE:
		THIS->SetWindowId(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXMesaRenderWindow::SetWindowId\n");



void
vtkXMesaRenderWindow::SetWindowInfo(info)
		char *	info
		CODE:
		THIS->SetWindowInfo(info);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::SetWindowName(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowName(arg1);
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::ShowCursor()
		CODE:
		THIS->ShowCursor();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::WindowInitialize()
		CODE:
		THIS->WindowInitialize();
		XSRETURN_EMPTY;


void
vtkXMesaRenderWindow::WindowRemap()
		CODE:
		THIS->WindowRemap();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XMesaTextMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkXMesaTextMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkXMesaTextMapper*
vtkXMesaTextMapper::New()
		CODE:
		RETVAL = vtkXMesaTextMapper::New();
		OUTPUT:
		RETVAL


void
vtkXMesaTextMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkXMesaTextMapper::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;


void
vtkXMesaTextMapper::RenderOverlay(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOverlay(viewport, actor);
		XSRETURN_EMPTY;

#endif

#ifndef USE_MESA

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLActor*
vtkOpenGLActor::New()
		CODE:
		RETVAL = vtkOpenGLActor::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLActor::Render(ren, mapper)
		vtkRenderer *	ren
		vtkMapper *	mapper
		CODE:
		THIS->Render(ren, mapper);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLCamera PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLCamera::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLCamera*
vtkOpenGLCamera::New()
		CODE:
		RETVAL = vtkOpenGLCamera::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLCamera::Render(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Render(ren);
		XSRETURN_EMPTY;


void
vtkOpenGLCamera::UpdateViewport(ren)
		vtkRenderer *	ren
		CODE:
		THIS->UpdateViewport(ren);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLImageActor PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLImageActor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkOpenGLImageActor::Load(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Load(ren);
		XSRETURN_EMPTY;


static vtkOpenGLImageActor*
vtkOpenGLImageActor::New()
		CODE:
		RETVAL = vtkOpenGLImageActor::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLImageActor::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLImageMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLImageMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLImageMapper*
vtkOpenGLImageMapper::New()
		CODE:
		RETVAL = vtkOpenGLImageMapper::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLImageMapper::RenderData(viewport, data, actor)
		vtkViewport *	viewport
		vtkImageData *	data
		vtkActor2D *	actor
		CODE:
		THIS->RenderData(viewport, data, actor);
		XSRETURN_EMPTY;


void
vtkOpenGLImageMapper::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLImager PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOpenGLImager::Erase()
		CODE:
		THIS->Erase();
		XSRETURN_EMPTY;


const char *
vtkOpenGLImager::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLImager*
vtkOpenGLImager::New()
		CODE:
		RETVAL = vtkOpenGLImager::New();
		OUTPUT:
		RETVAL


int
vtkOpenGLImager::RenderOpaqueGeometry()
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLLight PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLLight::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLLight*
vtkOpenGLLight::New()
		CODE:
		RETVAL = vtkOpenGLLight::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLLight::Render(ren, light_index)
		vtkRenderer *	ren
		int 	light_index
		CODE:
		THIS->Render(ren, light_index);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLPolyDataMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOpenGLPolyDataMapper::Draw(ren, a)
		vtkRenderer *	ren
		vtkActor *	a
		CODE:
		THIS->Draw(ren, a);
		XSRETURN_EMPTY;


const char *
vtkOpenGLPolyDataMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLPolyDataMapper*
vtkOpenGLPolyDataMapper::New()
		CODE:
		RETVAL = vtkOpenGLPolyDataMapper::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLPolyDataMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkOpenGLPolyDataMapper::RenderPiece(ren, a)
		vtkRenderer *	ren
		vtkActor *	a
		CODE:
		THIS->RenderPiece(ren, a);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLPolyDataMapper2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLPolyDataMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLPolyDataMapper2D*
vtkOpenGLPolyDataMapper2D::New()
		CODE:
		RETVAL = vtkOpenGLPolyDataMapper2D::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLPolyDataMapper2D::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLProperty PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOpenGLProperty::BackfaceRender(a, ren)
		vtkActor *	a
		vtkRenderer *	ren
		CODE:
		THIS->BackfaceRender(a, ren);
		XSRETURN_EMPTY;


const char *
vtkOpenGLProperty::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLProperty*
vtkOpenGLProperty::New()
		CODE:
		RETVAL = vtkOpenGLProperty::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLProperty::Render(a, ren)
		vtkActor *	a
		vtkRenderer *	ren
		CODE:
		THIS->Render(a, ren);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLRenderer PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOpenGLRenderer::Clear()
		CODE:
		THIS->Clear();
		XSRETURN_EMPTY;


void
vtkOpenGLRenderer::ClearLights()
		CODE:
		THIS->ClearLights();
		XSRETURN_EMPTY;


void
vtkOpenGLRenderer::DeviceRender()
		CODE:
		THIS->DeviceRender();
		XSRETURN_EMPTY;


const char *
vtkOpenGLRenderer::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLRenderer*
vtkOpenGLRenderer::New()
		CODE:
		RETVAL = vtkOpenGLRenderer::New();
		OUTPUT:
		RETVAL


int
vtkOpenGLRenderer::UpdateLights()
		CODE:
		RETVAL = THIS->UpdateLights();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLTexture PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLTexture::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkOpenGLTexture::Load(ren)
		vtkRenderer *	ren
		CODE:
		THIS->Load(ren);
		XSRETURN_EMPTY;


static vtkOpenGLTexture*
vtkOpenGLTexture::New()
		CODE:
		RETVAL = vtkOpenGLTexture::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLTexture::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLVolumeRayCastMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLVolumeRayCastMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLVolumeRayCastMapper*
vtkOpenGLVolumeRayCastMapper::New()
		CODE:
		RETVAL = vtkOpenGLVolumeRayCastMapper::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLVolumeTextureMapper2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOpenGLVolumeTextureMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOpenGLVolumeTextureMapper2D*
vtkOpenGLVolumeTextureMapper2D::New()
		CODE:
		RETVAL = vtkOpenGLVolumeTextureMapper2D::New();
		OUTPUT:
		RETVAL

#endif

#ifndef WIN32

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::OpenGLImageWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOpenGLImageWindow::EraseWindow()
		CODE:
		THIS->EraseWindow();
		XSRETURN_EMPTY;


void
vtkOpenGLImageWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkOpenGLImageWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkOpenGLImageWindow::GetDesiredDepth()
		CODE:
		RETVAL = THIS->GetDesiredDepth();
		OUTPUT:
		RETVAL


void
vtkOpenGLImageWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


void
vtkOpenGLImageWindow::MakeDefaultWindow()
		CODE:
		THIS->MakeDefaultWindow();
		XSRETURN_EMPTY;


static vtkOpenGLImageWindow*
vtkOpenGLImageWindow::New()
		CODE:
		RETVAL = vtkOpenGLImageWindow::New();
		OUTPUT:
		RETVAL


void
vtkOpenGLImageWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkOpenGLImageWindow::SwapBuffers()
		CODE:
		THIS->SwapBuffers();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XImageWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkXImageWindow::EraseWindow()
		CODE:
		THIS->EraseWindow();
		XSRETURN_EMPTY;


void
vtkXImageWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkXImageWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkXImageWindow::GetDesiredDepth()
		CODE:
		RETVAL = THIS->GetDesiredDepth();
		OUTPUT:
		RETVAL


int
vtkXImageWindow::GetNumberOfColors()
		CODE:
		RETVAL = THIS->GetNumberOfColors();
		OUTPUT:
		RETVAL


int *
vtkXImageWindow::GetPosition()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXImageWindow::GetPosition\n");



int *
vtkXImageWindow::GetSize()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXImageWindow::GetSize\n");



int
vtkXImageWindow::GetVisualClass()
		CODE:
		RETVAL = THIS->GetVisualClass();
		OUTPUT:
		RETVAL


int
vtkXImageWindow::GetVisualDepth()
		CODE:
		RETVAL = THIS->GetVisualDepth();
		OUTPUT:
		RETVAL


static vtkXImageWindow*
vtkXImageWindow::New()
		CODE:
		RETVAL = vtkXImageWindow::New();
		OUTPUT:
		RETVAL


void
vtkXImageWindow::SetBackgroundColor(r, g, b)
		float 	r
		float 	g
		float 	b
		CODE:
		THIS->SetBackgroundColor(r, g, b);
		XSRETURN_EMPTY;


void
vtkXImageWindow::SetParentId(arg1 = 0)
	CASE: items == 2
		Window 	arg1
		CODE:
		THIS->SetParentId(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXImageWindow::SetParentId\n");



void
vtkXImageWindow::SetParentInfo(info)
		char *	info
		CODE:
		THIS->SetParentInfo(info);
		XSRETURN_EMPTY;


void
vtkXImageWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXImageWindow::SetPosition\n");



void
vtkXImageWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXImageWindow::SetSize\n");



void
vtkXImageWindow::SetWindowId(arg1 = 0)
	CASE: items == 2
		Window 	arg1
		CODE:
		THIS->SetWindowId(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXImageWindow::SetWindowId\n");



void
vtkXImageWindow::SetWindowInfo(info)
		char *	info
		CODE:
		THIS->SetWindowInfo(info);
		XSRETURN_EMPTY;


void
vtkXImageWindow::SetWindowName(name)
		char *	name
		CODE:
		THIS->SetWindowName(name);
		XSRETURN_EMPTY;


void
vtkXImageWindow::SwapBuffers()
		CODE:
		THIS->SwapBuffers();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XOpenGLRenderWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkXOpenGLRenderWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkXOpenGLRenderWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkXOpenGLRenderWindow::GetDesiredDepth()
		CODE:
		RETVAL = THIS->GetDesiredDepth();
		OUTPUT:
		RETVAL


int
vtkXOpenGLRenderWindow::GetEventPending()
		CODE:
		RETVAL = THIS->GetEventPending();
		OUTPUT:
		RETVAL


void
vtkXOpenGLRenderWindow::HideCursor()
		CODE:
		THIS->HideCursor();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


static vtkXOpenGLRenderWindow*
vtkXOpenGLRenderWindow::New()
		CODE:
		RETVAL = vtkXOpenGLRenderWindow::New();
		OUTPUT:
		RETVAL


void
vtkXOpenGLRenderWindow::PrefFullScreen()
		CODE:
		THIS->PrefFullScreen();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetFullScreen(arg1)
		int 	arg1
		CODE:
		THIS->SetFullScreen(arg1);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetNextWindowId(arg1)
		Window 	arg1
		CODE:
		THIS->SetNextWindowId(arg1);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetOffScreenRendering(i)
		int 	i
		CODE:
		THIS->SetOffScreenRendering(i);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetParentId(arg1 = 0)
	CASE: items == 2
		Window 	arg1
		CODE:
		THIS->SetParentId(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXOpenGLRenderWindow::SetParentId\n");



void
vtkXOpenGLRenderWindow::SetParentInfo(info)
		char *	info
		CODE:
		THIS->SetParentInfo(info);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXOpenGLRenderWindow::SetPosition\n");



void
vtkXOpenGLRenderWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXOpenGLRenderWindow::SetSize\n");



void
vtkXOpenGLRenderWindow::SetStereoCapableWindow(capable)
		int 	capable
		CODE:
		THIS->SetStereoCapableWindow(capable);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetWindowId(arg1 = 0)
	CASE: items == 2
		Window 	arg1
		CODE:
		THIS->SetWindowId(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXOpenGLRenderWindow::SetWindowId\n");



void
vtkXOpenGLRenderWindow::SetWindowInfo(info)
		char *	info
		CODE:
		THIS->SetWindowInfo(info);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::SetWindowName(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowName(arg1);
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::ShowCursor()
		CODE:
		THIS->ShowCursor();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::WindowInitialize()
		CODE:
		THIS->WindowInitialize();
		XSRETURN_EMPTY;


void
vtkXOpenGLRenderWindow::WindowRemap()
		CODE:
		THIS->WindowRemap();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XOpenGLTextMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkXOpenGLTextMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkXOpenGLTextMapper*
vtkXOpenGLTextMapper::New()
		CODE:
		RETVAL = vtkXOpenGLTextMapper::New();
		OUTPUT:
		RETVAL


void
vtkXOpenGLTextMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkXOpenGLTextMapper::RenderGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderGeometry(viewport, actor);
		XSRETURN_EMPTY;


void
vtkXOpenGLTextMapper::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;


void
vtkXOpenGLTextMapper::RenderOverlay(arg1, arg2)
		vtkViewport *	arg1
		vtkActor2D *	arg2
		CODE:
		THIS->RenderOverlay(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkXOpenGLTextMapper::RenderTranslucentGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderTranslucentGeometry(viewport, actor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XRenderWindowInteractor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkXRenderWindowInteractor::BreakLoopFlagOff()
		CODE:
		THIS->BreakLoopFlagOff();
		XSRETURN_EMPTY;


void
vtkXRenderWindowInteractor::BreakLoopFlagOn()
		CODE:
		THIS->BreakLoopFlagOn();
		XSRETURN_EMPTY;


int
vtkXRenderWindowInteractor::CreateTimer(timertype)
		int 	timertype
		CODE:
		RETVAL = THIS->CreateTimer(timertype);
		OUTPUT:
		RETVAL


int
vtkXRenderWindowInteractor::DestroyTimer()
		CODE:
		RETVAL = THIS->DestroyTimer();
		OUTPUT:
		RETVAL


void
vtkXRenderWindowInteractor::Disable()
		CODE:
		THIS->Disable();
		XSRETURN_EMPTY;


void
vtkXRenderWindowInteractor::Enable()
		CODE:
		THIS->Enable();
		XSRETURN_EMPTY;


int
vtkXRenderWindowInteractor::GetBreakLoopFlag()
		CODE:
		RETVAL = THIS->GetBreakLoopFlag();
		OUTPUT:
		RETVAL


const char *
vtkXRenderWindowInteractor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkXRenderWindowInteractor::Initialize()
	CASE: items == 1
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkXRenderWindowInteractor::Initialize\n");



static vtkXRenderWindowInteractor*
vtkXRenderWindowInteractor::New()
		CODE:
		RETVAL = vtkXRenderWindowInteractor::New();
		OUTPUT:
		RETVAL


void
vtkXRenderWindowInteractor::SetBreakLoopFlag(arg1)
		int 	arg1
		CODE:
		THIS->SetBreakLoopFlag(arg1);
		XSRETURN_EMPTY;


void
vtkXRenderWindowInteractor::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkXRenderWindowInteractor::TerminateApp()
		CODE:
		THIS->TerminateApp();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::XTextMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkXTextMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkXTextMapper*
vtkXTextMapper::New()
		CODE:
		RETVAL = vtkXTextMapper::New();
		OUTPUT:
		RETVAL


void
vtkXTextMapper::SetFontSize(size)
		int 	size
		CODE:
		THIS->SetFontSize(size);
		XSRETURN_EMPTY;

#endif

#ifdef WIN32

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Win32OpenGLImageWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWin32OpenGLImageWindow::Clean()
		CODE:
		THIS->Clean();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkWin32OpenGLImageWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkWin32OpenGLImageWindow *
vtkWin32OpenGLImageWindow::GetOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkWin32OpenGLImageWindow";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkWin32OpenGLImageWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::MakeDefaultWindow()
		CODE:
		THIS->MakeDefaultWindow();
		XSRETURN_EMPTY;


static vtkWin32OpenGLImageWindow*
vtkWin32OpenGLImageWindow::New()
		CODE:
		RETVAL = vtkWin32OpenGLImageWindow::New();
		OUTPUT:
		RETVAL


void
vtkWin32OpenGLImageWindow::OpenGLInit()
		CODE:
		THIS->OpenGLInit();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::ResumeScreenRendering()
		CODE:
		THIS->ResumeScreenRendering();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SetParentInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetParentInfo(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWin32OpenGLImageWindow::SetPosition\n");



void
vtkWin32OpenGLImageWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWin32OpenGLImageWindow::SetSize\n");



void
vtkWin32OpenGLImageWindow::SetWindowInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowInfo(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SetWindowName(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowName(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SetupMemoryRendering(x, y, prn)
		int 	x
		int 	y
		HDC 	prn
		CODE:
		THIS->SetupMemoryRendering(x, y, prn);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SetupPalette(hDC)
		HDC 	hDC
		CODE:
		THIS->SetupPalette(hDC);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SetupPixelFormat(hDC, dwFlags, debug, bpp, zbpp)
		HDC 	hDC
		DWORD 	dwFlags
		int 	debug
		int 	bpp
		int 	zbpp
		CODE:
		THIS->SetupPixelFormat(hDC, dwFlags, debug, bpp, zbpp);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLImageWindow::SwapBuffers()
		CODE:
		THIS->SwapBuffers();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Win32OpenGLRenderWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWin32OpenGLRenderWindow::Clean()
		CODE:
		THIS->Clean();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::Frame()
		CODE:
		THIS->Frame();
		XSRETURN_EMPTY;


const char *
vtkWin32OpenGLRenderWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkWin32OpenGLRenderWindow::GetEventPending()
		CODE:
		RETVAL = THIS->GetEventPending();
		OUTPUT:
		RETVAL


void
vtkWin32OpenGLRenderWindow::HideCursor()
		CODE:
		THIS->HideCursor();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


static vtkWin32OpenGLRenderWindow*
vtkWin32OpenGLRenderWindow::New()
		CODE:
		RETVAL = vtkWin32OpenGLRenderWindow::New();
		OUTPUT:
		RETVAL


void
vtkWin32OpenGLRenderWindow::PrefFullScreen()
		CODE:
		THIS->PrefFullScreen();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::ResumeScreenRendering()
		CODE:
		THIS->ResumeScreenRendering();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetFullScreen(arg1)
		int 	arg1
		CODE:
		THIS->SetFullScreen(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetOffScreenRendering(offscreen)
		int 	offscreen
		CODE:
		THIS->SetOffScreenRendering(offscreen);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetParentInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetParentInfo(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWin32OpenGLRenderWindow::SetPosition\n");



void
vtkWin32OpenGLRenderWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWin32OpenGLRenderWindow::SetSize\n");



void
vtkWin32OpenGLRenderWindow::SetStereoCapableWindow(capable)
		int 	capable
		CODE:
		THIS->SetStereoCapableWindow(capable);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetWindowInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowInfo(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetWindowName(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowName(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetupMemoryRendering(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		HDC 	arg3
		CODE:
		THIS->SetupMemoryRendering(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 2
		HBITMAP 	arg1
		CODE:
		THIS->SetupMemoryRendering(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWin32OpenGLRenderWindow::SetupMemoryRendering\n");



void
vtkWin32OpenGLRenderWindow::SetupPalette(hDC)
		HDC 	hDC
		CODE:
		THIS->SetupPalette(hDC);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::SetupPixelFormat(hDC, dwFlags, debug, bpp, zbpp)
		HDC 	hDC
		DWORD 	dwFlags
		int 	debug
		int 	bpp
		int 	zbpp
		CODE:
		THIS->SetupPixelFormat(hDC, dwFlags, debug, bpp, zbpp);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::ShowCursor()
		CODE:
		THIS->ShowCursor();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::WindowInitialize()
		CODE:
		THIS->WindowInitialize();
		XSRETURN_EMPTY;


void
vtkWin32OpenGLRenderWindow::WindowRemap()
		CODE:
		THIS->WindowRemap();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Win32OpenGLTextMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWin32OpenGLTextMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static int
vtkWin32OpenGLTextMapper::GetListBaseForFont(tm, vp)
		vtkTextMapper *	tm
		vtkViewport *	vp
		CODE:
		RETVAL = vtkWin32OpenGLTextMapper::GetListBaseForFont(tm, vp);
		OUTPUT:
		RETVAL


static vtkWin32OpenGLTextMapper*
vtkWin32OpenGLTextMapper::New()
		CODE:
		RETVAL = vtkWin32OpenGLTextMapper::New();
		OUTPUT:
		RETVAL


void
vtkWin32OpenGLTextMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLTextMapper::RenderGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderGeometry(viewport, actor);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLTextMapper::RenderOpaqueGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOpaqueGeometry(viewport, actor);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLTextMapper::RenderOverlay(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderOverlay(viewport, actor);
		XSRETURN_EMPTY;


void
vtkWin32OpenGLTextMapper::RenderTranslucentGeometry(viewport, actor)
		vtkViewport *	viewport
		vtkActor2D *	actor
		CODE:
		THIS->RenderTranslucentGeometry(viewport, actor);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Win32RenderWindowInteractor PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkWin32RenderWindowInteractor::CreateTimer(timertype)
		int 	timertype
		CODE:
		RETVAL = THIS->CreateTimer(timertype);
		OUTPUT:
		RETVAL


int
vtkWin32RenderWindowInteractor::DestroyTimer()
		CODE:
		RETVAL = THIS->DestroyTimer();
		OUTPUT:
		RETVAL


void
vtkWin32RenderWindowInteractor::Disable()
		CODE:
		THIS->Disable();
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::Enable()
		CODE:
		THIS->Enable();
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::ExitCallback()
		CODE:
		THIS->ExitCallback();
		XSRETURN_EMPTY;


const char *
vtkWin32RenderWindowInteractor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkWin32RenderWindowInteractor::GetInstallMessageProc()
		CODE:
		RETVAL = THIS->GetInstallMessageProc();
		OUTPUT:
		RETVAL


void
vtkWin32RenderWindowInteractor::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::InstallMessageProcOff()
		CODE:
		THIS->InstallMessageProcOff();
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::InstallMessageProcOn()
		CODE:
		THIS->InstallMessageProcOn();
		XSRETURN_EMPTY;


static vtkWin32RenderWindowInteractor*
vtkWin32RenderWindowInteractor::New()
		CODE:
		RETVAL = vtkWin32RenderWindowInteractor::New();
		OUTPUT:
		RETVAL


static void
vtkWin32RenderWindowInteractor::SetClassExitMethod(func)
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
		    hv_store_ent(HashEntry, newSVpv("SetClassExitMethod",0), newRV(func), 0);
		}
		vtkWin32RenderWindowInteractor::SetClassExitMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::SetInstallMessageProc(arg1)
		int 	arg1
		CODE:
		THIS->SetInstallMessageProc(arg1);
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkWin32RenderWindowInteractor::TerminateApp()
		CODE:
		THIS->TerminateApp();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Rendering	PACKAGE = Graphics::VTK::Win32TextMapper PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWin32TextMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkWin32TextMapper*
vtkWin32TextMapper::New()
		CODE:
		RETVAL = vtkWin32TextMapper::New();
		OUTPUT:
		RETVAL

#endif


