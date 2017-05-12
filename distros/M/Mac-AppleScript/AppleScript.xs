#include <Carbon/Carbon.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Based on Apple code from
   http://developer.apple.com/qa/qa2001/qa1026.html */

MODULE = Mac::AppleScript		PACKAGE = Mac::AppleScript		

SV *
RunAppleScript(SV *text)
PPCODE:
{
    ComponentInstance theComponent;
    AEDesc scriptTextDesc;
    AEDesc resultData;
    OSStatus err = noErr;
    OSAID scriptID, resultID;
    SV *returnSV;
    
    /* set up locals to a known state */
    theComponent = NULL;
    AECreateDesc(typeNull, NULL, 0, &scriptTextDesc);
    scriptID = kOSANullScript;
    resultID = kOSANullScript;

    /* open the scripting component */
    theComponent = OpenDefaultComponent(kOSAComponentType,
                    typeAppleScript);
    if (theComponent == NULL) { 
      err = paramErr;
      croak("Can't open scripting component");
    }

    /* put the script text into an aedesc */
    /* we need to tell applescript this is text. Whether it's plain
       char or UTF8 depends on flags in the string */
    if (SvUTF8(text)) {
        err = AECreateDesc( typeUTF8Text, SvPV_nolen(text), sv_len(text), &scriptTextDesc);
    } else {
      err = AECreateDesc(typeChar, SvPV_nolen(text), sv_len(text), &scriptTextDesc);
    }
    if (err == noErr) {
	
      /* compile the script */
      err = OSACompile(theComponent, &scriptTextDesc,
		       kOSAModeNull, &scriptID);
      if (err == noErr) {
	
	/* run the script */
	err = OSAExecute(theComponent, scriptID, kOSANullScript,
			 kOSAModeNull, &resultID);
	
	/* collect the results - if any */
	/* We skip this, as we're not getting results at the moment */
	/*
	  if (resultData != NULL) {
	    AECreateDesc(typeNull, NULL, 0, resultData);
	    if (err == errOSAScriptError) {
	    OSAScriptError(theComponent, kOSAErrorMessage,
	    typeChar, resultData);
	    } else if (err == noErr && resultID != kOSANullScript) {
	    OSADisplay(theComponent, resultID, typeChar,
	  kOSAModeNull, resultData);
	  }
	  }
	  */
	if (err != noErr) {
	  sv_setiv(ERRSV, err);
	} else {
	  int isError = 0;
	  AECreateDesc(typeNull, NULL, 0, &resultData);
	  if (err == errOSAScriptError) {
            OSAScriptError(theComponent, kOSAErrorMessage,
			   typeUTF8Text /*typeChar*/, &resultData);
	    isError = 1;
	  } else if (err == noErr && resultID != kOSANullScript) {
            OSADisplay(theComponent, resultID, typeUTF8Text /*typeChar*/,
		       kOSAModeNull, &resultData);
	  }
	  /* We got something in resultData. Now fish it out */
	  {
	    char *returnChar;
	    Size returnSize;
	    /* How big is the return? */
	    returnSize = AEGetDescDataSize(&resultData);
	    /* Alloc some memory for it */
	    returnChar = malloc(returnSize); /* Yes, we should check
						for failure */
	    /* Fetch it */
	    err = AEGetDescData(&resultData, returnChar, returnSize);
	    if (isError) {
	      sv_setpvn(ERRSV, returnChar, returnSize);
	      err = 1;
	    } else {
	      returnSV = sv_2mortal(newSVpv(returnChar, returnSize));
	    }
	    AEDisposeDesc(&resultData);
	  }
	}
      } else {
	sv_setiv(ERRSV, err);
      }
    } else {
      sv_setiv(ERRSV, err);
    }
    AEDisposeDesc(&scriptTextDesc);
    if (scriptID != kOSANullScript) OSADispose(theComponent, scriptID);
    if (resultID != kOSANullScript) OSADispose(theComponent, resultID);
    if (theComponent != NULL) CloseComponent(theComponent);
    if (err) {
      XSRETURN_EMPTY;
    }
    XPUSHs(returnSV);
}
