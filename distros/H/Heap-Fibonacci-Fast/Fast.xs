/*
Copyright (c) 2009 by Sergey Aleynikov.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "fib.c"

#define heapnew(type)							\
		SV* obj_ref;							\
		SV* obj;								\
		struct fibheap* heap;					\
												\
		obj_ref= newSViv(0);					\
		obj = newSVrv(obj_ref, class);			\
												\
		heap = fh_makeheap(type);				\
		sv_setiv(obj, (IV)heap);				\
		SvREADONLY_on(obj);						\


MODULE = Heap::Fibonacci::Fast		PACKAGE = Heap::Fibonacci::Fast

PROTOTYPES: DISABLE

SV *
new_minheap(class)
		const char* class
	CODE:
		heapnew(min_keyed);
		RETVAL = obj_ref;

	OUTPUT:
		RETVAL

SV *
new_maxheap(class)
		const char* class
	CODE:
		heapnew(max_keyed);
		RETVAL = obj_ref;

	OUTPUT:
		RETVAL

SV *
new_codeheap(class, code)
		const char* class
		SV* code
	CODE:
		if(!SvOK(code) || !SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV){
			croak("You must supply a valid coderef to constructor");
		}

		heapnew(callback);

		heap->comparator = newSVsv(code);

		RETVAL = obj_ref;

	OUTPUT:
		RETVAL

void
DESTROY(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));

		fh_emptyheap(heap);
		fh_destroyheap(heap);

SV *
extract_top(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));

		SV* min = (SV*)fh_extractmin(heap);
		if(min == NULL){
			RETVAL = &PL_sv_undef;
		}else{
			RETVAL = min;
		}
	OUTPUT:
		RETVAL

SV *
top(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));

		if(heap->fh_min == NULL){
			RETVAL = &PL_sv_undef;
		}else{
			SV* min = heap->fh_min->fhe_data;
			SvREFCNT_inc(min);
			RETVAL = min;
		}

	OUTPUT:
		RETVAL

int
count(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));
		RETVAL = heap->fh_n;
	OUTPUT:
		RETVAL

SV*
top_key(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));

		if(heap->fh_keys == callback){
			croak("top_key() is only applicable for keyed heaps");
		}

		if(heap->fh_min == NULL){
			RETVAL = &PL_sv_undef;
		}else{
			RETVAL = newSViv(heap->fh_min->fhe_key);
		}

	OUTPUT:
		RETVAL

void
remove(obj, elem)
		SV* obj
		SV* elem
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));

		if (!SvOK(elem))
			croak("Undef supplied for remove()");

		fh_deleteel(heap, (struct fibheap_el *)SvIV(elem));

void
extract_upto(obj, upto_key)
		SV* obj
		SV* upto_key
	PPCODE:
		if(!SvOK(upto_key)){
			croak("Undef supplied as key for extract_upto()");
		}

		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));
		int upto_intkey;

		switch (heap->fh_keys) {
			case min_keyed:
				upto_intkey = SvIV(upto_key);
				while(
					heap->fh_min != NULL
						&&
					int_key_min_compare(heap->fh_min->fhe_key, upto_intkey) <= 0
				){
					XPUSHs(sv_2mortal((SV*)fh_extractmin(heap)));
				}
				break;

			case max_keyed:
				upto_intkey = SvIV(upto_key);
				while(
					heap->fh_min != NULL
						&&
					int_key_max_compare(heap->fh_min->fhe_key, upto_intkey) <= 0
				){
					XPUSHs(sv_2mortal((SV*)fh_extractmin(heap)));
				}
				break;

			case callback:
				while(
					heap->fh_min != NULL
						&&
					data_compare(heap, heap->fh_min->fhe_data, upto_key) <= 0
				){
					XPUSHs(sv_2mortal((SV*)fh_extractmin(heap)));
					PUTBACK;
				}
				break;
		}

void
key_insert(obj, ...)
		SV* obj
	PPCODE:
		struct fibheap* heap;
		SV *ret, *elem;
		int key;
		I32 gimme;
		int i;

		heap = (struct fibheap*)SvIV(SvRV(obj));
		if(heap->fh_keys == callback){
			croak("key_insert() is only applicable for keyed heaps");
		}

		items -= 1;
		if (items == 0){
			XSRETURN_EMPTY;
		}

		if (items % 2 != 0){
			croak("Odd number of parameters supplied for key_insert()");
		}

		gimme = GIMME_V;
		for(i = 0; i < items; i += 2){
			key = SvIV(ST(i + 1));
			elem = ST(i + 2);

			if(!SvOK(elem)){
				croak("Undef supplied as value for key_insert()");
			}

			SvREFCNT_inc(elem);
			if ((gimme == G_ARRAY) || (i == 0 && gimme == G_SCALAR)){
				ret = newSViv(fh_insertkey(heap, key, elem));
				SvREADONLY_on(ret);
				XPUSHs(sv_2mortal(ret));
			}else{
				(void)fh_insertkey(heap, key, elem);
			}
		}

void
insert(obj, ...)
		SV* obj
	PPCODE:
		struct fibheap* heap;
		SV *ret, *elem;
		I32 gimme;
		int i;

		items -= 1;
		if (items == 0){
			XSRETURN_EMPTY;
		}

		heap = (struct fibheap*)SvIV(SvRV(obj));
		if(heap->fh_keys != callback){
			croak("insert() is not applicable for keyed heaps");
		}

		gimme = GIMME_V;
		for(i = 0; i < items; i++){
			elem = ST(i + 1);

			if(!SvOK(elem)){
				croak("Undef supplied as value for insert()");
			}

			SvREFCNT_inc(elem);
			if ((gimme == G_ARRAY) || (i == 0 && gimme == G_SCALAR)){
				ret = newSViv(fh_insert(heap, elem));
				SvREADONLY_on(ret);
				XPUSHs(sv_2mortal(ret));
			}else{
				(void)fh_insert(heap, elem);
			}
		}

void
clear(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));

		fh_emptyheap(heap);

void
absorb(to, from)
		SV* to
		SV* from
	CODE:
		struct fibheap* heap_to = (struct fibheap*)SvIV(SvRV(to));
		struct fibheap* heap_from = (struct fibheap*)SvIV(SvRV(from));

		if(heap_from->fh_keys != heap_to->fh_keys)
			croak("Can't union heaps of different types");

		if(heap_from->fh_keys == callback)
			if(SvRV(heap_from->comparator) != SvRV(heap_to->comparator))
				croak("Can't union heaps with different compare callbacks");

		fh_union(heap_to, heap_from);
		SvSetSV(from, &PL_sv_undef);

SV*
get_type(obj)
		SV* obj
	CODE:
		struct fibheap* heap = (struct fibheap*)SvIV(SvRV(obj));
		switch (heap->fh_keys) {
			case min_keyed:
				RETVAL = newSVpvn("min", 3);
				break;

			case max_keyed:
				RETVAL = newSVpvn("max", 3);
				break;

			case callback:
				RETVAL = newSVpvn("code", 4);
				break;
		}

	OUTPUT:
		RETVAL


