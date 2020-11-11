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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "util.h"

/* convert a hash to a string, with the format "key=val,key=val" */
char *
hash2str( HV* hash )
{
  SV*   val;		/* temp for iterating over hash */
  char* key;		/* temp for iterating over hash */
  I32   keylen;		/* temp for iterating over hash */

  int   len = 0;	/* length of final string, including EOS */
  int   n;		/* number of elements in hash */

  char* str;		/* final string */
  char* ptr;		/* temp ptr */

  /* iterate over hash, determining the length of the final string */
  hv_iterinit(hash);
  while( val = hv_iternextsv(hash, &key, &keylen) )
  {
    /* complain if the value is undefined or if it's a reference */
    if ( !SvOK(val) || SvROK(val) )
      croak( "hash entry for `%s' not a scalar", key );

    n++;
    len += keylen + SvCUR(val);
  }

  len +=   n		/* '=' */
         + n-1		/* ',' */
         + 1;		/* EOS */

  /* now, fill in string */
  New( 0, str, len, char );
  ptr = str;

  hv_iterinit(hash);
  while( val = hv_iternextsv(hash, &key, &keylen) )
  {
    STRLEN cur;
    char *pv;

    strcpy(ptr, key);
    ptr += keylen;
    *ptr++ = '=';
    pv = SvPV(val, cur);
    strncpy(ptr, pv, cur);
    ptr += cur;
    *ptr++ = ',';
  }

  /* the EOS position now contains a ',', and ptr is one
     past that.  fix that */
  *--ptr = '\0';

  return str;
}


/* convert XPAGet client data to a Perl hash */
HV *
cdata2hash_Get( char *buf, int len, char *name, char *message )
{
  SV *sv;
  SV *ref;
  /* create hash which will contain buf, name, message */
  HV *hash = newHV();

  /* buf may be big, so try to get perl to use it directly */
  sv = NEWSV(0,0);
  sv_usepvn( sv, buf, len );
  if ( NULL == hv_store( hash, "buf", 3, sv, 0 ) )
    croak( "error storing length for response\n" );

  if ( NULL == hv_store( hash, "name", 4, newSVpv( name, 0 ), 0 ) )
    croak( "error storing name for response\n" );

  if ( message )
  {
    if ( NULL == hv_store( hash, "message", 7, newSVpv( message, 0 ), 0 ) )
      croak( "error storing message for response\n" );
  }

  return hash;
}

/* convert XPASet/XPAInfo/XPAAccess client data to a Perl hash */
HV *
cdata2hash_Set( char *name, char *message )
{
  /* create hash which will contain name, message */
  HV *hash = newHV();

  if ( NULL == hv_store( hash, "name", 4, newSVpv( name, 0 ), 0 ) )
    croak( "error storing name for response\n" );

  if ( message )
  {
    if ( NULL == hv_store( hash, "message", 7, newSVpv( message, 0 ), 0 ) )
      croak( "error storing message for response\n" );
  }
  return hash;
}

/* convert XPALookup client data to a Perl hash */
HV *
cdata2hash_Lookup( char *class, char *name, char *method, char *info )
{
  /* create hash which will contain name, message */
  HV *hash = newHV();

  if ( NULL == hv_store( hash, "name", 4, newSVpv(name,0), 0 ) )
    croak( "error storing name for response\n" );

  if ( NULL == hv_store( hash, "class", 5, newSVpv(class,0), 0 ) )
    croak( "error storing class for response\n" );

  if ( NULL == hv_store( hash, "method", 6, newSVpv(method,0), 0 ) )
    croak( "error storing method for response\n" );

  if ( NULL == hv_store( hash, "info", 4, newSVpv(info,0), 0 ) )
    croak( "error storing info for response\n" );

  return hash;
}
