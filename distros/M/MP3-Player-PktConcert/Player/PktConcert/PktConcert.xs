#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "usb.h"
#include "libipkc.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 10 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 10]) {
    case 'C':
	if (strEQ(name + 0, "IPC_CACHE_CLEAN")) {	/*  removed */
#ifdef IPC_CACHE_CLEAN
	    return IPC_CACHE_CLEAN;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 0, "IPC_CACHE_DIRTY")) {	/*  removed */
#ifdef IPC_CACHE_DIRTY
	    return IPC_CACHE_DIRTY;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

SV *perl_callback;

int
progress( off_t sent, off_t total ) {

	/*
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK( SP );
	XPUSHs( sv_2mortal( newSViv( sent )));
	XPUSHs( sv_2mortal( newSViv( total )));
	PUTBACK;

	call_sv( perl_callback, G_DISCARD );

	FREETMPS;
	LEAVE;
	*/
	
	return 0;
}

MODULE = MP3::Player::PktConcert		PACKAGE = MP3::Player::PktConcert		

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

# ============================================================
# MP3::Player::PktConcert CONSTRUCTIOR/DESTRUCTOR
# ============================================================
ipc_t *
new( CLASS )
	char *CLASS
	CODE:
	RETVAL = (ipc_t *)safemalloc( sizeof( ipc_t ));
	if( RETVAL == NULL ) {
		warn( "unable to allocate memory for MP3::Player::PktConcert" );
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

void
DESTROY( self )
	ipc_t *self
	CODE:
	safefree( (char*) self );

# ============================================================
# MP3::Player::PktConcert GETTERS/SETTERS
# ============================================================

SV *
bfree( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->bfree = SvIV(ST(1));
	}
	RETVAL = newSViv( self->bfree );
	OUTPUT:
	RETVAL

SV *
btotal( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->btotal = SvIV(ST(1));
	}
	RETVAL = newSViv( self->btotal );
	OUTPUT:
	RETVAL

SV *
lid( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->lid = SvIV(ST(1));
	}
	RETVAL = newSViv( self->lid );
	OUTPUT:
	RETVAL

SV *
hid( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->hid = SvIV(ST(1));
	}
	RETVAL = newSViv( self->hid );
	OUTPUT:
	RETVAL

SV *
psize( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->psize = SvIV(ST(1));
	}
	RETVAL = newSViv( self->psize );
	OUTPUT:
	RETVAL

SV *
bulkep( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->bulkep = SvIV(ST(1));
	}
	RETVAL = newSViv( self->bulkep );
	OUTPUT:
	RETVAL

SV *
ucache( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->ucache = SvIV(ST(1));
	}
	RETVAL = newSViv( self->ucache );
	OUTPUT:
	RETVAL

SV *
tcache( self, ... )
	ipc_t *self
	CODE:
	if( items > 1 ) {
		self->tcache = SvIV(ST(1));
	}
	RETVAL = newSViv( self->tcache );
	OUTPUT:
	RETVAL

SV *
usedids( self, ... )
	ipc_t *self
	PREINIT:
	STRLEN n_a;
	CODE:
	if( items > 1 ) {
		strcpy( self->usedids, SvPV(ST(1), n_a));
	}
	RETVAL = newSVpv( self->usedids, strlen( self->usedids ));
	OUTPUT:
	RETVAL

# ============================================================
# MP3::Player::PktConcert CLASS METHODS
# ============================================================

void
close( self )
	ipc_t	*self
	CODE:
	IPC_Close( self );

SV *
discover( self )
	ipc_t	*self
	ALIAS:
	MP3::Player::PktConcert::mount = 1
	PREINIT:
	int	*proc_port;
	CODE:
	proc_port = (int *)safemalloc( sizeof( int ));
	if( IPC_Discover( self, proc_port ) == -1 ) {
		XSRETURN_UNDEF;
	} else {
		RETVAL = newSViv( *proc_port );
	}
	OUTPUT:
	RETVAL

track_t *
next_track( self )
	ipc_t *self
	PREINIT:
	track_t *track;
	CODE:
	track = IPC_List_Tracks( self );
	if( track ) {
		RETVAL = track;
	} else {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

SV *
open( self )
	ipc_t	*self
	PREINIT:
	int	rs;
	CODE:
	if( (rs = IPC_Open( self )) == -1 ) {
		XSRETURN_UNDEF;
	} else {
		RETVAL = newSViv( 1 );
	}
	OUTPUT:
	RETVAL

void
reset_tracks( self )
	ipc_t *self
	CODE:
	IPC_Reset_List_Tracks( self );

void
send_tracks( self, name, path, ... )
	ipc_t *self
	SV *name
	SV *path
	CODE:
	if( items > 3 ) {
		perl_callback = ST(3);
	}
	IPC_Send_Track( 
		self, 
		(const char *) SvPV_nolen( name ), 
		(const char *) SvPV_nolen( path ), 
		progress 
	);

void
delete_track( self, id )
	ipc_t *self
	SV *id
	PREINIT:
	u_int16_t track_id;
	CODE:
	track_id = SvIV( id );
	IPC_Delete_Track( self, track_id );

void
usage( self )
	ipc_t	*self
	PREINIT:
	u_int32_t *bfree;
	u_int32_t *btotal;
	PPCODE:
	bfree = (u_int32_t *)safemalloc( sizeof( u_int32_t ));
	btotal = (u_int32_t *)safemalloc( sizeof( u_int32_t ));
	IPC_Get_Usage( self, bfree, btotal );
	EXTEND( SP, 2 );
	PUSHs( sv_2mortal( newSViv( *bfree )));
	PUSHs( sv_2mortal( newSViv( *btotal )));

MODULE = MP3::Player::PktConcert		PACKAGE = MP3::Player::PktConcert::Track		

# ============================================================
# MP3::Player::PktConcert::Track CONSTRUCTIOR/DESTRUCTOR
# ============================================================

track_t *
new( CLASS )
	char *CLASS
	CODE:
	RETVAL = (track_t *)safemalloc( sizeof( track_t ));
	if( RETVAL == NULL ) {
		warn( "unable to allocate memory for MP3::Player::PktConcert::Track" );
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

void
DESTROY( self )
	track_t *self
	CODE:
	safefree( (char*) self );

# ============================================================
# MP3::Player::PktConcert::Track GETTERS/SETTERS
# ============================================================

SV *
name( self )
	track_t *self
	CODE:
	RETVAL = newSVpv( self->name, strlen( self->name ) );
	OUTPUT:
	RETVAL

SV *
id( self )
	track_t *self
	CODE:
	RETVAL = newSViv( self->id );
	OUTPUT:
	RETVAL

SV *
bytes( self )
	track_t *self
	ALIAS:
	MP3::Player::PktConcert::Track::size = 2
	CODE:
	RETVAL = newSViv( self->bytes );
	OUTPUT:
	RETVAL

