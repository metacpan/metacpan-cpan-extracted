/*
 * c_api.h - This file is in the public domain
 * Author: Salvador Fandino <sfandino@yahoo.com>, Dave Rolsky <autarch@urth.org>
 *
 * Generated on: 2024-01-21 22:00:15
 * Math::Int64 version: 0.56
 * Module::CAPIMaker version: 0.02
 */

#if !defined (C_API_H_INCLUDED)
#define C_API_H_INCLUDED

static void
init_c_api(pTHX) {
    HV *hv = get_hv("Math::Int64::C_API", TRUE|GV_ADDMULTI);
    hv_store(hv, "min_version", 11, newSViv(1), 0);
    hv_store(hv, "max_version", 11, newSViv(2), 0);
    hv_store(hv, "version", 7, newSViv(2), 0);
    hv_store(hv, "SvI64", 5, newSViv(PTR2IV(&SvI64)), 0);
    hv_store(hv, "SvI64OK", 7, newSViv(PTR2IV(&SvI64OK)), 0);
    hv_store(hv, "SvU64", 5, newSViv(PTR2IV(&SvU64)), 0);
    hv_store(hv, "SvU64OK", 7, newSViv(PTR2IV(&SvU64OK)), 0);
    hv_store(hv, "newSVi64", 8, newSViv(PTR2IV(&newSVi64)), 0);
    hv_store(hv, "newSVu64", 8, newSViv(PTR2IV(&newSVu64)), 0);
    hv_store(hv, "randU64", 7, newSViv(PTR2IV(&randU64)), 0);

}

#define INIT_C_API init_c_api(aTHX)

#endif
