
#include "EXTERN.h"
#include "matrix.h"
#include "perl.h"
#include "XSUB.h"
#include "../Core/pdl.h"
#include "../Core/pdlcore.h"
#include "./mespdl.h"
#include "./p_funcs.h"
#include "./Meschach.h"

#define XOK(a) ((a)?1:0)

void p_sv( SV *a ){							/* Prints types IV, NV, PV 4 */
	STRLEN l;
	char* s;
	int i;
	SV* b;
	printf(" (");

	if(SvIOK(a)) printf(" I %i ",SvIV(a));
	else if(SvNOK(a))	printf(" N %lf ",SvNV(a));

	if(SvPOK(a)) {
		s= SvPV(a,l);
		printf(" P %p %i : ",s,l);
		for(i=0;i<l;i++)	printf("%2x,",(unsigned char)s[i]);
	}
	printf(")");
}

void p_av( AV *a ){
 
	I32 i,l;
	SV **b;
	printf("( AV ");
	l= av_len(a);
	printf(" ( %i : ",l);
	for(i=0;i<=l;i++){
		b= av_fetch(a,i,(I32)0);
		if(b) p_any(*b);
		else 	printf("bug in p_av \n");
	}
	printf(")");

}

void p_hv( HV *a ){
	HE *b;
	char* c;
	int d;
	SV* e;
	printf("( HV ");
	if( hv_iterinit(a) ){
		while( b= hv_iternext( a ) ){
			c= hv_iterkey(b,(I32*)&d);
			e= hv_iterval(a,b);
			printf("\n \"%s\" => %p ",c,e);
			p_any(e);
		}
	}
	printf(")");
}

void p_any( SV* a ){
	int i= SvTYPE(a);
	SV* b;

	printf(" TYPE : %i ",i);
	if(SvROK(a)){
		printf("REF ");
		b= SvRV(a);
		p_any(b);
	} 
	else if( i==SVt_IV || i==SVt_NV || i==SVt_PV )	p_sv(a);
	else if ( i==SVt_PVAV )		p_av((AV*)a);
	else if ( i==SVt_PVHV )		p_hv((HV*)a);
	else 	{	printf(" OTHER "); p_sv(a); }; 
	printf("\n");
}

void p_pdl(pdl *a) {

	int i;
	HV *h,*g;
	HV **gg;

	if(a==NULL)
		croak(" p_pdl ( NULL ) ");

	printf("######## p_pdl (address= %p )\n  sv=%p \n  datatype=%d \n"
				 "  data=%p \n  nvals=%d \n  offs=%d  \n"
				 "  ndims=%d \n  dims= ",
				 a,a->sv,a->datatype, a->data, a->nvals, a->offs, a->ndims ); 

	for(i=0;i<a->ndims;i++)
		printf("%d ",a->dims[i]);
	
	printf("\n  incs= ");
	for(i=0;i<a->ndims;i++)
		printf("%d ",a->incs[i]);

	printf("\n  nthreaddims=%d",a->nthreaddims);
	if(a->nthreaddims) { 

		printf("\n  threaddims= ");
		for(i=0;i<a->nthreaddims;i++)
			printf("%d ", a->threaddims[i]);

		printf("\n  threadincs= ");
		for(i=0;i<a->nthreaddims;i++)
			printf("%d ",a->threadincs[i]);

	}
	printf("\n########\n sv follows :");
	
	p_any(a->sv);

}

