#include <EXTERN.h>

/* avoid some nasty defines on win32 that cause c++ compilation to fail */
#ifdef WIN32
#define WIN32IOP_H
#endif

#include <perl.h>
#include <XSUB.h>

/* 'THIS' gets redefined to 'void' in 
the standard mingw include 'basetyps.h', which causes problems with
the 'THIS' that appears in XS code. */
#ifdef __MINGW32__
#undef THIS
#endif

#include "vtkPerl.h"

/* Don't include Xwindows stuff on win32 */
#ifndef WIN32
#include "vtkXRenderWindowTclInteractor.h"
#endif


#include "tkGlue.def"

#include "tkPort.h"
#include "tkInt.h"
/* Include win32 Tk Stuff */
#ifdef WIN32
#include "tkWin.h"
#include "tkWinInt.h"
#endif
#include "tkVMacro.h"
#include "tkGlue.h"
#include "tkGlue.m"




DECLARE_VTABLES;
DECLARE_WIN32_VTABLES;

MODULE = Graphics::VTK::Tk	PACKAGE = Graphics::VTK

PROTOTYPES: DISABLE


BOOT:
 {
  IMPORT_VTABLES;
  IMPORT_WIN32_VTABLES;
 }

#ifndef WIN32

MODULE = Graphics::VTK::Tk	PACKAGE = Graphics::VTK::XRenderWindowTclInteractor PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkXRenderWindowTclInteractor::CreateTimer(timertype)
		int 	timertype
		CODE:
		RETVAL = THIS->CreateTimer(timertype);
		OUTPUT:
		RETVAL


int
vtkXRenderWindowTclInteractor::DestroyTimer()
		CODE:
		RETVAL = THIS->DestroyTimer();
		OUTPUT:
		RETVAL


void
vtkXRenderWindowTclInteractor::Disable()
		CODE:
		THIS->Disable();
		XSRETURN_EMPTY;


void
vtkXRenderWindowTclInteractor::Enable()
		CODE:
		THIS->Enable();
		XSRETURN_EMPTY;



const char *
vtkXRenderWindowTclInteractor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL




void
vtkXRenderWindowTclInteractor::Initialize(arg1 = 0)
	CASE: items == 2
		XtAppContext 	arg1
		CODE:
		THIS->Initialize(arg1);
		XSRETURN_EMPTY;
	CASE: items == 1
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


static vtkXRenderWindowTclInteractor*
vtkXRenderWindowTclInteractor::New()
		CODE:
		RETVAL = vtkXRenderWindowTclInteractor::New();
		OUTPUT:
		RETVAL



void
vtkXRenderWindowTclInteractor::Start()
		CODE:
		THIS->Start();
		XSRETURN_EMPTY;


void
vtkXRenderWindowTclInteractor::TerminateApp()
		CODE:
		THIS->TerminateApp();
		XSRETURN_EMPTY;


void
vtkXRenderWindowTclInteractor::UpdateSize(arg1, arg2)
		int 	arg1
		int 	arg2
		CODE:
		THIS->UpdateSize(arg1, arg2);
		XSRETURN_EMPTY;

#endif
