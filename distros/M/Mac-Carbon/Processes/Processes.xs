/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Processes/Processes.xs,v 1.11 2009/09/17 06:56:08 pudge Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Processes.xs,v $
 * Revision 1.11  2009/09/17 06:56:08  pudge
 * Bunch of fixes and changes for release
 *   Add notes for 64-bit perl
 *
 *   Bump all the version numbers
 *
 *   Fix a bunch of tests (nothing major, just make them work better)
 *
 *   Fix sound-env-var checking code for tests (no more sound tests
 *   unless you ask for them with MAC_CARBON_SOUND, which was in the
 *   last version, but the logic was broken)
 *
 *   Make CFStringRef typemap better
 *
 *   Remove high-bit characters from source files
 *
 *   Add new system version gestalt constants
 *
 *   Fix leaks in Mac::Processes and Mac::Speech
 *
 * Revision 1.10  2006/06/20 01:39:18  pudge
 * Loads of fixes, mostly for Intel port
 *
 * Revision 1.9  2003/10/28 05:53:30  pudge
 * Add Carbon compat. notes
 *
 * Revision 1.8  2003/04/06 21:34:08  pudge
 * Add LSFindApplicationForInfo to Mac::Processes for finding
 * applications on Mac OS X (by creator, bundle ID, or name)
 *
 * Revision 1.7  2002/12/12 14:58:07  pudge
 * Update POD and docs
 *
 * Revision 1.6  2002/12/10 01:50:57  pudge
 * Add GetProcessPID and GetProcessForPID, for mapping between Mac OS PSN
 * and Unix PID.
 *
 * Revision 1.5  2002/11/13 02:04:52  pudge
 * Aieeeeee!  Big ol' Carbon update.
 *
 * Revision 1.4  2002/01/23 05:44:42  pudge
 * Update whitespace etc., from Thomas
 *
 * Revision 1.3  2000/09/12 19:42:21  pudge
 * Make LaunchApplication return PSN on success, undef on failure
 *
 * Revision 1.2  2000/09/09 22:18:28  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:32  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:53:10  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:50:30  neeri
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
#include <Memory.h>
#include <Processes.h>
#ifdef MACOS_TRADITIONAL
#include <GUSIFileSpec.h>
#endif

typedef LaunchPBPtr			LaunchParam;
typedef ProcessInfoRecPtr	ProcessInfo;

static ProcessInfo NewProcessInfo()
{
	ProcessInfo	pi;
	pi = (ProcessInfo) malloc(sizeof(ProcessInfoRec)+sizeof(FSSpec)+36);
	pi->processInfoLength	=	sizeof(ProcessInfoRec);
	pi->processName			=	(StringPtr)((char *)pi+sizeof(ProcessInfoRec));
	pi->processAppSpec		=	(FSSpecPtr)((char *)pi+sizeof(ProcessInfoRec)+36);
	
	return pi;
}

MODULE = Mac::Processes	PACKAGE = LaunchParam

=head2 LaunchParam

This Perl hash maps onto the fields of a Launch Parameter Block.

The fields are: 

    launchFileFlags
    launchControlFlags
    launchAppSpec
    launchAvailableSize
    launchProcessSN
    launchPreferredSize
    launchMinimumSize

=over 4

=cut

STRUCT * LaunchParam
	U16						launchFileFlags;
	U16						launchControlFlags;
	FSSpecPtr				launchAppSpec;
	ProcessSerialNumber		launchProcessSN;
	U32						launchPreferredSize;
	U32						launchMinimumSize;
	U32						launchAvailableSize;

=item new LaunchParam [ARGUMENTS]

Returns LaunchParam.

    $launch = 
        new LaunchParam(launchAppSpec =E<gt> "hd:apps:myapp", launchMinimumSize => 32000);

=cut
LaunchParam
_new()
	CODE:
	RETVAL = (LaunchParam) malloc(sizeof(LaunchParamBlockRec)+sizeof(FSSpec));
	RETVAL->launchBlockID			=	extendedBlock;
	RETVAL->launchEPBLength			=	extendedBlockLen;
	RETVAL->launchAppSpec			=	(FSSpecPtr)((char *)RETVAL+sizeof(LaunchParamBlockRec));
	RETVAL->launchAppParameters	=	nil;
	OUTPUT:
	RETVAL

=item DESTROY LPB

=back

=cut
void
DESTROY(lpb)
	LaunchParam	lpb
	CODE:
	free(lpb);


MODULE = Mac::Processes	PACKAGE = ProcessInfo

=head2 ProcessInfo

This Perl hash allows access to the C<ProcessInfo> structure.

The field names are: 

    processName
    processNumber
    processType
    processSignature
    processSize
    processMode
    processLocation
    processLauncher
    processLaunchDate
    processActiveTime
    processAppSpec

=over 4

=cut

STRUCT * ProcessInfo
	Str255				processName;
	ProcessSerialNumber	processNumber;
	U32					processType;
	OSType				processSignature;
	U32					processMode;
	Ptr					processLocation;
	U32					processSize;
	U32					processFreeMem;
	ProcessSerialNumber	processLauncher;
	U32					processLaunchDate;
	U32					processActiveTime;
	FSSpecPtr			processAppSpec;

=item DESTROY PI

=back

=cut
void
DESTROY(pi)
	ProcessInfo	pi
	CODE:
	free(pi);

MODULE = Mac::Processes	PACKAGE = Mac::Processes

=head2 Functions

=over 4

=item LaunchApplication LAUNCHPARAMS

The LaunchApplication function launches the application from the specified file
and returns the process serial number if the application is successfully launched.
Returns undef on failure.

=cut
ProcessSerialNumber
LaunchApplication(LaunchParams)
	LaunchParam LaunchParams
    CODE:
	if (gMacPerl_OSErr = LaunchApplication(LaunchParams)) {
        XSRETURN_UNDEF;
    }
	RETVAL = LaunchParams->launchProcessSN;
	OUTPUT:
	RETVAL


=item LaunchDeskAccessory PFILESPEC, PDANAME

B<Mac OS only.>

The LaunchDeskAccessory function searches the resource fork of the file specified
by the pFileSpec parameter for the desk accessory with the 'DRVR' resource name
specified in the pDAName parameter. If the 'DRVR' resource name is found,
LaunchDeskAccessory launches the corresponding desk accessory. If the desk
accessory is already open, it is brought to the front.
Returns zero on failure.

=cut
MacOSRet
LaunchDeskAccessory(pFileSpec, pDAName)
	SV *		pFileSpec
	Str255	pDAName
	PREINIT:
	FSSpec	spec;
	FSSpec *	fssp = nil;
	CODE:
#ifndef MACOS_TRADITIONAL
	croak("Usage: Mac::Processes::LaunchDeskAccessory unsupported in Carbon");
#else
	if (SvTRUE(pFileSpec) && GUSIPath2FSp(SvPV_nolen(pFileSpec), &spec))
		fssp = &spec;
	RETVAL = LaunchDeskAccessory(fssp, pDAName);
#endif
	OUTPUT:
	RETVAL

=item GetCurrentProcess

The GetCurrentProcess function returns the process serial
number of the process that is currently running, that is, the one currently
accessing the CPU.
Return C<undef> if an error was detected.

=cut
ProcessSerialNumber
GetCurrentProcess()
	CODE:
	if (gMacPerl_OSErr = GetCurrentProcess(&RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL
	
=item GetFrontProcess

The GetFrontProcess function returns the process serial
number of the process running in the foreground.
Return C<undef> if an error was detected.

=cut
ProcessSerialNumber
GetFrontProcess()
	CODE:
	if (gMacPerl_OSErr = GetFrontProcess(&RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL
	
=item GetNextProcess PSN

Get information about the next process, if any, in the Process Manager’s internal
list of open processes.
Return C<undef> if an error was detected.

=cut
ProcessSerialNumber
GetNextProcess(PSN)
	ProcessSerialNumber	PSN
	CODE:
	if (gMacPerl_OSErr = GetNextProcess(&PSN)) {
		XSRETURN_UNDEF;
	} else
		RETVAL = PSN;
	OUTPUT:
	RETVAL
	
=item GetProcessInformation PSN

The GetProcessInformation function returns, in a process information record,
information about the specified process. The information returned in the info
parameter includes the application’s name as it appears in the Application menu,
the type and signature of the application, the address of the application
partition, the number of bytes in the application partition, the number of free
bytes in the application heap, the application that launched the application, the
time at which the application was launched, and the location of the application
file.
Return C<undef> if an error was detected.

=cut
ProcessInfo
GetProcessInformation(PSN)
	ProcessSerialNumber	PSN
	CODE:
	RETVAL = NewProcessInfo();
	if (gMacPerl_OSErr = GetProcessInformation(&PSN, RETVAL)) {
		free(RETVAL);
		XSRETURN_UNDEF;
	} 
	OUTPUT:
	RETVAL
	
=item SetFrontProcess PSN

The SetFrontProcess function schedules the specified process to move to the
foreground. The specified process moves to the foreground after the current
foreground process makes a subsequent call to WaitNextEvent or EventAvail.
Returns zero on failure.

=cut
MacOSRet
SetFrontProcess(PSN)
	ProcessSerialNumber	&PSN

=item WakeUpProcess PSN

The WakeUpProcess function makes a process suspended by WaitNextEvent() eligible to
receive CPU time. A process is suspended when the value of the sleep parameter in
the WaitNextEvent() function is not 0 and no events for that process are pending in
the event queue. This process remains suspended until the time specified in the
sleep parameter expires or an event becomes available for that process. You can
use WakeUpProcess to make the process eligible for execution before the time
specified in the sleep parameter expires.
Returns zero on failure.

=cut
MacOSRet
WakeUpProcess(PSN)
	ProcessSerialNumber	&PSN

=item SameProcess PSN1, PSN2

The SameProcess function compares two process serial numbers and determines
whether they refer to the same process.
Return C<undef> if an error was detected.

=cut
Boolean
SameProcess(PSN1, PSN2)
	ProcessSerialNumber	PSN1
	ProcessSerialNumber	PSN2
	CODE:
	if (gMacPerl_OSErr = SameProcess(&PSN1, &PSN2, &RETVAL)) {
		XSRETURN_UNDEF;
	} 
	OUTPUT:
	RETVAL

=item ExitToShell

This function is not implemented: ExitToShell() unsupported. Use exit.

=cut
void
ExitToShell()
	CODE:
	croak("ExitToShell() unsupported. Use exit.");

=item GetProcessPID(PSN)

B<Mac OS X only.>

Get the UNIX process ID corresponding to a process serial number.

=cut
pid_t
GetProcessPID(PSN)
	ProcessSerialNumber	PSN
	CODE:
#ifdef MACOS_TRADITIONAL
	croak("Usage: Mac::Processes::GetProcessPID unsupported in Mac OS");
#else
	if (gMacPerl_OSErr = GetProcessPID(&PSN, &RETVAL)) {
		XSRETURN_UNDEF;
	}
#endif
	OUTPUT:
	RETVAL

=item GetProcessForPID(PID)

B<Mac OS X only.>

Get the process serial number corresponding to a UNIX process ID.

=cut
ProcessSerialNumber
GetProcessForPID(PID)
	pid_t	PID
	CODE:
#ifdef MACOS_TRADITIONAL
	croak("Usage: Mac::Processes::GetProcessForPID unsupported in Mac OS");
#else
	if (gMacPerl_OSErr = GetProcessForPID(PID, &RETVAL)) {
		XSRETURN_UNDEF;
	}
#endif
	OUTPUT:
	RETVAL

=item LSFindApplicationForInfo(creator, bundleID=NULL, name=NULL)

B<Mac OS X only.>

Return the path to the application matching one or more of creator,
bundleID, and name.  Pass undef or empty string for unused parameters.

	$path = LSFindApplicationForInfo("R*ch");
	$path = LSFindApplicationForInfo(undef, "com.barebones.bbedit");
	$path = LSFindApplicationForInfo(undef, undef, "BBEdit.app");
	$path = LSFindApplicationForInfo("R*ch", "com.barebones.bbedit", "BBEdit.app");

=cut
FSRef
LSFindApplicationForInfo(creator, bundleID=NULL, name=NULL)
	OSType		creator
	CFStringRef	bundleID
	CFStringRef	name
	INIT:
	if (strlen(SvPV_nolen(ST(0))) == 0)
		creator = NULL;
	if (bundleID != NULL && CFStringGetLength(bundleID) == 0)
		bundleID = NULL;
	if (name != NULL && CFStringGetLength(name) == 0)
		name = NULL;
	CODE:
#ifdef MACOS_TRADITIONAL
	croak("Usage: Mac::Processes::LSFindApplicationForInfo unsupported in Mac OS");
#else
	gMacPerl_OSErr = LSFindApplicationForInfo(creator, bundleID, name, &RETVAL, NULL);
	if (bundleID)
		CFRelease(bundleID);
	if (name)
		CFRelease(name);
	if (gMacPerl_OSErr)
		XSRETURN_UNDEF;
#endif
	OUTPUT:
	RETVAL


=back

=cut
