/*
 * -- XS code from Win32::SystenInfo::CpuUsage
 * -- this code is apparently not under any explict copyright
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* from const-c.inc */
#ifndef H_INC_CONST_C
#define H_INC_CONST_C 1
#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant (pTHX_ const char *name, STRLEN len) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw()};
my @names = (qw());

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Win32::SystemInfo::CpuUsage", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Win32::SystemInfo::CpuUsage", $types);
__END__
   */

  switch (len) {
  }
  return PERL_constant_NOTFOUND;
}
#endif


#if 0
# include <stdafx.h>
#endif 

#include <windows.h>
#include <stdio.h>
#if 0
# include "cpuUsage.h"
#endif

#define SystemBasicInformation		0
#define SystemPerformanceInformation	2
#define SystemTimeInformation			3

#define Li2Double(x) ((double)((x).HighPart) * 4.294967296E9 + (double)((x).LowPart))

typedef struct
{
	  DWORD   dwUnknown1;
	  ULONG   uKeMaximumIncrement;
	  ULONG   uPageSize;
	  ULONG   uMmNumberOfPhysicalPages;
	  ULONG   uMmLowestPhysicalPage;
	  ULONG   uMmHighestPhysicalPage;
	  ULONG   uAllocationGranularity;
	  PVOID   pLowestUserAddress;
	  PVOID   pMmHighestUserAddress;
	  ULONG   uKeActiveProcessors;
	  BYTE    bKeNumberProcessors;
	  BYTE    bUnknown2;
	  WORD    wUnknown3;
} SYSTEM_BASIC_INFORMATION;

typedef struct
{
	  LARGE_INTEGER		liIdleTime;
	  DWORD				dwSpare[76];
} SYSTEM_PERFORMANCE_INFORMATION;

typedef struct
{
	  LARGE_INTEGER liKeBootTime;
	  LARGE_INTEGER liKeSystemTime;
	  LARGE_INTEGER liExpTimeZoneBias;
	  ULONG			  uCurrentTimeZoneId;
	  DWORD     dwReserved;
} SYSTEM_TIME_INFORMATION;

// ntdll!NtQuerySystemInformation (NT specific!)
//
// The function copies the system information of the
// specified type into a buffer
//
// NTSYSAPI
// NTSTATUS
// NTAPI
// NtQuerySystemInformation(
//   IN   UINT   SystemInformationClass,   // information type
//   OUT  PVOID  SystemInformation,        // pointer to buffer
//   IN   ULONG  SystemInformationLength,  // buffer size in bytes
//   OUT  PULONG ReturnLength OPTIONAL     // pointer to a 32-bit
//										   // variable that receives
//										   // the number of bytes
//										   // written to the buffer
// );
typedef LONG (WINAPI *PROCNTQSI)(UINT,PVOID,ULONG,PULONG);

PROCNTQSI NtQuerySystemInformation;

int getCpuUsage(int interval)
{
	SYSTEM_PERFORMANCE_INFORMATION	SysPerfInfo;
	SYSTEM_TIME_INFORMATION			SysTimeInfo;
	SYSTEM_BASIC_INFORMATION		SysBaseInfo;
	double				dbIdleTime;
	double				dbSystemTime;
	LONG				status;
	LARGE_INTEGER		liOldIdleTime = {0,0};
	LARGE_INTEGER		liOldSystemTime = {0,0};

	int iCtl=0, percentage=0;

	NtQuerySystemInformation = (PROCNTQSI)GetProcAddress(
								GetModuleHandle("ntdll"),
								"NtQuerySystemInformation"
								);
	if(!NtQuerySystemInformation)
	return -1;

	// get number of processors in the system
	status = NtQuerySystemInformation(SystemBasicInformation,&SysBaseInfo,sizeof(SysBaseInfo),NULL);
	if(status != NO_ERROR)
	return -1;

	//printf("\n getting CPU Usage\n");
	//while(!_kbhit())

	while(1)
	{
		// get new system time
		status = NtQuerySystemInformation(SystemTimeInformation,&SysTimeInfo,sizeof(SysTimeInfo),0);
		if(status!=NO_ERROR)
		return -1;

		// get new CPU's idle time
		status = NtQuerySystemInformation(SystemPerformanceInformation,&SysPerfInfo,sizeof(SysPerfInfo),NULL);
		if(status != NO_ERROR)
		return -1;

		// if it's a first call - skip it
		if(liOldIdleTime.QuadPart != 0)
		{
			// CurrentValue = NewValue - OldValue
			dbIdleTime   = Li2Double(SysPerfInfo.liIdleTime)     - Li2Double(liOldIdleTime);
			dbSystemTime = Li2Double(SysTimeInfo.liKeSystemTime) - Li2Double(liOldSystemTime);

			// CurrentCpuIdle = IdleTime / SystemTime
			dbIdleTime = dbIdleTime / dbSystemTime;

			// CurrentCpuUsage% = 100 - (CurrentCpuIdle * 100) / NumberOfProcessors
			dbIdleTime = 100.0 - dbIdleTime * 100.0 / (double)SysBaseInfo.bKeNumberProcessors + 0.5;

			//+ 0.5, result is same in task manager
			percentage= (UINT)(dbIdleTime);

			//printf("\b\b\b\b%3d%%", percentage);
			if(iCtl > 0 ) return percentage;
		}

		// store new CPU's idle and system time
		liOldIdleTime   = SysPerfInfo.liIdleTime;
		liOldSystemTime = SysTimeInfo.liKeSystemTime;

		// wait one second
		Sleep(interval);
		iCtl++;
	}
	return 0;
}

MODULE = Sys::CpuLoadX		PACKAGE = Sys::CpuLoadX

void
constant(sv)
    PREINIT:
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	/* IV		iv;	Uncomment this if you need to return IVs */
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
	type = constant(aTHX_ s, len);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv =
	    sv_2mortal(newSVpvf("%s is not a valid Win32::SystemInfo::CpuUsage macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined Win32::SystemInfo::CpuUsage macro %s, used",
				   s));
          PUSHs(sv);
          break;
	/* Uncomment this if you need to return IVs
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break; */
	/* Uncomment this if you need to return NOs
        case PERL_constant_ISNO:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_no);
          break; */
	/* Uncomment this if you need to return NVs
        case PERL_constant_ISNV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHn(nv);
          break; */
	/* Uncomment this if you need to return PVs
        case PERL_constant_ISPV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, strlen(pv));
          break; */
	/* Uncomment this if you need to return PVNs
        case PERL_constant_ISPVN:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, iv);
          break; */
	/* Uncomment this if you need to return SVs
        case PERL_constant_ISSV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break; */
	/* Uncomment this if you need to return UNDEFs
        case PERL_constant_ISUNDEF:
          break; */
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
	/* Uncomment this if you need to return YESs
        case PERL_constant_ISYES:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_yes);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Win32::SystemInfo::CpuUsage macro %s, used",
               type, s));
          PUSHs(sv);
        }

int
xs_getCpuUsage(interval)
INPUT:
	int interval
CODE:
	RETVAL 	= getCpuUsage(interval);
OUTPUT:
	RETVAL



