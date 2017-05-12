#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <tamu_anova/tamu_anova.h>

#define anova_fixed anova_fixed
#define anova_random anova_random
#define anova_mixed anova_mixed

#include "const-c.inc"

#define my_hv_fetch(fname, hv, key, keylen, structure, sv, op) \
	sv = hv_fetch(hv, #key, keylen, 0); \
	if (sv != NULL) { \
		structure.key = op(*sv); \
	} else { \
		croak("Math::TamuAnova::" #fname ": no '" #key "' key"); \
		/* XSRETURN_UNDEF; */ \
	}

typedef long couple_t[2];

MODULE = Math::TamuAnova		PACKAGE = Math::TamuAnova		

INCLUDE: const-xs.inc

void
printtable(table)
	HV * table
    PREINIT:
	struct tamu_anova_table	t;
	SV		**sv;
    CODE:
	my_hv_fetch(printtable, table, dfTr, 4, t, sv, SvIV);
	my_hv_fetch(printtable, table, dfE , 3, t, sv, SvIV);
	my_hv_fetch(printtable, table, dfT , 3, t, sv, SvIV);
	my_hv_fetch(printtable, table, SSTr, 4, t, sv, SvNV);
	my_hv_fetch(printtable, table, SSE , 3, t, sv, SvNV);
	my_hv_fetch(printtable, table, SST , 3, t, sv, SvNV);
	my_hv_fetch(printtable, table, MSTr, 4, t, sv, SvNV);
	my_hv_fetch(printtable, table, MSE , 3, t, sv, SvNV);
	my_hv_fetch(printtable, table, F   , 1, t, sv, SvNV);
	my_hv_fetch(printtable, table, p   , 1, t, sv, SvNV);
	tamu_anova_printtable(t);
	

void
printtable_twoway(table)
	HV * table
    PREINIT:
	struct tamu_anova_table_twoway	t;
	SV		**sv;
    CODE:
	my_hv_fetch(printtable_twoway, table, dfB , 3, t, sv, SvIV);
	my_hv_fetch(printtable_twoway, table, dfAB, 4, t, sv, SvIV);
	my_hv_fetch(printtable_twoway, table, dfE , 3, t, sv, SvIV);
	my_hv_fetch(printtable_twoway, table, dfT , 3, t, sv, SvIV);
	my_hv_fetch(printtable_twoway, table, SSA , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, MSA , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, FA  , 2, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, pA  , 2, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, SSB , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, MSB , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, FB  , 2, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, pB  , 2, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, SSAB, 4, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, MSAB, 4, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, FAB , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, pAB , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, SSE , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, MSE , 3, t, sv, SvNV);
	my_hv_fetch(printtable_twoway, table, SST , 3, t, sv, SvNV);
	tamu_anova_printtable_twoway(t);

HV *
anova(data, factor, J)
	AV * data;
	AV * factor
	int J
    PREINIT:
    	double *d=NULL;
	long *f=NULL;
	int i;
	int I;
	struct tamu_anova_table t;
    CODE:
	I=av_len(data)+1;
	if (av_len(factor) != I-1) {
		fprintf(stderr,
		"Math::TamuAnova::anova: data and factor are not the same size!\n");
		XSRETURN_UNDEF;
	}
	if (I <= 0) {
		fprintf(stderr, "Math::TamuAnova::anova: null sized array\n");
		XSRETURN_UNDEF;
	}
	d=malloc(sizeof(double)*I);
	f=malloc(sizeof(long)*I);
	if (f==NULL || d==NULL) {
		fprintf(stderr, "Math::TamuAnova::anova: cannot allocate memory\n");
		free(d);
		free(f);
		XSRETURN_UNDEF;
	}
	for (i=0; i<I; i++) {
		int val;
		d[i]=SvNV(*av_fetch(data, i, 0));
		val=SvIV(*av_fetch(factor, i, 0));
		if (val < 1 || val > J) {
			fprintf(stderr, 
				"Math::TamuAnova::anova: factor[%i]=%i!\n",
				i, val);
			free(d);
			free(f);
			XSRETURN_UNDEF;
		}
		f[i]=val;
	}
	t=tamu_anova(d,f,I,J);
	
	free(d);
	free(f);
	
	//rh = (HV *)sv_2mortal((SV *)newHV());
	RETVAL = newHV();
	sv_2mortal((SV *)RETVAL);
	hv_store(RETVAL, "dfTr", 4, newSViv(t.dfTr), 0);
	hv_store(RETVAL, "dfE" , 3, newSViv(t.dfE), 0);
	hv_store(RETVAL, "dfT" , 3, newSViv(t.dfT), 0);
	hv_store(RETVAL, "SSTr", 4, newSVnv(t.SSTr), 0);
	hv_store(RETVAL, "SSE" , 3, newSVnv(t.SSE), 0);
	hv_store(RETVAL, "SST" , 3, newSVnv(t.SST), 0);
	hv_store(RETVAL, "MSTr", 4, newSVnv(t.MSTr), 0);
	hv_store(RETVAL, "MSE" , 3, newSVnv(t.MSE), 0);
	hv_store(RETVAL, "F"   , 1, newSVnv(t.F), 0);
	hv_store(RETVAL, "p"   , 1, newSVnv(t.p), 0);
	//fprintf(stderr, "ok\n");
    OUTPUT:
    	RETVAL

HV *
anova_twoway(data, factorA, factorB, JA, JB, type)
	AV * data;
	AV * factorA
	AV * factorB
	int JA
	int JB
	int type
    PREINIT:
    	double *d;
	couple_t *f;
	int i;
	int I;
	couple_t J;
	struct tamu_anova_table_twoway t;
    CODE:
	I=av_len(data)+1;
	if (av_len(factorA) != I-1
	    || av_len(factorB) != I-1) {
		fprintf(stderr,
			"Math::TamuAnova::anova: data factorA and factorB"
			" are not the same size!\n");
		XSRETURN_UNDEF;
	}
	if (I <= 0) {
		fprintf(stderr, "Math::TamuAnova::anova: null sized array\n");
		XSRETURN_UNDEF;
	}
	if (type != anova_fixed
	    && type != anova_random
	    && type != anova_mixed) {
		fprintf(stderr, "Math::TamuAnova::anova: Bad type %i\n", type);
		XSRETURN_UNDEF;
	}
	d=malloc(sizeof(double)*I);
	f=malloc(sizeof(couple_t)*I);
	if (f==NULL || d==NULL) {
		fprintf(stderr, "Math::TamuAnova::anova: cannot allocate memory\n");
		XSRETURN_UNDEF;
	}
	for (i=0; i<I; i++) {
		int val;
		d[i]=SvNV(*av_fetch(data, i, 0));
		//fprintf(stderr, "f[%i][0]=%i\n", i, val);
		val=SvIV(*av_fetch(factorA, i, 0));
		if (val < 1 || val > JA) {
			fprintf(stderr, 
				"Math::TamuAnova::anova: factorA[%i]=%i!\n",
				i, val);
			free(d);
			free(f);
			XSRETURN_UNDEF;
		}
		f[i][0]=val;
		//fprintf(stderr, "f[%i][0]=%i\n", i, val);
		val=SvIV(*av_fetch(factorB, i, 0));
		if (val < 1 || val > JB) {
			fprintf(stderr, 
				"Math::TamuAnova::anova: factorB[%i]=%i!\n",
				i, val);
			free(d);
			free(f);
			XSRETURN_UNDEF;
		}
		f[i][1]=val;
		//fprintf(stderr, "f[%i][1]=%i\n", i, val);
	}
	J[0]=JA;
	J[1]=JB;
	//fprintf(stderr, "go (%i, [%li, %li], %i)\n", I, J[0], J[1], type);
	//for(i=0; i<I; i++) {
	//	fprintf(stderr, "D[%i], F[%i][0,1]= (%g, [%li, %li])\n", 
	//			i, i, d[i], f[i][0], f[i][1]);
	//}
	t=tamu_anova_twoway(d,f,I,J,type);
	
	free(d);
	free(f);
	
	//rh = (HV *)sv_2mortal((SV *)newHV());
	RETVAL = newHV();
	sv_2mortal((SV *)RETVAL);
	hv_store(RETVAL, "dfA" , 3, newSViv(t.dfA), 0);
	hv_store(RETVAL, "dfB" , 3, newSViv(t.dfB), 0);
	hv_store(RETVAL, "dfAB", 4, newSViv(t.dfAB), 0);
	hv_store(RETVAL, "dfE" , 3, newSViv(t.dfE), 0);
	hv_store(RETVAL, "dfT" , 3, newSViv(t.dfT), 0);
	hv_store(RETVAL, "SSA" , 3, newSVnv(t.SSA), 0);
	hv_store(RETVAL, "MSA" , 3, newSVnv(t.MSA), 0);
	hv_store(RETVAL, "FA"  , 2, newSVnv(t.FA), 0);
	hv_store(RETVAL, "pA"  , 2, newSVnv(t.pA), 0);
	hv_store(RETVAL, "SSB" , 3, newSVnv(t.SSB), 0);
	hv_store(RETVAL, "MSB" , 3, newSVnv(t.MSB), 0);
	hv_store(RETVAL, "FB"  , 2, newSVnv(t.FB), 0);
	hv_store(RETVAL, "pB"  , 2, newSVnv(t.pB), 0);
	hv_store(RETVAL, "SSAB", 4, newSVnv(t.SSAB), 0);
	hv_store(RETVAL, "MSAB", 4, newSVnv(t.MSAB), 0);
	hv_store(RETVAL, "FAB" , 3, newSVnv(t.FAB), 0);
	hv_store(RETVAL, "pAB" , 3, newSVnv(t.pAB), 0);
	hv_store(RETVAL, "SSE" , 3, newSVnv(t.SSE), 0);
	hv_store(RETVAL, "MSE" , 3, newSVnv(t.MSE), 0);
	hv_store(RETVAL, "SST" , 3, newSVnv(t.SST), 0);
	//fprintf(stderr, "ok\n");
    OUTPUT:
    	RETVAL
