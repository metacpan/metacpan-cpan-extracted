/*
  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  Copyright (C) 2002-2014 Jens Thoms Toerring <jt@toerring.de>
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <fcntl.h>


MODULE = File::FcntlLock     PACKAGE = File::FcntlLock

PROTOTYPES: ENABLE


SV *
C_fcntl_lock( fd, function, flock_hash, int_err )
    int fd
    int function
    SV *flock_hash
    SV *int_err

    INIT:
        struct flock flock_struct;
        HV *fs;
        SV **sv_type,
           **sv_whence,
           **sv_start,
           **sv_len;

        sv_setiv( int_err, 0 );

        if ( ! SvROK( flock_hash ) )
        {
            sv_setiv( int_err, 1 );
            XSRETURN_UNDEF;
        }

        fs = ( HV * ) SvRV( flock_hash );

    CODE:
        /* Let's be careful and not assume that anything at all will work */

        if (    ( sv_type   = hv_fetch( fs, "l_type",   6, 0 ) ) == NULL
             || ( sv_whence = hv_fetch( fs, "l_whence", 8, 0 ) ) == NULL
             || ( sv_start  = hv_fetch( fs, "l_start",  7, 0 ) ) == NULL
             || ( sv_len    = hv_fetch( fs, "l_len",    5, 0 ) ) == NULL )
        {
            sv_setiv( int_err, 1 );
            XSRETURN_UNDEF;
        }

        flock_struct.l_type   = SvIV( *sv_type   );
        flock_struct.l_whence = SvIV( *sv_whence );
        flock_struct.l_start  = SvIV( *sv_start  );
        flock_struct.l_len    = SvIV( *sv_len    );

        /* Now call fcntl(2) - if we want the lock immediately but some other
           process is holding it we return 'undef' (people can find out about
           the reasons by checking errno). The same happens if we wait for the
           lock but receive a signal before we obtain the lock. */

        if ( fcntl( fd, function, &flock_struct ) != 0 )
            XSRETURN_UNDEF;

        /* Now to find out who's holding the lock we now must unpack the
           structure we got back from fcntl(2) and store it in the hash we
           got passed. */

        if ( function == F_GETLK )
        {
            hv_store( fs, "l_type",   6, newSViv( flock_struct.l_type   ), 0 );
            hv_store( fs, "l_whence", 8, newSViv( flock_struct.l_whence ), 0 );
            hv_store( fs, "l_start",  7, newSViv( flock_struct.l_start  ), 0 );
            hv_store( fs, "l_len",    5, newSViv( flock_struct.l_len    ), 0 );
            hv_store( fs, "l_pid",    5, newSViv( flock_struct.l_pid    ), 0 );
        }

        /* Return the systems return value of the fcntl(2) call (which is 0)
           but in a way that can't be mistaken as meaning false (shamelessly
           stolen from pp_sys.c in the the Perl sources). */

        RETVAL = newSVpvn( "0 but true", 10 );

    OUTPUT:
        RETVAL
