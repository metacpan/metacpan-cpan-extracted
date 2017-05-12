/////////////////////////////////////////////////////////////////////////////////////////
// File          HiPi::Utils
// Description:  C Utilities for HiPi::Utils
// Copyright:    Copyright (c) 2013-2017 Mark Dootson
// License:      This is free software; you can redistribute it and/or modify it under
//               the same terms as the Perl 5 programming language system itself.
/////////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"
#include "mylib/include/compat.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/syscall.h>

#if HIPI_PERL_VERSION_GE( 5, 16, 0 )
int PL_gid;
int PL_egid;
int PL_uid;
int PL_euid;
#endif

MODULE = HiPi::Utils     PACKAGE = HiPi::Utils

void
_drop_permissions_id(touid, togid = -1)
    int touid
    int togid
  PREINIT:
    int ruid, euid, suid, rgid, egid, sgid;
  CODE:
    if( togid != -1) {
        if (setresgid(togid,togid,togid) < 0)
	    croak("Failed in call to drop gid privileges.");
	
	if (getresgid(&rgid, &egid, &sgid) < 0)
	    croak("gid privilege check failed.");
	
	if (rgid != togid || egid != togid || sgid != togid)
            croak("Failed to drop gid privileges.");

	PL_gid  = togid;
	PL_egid = togid;

    }
    
    if (setresuid(touid,touid,touid) < 0) 
	croak("Failed in call to drop uid privileges");
		
    if (getresuid(&ruid, &euid, &suid) < 0)
	croak("uid privilege check failed");
		
    if (ruid != touid || euid != touid || suid != touid)
	croak("Failed to drop uid privileges.");

    PL_uid  = touid;
    PL_euid = touid;
