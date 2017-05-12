/*********************************************************************
Project	:	MacPerl
File		:	PerlAEUtils.h		-	Stuff for Perl AppleEvent handling
Author	:	Matthias Neeracher
Language	:	Metrowerks C++

$Log: PerlAEUtils.h,v $
Revision 1.5  2003/10/28 05:48:54  pudge
Add #undef I_POLL for Panther

Revision 1.4  2003/08/13 21:41:30  pudge
undef DEBUG for the sake of gcc 3.3 (perl's DEBUG conflicts with Mac's)

Revision 1.3  2003/04/06 21:16:10  pudge
Don't suck in Carbon.h, just #undef Move

Revision 1.2  2002/12/10 03:06:24  pudge
Big update for Carbon support

Revision 1.1  2000/08/14 01:48:18  neeri
Checked into Sourceforge

Revision 1.1  1997/04/07 20:49:10  neeri
Synchronized with MacPerl 5.1.4a1

*********************************************************************/

#ifndef MACOS_TRADITIONAL
#undef Move
#undef I_POLL
#undef DEBUG
#endif
#include <AppleEvents.h>
#ifdef MACOS_TRADITIONAL
#include <AEBuild.h>
#include <AEStream.h>
#include <AESubDescs.h>
#endif
#include <OSA.h>

#ifdef __cplusplus
extern "C" {
#endif

extern OSACreateAppleEventUPP	gPAECreate;
extern OSASendUPP					gPAESend;
extern AEEventHandlerUPP		gPAEResume;
extern OSAActiveUPP				gPAEActive;
extern long							gPAECreateRefCon;
extern long							gPAESendRefCon;
extern long							gPAEResumeRefCon;
extern long							gPAEActiveRefCon;
extern Boolean						gPAEInstall;

extern Ptr gPAEArgs;

void PAEClearArgs();
Boolean PAEDoNextParam(char ** formscan, SV * sv);
int PAENextParam(char ** formscan);
OSErr PAEInstallEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler);
OSErr PAEGetEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler);
OSErr PAERemoveEventHandler(OSType aeClass, OSType aeID, Boolean sysHandler);
OSErr	PAEDoAppleEvent(const AppleEvent * event, AppleEvent * reply);
Boolean PAEHasOpenHandler();
void PAENuke();

#ifdef __cplusplus
}
#endif
