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

#ifndef WIN32
#define Arg X11_Arg
#include "../pTk/vtkXRenderWindowTclInteractor.h"
#endif

/* #include "../pTk/vtkTkport.h" */
#
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

#include "../pTk/vtkTkRenderWidget.h"



DECLARE_VTABLES;
DECLARE_WIN32_VTABLES;

MODULE = Graphics::VTK::Tk::vtkInteractor	PACKAGE = Tk

PROTOTYPES: DISABLE

void
vtkinteractor(...)
CODE:
 {
  XSRETURN(XSTkCommand(cv,(Tcl_CmdProc *)vtkTkRenderWidget_Cmd,items,&ST(0)));
 }



BOOT:
 {
  IMPORT_VTABLES;
  IMPORT_WIN32_VTABLES;

  
 }


