/* XS code for List::BinarySearch::XS.pm, from the List::BinarySearch::XS
 * distribution. (c)2013 David Oswald. See distribution POD for license
 * information and documentation.
 */


/* Favor efficiency. There have been reports of this failing under Windows,
 * which needs further investigation once I see an applicable FAIL report.
 */
#define PERL_NO_GET_CONTEXT


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* Stolen from List::MoreUtils, but it seems clear enough how it works, so
 * I'll cargo-cult the code shamelessly (and cross my fingers).
 * Must appear after the three preceeding "includes".
 */
 
#ifndef PERL_VERSION
#    include <patchlevel.h>
#    if !(defined(PERL_VERSION) || (SUBVERSION > 0 && defined(PATCHLEVEL)))
#        include <could_not_find_Perl_patchlevel.h>
#    endif
#    define PERL_REVISION 5
#    define PERL_VERSION  PATCHLEVEL
#    define PERL_SUBVERSION SUBVERSION
#endif


/* cxinc wasn't part of the public API for 5.8 and 5.10, so we have to
 * define it here.  This is unnecessary for 5.12+
 * See http://www.nntp.perl.org/group/perl.perl5.porters/2009/07/msg149207.html
 * for a discussion on the issue.
 */
#if PERL_VERSION < 12
#define cxinc()                        Perl_cxinc(aTHX)
#endif


#include "multicall.h"
#include "ppport.h"



/* Returns index of found element, or undef if none found. */

I32 binsearch( SV* block, SV* needle, SV* aref_haystack ) {
  dTHX;
  dSP;
  dMULTICALL;
  GV *gv;
  HV *stash;
  I32 gimme     = G_SCALAR;
  CV *cv        = sv_2cv(block, &stash, &gv, 0);
  I32 min       = 0;
  I32 max       = 0;
  GV *agv       = gv_fetchpv("a", GV_ADD, SVt_PV);
  GV *bgv       = gv_fetchpv("b", GV_ADD, SVt_PV);
  AV *haystack  = 0;
  SAVESPTR(GvSV(agv));
  SAVESPTR(GvSV(bgv));

  /* We must have a valid subref, and aref for the haystack. */
  if( cv == Nullcv )
    croak("Not a subroutine reference.");
  if( ! SvROK( aref_haystack ) || SvTYPE(SvRV(aref_haystack)) != SVt_PVAV )
    croak( "Argument must be an array ref.\n" );

  haystack = (AV*)SvRV(aref_haystack);
  max = av_len(haystack); /* Perl 5.16 applied av_top_index synonym */

  if( max < 0 ) return -1; /* Empty list; needle can't be found. */

  PUSH_MULTICALL(cv);

  while( max > min ) {

    I32 mid = ( max - min ) / 2 + min;
    
    /* Fetch value at aref_haystack->[mid] */
    GvSV(agv) = needle;
    GvSV(bgv) = *av_fetch(haystack,mid,0);  /* Hay */

    MULTICALL;
    if( SvIV( *PL_stack_sp ) == 1 ) {  /* if ($a<=>$b) > 0 */
      min = mid + 1;
    }
    else {
      max = mid;
    }
  }

  /* Detect if we have a winner, and who won. */
  GvSV(agv) = needle;
  GvSV(bgv) = *av_fetch(haystack,min,0);
  MULTICALL;
  if( SvIV(*PL_stack_sp ) == 0 ) {
    POP_MULTICALL;
    return min;
  }

  /* Otherwise we have a loser. */
  POP_MULTICALL;
  return -1; /* Not found. */
}



/* Returns index of found element, or index of insert point if none found. */

SV* binsearch_pos( SV* block, SV* needle, SV* aref_haystack ) {
  dTHX;
  dSP;
  dMULTICALL;
  GV *gv;
  HV *stash;
  I32 gimme    = G_SCALAR;
  CV *cv       = sv_2cv(block, &stash, &gv, 0);
  I32 low      = 0;
  I32 high     = 0;
  GV *agv      = gv_fetchpv("a", GV_ADD, SVt_PV);
  GV *bgv      = gv_fetchpv("b", GV_ADD, SVt_PV);
  AV *haystack = 0;
  SAVESPTR(GvSV(agv));
  SAVESPTR(GvSV(bgv));

  /* We must have a valid subref, and aref for the haystack. */
  if( cv == Nullcv )
    croak("Not a subroutine reference.");
  if( ! SvROK( aref_haystack ) || SvTYPE(SvRV(aref_haystack)) != SVt_PVAV )
    croak( "Argument must be an array ref.\n" );

  haystack = (AV*)SvRV(aref_haystack);
  high = av_len(haystack) + 1; /* scalar @{$aref} (Perl 5.16 introduced av_top_index synonym.) */

  if( high <= 0 ) return newSViv(low); /* Empty list; insert at zero. */

  PUSH_MULTICALL(cv);

  while( low < high ) {

    I32 cur = ( high - low ) / 2 + low;
    
    /* Fetch value at aref_haystack->[mid] */
    GvSV(agv) = needle;
    GvSV(bgv) = *av_fetch(haystack,cur,0);  /* Hay */

    MULTICALL;
    if( SvIV( *PL_stack_sp ) > 0 ) {  /* if ($a<=>$b) > 0 */
      low = cur + 1;
    }
    else {
      high = cur;
    }
  }
  POP_MULTICALL;
  return newSViv(low);
}



MODULE = List::BinarySearch::XS   PACKAGE = List::BinarySearch::XS
PROTOTYPES: ENABLE

SV *
binsearch (block, needle, aref_haystack)
  SV *  block
  SV *  needle
  SV *  aref_haystack
  PROTOTYPE: &$\@
  PPCODE:
    /* We need binsearch to return undef or empty list on no match, depending
     * on context.  This snippet detects an undef rv, and just massages it
     * into an empty list.
     */
    I32 rv = binsearch( block, needle, aref_haystack );
    if( rv == -1 ) {
      XSRETURN_EMPTY;
    }
    else {
      SV* output = sv_2mortal(newSViv(rv));
      PUSHs(output);
    }
    /* In other words, only return something if our search was successful. */


SV *
binsearch_pos (block, needle, aref_haystack)
  SV *  block
  SV *  needle
  SV *  aref_haystack
  PROTOTYPE: &$\@
