/* --8<--8<--8<--8<--
 *
 * Copyright (C) 2000-2009 Smithsonian Astrophysical Observatory
 *
 * This file is part of IPC-XPA
 *
 * IPC-XPA is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * -->8-->8-->8-->8-- */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <xpa.h>
#include "util.h"
#ifdef __cplusplus
}
#endif

#define X_MAXSERVERS "max_servers"
#define L_MAXSERVERS strlen(X_MAXSERVERS)

#define X_MODE     "mode"
#define L_MODE	   strlen(X_MODE)

/* catch error from pre 2.1 server -- if we find this error, we know the
   access point is available */
#define OLD_SERVER(s) strstr(s, "invalid xpa command in initialization string")

typedef XPA IPC_XPA_RAW;

MODULE = IPC::XPA		PACKAGE = IPC::XPA

IPC_XPA_RAW
_Open(mode)
	char* mode
	CODE:
		RETVAL = XPAOpen(mode);
	OUTPUT:
	RETVAL

IPC_XPA_RAW
nullXPA()
	CODE:
		RETVAL = NULL;
	OUTPUT:
	RETVAL


void
_Close(xpa)
	IPC_XPA_RAW	xpa
	CODE:
	XPAClose(xpa);

void
_Get(xpa, xtemplate, paramlist, mode, max_servers )
	IPC_XPA_RAW	xpa
	char*	xtemplate
	char*	paramlist
	char*   mode
	int     max_servers
	PREINIT:
		char **bufs;
		int *lens;
		char **names;
		char **messages;
		int i;
		int ns;
	PPCODE:
		/* allocate return arrays */
		New( 0, bufs, max_servers, char *);
		New( 0, lens, max_servers, int);
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPAGet(xpa, xtemplate, paramlist, mode, bufs, lens,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		EXTEND(SP, 2*ns);
		for ( i = 0 ; i < ns ; i++ )
		{
		  /* push the name of the server */
		  PUSHs( sv_2mortal(newSVpv(names[i],0)) );
  		  /* push a reference to the hash onto the stack */
		  PUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Get(bufs[i],lens[i],names[i],
					       messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( bufs );
		Safefree( lens );
		Safefree( names );
		Safefree( messages );


#undef NMARGS
#define NMARGS 3
void
_Set(xpa, xtemplate, paramlist, mode, buf, len, max_servers )
	IPC_XPA_RAW	xpa
	char*	xtemplate
	char*	paramlist
	char*   mode
	char*	buf
	long	len
	int     max_servers
	PREINIT:
		char **bufs;
		int   *lens;
		char **names;
		char **messages;
		int i;
		int ns;
		int n = 1;
	PPCODE:
		/* allocate return arrays */
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPASet(xpa, xtemplate, paramlist, mode, buf, len,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		EXTEND(SP, 2*ns);
		for ( i = 0 ; i < ns ; i++ )
		{
		  /* push the name of the server */
		  PUSHs( sv_2mortal(newSVpv(names[i],0)) );
  		  /* Now, push a reference to the hash onto the stack */
		  PUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Set(names[i], messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( names );
		Safefree( messages );


void
_Info(xpa, xtemplate, paramlist, mode, max_servers )
	IPC_XPA_RAW	xpa
	char*	xtemplate
	char*	paramlist
	char*	mode
	int	max_servers
	PREINIT:
		char **names;
		char **messages;
		int i;
		int ns;
	PPCODE:
		/* allocate return arrays */
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPAInfo(xpa, xtemplate, paramlist, mode,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		EXTEND(SP, 2*ns);
		for ( i = 0 ; i < ns ; i++ )
		{
		  /* push the name of the server */
		  PUSHs( sv_2mortal(newSVpv(names[i],0)) );
  		  /* Now, push a reference to the hash onto the stack */
		  PUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Set(names[i], messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( names );
		Safefree( messages );

void
_NSLookup(xpa, tname, ttype)
	IPC_XPA_RAW	xpa
	char*	tname
	char*	ttype
	PREINIT:
		char **xclasses;
		char **names;
		char **methods;
		char **infos;
		int i;
		int ns;
	PPCODE:
		ns = XPANSLookup( xpa, tname, ttype, &xclasses, &names,
                                 &methods, &infos );
		/* convert result into something Perlish */
		EXTEND(SP, ns);
		for ( i = 0 ; i < ns ; i++ )
		{
  		  /* Now, push a reference to the hash onto the stack */
		  PUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Lookup(xclasses[i],
						      names[i],
						      methods[i],
						      infos[i]
						       ))) );
		  free( xclasses[i] );
		  free( names[i] );
		  free( methods[i] );
		  free( infos[i] );
		}
		if ( ns > 0 )
		{
		  free( xclasses );
		  free( names );
		  free( methods );
		  free( infos );
		}

void
_Access(xpa, xtemplate, paramlist, mode, max_servers )
	IPC_XPA_RAW	xpa
	char*	xtemplate
	char*	paramlist
	char*	mode
	int	max_servers
	PREINIT:
		char **names;
		char **messages;
		int i;
		int ns;
	PPCODE:
		/* allocate return arrays */
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPAAccess(xpa, xtemplate, paramlist, mode,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		EXTEND(SP, 2*ns);
		for ( i = 0 ; i < ns ; i++ )
		{
		  /* push the name of the server */
		  PUSHs( sv_2mortal(newSVpv(names[i],0)) );

		  /* older servers than 2.1 will react with an error
		     to the access command; they're there (because
		     we see the error) */
		  if ( messages[i] && OLD_SERVER(messages[i]) )
		  {
		    free( messages[i] );
		    messages[i] = NULL;
		  }
  		  /* Now, push a reference to the hash onto the stack */
		  PUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Set(names[i], messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( names );
		Safefree( messages );
