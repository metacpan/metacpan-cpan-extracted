
/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */

#ifndef _Misc_Types_h_
#define _Misc_Types_h_

#ifndef PerlGtkDeclareFunc
#include "PerlGtkInt.h"
#endif

#include <gtk/gtktypeutils.h>

struct opts { int value; char * name; };
   
PerlGtkDeclareFunc(void, UnregisterMisc)(HV * hv_object, void * misc_object);
PerlGtkDeclareFunc(void, RegisterMisc)(HV * hv_object, void * misc_object);
PerlGtkDeclareFunc(HV *, RetrieveMisc)(void * gtk_object);

PerlGtkDeclareFunc(SV *, newSVMiscRef)(void * object, char * classname, int * newref);
PerlGtkDeclareFunc(void *, SvMiscRef)(SV * o, char * classname);

PerlGtkDeclareFunc(void, CroakOpts)(char * name, char * value, struct opts * o);
PerlGtkDeclareFunc(long, SvOpt)(SV * name, char * optname, struct opts * o);
PerlGtkDeclareFunc(SV *, newSVOpt)(long value, char * optname, struct opts * o);

PerlGtkDeclareFunc(long, SvOptFlags)(SV * name, char * optname, struct opts * o);
PerlGtkDeclareFunc(SV *, newSVOptFlags)(long value, char * optname, struct opts * o);

PerlGtkDeclareFunc(long, SvOptsHash)(SV * name, char * optname, HV * o);
PerlGtkDeclareFunc(SV *, newSVOptsHash)(long value, char * optname, HV * o);
PerlGtkDeclareFunc(long, SvFlagsHash)(SV * name, char * optname, HV * o);
PerlGtkDeclareFunc(SV *, newSVFlagsHash)(long value, char * optname, HV * o);

PerlGtkDeclareFunc (SV *, newSVDefEnumHash)(GtkType type, long value);
PerlGtkDeclareFunc (SV *, newSVDefFlagsHash)(GtkType type, long value);
PerlGtkDeclareFunc (long, SvEFValueLookup)(GtkEnumValue * vals, char* name, GtkType type);
PerlGtkDeclareFunc (long, SvDefEnumHash)(GtkType type, SV *name);
PerlGtkDeclareFunc (long, SvDefFlagsHash)(GtkType type, SV *name);
PerlGtkDeclareVar(int, pgtk_use_minus);
PerlGtkDeclareVar(int, pgtk_use_array);

PerlGtkDeclareFunc(void *, pgtk_alloc_temp)(int length);


#define PackCallbackST(av, first)							\
		if (SvRV(ST(first)) && (SvTYPE(SvRV(ST(first))) == SVt_PVAV)) {		\
			int i;								\
			AV * x = (AV*)SvRV(ST(first));					\
			for(i=0;i<=av_len(x);i++) {					\
				av_push(av, newSVsv(*av_fetch(x, i, 0)));		\
			}								\
		} else {								\
			int i;								\
			for(i=first;i<items;i++)					\
				av_push(av, newSVsv(ST(i)));				\
		}

#define PackCallback(av, sv)								\
		if (SvRV(sv) && (SvTYPE(SvRV(sv)) == SVt_PVAV)) {			\
			int i;								\
			AV * x = (AV*)SvRV(sv);						\
			for(i=0;i<=av_len(x);i++) {					\
				av_push(av, newSVsv(*av_fetch(x, i, 0)));		\
			}								\
		} else {								\
			av_push(av, newSVsv(sv));					\
		}

#endif /*_Misc_Types_h_*/

