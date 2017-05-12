#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#define NEED_vnewSVpvf
#define NEED_warner
#include "ppport.h"

#define MAGIC	1	/* Support magic */

#ifndef INFINITY
# ifdef HUGE_VAL
#  define INFINITY	((NV) HUGE_VAL)
# else /* HUGE_VAL */
#  define INFINITY	(NV_MAX*NV_MAX)
# endif /* HUGE_VAL */
#endif /* INFINITY */

#define MORTALCOPY(sv) sv_2mortal(newSVsv(sv))
#define MAX_SIZE	((size_t) -1)

enum order {
    LESS = 1,
    MORE,
    LT,
    GT,
    CODE_ORDER,
    MAX_ORDER
};

enum elements {
    SCALAR = 1,
    ARRAY,
    HASH,
    METHOD,
    OBJECT,
    FUNCTION,
    ANY_ELEM,
    MAX_ELEMENTS
};

typedef struct heap {
    SV **values;	/* The values the user stored in the heap */
    SV **keys;		/* The corresponding keys, but only if wrapped == 1 */
    SV *hkey;		/* An SV used in finding a key for a value.
                           E.g. the hash key for element type Hash */
    SV *order_sv;	/* Code reference to compare keys for the CODE order */
    SV *infinity;	/* The infinity for the given order, can be NULL */
    SV *user_data;	/* Associated data, only for the user */
    size_t used;	/* How many values/keys are used+1 (index 0 unused) */
    size_t allocated;	/* How many values/keys are allocated */
    size_t max_count;	/* Maximum heap size, MAX_SIZE means unlimited */
    I32 aindex;		/* A value used for indexing the key for a value */
    int wrapped;	/* True if keys are stored seperate from values */
    int fast;		/* True means that keys are scalars, not SV's */
    int has_values;	/* SV values in the SV array. False for fast scalars */
    int dirty;		/* "dirty" option was given and true */
    int can_die;	/* used to choose between mass-heapify or one-by-one */
    int key_ops;        /* key_insert, _key_insert and key_absorb will work */
    int locked;
    enum order order;	/* Which order is used */
    enum elements elements; /* Element type */
} *heap;

/*
    O: not filled in
    X: Filled in, but not an SV (only happens for keys, if and only if fast)
    *: Filled in with an SV     (if and only if has_values)

    Possible flag combinations:
    wrapped fast has_values KV
      0       0      0	          Impossible
      1       0      0		  Impossible
      0       1      0      XO    scalar dirty order
      1       1      0		  Impossible
      0       0      1      O*    Normal heap
      1       0      1      **    Object/Any heap
     (0       1      1      X*    normal heap with dirty order) # dropped
      1       1      1      X*    Object/Any heap with dirty order

      looks "wrapped" to the outside world for the last 3 cases
 */

typedef struct merge {
    SV *key;
    AV *array;
    I32 index;
} merge;

typedef struct fast_merge {
    AV *array;
    I32 index;
    NV key;
} fast_merge;

/* Workaround for older perls without packWARN */
#ifndef packWARN
# define packWARN(a) (a)
#endif

/* Duplicate from perl source (since it's not exported unfortunately) */
static bool my_isa_lookup(pTHX_ HV *stash, const char *name, HV* name_stash,
                          int len, int level) {
    AV* av;
    GV* gv;
    GV** gvp;
    HV* hv = Nullhv;
    SV* subgen = Nullsv;

    /* A stash/class can go by many names (ie. User == main::User), so
       we compare the stash itself just in case */
    if ((name_stash && stash == name_stash) ||
        strEQ(HvNAME(stash), name) ||
        strEQ(name, "UNIVERSAL")) return TRUE;

    if (level > 100) croak("Recursive inheritance detected in package '%s'",
                           HvNAME(stash));

    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (subgen = GvSV(gv)) &&
        (hv = GvHV(gv))) {
        if (SvIV(subgen) == (IV)PL_sub_generation) {
            SV* sv;
            SV** svp = (SV**)hv_fetch(hv, name, len, FALSE);
            if (svp && (sv = *svp) != (SV*)&PL_sv_undef) {
                DEBUG_o( Perl_deb(aTHX_ "Using cached ISA %s for package %s\n",
                                  name, HvNAME(stash)) );
                return sv == &PL_sv_yes;
            }
        } else {
            DEBUG_o( Perl_deb(aTHX_ "ISA Cache in package %s is stale\n",
                              HvNAME(stash)) );
            hv_clear(hv);
            sv_setiv(subgen, PL_sub_generation);
        }
    }

    gvp = (GV**)hv_fetch(stash,"ISA",3,FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (av = GvAV(gv))) {
	if (!hv || !subgen) {
	    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, TRUE);

	    gv = *gvp;

	    if (SvTYPE(gv) != SVt_PVGV)
		gv_init(gv, stash, "::ISA::CACHE::", 14, TRUE);

	    if (!hv)
		hv = GvHVn(gv);
	    if (!subgen) {
		subgen = newSViv(PL_sub_generation);
		GvSV(gv) = subgen;
	    }
	}
	if (hv) {
	    SV** svp = AvARRAY(av);
	    /* NOTE: No support for tied ISA */
	    I32 items = AvFILLp(av) + 1;
	    while (items--) {
		SV* sv = *svp++;
		HV* basestash = gv_stashsv(sv, FALSE);
		if (!basestash) {
		    if (ckWARN(WARN_MISC))
			Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
                                    "Can't locate package %"SVf" for @%s::ISA",
                                    sv, HvNAME(stash));
		    continue;
		}
		if (my_isa_lookup(aTHX_ basestash, name, name_stash,
                                  len, level + 1)) {
		    (void)hv_store(hv,name,len,&PL_sv_yes,0);
		    return TRUE;
		}
	    }
	    (void)hv_store(hv,name,len,&PL_sv_no,0);
	}
    }
    return FALSE;
}

#define C_HEAP(object, context) c_heap(aTHX_ object, context)

static heap c_heap(pTHX_ SV *object, const char *context) {
    SV *sv;
    HV *stash, *class_stash;
    IV address;

    if (MAGIC) SvGETMAGIC(object);
    if (!SvROK(object)) {
        if (SvOK(object)) croak("%s is not a reference", context);
        croak("%s is undefined", context);
    }
    sv = SvRV(object);
    if (!SvOBJECT(sv)) croak("%s is not an object reference", context);
    stash = SvSTASH(sv);
    /* Is the next even possible ? */
    if (!stash) croak("%s is not a typed reference", context);
    class_stash = gv_stashpv("Heap::Simple::XS", FALSE);
    if (!my_isa_lookup(aTHX_ stash, "Heap::Simple::XS", class_stash, 16, 0))
        croak("%s is not a Heap::Simple::XS reference", context);
    address = SvIV(sv);
    if (!address)
        croak("Heap::Simple::XS object %s has a NULL pointer", context);
    return INT2PTR(heap, address);
}

#define TRY_C_HEAP(object) try_c_heap(aTHX_ &(object))

static heap try_c_heap(pTHX_ SV **object) {
    SV *sv;
    HV *stash, *class_stash;
    IV address;

    sv = *object;
    if (!SvROK(sv)) return NULL;
    sv = SvRV(sv);
    if (!SvOBJECT(sv)) return NULL;
    stash = SvSTASH(sv);
    /* Is the next even possible ? */
    if (!stash) return NULL;
    class_stash = gv_stashpv("Heap::Simple::XS", FALSE);
    if (!my_isa_lookup(aTHX_ stash, "Heap::Simple::XS", class_stash, 16,0))
        return NULL;
    address = SvIV(sv);
    if (!address) croak("Heap::Simple::XS object is a NULL pointer");
    *object = sv;
    return INT2PTR(heap, address);
}

static void extend(heap h, size_t min_extra) {
    min_extra += 3+h->used;
    h->allocated = 2*h->used;
    if (h->allocated < min_extra) h->allocated = min_extra;
    /* if (h->allocated > MAX_INT) croak("Allocation overflow"); */
    if (h->fast) {
        NV *tmp;
        tmp = (NV *) h->keys;
        Renew(tmp, h->allocated, NV);
        h->keys = (SV **) tmp;
        if (h->has_values) Renew(h->values, h->allocated, SV *);
    } else {
        if (h->wrapped) Renew(h->keys, h->allocated, SV *);
        Renew(h->values, h->allocated, SV *);
    }
}

/* target is lowercase, ends in 0, and lengths are already equal */
static int low_eq(const char *name, const char *target) {
    while (*target) {
        if (toLOWER(*name) != *target++) return 0;
        name++;
    }
    return 1;
}

static const char *elements_name(heap h) {
    switch(h->elements) {
      case SCALAR:   return "Scalar";
      case ARRAY:    return "Array";
      case HASH:     return "Hash";
      case METHOD:   return "Method";
      case OBJECT:   return "Object";
      case FUNCTION: return "Function";
      case ANY_ELEM: return "Any";
      case 0: croak("Element type is unspecified");
      default: croak("Assertion: Impossible element type %d", h->elements);
    }
    /* NOTREACHED */
    return NULL;
}

static const char *order_name(heap h) {
    switch(h->order) {
      case LESS: return "<";
      case MORE: return ">";
      case LT:   return "lt";
      case GT:   return "gt";
      case CODE_ORDER: return "CODE";
      case 0: croak("Order type is unspecified");
      default: croak("Assertion: Impossible order type %d", h->order);
    }
    /* NOTREACHED */
    return NULL;
}

/*  KEY only gets called if h->fast == 0 */
#define KEY(h, i) ((h)->wrapped ? (h)->keys[i] : fetch_key(aTHX_ (h),(h)->values[i]))
/* FKEY only gets called if h->fast == 1 */
#define FKEY(type, h, i)	(((type *)(h)->keys)[i])
/* key is returned with the refcount unincremented,
   key will not have get magic applied */
static SV *fetch_key(pTHX_ heap h, SV *value) {
    switch(h->elements) {
        AV *av;
        HV *hv;
        HE *he;
        SV **fetched, *key;
        I32 start, count;
      case SCALAR:
        return value;
      case ARRAY:
        /* mm, can a tied access change the stack base ? */
        if (!SvROK(value)) croak("Not a reference");
        av = (AV*) SvRV(value);
        if (SvTYPE(av) != SVt_PVAV) croak("Not an ARRAY reference");
        fetched = av_fetch(av, h->aindex, 0);
        return fetched ? *fetched : &PL_sv_undef;
      case HASH:
        if (!SvROK(value)) croak("Not a reference");
        hv = (HV*) SvRV(value);
        if (SvTYPE(hv) != SVt_PVHV) croak("Not a HASH reference");
        he = hv_fetch_ent(hv, h->hkey, 0, h->aindex);
        if (he) {
            /* HASH value for magical hashes seem to jump around */
            if (!h->aindex && !(MAGIC && SvMAGICAL(hv)))
                h->aindex = HeHASH(he);
            return HeVAL(he);
        } else {
            return &PL_sv_undef;
        }
      case OBJECT:
        if (!h->hkey) croak("Element type 'Object' without key method");
        /* FALLTHROUGH */
      case METHOD:
          {
              dSP;

              start = (SP) - PL_stack_base;
              PUSHMARK(SP);
              XPUSHs(value);
              PUTBACK;
              count = call_sv(h->hkey, G_SCALAR | G_METHOD);
              if (count != 1) croak("Forced scalar context call succeeded in returning %d values. This is impossible", (int) count);

              SPAGAIN;
              key = POPs;
              if (start != (SP) - PL_stack_base) croak("Stack base changed");
              PUTBACK;
              /* Stack is back, but can have been reallocated ! */
              return key;
          }
      case ANY_ELEM:
        if (!h->hkey) croak("Element type 'Any' without key code");
        /* FALLTHROUGH */
      case FUNCTION:
          {
              dSP;

              start = (SP) - PL_stack_base;
              PUSHMARK(SP);
              XPUSHs(value);
              PUTBACK;
              count = call_sv(h->hkey, G_SCALAR);
              if (count != 1) croak("Forced scalar context call succeeded in returning %d values. This is impossible", (int) count);

              SPAGAIN;
              key = POPs;
              if (start != (SP) - PL_stack_base) croak("Stack base changed");
              PUTBACK;
              /* Stack is back, but can have been reallocated ! */
              return key;
          }
      default:
        croak("fetch_key not implemented for element type '%s'",
              elements_name(h));
    }
    croak("fetch_key does not return for element type '%s'",
          elements_name(h));
    /* NOTREACHED */
    return NULL;
}

/* should be able to handle get magic if needed,
   but will normally be called without */
static int less(pTHX_ heap h, SV *l, SV *r) {
    SV *result;
    I32 start, count;
    struct op dmy_op, *old_op;
    dSP;

    start = (SP) - PL_stack_base;
    if (h->order == CODE_ORDER) { PUSHMARK(SP); }
    XPUSHs(l);
    XPUSHs(r);
    PUTBACK;
    switch(h->order) {
      case LESS:
        /* pp_lt(); */
        PL_ppaddr[OP_LT](aTHXR);
        break;
      case MORE:
        /* pp_gt(); */
        PL_ppaddr[OP_GT](aTHXR);
        break;
      case LT:
        /* pp_slt(); */
        old_op = PL_op;
        PL_op = &dmy_op;
        PL_op->op_type = OP_SLT;
        PL_ppaddr[OP_SLT](aTHXR);
        PL_op = old_op;
        break;
      case GT:
        /* pp_sgt(); */
        old_op = PL_op;
        PL_op = &dmy_op;
        PL_op->op_type = OP_SGT;
        PL_ppaddr[OP_SGT](aTHXR);
        PL_op = old_op;
        break;
      case CODE_ORDER:
        count = call_sv(h->order_sv, G_SCALAR);
        if (count != 1) croak("Forced scalar context call succeeded in returning %d values. This is impossible", (int) count);
        break;
      default:
        croak("less not implemented for order type '%s'", order_name(h));
    }
    SPAGAIN;
    result = POPs;
    if (start != (SP) - PL_stack_base) croak("Stack base changed");
    PUTBACK;
    /* warn("comparing %"SVf" to %"SVf" -> %d", l, r, SvTRUE(result) ? 1 : 0); */
    if      (result == &PL_sv_yes) return 1;
    else if (result == &PL_sv_no)  return 0;
    /* This can also happen for pp_lt and co in case the value is overloaded */
    /* SvTRUE does mg_get (through sv_2bool) */
    else return SvTRUE(result) ? 1 : 0;
}

/* key and value have refcount not increaded at call */
static void key_insert(pTHX_ heap h, SV *key, SV *value) {
    size_t p, pos, l, n;
    SV *new, *t1, *t2;
    int val_copied, key_copied;

    val_copied = 0;
    if (h->fast) {
        NV k;

        if (!key) {
            if (MAGIC && SvGMAGICAL(value)) {
                value = MORTALCOPY(value);
                val_copied = 1;
            }
            key = fetch_key(aTHX_ h, value);
        }
        /* SvNV will handle get magic (though sv_2nv) */
        if      (h->order == LESS) k =  SvNV(key);
        else if (h->order == MORE) k = -SvNV(key);
        else croak("No fast %s order", order_name(h));

        if (h->used > h->max_count) {
            NV key1, key2;
            if (h->used < 2 || k <= FKEY(NV, h, 1)) return;
            /* Drop the old top and percolate the new value down */
            /* This is almost completely identical to extract_top, but
               I don't see a clean way to factor it out that preserves
               resistance agains crashes of less/fetch_key */
            n = h->used-1;
            l = 2;

            if (h->has_values) {
                new = val_copied ? SvREFCNT_inc(value) : newSVsv(value);
                t1 = h->values[1];
            }

            while (l < n) {
                key1 = FKEY(NV, h, l);
                key2 = FKEY(NV, h, l+1);
                if (key1 < k) {
                    if (key2 < key1) {
                        FKEY(NV, h, l/2) = key2;
                        l++;
                    } else {
                        FKEY(NV, h, l/2) = key1;
                    }
                } else if (key2 < k) {
                    FKEY(NV, h, l/2) = key2;
                    l++;
                } else break;
                if (h->has_values) h->values[l/2] = h->values[l];
                l *= 2;
            }
            if (l == n) {
                key1 = FKEY(NV, h, l);
                if (key1 < k) {
                    FKEY(NV, h, l/2) = key1;
                    if (h->has_values) h->values[l/2] = h->values[l];
                    l*= 2;
                }
            }
            l /= 2;
            FKEY(NV, h, l) = k;
            if (h->has_values) {
                h->values[l] = new;
                SvREFCNT_dec(t1);
            }
            return;
        }

        pos = h->used;
        if (h->used >= h->allocated) extend(h, 1);
        FKEY(NV, h, 0) = k;
        if (h->has_values) {
            new = val_copied ? SvREFCNT_inc(value) : newSVsv(value);
            while (k < (FKEY(NV, h, pos) = FKEY(NV, h, pos >> 1))) {
                h->values[pos] = h->values[pos >> 1];
                pos >>= 1;
            }
            h->values[pos] = new;
        } else
            while (k < (FKEY(NV, h, pos) = FKEY(NV, h, pos >> 1))) pos >>= 1;
        FKEY(NV, h, pos) = k;
        h->used++;
        return;
    }

    /* h->fast == 0 */
    if (h->used < 2) {
        /* Handled seperately in order to avoid an unneeded key fetch */
        if (h->used != 1) croak("Assertion: negative sized heap");
        if (h->max_count < 1) return;
        if (h->allocated <= 1) extend(h, 1);
        if (h->wrapped) {
            if (!key) {
                if (MAGIC && SvGMAGICAL(value)) {
                    value = MORTALCOPY(value);
                    val_copied = 1;
                }
                key = fetch_key(aTHX_ h, value);
            }
            /* newSVsv does get magic */
            h->keys[1] = newSVsv(key);
        }
        h->values[1] = val_copied ? SvREFCNT_inc(value) : newSVsv(value);
        h->used = 2;
        return;
    }

    /* We are certain we will need the key now. Fetch it. */
    if (!key) {
        if (MAGIC && SvGMAGICAL(value)) {
            value = MORTALCOPY(value);
            val_copied = 1;
        }
        key = fetch_key(aTHX_ h, value);
    }
    if (MAGIC && SvGMAGICAL(key)) {
        key = MORTALCOPY(key);
        key_copied = 1;
    } else key_copied = 0;

    if (h->used > h->max_count) {
        SV *key1, *key2;
        if (!less(aTHX_ h, KEY(h, 1), key)) return;
        /* Drop the old top and percolate the new value down */
        /* This is almost completely identical to extract_top, but
           I don't see a clean way to factor it out that preserves
           resistance agains exceptions in less/fetch_key */

        n = h->used-1;
        l = 2;

        while (l < n) {
            key1 = KEY(h, l);
            if (MAGIC && SvGMAGICAL(key1)) key1 = MORTALCOPY(key1);
            key2 = KEY(h, l+1);
            if (less(aTHX_ h, key1, key)) {
                if (less(aTHX_  h, key2, key1)) l++;
            } else if (less(aTHX_ h, key2, key)) l++;
            else break;
            l *= 2;
        }
        if (l == n) {
            key1 = KEY(h, l);
            if (less(aTHX_ h, key1, key)) l*= 2;
        }
        l /= 2;

        t1 = val_copied ? SvREFCNT_inc(value) : newSVsv(value);
        if (h->wrapped) {
            /* Assume newSVsv can't die since key will already have been
               (mortal)copied in case it's magic */
            key1 = key_copied ? SvREFCNT_inc(key) : newSVsv(key);
            while (l >= 1) {
                key2 = h->keys[l];
                t2   = h->values[l];
                h->keys[l] = key1;
                h->values[l] = t1;
                key1 = key2;
                t1 = t2;
                l /= 2;
            }
            SvREFCNT_dec(key1);
        } else {
            while (l >= 1) {
                t2 = h->values[l];
                h->values[l] = t1;
                t1 = t2;
                l /= 2;
            }
        }
        SvREFCNT_dec(t1);
        return;
    }
    pos = h->used;

    while (pos > 1 && less(aTHX_ h, key, KEY(h, pos/2))) pos /= 2;
    if (h->used >= h->allocated) extend(h, 1);
    new = val_copied ? SvREFCNT_inc(value) : newSVsv(value);
    if (h->wrapped) {
        /* Assume newSVsv can't die since key will already have been
           (mortal)copied in case it's magic */
        key = key_copied ? SvREFCNT_inc(key) : newSVsv(key);
        for (p=h->used; p != pos; p/=2) {
            h->keys[p]   = h->keys[p/2];
            h->values[p] = h->values[p/2];
        }
        h->keys[pos] = key;
    } else {
        for (p=h->used; p != pos; p/=2) h->values[p] = h->values[p/2];
    }
    h->values[pos] = new;
    h->used++;
}

static void multi_insert(pTHX_ heap h, size_t first) {
    size_t i;
    SV *value;

    /* Shut up warnings */
    value = NULL;

    if (h->fast) {
        NV k, key1, key2;
        size_t n, l;

        n = h->used-1;
        for (i = n/2; i>= first; i--) {
            if (h->has_values) value = h->values[i];
            k = FKEY(NV, h, i);
            l = i*2;
            while (l < n) {
                key1 = FKEY(NV, h, l);
                key2 = FKEY(NV, h, l+1);
                if (key1 < k) {
                    if (key2 < key1) {
                        FKEY(NV, h, l/2) = key2;
                        l++;
                    } else {
                        FKEY(NV, h, l/2) = key1;
                    }
                } else if (key2 < k) {
                    FKEY(NV, h, l/2) = key2;
                    l++;
                } else break;
                if (h->has_values) h->values[l/2] = h->values[l];
                l *= 2;
            }
            if (l == n) {
                key1 = FKEY(NV, h, l);
                if (key1 < k) {
                    FKEY(NV, h, l/2) = key1;
                    if (h->has_values) h->values[l/2] = h->values[l];
                    l*= 2;
                }
            }
            l /= 2;
            if (h->has_values) h->values[l] = value;
            FKEY(NV, h, l) = k;
        }
        /* i is now points to the highest numbered old entry that needs to
           be percolated */
        first /= 2;
        if (first < 1) first = 1;
        /* the range [first..i] MUST be percolated */
        if (i >= first) {
            size_t *todo, *old_to, *new_to, *here;
            New(__LINE__ % 1000, todo, i-first+2, size_t);
            new_to = todo;
            todo++;
            while (i >= first) *++new_to = i--;

            while (new_to >= todo) {
                old_to = new_to;
                new_to = todo-1;
                *new_to = *old_to;
                for (here = todo; here <= old_to; here++) {
                    i = *here;
                    if (h->has_values) value = h->values[i];
                    k = FKEY(NV, h, i);
                    l = i*2;
                    while (l < n) {
                        key1 = FKEY(NV, h, l);
                        key2 = FKEY(NV, h, l+1);
                        if (key1 < k) {
                            if (key2 < key1) {
                                FKEY(NV, h, l/2) = key2;
                                l++;
                            } else {
                                FKEY(NV, h, l/2) = key1;
                            }
                        } else if (key2 < k) {
                            FKEY(NV, h, l/2) = key2;
                            l++;
                        } else break;
                        if (h->has_values) h->values[l/2] = h->values[l];
                        l *= 2;
                    }
                    if (l == n) {
                        key1 = FKEY(NV, h, l);
                        if (key1 < k) {
                            FKEY(NV, h, l/2) = key1;
                            if (h->has_values) h->values[l/2] = h->values[l];
                            l*= 2;
                        }
                    }
                    l /= 2;
                    if (h->has_values) h->values[l] = value;
                    FKEY(NV, h, l) = k;
                    /* Did entry i change ? */
                    if (l != i && i/2 < *new_to && i >= 2) *++new_to = i/2;
                }
            }
            todo--;
            Safefree(todo);
        }
    } else {
        SV *k, *key1, *key2;
        size_t n, l;

        n = h->used-1;
        for (i = n/2; i>= first; i--) {
            k = KEY(h, i);
            value = h->values[i];
            l = i*2;
            while (l < n) {
                key1 = KEY(h, l);
                key2 = KEY(h, l+1);
                if (less(aTHX_ h, key1, k)) {
                    if (less(aTHX_ h, key2, key1)) {
                        if (h->wrapped) h->keys[l/2] = key2;
                        l++;
                    } else {
                        if (h->wrapped) h->keys[l/2] = key1;
                    }
                } else if (less(aTHX_ h, key2, k)) {
                    if (h->wrapped) h->keys[l/2] = key2;
                    l++;
                } else break;
                h->values[l/2] = h->values[l];
                l *= 2;
            }
            if (l == n) {
                key1 = KEY(h, l);
                if (less(aTHX_ h, key1, k)) {
                    if (h->wrapped) h->keys[l/2] = key1;
                    h->values[l/2] = h->values[l];
                    l*= 2;
                }
            }
            l /= 2;
            h->values[l] = value;
            if (h->wrapped) h->keys[l] = k;
        }
        /* i is now points to the highest numbered old entry that needs to
           be percolated */
        first /= 2;
        if (first < 1) first = 1;
        /* the range [first..i] MUST be percolated */
        if (i >= first) {
            size_t *todo, *old_to, *new_to, *here;
            New(__LINE__ % 1000, todo, i-first+2, size_t);
            SAVEFREEPV(todo);
            new_to = todo;
            todo++;
            while (i >= first) *++new_to = i--;

            while (new_to >= todo) {
                old_to = new_to;
                new_to = todo-1;
                *new_to = *old_to;
                for (here = todo; here <= old_to; here++) {
                    i = *here;
                    value = h->values[i];
                    k = KEY(h, i);
                    l = i*2;
                    while (l < n) {
                        key1 = KEY(h, l);
                        key2 = KEY(h, l+1);
                        if (less(aTHX_ h, key1, k)) {
                            if (less(aTHX_ h, key2, key1)) {
                                if (h->wrapped) h->keys[l/2] = key2;
                                l++;
                            } else {
                                if (h->wrapped) h->keys[l/2] = key1;
                            }
                        } else if (less(aTHX_ h, key2, k)) {
                            if (h->wrapped) h->keys[l/2] = key2;
                            l++;
                        } else break;
                        h->values[l/2] = h->values[l];
                        l *= 2;
                    }
                    if (l == n) {
                        key1 = KEY(h, l);
                        if (less(aTHX_ h, key1, k)) {
                            if (h->wrapped) h->keys[l/2] = key1;
                            h->values[l/2] = h->values[l];
                            l*= 2;
                        }
                    }
                    l /= 2;
                    h->values[l] = value;
                    if (h->wrapped) h->keys[l] = k;
                    /* Did entry i change ? */
                    if (l != i && i/2 < *new_to && i >= 2) *++new_to = i/2;
                }
            }
        }
    }
}

/* Returns the top value with the refcount still increased
   Only to be called if there is at least element, so with h->used >= 2
   The non-fast version uses the stack, so wrap in PUTBACK/SPAGAIN ! */
static SV *extract_top(pTHX_ heap h) {
    SV *t1, *t2;
    size_t l, n;

    n = h->used-2;
    l = 2;

    if (h->fast) {
        NV key, key1, key2;

        key = FKEY(NV, h, --h->used);
        if (h->has_values) t1 = h->values[1];
        else if (h->order == LESS) t1 = newSVnv( FKEY(NV, h, 1));
        else if (h->order == MORE) t1 = newSVnv(-FKEY(NV, h, 1));
        else croak("No fast %s order", order_name(h));

        while (l < n) {
            key1 = FKEY(NV, h, l);
            key2 = FKEY(NV, h, l+1);
            if (key1 < key) {
                if (key2 < key1) {
                    FKEY(NV, h, l/2) = key2;
                    l++;
                } else {
                    FKEY(NV, h, l/2) = key1;
                }
            } else if (key2 < key) {
                FKEY(NV, h, l/2) = key2;
                l++;
            } else break;
            if (h->has_values) h->values[l/2] = h->values[l];
            l *= 2;
        }
        if (l == n) {
            key1 = FKEY(NV, h, l);
            if (key1 < key) {
                FKEY(NV, h, l/2) = key1;
                if (h->has_values) h->values[l/2] = h->values[l];
                l*= 2;
            }
        }
        l /= 2;
        FKEY(NV, h, l) = key;
        if (h->has_values) h->values[l] = h->values[h->used];
    } else {
        SV *key, *key1, *key2;

        key = KEY(h, h->used-1);
        while (l < n) {
            key1 = KEY(h, l);
            if (MAGIC && SvGMAGICAL(key1)) key1 = MORTALCOPY(key1);
            key2 = KEY(h, l+1);
            if (less(aTHX_ h, key1, key)) {
                if (less(aTHX_  h, key2, key1)) l++;
            } else if (less(aTHX_ h, key2, key)) l++;
            else break;
            l *= 2;
        }
        if (l == n) {
            key1 = KEY(h, l);
            if (less(aTHX_ h, key1, key)) l*= 2;
        }
        l /= 2;

        t1 = h->values[--h->used];
        if (h->wrapped) {
            key1 = h->keys[h->used];
            while (l >= 1) {
                key2 = h->keys[l];
                t2 = h->values[l];
                h->keys[l] = key1;
                h->values[l] = t1;
                key1 = key2;
                t1 = t2;
                l /= 2;
            }
            SvREFCNT_dec(key1);
        } else {
            while (l >= 1) {
                t2 = h->values[l];
                h->values[l] = t1;
                t1 = t2;
                l /= 2;
            }
        }
    }
    return t1;
}

static void reverse(heap h, size_t bottom, size_t top) {
    while (top > bottom) {
        SV *value, *key;

        if (h->has_values) {
            value = h->values[top];
            h->values[top] = h->values[bottom];
            h->values[bottom] = value;
        }

        if (h->fast) {
            NV k;
            k = FKEY(NV, h, top);
            FKEY(NV, h, top) = FKEY(NV, h, bottom);
            FKEY(NV, h, bottom) = k;
        } else if (h->wrapped) {
            key = h->keys[top];
            h->keys[top] = h->keys[bottom];
            h->keys[bottom] = key;
        }

        top--;
        bottom++;
    }
}

static void option(pTHX_ heap h, SV *tag, SV *value) {
    STRLEN len;
    /* SvPV does magic fetch */
    char *name = SvPV(tag, len);
    if (len >= 5) switch(name[0]) {
      case 'c':
        if (len == 7 && strEQ(name, "can_die")) {
            /* SvTRUE does mg_get (through sv_2bool) */
            h->can_die = SvTRUE(value);
            return;
        }
        break;
      case 'd':
        if (len == 5 && strEQ(name, "dirty")) {
            if (h->dirty) croak("Multiple dirty options");
            /* SvTRUE does mg_get (through sv_2bool) */
            h->dirty = SvTRUE(value) ? 1 : -1;
            return;
        }
        break;
      case 'e':
        if (len == 8 && strEQ(name, "elements")) {
            if (h->elements) croak("Multiple elements options");
            if (MAGIC) SvGETMAGIC(value);
            if (SvROK(value)) {
                /* Some sort of reference */
                AV *av;
                SV **fetched;

                av = (AV*) SvRV(value);
                if (SvTYPE(av) != SVt_PVAV)
                    croak("option elements is not an array reference");
                fetched = av_fetch(av, 0, 0);
                /* SvPV will do get magic */
                if (fetched) name = SvPV(*fetched, len);
                if (!fetched || !SvOK(*fetched))
                    croak("option elements has no type defined at index 0");
                if ((len == 6 && low_eq(name, "scalar")) ||
                    (len == 3 && low_eq(name, "key"))) {
                    if (av_len(av) > 0)
                        warn("Extra arguments to Scalar ignored");
                    h->elements = SCALAR;
                } else if (len == 5 && low_eq(name, "array")) {
                    h->elements = ARRAY;
                    if (av_len(av) > 0) {
                        SV **pindex, *index;
                        IV i;
                        if (av_len(av) > 1) warn("Extra arguments to Array ignored");
                        pindex = av_fetch(av, 1, 0);
                        /* SvIV will do get magic (through sv_2iv) */
                        index = pindex ? *pindex : &PL_sv_undef;
                        h->aindex = i = SvIV(index);
                        if (i != h->aindex)
                            croak("Index overflow of %"IVdf, i);
                    } else h->aindex = 0;
                } else if (len == 4 && low_eq(name, "hash")) {
                    SV **index;
                    h->elements = HASH;
                    if (av_len(av) < 1)
                        croak("missing key name for %"SVf, *fetched);
                    if (av_len(av) > 1)
                        warn("Extra arguments to Hash ignored");
                    index = av_fetch(av, 1, 0);
                    if (h->hkey)
                        croak("Assertion: already have a hash key");
                    /* newSVsv will do get magic */
                    if (index) h->hkey = newSVsv(*index);
                    if (!index || !SvOK(*index))
                        croak("missing key name for %"SVf, *fetched);
                    h->aindex = 0;
                } else if (len == 6 && (low_eq(name, "method") ||
                                        low_eq(name, "object"))) {
                    SV **index;
                    if (toLOWER(name[0]) == 'm') {
                        h->elements = METHOD;
                        if (av_len(av) < 1)
                            croak("missing key method for %"SVf, *fetched);
                    } else {
                        h->elements = OBJECT;
                        h->wrapped  = 1;
                        if (av_len(av) < 1) return;
                    }
                    if (av_len(av) > 1)
                        warn("Extra arguments to %"SVf" ignored", *fetched);
                    index = av_fetch(av, 1, 0);
                    if (h->hkey)
                        croak("Assertion: already have a method name");
                    /* newSVsv will do get magic */
                    if (index) h->hkey = newSVsv(*index);
                    if (!index || !SvOK(*index))
                        croak("missing key method for %"SVf, *fetched);
                } else if ((len == 8 && low_eq(name, "function")) ||
                           (len == 3 && low_eq(name, "any"))) {
                    SV **index;
                    if (toLOWER(name[0]) == 'f') {
                        h->elements = FUNCTION;
                        if (av_len(av) < 1)
                            croak("missing key function for %"SVf, *fetched);
                    } else {
                        h->elements = ANY_ELEM;
                        h->wrapped  = 1;
                        if (av_len(av) < 1) return;
                    }
                    if (av_len(av) > 1)
                        warn("Extra arguments to %"SVf" ignored", *fetched);
                    index = av_fetch(av, 1, 0);
                    if (h->hkey)
                        croak("Assertion: already have a key function");
                    /* Don't check if it's actually a code ref.
                       Allow unstrict name based call, or garbage that
                       never gets used */
                    /* newSVsv will do get magic */
                    if (index) h->hkey = newSVsv(*index);
                    if (!index || !SvOK(*index))
                        croak("missing key function for %"SVf, *fetched);
                } else croak("Unknown element type '%"SVf"'", *fetched);
            } else {
                name = SvPV(value, len);
                if      ((len == 6 && low_eq(name, "scalar")) ||
                          (len == 3 && low_eq(name, "key")))
                    h->elements = SCALAR;
                else if (len == 5 && low_eq(name, "array")) {
                    h->elements = ARRAY;
                    h->aindex = 0;
                } else if (len == 6 && low_eq(name, "object")) {
                    h->elements = OBJECT;
                    h->wrapped  = 1;
                } else if (len == 3 && low_eq(name, "any")) {
                    h->elements = ANY_ELEM;
                    h->wrapped  = 1;
                } else if (len == 4 && low_eq(name, "hash"))
                    croak("missing key name for %"SVf, value);
                else if(len == 6 && low_eq(name, "method"))
                    croak("missing key method for %"SVf, value);
                else if (len == 8 && low_eq(name, "function"))
                    croak("missing key function for %"SVf, value);
                else croak("Unknown element type '%"SVf"'", value);
            }
            return;
        }
        break;
      case 'i':
        if (len == 8 && strEQ(name, "infinity")) {
            if (h->infinity) croak("Multiple infinity options");
            h->infinity = newSVsv(value);
            return;
        }
        break;
      case 'm':
        if (len == 9 && strEQ(name, "max_count")) {
            NV max_count;
            size_t m;
            if (h->max_count != MAX_SIZE) croak("Multiple max_count options");
            max_count = SvNV(value);
            if (max_count < 0) croak("max_count should not be negative");
            if (max_count == INFINITY) return;
            if (max_count >= MAX_SIZE)
                croak("max_count too big. Use infinity instead");
            m = (size_t) max_count;
            if (m != max_count) croak("max_count should be an integer");
            h->max_count = m;
            return;
        }
        break;
      case 'o':
        if (len == 5 && strEQ(name, "order")) {
            if (h->order) croak("Multiple order options");
            /* SvPV does get magic */
            name = SvPV(value, len);
            if (SvROK(value)) {
                /* Some sort of reference */
                SV *cv = SvRV(value);
                if (SvTYPE(cv) != SVt_PVCV)
                    croak("order value is a reference but not a code reference");
                h->order = CODE_ORDER;
                h->order_sv = newRV_inc(cv);
                return;
            }
            if      (len == 1 && name[0] == '<') h->order = LESS;
            else if (len == 1 && name[0] == '>') h->order = MORE;
            else if (len == 2 && low_eq(name, "lt")) h->order = LT;
            else if (len == 2 && low_eq(name, "gt")) h->order = GT;
            else croak("Unknown order '%"SVf"'", value);
            return;
        }
        break;
      case 'u':
        if (len == 9 && strEQ(name, "user_data")) {
            if (h->user_data) croak("Multiple user_data options");
            h->user_data = newSVsv(value);
            return;
        }
        break;
    }
    croak("Unknown option '%"SVf"'", tag);
}

MODULE = Heap::Simple::XS		PACKAGE = Heap::Simple::XS
PROTOTYPES: ENABLE

SV *
new(char *class, ...)
  PREINIT:
    heap h;
    I32 i;
  CODE:
    if (items % 2 == 0) croak("Odd number of elements in options");
    New(__LINE__, h, 1, struct heap);
    h->keys = h->values = NULL;
    h->hkey = h->infinity = h->user_data = h->order_sv = NULL;
    h->allocated = 0;
    h->used = 1;
    h->wrapped = 0;
    h->order = 0;
    h->elements = 0;
    h->fast = 0;
    h->has_values = 1;
    h->can_die = 0;
    h->max_count = -1;
    h->dirty = 0;
    h->locked = 0;
    RETVAL = sv_newmortal();
    sv_setref_pv(RETVAL, class, (void*) h);

    for (i=1; i<items; i+=2) option(aTHX_ h, ST(i), ST(i+1));

    if (!h->order) h->order = LESS;
    if (!h->infinity) switch(h->order) {
      case LESS: h->infinity = newSVnv( INFINITY); break;
      case MORE: h->infinity = newSVnv(-INFINITY); break;
      case GT:   h->infinity = newSVpvn("", 0);         break;
      case LT: case CODE_ORDER: break;
      default:
        croak("Assertion: No infinity handler for order '%s'",
              order_name(h));
    }
    if (!h->elements) h->elements = SCALAR;
    if (h->dirty < 0) h->dirty = 0;

    /* FUNCTION and METHOD are excluded for the simple reason that if you want
       caching with them, you could use Any and Object instead */
    if (h->dirty && (h->order == LESS || h->order == MORE) &&
        (h->elements != FUNCTION && h->elements != METHOD)) h->fast = 1;
    if (h->fast && h->order != LESS && h->order != MORE)
        croak("No fast %s order", order_name(h));
    if (h->fast && h->elements == SCALAR) h->has_values = 0;
    h->key_ops = h->wrapped || (h->fast && h->has_values);
    /* Can't happen, but let's just make sure */
    if (h->wrapped && !h->has_values)
        croak("Assertion: wrapped but no has_values");
    SvREFCNT_inc(RETVAL);
  OUTPUT:
    RETVAL

UV
count(heap h)
  CODE:
    RETVAL = h->used-1;
  OUTPUT:
    RETVAL

void
insert(heap h, ...)
  PREINIT:
    I32 i, more;
    SV *key, *value;
    size_t first;
  CODE:
    if (h->locked) croak("recursive heap change");
    SAVEINT(h->locked);
    h->locked = 1;
    PUTBACK;
    i = 1;
    more = h->used-1+items-1 > h->max_count ?
	h->max_count-(h->used-1) : items-1;
    if (more > 1 && !h->can_die) {
        if (h->used+more > h->allocated) extend(h, more);
        first = h->used;
        if (h->fast) {
            NV k;

            for (; i<more; i++) {
                int val_copied;

                value = ST(i);
                if (MAGIC && SvGMAGICAL(value)) {
                    value = MORTALCOPY(value);
                    val_copied = 1;
                } else val_copied = 0;

                key = fetch_key(aTHX_ h, value);
                /* SvNV will handle get magic (though sv_2nv) */
                if      (h->order == LESS) k =  SvNV(key);
                else if (h->order == MORE) k = -SvNV(key);
                else croak("No fast %s order", order_name(h));

                FKEY(NV, h, h->used) = k;
                if (h->has_values)
                    h->values[h->used] = val_copied ?
                        SvREFCNT_inc(value) : newSVsv(value);
                h->used++;
            }
        } else {
            for (; i<more; i++) {
                value = ST(i);
                if (h->wrapped) {
                    int val_copied, key_copied;

                    if (MAGIC && SvGMAGICAL(value)) {
                        value = MORTALCOPY(value);
                        val_copied = 1;
                    } else val_copied = 0;

                    key = fetch_key(aTHX_ h, value);
                    if (MAGIC && SvGMAGICAL(key)) {
                        key = MORTALCOPY(key);
                        key_copied = 1;
                    } else key_copied = 0;
                    h->values[h->used] =
                        val_copied ? SvREFCNT_inc(value) : newSVsv(value);
                    /* Assume newSVsv can't die since key will already
                       have been (mortal)copied in case it's magic */
                    h->keys[h->used] = key_copied ?
                        SvREFCNT_inc(key) : newSVsv(key);
                } else h->values[h->used] = newSVsv(value);

                h->used++;
            }
        }
        multi_insert(aTHX_ h, first);
    }
    for (; i<items; i++) key_insert(aTHX_ h, NULL, ST(i));
    XSRETURN_EMPTY;

void
key_insert(heap h, ...)
  PREINIT:
    I32 i, more;
    SV *key, *value;
    size_t first;
  CODE:
    if (!h->key_ops) croak("This heap type does not support key_insert");
    if (items % 2 == 0) croak("Odd number of arguments");
    if (h->locked) croak("recursive heap change");
    SAVEINT(h->locked);
    h->locked = 1;
    PUTBACK;

    i = 1;
    more = h->used-1+items/2 > h->max_count ?
	h->max_count-(h->used-1) : items/2;
    if (more > 1 && !h->can_die) {
        if (h->used+more > h->allocated) extend(h, more);
        more = 2*more+1;
        first = h->used;
        if (h->fast) {
            NV k;

            for (; i<more; i+=2) {
                int val_copied;

                value = ST(i+1);

                if (MAGIC && SvGMAGICAL(value)) {
                    value = MORTALCOPY(value);
                    val_copied = 1;
                } else val_copied = 0;

                key = ST(i);
                /* SvNV will handle get magic (though sv_2nv) */
                if      (h->order == LESS) k =  SvNV(key);
                else if (h->order == MORE) k = -SvNV(key);
                else croak("No fast %s order", order_name(h));

                FKEY(NV, h, h->used) = k;
                if (h->has_values)
                    h->values[h->used] = val_copied ?
                        SvREFCNT_inc(value) : newSVsv(value);
                h->used++;
            }
        } else {
            if (!h->wrapped) croak("Assertion: slow non-wrapped key_ops");
            for (; i<more; i+=2) {
                int val_copied, key_copied;

                value = ST(i+1);

                if (MAGIC && SvGMAGICAL(value)) {
                    value = MORTALCOPY(value);
                    val_copied = 1;
                } else val_copied = 0;

                key = ST(i);
                if (MAGIC && SvGMAGICAL(key)) {
                    key = MORTALCOPY(key);
                    key_copied = 1;
                } else key_copied = 0;
                h->values[h->used] = val_copied ?
                    SvREFCNT_inc(value) : newSVsv(value);
                /* Assume newSVsv can't die since key will already
                   have been (mortal)copied in case it's magic */
                h->keys[h->used] = key_copied ?
                    SvREFCNT_inc(key) : newSVsv(key);

                h->used++;
            }
        }
        multi_insert(aTHX_ h, first);
    }
    for (; i<items; i+=2) key_insert(aTHX_ h, ST(i), ST(i+1));
    XSRETURN_EMPTY;

void
_key_insert(heap h, ...)
  PREINIT:
    AV *av;
    SV *key, *value, **key_ref, **val_ref, *pair;
    I32 i, more;
    size_t first;
  CODE:
    if (!h->key_ops) croak("This heap type does not support _key_insert");
    if (h->locked) croak("recursive heap change");
    SAVEINT(h->locked);
    h->locked = 1;
    PUTBACK;
    i = 1;
    more = h->used-1+items-1 > h->max_count ?
	h->max_count-(h->used-1) : items-1;
    if (more > 1 && !h->can_die) {
        if (h->used+more > h->allocated) extend(h, more);
        first = h->used;
        if (!h->fast && !h->wrapped)
            croak("Assertion: slow non-wrapped key_ops");
        for (; i<more; i++) {
            pair = ST(i);
            if (MAGIC) SvGETMAGIC(pair);
            if (!SvROK(pair)) croak("pair is not a reference");
            av = (AV*) SvRV(pair);
            if (SvTYPE(av) != SVt_PVAV) croak("pair is not an ARRAY reference");
            key_ref = av_fetch(av, 0, 0);
            if (!key_ref) croak("No key in the element array");
            key = *key_ref;
            val_ref = av_fetch(av, 1, 0);
            if (!val_ref) croak("No value in the element array");
            value = *val_ref;

            if (h->fast) {
                NV k;
                int val_copied;

                if (MAGIC && SvGMAGICAL(value)) {
                    value = MORTALCOPY(value);
                    val_copied = 1;
                } else val_copied = 0;

                /* SvNV will handle get magic (though sv_2nv) */
                if      (h->order == LESS) k =  SvNV(key);
                else if (h->order == MORE) k = -SvNV(key);
                else croak("No fast %s order", order_name(h));

                FKEY(NV, h, h->used) = k;
                if (h->has_values)
                    h->values[h->used] =
                        val_copied ? SvREFCNT_inc(value) : newSVsv(value);
            } else {
                int val_copied, key_copied;

                if (MAGIC && SvGMAGICAL(value)) {
                    value = MORTALCOPY(value);
                    val_copied = 1;
                } else val_copied = 0;

                if (MAGIC && SvGMAGICAL(key)) {
                    key = MORTALCOPY(key);
                    key_copied = 1;
                } else key_copied = 0;
                h->values[h->used] =
                    val_copied ? SvREFCNT_inc(value) : newSVsv(value);
                /* Assume newSVsv can't die since key will already
                   have been (mortal)copied in case it's magic */
                h->keys[h->used] = key_copied ?
                    SvREFCNT_inc(key) : newSVsv(key);
            }
            h->used++;
        }
        multi_insert(aTHX_ h, first);
    }
    for (; i<items; i++) {
        pair = ST(i);
        if (MAGIC) SvGETMAGIC(pair);
        if (!SvROK(pair)) croak("pair is not a reference");
        av = (AV*) SvRV(pair);
        if (SvTYPE(av) != SVt_PVAV) croak("pair is not an ARRAY reference");
        key_ref = av_fetch(av, 0, 0);
        if (!key_ref) croak("No key in the element array");
        val_ref = av_fetch(av, 1, 0);
        if (!val_ref) croak("No value in the element array");

        key_insert(aTHX_ h, *key_ref, *val_ref);
    }
    XSRETURN_EMPTY;

void
extract_top(heap h)
  ALIAS:
    Heap::Simple::XS::extract_min   = 1
    Heap::Simple::XS::extract_first = 2
  PPCODE:
    if (h->used <= 2) {
        if (h->used < 2) {
            if (ix != 2) croak("Empty heap");
            XSRETURN_EMPTY;
        }
        if (h->locked) croak("recursive heap change");
        SAVEINT(h->locked);
        h->locked = 1;
        --h->used;
        if (h->wrapped && !h->fast) SvREFCNT_dec(h->keys[h->used]);
        if (h->has_values) PUSHs(sv_2mortal(h->values[h->used]));
        else if (h->order == LESS) XSRETURN_NV( FKEY(NV, h, 1));
        else if (h->order == MORE) XSRETURN_NV(-FKEY(NV, h, 1));
        else croak("No fast %s order", order_name(h));
    } else {
        PUTBACK;
        if (h->locked) croak("recursive heap change");
        SAVEINT(h->locked);
        h->locked = 1;
        PUSHs(sv_2mortal(extract_top(aTHX_ h)));
    }

void
extract_upto(heap h, SV *border)
  PPCODE:
    /* special case, avoid uneeded access to border */
    if (h->used < 2) return;
    if (h->locked) croak("recursive heap change");
    SAVEINT(h->locked);
    h->locked = 1;
    if (h->fast) {
        NV b;
        if      (h->order == LESS) b =  SvNV(border);
        else if (h->order == MORE) b = -SvNV(border);
        else croak("No fast %s order", order_name(h));
        while (FKEY(NV, h, 1) <= b) {
            /* No PUTBACK/SPAGAIN needed since fast extract top
               won't change the stack */
            XPUSHs(sv_2mortal(extract_top(aTHX_ h)));
            if (h->used < 2) break;
        }
    } else {
        if (MAGIC && SvGMAGICAL(border)) border = MORTALCOPY(border);
        while (1) {
            SV *top;

            PUTBACK;
            if (less(aTHX_ h, border, KEY(h, 1))) {
                SPAGAIN;
                break;
            }
            top = extract_top(aTHX_ h);
            SPAGAIN;
            XPUSHs(sv_2mortal(top));
            if (h->used < 2) break;
        }
    }
    if ((h->used+4)*4 < h->allocated) extend(h, 0); /* shrink really */

void
extract_all(heap h)
  PPCODE:
    if (h->locked) croak("recursive heap change");
    SAVEINT(h->locked);
    h->locked = 1;
    /* Extends one too much. Who cares... */
    EXTEND(SP, h->used);
    EXTEND_MORTAL(h->used);
    if (h->fast) {
        /* No PUTBACK/SPAGAIN needed since fast extract top
           won't change the stack */
        while (h->used > 1) XPUSHs(sv_2mortal(extract_top(aTHX_ h)));
    } else while (h->used > 1) {
        SV *top;

        PUTBACK;
        top = extract_top(aTHX_ h);
        SPAGAIN;
        XPUSHs(sv_2mortal(top));
    }
    if ((1+4)*4 < h->allocated) extend(h, 0); /* shrink really */

void
top(heap h)
  ALIAS:
    Heap::Simple::XS::first = 1
  PPCODE:
    if (h->used < 2) {
        if (ix != 1) croak("Empty heap");
        XSRETURN_EMPTY;
    }
    if (h->has_values) PUSHs(sv_2mortal(SvREFCNT_inc(h->values[1])));
    else if (h->order == LESS) XSRETURN_NV( FKEY(NV, h, 1));
    else if (h->order == MORE) XSRETURN_NV(-FKEY(NV, h, 1));
    else croak("No fast %s order", order_name(h));

void
top_key(heap h)
  ALIAS:
    Heap::Simple::XS::min_key   = 1
    Heap::Simple::XS::first_key = 2
  PPCODE:
    if (h->used < 2) {
        if (ix == 2) XSRETURN_EMPTY;
        if (!h->infinity || !SvOK(h->infinity)) croak("Empty heap");
        PUSHs(sv_2mortal(SvREFCNT_inc(h->infinity)));
    } else if (h->fast) {
        if      (h->order== LESS) XSRETURN_NV( FKEY(NV, h, 1));
        else if (h->order== MORE) XSRETURN_NV(-FKEY(NV, h, 1));
        else croak("No fast %s order", order_name(h));
    } else PUSHs(sv_2mortal(SvREFCNT_inc(KEY(h, 1))));

void
keys(heap h)
  PREINIT:
    /* you can actally modify the values through the return */
    size_t i;
    SV *key;
  PPCODE:
    /* Extends one too much. Who cares... */
    EXTEND(SP, h->used);
    EXTEND_MORTAL(h->used);
    if (h->fast) {
        if      (h->order == LESS) for (i=1; i<h->used; i++)
            PUSHs(sv_2mortal(newSVnv( FKEY(NV, h, i))));
        else if (h->order == MORE) for (i=1; i<h->used; i++)
            PUSHs(sv_2mortal(newSVnv(-FKEY(NV, h, i))));
        else croak("No fast %s order", order_name(h));
    } else {
        for (i=1; i<h->used; i++) {
            PUTBACK;
            key = KEY(h, i);
            SPAGAIN;
            PUSHs(sv_2mortal(SvREFCNT_inc(key)));
        }
    }

void
values(heap h)
  PREINIT:
    /* you can actally modify the values through the return */
    size_t i;
  PPCODE:
    /* Extends one too much. Who cares... */
    EXTEND(SP, h->used);
    EXTEND_MORTAL(h->used);
    if (h->has_values) for (i=1; i<h->used; i++)
        PUSHs(sv_2mortal(SvREFCNT_inc(h->values[i])));
    else if (h->order == LESS) for (i=1; i<h->used; i++)
        PUSHs(sv_2mortal(newSVnv( FKEY(NV, h, i))));
    else if (h->order == MORE) for (i=1; i<h->used; i++)
        PUSHs(sv_2mortal(newSVnv(-FKEY(NV, h, i))));
    else croak("No fast %s order", order_name(h));

void
clear(heap h)
  PREINIT:
    SV *key, *value;
  PPCODE:
    if (h->locked) croak("recursive heap change");
    SAVEINT(h->locked);
    h->locked = 1;
    if (h->fast || !h->wrapped) {
        if (h->has_values)
            while (h->used > 1) SvREFCNT_dec(h->values[--h->used]);
        else h->used = 1;
    } else {
        while (h->used > 1) {
            --h->used;
            value = h->values[h->used];
            key   = h->keys  [h->used];
            SvREFCNT_dec(key);
            SvREFCNT_dec(value);
        }
    }
    if ((1+4)*4 < h->allocated) extend(h, 0); /* shrink really */

SV *
key(heap h, SV *value)
  CODE:
    if (h->fast) {
        RETVAL = newSVnv(SvNV(fetch_key(aTHX_ h, value)));
    } else {
        RETVAL = SvREFCNT_inc(fetch_key(aTHX_ h, value));
    }

  OUTPUT:
    RETVAL

void
_absorb(SV * heap1, SV *heap2)
  PREINIT:
    int copied2, one_by_one;
    SV *heap1_ref, *value;
    heap h1, h2;
  PPCODE:
    /* Helper for absorb, puts h1 into h2 */
    h1 = C_HEAP(heap1, "heap1");
    /* Keep argument alive for the duration */
    heap1_ref = SvRV(heap1);
    sv_2mortal(SvREFCNT_inc(heap1_ref));
    if (h1->locked) croak("recursive heap change");
    SAVEINT(h1->locked);
    h1->locked = 1;

    if (h1->used < 2) XSRETURN_EMPTY;

    if (MAGIC && SvMAGICAL(heap2)) {
        heap2 = MORTALCOPY(heap2);
        copied2 = 1;
    } else copied2 = 0;
    /* If we are an XS heap, the argument (h2) probably is too */
    h2 = TRY_C_HEAP(heap2);
    if (h2) {
        size_t more, first;

        if (h1 == h2) croak("Self absorption");
        PUTBACK;

        /* Keep argument alive for the duration */
        /* heap2 is now the object, not the object pointer */
        if (!copied2) sv_2mortal(SvREFCNT_inc(heap2));
        more = h1->used-1;
        if (h2->used-1+more > h2->max_count)
            more = h2->max_count-(h2->used-1);
        if (more <= 1) one_by_one = 1;
        else one_by_one = h2->can_die;
        if (!one_by_one) {
            SV *key;

            if (h2->locked) croak("recursive heap change");
            SAVEINT(h2->locked);
            h2->locked = 1;

            first = h2->used;
            if (first+more > h2->allocated) extend(h2, more);

            if (h2->fast) {
                NV k;

                while (more--) {
                    if (h1->has_values) value = h1->values[h1->used-1];
                    else if (h1->order == LESS)
                        value = newSVnv(FKEY(NV, h1, h1->used-1));
                    else if (h1->order == MORE)
                        value = newSVnv(-FKEY(NV, h1, h1->used-1));
                    else croak("No fast %s order", order_name(h1));
                    if (h2->has_values) h2->values[h2->used] = value;
                    else sv_2mortal(value);
                    h2->used++;
                    h1->used--;
                    if (h1->wrapped && !h1->fast)
                        SvREFCNT_dec(h1->keys[h1->used]);

                    key = fetch_key(aTHX_ h2, value);
                    /* SvNV will handle get magic (though sv_2nv) */
                    if      (h2->order == LESS) k =  SvNV(key);
                    else if (h2->order == MORE) k = -SvNV(key);
                    else croak("No fast %s order", order_name(h2));
                    FKEY(NV, h2, h2->used-1) = k;
                }
            } else {
                while (more--) {
                    if (h1->has_values) value = h1->values[h1->used-1];
                    else if (h1->order == LESS)
                        value = newSVnv(FKEY(NV, h1, h1->used-1));
                    else if (h1->order == MORE)
                        value = newSVnv(-FKEY(NV, h1, h1->used-1));
                    else croak("No fast %s order", order_name(h1));

                    if (h2->wrapped) {
                        if (h1->has_values) {
                            key = fetch_key(aTHX_ h2, value);
                            h2->keys[h2->used] = newSVsv(key);
                        } else {
                            sv_2mortal(value);
                            key = fetch_key(aTHX_ h2, value);
                            h2->keys[h2->used] = newSVsv(key);
                            SvREFCNT_inc(value);
                        }
                    }
                    h2->values[h2->used] = value;
                    h2->used++;
                    h1->used--;
                    if (h1->wrapped && !h1->fast)
                        SvREFCNT_dec(h1->keys[h1->used]);
                }
            }
            /* Reverse so that low elements are more likely to be on top
               Only makes sense if the orders are likely to be the same.
               It also depends on how a key is gets derived from a value,
               so we just use the order attribute as heuristic
            */
            if (h1->order == h2->order) reverse(h2, first, h2->used-1);

            h2->locked = 0;
            multi_insert(aTHX_ h2, first);
        }
        if (h1->used >= 2 && h1->fast) value = sv_newmortal();
        while (h1->used >= 2) {
            SAVETMPS;
            if (h1->has_values) value = h1->values[h1->used-1];
            else if (h1->order == LESS)
                sv_setnv(value, FKEY(NV, h1, h1->used-1));
            else if (h1->order == MORE)
                sv_setnv(value, -FKEY(NV, h1, h1->used-1));
            else croak("No fast %s order", order_name(h1));

            key_insert(aTHX_ h2, NULL, value);

            h1->used--;
            if (h1->has_values) SvREFCNT_dec(value);
            if (h1->wrapped && !h1->fast) SvREFCNT_dec(h1->keys[h1->used]);
            if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
            FREETMPS;
        }
    } else if (!SvOK(heap2)) croak("heap2 is undefined");
    else if (!sv_isobject(heap2)) croak("heap2 is not an object reference");
    else {
        I32 count;

        /* Simple way to keep the refcount up at both levels */
        if (!copied2) heap2 = MORTALCOPY(heap2);
        if (h1->used <= 2) one_by_one = 1;
        else {
            PUSHMARK(SP);
            PUSHs(heap2);
            PUTBACK;
            count = call_method("can_die", G_SCALAR);
            if (count != 1) croak("Forced scalar context call succeeded in returning %d values. This is impossible", (int) count);
            SPAGAIN;
            value = POPs;
            one_by_one = SvTRUE(value);
        }
        if (one_by_one) {
            ENTER;
            if (h1->fast) value = sv_newmortal();
            while (h1->used >= 2) {
                SAVETMPS;
                if (h1->has_values) value = h1->values[h1->used-1];
                else if (h1->order == LESS)
                    sv_setnv(value,  FKEY(NV, h1, h1->used-1));
                else if (h1->order == MORE)
                    sv_setnv(value, -FKEY(NV, h1, h1->used-1));
                else croak("No fast %s order", order_name(h1));
                PUSHMARK(SP);
                PUSHs(heap2);
                PUSHs(value);
                PUTBACK;

                count = call_method("insert", G_VOID);

                SPAGAIN;
                if (count) {
                    if (count < 0) croak("Forced void context call 'insert' succeeded in returning %d values. This is impossible", (int) count);
                    SP -= count;
                }
                h1->used--;
                if (h1->has_values) SvREFCNT_dec(value);
                if (h1->wrapped && !h1->fast) SvREFCNT_dec(h1->keys[h1->used]);
                if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
                FREETMPS;
            }
            LEAVE;
        } else {
            size_t i;

            EXTEND(SP, h1->used);
            if (!h1->has_values) EXTEND_MORTAL(h1->used);

            PUSHMARK(SP);
            PUSHs(heap2);
            for (i=1; i<h1->used; i++) {
                if (h1->has_values) value = h1->values[i];
                else {
                    if (h1->order == LESS)
                        value = newSVnv(FKEY(NV, h1, i));
                    else if (h1->order == MORE)
                        value = newSVnv(-FKEY(NV, h1, i));
                    else croak("No fast %s order", order_name(h1));
                    sv_2mortal(value);
                }
                PUSHs(value);
            }
            PUTBACK;
            count = call_method("insert", G_VOID);
            SPAGAIN;
            if (count) {
                if (count < 0) croak("Forced void context call 'insert' succeeded in returning %d values. This is impossible", (int) count);
                SP -= count;
            }
            while (h1->used > 1) {
                h1->used--;
                if (h1->has_values) SvREFCNT_dec(h1->values[h1->used]);
                if (h1->wrapped && !h1->fast) SvREFCNT_dec(h1->keys[h1->used]);
            }
            if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
        }
    }

void
_key_absorb(SV * heap1, SV *heap2)
  PREINIT:
    int copied2;
    SV *heap1_ref, *key, *value;
    heap h1, h2;
    int one_by_one;
  PPCODE:
    /* Helper for absorb, puts h1 into h2 */
    h1 = C_HEAP(heap1, "heap1");
    /* Keep arguments alive for the duration */
    heap1_ref = SvRV(heap1);
    sv_2mortal(SvREFCNT_inc(heap1_ref));
    if (h1->locked) croak("recursive heap change");
    SAVEINT(h1->locked);
    h1->locked = 1;

    if (h1->used < 2) XSRETURN_EMPTY;

    if (MAGIC && SvMAGICAL(heap2)) {
        heap2 = MORTALCOPY(heap2);
        copied2 = 1;
    } else copied2 = 0;
    /* If we are an XS heap, the argument probably is too */
    h2 = TRY_C_HEAP(heap2);
    if (h2) {
        size_t more, first;

        if (h1 == h2) croak("Self absorption");
        if (!h2->key_ops) croak("This heap type does not support key_insert");
        PUTBACK;

        /* Keep arguments alive for the duration */
        /* heap2 is now the object, not the object pointer */
        if (!copied2) sv_2mortal(SvREFCNT_inc(heap2));
        more = h1->used-1;
        if (h2->used-1+more > h2->max_count)
            more = h2->max_count-(h2->used-1);
        if (more <= 1) one_by_one = 1;
        else one_by_one = h2->can_die;
        if (!one_by_one) {
            SV *key;

            if (h2->locked) croak("recursive heap change");
            SAVEINT(h2->locked);
            h2->locked = 1;

            first = h2->used;
            if (first+more > h2->allocated) extend(h2, more);

            if (h2->fast) {
                NV k;

                while (more--) {
                    if (!h1->fast) k = SvNV(KEY(h1, h1->used-1));
                    else if (h1->order== LESS)
                        k = FKEY(NV, h1, h1->used-1);
                    else if (h1->order== MORE)
                        k = -FKEY(NV, h1, h1->used-1);
                    else croak("No fast %s order", order_name(h1));

                    if      (h2->order == LESS) FKEY(NV, h2, h2->used-1) =  k;
                    else if (h2->order == MORE) FKEY(NV, h2, h2->used-1) = -k;
                    else croak("No fast %s order", order_name(h2));

                    if (h2->has_values) {
                        if (h1->has_values) value = h1->values[h1->used-1];
                        else if (h1->order == LESS)
                            value = newSVnv(FKEY(NV, h1, h1->used-1));
                        else if (h1->order == MORE)
                            value = newSVnv(-FKEY(NV, h1, h1->used-1));
                        else croak("No fast %s order", order_name(h1));
                        h2->values[h2->used] = value;
                    } else if (h1->has_values)
                        SvREFCNT_dec(h1->values[h1->used-1]);

                    h2->used++;
                    h1->used--;

                    if (h1->wrapped && !h1->fast) SvREFCNT_dec(h1->keys[h1->used]);
                    if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
                }
            } else {
                while (more--) {
                    if (h1->has_values)
                        value = h1->values[h1->used-1];
                    else if (h1->order == LESS)
                        value = newSVnv(FKEY(NV, h1, h1->used-1));
                    else if (h1->order == MORE)
                        value = newSVnv(-FKEY(NV, h1, h1->used-1));
                    else croak("No fast %s order", order_name(h1));

                    if (!h1->fast) {
                        key = KEY(h1, h1->used-1);
                        if (!h1->wrapped) SvREFCNT_inc(key);
                    } else if (h1->order== LESS)
                        key = newSVnv(FKEY(NV, h1, h1->used-1));
                    else if (h1->order== MORE)
                        key = newSVnv(-FKEY(NV, h1, h1->used-1));
                    else croak("No fast %s order", order_name(h1));

                    h2->keys  [h2->used] = key;
                    h2->values[h2->used] = value;
                    h2->used++;
                    h1->used--;
                }
            }

            /* Reverse so that low elements are more likely to be on top
               Only makes sense if the orders are likely to be the same.
               It also depends on how a key is gets derived from a value,
               so we just use the order attribute as heuristic
            */
            if (h1->order == h2->order) reverse(h2, first, h2->used-1);

            h2->locked = 0;
            multi_insert(aTHX_ h2, first);
        }

        if (h1->used >= 2) {
            if (h1->fast)        key   = sv_newmortal();
            if (!h1->has_values) value = sv_newmortal();
        }
        while (h1->used >= 2) {
            SAVETMPS;
            if (h1->has_values) value = h1->values[h1->used-1];
            else if (h1->order == LESS)
                sv_setnv(value, FKEY(NV, h1, h1->used-1));
            else if (h1->order == MORE)
                sv_setnv(value, -FKEY(NV, h1, h1->used-1));
            else croak("No fast %s order", order_name(h1));

            if (!h1->fast) key = KEY(h1, h1->used-1);
            else if (h1->order== LESS)
                sv_setnv(key,  FKEY(NV, h1, h1->used-1));
            else if (h1->order== MORE)
                sv_setnv(key, -FKEY(NV, h1, h1->used-1));
            else croak("No fast %s order", order_name(h1));

            key_insert(aTHX_ h2, key, value);

            h1->used--;
            if (h1->has_values) SvREFCNT_dec(value);
            if (h1->wrapped && !h1->fast) SvREFCNT_dec(h1->keys[h1->used]);
            if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
            FREETMPS;
        }
    } else if (!SvOK(heap2)) croak("heap2 is undefined");
    else if (!sv_isobject(heap2)) croak("heap2 is not an object reference");
    else {
        I32 count;

        /* Simple way to keep the refcount up at both levels */
        if (!copied2) heap2 = MORTALCOPY(heap2);
        if (h1->used <= 2) one_by_one = 1;
        else {
            PUSHMARK(SP);
            PUSHs(heap2);
            PUTBACK;
            count = call_method("can_die", G_SCALAR);
            if (count != 1) croak("Forced scalar context call succeeded in returning %d values. This is impossible", (int) count);
            SPAGAIN;
            value = POPs;
            one_by_one = SvTRUE(value);
        }
        if (one_by_one) {
            ENTER;
            /* We will push up to three arguments */
            EXTEND(SP, 3);

            if (h1->fast)        key   = sv_newmortal();
            if (!h1->has_values) value = sv_newmortal();
            while (h1->used >= 2) {
                SAVETMPS;
                if (h1->has_values) value = h1->values[h1->used-1];
                else if (h1->order == LESS)
                    sv_setnv(value,  FKEY(NV, h1, h1->used-1));
                else if (h1->order == MORE)
                    sv_setnv(value, -FKEY(NV, h1, h1->used-1));
                else croak("No fast %s order", order_name(h1));

                if (!h1->fast) key = KEY(h1, h1->used-1);
                else if (h1->order== LESS)
                    sv_setnv(key,  FKEY(NV, h1, h1->used-1));
                else if (h1->order== MORE)
                    sv_setnv(key, -FKEY(NV, h1, h1->used-1));
                else croak("No fast %s order", order_name(h1));

                PUSHMARK(SP);
                PUSHs(heap2);
                PUSHs(key);
                PUSHs(value);
                PUTBACK;

                count = call_method("key_insert", G_VOID);

                SPAGAIN;
                if (count) {
                    if (count < 0) croak("Forced void context call 'key_insert' succeeded in returning %d values. This is impossible", (int) count);
                    SP -= count;
                }
                h1->used--;
                if (h1->has_values) SvREFCNT_dec(value);
                if (h1->wrapped && !h1->fast) SvREFCNT_dec(h1->keys[h1->used]);
                if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
                FREETMPS;
            }
            LEAVE;
        } else {
            size_t i;

            EXTEND(SP, 2*h1->used-1);
            i = 0;
            if (h1->fast || !h1->wrapped) i += h1->used-1;
            if (h1->has_values) i+= h1->used-1;
            if (i) EXTEND_MORTAL(i);

            /* Drain h1 only *after* calling key_insert in case h2 doesn't
               actually support key_insert */
            PUSHMARK(SP);
            PUSHs(heap2);
            for (i=1; i<h1->used; i++) {
                if (!h1->fast) key = KEY(h1, i);
                else {
                    if (h1->order== LESS) key = newSVnv( FKEY(NV, h1, i));
                    else if (h1->order== MORE) key = newSVnv(-FKEY(NV, h1, i));
                    else croak("No fast %s order", order_name(h1));
                    sv_2mortal(key);
                }
                PUSHs(key);

                if (h1->has_values) value = h1->values[i];
                else {
                    if (h1->order == LESS)
                        value = newSVnv(FKEY(NV, h1, i));
                    else if (h1->order == MORE)
                        value = newSVnv(-FKEY(NV, h1, i));
                    else croak("No fast %s order", order_name(h1));
                    sv_2mortal(value);
                }
                PUSHs(value);
            }
            PUTBACK;
            count = call_method("key_insert", G_VOID);
            SPAGAIN;
            if (count) {
                if (count < 0) croak("Forced void context call 'key_insert' succeeded in returning %d values. This is impossible", (int) count);
                SP -= count;
            }
            while (h1->used > 1) {
                h1->used--;
                if (h1->has_values) SvREFCNT_dec(h1->values[h1->used]);
                if (h1->wrapped && !h1->fast) SvREFCNT_dec(KEY(h1, h1->used));
            }
            if ((h1->used+4)*4 < h1->allocated) extend(h1, 0); /* shrink really */
        }
    }

void
absorb(SV *heap, ...)
  PREINIT:
    I32 count, i;
    SV *heap2;
  CODE:
    for (i=1; i<items; i++) {
        heap2 = ST(i);
        if (MAGIC && SvMAGICAL(heap2)) heap2 = MORTALCOPY(heap2);
        PUSHMARK(SP);
        XPUSHs(heap2);
        XPUSHs(heap);
        PUTBACK;
        count = call_method("_absorb", G_VOID);
        /* Needed or the stack will remember and return the stuff we pushed */
        SPAGAIN;
        if (count) {
            if (count < 0) croak("Forced void context call '_absorb' succeeded in returning %d values. This is impossible", (int) count);
            SP -= count;
        }
    }

void
key_absorb(SV *heap, ...)
  PREINIT:
    I32 count, i;
    SV *heap2;
  CODE:
    for (i=1; i<items; i++) {
        heap2 = ST(i);
        if (MAGIC && SvMAGICAL(heap2)) heap2 = MORTALCOPY(heap2);
        PUSHMARK(SP);
        XPUSHs(heap2);
        XPUSHs(heap);
        PUTBACK;
        count = call_method("_key_absorb", G_VOID);
        /* Needed or the stack will remember and return the stuff we pushed */
        SPAGAIN;
        if (count) {
            if (count < 0) croak("Forced void context call '_key_absorb' succeeded in returning %d values. This is impossible", (int) count);
            SP -= count;
        }
    }

void
infinity(heap h, SV *new_infinity=0)
  PPCODE:
    if (GIMME_V != G_VOID)
        XPUSHs(h->infinity ?
               sv_2mortal(SvREFCNT_inc(h->infinity)) : &PL_sv_undef);
    if (new_infinity) {
        if (h->infinity) sv_2mortal(h->infinity);
        h->infinity = newSVsv(new_infinity);
    }

IV
key_index(heap h)
  CODE:
    if (h->elements != ARRAY) croak("Heap elements are not of type 'Array'");
    RETVAL = h->aindex;
  OUTPUT:
    RETVAL

SV *
key_name(heap h)
  CODE:
    if (h->elements != HASH) croak("Heap elements are not of type 'Hash'");
    /* Make a copy instead of returning an lvalue
       so that the cached aindex remains valid */
    RETVAL = newSVsv(h->hkey);
  OUTPUT:
    RETVAL

SV *
key_method(heap h)
  CODE:
    if (h->elements != METHOD && h->elements != OBJECT)
        croak("Heap elements are not of type 'Method' or 'Object'");
    RETVAL = SvREFCNT_inc(h->hkey);
  OUTPUT:
    RETVAL

SV *
key_function(heap h)
  CODE:
    if (h->elements != FUNCTION && h->elements != ANY_ELEM)
        croak("Heap elements are not of type 'Function' or 'Any'");
    RETVAL = SvREFCNT_inc(h->hkey);
  OUTPUT:
    RETVAL

void
user_data(heap h, SV *new_user_data=0)
  PPCODE:
    if (GIMME_V != G_VOID)
        PUSHs(h->user_data ? h->user_data : &PL_sv_undef);
    if (new_user_data) {
        if (h->user_data) sv_2mortal(h->user_data);
        h->user_data = newSVsv(new_user_data);
    }

void
order(heap h)
  PPCODE:
    PUSHs(h->order == CODE_ORDER ?
          h->order_sv : sv_2mortal(newSVpv(order_name(h), 0)));

void
elements(heap h)
  PPCODE:
    XPUSHs(sv_2mortal(newSVpv(elements_name(h), 0)));
    if (GIMME_V == G_ARRAY) switch(h->elements) {
      case SCALAR:
        break;
      case ARRAY:
        XPUSHs(sv_2mortal(newSViv(h->aindex)));
        break;
      case HASH:
      case METHOD:
      case OBJECT:
      case FUNCTION:
      case ANY_ELEM:
        if (h->hkey) XPUSHs(sv_2mortal(newSVsv(h->hkey)));
        break;
      default:
        croak("Assertion: unhandled element type %s", elements_name(h));
    }

void
wrapped(heap h)
  PPCODE:
    if (h->key_ops) XSRETURN_YES;
    if (GIMME_V == G_SCALAR) XSRETURN_NO;
    XSRETURN_EMPTY;

void
dirty(heap h)
  PPCODE:
    if (h->dirty) XSRETURN_YES;
    if (GIMME_V == G_SCALAR) XSRETURN_NO;
    XSRETURN_EMPTY;

void
can_die(heap h)
  PPCODE:
    /* ->fast types are wrapped too really */
    if (h->can_die) XSRETURN_YES;
    if (GIMME_V == G_SCALAR) XSRETURN_NO;
    XSRETURN_EMPTY;

void
max_count(heap h)
  PPCODE:
    if (h->max_count == MAX_SIZE) XSRETURN_NV(INFINITY);
    XSRETURN_UV(h->max_count);

void
merge_arrays(heap h, ...)
  PREINIT:
    I32 i, j;
    size_t l, filled, left, k0, k1, k2;
    SV *value, **ptr, *key;
    AV *av, *work_av;
    merge *work_heap, here;
    fast_merge *fast_work_heap, fast_here;
  CODE:
    filled = left = 0;
    for (i=1; i<items; i++) {
        value = ST(i);
        if (MAGIC) SvGETMAGIC(value);
        if (!SvROK(value))
            croak("argument %u is not a reference", (unsigned int) i-1);

        work_av = (AV*) SvRV(value);
        if (MAGIC) SvGETMAGIC((SV *) work_av);
        if (SvTYPE(work_av) != SVt_PVAV)
            croak("argument %u is not an array reference", (unsigned int) i-1);
        j = av_len(work_av);
        if (j < 0) continue;
        filled++;
        left += j+1;
        av = work_av;
    }

    work_av = newAV();
    value = newRV_noinc((SV *) work_av);
    ST(0) = sv_2mortal(value);
    k2 = left;
    if (h->max_count != MAX_SIZE && h->max_count < left)
	left = h->max_count;
    av_extend(work_av, (I32) left - 1);

    switch(filled) {
      case 0: break;
      case 1:
        for (k0= k2-left, k1=0; k1 < left; k0++, k1++) {
            ptr = av_fetch(av, k0, 0);
            if (ptr) {
                value = newSVsv(*ptr);
                if (!av_store(work_av, k1, value)) {
                    SvREFCNT_dec(value);
                    croak("Assertion: Could not store value");
                }
            }
        }
        break;
      default:
        if (h->fast) {
            if (h->max_count < filled) {
                filled = h->max_count;
                New(__LINE__ % 1000, fast_work_heap, filled+1, struct fast_merge);
                SAVEFREEPV(fast_work_heap);
                k1 = 0;
                for (i=1; i<items && k1 < filled; i++) {
                    value = ST(i);
                    if (!SvROK(value))
                        croak("argument %u is not a reference (it was last time)",
                              (unsigned int) i-1);

                    av = (AV*) SvRV(value);
                    if (SvTYPE(work_av) != SVt_PVAV)
                        croak("argument %u is not an array reference (it was last time)", (unsigned int) i-1);
                    j = av_len(av);
                    if (j < 0) continue;
                    ++k1;
                    ptr = av_fetch(av, j, 0);
                    key = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    if      (h->order == LESS)
                        fast_work_heap[k1].key =  SvNV(key);
                    else if (h->order == MORE)
                        fast_work_heap[k1].key= -SvNV(key);
                    else croak("No fast %s order", order_name(h));
                    fast_work_heap[k1].array = av;
                    fast_work_heap[k1].index = j;
                }
                if (k1 != filled)
                    croak("Less than %"UVuf" non-empty array references in the second round", (UV) filled);

                /* heapify, top is smallest */
                for (k2 = filled/2; k2 > 0; k2--) {
                    l = k2*2;
                    fast_here = fast_work_heap[k2];
                    while (l < filled) {
                        if (fast_work_heap[l].key < fast_here.key) {
                            if (fast_work_heap[l+1].key < fast_work_heap[l].key) l++;
                        } else if (fast_work_heap[l+1].key < fast_here.key) l++;
                        else break;
                        fast_work_heap[l/2] = fast_work_heap[l];
                        l *= 2;
                    }
                    if (l == filled && fast_work_heap[l].key < fast_here.key) {
                        fast_work_heap[l/2] = fast_work_heap[l];
                        l *= 2;
                    }
                    fast_work_heap[l/2] = fast_here;
                }
                for (; i<items; i++) {
                    value = ST(i);
                    if (!SvROK(value))
                        croak("argument %u is not a reference (it was last time)",
                              (unsigned int) i-1);

                    av = (AV*) SvRV(value);
                    if (SvTYPE(work_av) != SVt_PVAV)
                        croak("argument %u is not an array reference (it was last time)", (unsigned int) i-1);
                    j = av_len(av);
                    if (j < 0) continue;
                    ptr = av_fetch(av, j, 0);
                    key = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    if      (h->order == LESS) fast_here.key =  SvNV(key);
                    else if (h->order == MORE) fast_here.key = -SvNV(key);
                    else croak("No fast %s order", order_name(h));
                    if (fast_work_heap[1].key >= fast_here.key) continue;
                    l = 2;
                    while (l < filled) {
                        if (fast_work_heap[l].key < fast_here.key) {
                            if (fast_work_heap[l+1].key < fast_work_heap[l].key) l++;
                        } else if (fast_work_heap[l+1].key < fast_here.key) l++;
                        else break;
                        fast_work_heap[l/2] = fast_work_heap[l];
                        l *= 2;
                    }
                    if (l == filled && fast_work_heap[l].key < fast_here.key)
                        fast_work_heap[l/2] = fast_work_heap[l];
                    else l /= 2;
                    fast_work_heap[l].key = fast_here.key;
                    fast_work_heap[l].array = av;
                    fast_work_heap[l].index = j;
                }
            } else {
                New(__LINE__ % 1000, fast_work_heap, filled+1, struct fast_merge);
                SAVEFREEPV(fast_work_heap);
                k1 = 0;
                for (i=1; i<items; i++) {
                    value = ST(i);
                    if (!SvROK(value))
                        croak("argument %u is not a reference (it was last time)",
                              (unsigned int) i-1);

                    av = (AV*) SvRV(value);
                    if (SvTYPE(work_av) != SVt_PVAV)
                        croak("argument %u is not an array reference (it was last time)", (unsigned int) i-1);
                    j = av_len(av);
                    if (j < 0) continue;
                    if (++k1 > filled)
                        croak("More than %"UVuf" non-empty array references in the second round", (UV) filled);
                    ptr = av_fetch(av, j, 0);
                    key = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    if      (h->order == LESS) fast_work_heap[k1].key =  SvNV(key);
                    else if (h->order == MORE) fast_work_heap[k1].key = -SvNV(key);
                    else croak("No fast %s order", order_name(h));
                    fast_work_heap[k1].array = av;
                    fast_work_heap[k1].index = j;
                }
                if (k1 != filled)
                    croak("Less than %"UVuf" non-empty array references in the second round", (UV) filled);
            }

            /* heapify */
            for (k2 = filled/2; k2 > 0; k2--) {
                l = k2*2;
                fast_here = fast_work_heap[k2];
                while (l < filled) {
                    if (fast_here.key < fast_work_heap[l].key) {
                        if (fast_work_heap[l].key < fast_work_heap[l+1].key) l++;
                    } else if (fast_here.key < fast_work_heap[l+1].key) l++;
                    else break;
                    fast_work_heap[l/2] = fast_work_heap[l];
                    l *= 2;
                }
                if (l == filled && fast_here.key < fast_work_heap[l].key) {
                    fast_work_heap[l/2] = fast_work_heap[l];
                    l *= 2;
                }
                fast_work_heap[l/2] = fast_here;
            }

            /* Start extracting */
            while (1) {
                j = fast_work_heap[1].index;
                av = fast_work_heap[1].array;
                ptr = av_fetch(av, j, 0);
                if (ptr) {
                    value = newSVsv(*ptr);
                    --left;
                    if (!av_store(work_av, left, value)) {
                        SvREFCNT_dec(value);
                        croak("Assertion: Could not store value");
                    }
                }
                if (left == 0) break;
                j--;
                if (j >= 0) {
                    ptr = av_fetch(av, j, 0);
                    key = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    if      (h->order == LESS) fast_here.key =  SvNV(key);
                    else if (h->order == MORE) fast_here.key = -SvNV(key);
                    else croak("No fast %s order", order_name(h));
                    fast_here.array = av;
                    fast_here.index = j;
                } else {
                    fast_here = fast_work_heap[filled--];
                    if (filled <= 1) {
                        av = fast_here.array;
                        for (j = fast_here.index; j >= 0; j--) {
                            --left;
                            ptr = av_fetch(av, j, 0);
                            if (ptr) {
                                value = newSVsv(*ptr);
                                if (!av_store(work_av, left, value)) {
                                    SvREFCNT_dec(value);
                                    croak("Assertion: Could not store value");
                                }
                            }
                            if (left == 0) break;
                        }
                        if (left) croak("Not enough values the second time round");
                        break;
                    }
                }
                l = 2;
                while (l < filled) {
                    if (fast_here.key < fast_work_heap[l].key) {
                        if (fast_work_heap[l].key < fast_work_heap[l+1].key) l++;
                    } else if (fast_here.key < fast_work_heap[l+1].key) l++;
                    else break;
                    fast_work_heap[l/2] = fast_work_heap[l];
                    l *= 2;
                }
                if (l == filled && fast_here.key < fast_work_heap[l].key) {
                    fast_work_heap[l/2] = fast_work_heap[l];
                    l *= 2;
                }
                fast_work_heap[l/2] = fast_here;
            }
        } else {
            if (h->max_count < filled) {
                filled = h->max_count;
                New(__LINE__ % 1000, work_heap, filled+1, struct merge);
                SAVEFREEPV(work_heap);
                k1 = 0;
                for (i=1; i<items && k1 < filled; i++) {
                    value = ST(i);
                    if (!SvROK(value))
                        croak("argument %u is not a reference (it was last time)",
                              (unsigned int) i-1);

                    av = (AV*) SvRV(value);
                    if (SvTYPE(work_av) != SVt_PVAV)
                        croak("argument %u is not an array reference (it was last time)", (unsigned int) i-1);
                    j = av_len(av);
                    if (j < 0) continue;
                    ++k1;
                    ptr = av_fetch(av, j, 0);
                    work_heap[k1].key = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    work_heap[k1].array = av;
                    work_heap[k1].index = j;
                }
                if (k1 != filled)
                    croak("Less than %"UVuf" non-empty array references in the second round", (UV) filled);

                /* heapify, top is smallest */
                for (k2 = filled/2; k2 > 0; k2--) {
                    l = k2*2;
                    here = work_heap[k2];
                    while (l < filled) {
                        if (less(aTHX_ h, work_heap[l].key, here.key)) {
                            if (less(aTHX_ h, work_heap[l+1].key, work_heap[l].key)) l++;
                        } else if (less(aTHX_ h, work_heap[l+1].key, here.key)) l++;
                        else break;
                        work_heap[l/2] = work_heap[l];
                        l *= 2;
                    }
                    if (l == filled && less(aTHX_ h, work_heap[l].key, here.key)) {
                        work_heap[l/2] = work_heap[l];
                        l *= 2;
                    }
                    work_heap[l/2] = here;
                }
                for (; i<items; i++) {
                    value = ST(i);
                    if (!SvROK(value))
                        croak("argument %u is not a reference (it was last time)",
                              (unsigned int) i-1);

                    av = (AV*) SvRV(value);
                    if (SvTYPE(work_av) != SVt_PVAV)
                        croak("argument %u is not an array reference (it was last time)", (unsigned int) i-1);
                    j = av_len(av);
                    if (j < 0) continue;
                    ptr = av_fetch(av, j, 0);
                    here.key   = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    if (!less(aTHX_ h, work_heap[1].key, here.key)) continue;
                    l = 2;
                    while (l < filled) {
                        if (less(aTHX_ h, work_heap[l].key, here.key)) {
                            if (less(aTHX_ h, work_heap[l+1].key, work_heap[l].key)) l++;
                        } else if (less(aTHX_ h, work_heap[l+1].key, here.key)) l++;
                        else break;
                        work_heap[l/2] = work_heap[l];
                        l *= 2;
                    }
                    if (l == filled &&
                        less(aTHX_ h, work_heap[l].key, here.key))
                        work_heap[l/2] = work_heap[l];
                    else l /= 2;
                    work_heap[l].key = here.key;
                    work_heap[l].array = av;
                    work_heap[l].index = j;
                }
            } else {
                New(__LINE__ % 1000, work_heap, filled+1, struct merge);
                SAVEFREEPV(work_heap);
                k1 = 0;
                for (i=1; i<items; i++) {
                    value = ST(i);
                    if (!SvROK(value))
                        croak("argument %u is not a reference (it was last time)",
                              (unsigned int) i-1);

                    av = (AV*) SvRV(value);
                    if (SvTYPE(work_av) != SVt_PVAV)
                        croak("argument %u is not an array reference (it was last time)", (unsigned int) i-1);
                    j = av_len(av);
                    if (j < 0) continue;
                    if (++k1 > filled)
                        croak("More than %"UVuf" non-empty array references in the second round", (UV) filled);
                    ptr = av_fetch(av, j, 0);
                    work_heap[k1].key   = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    work_heap[k1].array = av;
                    work_heap[k1].index = j;
                }
                if (k1 != filled)
                    croak("Less than %"UVuf" non-empty array references in the second round", (UV) filled);
            }

            /* heapify */
            for (k2 = filled/2; k2 > 0; k2--) {
                l = k2*2;
                here = work_heap[k2];
                while (l < filled) {
                    if (less(aTHX_ h, here.key, work_heap[l].key)) {
                        if (less(aTHX_ h, work_heap[l].key, work_heap[l+1].key)) l++;
                    } else if (less(aTHX_ h, here.key, work_heap[l+1].key)) l++;
                    else break;
                    work_heap[l/2] = work_heap[l];
                    l *= 2;
                }
                if (l == filled && less(aTHX_ h, here.key, work_heap[l].key)) {
                    work_heap[l/2] = work_heap[l];
                    l *= 2;
                }
                work_heap[l/2] = here;
            }

            /* Start extracting */
            while (1) {
                j = work_heap[1].index;
                av = work_heap[1].array;
                ptr = av_fetch(av, j, 0);
                if (ptr) {
                    value = newSVsv(*ptr);
                    --left;
                    if (!av_store(work_av, left, value)) {
                        SvREFCNT_dec(value);
                        croak("Assertion: Could not store value");
                    }
                }
                if (left == 0) break;
                j--;
                if (j >= 0) {
                    ptr = av_fetch(av, j, 0);
                    here.key   = fetch_key(aTHX_ h, ptr ? *ptr : &PL_sv_undef);
                    here.array = av;
                    here.index = j;
                } else {
                    here = work_heap[filled--];
                    if (filled <= 1) {
                        av = here.array;
                        for (j = here.index; j >= 0; j--) {
                            --left;
                            ptr = av_fetch(av, j, 0);
                            if (ptr) {
                                value = newSVsv(*ptr);
                                if (!av_store(work_av, left, value)) {
                                    SvREFCNT_dec(value);
                                    croak("Assertion: Could not store value");
                                }
                            }
                            if (left == 0) break;
                        }
                        if (left) croak("Not enough values the second time round");
                        break;
                    }
                }
                l = 2;
                while (l < filled) {
                    if (less(aTHX_ h, here.key, work_heap[l].key)) {
                        if (less(aTHX_ h, work_heap[l].key, work_heap[l+1].key)) l++;
                    } else if (less(aTHX_ h, here.key, work_heap[l+1].key)) l++;
                    else break;
                    work_heap[l/2] = work_heap[l];
                    l *= 2;
                }
                if (l == filled && less(aTHX_ h, here.key, work_heap[l].key)) {
                    work_heap[l/2] = work_heap[l];
                    l *= 2;
                }
                work_heap[l/2] = here;
            }
        }
        break;
    }
    XSRETURN(1);

void
DESTROY(heap h)
  PREINIT:
    SV *key, *value;
  PPCODE:
    /* Let's assume the module isn't buggy and it always increases the refcount
       on the heap during modification.
       That means that the user is explicitely calling DESTROY */
    if (h->locked)
	croak("Refusing explicit DESTROY call during heap modification");
    h->locked = 1;
    if (h->fast || !h->wrapped) {
        if (h->has_values)
            while (h->used > 1) SvREFCNT_dec(h->values[--h->used]);
    } else {
        while (h->used > 1) {
            --h->used;
            value = h->values[h->used];
            key   = h->keys  [h->used];
            SvREFCNT_dec(key);
            SvREFCNT_dec(value);
        }
    }
    if (h->hkey) {
        key = h->hkey;
        h->hkey = NULL;
        SvREFCNT_dec(key);
    }
    if (h->infinity) {
        key = h->infinity;
        h->infinity = NULL;
        SvREFCNT_dec(key);
    }
    if (h->user_data) {
        key = h->user_data;
        h->user_data = NULL;
        SvREFCNT_dec(key);
    }
    if (h->order_sv) {
        key = h->order_sv;
        h->order_sv = NULL;
        SvREFCNT_dec(key);
    }
    if (h->values) Safefree(h->values);
    if (h->keys)   Safefree(h->keys);
    Safefree(h);

BOOT:
    if (MAX_SIZE < 0) croak("signed size_t");
