#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "sv-table.inc"

#if PERL_VERSION >= 8
#define DO_PM_STATS
/* PMOP stats seem to SEGV pre 5.8.0 for some unknown reason.
   (Well, dereferncing 0x8 is quite well known as a cause of SEGVs, it's just
   why I find that value in a chain of pointers...)  */
#endif

#ifndef HvRITER_get
#  define HvRITER_get HvRITER
#endif
#ifndef HvEITER_get
#  define HvEITER_get HvEITER
#endif

#ifndef HvPLACEHOLDERS_get
#  define HvPLACEHOLDERS_get HvPLACEHOLDERS
#endif
#ifndef HvNAME_get
#  define HvNAME_get HvNAME
#endif

static HV *
newHV_maybeshare(bool dont_share) {
  HV *hv = newHV();
  if (dont_share)
    HvSHAREKEYS_off(hv);
  return hv;
}

static void
store_UV(HV *hash, const char *key, UV value) {
  SV *sv = newSVuv(value);
  if (!hv_store(hash, (char *)key, strlen(key), sv, 0)) {
    /* Oops. Failed.  */
    SvREFCNT_dec(sv);
  }
}

static void
inc_key_len(HV *hash, const char *key, I32 len) {
  SV **count = hv_fetch(hash, (char*)key, len, 1);
  if (count) {
    sv_inc(*count);
  }
}

static void
inc_key(HV *hash, const char *key) {
  inc_key_len(hash, key, strlen(key));
}

static void
inc_key_by(HV *hash, const char *key, UV add) {
  SV **count = hv_fetch(hash, (char*)key, strlen(key), 1);
  if (count) {
    sv_setuv(*count, (SvOK(*count) ? SvUV(*count) : 0) + add);
  }
}

static void
inc_UV_key(HV *hash, UV key) {
  SV **count = hv_fetch(hash, (char*)&key, sizeof(key), 1);
  if (count) {
    sv_inc(*count);
  }
}

static void
inc_UV_key_in_hash(bool dont_share, HV *hash, char *key, UV subkey) {
  SV **ref = hv_fetch(hash, key, strlen(key), 1);
  HV *subhash;
  if (ref) {
    if (SvTYPE(*ref) != SVt_RV) {
      /* We got back a new SV that has just been created. Substitute a
	 hash for it.  */
      SvREFCNT_dec(*ref);
      subhash = newHV_maybeshare(dont_share);
      *ref = newRV_noinc((SV*)subhash);
    } else {
      assert (SvROK(*ref));
      subhash = (HV*)SvRV(*ref);
    }
    inc_UV_key(subhash, subkey);
  }
}

typedef void (unpack_function)(pTHX_ SV *sv, UV u);

/* map hash keys in some interesting way.  */
static HV *
unpack_hash_keys(bool dont_share, HV *packed, unpack_function *f) {
  HV *unpacked = newHV_maybeshare(dont_share);
  SV *temp = newSV(0);
  char *key;
  I32 keylen;
  SV *count;
  dTHX;

  hv_iterinit(packed);
  while ((count = hv_iternextsv(packed, &key, &keylen))) {
    /* need to do the unpack.  */
    STRLEN len;
    char *p;
    UV value = 0;

    assert (keylen == sizeof(value));
    memcpy (&value, key, sizeof(value));

    /* Convert the number to a string.  */
    f(aTHX_ temp, value);
    p = SvPV(temp, len);
    
    if (!hv_store(unpacked, p, len, SvREFCNT_inc(count), 0)) {
      /* Oops. Failed.  */
      SvREFCNT_dec(count);
    }
  }
  SvREFCNT_dec(temp);
  return unpacked;
}

/* take a hash keyed by packed UVs and build a new hash keyed by (stringified)
   numbers.
   keys are (in effect) map {unpack "J", $_}
*/
static HV *
unpack_UV_hash_keys(bool dont_share, HV *packed) {
  return unpack_hash_keys(dont_share, packed, &Perl_sv_setuv);
}

static HV *
unpack_IV_hash_keys(bool dont_share, HV *packed) {
  /* Cast needed as IV isn't UV (the last argument)  */
  return unpack_hash_keys(dont_share, packed,
			  (unpack_function*)&Perl_sv_setiv);
}

void
UV_to_type(pTHX_ SV *sv, UV value)
{
  if (value < sv_names_len) {
    sv_setpv(sv, sv_names[value]);
  } else if (value == SVTYPEMASK) {
    sv_setpv(sv, "(free)");
  } else {
    /* Convert the number to a string.  */
    sv_setuv(sv, value);
  }
}

static HV *
unpack_UV_keys_to_types(bool dont_share, HV *packed) {
  return unpack_hash_keys(dont_share, packed, &UV_to_type);
}

static int
store_hv_in_hv(HV *target, const char *key, HV *value) {
  SV *rv = newRV_noinc((SV *)value);
  if (hv_store(target, (char *)key, strlen(key), rv, 0))
    return 1;

  /* Oops. Failed.  */
  SvREFCNT_dec(rv);
  return 0;
}

static void
unpack_hash_keys_in_subhash(bool dont_share, HV *hash, char *key,
			    unpack_function *f) {
  SV **temp_ref = hv_fetch(hash, key, strlen(key), 0);
  if (temp_ref) {
    HV *packed_hash;

    assert(SvROK(*temp_ref));
    packed_hash = (HV *) SvRV(*temp_ref);
    assert(SvTYPE(packed_hash) == SVt_PVHV);
    SvRV(*temp_ref) = (SV *) unpack_hash_keys(dont_share, packed_hash, f);
    SvREFCNT_dec(packed_hash);
  }
}

static HV *
init_hv_key_stats(bool dont_share) {
  HV *hv = newHV_maybeshare(dont_share);
  store_UV(hv, "total", 0);
  store_UV(hv, "keys", 0);
  store_UV(hv, "keylen", 0);
  return hv;
}

static void
calculate_hv_key_stats(HV *stats, HV *target) {
  inc_key(stats, "total");

  if (HvARRAY(target)) {
    I32 r = (I32) HvMAX(target)+1;
    UV keys = 0;
    UV keylen = 0;
    SV **count;
    while (r--) {
      const HE *he = HvARRAY(target)[r];
      while (he) {
	++keys;
	keylen += HeKLEN(he);
	he = HeNEXT(he);
      }
    }

    inc_key_by(stats, "keys", keys);
    inc_key_by(stats, "keylen", keylen);
  }
}

static void
calculate_pvx_stats(bool dont_share, HV **stats, SV *target) {
  if (!*stats)
    *stats = newHV_maybeshare(dont_share);
  inc_key(*stats, "total");
  inc_key_by(*stats, "length", SvCUR(target));
  inc_key_by(*stats, "allocated", SvLEN(target));
}

static void
process_magic(bool dont_share, HV *stats, struct magic *magic) {
  SV **ref = hv_fetch(stats, &(magic->mg_type), 1, 1);
  if (ref) {
    HV *subhash;
    if (SvTYPE(*ref) != SVt_RV) {
      /* We got back a new SV that has just been created. Substitute a
	 hash for it.  */
      SvREFCNT_dec(*ref);
      subhash = newHV_maybeshare(dont_share);
      *ref = newRV_noinc((SV*)subhash);
    } else {
      assert (SvROK(*ref));
      subhash = (HV*)SvRV(*ref);
    }
    inc_key(subhash, "total");
    if (magic->mg_obj)
      inc_key(subhash, "has obj");
    if (magic->mg_ptr)
      inc_key(subhash, "has ptr");
    if (magic->mg_moremagic)
      inc_key(subhash, "has more magic");
    inc_UV_key_in_hash(dont_share, subhash, "vtable",
		       PTR2UV(magic->mg_virtual));
    inc_UV_key_in_hash(dont_share, subhash, "len", magic->mg_len);
    inc_UV_key_in_hash(dont_share, subhash, "flags", magic->mg_flags);
  }
}

static SV *
sv_stats(bool dont_share) {
  HV *hv = newHV_maybeshare(dont_share);
  UV av_has_arylen = 0;
  HV *sizes;
  HV *types_raw = newHV_maybeshare(dont_share);
#ifdef DO_PM_STATS
  HV *pm_stats_raw = newHV_maybeshare(dont_share);
#endif
  HV *riter_stats_raw = newHV_maybeshare(dont_share);
  UV hv_has_eiter = 0;
  HV *hv_shared_stats = init_hv_key_stats(dont_share);
  HV *hv_unshared_stats = init_hv_key_stats(dont_share);
  HV *symtab_shared_stats = init_hv_key_stats(dont_share);
  HV *symtab_unshared_stats = init_hv_key_stats(dont_share);
  HV *mg_stats_raw = newHV_maybeshare(dont_share);
  HV *stash_stats_raw = newHV_maybeshare(dont_share);
  HV *hv_name_stats = newHV_maybeshare(dont_share);
  U32 gv_gp_null_anon = 0;
  U32 gv_name_null = 0;
  HV *gv_name_stats = newHV_maybeshare(dont_share);
  HV *gv_gp_null = newHV_maybeshare(dont_share);
  HV *gv_stats = newHV_maybeshare(dont_share);
  HV *gv_obj_stats = newHV_maybeshare(dont_share);
  HV *pv_shared_strings = newHV_maybeshare(dont_share);
  HV *pvx_normal_stats = 0;
  HV *pvx_hek_stats = 0;
  HV *pvx_cow_stats = 0;
  HV *pvx_alien_stats = 0;
  HV *types;
  UV fakes = 0;
  UV arenas = 0;
  UV slots = 0;
  UV free = 0;
  SV* svp = PL_sv_arenaroot;
  HV *prototypes = newHV_maybeshare(dont_share);
  HV *gp_refcnt_raw = newHV_maybeshare(dont_share);
  HV *gp_seen = newHV_maybeshare(dont_share);
  HV *gp_files = newHV_maybeshare(dont_share);
  U32 gp_null_files = 0;
  HV *cv_files = newHV_maybeshare(dont_share);
  U32 cv_null_files = 0;
  HV *fm_prototypes = newHV_maybeshare(dont_share);
  HV *fm_files = newHV_maybeshare(dont_share);
  U32 fm_null_files = 0;
  HV *magic = newHV_maybeshare(dont_share);

  while (svp) {
    SV **count;
    UV size = SvREFCNT(svp); 
    
    arenas++;
    slots += size;
    if (SvFAKE(svp))
      fakes++;

    inc_UV_key(hv, size);

    /* Remember that the zeroth slot is used as the pointer onwards, so don't
       include it. */

    while (--size > 0) {
      UV type = SvTYPE(svp + size);
      SV *target = (SV*)svp + size;

      if(type >= SVt_PVMG && type <= sv_names_len) {
	/* This is naughty. I'm storing hashes directly in hashes.  */
	HV **stats;
	MAGIC *mg = SvMAGIC(target);
	UV mg_count = 0;

	while (mg) {
	  mg_count++;
	  process_magic(dont_share, magic, mg);
	  mg = mg->mg_moremagic;
	}

	stats = (HV**) hv_fetch(mg_stats_raw, (char*)&type, sizeof(type), 1);
	if (stats) {
	  if (SvTYPE(*stats) != SVt_PVHV) {
	    /* We got back a new SV that has just been created. Substitute a
	       hash for it.  */
	    SvREFCNT_dec(*stats);
	    *stats = newHV_maybeshare(dont_share);
	  }
	  inc_UV_key(*stats, mg_count);
	}

	if (SvSTASH(target)) {
	  inc_UV_key(stash_stats_raw, type);
	}
      }
      if(type == SVt_PVHV) {
	HV *keystats = hv_shared_stats;
#ifdef DO_PM_STATS
	UV pm_count = 0;
#ifdef HvPMROOT
	PMOP *pm = HvPMROOT((HV*)target);
#else
	MAGIC *mg = mg_find((SV *)target, PERL_MAGIC_symtab);
	PMOP *pm = mg ? (PMOP *) mg->mg_obj : 0;
#endif

	while (pm) {
	  pm_count++;
	  pm = pm->op_pmnext;
	}

	inc_UV_key(pm_stats_raw, pm_count);
#endif

	if (HvEITER_get(target))
	  hv_has_eiter++;
	inc_UV_key(riter_stats_raw, (UV)HvRITER_get(target));
	if (HvNAME_get(target)) {
	  inc_key(hv_name_stats, HvNAME_get(target));
	  keystats = HvSHAREKEYS(target)
	    ? symtab_shared_stats : symtab_unshared_stats;
	} else if (!HvSHAREKEYS(target))
	  keystats = hv_unshared_stats;

	calculate_hv_key_stats(keystats, (HV*)target);
      } else if (type == SVt_PVAV) {
	if (AvARYLEN(target))
	  av_has_arylen++;
      } else if (type == SVt_PVGV) {
	const char *name = GvNAME(target);
	const struct gp *const gp = GvGP(target);

	if (name) {
	  STRLEN namelen = GvNAMELEN(target);
	  inc_key_len(gv_name_stats, name, namelen);
	} else {
	  gv_name_null++;
	}
	if (!gp) {
	  const char *name = HvNAME_get(GvSTASH(target));
	  if (name)
	    inc_key(gv_gp_null, name);
	  else
	    gv_gp_null_anon++;
	} else {

	  if (GvSV(target)) {
	    inc_UV_key_in_hash(dont_share, gv_stats, "SCALAR",
			       SvTYPE(GvSV(target)));
	    if (SvOBJECT(GvSV(target)))
	      inc_key(gv_obj_stats, "SCALAR");
	  }
	  if (GvAV(target)) {
	    inc_UV_key_in_hash(dont_share, gv_stats, "ARRAY",
			       SvTYPE(GvAV(target)));
	    if (SvOBJECT(GvAV(target)))
	      inc_key(gv_obj_stats, "ARRAY");
	  }
	  if (GvHV(target)) {
	    inc_UV_key_in_hash(dont_share, gv_stats, "HASH",
			       SvTYPE(GvHV(target)));
	    if (SvOBJECT(GvHV(target)))
	      inc_key(gv_obj_stats, "HASH");
	  }
	  if (GvIO(target)) {
	    inc_UV_key_in_hash(dont_share, gv_stats, "IO",
			       SvTYPE(GvIO(target)));
	    if (SvOBJECT(GvIO(target)))
	      inc_key(gv_obj_stats, "IO");
	  }
	  if (GvCV(target)) {
	    inc_UV_key_in_hash(dont_share, gv_stats, "CODE",
			       SvTYPE(GvCV(target)));
	    if (SvOBJECT(GvCV(target)))
	      inc_key(gv_obj_stats, "CODE");
	  }
	  if (GvFORM(target)) {
	    inc_UV_key_in_hash(dont_share, gv_stats, "FORMAT",
			       SvTYPE(GvFORM(target)));
	    if (SvOBJECT(GvFORM(target)))
	      inc_key(gv_obj_stats, "FORMAT");
	  }
	  inc_UV_key(gp_refcnt_raw, GvREFCNT(target));

	  if (!hv_exists(gp_seen, (char *)&gp, sizeof(gp))) {
	    const char *file = gp->gp_file;

	    if (file)
	      inc_key(gp_files, file);
	    else
	      ++gp_null_files;

	    hv_store(gp_seen, (char *)&gp, sizeof(gp), &PL_sv_yes, 0);
	  }
	}
      } else if (type == SVt_PVCV) {
	const char *file = CvFILE(target);

	if (file)
	  inc_key(cv_files, file);
	else
	  ++cv_null_files;

	if (SvPOK(target)) {
	  I32 length = SvCUR(target);
	  inc_key_len(prototypes, SvPVX(target),
		      SvUTF8(target) ? -length : length);
	}
      } else if (type == SVt_PVFM) {
	const char *file = CvFILE(target);

	if (file)
	  inc_key(fm_files, file);
	else
	  ++fm_null_files;

	if (SvPOK(target)) {
	  I32 length = SvCUR(target);
	  inc_key_len(fm_prototypes, SvPVX(target),
		      SvUTF8(target) ? -length : length);
	}
      }
      /* This type inequality is going to break on blead versions if the
	 types are reordered significantly.  */
      if (type >= SVt_PV && (type <= SVt_PVBM || type == SVt_PVLV)
	  && type != SVTYPEMASK && !SvROK(target) && SvPVX(target)) {
	HV **pvx_stats = &pvx_normal_stats;

	if(SvFAKE(target) && SvREADONLY(target)) {
	  /* Some sort of COW */
	  if (SvLEN(target)) {
	    pvx_stats = &pvx_cow_stats;
	  } else {
	    pvx_stats = &pvx_hek_stats;
	    inc_key_len(pv_shared_strings, SvPVX(target),
#if PERL_VERSION >= 8
			SvUTF8(target) ? -SvCUR(target) :
#endif
			SvCUR(target));
	  }
	} else if (!SvLEN(target)) {
	  pvx_stats = &pvx_alien_stats;
	}

	calculate_pvx_stats(dont_share, pvx_stats, target);
      }
      inc_UV_key(types_raw, type);
    }

    svp = (SV *) SvANY(svp);
  }

  {
    /* Now splice all our mg stats hashes into the main count hash  */
    HV *mg_stats_raw_for_type;
    char *key;
    I32 keylen;

    hv_iterinit(mg_stats_raw);
    while ((mg_stats_raw_for_type
	    = (HV *) hv_iternextsv(mg_stats_raw, &key, &keylen))) {
      HV *type_stats = newHV_maybeshare(dont_share);
      UV type;
      /* This is the position in the main counts stash.  */
      SV **count = hv_fetch(types_raw, key, keylen, 1);

      assert (keylen == sizeof(UV));
      assert (SvTYPE(mg_stats_raw_for_type) == SVt_PVHV);

      memcpy (&type, key, sizeof(type));

      if (count) {
	if(hv_store(type_stats, "total", 5, *count, 0)) {
	  /* We've now re-stored the total.
	   At this point hv_stats and types_raw *both* think that they own a
	   reference, but the reference count is 1.
	   Which is OK, because types_raw is about to be holding a reference
	   to something else:
	  */
	  *count = newRV_noinc((SV *)type_stats);

	  store_hv_in_hv(type_stats, "mg",
			 unpack_UV_hash_keys(dont_share,
					     mg_stats_raw_for_type));

	  if(type == SVt_PVHV) {
	    /* Specific extra things to store for Hashes  */
#ifdef DO_PM_STATS
	    store_hv_in_hv(type_stats, "PMOPs",
			   unpack_UV_hash_keys(dont_share, pm_stats_raw));
	    SvREFCNT_dec(pm_stats_raw);
#endif
	    store_hv_in_hv(type_stats, "riter",
			   unpack_IV_hash_keys(dont_share, riter_stats_raw));
	    SvREFCNT_dec(riter_stats_raw);
	    store_hv_in_hv(type_stats, "names", hv_name_stats);
	    store_UV(type_stats, "has_eiter", hv_has_eiter);

	    store_hv_in_hv(type_stats, "shared_keys", hv_shared_stats);
	    store_hv_in_hv(type_stats, "unshared_keys", hv_unshared_stats);
	    store_hv_in_hv(type_stats, "symtab_shared_keys",
			   symtab_shared_stats);
	    store_hv_in_hv(type_stats, "symtab_unshared_keys",
			   symtab_unshared_stats);
 	  } else if(type == SVt_PVAV) {
	    store_UV(type_stats, "has_arylen", av_has_arylen);
	  } else if(type == SVt_PVGV) {
	    HE *he;

	    hv_iterinit(gv_stats);
	    while ((he = hv_iternext(gv_stats))) {
	      HV *packed;
	      assert(SvROK(HeVAL(he)));

	      packed = (HV *) SvRV(HeVAL(he));
	      SvRV(HeVAL(he)) = (SV *) unpack_UV_keys_to_types(dont_share,
							       packed);
	      SvREFCNT_dec(packed);
	    }

	    store_hv_in_hv(type_stats, "thingies", gv_stats);
	    store_hv_in_hv(type_stats, "objects", gv_obj_stats);
	    store_hv_in_hv(type_stats, "null_gp", gv_gp_null);
	    store_UV(type_stats, "null_gp_anon", gv_gp_null_anon);
	    store_hv_in_hv(type_stats, "names", gv_name_stats);
	    store_UV(type_stats, "null_name", gv_name_null);
	    store_hv_in_hv(type_stats, "gp_refcnt",
			   unpack_UV_hash_keys(dont_share, gp_refcnt_raw));
	    SvREFCNT_dec(gp_refcnt_raw);
 	  } else if(type == SVt_PVCV) {
	    store_UV(type_stats, "NULL files", cv_null_files);
	    store_hv_in_hv(type_stats, "files", cv_files);
	    store_hv_in_hv(type_stats, "prototypes", prototypes);
 	  } else if(type == SVt_PVFM) {
	    store_UV(type_stats, "NULL files", fm_null_files);
	    store_hv_in_hv(type_stats, "files", fm_files);
	    store_hv_in_hv(type_stats, "prototypes", fm_prototypes);
	  }
	}
      }
    }
  }
  /* At which point the raw hashes still have 1 reference each, owned by the
     top level hash, which we don't need any more.  */
  SvREFCNT_dec(mg_stats_raw);

  /* Now splice our stash stats into the main count hash.
     I can't see a good way to reduce code duplication here.  */
  {
    SV *stash_stat;
    char *key;
    I32 keylen;

    hv_iterinit(stash_stats_raw);
    while ((stash_stat = hv_iternextsv(stash_stats_raw, &key, &keylen))) {
      /* This is the position in the main counts stash.  */
      SV **count = hv_fetch(types_raw, key, keylen, 1);

      if (count) {
	HV *results;
	if (SvROK(*count)) {
	  results = (HV*)SvRV(*count);
	} else {
	  results = newHV_maybeshare(dont_share);

	  /* We're donating the reference of *count from types_raw to results
	   */
	  if(!hv_store(results, "total", 5, *count, 0)) {
	    /* We're in a mess here.  */
	    croak("store failed");
	  }
	  *count = newRV_noinc((SV *)results);
	}

	if(hv_store(results, "has_stash", 9, stash_stat, 0)) {
	  /* Currently has 1 reference, owned by stash_stats_raw. Fix this:  */
	  SvREFCNT_inc(stash_stat);
	}
      }
    }
  }
  SvREFCNT_dec(stash_stats_raw);

  svp = PL_sv_root;
  while (svp) {
    free++;
    svp = (SV *) SvANY(svp);
  }

  types = unpack_UV_keys_to_types(dont_share, types_raw);
  SvREFCNT_dec(types_raw);
  sizes = unpack_UV_hash_keys(dont_share, hv);

  /* Now re-use it for our output  */
  hv_clear(hv);

  store_UV(hv, "arenas", arenas);
  store_UV(hv, "fakes", fakes);
  store_UV(hv, "total_slots", slots);
  store_UV(hv, "free", free);

  store_UV(hv, "nice_chunk_size", PL_nice_chunk_size);
  store_UV(hv, "sizeof(SV)", sizeof(SV));
  store_UV(hv, "sizeof(struct gp)", sizeof(struct gp));

  store_hv_in_hv(hv, "sizes", sizes);
  store_hv_in_hv(hv, "types", types);

  {
    HV *pvx_stats = newHV_maybeshare(dont_share);

    if (pvx_normal_stats)
      store_hv_in_hv(pvx_stats, "normal", pvx_normal_stats);
    if (pvx_hek_stats)
      store_hv_in_hv(pvx_stats, "shared hash key", pvx_hek_stats);
    if (pvx_cow_stats)
      store_hv_in_hv(pvx_stats, "old COW", pvx_cow_stats);
    if (pvx_alien_stats)
      store_hv_in_hv(pvx_stats, "alien", pvx_alien_stats);
    
    store_hv_in_hv(hv, "PVX", pvx_stats);
  }

  store_hv_in_hv(hv, "shared string scalars", pv_shared_strings);

  store_UV(hv, "gp NULL files", gp_null_files);
  store_hv_in_hv(hv, "gp files", gp_files);

  SvREFCNT_dec(gp_seen);

  {
    SV *magic_stat_ref;
    char *key;
    I32 keylen;

    hv_iterinit(magic);
    while ((magic_stat_ref = hv_iternextsv(magic, &key, &keylen))) {
      HV *magic_stat;

      assert(SvROK(magic_stat_ref));
      magic_stat = (HV *) SvRV(magic_stat_ref);
      assert(SvTYPE(magic_stat) == SVt_PVHV);

      unpack_hash_keys_in_subhash(dont_share, magic_stat, "len",
				  (unpack_function*)&Perl_sv_setiv);
      unpack_hash_keys_in_subhash(dont_share, magic_stat, "vtable",
				  &Perl_sv_setuv);
      unpack_hash_keys_in_subhash(dont_share, magic_stat, "flags",
				  &Perl_sv_setuv);
    }
  }

  store_hv_in_hv(hv, "magic", magic);

  return newRV_noinc((SV *) hv);
}

static SV *
shared_string_table() {
  HV *hv = newHV();
  HE *entry;
  /* Somehow it feels safer not to be fiddling with the count of shared hash
     keys while iterating over them.  */
  HvSHAREKEYS_off(hv);
  hv_ksplit(hv, HvMAX(PL_strtab));

  hv_iterinit(PL_strtab);

  while ((entry = hv_iternext(PL_strtab))) {
    SV *sv = newSVuv((PTR2UV(HeVAL(entry)))/ sizeof(SV));
    if (!hv_store(hv, HeKEY(entry), HeKLEN(entry), sv, HeHASH(entry))) {
      /* Oops. Failed.  */
      SvREFCNT_dec(sv);
    }
  }

  return newRV_noinc((SV *) hv);
}

struct name_len_size {
  const char *name;
  size_t size;
};

static SV *
sizes() {
  HV *hv = newHV();
  const struct name_len_size entries[] = {
#include "sizes.inc"
    /* Using a NULL entry as a terminator rather than calculating the length
       at compile time saves special casing the last real entry to avoid a
       trailing comma.  */
    {0, 0}
  };
  const struct name_len_size *entry = entries;
  
  while (entry->name) {
    store_UV(hv, entry->name, entry->size);
    ++entry;
  }
  return newRV_noinc((SV *) hv);
}

MODULE = Devel::Arena		PACKAGE = Devel::Arena		

PROTOTYPES: ENABLE

SV *
sv_stats(dont_share = 0)
     bool dont_share;

SV *
shared_string_table()

SV *
sizes()
