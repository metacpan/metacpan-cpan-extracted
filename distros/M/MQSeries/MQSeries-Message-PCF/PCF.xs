#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static char rcsid[] = "$Id: PCF.xs,v 37.11 2012/09/26 16:10:12 jettisu Exp $";

/*
  (c) 1999-2012 Morgan Stanley & Co. Incorporated
  See ..../src/LICENSE for terms of distribution.
 */

/*
  Copied from DevelPPPort-1.0003/ppport.h
 */
#ifndef PERL_PATCHLEVEL
#       ifndef __PATCHLEVEL_H_INCLUDED__
#               include "patchlevel.h"
#       endif
#endif
#ifndef PATCHLEVEL
#   define PATCHLEVEL PERL_VERSION
#endif
#ifndef PERL_PATCHLEVEL
#       define PERL_PATCHLEVEL PATCHLEVEL
#endif
#ifndef PERL_SUBVERSION
#       define PERL_SUBVERSION SUBVERSION
#endif

#ifndef ERRSV
#       define ERRSV perl_get_sv("@",FALSE)
#endif

#if (PERL_PATCHLEVEL < 4) || ((PERL_PATCHLEVEL == 4) && (PERL_SUBVERSION <= 4))
#       define PL_sv_undef      sv_undef
#       define PL_sv_yes        sv_yes
#       define PL_sv_no         sv_no
#       define PL_na            na
#       define PL_stdingv       stdingv
#       define PL_hints         hints
#       define PL_curcop        curcop
#       define PL_curstash      curstash
#       define PL_copline       copline
#endif

#if (PERL_PATCHLEVEL < 5)
#  ifdef WIN32
#       define dTHR extern int Perl___notused
#  else
#       define dTHR extern int errno
#  endif
#endif

#ifndef boolSV
#       define boolSV(b) ((b) ? &PL_sv_yes : &PL_sv_no)
#endif

#ifndef __MVS__
#include "cmqc.h"
#include "cmqcfc.h"
#else
#include "../inc/cmqc.h"
#include "../inc/cmqcfc.h"
#endif /* ! __MVS__ */

/*#define DEBUGME*/

#ifdef DEBUGME
#define TRACEME(x)      do { PerlIO_stdoutf x; PerlIO_stdoutf("\n"); } while (0)
#else
#define TRACEME(x)
#endif

/*
 * PRIdLEAST64 and SCNdLEAST64 are a late additions to C99, but we may
 * have the non-least versions.
 */
#if !defined(PRIdLEAST64)
#if !defined(PRId64)
#define PRIdLEAST64 "lld"
#else /* defined(PRId64) */
#define PRIdLEAST64 PRId64
#endif /* defined(PRId64) */
#endif /* defined(PRIdLEAST64) */
#if !defined(SCNdLEAST64)
#if !defined(SCNd64)
#define SCNdLEAST64 "lld"
#else /* defined(SCNd64) */
#define SCNdLEAST64 SCNd64
#endif /* defined(SCNd64) */
#endif /* defined(SCNdLEAST64) */

MODULE = MQSeries::Message::PCF         PACKAGE = MQSeries::Message::PCF

void
MQDecodePCF(pBuffer)
     PMQCHAR pBuffer;

     PPCODE:
     {
         PMQCHAR   pTemp = pBuffer;
         PMQCHAR   pSListTemp;
         MQCFST   *pStringParam;
#ifdef MQCFT_STRING_FILTER
         MQCFSF   *pStringFilter;
#endif
#ifdef MQCFT_BYTE_STRING
         MQCFBS   *pByteStringParam;
#endif
         MQCFIN   *pIntegerParam;
         MQCFSL   *pStringParamList;
         MQCFIL   *pIntegerParamList;
#ifdef MQCFT_INTEGER_FILTER
         MQCFIF   *pIntegerFilter;
#endif
#ifdef MQCFT_INTEGER64
         MQCFIN64 *pInteger64Param;
#endif /* MQCFT_INTEGER64 */
#ifdef MQCFT_INTEGER64_LIST
         /* yes, the type name looks like a filter, but...whatever */
         MQCFIL64 *pInteger64ParamList;
#endif /* MQCFT_INTEGER64_LIST */
#ifdef MQCFT_GROUP
         MQCFGR *pGroupParam;
#endif /* MQCFT_GROUP */

         HV       *HeaderHV, *DataHV;
         AV       *DataAV, *ListAV;
         int       count, listcount, errors = 0, tmpStringLength;
         AV       *DataAVA; /* a "stack" for handling MQCFT_GROUP records */
         int       parametercount;
         int       abscount; /* like "count", but ignores groups */

         MQCFH     Header = *(MQCFH *)pTemp;
         pTemp += Header.StrucLength;

         /* Create hash with header fields */
         HeaderHV = newHV();

         hv_store(HeaderHV,"Type",4,(newSViv(Header.Type)),0);
         hv_store(HeaderHV,"Version",7,(newSViv(Header.Version)),0);
         hv_store(HeaderHV,"Command",7,(newSViv(Header.Command)),0);
         hv_store(HeaderHV,"MsgSeqNumber",12,(newSViv(Header.MsgSeqNumber)),0);
         hv_store(HeaderHV,"Control",7,(newSViv(Header.Control)),0);
         hv_store(HeaderHV,"CompCode",8,(newSViv(Header.CompCode)),0);
         hv_store(HeaderHV,"Reason",6,(newSViv(Header.Reason)),0);
         hv_store(HeaderHV,"ParameterCount",14,(newSViv(Header.ParameterCount)),0);

         XPUSHs(sv_2mortal(newRV_noinc((SV*)HeaderHV)));

         /* Create array with data */
         DataAV = newAV();
         DataAVA = newAV();

         /*
          * Step 0 of group handling: the limit on the number of loops
          * through the for is not dependent any longer on the header.
          */
         parametercount = (int)Header.ParameterCount;
         for ( abscount = count = 0 ; count < parametercount ; abscount++, count++ ) {
             /*
              * FIXME for MQV6:
              * - Byte
              * - Byte list
              * - Display unknown type number
              */
             pStringParam = (MQCFST *)pTemp;
#ifdef MQCFT_STRING_FILTER
             pStringFilter = (MQCFSF *)pTemp;
#endif
#ifdef MQCFT_BYTE_STRING
             pByteStringParam = (MQCFBS *)pTemp;
#endif
             pIntegerParam = (MQCFIN *)pTemp;
             pStringParamList = (MQCFSL *)pTemp;
             pIntegerParamList = (MQCFIL *)pTemp;
#ifdef MQCFT_INTEGER_FILTER
             pIntegerFilter = (MQCFIF *)pTemp;
#endif
#ifdef MQCFT_INTEGER64
             pInteger64Param = (MQCFIN64 *)pTemp;
#endif /* MQCFT_INTEGER64 */
#ifdef MQCFT_INTEGER64_LIST
             pInteger64ParamList = (MQCFIL64 *)pTemp;
#endif /* MQCFT_INTEGER64_LIST */
#ifdef MQCFT_GROUP
             pGroupParam = (MQCFGR *)pTemp;
#endif /* MQCFT_GROUP */

             /* warn("PCF parameter %d is of type %d, structure length %d, parameter %d\n", abscount, pStringParam->Type, pStringParam->StrucLength, pStringParam->Parameter); */

             if ( pStringParam->Type == MQCFT_STRING ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pStringParam->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pStringParam->Parameter)),0);
                 hv_store(DataHV,"CodedCharSetId",14,(newSViv(pStringParam->CodedCharSetId)),0);
                 hv_store(DataHV,"String",6,(newSVpvn(pStringParam->String,pStringParam->StringLength)),0);

                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pStringParam->StrucLength;
#ifdef MQCFT_STRING_FILTER
             } else if ( pStringFilter->Type == MQCFT_STRING_FILTER ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pStringFilter->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pStringFilter->Parameter)),0);
                 hv_store(DataHV,"Operator",8,(newSViv(pStringFilter->Operator)),0);
                 hv_store(DataHV,"CodedCharSetId",14,(newSViv(pStringFilter->CodedCharSetId)),0);
                 hv_store(DataHV,"FilterValue",11,(newSVpvn(pStringFilter->FilterValue,pStringFilter->FilterValueLength)),0);

                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pIntegerFilter->StrucLength;
#endif /* MQCFT_INTEGER_FILTER */
#ifdef MQCFT_BYTE_STRING
             } else if ( pByteStringParam->Type == MQCFT_BYTE_STRING ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pByteStringParam->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pByteStringParam->Parameter)),0);
                 hv_store(DataHV,"ByteString",10,(newSVpvn((const char *)pByteStringParam->String,pByteStringParam->StringLength)),0);

                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pByteStringParam->StrucLength;
#endif /*MQCFT_BYTE_STRING  */
             } else if ( pIntegerParam->Type == MQCFT_INTEGER ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pIntegerParam->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pIntegerParam->Parameter)),0);
                 hv_store(DataHV,"Value",5,(newSViv(pIntegerParam->Value)),0);

                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pIntegerParam->StrucLength;
#ifdef MQCFT_INTEGER64
             } else if ( pInteger64Param->Type == MQCFT_INTEGER64 ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pInteger64Param->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pInteger64Param->Parameter)),0);
                 if (sizeof(IV) >= 8) {
                     hv_store(DataHV,"Value",5,(newSViv((IV)pInteger64Param->Value)),0);
                 } else {
                     char   printed_number[32];
                     STRLEN len;

                     sprintf(printed_number, "%" PRIdLEAST64, pInteger64Param->Value);
                     len = strlen((const char *)printed_number);
                     hv_store(DataHV,"Value",5,(newSVpvn(printed_number,len)),0);
                 }

                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pInteger64Param->StrucLength;
#endif /* MQCFT_INTEGER64 */
#ifdef MQCFT_INTEGER_FILTER
             } else if ( pIntegerFilter->Type == MQCFT_INTEGER_FILTER ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pIntegerFilter->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pIntegerFilter->Parameter)),0);
                 hv_store(DataHV,"Operator",8,(newSViv(pIntegerFilter->Operator)),0);
                 hv_store(DataHV,"FilterValue",11,(newSViv(pIntegerFilter->FilterValue)),0);

                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pIntegerFilter->StrucLength;
#endif /* MQCFT_INTEGER_FILTER */
             } else if ( pStringParamList->Type == MQCFT_STRING_LIST ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pStringParamList->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pStringParamList->Parameter)),0);
                 hv_store(DataHV,"CodedCharSetId",14,(newSViv(pStringParamList->CodedCharSetId)),0);

                 ListAV = newAV();
                 pSListTemp = pStringParamList->Strings;

                 for ( listcount = 0 ; listcount < (int)pStringParamList->Count ; listcount++ ) {

                     tmpStringLength = 0;

                     while (
                            tmpStringLength < pStringParamList->StringLength &&
                            pSListTemp[tmpStringLength] != '\0'
                            ) {
                         tmpStringLength++;
                     }

                     av_push(ListAV,newSVpvn(pSListTemp,tmpStringLength));
                     pSListTemp += pStringParamList->StringLength;
                 }

                 hv_store(DataHV,"Strings",7,(newRV_noinc((SV*)ListAV)),0);
                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pStringParamList->StrucLength;
             } else if ( pIntegerParamList->Type == MQCFT_INTEGER_LIST ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pIntegerParamList->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pIntegerParamList->Parameter)),0);

                 ListAV = newAV();

                 for ( listcount = 0 ; listcount < (int)pIntegerParamList->Count ; listcount++ ) {
                     av_push(ListAV,newSViv(pIntegerParamList->Values[listcount]));
                 }

                 hv_store(DataHV,"Values",6,(newRV_noinc((SV*)ListAV)),0);
                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pIntegerParamList->StrucLength;
#ifdef MQCFT_INTEGER64_LIST
             } else if ( pInteger64ParamList->Type == MQCFT_INTEGER64_LIST ) {
                 DataHV = newHV();

                 hv_store(DataHV,"Type",4,(newSViv(pInteger64ParamList->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pInteger64ParamList->Parameter)),0);

                 ListAV = newAV();

                 if (sizeof(IV) >= 8) {
                     for ( listcount = 0 ; listcount < (int)pInteger64ParamList->Count ; listcount++ ) {
                         av_push(ListAV,newSViv((IV)pInteger64ParamList->Values[listcount]));
                     }
                 } else {
                     char   printed_number[32]; 
                     STRLEN len; 
                     for ( listcount = 0 ; listcount < (int)pInteger64ParamList->Count ; listcount++ ) {
                         sprintf(printed_number, "%" PRIdLEAST64, pInteger64ParamList->Values[listcount]); 
                         len = strlen((const char *)printed_number); 
                         av_push(ListAV,newSVpvn(printed_number,len));
                     }
                 }

                 hv_store(DataHV,"Values",6,(newRV_noinc((SV*)ListAV)),0);
                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pIntegerParamList->StrucLength;
#endif /* MQCFT_INTEGER64_LIST */
#ifdef MQCFT_GROUP
             } else if ( pGroupParam->Type == MQCFT_GROUP ) {
                 /*
                  * Step 1 of group handling: don't talk about group
                  * handling.
                  */
                 AV* GroupAV = newAV();

                 /*
                  * Step 2 of group handling: create and fill the
                  * regular anonymous hash that we usually do, but the
                  * "group" is the new anonymous array we just created
                  * (see step 1), not something from the PCF data
                  * itself.  Then push it into the current DataAV and
                  * push up the pointer.  As usual.
                  */
                 DataHV = newHV();
                 hv_store(DataHV,"Type",4,(newSViv(pGroupParam->Type)),0);
                 hv_store(DataHV,"Parameter",9,(newSViv(pGroupParam->Parameter)),0);
                 hv_store(DataHV,"Group",5,(newRV_noinc((SV*)GroupAV)),0);
                 av_push(DataAV,newRV_noinc((SV*)DataHV));
                 pTemp += pGroupParam->StrucLength;

                 /*
                  * Step 3 of group handling: push the current DataAV
                  * onto the stack along with my current values for
                  * count and parametercount.  Then point DataAV at
                  * the GroupAV, reset count to -1 (we're in a for
                  * loop), and change parametercount to match the
                  * group.  The for loop keeps going, but the elements
                  * we peel off will go into the group's array, not
                  * the top-level one.
                  */
                 av_push(DataAVA, newRV((SV*)DataAV));
                 av_push(DataAVA, newSViv(count));
                 av_push(DataAVA, newSViv(parametercount));
                 DataAV = GroupAV;
                 count = -1; /* -1 because of post-increment in loop header */
                 /* leave abscount alone so that it indicates the full count */
                 parametercount = pGroupParam->ParameterCount;
#endif /* MQCFT_GROUP */
             } else {
                 /* Unknown type - assume basic structure is the same */
                 warn("Unknown PCF parameter %d is of type %d, structure length %d, parameter %d\n", abscount, pStringParam->Type, pStringParam->StrucLength, pStringParam->Parameter);
                 errors++;
                 pTemp += pIntegerParamList->StrucLength;
             }

             /*
              * Step 4 of group handling: if we're about to fall out
              * of the for loop and we have things in the DataAVA
              * array, pop out the previous parametercount, count, and
              * DataAV in reverse order.  Now we won't fall out of the
              * loop.  Do this "while" we're about to fall out (not
              * if, actually) so that if the current group ends at the
              * end of the group above, we don't fall out by accident.
              */
             while (count + 1 == parametercount && av_len(DataAVA) > -1) {
                 SV *sp;
                 sp = av_pop(DataAVA);
                 parametercount = SvIV(sp);
                 SvREFCNT_dec(sp);
                 sp = av_pop(DataAVA);
                 count = SvIV(sp);
                 SvREFCNT_dec(sp);
                 sp = av_pop(DataAVA);
                 DataAV = (AV*)SvRV(sp);
                 SvREFCNT_dec(sp);
             }

         } /* End foreach: PCF parameter */

         SvREFCNT_dec((SV*)DataAVA);

         if (errors) {
             warn("MQDecodePCF: %d unrecognized parameters in data list.\n",
                  errors);
             SvREFCNT_dec((SV*)DataAV);
             XSRETURN_EMPTY;
         }

         XPUSHs(sv_2mortal(newRV_noinc((SV *)DataAV)));
     }


void
MQEncodePCF(Header,ParameterList)
        MQCFH   Header;
        AV*     ParameterList = (AV*)SvRV(ST(1));

        PPCODE:
        {

          IV Type;
          SV *Result, *ParameterResult, **svp;
          AV *ValuesAV, *StringsAV;
#ifdef MQCFT_GROUP
          AV *GroupAVA;
#endif /* MQCFT_GROUP */
          HV *ParameterHV;

          MQCFST *pStringParam;
#ifdef MQCFT_BYTE_STRING
          MQCFBS *pByteStringParam;
#endif
          MQCFSL *pStringParamList;
          MQCFIL *pIntegerParamList;

          MQLONG Parameter, Value, CodedCharSetId, StrucLength;

          STRLEN StringLength, MaxStringLength;

          int index, subindex, typecount;
          char *String, *pString;

          ParameterResult = newSVpv("",0);
#define PCF_DISCARD_RESULT() SvREFCNT_dec(ParameterResult)
#ifdef MQCFT_GROUP
          GroupAVA = newAV();
#define PCF_DISCARD_GROUP() SvREFCNT_dec((SV*)GroupAVA)
#else
#define PCF_DISCARD_GROUP() do { /* nothing to do here */ } while (0)
#endif /* MQCFT_GROUP */

          Header.ParameterCount = av_len(ParameterList) + 1;

          for ( index = 0 ; index <= av_len(ParameterList) ; index++ ) {
              /*
               * Get the next element in the array, and verify that it is
               * a HASH reference.
               */
              svp = av_fetch(ParameterList,index,0);
              if ( !SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVHV ) ) {
                  warn("MQEncodePCF: ParameterList entry '%d' is not a HASH reference.\n",index);
                  PCF_DISCARD_RESULT();
                  PCF_DISCARD_GROUP();
                  XSRETURN_UNDEF;
              }

              ParameterHV = (HV*)SvRV(*svp);

              /*
               * Look for the following keys: String, Value, Strings,
               * Values.  Only one of these is allowed to exist, and its
               * existence determines the type of data structure (MQCF*)
               * we are encoding.
               */
              typecount = 0;

              if (hv_exists(ParameterHV,"Value",5)) {
                  typecount++;
                  Type = MQCFT_INTEGER;
#ifdef MQCFT_INTEGER64
                  svp = hv_fetch(ParameterHV, "Type", 4, 0);
                  if (svp != NULL &&
                      (SvIV(*svp) == MQCFT_INTEGER64 ||
                       SvIV(*svp) == MQCFT_INTEGER64_LIST)) {
                      Type = MQCFT_INTEGER64;
                  }
#endif /* MQCFT_INTEGER64 */
              }

              if (hv_exists(ParameterHV,"String",6)) {
                  typecount++;
                  Type = MQCFT_STRING;
              }

              /* XS doesn't like a blank line fore an ifdef */
#ifdef MQCFT_BYTE_STRING
              if (hv_exists(ParameterHV,"ByteString",10)) {
                  typecount++;
                  Type = MQCFT_BYTE_STRING;
              }
#endif /* MQCFT_BYTE_STRING */

              if (hv_exists(ParameterHV,"Values",6)) {
                  typecount++;
                  Type = MQCFT_INTEGER_LIST;
#ifdef MQCFT_INTEGER64_LIST
                  svp = hv_fetch(ParameterHV, "Type", 4, 0);
                  if (svp != NULL &&
                      (SvIV(*svp) == MQCFT_INTEGER64 ||
                       SvIV(*svp) == MQCFT_INTEGER64_LIST)) {
                      Type = MQCFT_INTEGER64_LIST;
                  }
#endif /* MQCFT_INTEGER64_LIST */
              }

              if (hv_exists(ParameterHV,"Strings",7)) {
                  typecount++;
                  Type = MQCFT_STRING_LIST;
              }

              /* Integer filter (MQ v6 and above) */
#ifdef MQCFT_INTEGER_FILTER
              if (hv_exists(ParameterHV,"ByteStringFilter",16)) {
                  typecount++;
                  Type = MQCFT_BYTE_STRING_FILTER;
              }
              if (hv_exists(ParameterHV,"IntegerFilter",13)) {
                  typecount++;
                  Type = MQCFT_INTEGER_FILTER;
              }
              if (hv_exists(ParameterHV,"StringFilter",12)) {
                  typecount++;
                  Type = MQCFT_STRING_FILTER;
              }
#endif
#ifdef MQCFT_GROUP
              if (hv_exists(ParameterHV,"Group",5)) {
                  typecount++;
                  Type = MQCFT_GROUP;
              }
#endif /* MQCFT_GROUP */

              if (typecount == 0) {
                  warn("MQEncodePCF: ParameterList entry '%d' has none of the following keys:\n",index);
#ifdef MQCFT_BYTE_STRING
                  warn("\tString ByteString Value Strings Values\n");
#else
                  warn("\tString Value Strings Values\n");
#endif /* MQCFT_BYTE_STRING */
#ifdef MQCFT_INTEGER_FILTER
                  warn("\tIntegerFilter StringFilter ByteStringFilter\n");
#endif
#ifdef MQCFT_GROUP
                  warn("\tGroup\n");
#endif /* MQCFT_GROUP */
                  PCF_DISCARD_RESULT();
                  PCF_DISCARD_GROUP();
                  XSRETURN_UNDEF;
              }

              if (typecount > 1) {
                  warn("MQEncodePCF: ParameterList entry '%d' has more than one of the following keys:\n",index);
#ifdef MQCFT_BYTE_STRING
                  warn("\tString ByteString Value Strings Values\n");
#else
                  warn("\tString Value Strings Values\n");
#endif /* MQCFT_BYTE_STRING */
#ifdef MQCFT_INTEGER_FILTER
                  warn("\tIntegerFilter StringFilter ByteStringFilter\n");
#endif
#ifdef MQCFT_GROUP
                  warn("\tGroup\n");
#endif /* MQCFT_GROUP */
                  PCF_DISCARD_RESULT();
                  PCF_DISCARD_GROUP();
                  XSRETURN_UNDEF;
              }

              /*
               * Get the Parameter key from the HASH, which all types
               * must have, and verify that it is an integer.
               */
              svp = hv_fetch(ParameterHV,"Parameter",9,0);
              if (svp == NULL) {
                  warn("MQEncodePCF: ParameterList entry '%d' has no 'Parameter' key.\n",index);
                  PCF_DISCARD_RESULT();
                  PCF_DISCARD_GROUP();
                  XSRETURN_UNDEF;
              }
              Parameter = SvIV(*svp);

              /*
               * Extract the CodedCharSetId key, if it exists, and
               * verify that it is an integer (not much else we can, or
               * want, to do here).
               */
              svp = hv_fetch(ParameterHV,"CodedCharSetId",14,0);
              if (svp != NULL) {
                  CodedCharSetId = SvIV(*svp);
              } else {
                  CodedCharSetId = MQCCSI_DEFAULT;
              }

              /*
               * The rest of the processing of the HASH depends on which
               * Type we have.
               */
              if (Type == MQCFT_INTEGER) {
                  MQCFIN IntegerParam = {MQCFIN_DEFAULT};

                  /*
                   * Extract the Value key, and verify that it is an
                   * integer
                   */
                  svp = hv_fetch(ParameterHV,"Value",5,0);
                  if ( svp == NULL ) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'Value' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  Value = SvIV(*svp);

                  /*
                   * We can now populate the MQCFIN structure, and
                   * concatenate it to the ParameterResult.
                   */
                  IntegerParam.Parameter = Parameter;
                  IntegerParam.Value = Value;
                  sv_catpvn(ParameterResult,(char *)&IntegerParam,MQCFIN_STRUC_LENGTH);
                  /* warn("Parameter %d is integer; param %d, value %d\n", index, Parameter, Value); */
              } else if (Type == MQCFT_STRING) {
                  /*
                   * Extract the String, which must obviously be a string
                   */
                  svp = hv_fetch(ParameterHV,"String",6,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'String' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  if (!SvPOK(*svp)) {
                      warn("MQEncodePCF: ParameterList entry '%d' String key is not a string.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  String = SvPV(*svp,StringLength);

                  /*
                   * The total size of the structure needs to be a multiple
                   * of 4 (or some buggy IBM code will vomit somewhere, I'm
                   * sure...)
                   */
                  StrucLength = MQCFST_STRUC_LENGTH_FIXED + StringLength;
                  if ( StrucLength % 4 )
                      StrucLength += 4 - (StrucLength%4);

                  /*
                   * Create the MQCFST structure, and concatenate it to the
                   * ParameterResult
                   */
                  if ((pStringParam = (MQCFST *)malloc(StrucLength)) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pStringParam->Type            = MQCFT_STRING;
                  pStringParam->Parameter       = Parameter;
                  pStringParam->CodedCharSetId  = CodedCharSetId;
                  pStringParam->StringLength    = StringLength;
                  pStringParam->StrucLength     = StrucLength;

                  memset(pStringParam->String,'\0',StrucLength - MQCFST_STRUC_LENGTH_FIXED);
                  strncpy(pStringParam->String,String,StringLength);
                  sv_catpvn(ParameterResult, (char *)pStringParam, pStringParam->StrucLength);
                  free(pStringParam);
#ifdef MQCFT_BYTE_STRING
              } else if (Type == MQCFT_BYTE_STRING) {
                  /*
                   * Extract the ByteString, which must be a string
                   */
                  svp = hv_fetch(ParameterHV, "ByteString", 10, 0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'ByteString' key.\n", index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  if (!SvPOK(*svp)) {
                      warn("MQEncodePCF: ParameterList entry '%d' ByteString key is not a string.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  String = SvPV(*svp, StringLength);

                  /*
                   * The total size of the structure needs to be a multiple
                   * of 4 (or some buggy IBM code will vomit somewhere, I'm
                   * sure...)
                   */
                  StrucLength = MQCFBS_STRUC_LENGTH_FIXED + StringLength;
                  if ( StrucLength % 4 )
                      StrucLength += 4 - (StrucLength%4);

                  /*
                   * Create the MQCFBS structure, and concatenate it to the
                   * ParameterResult
                   */
                  if ((pByteStringParam = (MQCFBS *)malloc(StrucLength)) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pByteStringParam->Type = MQCFT_BYTE_STRING;
                  pByteStringParam->Parameter = Parameter;
                  pByteStringParam->StringLength = StringLength;
                  pByteStringParam->StrucLength = StrucLength;

                  memset(pByteStringParam->String, '\0', StrucLength - MQCFBS_STRUC_LENGTH_FIXED);
                  memcpy(pByteStringParam->String, String, StringLength);
                  sv_catpvn(ParameterResult, (char *)pByteStringParam, pByteStringParam->StrucLength);
                  free(pByteStringParam);
#endif /* MQCFT_BYTE_STRING */
              } else if (Type == MQCFT_INTEGER_LIST) {
                  /*
                   * Extract the Values key, and verify that it is an ARRAY
                   * reference
                   */
                  svp = hv_fetch(ParameterHV,"Values",6,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'Values' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  if (!SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVAV)) {
                      warn("MQEncodePCF: ParameterList entry '%d' Values key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  ValuesAV = (AV*)SvRV(*svp);
                  if (av_len(ValuesAV) == -1) {
                      warn("MQEncodePCF: ParameterList entry '%d' Values ARRAY is empty.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  /*
                   * Calculate the length of the structure
                   */
                  StrucLength = (MQLONG)(MQCFIL_STRUC_LENGTH_FIXED +
                                         ( sizeof(MQLONG) * (av_len(ValuesAV) + 1)));

                  /*
                   * Create the MQCFIL structure...
                   */
                  if ((pIntegerParamList = (MQCFIL *)malloc(StrucLength) ) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pIntegerParamList->Type = MQCFT_INTEGER_LIST;
                  pIntegerParamList->StrucLength = StrucLength;
                  pIntegerParamList->Parameter = Parameter;
                  pIntegerParamList->Count = av_len(ValuesAV) + 1;

                  for (subindex = 0 ; subindex <= av_len(ValuesAV) ; subindex++) {
                      svp = av_fetch(ValuesAV,subindex,0);
                      if (svp == NULL) {
                          warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' Values entry '%d'.\n", index,subindex);
                          free(pIntegerParamList);
                          PCF_DISCARD_RESULT();
                          PCF_DISCARD_GROUP();
                          XSRETURN_UNDEF;
                      }
                      pIntegerParamList->Values[subindex] = SvIV(*svp);
                  }
                  sv_catpvn(ParameterResult, (char *)pIntegerParamList, StrucLength);
                  free(pIntegerParamList);
#ifdef MQCFT_INTEGER64
              } else if (Type == MQCFT_INTEGER64) {
                  MQCFIN64 Integer64Param = {MQCFIN64_DEFAULT};
                  /*
                   * Extract the Value key, and verify that it is an integer
                   */
                  svp = hv_fetch(ParameterHV,"Value",5,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'Value' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  Integer64Param.Parameter = Parameter;
                  if (sizeof(IV) >= 8 || SvIOKp(*svp)) {
                      Integer64Param.Value = (MQINT64)SvIV(*svp);
                  } else {
                      char *val = SvPV(*svp, StringLength);
                      if (!sscanf(val, "%" SCNdLEAST64, &Integer64Param.Value)) {
                          /* um...plan?! */
                      }
                  }

                  sv_catpvn(ParameterResult,(char *)&Integer64Param,MQCFIN64_STRUC_LENGTH);
#endif /* MQCFT_INTEGER64 */
#ifdef MQCFT_INTEGER64_LIST
              } else if (Type == MQCFT_INTEGER64_LIST) {
                  MQCFIL64 *pInteger64ParamList;
                  /*
                   * Extract the Values key, and verify that it is an ARRAY
                   * reference
                   */
                  svp = hv_fetch(ParameterHV,"Values",6,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'Values' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  if (!SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVAV)) {
                      warn("MQEncodePCF: ParameterList entry '%d' Values key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  ValuesAV = (AV*)SvRV(*svp);
                  if (av_len(ValuesAV) == -1) {
                      warn("MQEncodePCF: ParameterList entry '%d' Values ARRAY is empty.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  /*
                   * Calculate the length of the structure
                   */
                  StrucLength = (MQLONG)(MQCFIL_STRUC_LENGTH_FIXED +
                                         ( sizeof(MQINT64) * (av_len(ValuesAV) + 1)));

                  /*
                   * Create the MQCFIL64 structure...
                   */
                  if ((pInteger64ParamList = (MQCFIL64 *)malloc(StrucLength) ) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pInteger64ParamList->Type = MQCFT_INTEGER64_LIST;
                  pInteger64ParamList->StrucLength = StrucLength;
                  pInteger64ParamList->Parameter = Parameter;
                  pInteger64ParamList->Count = av_len(ValuesAV) + 1;

                  for (subindex = 0 ; subindex <= av_len(ValuesAV) ; subindex++) {
                      svp = av_fetch(ValuesAV,subindex,0);
                      if (svp == NULL) {
                          warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' Values entry '%d'.\n", index,subindex);
                          free(pInteger64ParamList);
                          PCF_DISCARD_RESULT();
                          PCF_DISCARD_GROUP();
                          XSRETURN_UNDEF;
                      }
                      if (sizeof(IV) >= 8 || SvIOKp(*svp)) {
                          pInteger64ParamList->Values[subindex] = (MQINT64)SvIV(*svp);
                      } else {
                          char *val = SvPV(*svp, StringLength);
                          if (!sscanf(val, "%" SCNdLEAST64, &pInteger64ParamList->Values[subindex])) {
                              /* um...plan?! */
                          }
                      }
                  }
                  sv_catpvn(ParameterResult, (char *)pInteger64ParamList, StrucLength);
                  free(pInteger64ParamList);
#endif /* MQCFT_INTEGER64_LIST */
              } else if (Type == MQCFT_STRING_LIST) {
                  /*
                   * Extract the Strings key and verify that it is an ARRAY
                   * reference
                   */
                  svp = hv_fetch(ParameterHV,"Strings",7,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'Strings' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  if (!SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVAV)) {
                      warn("MQEncodePCF: ParameterList entry '%d' Strings key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  StringsAV = (AV*)SvRV(*svp);
                  if ( av_len(StringsAV) == -1 ) {
                      warn("MQEncodePCF: ParameterList entry '%d' Strings ARRAY is empty.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  /*
                   * Calculate the length of the structure, which means
                   * figuring out the length of the longest string.
                   */
                  MaxStringLength = 0;
                  for (subindex = 0; subindex <= av_len(StringsAV); subindex++) {
                      svp = av_fetch(StringsAV,subindex,0);
                      if ( svp == NULL || !SvPOK(*svp) ) {
                          warn("MQEncodePCF: ParameterList entry '%d' Strings entry '%d' is not a string.\n", index,subindex);
                          PCF_DISCARD_RESULT();
                          PCF_DISCARD_GROUP();
                          XSRETURN_UNDEF;
                      }
                      String = SvPV(*svp,StringLength);
                      if (StringLength > MaxStringLength)
                          MaxStringLength = StringLength;
                  }

                  StrucLength = MQCFSL_STRUC_LENGTH_FIXED +
                      (MaxStringLength * (av_len(StringsAV) + 1));
                  if (StrucLength % 4)
                      StrucLength += 4 - (StrucLength%4);

                  /*
                   * Now allocate the memory for the MQCFSL, and populate
                   * it with data
                   */
                  if ((pStringParamList = (MQCFSL *)malloc(StrucLength)) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pStringParamList->Type = MQCFT_STRING_LIST;
                  pStringParamList->StrucLength = StrucLength;
                  pStringParamList->Parameter = Parameter;
                  pStringParamList->CodedCharSetId = CodedCharSetId;
                  pStringParamList->Count = av_len(StringsAV) + 1;
                  pStringParamList->StringLength = MaxStringLength;

                  pString = (char *)pStringParamList->Strings;
                  memset(pString,'\0',StrucLength - MQCFSL_STRUC_LENGTH_FIXED);

                  for (subindex = 0; subindex <= av_len(StringsAV); subindex++) {
                      svp = av_fetch(StringsAV,subindex,0);
                      String = SvPV(*svp,StringLength);
                      strncpy(pString,String,StringLength);
                      pString += MaxStringLength;
                  }
                  sv_catpvn(ParameterResult, (char *)pStringParamList, StrucLength);
                  free(pStringParamList);
#ifdef MQCFT_INTEGER_FILTER
              } else if (Type == MQCFT_BYTE_STRING_FILTER) {
                  MQCFBF *pByteStringFilter;

                  /*
                   * Extract the ByteStringFilter key, and verify that it is an
                   * array reference with three elements (size 2)
                   */
                  svp = hv_fetch(ParameterHV,"ByteStringFilter",16,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'ByteStringFilter' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  if (!SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVAV)) {
                      warn("MQEncodePCF: ParameterList entry '%d' ByteStringFilter key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  ValuesAV = (AV*)SvRV(*svp);
                  if (av_len(ValuesAV) != 2) {
                      warn("MQEncodePCF: ParameterList entry '%d' ByteStringFilter ARRAY does not have three elements [ Parameter, Operator, Value ].\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  /*
                   * Get the byte string value, which we need to size the
                   * MQCFBF data structure.
                   */
                  svp = av_fetch(ValuesAV,2,0);
                  if (svp == NULL || !SvPOK(*svp)) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' ByteStringFilter entry '%d' (FilterValue).\n", index,2);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  String = SvPV(*svp,StringLength);

                  /*
                   * We can now allocate and fill the MQCFIF structure,
                   * then concatenate it to the ParameterResult.
                   */
                  StrucLength = MQCFBF_STRUC_LENGTH_FIXED + StringLength;
                  if (StrucLength % 4)
                      StrucLength += 4 - (StrucLength%4);
                  if ((pByteStringFilter = (MQCFBF *)malloc(StrucLength)) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pByteStringFilter->Type = MQCFT_BYTE_STRING_FILTER;
                  pByteStringFilter->StrucLength = StrucLength;
                  pByteStringFilter->FilterValueLength = StringLength;
                  memset(pByteStringFilter->FilterValue, '\0', StrucLength - MQCFBF_STRUC_LENGTH_FIXED);
                  memcpy(pByteStringFilter->FilterValue, String, StringLength);

                  svp = av_fetch(ValuesAV,0,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' ByteStringFilter entry '%d' (Parameter).\n", index,0);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  pByteStringFilter->Parameter = SvIV(*svp);

                  svp = av_fetch(ValuesAV,1,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' ByteStringFilter entry '%d' (Operator).\n", index,1);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  pByteStringFilter->Operator = SvIV(*svp);

                  sv_catpvn(ParameterResult,(char *)pByteStringFilter,StrucLength);
                  /* warn("Have ByteStringFilter at %d with parameter %d, Operator %d, FilterValue %s\n", index, pByteStringFilter->Parameter, pByteStringFilter->Operator, pByteStringFilter->FilterValue); */
                  free(pByteStringFilter);
              } else if (Type == MQCFT_INTEGER_FILTER) {
                  MQCFIF IntegerFilter = {MQCFIF_DEFAULT};

                  /*
                   * Extract the IntegerFilter key, and verify that it is an
                   * array reference with three elements (size 2)
                   */
                  svp = hv_fetch(ParameterHV,"IntegerFilter",13,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'IntegerFilter' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  if (!SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVAV)) {
                      warn("MQEncodePCF: ParameterList entry '%d' IntegerFilter key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  ValuesAV = (AV*)SvRV(*svp);
                  if (av_len(ValuesAV) != 2) {
                      warn("MQEncodePCF: ParameterList entry '%d' IntegerFilter ARRAY does not have three elements [ Parameter, Operator, Value ].\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  /*
                   * We can now populate the MQCFIF structure, and
                   * concatenate it to the ParameterResult.
                   */
                  svp = av_fetch(ValuesAV,0,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' IntegerFilter entry '%d' (Parameter).\n", index,0);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  IntegerFilter.Parameter = SvIV(*svp);

                  svp = av_fetch(ValuesAV,1,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' IntegerFilter entry '%d' (Operator).\n", index,1);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  IntegerFilter.Operator = SvIV(*svp);

                  svp = av_fetch(ValuesAV,2,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' IntegerFilter entry '%d' (FilterValue).\n", index,2);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  IntegerFilter.FilterValue = SvIV(*svp);

                  sv_catpvn(ParameterResult,(char *)&IntegerFilter,MQCFIF_STRUC_LENGTH);
                  /* warn("Have IntegerFilter at %d with parameter %d, Operator %d, FilterValue %d\n", index, IntegerFilter.Parameter, IntegerFilter.Operator, IntegerFilter.FilterValue); */
              } else if (Type == MQCFT_STRING_FILTER) {
                  MQCFSF *pStringFilter;

                  /*
                   * Extract the StringFilter key, and verify that it is an
                   * array reference with three elements (size 2)
                   */
                  svp = hv_fetch(ParameterHV,"StringFilter",12,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'StringFilter' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  if (!SvROK(*svp) || ( SvROK(*svp) && SvTYPE(SvRV(*svp)) != SVt_PVAV)) {
                      warn("MQEncodePCF: ParameterList entry '%d' StringFilter key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  ValuesAV = (AV*)SvRV(*svp);
                  if (av_len(ValuesAV) != 2) {
                      warn("MQEncodePCF: ParameterList entry '%d' StringFilter ARRAY does not have three elements [ Parameter, Operator, Value ].\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  /*
                   * Get the string value, which we need to size the
                   * MQCFSF data structure.
                   */
                  svp = av_fetch(ValuesAV,2,0);
                  if (svp == NULL || !SvPOK(*svp)) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' StringFilter entry '%d' (FilterValue).\n", index,2);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  String = SvPV(*svp,StringLength);

                  /*
                   * We can now allocate and fill the MQCFSF structure,
                   * then concatenate it to the ParameterResult.
                   */
                  StrucLength = MQCFSF_STRUC_LENGTH_FIXED + StringLength;
                  if (StrucLength % 4)
                      StrucLength += 4 - (StrucLength%4);
                  if ((pStringFilter = (MQCFSF *)malloc(StrucLength)) == NULL) {
                      perror("Unable to allocate memory");
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  pStringFilter->Type = MQCFT_STRING_FILTER;
                  pStringFilter->StrucLength = StrucLength;
                  pStringFilter->CodedCharSetId = CodedCharSetId;
                  pStringFilter->FilterValueLength = StringLength;
                  memset(pStringFilter->FilterValue, '\0', StrucLength - MQCFSF_STRUC_LENGTH_FIXED);
                  memcpy(pStringFilter->FilterValue, String, StringLength);

                  svp = av_fetch(ValuesAV,0,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' StringFilter entry '%d' (Parameter).\n", index,0);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  pStringFilter->Parameter = SvIV(*svp);

                  svp = av_fetch(ValuesAV,1,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: Unable to retrieve ParameterList entry '%d' StringFilter entry '%d' (Operator).\n", index,1);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  pStringFilter->Operator = SvIV(*svp);

                  sv_catpvn(ParameterResult,(char *)pStringFilter,StrucLength);
                  /* warn("Have StringFilter at %d with parameter %d, Operator %d, FilterValue %s\n", index, pStringFilter->Parameter, pStringFilter->Operator, pStringFilter->FilterValue); */
                  free(pStringFilter);
#endif /* MQCFT_INTEGER_FILTER */
#ifdef MQCFT_GROUP
              } else if (Type == MQCFT_GROUP) {
                  MQCFGR GroupParam = {MQCFGR_DEFAULT};
                  AV *GroupAV;

                  svp = hv_fetch(ParameterHV,"Group",5,0);
                  if (svp == NULL) {
                      warn("MQEncodePCF: ParameterList entry '%d' has no 'Group' key.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
                      warn("MQEncodePCF: ParameterList entry '%d' Group key is not an ARRAY reference.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }
                  GroupAV = (AV*)SvRV(*svp);
                  if (av_len(GroupAV) == -1) {
                      warn("MQEncodePCF: ParameterList entry '%d' Group ARRAY is empty.\n",index);
                      PCF_DISCARD_RESULT();
                      PCF_DISCARD_GROUP();
                      XSRETURN_UNDEF;
                  }

                  GroupParam.Parameter = Parameter;
                  GroupParam.ParameterCount = av_len(GroupAV) + 1;
                  sv_catpvn(ParameterResult,(char *)&GroupParam,MQCFGR_STRUC_LENGTH);
                  av_push(GroupAVA, newRV((SV*)ParameterList));
                  av_push(GroupAVA, newSViv(index));
                  index = -1; /* -1 because of post-increment in loop header */
                  ParameterList = GroupAV;
#endif /* MQCFT_GROUP */
              } else {
                  warn("MQEncodePCF: ParameterList entry '%d' is of Type '%d', not sure how to handle this\n", index, Type);
                  PCF_DISCARD_RESULT();
                  PCF_DISCARD_GROUP();
                  XSRETURN_UNDEF;
              }
#ifdef MQCFT_GROUP
              while (index >= av_len(ParameterList) && av_len(GroupAVA) > -1) {
                  SV *sp;
                  sp = av_pop(GroupAVA);
                  index = SvIV(sp);
                  SvREFCNT_dec(sp);
                  sp = av_pop(GroupAVA);
                  ParameterList = (AV*)SvRV(sp);
                  SvREFCNT_dec(sp);
              }
#endif /* MQCFT_GROUP */
          }

          Result = newSVpv((char *)&Header, Header.StrucLength);
          sv_catsv(Result,ParameterResult);
          PCF_DISCARD_RESULT();
          PCF_DISCARD_GROUP();
          XPUSHs(sv_2mortal(Result));
        }
