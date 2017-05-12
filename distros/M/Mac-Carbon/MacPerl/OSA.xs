/* $Header: /cvsroot/macperl/perl/macos/ext/MacPerl/OSA.xs,v 1.4 2002/11/13 02:04:53 pudge Exp $
 *
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: OSA.xs,v $
 * Revision 1.4  2002/11/13 02:04:53  pudge
 * Aieeeeee!  Big ol' Carbon update.
 *
 * Revision 1.3  2001/12/19 22:54:15  pudge
 * Make DoAppleScript return errors in $@
 *
 * Revision 1.2  2001/04/16 04:45:15  neeri
 * Switch from atexit() to Perl_call_atexit (MacPerl bug #232158)
 *
 * Revision 1.1  2000/08/14 03:39:34  neeri
 * Checked into Sourceforge
 *
 * Revision 1.1  2000/05/14 21:45:04  neeri
 * First build released to public
 *
 * Revision 1.1  1997/04/07 20:51:08  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifndef MACOS_TRADITIONAL
#include "../Carbon.h"
#endif
#include <Types.h>
#include <Components.h>
#include <AppleEvents.h>
#include <AppleScript.h>
#include <OSA.h>
#include <Gestalt.h>

ComponentInstance gScriptingComponent;

void ShutDownAppleScript(pTHX_ void * p)
{
	CloseComponent(gScriptingComponent);
	
	gScriptingComponent = nil;
}

OSErr InitAppleScript(void)
{
	OSErr                myErr;
	ComponentDescription descr;
	ComponentDescription capabilities;
	Component            myComponent;
	short                retryCount;
	long						res;
			
	retryCount = 0;
	
	if (Gestalt(gestaltAppleEventsAttr, &res))
		return -1;
	else if (!(res & (1<<gestaltAppleEventsPresent)))
		return -1;
	else if (Gestalt(gestaltComponentMgr, &res))
		return -1;
		
	descr.componentType         = kOSAComponentType;
	descr.componentSubType      = kAppleScriptSubtype;
	descr.componentManufacturer = (OSType) 0;
	descr.componentFlags        = kOSASupportsCompiling + 
											kOSASupportsGetSource + 
											kOSASupportsAESending;
	descr.componentFlagsMask    = descr.componentFlags;
	
	myComponent = FindNextComponent(nil, &descr);
	
	if (myComponent==nil)
	  	return -1;
	else {
		myErr = GetComponentInfo(myComponent, &capabilities, nil, nil, nil);
		gScriptingComponent = OpenComponent(myComponent);
		if (!gScriptingComponent)
			return(-1);
		else
			Perl_call_atexit(aTHX_ ShutDownAppleScript, NULL);
	}
		
	return myErr;
}

MODULE = OSA	PACKAGE = MacPerl	PREFIX = MP_

void
MP_Reply(reply)
	char *	reply
	CODE:
	{
#ifndef MACOS_TRADITIONAL
	croak("Usage: MacPerl::Reply unsupported in Carbon");
#else
		if (gMacPerl_Reply)
			DisposeHandle(gMacPerl_Reply);

		PtrToHand(reply, &gMacPerl_Reply, strlen(reply));
#endif
	}

void
MP_DoAppleScript(script)
	SV *	script
	CODE:
	{
		OSAError	myOSAErr;
		char *		scriptText;
		STRLEN		scriptTextLen;
		AEDesc		scriptTextDesc;
		AEDesc		scriptResultDesc;

		if (!gScriptingComponent && InitAppleScript())
			croak("MacPerl::DoAppleScript couldn't initialize AppleScript");

		sv_setpvn(ERRSV, "", 0);
		scriptText = (char*) SvPV(ST(0), scriptTextLen);
		AECreateDesc(typeChar, scriptText, scriptTextLen, &scriptTextDesc);

		myOSAErr = OSADoScript(
			gScriptingComponent, 
			&scriptTextDesc, 
			kOSANullScript, 
			typeChar, 
			kOSAModeCanInteract,
			&scriptResultDesc
		);
		AEDisposeDesc(&scriptTextDesc);

		if (!myOSAErr) {
			char *		scriptResultData;
			STRLEN		scriptResultLen;
			AEDesc		scriptResultDataDesc;

			if (!AECoerceDesc(&scriptResultDesc, typeChar, &scriptResultDataDesc)) {
#ifdef MACOS_TRADITIONAL
				HLock(scriptResultDataDesc.dataHandle);
				scriptResultLen  = GetHandleSize(scriptResultDataDesc.dataHandle);
				scriptResultData = *scriptResultDataDesc.dataHandle;
#else
				scriptResultLen  = AEGetDescDataSize(&scriptResultDataDesc);
				scriptResultData = NewPtr(scriptResultLen);
				AEGetDescData(&scriptResultDataDesc, scriptResultData, scriptResultLen);
#endif

				ST(0) = sv_2mortal(newSVpv(scriptResultData, scriptResultLen));

				AEDisposeDesc(&scriptResultDataDesc);
#ifndef MACOS_TRADITIONAL
				DisposePtr(scriptResultData);
#endif
			} else
				ST(0) = &PL_sv_undef;

			AEDisposeDesc(&scriptResultDesc);
		}

		else {

			if (myOSAErr == errOSAScriptError) {
				AEDesc		errorDesc;
				AEDesc		errorDataDesc;

				OSAScriptError(
					gScriptingComponent,
					kOSAErrorMessage,
					typeChar,
					&errorDesc
				);

				if (!AECoerceDesc(&errorDesc, typeChar, &errorDataDesc)) {
					char *		errorData;
					STRLEN		errorLen;
#ifdef MACOS_TRADITIONAL
					HLock(errorDataDesc.dataHandle);
					errorLen  = GetHandleSize(errorDataDesc.dataHandle);
					errorData = *errorDataDesc.dataHandle;
#else
					errorLen  = AEGetDescDataSize(&errorDataDesc);
					errorData = NewPtr(errorLen);
					AEGetDescData(&errorDataDesc, errorData, errorLen);
#endif

					/* AppleScript errors end in '.', we don't want it */
					if (strchr(errorData+errorLen-1, '.')) {
						errorLen--;
					}
					/* set $@ */
					sv_setpvn(ERRSV, errorData, errorLen);

					AEDisposeDesc(&errorDataDesc);
#ifndef MACOS_TRADITIONAL
					DisposePtr(errorData);
#endif
				}
				AEDisposeDesc(&errorDesc);
			}

			ST(0) = &PL_sv_undef;
		}
	}
