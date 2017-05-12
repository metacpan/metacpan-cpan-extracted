#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/opt/perl/perl-5.12.2/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(DLG_EXIT_CANCEL DLG_EXIT_ERROR DLG_EXIT_ESC DLG_EXIT_EXTRA
	       DLG_EXIT_HELP DLG_EXIT_ITEM_HELP DLG_EXIT_OK DLG_EXIT_UNKNOWN));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Hobocamp", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Hobocamp", $types);
__END__
   */

  switch (len) {
  case 11:
    if (memEQ(name, "DLG_EXIT_OK", 11)) {
#ifdef DLG_EXIT_OK
      *iv_return = DLG_EXIT_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 12:
    if (memEQ(name, "DLG_EXIT_ESC", 12)) {
#ifdef DLG_EXIT_ESC
      *iv_return = DLG_EXIT_ESC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "DLG_EXIT_HELP", 13)) {
#ifdef DLG_EXIT_HELP
      *iv_return = DLG_EXIT_HELP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    /* Names all of length 14.  */
    /* DLG_EXIT_ERROR DLG_EXIT_EXTRA */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'R':
      if (memEQ(name, "DLG_EXIT_ERROR", 14)) {
      /*                          ^         */
#ifdef DLG_EXIT_ERROR
        *iv_return = DLG_EXIT_ERROR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "DLG_EXIT_EXTRA", 14)) {
      /*                          ^         */
#ifdef DLG_EXIT_EXTRA
        *iv_return = DLG_EXIT_EXTRA;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    if (memEQ(name, "DLG_EXIT_CANCEL", 15)) {
#ifdef DLG_EXIT_CANCEL
      *iv_return = DLG_EXIT_CANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "DLG_EXIT_UNKNOWN", 16)) {
#ifdef DLG_EXIT_UNKNOWN
      *iv_return = DLG_EXIT_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    if (memEQ(name, "DLG_EXIT_ITEM_HELP", 18)) {
#ifdef DLG_EXIT_ITEM_HELP
      *iv_return = DLG_EXIT_ITEM_HELP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}


#### XS Section:
void
constant(sv)
    PREINIT:
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
        /* Change this to constant(aTHX_ s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(aTHX_ s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv =
	    sv_2mortal(newSVpvf("%s is not a valid Hobocamp macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined Hobocamp macro %s, used",
				   s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
	/* Uncomment this if you need to return NOs
        case PERL_constant_ISNO:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_no);
          break; */
	/* Uncomment this if you need to return NVs
        case PERL_constant_ISNV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHn(nv);
          break; */
	/* Uncomment this if you need to return PVs
        case PERL_constant_ISPV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, strlen(pv));
          break; */
	/* Uncomment this if you need to return PVNs
        case PERL_constant_ISPVN:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, iv);
          break; */
	/* Uncomment this if you need to return SVs
        case PERL_constant_ISSV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break; */
	/* Uncomment this if you need to return UNDEFs
        case PERL_constant_ISUNDEF:
          break; */
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
	/* Uncomment this if you need to return YESs
        case PERL_constant_ISYES:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_yes);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Hobocamp macro %s, used",
               type, s));
          PUSHs(sv);
        }
