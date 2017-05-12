#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if __GNUC__ >= 3
# define attribute(x) __attribute__(x)
# define expect(expr,value) __builtin_expect ((expr),(value))
# define INLINE static inline
#else
# define attribute(x)
# define expect(expr,value) (expr)
# define INLINE static
#endif

#define expect_false(expr) expect ((expr) != 0, 0)
#define expect_true(expr)  expect ((expr) != 0, 1)

typedef AV* MMapDB;

/* object AV layout -- must match @attributes in MMapDB.pm */
# define MMDB_FILENAME       0
# define MMDB_READONLY       1
# define MMDB_INTFMT         2
# define MMDB_DATA           3
# define MMDB_INTSIZE        4
# define MMDB_STRINGFMT      5
# define MMDB_STRINGTBL      6
# define MMDB_MAINIDX        7
# define MMDB_IDIDX          8
# define MMDB_MAIN_INDEX     9
# define MMDB_ID_INDEX      10
# define MMDB_NEXTID        11
# define MMDB_IDMAP         12
# define MMDB_TMPFH         13
# define MMDB_TMPNAME       14
# define MMDB_STRINGFH      15
# define MMDB_STRINGMAP     16
# define MMDB_STRPOS        17
# define MMDB_LOCKFILE      18
# define MMDB_FLAGS         19	/* 1 Byte, not used by now */
# define MMDB_DBFORMAT_IN   20
# define MMDB_DBFORMAT_OUT  21
# define MMDB_STRINGFMT_OUT 22

# define identity(v) (v)

/* converts DB integer to host */
# define xI(type, cnv, var) ((type)cnv(var))

/* returns the pointer of a string given by its position in the string table */
/* pos: position in host byte order */
/* t: string table pointer */
# define xSp(type, cnv, t, pos) ((char*)(t)+sizeof(type)+(pos))

/* reads the length of a string given by its position from the string table */
/* pos: position in host byte order */
/* t: string table pointer */
/*# define xSl(type, cnv, t, pos) (cnv(((type*)((char*)(t)+(pos)))[0]))*/
# define xSl(type, cnv, t, pos) \
    xI(type, cnv, ((type*)xSp(type, cnv, (t), (pos)))[-1])

# define xSutf8(type, cnv, t, pos) \
    ((int)xSp(type, cnv, (t), (pos))[xSl(type, cnv, (t), (pos))])



/********************************************************************/
/********************************************************************/
# undef DEBUG
/********************************************************************/
/********************************************************************/


# ifdef DEBUG
# define W warn
# else
# define W if(0) warn
# endif

# define DECLFN(type, fmt, cnv)						\
  static void								\
  pushresult_##fmt(pTHX_ const void* _descr, SV** sp);			\
  static void								\
  pushrecords_##fmt(pTHX_ const void* _descr, int dbfmt,		\
		    const char* datap, UV dataend,			\
		    const void* _strtbl, SV** sp);			\
  static void								\
  pushvalues_##fmt(pTHX_ const void* _descr, int dbfmt,			\
		   const char* datap, UV dataend,			\
		   const void* _strtbl, SV** sp);			\
  static void								\
  pushsorts_##fmt(pTHX_ const void* _descr, int dbfmt,			\
		  const char* datap, UV dataend,			\
		  const void* _strtbl, SV** sp);			\
  static void*								\
  idx_lookup_##fmt(const char* k, int klen, int dbfmt, int kutf8,	\
                   const void* kidx,					\
		   const void* strtbl, UV dataend,			\
		   /* output */ int *isidx, UV* nextpos);		\
  static UV								\
  idx_srchpos_##fmt(const char* k, int klen, int dbfmt, int kutf8,	\
		    const void* kidx,					\
		    const void* strtbl, UV dataend);			\
  static UV								\
  ididx_lookup_##fmt(UV id, const void* kidx);				\
  static AV*								\
  drec_##fmt(pTHX_ const void* _rec, int dbfmt, const void* _strtbl);	\
  static SV*								\
  dval_##fmt(pTHX_ const void* _rec, int dbfmt, const void* _strtbl);	\
  static SV*								\
  dsort_##fmt(pTHX_ const void* _rec, int dbfmt, const void* _strtbl);

DECLFN(U32,     L, identity)
DECLFN(UV,      J, identity)
DECLFN(U32,     N, ntohl)
# ifdef HAS_QUAD
DECLFN(U64TYPE, Q, identity)
# endif

typedef void* (*idx_lookup)(const char *k, int klen, int dbfmt, int kutf8,
	      		    const void *kidx,
			    const void *strtbl, UV dataend,
			    /* output params */
			    int* isidx, UV* nextpos);
typedef UV (*idx_srchpos)(const char *k, int klen, int dbfmt, int kutf8,
			  const void *kidx,
			  const void *strtbl, UV dataend);
typedef void (*pushresult)(pTHX_ const void* _descr, SV** sp);
typedef void (*pushrecords)(pTHX_ const void* _descr, int dbfmt,
			    const char* datap, UV dataend,
			    const void* _strtbl, SV** sp);
typedef void (*pushvalues)(pTHX_ const void* _descr, int dbfmt,
			   const char* datap, UV dataend,
			   const void* _strtbl, SV** sp);
typedef void (*pushsorts)(pTHX_ const void* _descr, int dbfmt,
			  const char* datap, UV dataend,
			  const void* _strtbl, SV** sp);
typedef AV* (*drec)(pTHX_ const void* _rec, int dbfmt, const void* _strtbl);
typedef SV* (*dval)(pTHX_ const void* _rec, int dbfmt, const void* _strtbl);
typedef SV* (*dsort)(pTHX_ const void* _rec, int dbfmt, const void* _strtbl);
typedef UV (*ididx_lookup)(UV id, const void *kidx);

# define USEFN(fmt) {							\
      idx_lookup_##fmt,							\
      idx_srchpos_##fmt,						\
      pushresult_##fmt,							\
      pushrecords_##fmt,						\
      pushvalues_##fmt,							\
      pushsorts_##fmt,							\
      ididx_lookup_##fmt,						\
      drec_##fmt,							\
      dval_##fmt,							\
      dsort_##fmt}
# define NULLFN {0,0,0,0}

struct {
  idx_lookup idx;
  idx_srchpos srch;
  pushresult pres;
  pushrecords precords;
  pushvalues pvalues;
  pushsorts psorts;
  ididx_lookup ididx;
  drec drec;
  dval dval;
  dsort dsort;
} lookup[]={
# ifdef EBCDIC
  USEFN(L),
  USEFN(N),
#   ifdef HAS_QUAD
  USEFN(Q),
#   else
  NULLFN,
#   endif
  USEFN(J),
# else	/* ASCII */
#   ifdef HAS_QUAD
  USEFN(Q),
#   else
  NULLFN,
#   endif
  USEFN(J),
  USEFN(L),
  USEFN(N),
# endif
};

# ifdef EBCDIC
/* XXX: untested due to lack of hardware */
#   define L(c, m) (*((lookup[(((c)-3)>>1) & 3]).m))
# else
#   define L(c, m) (*((lookup[((c)>>1) & 3]).m))
# endif

INLINE int
cmp(const void* p1, int p1len, const void* p2, int p2len) {
  int rc=memcmp(p1, p2, p1len<p2len?p1len:p2len);
  W("    --> cmp('%*s', '%*s') => %d\n",
    p1len, (char*)p1, p2len, (char*)p2, rc);
  return rc ? rc : p1len==p2len ? 0 : p1len<p2len ? -1 : 1;
}

INLINE int
cmp1(const void* p1, int p1len, int p1utf8,
     const void* p2, int p2len, int p2utf8) {
  int rc=memcmp(p1, p2, p1len<p2len?p1len:p2len);
  W("    --> cmp('%*s' (%d), '%*s' (%d)) => %d\n",
    p1len, (char*)p1, p1utf8, p2len, (char*)p2, p2utf8, rc);
  if( rc  ) return rc;
  if( p1len==p2len ) {
    if(!p1utf8 == !p2utf8) return 0;
    /* check for fake utf8 strings that means strings that have the flag set */
    /* but consist completely of ascii */
    char* fake=p1utf8 ? (char*)p1 : (char*)p2;
    while( p1len-- ) {
      if( *fake++ & 0x80 ) return p2utf8 ? -1 : 1;
    }
    return 0;
  }
  return p1len<p2len ? -1 : 1;
}

# define GENFN(type, fmt, cnv)						\
  static void								\
  pushresult_##fmt(pTHX_ const void* _descr, SV** sp) {			\
    const type* descr=_descr;						\
    type npos;								\
    int i;								\
    npos=xI(type, cnv, *descr++);	/* position count */		\
    EXTEND(SP, npos);							\
    for( i=0; i<npos; i++ ) {						\
      mPUSHu(xI(type, cnv, descr[i]));					\
    }									\
    PUTBACK;								\
  }									\
									\
  static void								\
  pushrecords_##fmt(pTHX_ const void* _descr, int dbfmt,		\
		    const char* datap,					\
		    UV dataend, const void* strtbl, SV** sp) {		\
    const type* descr=_descr;						\
    type npos, pos;							\
    int i;								\
    AV* av;								\
    npos=xI(type, cnv, *descr++);	/* position count */		\
    EXTEND(SP, npos);							\
    for( i=0; i<npos; i++ ) {						\
      pos=xI(type, cnv, descr[i]);					\
      if( expect_true(pos<dataend) ) {					\
        av=drec_##fmt(aTHX_ datap+pos, dbfmt, strtbl);			\
	PUSHs(sv_2mortal(newRV_noinc((SV*)av)));			\
      }									\
    }									\
    PUTBACK;								\
  }									\
									\
  static void								\
  pushvalues_##fmt(pTHX_ const void* _descr, int dbfmt,			\
		   const char* datap,					\
		   UV dataend, const void* strtbl, SV** sp) {		\
    const type* descr=_descr;						\
    type npos, pos;							\
    int i;								\
    SV* rsv;								\
    npos=xI(type, cnv, *descr++);	/* position count */		\
    EXTEND(SP, npos);							\
    for( i=0; i<npos; i++ ) {						\
      pos=xI(type, cnv, descr[i]);					\
      if( expect_true(pos<dataend) ) {					\
        rsv=dval_##fmt(aTHX_ datap+pos, dbfmt, strtbl);			\
	PUSHs(sv_2mortal(rsv));						\
      }									\
    }									\
    PUTBACK;								\
  }									\
									\
  static void								\
  pushsorts_##fmt(pTHX_ const void* _descr, int dbfmt,			\
		   const char* datap,					\
		   UV dataend, const void* strtbl, SV** sp) {		\
    const type* descr=_descr;						\
    type npos, pos;							\
    int i;								\
    SV* rsv;								\
    npos=xI(type, cnv, *descr++);	/* position count */		\
    EXTEND(SP, npos);							\
    for( i=0; i<npos; i++ ) {						\
      pos=xI(type, cnv, descr[i]);					\
      if( expect_true(pos<dataend) ) {					\
        rsv=dsort_##fmt(aTHX_ datap+pos, dbfmt, strtbl);		\
	PUSHs(sv_2mortal(rsv));						\
      }									\
    }									\
    PUTBACK;								\
  }									\
									\
  static void*								\
  idx_lookup_##fmt(const char* k, int klen, int dbfmt, int kutf8,	\
                   const void* kidx,					\
		   const void* strtbl, UV dataend,			\
		   /* output */ int *isidx, UV* nextpos) {		\
    const type* idx=kidx;						\
    type high=xI(type, cnv, *idx++);					\
    type rlen=xI(type, cnv, *idx++);					\
    type low=0, cur, curoff;						\
    int rel;								\
    if( dbfmt==0 ) { 							\
      while( low<high ) {						\
	cur=(high+low)/2;						\
	curoff=xI(type, cnv, idx[rlen*cur]);				\
        rel=cmp(xSp(type, cnv, strtbl, curoff),				\
	        xSl(type, cnv, strtbl, curoff),				\
	        k, klen);						\
	if(rel<0) {							\
	  low=cur+1;							\
	} else if(rel>0) {						\
	  high=cur;							\
	} else {							\
	  idx+=cur*rlen+1;	/* idx now points to the npos field */	\
	  *isidx=(xI(type, cnv, idx[0])==1 &&				\
		  xI(type, cnv, idx[1])>=dataend);			\
	  *nextpos=xI(type, cnv, idx[1]);				\
	  return (void*)(idx);						\
	}								\
      }									\
    } else {	   							\
      while( low<high ) {						\
	cur=(high+low)/2;						\
	W("  --> lch: %d, %d, %d\n", (int)low, (int)cur, (int)high);	\
	curoff=xI(type, cnv, idx[rlen*cur]);				\
        rel=cmp1(xSp(type, cnv, strtbl, curoff),			\
	         xSl(type, cnv, strtbl, curoff),			\
	         xSutf8(type, cnv, strtbl, curoff),			\
	         k, klen, kutf8);					\
	if(rel<0) {							\
	  low=cur+1;							\
	} else if(rel>0) {						\
	  high=cur;							\
	} else {							\
	  W("    --> BINGO");						\
	  idx+=cur*rlen+1;	/* idx now points to the npos field */	\
	  *isidx=(xI(type, cnv, idx[0])==1 &&				\
		  xI(type, cnv, idx[1])>=dataend);			\
	  *nextpos=xI(type, cnv, idx[1]);				\
	  return (void*)(idx);						\
	}								\
      }									\
    } 	   								\
    return NULL;							\
  }									\
									\
  static UV								\
  idx_srchpos_##fmt(const char* k, int klen, int dbfmt, int kutf8,	\
		    const void* kidx,					\
		    const void* strtbl, UV dataend) {			\
    const type* idx=kidx;						\
    type high=xI(type, cnv, *idx++);					\
    type rlen=xI(type, cnv, *idx++);					\
    type low=0, cur, curoff;						\
    int rel;								\
    if( dbfmt==0 ) { 							\
      while( low<high ) {						\
	cur=(high+low)/2;						\
	curoff=xI(type, cnv, idx[rlen*cur]);				\
        rel=cmp(xSp(type, cnv, strtbl, curoff),				\
	        xSl(type, cnv, strtbl, curoff),				\
	        k, klen);						\
	if(rel<0) {							\
	  low=cur+1;							\
	} else {							\
	  high=cur;							\
	}								\
      }									\
    } else {	   							\
      while( low<high ) {						\
	cur=(high+low)/2;						\
	curoff=xI(type, cnv, idx[rlen*cur]);				\
        rel=cmp1(xSp(type, cnv, strtbl, curoff),			\
	         xSl(type, cnv, strtbl, curoff),			\
	         xSutf8(type, cnv, strtbl, curoff),			\
	         k, klen, kutf8);					\
	if(rel<0) {							\
	  low=cur+1;							\
	} else {							\
	  high=cur;							\
	}								\
      }									\
    } 	   								\
    return (UV)low;							\
  }									\
									\
  static UV								\
  ididx_lookup_##fmt(UV id, const void* kidx) {				\
    const type* idx=kidx;						\
    type high=xI(type, cnv, *idx++);					\
    type low=0, cur, curid;						\
    while( low<high ) {							\
      cur=(high+low)/2;							\
      curid=xI(type, cnv, idx[2*cur]);					\
      if(curid<id) {							\
	low=cur+1;							\
      } else if(curid>id) {						\
	high=cur;							\
      } else {								\
	return (UV)xI(type, cnv, idx[2*cur+1]);				\
      }									\
    }									\
    return (UV)-1;							\
  }									\
									\
  static AV*								\
  drec_##fmt(pTHX_ const void* _rec, int dbfmt, const void* _strtbl) {	\
    const type* rec=_rec;						\
    type stroff;							\
    const char* strtbl=_strtbl;						\
    type id, nkeys, i;							\
    AV* av=newAV();							\
    AV* res=newAV();							\
    SV *sv;								\
									\
    rec++;      /* skip valid flag */					\
    id=xI(type, cnv, *rec++);	  /* read ID */				\
    nkeys=xI(type, cnv, *rec++);  /* read NKEYS */			\
    av_extend(av, nkeys);						\
									\
    for(i=0; i<nkeys; i++) {						\
      /* read next string position */ 					\
      stroff=xI(type, cnv, *rec++);					\
      sv=newSV(0);							\
      SvUPGRADE(sv, SVt_PV);						\
      SvPOK_only(sv);							\
      /* set the string itself */					\
      SvPV_set(sv, xSp(type, cnv, strtbl, stroff)); 			\
      SvLEN_set(sv, 0);							\
      SvCUR_set(sv, xSl(type, cnv, strtbl, stroff));			\
      SvREADONLY_on(sv);						\
      if( dbfmt>0 ) {							\
        if( xSutf8(type, cnv, strtbl, stroff) ) SvUTF8_on(sv);		\
      }									\
      av_push(av, sv);							\
    }									\
    									\
    av_extend(res, 4);							\
    av_push(res, newRV_noinc((SV*)av));					\
									\
    for( i=0; i<2; i++ ) {						\
      /* read next string position */ 					\
      stroff=xI(type, cnv, *rec++);					\
      sv=newSV(0);							\
      SvUPGRADE(sv, SVt_PV);						\
      SvPOK_only(sv);							\
      /* set the string itself */					\
      SvPV_set(sv, xSp(type, cnv, strtbl, stroff)); 			\
      SvLEN_set(sv, 0);							\
      SvCUR_set(sv, xSl(type, cnv, strtbl, stroff));			\
      SvREADONLY_on(sv);						\
      if( dbfmt>0 ) {							\
        if( xSutf8(type, cnv, strtbl, stroff) ) SvUTF8_on(sv);		\
      }									\
      av_push(res, sv);							\
    }									\
    av_push(res, newSVuv(id));						\
    return res;								\
  }									\
									\
  static SV*								\
  dval_##fmt(pTHX_ const void* _rec, int dbfmt, const void* _strtbl) {	\
    const type* rec=_rec;						\
    type stroff;							\
    const char* strtbl=_strtbl;						\
    SV *sv;								\
									\
    rec+=2;		/* skip valid flag and ID */			\
    rec+=xI(type, cnv, *rec)+2;  /* skip NKEYS, KEYS and SORT */	\
    		       		    	 	     	      		\
    stroff=xI(type, cnv, *rec);	 					\
    sv=newSV(0);							\
    SvUPGRADE(sv, SVt_PV);						\
    SvPOK_only(sv);							\
    /* set the string itself */						\
    SvPV_set(sv, xSp(type, cnv, strtbl, stroff)); 			\
    SvLEN_set(sv, 0);							\
    SvCUR_set(sv, xSl(type, cnv, strtbl, stroff));			\
    SvREADONLY_on(sv);							\
    if( dbfmt>0 ) {							\
      if( xSutf8(type, cnv, strtbl, stroff) ) SvUTF8_on(sv);		\
    }									\
    return sv;								\
  }									\
									\
  static SV*								\
  dsort_##fmt(pTHX_ const void* _rec, int dbfmt, const void* _strtbl) {	\
    const type* rec=_rec;						\
    type stroff;							\
    const char* strtbl=_strtbl;						\
    SV *sv;								\
									\
    rec+=2;		/* skip valid flag and ID */			\
    rec+=xI(type, cnv, *rec)+1;  /* skip NKEYS and KEYS */		\
    		       		    	 	     	      		\
    stroff=xI(type, cnv, *rec);	 					\
    sv=newSV(0);							\
    SvUPGRADE(sv, SVt_PV);						\
    SvPOK_only(sv);							\
    /* set the string itself */						\
    SvPV_set(sv, xSp(type, cnv, strtbl, stroff)); 			\
    SvLEN_set(sv, 0);							\
    SvCUR_set(sv, xSl(type, cnv, strtbl, stroff));			\
    SvREADONLY_on(sv);							\
    if( dbfmt>0 ) {							\
      if( xSutf8(type, cnv, strtbl, stroff) ) SvUTF8_on(sv);		\
    }									\
    return sv;								\
  }

GENFN(U32,     L, identity)
GENFN(UV,      J, identity)
GENFN(U32,     N, ntohl)
# ifdef HAS_QUAD
GENFN(U64TYPE, Q, identity)
# endif


MODULE = MMapDB		PACKAGE = MMapDB		

PROTOTYPES: DISABLED

void
index_lookup(I, ...)
    MMapDB I;
  PPCODE:
    if( expect_true(items>1) ) {
      UV pos=SvUV(ST(1));
      STRLEN keylen;
      char *datap, *intfmt, *keyp;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      void *strtbl, *found=0;
      UV dataend, dbfmt;
      int i, isidx=1;

      if( expect_false(!(svp && SvROK(*svp))) ) goto END;
      datap=SvPV_nolen(SvRV(*svp));

      intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
      strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));
      dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
      dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

      W("MainIdx=%d, pos=%d\n", (int)dataend, (int)pos);
      if( !pos ) pos=dataend;

      for(i=2; i<items && isidx; i++) {
	keyp=SvPV(ST(i), keylen);

	W("\nlooking for %*s\n", (int)keylen, (char*)keyp);

	found=L(intfmt[0],idx)(keyp, keylen, dbfmt, SvUTF8(ST(i)), datap+pos,
			       strtbl, dataend,
			       &isidx, &pos);

	W("  --> found %lx\n", (long)found);

	if(!found) goto END;
      }

      if( expect_true(found && i==items) ) {
	L(intfmt[0],pres)(aTHX_ found, sp);
	/* pres() EXTENDs the stack and hence can reallocate it.
	 * So it calls PUTPACK afterwards and we must return here
	 * to avoid the implicit PUTBACK that XS inserts. */
	return;
      }
    }
   END:

void
index_lookup_position(I, ...)
    MMapDB I;
  PPCODE:
    if( expect_true(items>1) ) {
      UV pos=SvUV(ST(1));
      STRLEN keylen;
      char *datap, *intfmt, *keyp;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      void *strtbl;
      UV dataend, dbfmt;
      int i, isidx=1;

      if( expect_false(!(svp && SvROK(*svp))) ) goto END;
      datap=SvPV_nolen(SvRV(*svp));

      intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
      strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));
      dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
      dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

      if( !pos ) pos=dataend;

      for(i=2; i<items-1 && isidx; i++) {
	keyp=SvPV(ST(i), keylen);
	if( !L(intfmt[0],idx)(keyp, keylen, dbfmt, SvUTF8(ST(i)), datap+pos,
			      strtbl, dataend,
			      &isidx, &pos) ) goto END;
      }

      if( expect_true(i==items-1 && isidx) ) {
	keyp=SvPV(ST(i), keylen);
	/* we return 2 items. Since we got at least 2 items on the
	 * stack we don't need to extend it. */
	mPUSHu(pos);
	mPUSHu(L(intfmt[0],srch)(keyp, keylen, dbfmt, SvUTF8(ST(i)), datap+pos,
				 strtbl, dataend));
      }
    }
   END:

void
id_index_lookup(I, id)
    MMapDB I;
    UV id;
  PPCODE:
    {
      char *datap, *intfmt;
      UV pos;
      SV **svp=av_fetch(I, MMDB_DATA, 0);

      if( expect_true((svp && SvROK(*svp))) ) {
	datap=SvPV_nolen(SvRV(*svp));

	intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
	pos=SvUV(*av_fetch(I, MMDB_IDIDX, 0));

	pos=L(intfmt[0],ididx)(id, datap+pos);

	if( pos!=(UV)-1 ) {
	  /* EXTEND(SP,1); # not necessary there is already room for 2 items */
	  PUSHs(sv_2mortal(newSVuv(pos)));
	}
      }
    }

void
data_record(I, ...)
    MMapDB I;
  PPCODE:
    if( items>1 ) {
      int i;
      UV pos;
      char *datap, *intfmt;
      UV dataend, dbfmt;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      AV* av;
      void* strtbl;

      if( expect_true((svp && SvROK(*svp))) ) {
	datap=SvPV_nolen(SvRV(*svp));

	dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
	dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

	intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
	strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));

	for( i=1; i<items; i++ ) {
	  pos=SvUV(ST(i));
	  if( expect_true(pos<dataend) ) {
	    av=L(intfmt[0],drec)(aTHX_ datap+pos, dbfmt, strtbl);
	    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
	  } else {
	    PUSHs(&PL_sv_undef);
	  }
	}
      }
    }

void
index_lookup_records(I, ...)
    MMapDB I;
  PPCODE:
    if( expect_true(items>1) ) {
      UV pos=SvUV(ST(1));
      STRLEN keylen;
      char *datap, *intfmt, *keyp;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      void *strtbl, *found=0;
      UV dataend, dbfmt;
      int i, isidx=1;

      if( expect_false(!(svp && SvROK(*svp))) ) goto END;
      datap=SvPV_nolen(SvRV(*svp));

      intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
      strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));
      dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
      dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

      W("MainIdx=%d, pos=%d\n", (int)dataend, (int)pos);
      if( !pos ) pos=dataend;

      for(i=2; i<items && isidx; i++) {
	keyp=SvPV(ST(i), keylen);

	W("\nlooking for %*s\n", (int)keylen, (char*)keyp);

	found=L(intfmt[0],idx)(keyp, keylen, dbfmt, SvUTF8(ST(i)), datap+pos,
			       strtbl, dataend,
			       &isidx, &pos);

	W("  --> found %lx\n", (long)found);

	if(!found) goto END;
      }

      if( expect_true(found && i==items) ) {
	L(intfmt[0],precords)(aTHX_ found, dbfmt, datap, dataend, strtbl, sp);
	/* pres() EXTENDs the stack and hence can reallocate it.
	 * So it calls PUTPACK afterwards and we must return here
	 * to avoid the implicit PUTBACK that XS inserts. */
	return;
      }
    }
   END:

void
data_value(I, ...)
    MMapDB I;
  PPCODE:
    if( items>1 ) {
      int i;
      UV pos;
      char *datap, *intfmt;
      UV dataend, dbfmt;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      SV* rsv;
      void* strtbl;

      if( expect_true((svp && SvROK(*svp))) ) {
	datap=SvPV_nolen(SvRV(*svp));

	dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
	dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

	intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
	strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));

	for( i=1; i<items; i++ ) {
	  pos=SvUV(ST(i));
	  if( expect_true(pos<dataend) ) {
	    rsv=L(intfmt[0],dval)(aTHX_ datap+pos, dbfmt, strtbl);
	    PUSHs(sv_2mortal(rsv));
	  } else {
	    PUSHs(&PL_sv_undef);
	  }
	}
      }
    }

void
index_lookup_values(I, ...)
    MMapDB I;
  PPCODE:
    if( expect_true(items>1) ) {
      UV pos=SvUV(ST(1));
      STRLEN keylen;
      char *datap, *intfmt, *keyp;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      void *strtbl, *found=0;
      UV dataend, dbfmt;
      int i, isidx=1;

      if( expect_false(!(svp && SvROK(*svp))) ) goto END;
      datap=SvPV_nolen(SvRV(*svp));

      intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
      strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));
      dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
      dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

      W("MainIdx=%d, pos=%d\n", (int)dataend, (int)pos);
      if( !pos ) pos=dataend;

      for(i=2; i<items && isidx; i++) {
	keyp=SvPV(ST(i), keylen);

	W("\nlooking for %*s\n", (int)keylen, (char*)keyp);

	found=L(intfmt[0],idx)(keyp, keylen, dbfmt, SvUTF8(ST(i)), datap+pos,
			       strtbl, dataend,
			       &isidx, &pos);

	W("  --> found %lx\n", (long)found);

	if(!found) goto END;
      }

      if( expect_true(found && i==items) ) {
	L(intfmt[0],pvalues)(aTHX_ found, dbfmt, datap, dataend, strtbl, sp);
	/* pres() EXTENDs the stack and hence can reallocate it.
	 * So it calls PUTPACK afterwards and we must return here
	 * to avoid the implicit PUTBACK that XS inserts. */
	return;
      }
    }
   END:

void
data_sort(I, ...)
    MMapDB I;
  PPCODE:
    if( items>1 ) {
      int i;
      UV pos;
      char *datap, *intfmt;
      UV dataend, dbfmt;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      SV* rsv;
      void* strtbl;

      if( expect_true((svp && SvROK(*svp))) ) {
	datap=SvPV_nolen(SvRV(*svp));

	dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
	dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

	intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
	strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));

	for( i=1; i<items; i++ ) {
	  pos=SvUV(ST(i));
	  if( expect_true(pos<dataend) ) {
	    rsv=L(intfmt[0],dsort)(aTHX_ datap+pos, dbfmt, strtbl);
	    PUSHs(sv_2mortal(rsv));
	  } else {
	    PUSHs(&PL_sv_undef);
	  }
	}
      }
    }

void
index_lookup_sorts(I, ...)
    MMapDB I;
  PPCODE:
    if( expect_true(items>1) ) {
      UV pos=SvUV(ST(1));
      STRLEN keylen;
      char *datap, *intfmt, *keyp;
      SV **svp=av_fetch(I, MMDB_DATA, 0);
      void *strtbl, *found=0;
      UV dataend, dbfmt;
      int i, isidx=1;

      if( expect_false(!(svp && SvROK(*svp))) ) goto END;
      datap=SvPV_nolen(SvRV(*svp));

      intfmt=SvPV_nolen(*av_fetch(I, MMDB_INTFMT, 0));
      strtbl=datap+SvUV(*av_fetch(I, MMDB_STRINGTBL, 0));
      dataend=SvUV(*av_fetch(I, MMDB_MAINIDX, 0));
      dbfmt=SvUV(*av_fetch(I, MMDB_DBFORMAT_IN, 0));

      W("MainIdx=%d, pos=%d\n", (int)dataend, (int)pos);
      if( !pos ) pos=dataend;

      for(i=2; i<items && isidx; i++) {
	keyp=SvPV(ST(i), keylen);

	W("\nlooking for %*s\n", (int)keylen, (char*)keyp);

	found=L(intfmt[0],idx)(keyp, keylen, dbfmt, SvUTF8(ST(i)), datap+pos,
			       strtbl, dataend,
			       &isidx, &pos);

	W("  --> found %lx\n", (long)found);

	if(!found) goto END;
      }

      if( expect_true(found && i==items) ) {
	L(intfmt[0],psorts)(aTHX_ found, dbfmt, datap, dataend, strtbl, sp);
	/* pres() EXTENDs the stack and hence can reallocate it.
	 * So it calls PUTPACK afterwards and we must return here
	 * to avoid the implicit PUTBACK that XS inserts. */
	return;
      }
    }
   END:

int
_localizing()
  CODE:
    RETVAL=PL_localizing;
  OUTPUT:
    RETVAL

## Local Variables:
## mode: C
## End:
