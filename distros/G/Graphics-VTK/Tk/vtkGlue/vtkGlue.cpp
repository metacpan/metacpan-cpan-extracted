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

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "pTk/tkInt.h"
#include "pTk/tkVMacro.h"
#include "tkGlue.h"
#include "tkGlue.m"

#include <stdlib.h>
#include "vtkObject.h"


/* Replacements for vtk's functions that appear in vtkTclUtil.cxx that are
   needed by the tk widget functions */

/* The original vtk function creates a tcl object from a pointer to 
   a vtk object, and then calls this function to "register" the pointer
   with Tcl. This scheme is not really compatible with perl so here we
   delete the object just created, then re-create it by calling the
   perl 'new' method.

*/
EXTERN void vtkTclGetObjectFromPointer(Tcl_Interp *interp, void * &temp1,
			   int (*command)(ClientData, 
					  Tcl_Interp *,int, char *[])){
			
	int count;
  	vtkObject *temp = (vtkObject *)temp1;
	const char * objectName; // Name of the object created
	char tempName[200];
	dSP; // Declare local copy of perl stack
	SV* object;  // Object created (perl reference)
	
	// Get object name from temp->getClassName
	objectName = temp->GetClassName();
			  
	// Delete object created (We will create it again using the
	//  conventional perl method
	temp->Delete();
	
	strcpy(tempName, "Graphics::VTK::");
	strncat(tempName, objectName+3,194); /* +3 added to skip the leading 'vtk' */
	
	// Implementation-specific (i.e. opengl, mesa, win32) render
	//  window object names are created as VTK::vtkRenderWindow
	//  vktRenderWindow takes care or calling the implementation specific
	// object constructor
	//printf("TempName is '%s'\n",tempName);
	if( !strcmp(tempName, "Graphics::VTK::MesaRenderWindow") ||
		!strcmp(tempName, "Graphics::VTK::OpenGLRenderWindow") ||
		!strcmp(tempName, "Graphics::VTK::Win32OpenGLRenderWindow") ||
		!strcmp(tempName, "Graphics::VTK::QuartzRenderWindow") ||
		!strcmp(tempName, "Graphics::VTK::XRenderWindow") ){
			strcpy(tempName,"Graphics::VTK::RenderWindow");};

	// Implementation-specific (i.e. opengl, mesa, win32) render
	//  window object names are created as VTK::vtkRenderWindow
	//  vktRenderWindow takes care or calling the implementation specific
	// object constructor
	if( !strcmp(tempName, "Graphics::VTK::MesaImageWindow") ||
		!strcmp(tempName, "Graphics::VTK::OpenGLImageWindow") ||
		!strcmp(tempName, "Graphics::VTK::QuartzImageWindow") ||
		!strcmp(tempName, "Graphics::VTK::XImageWindow") ){
			strcpy(tempName,"Graphics::VTK::ImageWindow");};

	objectName = tempName;
			
			
	//printf("Creating a object type '%s'\n",objectName);
	
	// Create perl object using xS code for calling class->new
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv((char*)objectName, 0))) ;
        PUTBACK;
        count = perl_call_method((char *)"new", G_SCALAR);

	SPAGAIN;  // Refresh local copy of the stack pointer
	
	if( count != 1){
		printf("count = %d\n",count);
		croak("Error calling new in vtkTclGetObjectFromPointer\n");
	}

	
	object = POPs;
	
	//printf("Objects Ref count is %d\n",SvREFCNT(object));
    	/* Store the object in the interp result */
	Tcl_SetObjResult(interp, object);	
	//printf("Objects Ref count is %d\n",SvREFCNT(object));
	//printf("Object being returned is '%s'\n",SvPV_nolen(object)); 
		
	// Get the pointer using XS macros and place in temp
	temp1 = (void *)SvIV((SV*)SvRV(object));
	
	// Cleanup
	PUTBACK ;

	//printf("Objects Ref count is %d\n",SvREFCNT(object));
	
	
	
}

/* Replacement for the original vtk function that gets a pointer
   from a VTK object

*/
EXTERN void *vtkTclGetPointerFromObject( Arg object,
					       char *result_type,
					       Tcl_Interp *interp, 
					       int &error){

	
	return (void *)SvIV((SV*)SvRV(object));
}

/* Function used only for debugging

*/
EXTERN int Tcl_RefCount( Arg object){				  

	printf("Tcl_RefCount called '%s'\n",SvPV(object, PL_na)); 
	
	return SvREFCNT(object);
}
	
