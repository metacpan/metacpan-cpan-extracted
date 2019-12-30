#ifndef __DEVEL_MAT_DUMPER_HELPER_H__
#define __DEVEL_MAT_DUMPER_HELPER_H__

#define DMD_ANNOTATE_SV(targ, val, name)  S_DMD_AnnotateSv(aTHX_ targ, val, name)
static int S_DMD_AnnotateSv(pTHX_ const SV *targ, const SV *val, const char *name)
{
  dSP;
  if(!targ || !val)
    return 0;

  mXPUSHi(0x87); /* TODO PMAT_SVxSVSVnote */
  XPUSHs((SV *)targ);
  XPUSHs((SV *)val);
  mXPUSHp(name, strlen(name));
  PUTBACK;
  return 4;
}

typedef int DMD_Helper(pTHX_ const SV *sv);

#define DMD_SET_PACKAGE_HELPER(package, helper) S_DMD_SetPackageHelper(aTHX_ package, helper)
static void S_DMD_SetPackageHelper(pTHX_ char *package, DMD_Helper *helper)
{
  HV *helper_per_package = get_hv("Devel::MAT::Dumper::HELPER_PER_PACKAGE", GV_ADD);

  hv_store(helper_per_package, package, strlen(package), newSVuv(PTR2UV(helper)), 0);
}

typedef int DMD_MagicHelper(pTHX_ const SV *sv, MAGIC *mg);

#define DMD_SET_MAGIC_HELPER(vtbl, helper) S_DMD_SetMagicHelper(aTHX_ vtbl, helper)
static void S_DMD_SetMagicHelper(pTHX_ MGVTBL *vtbl, DMD_MagicHelper *helper)
{
  HV *helper_per_magic = get_hv("Devel::MAT::Dumper::HELPER_PER_MAGIC", GV_ADD);
  SV *keysv = newSViv((IV)vtbl);

  hv_store_ent(helper_per_magic, keysv, newSVuv(PTR2UV(helper)), 0);

  SvREFCNT_dec(keysv);
}

#define DMD_IS_ACTIVE()  S_DMD_is_active(aTHX)
static bool S_DMD_is_active(pTHX)
{
#ifdef MULTIPLICITY
  return !!get_cv("Devel::MAT::Dumper::dump", 0);
#else
  static bool active;
  static bool cached = FALSE;
  if(!cached) {
    active = !!get_cv("Devel::MAT::Dumper::dump", 0);
    cached = TRUE;
  }
  return active;
#endif
}

#endif
