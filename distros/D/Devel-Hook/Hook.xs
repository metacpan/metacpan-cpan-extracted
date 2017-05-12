
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "keywords.h"

AV   *_get_begin_array();
AV   *_get_unitcheck_array();
AV   *_get_check_array();
AV   *_get_init_array();
AV   *_get_end_array();

AV *_get_begin_array() {
    if ( !PL_beginav ) {
        PL_beginav = newAV();
    }
    return PL_beginav;
}

AV *_get_unitcheck_array() {
#ifdef KEY_UNITCHECK
    if ( !PL_unitcheckav ) {
        PL_unitcheckav = newAV();
    }
    return PL_unitcheckav;
#else
    croak( "UNITCHECK not implemented in this release of perl" );
#endif
}

AV *_get_check_array() {
    if ( !PL_checkav ) {
        PL_checkav = newAV();
    }
    return PL_checkav;
}

AV *_get_init_array() {
    if ( !PL_initav ) {
        PL_initav = newAV();
    }
    return PL_initav;
}

AV *_get_end_array() {
    if ( !PL_endav ) {
        PL_endav = newAV();
    }
    return PL_endav;
}

HV *_get_supported_types() {
    HV *hv = newHV();
    hv_store( hv, "BEGIN", 5, &PL_sv_yes, 0 );
#ifdef KEY_UNITCHECK
    hv_store( hv, "UNITCHECK", 9, &PL_sv_yes, 0 );
#else
    hv_store( hv, "UNITCHECK", 9, &PL_sv_no, 0 );
#endif
    hv_store( hv, "CHECK", 5, &PL_sv_yes, 0 );
    hv_store( hv, "INIT", 4, &PL_sv_yes, 0 );
    hv_store( hv, "END", 3, &PL_sv_yes, 0 );
    return hv;
}

MODULE = Devel::Hook		PACKAGE = Devel::Hook

PROTOTYPES: ENABLE

AV*
_get_begin_array()

AV*
_get_unitcheck_array()

AV*
_get_check_array()

AV*
_get_init_array()

AV *
_get_end_array()

HV *
_get_supported_types()

