#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

# undef HAVE_ATOMICS

# ifdef __GNUC__
#   define GCC_V (10000*__GNUC__ + 100*__GNUC_MINOR__ + __GNUC_PATCHLEVEL__)

#   if GCC_V >= 30000
#     define expect(expr,value) __builtin_expect ((expr),(value))
#     define INLINE static inline
#   endif

#   if GCC_V >= 40102
#     pragma message "GCC Version >= 40102: using atomic builtins"
#     define HAVE_ATOMICS 1
#     define atomic_add(ptr, v) __sync_add_and_fetch((ptr), (v))
#     define atomic_sub(ptr, v) __sync_sub_and_fetch((ptr), (v))
#   endif
# endif

# include "config.h"

# ifndef expect
#   define expect(expr,value) (expr)
# endif

# ifndef INLINE
#   define INLINE static
# endif

# ifndef atomic_add
#   define atomic_add(ptr, v) (*(ptr)+=(v))
# endif

# ifndef atomic_sub
#   define atomic_sub(ptr, v) (*(ptr)-=(v))
# endif

# ifndef HAVE_ATOMICS
#   define HAVE_ATOMICS 0
# endif

#define expect_false(expr) expect ((expr) != 0, 0)
#define expect_true(expr)  expect ((expr) != 0, 1)

typedef volatile IV vIV;
typedef volatile UV vUV;

struct hdr {
  union {
    vUV iv;
    char *c;
  } magic;
  vUV how_many;
  vUV slotsize;
  vUV extra;
};

INLINE vIV* get_slot( SV *sb, UV slot, UV *slotsize ) {
  if( expect_true((sb && SvROK(sb))) ) {
    struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
    vIV *data=(vIV*)(sizeof(*hdr)+(char*)hdr);
    if( expect_true(slot<hdr->how_many) ) {
      if( expect_true(slotsize) ) *slotsize=hdr->slotsize;
      return &data[slot*hdr->slotsize];
    } else {
      croak("slot number out of range");
    }
  } else {
    croak("invalid scoreboard parameter");
  }
}

INLINE IV sum( SV *sb, UV idx ) {
  if( expect_true((sb && SvROK(sb))) ) {
    struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
    vIV *data=(vIV*)(sizeof(*hdr)+(char*)hdr);
    IV res=0;
    UV i;
    if( expect_true(idx<hdr->slotsize) ) {
      for( i=0; i<hdr->how_many; i++ ) {
	res+=data[i*hdr->slotsize+idx];
      }
      return res;
    } else {
      croak("index within slot out of range");
    }
  } else {
    croak("invalid scoreboard parameter");
  }
}

INLINE vIV* get_extra( SV *sb, UV *slotsize ) {
  if( expect_true((sb && SvROK(sb))) ) {
    struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
    vIV *data=(vIV*)(sizeof(*hdr)+(char*)hdr);
    if( expect_true(slotsize) ) *slotsize=hdr->extra;
    return &data[hdr->how_many*hdr->slotsize];
  } else {
    croak("invalid scoreboard parameter");
  }
}

MODULE = IPC::ScoreBoard		PACKAGE = IPC::ScoreBoard		

PROTOTYPES: ENABLE

IV
nslots(sb)
  SV* sb
  PROTOTYPE: $
  CODE:
    if( expect_true((sb && SvROK(sb))) ) {
      struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
      RETVAL=hdr->how_many;
    } else {
      croak("invalid scoreboard parameter");
    }
  OUTPUT:
    RETVAL

IV
slotsize(sb)
  SV* sb
  PROTOTYPE: $
  CODE:
    if( expect_true((sb && SvROK(sb))) ) {
      struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
      RETVAL=hdr->slotsize;
    } else {
      croak("invalid scoreboard parameter");
    }
  OUTPUT:
    RETVAL

IV
nextra(sb)
  SV* sb
  PROTOTYPE: $
  CODE:
    if( expect_true((sb && SvROK(sb))) ) {
      struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
      RETVAL=hdr->extra;
    } else {
      croak("invalid scoreboard parameter");
    }
  OUTPUT:
    RETVAL

IV
get(sb, slot, idx=0)
  SV* sb
  UV slot
  UV idx
  PROTOTYPE: $$;$
  INIT:
    UV sz;
    vIV *slotptr=get_slot(sb, slot, &sz);
  CODE:
    if( expect_true(idx<sz) ) {
      RETVAL=slotptr[idx];
    } else {
      croak("index within slot out of range");
    }
  OUTPUT:
    RETVAL

IV
set(sb, slot, idx, val)
  SV* sb
  UV slot
  UV idx
  IV val
  PROTOTYPE: $$$$
  INIT:
    UV sz;
    vIV *slotptr=get_slot(sb, slot, &sz);
  CODE:
  if( expect_true(idx<sz) ) {
      RETVAL=slotptr[idx]=val;
    } else {
      croak("index within slot out of range");
    }
  OUTPUT:
    RETVAL

IV
incr(sb, slot, idx, amount=1)
  SV* sb
  UV slot
  UV idx
  IV amount
  PROTOTYPE: $$$;$
  INIT:
    UV sz;
    vIV *slotptr=get_slot(sb, slot, &sz);
  CODE:
    if( expect_true(idx<sz) ) {
      RETVAL=atomic_add(&slotptr[idx], amount);
    } else {
      croak("index within slot out of range");
    }
  OUTPUT:
    RETVAL

IV
decr(sb, slot, idx, amount=1)
  SV* sb
  UV slot
  UV idx
  IV amount
  PROTOTYPE: $$$;$
  INIT:
    UV sz;
    vIV *slotptr=get_slot(sb, slot, &sz);
  CODE:
    if( expect_true(idx<sz) ) {
      RETVAL=atomic_sub(&slotptr[idx], amount);
    } else {
      croak("index within slot out of range");
    }
  OUTPUT:
    RETVAL

IV
sum(sb, idx)
  SV* sb
  UV idx
  PROTOTYPE: $$
  CODE:
    RETVAL=sum(sb, idx);
  OUTPUT:
    RETVAL

void
get_all(sb, slot)
  SV* sb
  UV slot
  PROTOTYPE: $$
  INIT:
    UV sz, i;
    vIV *slotptr=get_slot(sb, slot, &sz);
  PPCODE:
    EXTEND(SP, sz);
    for( i=0; i<sz; i++ ) {
      mPUSHi(slotptr[i]);
    }

void
sum_all(sb)
  SV* sb
  PROTOTYPE: $
  PPCODE:
    if( expect_true((sb && SvROK(sb))) ) {
      struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
      vIV *data=(vIV*)(sizeof(*hdr)+(char*)hdr);
      UV i, j;
      EXTEND(SP, hdr->slotsize);
      for( j=0; j<hdr->slotsize; j++ ) {
	mPUSHi(0);
      }
      for( i=0; i<hdr->how_many; i++ ) {
	for( j=0; j<hdr->slotsize; j++ ) {
	  SvIV_set(ST(j), SvIVX(ST(j))+data[i*hdr->slotsize+j]);
	}
      }
    } else {
      croak("invalid scoreboard parameter");
    }

IV
get_extra(sb, idx=0)
  SV* sb
  UV idx
  PROTOTYPE: $;$
  INIT:
    UV sz;
    vIV *slotptr=get_extra(sb, &sz);
  CODE:
    if( expect_true(idx<sz) ) {
      RETVAL=slotptr[idx];
    } else {
      croak("index within extra slot out of range");
    }
  OUTPUT:
    RETVAL

IV
set_extra(sb, idx, val)
  SV* sb
  UV idx
  IV val
  PROTOTYPE: $$$
  INIT:
    UV sz;
    vIV *slotptr=get_extra(sb, &sz);
  CODE:
  if( expect_true(idx<sz) ) {
      RETVAL=slotptr[idx]=val;
    } else {
      croak("index within extra slot out of range");
    }
  OUTPUT:
    RETVAL

IV
incr_extra(sb, idx, amount=1)
  SV* sb
  UV idx
  IV amount
  PROTOTYPE: $$;$
  INIT:
    UV sz;
    vIV *slotptr=get_extra(sb, &sz);
  CODE:
    if( expect_true(idx<sz) ) {
      RETVAL=atomic_add(&slotptr[idx], amount);
    } else {
      croak("index within extra slot out of range");
    }
  OUTPUT:
    RETVAL

IV
decr_extra(sb, idx, amount=1)
  SV* sb
  UV idx
  IV amount
  PROTOTYPE: $$;$
  INIT:
    UV sz;
    vIV *slotptr=get_extra(sb, &sz);
  CODE:
    if( expect_true(idx<sz) ) {
      RETVAL=atomic_sub(&slotptr[idx], amount);
    } else {
      croak("index within extra slot out of range");
    }
  OUTPUT:
    RETVAL

void
get_all_extra(sb)
  SV* sb
  PROTOTYPE: $
  INIT:
    UV sz, i;
    vIV *slotptr=get_extra(sb, &sz);
  PPCODE:
    EXTEND(SP, sz);
    for( i=0; i<sz; i++ ) {
      mPUSHi(slotptr[i]);
    }

IV
have_atomics()
  PROTOTYPE:
  CODE:
    RETVAL=HAVE_ATOMICS;
  OUTPUT:
    RETVAL


IV
offset_of(sb, slot, idx=0)
  SV* sb
  UV slot
  UV idx
  PROTOTYPE: $$;$
  CODE:
    RETVAL=-1;
    if( expect_true((sb && SvROK(sb))) ) {
      struct hdr *hdr=(struct hdr *)SvPV_nolen(SvRV(sb));
      IV *data=(IV*)(sizeof(*hdr)+(char*)hdr);

      if( expect_true(items>2 && SvOK(ST(2))) ) {
	/* fetch slot offset */
	if( expect_true(slot<hdr->how_many) ) {
	  if( expect_true(idx<hdr->slotsize) ) {
	    RETVAL=(char*)&data[slot*hdr->slotsize+idx] - (char*)hdr;
	  } else {
	    croak("index within extra slot out of range");
	  }
	} else {
	  croak("slot number out of range");
	}
      } else {
	/* fetch extra offset */
	if( expect_true(slot<hdr->extra) ) {
	  RETVAL=(char*)&data[hdr->how_many*hdr->slotsize+slot] - (char*)hdr;
	} else {
	  croak("index within extra slot out of range");
	}
      }
    }
  OUTPUT:
    RETVAL

## Local Variables:
## mode: C
## End:
