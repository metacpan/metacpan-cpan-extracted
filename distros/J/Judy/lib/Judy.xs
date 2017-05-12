#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* FIXME: omg, this is a buffer overflow. Store nothing in Judy::SL
   that is larger than this. */
#define MAXLINELEN    1000000
#define MAXLINELEN_S "1000000"

/* --- hint for SvPVbyte ---
   Does not work in perl-5.6.1, ppport.h implements a version
   borrowed from perl-5.7.3. */
#define NEED_sv_2pvbyte
#include "ppport.h"

/* Redefine Judy's error handling. Judy's default is to write this
   message to stderr and exit(1). That's unfriendly to a perl
   programmer. This does roughly the same thing but since it is perl's
   own croak(), the warning can be caught.

   This redefinition must occur prior to including Judy.h */
#define JUDYERROR(CallerFile,CallerLine,JudyFunc,JudyErrno,JudyErrID) \
    croak("File '%s', line %d: %s(), JU_ERRNO_* == %d, ID == %d\n",   \
          CallerFile, CallerLine,                                     \
          JudyFunc, JudyErrno, JudyErrID);

/* Judy.h comes from Judy at http://judy.sourceforge.net and is
   automatically installed for you by Alien::Judy. If you're
   having problems, please file a bug or better, fix it
   and post the patch. */
#include "Judy.h"

/* pjudy.h includes whatever I need to share between Judy.xs and the
   test suite. */
#include "pjudy.h"

#if PTRSIZE == 4
#        define PDEADBEEF (void*)0xdeadbeef
#else
#        define PDEADBEEF (void*)0xdeadbeefdeadbeef
#endif

#if LONGSIZE == 4
#        define DEADBEEF 0xdeadbeef
#else
#        define DEADBEEF 0xdeadbeefdeadbeef
#endif


int trace = 0;
#define OOGA(...)\
  do {\
    if ( trace ) {\
      PerlIO_printf(PerlIO_stdout(),__VA_ARGS__);\
      PerlIO_flush(PerlIO_stdout());\
    }\
  } while (0);

/* Pre-declare function signatures */
UWord_t
pvtJudyHSMemUsedV(Pvoid_t PJLArray, UWord_t remainingLength, UWord_t keyLength );

/* TODO: document this */
UWord_t
pvtJudyHSMemUsedV(Pvoid_t PJLArray, UWord_t remainingLength, UWord_t keyLength )
{
  if ( remainingLength > LONGSIZE ) {
    if ( JLAP_INVALID & (int)PJLArray ) {
      OOGA("keyLength=%lu sizeof(Word_t)=%u\n",keyLength,sizeof(Word_t));
      return keyLength + sizeof( Word_t );
    }
    else if ( PJLArray ) {
      UWord_t sum      = 0;
      UWord_t Index    = 0;
      Pvoid_t *innerL = NULL;

      /* Iterate over semi-colliding keys */
      JLF( innerL, PJLArray, Index );
      OOGA("innerL=%lx\n",(UWord_t)innerL);

      while ( innerL ) {
	OOGA("*innerL=%lx\n",(UWord_t)*innerL);
	if ( *innerL ) {
	  OOGA("JudyLMemUsed=%lu\n",JudyLMemUsed(*innerL));
	  sum += JudyLMemUsed( *innerL );
  
	  OOGA("pvtMemUsedJudyHSTree(%lx,%lu)\n",(UWord_t)*innerL,keyLength);
	  sum += pvtJudyHSMemUsedV( *innerL, keyLength - LONGSIZE, keyLength );
	}

	JLN( innerL, PJLArray, Index );
	OOGA("innerL=%lx\n",(UWord_t)innerL);
      }
    }
  }
  else {
    OOGA("keyLength=%lu sizeof(Word_t)=%u\n",keyLength,sizeof(Word_t));
    return keyLength + sizeof( Word_t );
  }
}

/* TODO: document this */
UWord_t
pvtJudyHSMemUsed( Pvoid_t PJHSArray )
{
  UWord_t sum;
  UWord_t keyLength = 0;
  Pvoid_t *hashL;

  /* Count the size of the base JudyL array that maps from key length
   * to hashes containing values with keys only that length.
   */
  sum = JudyLMemUsed( PJHSArray );

  /* Iterate over all key lengths and the hashes */
  JLF( hashL, PJHSArray, keyLength );
  while ( hashL ) {
    /* Count the size of this hash */
    sum += JudyLMemUsed( *hashL );

    /* Count the space consumed by all values in this hash */
    sum += pvtJudyHSMemUsedV( *hashL, keyLength, keyLength );

    JLN( hashL, PJHSArray, keyLength );
  }

  return sum;
}

MODULE = Judy PACKAGE = Judy PREFIX = lj_

PROTOTYPES: ENABLE

=for FIXME Constants aren't used as constants. The functions are
getting called anyway.

=cut

void
trace( x )
        int x
    CODE:
        trace = x;

Pvoid_t
lj_PJERR()
    PROTOTYPE:
    CODE:
        RETVAL = PJERR;
    OUTPUT:
        RETVAL

UWord_t
lj_JLAP_INVALID()
    PROTOTYPE:
    CODE:
        RETVAL = JLAP_INVALID;
    OUTPUT:
        RETVAL






MODULE = Judy PACKAGE = Judy::Mem PREFIX = ljme_

PROTOTYPES: DISABLE

void*
ljme_String2Ptr(in)
        Str in
    INIT:
        void *out = PDEADBEEF;
    CODE:
        Newx(out,in.length + 1,char);
        Copy(in.ptr,out,in.length,char);
        *((char*)(out + in.length)) = '\0';
        RETVAL = out;
    OUTPUT:
        RETVAL

Str
ljme_Ptr2String(in)
        void *in
    CODE:
        /* Guess about the length of the string. Use Ptr2String2 if there are nulls. */
        RETVAL.ptr = in;
        RETVAL.length = 0;
    OUTPUT:
        RETVAL

Str
ljme_Ptr2String2(in,length)
        void *in
        STRLEN length
    CODE:
        RETVAL.ptr = in;
        RETVAL.length = length;
    OUTPUT:
        RETVAL

void
ljme_Free(ptr)
        void *ptr
    CODE:
        Safefree(ptr);

IV
Peek(ptr)
        PWord_t ptr
    CODE:
        OOGA("%s:%d Peek(%#lx)\n",__FILE__,__LINE__,(long)ptr);
        OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)ptr);
        OOGA("%"IVdf"\n",(IV)*ptr);
        RETVAL = (Word_t)*ptr;
    OUTPUT:
        RETVAL

void
Poke(ptr,sv)
        PWord_t ptr
        SV *sv
    CODE:
        OOGA("%s:%d Poke(%#lx,%"IVdf")\n",__FILE__,__LINE__,(long)ptr,SvIV(sv));
        *ptr = SvIV(sv);






MODULE = Judy PACKAGE = Judy::1 PREFIX = lj1_

IV
lj1_Set( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    CODE:
        OOGA("%s:%d  J1S(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1S(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1S(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        RETVAL = Rc_int;
    OUTPUT:
        PJ1Array
        RETVAL

IV
lj1_Unset( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    CODE:
        OOGA("%s:%d  J1U(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1U(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1U(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        RETVAL = Rc_int;
    OUTPUT:
        PJ1Array
        RETVAL

IV
lj1_Test( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    CODE:
        OOGA("%s:%d  J1T(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1T(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1T(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        RETVAL = Rc_int;
    OUTPUT:
        PJ1Array
        RETVAL

UV
lj1_Count( PJ1Array, Key1, Key2 )
        Pvoid_t PJ1Array
        UWord_t Key1
        UWord_t Key2
    INIT:
        UWord_t Rc_word = DEADBEEF;
        JError_t JError;
    CODE:
        /* TODO: Upgrade the returned IV to a UV if the count would be
           "negative" */

        OOGA("%s:%d Judy1Count(%#lx,%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PJ1Array,Key1,Key2,(long)&JError);
        Rc_word = Judy1Count(PJ1Array,Key1,Key2,&JError);
        OOGA("%s:%d Judy1Count(%#lx,%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PJ1Array,Key1,Key2,(long)&JError);
        if ( Rc_word ) {
            RETVAL = Rc_word;
        }
        else {
            if ( JU_ERRNO(&JError) == JU_ERRNO_NONE ) {
                RETVAL = 0;
            }
            else if ( JU_ERRNO(&JError) == JU_ERRNO_FULL ) {
                /* On a 32-bit machine, this value is
                 * indistinguishable from the count of 2^32. On a
                 * 64-bit machine, this value cannot be triggered.
                 */
                RETVAL = ULONG_MAX;
            }
            else if ( JU_ERRNO(&JError) > JU_ERRNO_NFMAX ) {
                /* Defer to back to the default implementation for
                 * error handling in the J1C macro.
                 */
                J_E("Judy1Count",&JError);
            }
        }
    OUTPUT:
        RETVAL

void
lj1_Nth( PJ1Array, Nth )
        Pvoid_t PJ1Array
        UWord_t Nth
    INIT:
        UWord_t Index = DEADBEEF;
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1BC(%#x,%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Nth,Index);
        J1BC(Rc_int,PJ1Array,Nth,Index);
        OOGA("%s:%d .J1BC(%#x,%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Nth,Index);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Index)));
        }

UV
lj1_Free( PJ1Array )
        Pvoid_t PJ1Array
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        OOGA("%s:%d  J1FA(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJ1Array);
        J1FA(Rc_word,PJ1Array);
        OOGA("%s:%d .J1FA(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJ1Array);
        RETVAL = Rc_word;
    OUTPUT:
        PJ1Array
        RETVAL

UV
lj1_MemUsed( PJ1Array )
        Pvoid_t PJ1Array
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        OOGA("%s:%d  M1MU(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJ1Array);
        J1MU(Rc_word,PJ1Array);
        OOGA("%s:%d  M1MU(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJ1Array);
        RETVAL = Rc_word;
    OUTPUT:
        PJ1Array
        RETVAL

void
lj1_First( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1F(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1F(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1F(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }


void
lj1_Next( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1N(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1N(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1N(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }



void
lj1_Last( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1L(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1L(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1L(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }


void
lj1_Prev( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1P(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1P(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1P(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }

void
lj1_FirstEmpty( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1FE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1FE(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1FE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }


void
lj1_NextEmpty( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1NE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1NE(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1NE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }

void
lj1_LastEmpty( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1LE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1LE(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1LE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }

void
lj1_PrevEmpty( PJ1Array, Key )
        Pvoid_t PJ1Array
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  J1PE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);
        J1PE(Rc_int,PJ1Array,Key);
        OOGA("%s:%d .J1PE(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJ1Array,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }






MODULE = Judy PACKAGE = Judy::L PREFIX = ljl_

PWord_t
ljl_Set( PJLArray, Key, Value )
        Pvoid_t PJLArray
        UWord_t Key
        IWord_t Value
    INIT:
        PWord_t PValue = PDEADBEEF;
    CODE:
        OOGA("%s:%d  JLI(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        JLI(PValue,PJLArray,Key);
        OOGA("%s:%d .JLI(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        *PValue = Value;
        RETVAL = PValue;
    OUTPUT:
        PJLArray
        RETVAL


int
ljl_Delete( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    CODE:
        OOGA("%s:%d  JLD(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);
        JLD(Rc_int,PJLArray,Key);
        OOGA("%s:%d .JLD(%#x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);
        RETVAL = Rc_int;
    OUTPUT:
        PJLArray
        RETVAL

void
ljl_Get( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLG(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        JLG(PValue,PJLArray,Key);
        OOGA("%s:%d .JLG(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);

        if ( PValue ) {
            OOGA("%s:%d *%#lx,",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,2);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
        }

UWord_t
ljl_Count( PJLArray, Key1, Key2 )
        Pvoid_t PJLArray
        UWord_t Key1
        UWord_t Key2
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        OOGA("%s:%d  JLC(%#lx,%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray,Key1,Key2);
        JLC(Rc_word,PJLArray,Key1,Key2);
        OOGA("%s:%d .JLC(%#lx,%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray,Key1,Key2);

        RETVAL = Rc_word;
    OUTPUT:
        RETVAL

void
ljl_Nth( PJLArray, Nth )
        Pvoid_t PJLArray
        UWord_t Nth
    INIT:
        UWord_t Rc_word = DEADBEEF;
        UWord_t Index = DEADBEEF;
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLBC(%#lx,%#lx,%ld,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray,Nth,Index);
        JLBC(PValue,PJLArray,Nth,Index);
        OOGA("%s:%d .JLBC(%#lx,%#lx,%ld,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray,Nth,Index);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVuv(Index)));
        }

UWord_t
ljl_Free( PJLArray )
        Pvoid_t PJLArray
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        OOGA("%s:%d  JLFA(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray);
        JLFA(Rc_word,PJLArray);
        OOGA("%s:%d .JLFA(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray);

        RETVAL = Rc_word;
    OUTPUT:
        PJLArray
        RETVAL

UWord_t
ljl_MemUsed( PJLArray )
        Pvoid_t PJLArray
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        OOGA("%s:%d  JLMU(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray);
        JLMU(Rc_word,PJLArray);
        OOGA("%s:%d .JLMU(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJLArray);

        RETVAL = Rc_word;
    OUTPUT:
        RETVAL

void
ljl_First( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLF(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        JLF(PValue,PJLArray,Key);
        OOGA("%s:%d .JLF(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVuv(Key)));
        }


void
ljl_Next( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLN(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        JLN(PValue,PJLArray,Key);
        OOGA("%s:%d .JLN(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVuv(Key)));
        }



void
ljl_Last( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLL(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        JLL(PValue,PJLArray,Key);
        OOGA("%s:%d .JLL(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVuv(Key)));
        }


void
ljl_Prev( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLP(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);
        JLP(PValue,PJLArray,Key);
        OOGA("%s:%d .JLP(%#lx,%#lx,%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJLArray,Key);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVuv(Key)));
        }

void
ljl_FirstEmpty( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLFE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);
        JLFE(Rc_int,PJLArray,Key);
        OOGA("%s:%d .JLFE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }


void
ljl_NextEmpty( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLNE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);
        JLNE(Rc_int,PJLArray,Key);
        OOGA("%s:%d .JLNE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }

void
ljl_LastEmpty( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLLE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);
        JLLE(Rc_int,PJLArray,Key);
        OOGA("%s:%d .JLLE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }

void
ljl_PrevEmpty( PJLArray, Key )
        Pvoid_t PJLArray
        UWord_t Key
    INIT:
        int Rc_int = DEADBEEF;
    PPCODE:
        OOGA("%s:%d  JLPE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);
        JLPE(Rc_int,PJLArray,Key);
        OOGA("%s:%d .JLPE(0x%x,%#lx,%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJLArray,Key);

        if ( Rc_int ) {
            XPUSHs(sv_2mortal(newSVuv(Key)));
        }






MODULE = Judy PACKAGE = Judy::SL PREFIX = ljsl_

PWord_t
ljsl_Set( PJSLArray, Key, Value )
        Pvoid_t PJSLArray
        Str Key
        IWord_t Value
    INIT:
        PWord_t PValue = PDEADBEEF;
        uint8_t Index[MAXLINELEN];
    CODE:
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }
        Copy((const char* const)Key.ptr,Index,(const int)Key.length,char);
        Index[Key.length] = '\0';

        /* Cast from (char*) to (const uint8_t*) to silence a warning. */
        OOGA("%s:%d  JSLI(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)&Index);
        JSLI(PValue,PJSLArray,(const uint8_t* const)Index);
        OOGA("%s:%d .JSLI(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)&Index);

        OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
        *PValue = Value;
        OOGA("%#lx)\n",*PValue);

        RETVAL = PValue;
    OUTPUT:
        PJSLArray
        RETVAL

int
ljsl_Delete( PJSLArray, Key )
        Pvoid_t PJSLArray
        Str Key
    INIT:
        int Rc_int = DEADBEEF;
    CODE:
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }

        /* Cast from (char*) to (const uint8_t*) to silence a warning. */
        OOGA("%s:%d  JSLD(0x%x,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJSLArray,Key.ptr,(long)Key.ptr);
        JSLD(Rc_int,PJSLArray,(const uint8_t*)Key.ptr);
        OOGA("%s:%d .JSLD(0x%x,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,Rc_int,(long)PJSLArray,Key.ptr,(long)Key.ptr);
        RETVAL = Rc_int;
    OUTPUT:
        PJSLArray
        RETVAL

void
ljsl_Get( PJSLArray, Key )
        Pvoid_t PJSLArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
        uint8_t Index[MAXLINELEN];
    PPCODE:
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }
        Copy(Key.ptr,Index,Key.length,uint8_t);
        Index[Key.length] = '\0';

        /* Cast from (char*) to (const uint8_t*) to silence a warning. */
        OOGA("%s:%d PSLG(%#lx,%#lx,\"%s\"@%d)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Key.ptr,Key.length);
        JSLG(PValue,PJSLArray,Index);
        OOGA("%s:%d PSLG(%#lx,%#lx,\"%s\"@%d)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Key.ptr,Key.length);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,2);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
        }

UWord_t
ljsl_Free( PJSLArray )
        Pvoid_t PJSLArray
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        OOGA("%s:%d  JSLFA(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJSLArray);
        JSLFA(Rc_word,PJSLArray);
        OOGA("%s:%d .JSLFA(%#lx,%#lx)\n",__FILE__,__LINE__,Rc_word,(long)PJSLArray);

        RETVAL = Rc_word;
    OUTPUT:
        PJSLArray
        RETVAL

void
ljsl_First( PJSLArray, Key )
        Pvoid_t PJSLArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
        uint8_t Index[MAXLINELEN];
    PPCODE:
        /* Copy Index because it is both input and output. */
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }
        Copy(Key.ptr,Index,Key.length,uint8_t);
        Index[Key.length] = '\0';

        /* Cast from (char*) to (uint8_t*) to silence a warning. */ 
        OOGA("%s:%d  JSLF(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);
        JSLF(PValue,PJSLArray,Index);
        OOGA("%s:%d .JSLF(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVpv((char*)Index,0)));
        }

void
ljsl_Next( PJSLArray, Key )
        Pvoid_t PJSLArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
        uint8_t Index[MAXLINELEN];
    PPCODE:
        /* Copy Index because it is both input and output. */
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }
        Copy(Key.ptr,Index,Key.length,uint8_t);
        Index[Key.length] = '\0';

        /* Cast from (char*) to (uint8_t*) to silence a warning. */
        OOGA("%s:%d  JSLN(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);
        JSLN(PValue,PJSLArray,Index);
        OOGA("%s:%d .JSLN(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVpv((char*)Index,0)));
        }

void
ljsl_Last( PJSLArray, Key )
        Pvoid_t PJSLArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
        uint8_t Index[MAXLINELEN];
    PPCODE:
        /* Copy Index because it is both input and output. */
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }
        Copy(Key.ptr,Index,Key.length,uint8_t);
        Index[Key.length] = '\0';

        /* Cast from (char*) to (uint8_t*) to silence a warning. */
        OOGA("%s:%d  JSLL(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);
        JSLL(PValue,PJSLArray,Index);
        OOGA("%s:%d .JSLL(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVpv((char*)Index,0)));
        }

void
ljsl_Prev( PJSLArray, Key )
        Pvoid_t PJSLArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
        uint8_t Index[MAXLINELEN];
    PPCODE:
        /* Copy Index because it is both input and output. */
        if ( Key.length > MAXLINELEN ) {
           croak("Sorry, can't use keys longer than "MAXLINELEN_S" for now. This is a bug.");
        }
        Copy(Key.ptr,Index,Key.length,uint8_t);
        Index[Key.length] = '\0';

        /* Cast from (char*) to (uint8_t*) to silence a warning. */
        OOGA("%s:%d  JSLP(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);
        JSLP(PValue,PJSLArray,Index);
        OOGA("%s:%d .JSLP(%#lx,%#lx,\"%s\"@%#lx)\n",__FILE__,__LINE__,(long)PValue,(long)PJSLArray,Index,(long)Index);

        if ( PValue ) {
            OOGA("%s:%d *%#lx=",__FILE__,__LINE__,(long)PValue);
            OOGA("%#lx)\n",*PValue);
            EXTEND(SP,3);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
            PUSHs(sv_2mortal(newSVpv((char*)Index,0)));
        }






MODULE = Judy PACKAGE = Judy::HS PREFIX = ljhs_

UWord_t
ljhs_MemUsed( PJHSArray )
        Pvoid_t PJHSArray
    CODE:
        RETVAL = pvtJudyHSMemUsed( PJHSArray );
    OUTPUT:
        RETVAL

UWord_t
ljhs_Duplicates( PJHSArray, Key )
        Pvoid_t PJHSArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    CODE:
        JHSI(PValue,PJHSArray,Key.ptr,Key.length);
        RETVAL = *PValue;
        ++*PValue;
    OUTPUT:
        PJHSArray
        RETVAL



PWord_t
ljhs_Set( PJHSArray, Key, Value )
        Pvoid_t PJHSArray
        Str Key
        IWord_t Value
    INIT:
        IWord_t  *PValue = PDEADBEEF;
    CODE:
        JHSI(PValue,PJHSArray,Key.ptr,Key.length);
        *PValue = Value;
        RETVAL = PValue;
    OUTPUT:
        PJHSArray
        RETVAL

int
ljhs_Delete( PJHSArray, Key )
        Pvoid_t PJHSArray
        Str Key
    INIT:
        int Rc_int = DEADBEEF;
    CODE:
        JHSD(Rc_int,PJHSArray,Key.ptr,Key.length);
        RETVAL = Rc_int;
    OUTPUT:
        PJHSArray
        RETVAL

void
ljhs_Get( PJHSArray, Key )
        Pvoid_t PJHSArray
        Str Key
    INIT:
        PWord_t PValue = PDEADBEEF;
    PPCODE:
        JHSG(PValue,PJHSArray,Key.ptr,Key.length);

        /* OUTPUT */
        if ( PValue ) {
            EXTEND(SP,2);
            PUSHs(sv_2mortal(newSVuv(INT2PTR(UV,PValue))));
            PUSHs(sv_2mortal(newSViv((signed long int)*PValue)));
        }

UWord_t
ljhs_Free( PJHSArray )
        Pvoid_t PJHSArray
    INIT:
        UWord_t Rc_word = DEADBEEF;
    CODE:
        JHSFA(Rc_word,PJHSArray);
        RETVAL = Rc_word;
    OUTPUT:
        PJHSArray
        RETVAL






MODULE = Judy PACKAGE = Judy PREFIX = lj_

# Switch back to the base Judy namespace. xsubpp requires this.
#
# Also, avoid terminating in =pod because ExtUtils::ParseXS throws
# warnings. This paragraph used to be in =pod/cut comments.