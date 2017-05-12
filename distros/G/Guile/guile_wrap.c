#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "libguile.h"
#include <guile/gh.h>

// transaltes an SV into a new SCM
SCM newSCMsv (SV *sv, char *type) {
  SCM scm;
  AV *av;
  int len;
  char *val;

  // derive type from SV
  if (type == NULL) {
    if (sv_derived_from(sv, "Guile::SCM")) {
      // if we've already got an SCM in SV clothing, return it
      IV tmp = SvIV((SV*)SvRV(sv));
      scm = INT2PTR(SCM,tmp);
      return scm;
    } else if (SvROK(sv)) {
      if (SvTYPE(SvRV(sv)) == SVt_PVAV) {
        // assume list for arrays
        type = "list";
      } else {
        croak("Guile::SCM::new : unsupported input ref type.");
      }
    } else if (SvIOK(sv)) {
      type = "integer";
    } else if (SvNOK(sv)) {
      type = "real";
    } else if (SvPOK(sv)) {
      type = "string";
    } else {
      croak("Guile::SCM::new : unsupported input type.");
    }
  }

  // create requested type
  if (strEQ(type, "integer")) {
    return gh_int2scm(SvIV(sv));
  } else if (strEQ(type, "real")) {
    return gh_double2scm(SvNV(sv));
  } else if (strEQ(type, "string")) {
    val = SvPV(sv, len);
    return gh_str2scm(val, len);
  } else if (strEQ(type, "symbol")) {
    val = SvPV(sv, len);      
    return scm_string_to_symbol(gh_str2scm(val, len));
  } else if (strEQ(type, "list")) {
    int x;

    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
      croak("Guile::SCM::new : list type requires an array-ref.");
    av = (AV *) SvRV(sv);
    len = av_len(av);

    switch(len) {
    case -1:
      // empty list
      return SCM_EOL;
    case 0:
      return SCM_LIST1(newSCMsv(*(av_fetch(av,0,0)), NULL));
    case 1:
      return SCM_LIST2(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL));
    case 2:
      return SCM_LIST3(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL));
    case 3:
      return SCM_LIST4(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL),
                       newSCMsv(*(av_fetch(av,3,0)), NULL));
    case 4:
      return SCM_LIST5(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL),
                       newSCMsv(*(av_fetch(av,3,0)), NULL),
                       newSCMsv(*(av_fetch(av,4,0)), NULL));
    case 5:
      return SCM_LIST6(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL),
                       newSCMsv(*(av_fetch(av,3,0)), NULL),
                       newSCMsv(*(av_fetch(av,4,0)), NULL),
                       newSCMsv(*(av_fetch(av,5,0)), NULL));
    case 6:
      return SCM_LIST7(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL),
                       newSCMsv(*(av_fetch(av,3,0)), NULL),
                       newSCMsv(*(av_fetch(av,4,0)), NULL),
                       newSCMsv(*(av_fetch(av,5,0)), NULL),
                       newSCMsv(*(av_fetch(av,6,0)), NULL));
    case 7:
      return SCM_LIST8(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL),
                       newSCMsv(*(av_fetch(av,3,0)), NULL),
                       newSCMsv(*(av_fetch(av,4,0)), NULL),
                       newSCMsv(*(av_fetch(av,5,0)), NULL),
                       newSCMsv(*(av_fetch(av,6,0)), NULL),
                       newSCMsv(*(av_fetch(av,7,0)), NULL));
    case 8:
      return SCM_LIST9(newSCMsv(*(av_fetch(av,0,0)), NULL),
                       newSCMsv(*(av_fetch(av,1,0)), NULL),
                       newSCMsv(*(av_fetch(av,2,0)), NULL),
                       newSCMsv(*(av_fetch(av,3,0)), NULL),
                       newSCMsv(*(av_fetch(av,4,0)), NULL),
                       newSCMsv(*(av_fetch(av,5,0)), NULL),
                       newSCMsv(*(av_fetch(av,6,0)), NULL),
                       newSCMsv(*(av_fetch(av,7,0)), NULL),
                       newSCMsv(*(av_fetch(av,8,0)), NULL));
    default:
      // case (len>8):
      for(x=0;x<=len;x++)
        scm = scm_cons(scm, newSCMsv(*(av_fetch(av,x,0)), NULL));
      return scm_cons(scm, SCM_EOL);
    }      
  } else if (strEQ(type, "pair")) {
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
      croak("Guile::SCM::new : pair type requires an array-ref.");
    av = (AV *) SvRV(sv);
    len = av_len(av);
    if (len != 1) 
      croak("Guile::SCM::new : pair type requires an array-ref of two elements.");
    // construct pair, recursively calling newSCMsv    
    scm = scm_cons(newSCMsv(*(av_fetch(av,0,0)), NULL),
                   newSCMsv(*(av_fetch(av,1,0)), NULL));
  } else {
    croak("Guile::SCM::new : unknown type requested : %s", type);
  }

  return scm;
}

// translates an SCM into a new SV
SV * newSVscm (SCM scm) {

  if (SCM_IMP(scm)) {
    // immediate types

    // integer
    if (SCM_INUMP(scm)) 
      return newSViv(SCM_INUM(scm));

    // character
    if (SCM_CHARP(scm))
      return newSVpvf("%c", SCM_CHAR(scm));

    // true
    if (scm == SCM_BOOL_T)
      return &PL_sv_yes;

    // false
    if (scm == SCM_BOOL_F) 
      return &PL_sv_no;

    // undefined, unspecified or eol
    if (scm == SCM_UNDEFINED || scm == SCM_UNSPECIFIED || scm == SCM_EOL)
      return &PL_sv_undef;

    croak("Guile::newSVscm : Unknown immediate SCM type.");
  } else {
    // lists - translated to a flat array, rather than the 
    // [1 [2 [3, undef]]] that might also be possible.  I suppose that 
    // might make sense if Perl had car and cdr!
    if (gh_list_p(scm)) {
      AV *av = newAV();
      SV* sv;
      SCM tmp;
      do {
        // turn the elements into Guile::SCM objects since SVifying them
        // will cause data loss
        sv = newSV(0);
        tmp = SCM_CAR(scm);
        scm_gc_protect_object(tmp);
        sv_setref_pv(sv, "Guile::SCM", (void*)tmp);
        av_push(av, sv);
        scm = SCM_CDR(scm);
      } while(scm != SCM_EOL);      
      return newRV_noinc((SV*)av);
    }

    // pairs - check this after lists since a list is also a pair
    if (SCM_CONSP(scm)) {
      // create a two-element array with the CAR and CDR of the pair
      // turn the elements into Guile::SCM objects since SVifying them
      // will cause data loss
      AV *av = newAV();
      SV* sv;
      SCM tmp;
      av_extend(av, 1);
      sv = newSV(0);
      tmp = SCM_CAR(scm);
      scm_gc_protect_object(tmp);
      sv_setref_pv(sv, "Guile::SCM", (void*)tmp);
      av_store(av, 0, sv);
      sv = newSV(0);
      tmp = SCM_CDR(scm);
      scm_gc_protect_object(tmp);
      sv_setref_pv(sv, "Guile::SCM", (void*)tmp);
      av_store(av, 1, sv);
      return newRV_noinc((SV*)av);
    }
     
    // strings and symbols
    if (SCM_STRINGP(scm) || SCM_SYMBOLP(scm))
      return newSVpvn(SCM_STRING_CHARS(scm),SCM_STRING_LENGTH(scm));

    // floats
    if (scm_inexact_p(scm) == SCM_BOOL_T) 
      return newSVnv(gh_scm2double(scm));

    croak("Guile::newSVscm : Unknown non-immediate SCM type.");
  }  
}
