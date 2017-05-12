#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define  DECNUMDIGITS 1         // number of digits set dynamically
#include <decContext.h>
#include <decNumber.h>

decContext set;                 // default working context
size_t CurrentNumSize;          // current size of a decNumber in bytes
decNumber One;                  // 1 for increment

// Returns the size in bytes of a decNumber with 'ndigits' digits
size_t SizeNum(int32_t ndigits) {
  if ( ndigits <1 ) ndigits = 1;
  if (ndigits <= DECDPUN ) return sizeof(decNumber);
  ndigits -= DECDPUN;
  return (ndigits/DECDPUN+(ndigits%DECDPUN?1:0)+1)*sizeof(decNumberUnit)+sizeof(decNumber);
}

#define DECNUM_ALLOC( name, size )  Newxc(name, size, char, decNumber); \
                                    if (name == NULL) croak("Out of memory!") \


#define DECNUM_FREE( name ) if ( name ) Safefree(name); \
                            name = NULL

#define DECNUM_ADJUST( name ) if ( name->digits < set.digits - 12 ) { \
                                Renewc(name, SizeNum(name->digits), char, decNumber);   \
                                if (name == NULL) croak("Out of memory!"); \
                              }


//=======================| Math::decContext

MODULE = Math::decContext   PACKAGE = Math::decContext

#============| Initialize default context

BOOT:
  decContextTestEndian(0);
  set.round = DEC_ROUND_HALF_EVEN;
  decContextZeroStatus(&set);
  set.traps = 0;
  set.clamp = 0;
  set.digits = 34;
  set.emin = -6143;
  set.emax = 6144;
  CurrentNumSize = SizeNum(set.digits);
  decNumberFromUInt32(&One, 1);


MODULE = Math::decNumber    PACKAGE = decNumberPtr    PREFIX = decNumber

#============| Destructor
void
decNumberDESTROY( number )
  decNumber * number
  PPCODE:
    // fprintf( stderr, "***> DESTROY %x\n", number);
    DECNUM_FREE(number);


MODULE = Math::decNumber    PACKAGE = Math::decNumber   PREFIX = decNumber

#============| Global context functions

void
ContextClearStatus( status )
  uint32_t status;
  CODE:
    decContextClearStatus(&set, status);

uint32_t
ContextGetStatus()
  CODE:
    RETVAL = decContextGetStatus(&set);
  OUTPUT:
    RETVAL

const char *
_ContextStatusToString()
  CODE:
    RETVAL = decContextStatusToString(&set);
  OUTPUT:
    RETVAL

void
ContextSetStatus( status )
  uint32_t status
  CODE:
    decContextSetStatus(&set, status);

void
ContextSetStatusQuiet( status )
  uint32_t status
  CODE:
    decContextSetStatusQuiet(&set, status);

void
ContextSetStatusFromString( string )
  char * string
  CODE:
    decContextSetStatusFromString(&set, string);

void
ContextSetStatusFromStringQuiet( string )
  char * string
  CODE:
    decContextSetStatusFromStringQuiet(&set, string);

uint32_t
ContextSaveStatus( mask )
  uint32_t mask
  CODE:
    RETVAL = decContextSaveStatus(&set, mask);
  OUTPUT:
    RETVAL

uint32_t
ContextTestStatus( mask )
  uint32_t mask
  CODE:
    RETVAL = decContextTestStatus(&set, mask);
  OUTPUT:
    RETVAL

uint32_t
ContextTestSavedStatus( status, mask )
  uint32_t status
  uint32_t mask
  CODE:
    RETVAL = decContextTestSavedStatus(status, mask);
  OUTPUT:
    RETVAL

void
ContextRestoreStatus( status, mask )
  uint32_t status
  uint32_t mask
  CODE:
    decContextRestoreStatus(&set, status, mask);

void
ContextZeroStatus()
  CODE:
    decContextZeroStatus(&set);

enum rounding
ContextRounding( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextRounding( [mode] )");
    RETVAL = decContextGetRounding(&set);
    if (items == 1 )
      decContextSetRounding(&set, SvIV(ST(0)));
  OUTPUT:
    RETVAL

int32_t
ContextPrecision( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextPrecision( [digits] )");
    RETVAL = set.digits;
    if (items == 1 ) {
      set.digits = SvIV(ST(0));
      CurrentNumSize = SizeNum(SvIV(ST(0)));
    }
  OUTPUT:
    RETVAL

int32_t
ContextMaxExponent( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextMaxExponent( [exponent] )");
    RETVAL = set.emax;
    if (items == 1 )
      set.emax = SvIV(ST(0));
  OUTPUT:
    RETVAL

int32_t
ContextMinExponent( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextMinExponent( [exponent] )");
    RETVAL = set.emin;
    if (items == 1 )
      set.emin = SvIV(ST(0));
  OUTPUT:
    RETVAL

int32_t
ContextTraps( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextTraps( [mode] )");
    RETVAL = set.traps;
    if (items == 1 )
      set.traps = SvIV(ST(0));
  OUTPUT:
    RETVAL

uint8_t
ContextClamp( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextClamp( [clamp] )");
    RETVAL = set.clamp;
    if (items == 1 )
      set.clamp = (uint8_t) SvIV(ST(0));
  OUTPUT:
    RETVAL

#if DECSUBSET

uint8_t
ContextExtended( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextExtended( [extended] )");
    RETVAL = set.extended;
    if (items == 1 )
      set.extended = SvIV(ST(0));
  OUTPUT:
    RETVAL

#else

uint8_t
ContextExtended( ... )
  CODE:
    if (items > 1)
      croak("Usage: ContextExtended( [extended] )");
    RETVAL = 1;
  OUTPUT:
    RETVAL

#endif


#============| Conversion functions

decNumber *
decNumberFromString( string )
  char * string
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberFromString(RETVAL, string, &set);
    // DECNUM_ADJUST( RETVAL )
  OUTPUT:
    RETVAL

char *
decNumberToString( number )
  decNumber * number
  PREINIT:
    char * string;
  CODE:
    Newx(string, number->digits+14, char);
    if (string == NULL) croak("Out of memory!");
    SAVEFREEPV(string);
    decNumberToString(number, string);
    RETVAL = string;
  OUTPUT:
    RETVAL

char *
decNumberToEngString( number )
  decNumber * number
  PREINIT:
    char * string;
  CODE:
    Newx(string, number->digits+14, char);
    if (string == NULL) croak("Out of memory!");
    SAVEFREEPV(string);
    decNumberToEngString(number, string);
    RETVAL = string;
  OUTPUT:
    RETVAL

#============| Arithmetic functions

decNumber *
decNumberAbs ( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberAbs(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberAdd( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberAdd(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberDivide( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberDivide(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberDivideInteger( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberDivideInteger(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberExp( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberExp(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberFMA( a, b, c )
  decNumber * a
  decNumber * b
  decNumber * c
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberFMA(RETVAL, a, b, c, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberLn( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberLn(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberLogB( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberLogB(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberLog10( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberLog10(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberMax( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberMax(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberMaxMag( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberMaxMag(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberMin( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberMin(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberMinMag ( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberMinMag (RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberMinus( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberMinus(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberMultiply( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberMultiply(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberNextMinus( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberNextMinus(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberNextPlus( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberNextPlus(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberNextToward( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberNextToward(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberPlus( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberPlus(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberPower( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberPower(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberQuantize( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberQuantize(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberRemainder( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberRemainder(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberRemainderNear( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberRemainderNear(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberRescale( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberRescale(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberScaleB( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberScaleB(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberSquareRoot( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberSquareRoot(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberSubtract( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberSubtract(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberToIntegralExact( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberToIntegralExact(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberToIntegralValue( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberToIntegralValue(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberTrim( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    // The function decNumberTrim modifies its argument. We want a true function.
    decNumberCopy(RETVAL, a);
    RETVAL = decNumberTrim(RETVAL);
  OUTPUT:
    RETVAL

#============| Logical functions

decNumber *
decNumberAnd( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberAnd(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberCompare( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberCompare(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberCompareSignal( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberCompareSignal(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberCompareTotal( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberCompareTotal(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberCompareTotalMag( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberCompareTotalMag(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberInvert( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberInvert(RETVAL, a, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberOr( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberOr(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberRotate( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberRotate(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberSameQuantum( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberSameQuantum(RETVAL, a, b);
  OUTPUT:
    RETVAL

decNumber *
decNumberShift( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberShift(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

decNumber *
decNumberXor( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberXor(RETVAL, a, b, &set);
  OUTPUT:
    RETVAL

#============| Test functions

int32_t
decNumberIsCanonical( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsCanonical(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsFinite( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsFinite(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsInfinite( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsInfinite(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsNaN( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsNaN(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsNegative( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsNegative(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsNormal( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsNormal(a, &set);
  OUTPUT:
    RETVAL

int32_t
decNumberIsQNaN( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsQNaN(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsSNaN( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsSNaN(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsSpecial( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsSpecial(a);
  OUTPUT:
    RETVAL

int32_t
decNumberIsSubnormal( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsSubnormal(a, &set);
  OUTPUT:
    RETVAL

int32_t
decNumberIsZero( a )
  decNumber * a
  CODE:
    RETVAL = decNumberIsZero(a);
  OUTPUT:
    RETVAL

#============| Utility functions

enum decClass
decNumberClass( a )
  decNumber * a
  CODE:
    RETVAL = decNumberClass(a, &set);
  OUTPUT:
    RETVAL

const char *
_ClassToString( nclass )
  enum decClass nclass
  CODE:
    RETVAL = decNumberClassToString(nclass);
  OUTPUT:
    RETVAL

decNumber *
decNumberReduce( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, CurrentNumSize );
    decNumberReduce(RETVAL, a, &set);
  OUTPUT:
    RETVAL

int
decNumberRadix()
  CODE:
    RETVAL =  decNumberRadix(1);
  OUTPUT:
    RETVAL

decNumber *
decNumberCopy( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, SizeNum(a->digits) );
    decNumberCopy(RETVAL, a);
  OUTPUT:
    RETVAL

decNumber *
decNumberCopyNegate( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, SizeNum(a->digits) );
    decNumberCopyNegate(RETVAL, a);
  OUTPUT:
    RETVAL

decNumber *
decNumberCopySign( a, b )
  decNumber * a
  decNumber * b
  CODE:
    DECNUM_ALLOC( RETVAL, SizeNum(a->digits) );
    decNumberCopySign(RETVAL, a, b);
  OUTPUT:
    RETVAL

decNumber *
decNumberCopyAbs( a )
  decNumber * a
  CODE:
    DECNUM_ALLOC( RETVAL, SizeNum(a->digits) );
    decNumberCopyAbs(RETVAL, a);
  OUTPUT:
    RETVAL

void
_increment( a )
  decNumber * a
  CODE:
    decNumberAdd(a, a, &One, &set);

void
_decrement( a )
  decNumber * a
  CODE:
    decNumberSubtract(a, a, &One, &set);

const char *
decNumberVersion()
  CODE:
    RETVAL = decNumberVersion();
  OUTPUT:
    RETVAL

#============| The End


















