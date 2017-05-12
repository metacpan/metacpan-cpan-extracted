#define NEED_newSV_type
#include "xshelper.h"
#include "mgx.h"
#define NEED_mro_get_linear_isa
#include "mro_compat.h"

#ifndef HvNAMELEN_get
#define HvNAMELEN_get(stash) strlen(HvNAME_get(stash))
#endif

#if PERL_BCDVERSION < 0x5010000
#define HF_USE_TIE TRUE
#endif

#define PACKAGE "Hash::FieldHash"

#ifdef HF_USE_TIE
#include "compat58.h"
#endif

#define OBJECT_REGISTRY_KEY PACKAGE "::" "::META"
#define NAME_REGISTRY_KEY   OBJECT_REGISTRY_KEY

#define INVALID_OBJECT "Invalid object \"%"SVf"\" as a fieldhash key"

#define MY_CXT_KEY PACKAGE "::_guts" XS_VERSION
typedef struct {
	AV* object_registry; /* the global object registry */
	I32 last_id;         /* the last allocated id */
	SV* free_id;         /* the top of the linked list */

	HV*  name_registry;
	bool name_registry_is_stale;
} my_cxt_t;
START_MY_CXT
#define ObjectRegistry  (MY_CXT.object_registry)
#define LastId          (MY_CXT.last_id)
#define FreeId          (MY_CXT.free_id)
#define NameRegistry    (MY_CXT.name_registry)

#define NameRegistryIsStale (MY_CXT.name_registry_is_stale)

static int fieldhash_key_free(pTHX_ SV* const sv, MAGIC* const mg);
static MGVTBL fieldhash_key_vtbl = {
	NULL, /* get */
	NULL, /* set */
	NULL, /* len */
	NULL, /* clear */
	fieldhash_key_free,
	NULL, /* copy */
	NULL, /* dup */
#ifdef MGf_LOCAL
	NULL, /* local */
#endif
};

#define fieldhash_key_mg(sv) MgFind(sv, &fieldhash_key_vtbl)

#ifndef HF_USE_TIE
static I32 fieldhash_watch(pTHX_ IV const action, SV* const fieldhash);
static struct ufuncs fieldhash_ufuncs = {
	fieldhash_watch, /* uf_val */
	NULL,            /* uf_set */
	0,               /* uf_index */
};

#define fieldhash_mg(sv) hf_fieldhash_mg(aTHX_ sv)
static MAGIC*
hf_fieldhash_mg(pTHX_ SV* const sv){
	MAGIC* mg;

	assert(sv != NULL);
	for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
		if(((struct ufuncs*)mg->mg_ptr) == &fieldhash_ufuncs){
			break;
		}
	}
	return mg;
}

static SV*
fieldhash_fetch(pTHX_ HV* const fieldhash, SV* const key){
	HE* const he = hv_fetch_ent(fieldhash, key, FALSE, 0U);

	return he ? HeVAL(he) : &PL_sv_undef;
}

static void
fieldhash_store(pTHX_ HV* const fieldhash, SV* const key, SV* const val){
	(void)hv_store_ent(fieldhash, key, val, 0U);
}

#endif /* !HF_USE_TIE */

static SV*
hf_new_id(pTHX_ pMY_CXT){
	SV* obj_id;
	if(!FreeId){
		obj_id = newSV_type(SVt_PVIV);
		sv_setiv(obj_id, ++LastId);
	}
	else{
		obj_id = FreeId;
		FreeId = INT2PTR(SV*, SvIVX(obj_id)); /* next node */

		(void)sv_2iv(obj_id);
	}
	return obj_id;
}

static void
hf_free_id(pTHX_ pMY_CXT_ SV* const obj_id){
	assert(SvTYPE(obj_id) >= SVt_PVIV);

	SvIV_set(obj_id, PTR2IV(FreeId));
	SvIOK_off(obj_id);
	FreeId = obj_id;
}

static SV*
hf_av_find(pTHX_ AV* const av, SV* const sv){
	SV** const ary = AvARRAY(av);
	I32  const len = AvFILLp(av)+1;
	I32 i;

	for(i = 0; i < len; i++){
		if(ary[i] == sv){
			return sv;
		}
	}
	return NULL;
}

/*
    defined actions (in 5.10.0) are:
       HV_FETCH_ISSTORE  = 0x04
       HV_FETCH_ISEXISTS = 0x08
       HV_FETCH_LVALUE   = 0x10
       HV_FETCH_JUST_SV  = 0x20
       HV_DELETE         = 0x40
 */
#define HF_CREATE_KEY(a) (a & (HV_FETCH_ISSTORE | HV_FETCH_LVALUE))

static I32
fieldhash_watch(pTHX_ IV const action, SV* const fieldhash){
	MAGIC* const mg = fieldhash_mg(fieldhash);
	SV* obj_ref;
	SV* obj;
	const MAGIC* key_mg;
	AV* reg;         /* field registry */

	assert(mg != NULL);

	obj_ref = mg->mg_obj; /* the given hash key */

	if(!SvROK(obj_ref)){ /* it can be an object ID */
		if(!looks_like_number(obj_ref)){ /* looks like an ID? */
			Perl_croak(aTHX_ INVALID_OBJECT, obj_ref);
		}

		if(!HF_CREATE_KEY(action)){ /* fetch, exists, delete */
			return 0;
		}
		else{ /* store, lvalue fetch */
			dMY_CXT;
			SV** const svp = av_fetch(ObjectRegistry, (I32)SvIV(obj_ref), FALSE);

			if(!svp){
				Perl_croak(aTHX_ INVALID_OBJECT, obj_ref);
			}

			/* retrieve object from ID */
			assert(SvIOK(*svp));
			obj = INT2PTR(SV*, SvIVX(*svp));
			obj_ref = NULL;
		}
	}
	else{
		obj = SvRV(obj_ref);
	}

	assert(!SvIS_FREED(obj));

	key_mg = fieldhash_key_mg(obj);
	if(!key_mg){ /* first access */
		if(!HF_CREATE_KEY(action)){ /* fetch, exists, delete */
			/* replace the key with a sv that is not a registered ID */
			mg->mg_obj = &PL_sv_no;
			return 0;
		}
		else{ /* store, lvalue fetch */
			dMY_CXT;
			SV* const obj_id      = hf_new_id(aTHX_ aMY_CXT);
			SV* const obj_weakref = newSViv(PTR2IV(obj));

			av_store(ObjectRegistry, (I32)SvIVX(obj_id), obj_weakref);

			mg->mg_obj = obj_id; /* key replacement */

			reg = newAV(); /* field registry for obj */

			key_mg = sv_magicext(
				obj,
				(SV*)reg,
				PERL_MAGIC_ext,
				&fieldhash_key_vtbl,
				(char*)obj_id,
				HEf_SVKEY
			);

			SvREFCNT_dec(reg);    /* refcnt++ in sv_magicext() */
		}
	}
	else{
		/* key_mg->mg_ptr is obj_id */
		mg->mg_obj = (SV*)key_mg->mg_ptr; /* key replacement */

		if(!HF_CREATE_KEY(action)){
			return 0;
		}

		reg = (AV*)key_mg->mg_obj;
		assert(SvTYPE(reg) == SVt_PVAV);
	}

	/* add a new fieldhash to the field registry if needed */
	if(!hf_av_find(aTHX_ reg, (SV*)fieldhash)){
		av_push(reg, (SV*)SvREFCNT_inc_simple_NN(fieldhash));
	}

	return 0;
}

static int
fieldhash_key_free(pTHX_ SV* const sv, MAGIC* const mg){
	PERL_UNUSED_ARG(sv);

	//warn("key_free(sv=0x%p, mg=0x%p, id=%"SVf")", sv, mg, (SV*)mg->mg_ptr);

	/*
		Does nothing during global destruction, because
		some data may have been released.
	*/
	if(!PL_dirty){
		dMY_CXT;
		AV* const reg    = (AV*)mg->mg_obj; /* field registry */
		SV* const obj_id = (SV*)mg->mg_ptr;
		I32 const len    = AvFILLp(reg)+1;
		I32 i;

		assert(SvTYPE(reg) == SVt_PVAV);


		/* delete $fieldhash{$obj} for each fieldhash */
		for(i = 0; i < len; i++){
			HV* const fieldhash = (HV*)AvARRAY(reg)[i];
			assert(SvTYPE(fieldhash) == SVt_PVHV);

			/* NOTE: Don't use G_DISCARD, because it may cause
			         a double-free problem (t/11_panic_malloc.t).
			*/
			(void)hv_delete_ent(fieldhash, obj_id, 0, 0U);
		}

		av_delete(ObjectRegistry, (I32)SvIVX(obj_id), G_DISCARD);
		hf_free_id(aTHX_ aMY_CXT_ obj_id);
	}

	return 0;
}

MGVTBL hf_accessor_vtbl;

XS(XS_Hash__FieldHash_accessor);
XS(XS_Hash__FieldHash_accessor){
	dVAR; dXSARGS;
	SV* const obj_ref   = ST(0);
	MAGIC* const mg     = mg_find_by_vtbl((SV*)cv, &hf_accessor_vtbl);
	HV* const fieldhash = (HV*)mg->mg_obj;

	if(items < 1 || !SvROK(obj_ref)){
		Perl_croak(aTHX_ "The %s() method must be called as an instance method", GvNAME(CvGV(cv)));
	}
	if(items > 2){
		Perl_croak(aTHX_ "Cannot set a list of values to \"%s\"", GvNAME(CvGV(cv)));
	}

	if(items == 1){ /* get */
		ST(0) = fieldhash_fetch(aTHX_ fieldhash, obj_ref);
	}
	else{ /* set */
		fieldhash_store(aTHX_ fieldhash, obj_ref, newSVsv(ST(1)));
		/* returns self */
	}
	XSRETURN(1);
}


static HV*
hf_get_named_fields(pTHX_ HV* const stash, const char** const pkg_ptr, I32* const pkglen_ptr){
	dMY_CXT;
	const char* const pkg  = HvNAME_get(stash);
	I32 const pkglen       = HvNAMELEN_get(stash);
	SV** const svp         = hv_fetch(NameRegistry, pkg, pkglen, FALSE);
	HV* fields;

	if(!svp){
		fields = newHV();

		(void)hv_store(NameRegistry, pkg, pkglen, newRV_noinc((SV*)fields), 0U);
		NameRegistryIsStale = TRUE;
	}
	else{
		assert(SvROK(*svp));
		fields = (HV*)SvRV(*svp);
		assert(SvTYPE(fields) == SVt_PVHV);
	}

	if(NameRegistryIsStale){
		AV* const isa = mro_get_linear_isa(stash);
		I32 const len = AvFILLp(isa)+1;
		I32 i;
		for(i = 1 /* skip this class */; i < len; i++){
			HE* const he          = hv_fetch_ent(NameRegistry, AvARRAY(isa)[i], FALSE, 0U);
			HV* const base_fields = he && SvROK(HeVAL(he)) ? (HV*)SvRV(HeVAL(he)) : NULL;

			if(base_fields){
				char* key;
				I32   keylen;
				SV*   val;
				hv_iterinit(base_fields);
				while((val = hv_iternextsv(base_fields, &key, &keylen))){
					(void)hv_store(fields, key, keylen, newSVsv(val), 0U);
				}
			}
		}
	}

	if(pkg_ptr)    *pkg_ptr    = pkg;
	if(pkglen_ptr) *pkglen_ptr = pkglen;

	return fields;
}

static void
hf_add_field(pTHX_ HV* const fieldhash, SV* const name, SV* const package){
	if(name){
		dMY_CXT;
		HV* const stash = package ? gv_stashsv(package, TRUE) : CopSTASH(PL_curcop);
		I32         pkglen;
		const char* pkg;
		HV* const fields = hf_get_named_fields(aTHX_ stash, &pkg, &pkglen);
		STRLEN namelen;
		const char* namepv = SvPV_const(name, namelen);
		CV* xsub;

		if(hv_exists_ent(fields, name, 0U) && ckWARN(WARN_REDEFINE)){
			Perl_warner(aTHX_ packWARN(WARN_REDEFINE), "field \"%"SVf"\" redefined or overridden", name);
		}

		(void)hv_store_ent(fields, name, newRV_inc((SV*)fieldhash), 0U);

		namepv   = Perl_form(aTHX_ "%s::%s", pkg, namepv); /* fully qualified name */
		namelen += sizeof("::")-1 + pkglen;
		(void)hv_store(fields, namepv, namelen, newRV_inc((SV*)fieldhash), 0U);

		if(ckWARN(WARN_REDEFINE) && get_cv(namepv, 0x00)){
			Perl_warner(aTHX_ packWARN(WARN_REDEFINE),
				"Subroutine %s redefined", namepv);
		}

		xsub = newXS( (char*)namepv, XS_Hash__FieldHash_accessor, __FILE__);
		sv_magicext(
			(SV*)xsub,
			(SV*)fieldhash,
			PERL_MAGIC_ext,
			&hf_accessor_vtbl,
			NULL,
			0
		);
		CvMETHOD_on(xsub);

		NameRegistryIsStale = TRUE;
	}
}

MODULE = Hash::FieldHash	PACKAGE = Hash::FieldHash

PROTOTYPES: DISABLE

BOOT:
{
	MY_CXT_INIT;
	ObjectRegistry = get_av(OBJECT_REGISTRY_KEY, GV_ADDMULTI);
	NameRegistry   = get_hv(  NAME_REGISTRY_KEY, GV_ADDMULTI);
	LastId         = -1;
}

#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
	MY_CXT_CLONE;

	ObjectRegistry = get_av(OBJECT_REGISTRY_KEY, GV_ADDMULTI);
	NameRegistry   = get_hv(  NAME_REGISTRY_KEY, GV_ADDMULTI);
	FreeId         = NULL;
	PERL_UNUSED_VAR(items);

#endif /* !USE_ITHREADS */

#ifndef HF_USE_TIE

void
fieldhash(HV* hash, SV* name = NULL, SV* package = NULL)
PROTOTYPE: \%;$$
CODE:
	assert(SvTYPE(hash) >= SVt_PVMG);
	if(!fieldhash_mg((SV*)hash)){
		hv_clear(hash);
		sv_magic((SV*)hash,
			NULL,                     /* mg_obj */
			PERL_MAGIC_uvar,          /* mg_type */
			(char*)&fieldhash_ufuncs, /* mg_ptr as the ufuncs table */
			0                         /* mg_len (0 indicates static data) */
		);

		hf_add_field(aTHX_ hash, name, package);
	}

#else /* HF_USE_TIE */

INCLUDE: compat58.xsi

#endif


#ifdef FIELDHASH_DEBUG

void
_dump_internals()
PREINIT:
	dMY_CXT;
	SV* obj_id;
CODE:
	for(obj_id = FreeId; obj_id; obj_id = INT2PTR(SV*, SvIVX(obj_id))){
		sv_dump(obj_id);
	}

HV*
_name_registry()
PREINIT:
	dMY_CXT;
CODE:
	RETVAL = NameRegistry;
OUTPUT:
	RETVAL

#endif /* !FIELDHASH_DEBUG */


void
from_hash(SV* object, ...)
PREINIT:
	const char* stashname;
	HV*   stash;
	HV*   fields;
INIT:
	if(!sv_isobject(object)){
		Perl_croak(aTHX_ "The %s() method must be called as an instance method", GvNAME(CvGV(cv)));
	}
CODE:
	stash  = SvSTASH(SvRV(object));
	fields = hf_get_named_fields(aTHX_ stash, &stashname, NULL);

	if(items == 2){
		SV* const arg = ST(1);
		HV* hv;
		char* key;
		I32   keylen;
		SV*   val;

		if(!(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV)){
			Perl_croak(aTHX_ "Single parameters to %s() must be a HASH reference", GvNAME(CvGV(cv)));
		}

		hv = (HV*)SvRV(arg);
		hv_iterinit(hv);
		while((val = hv_iternextsv(hv, &key, &keylen))){
			SV** const svp = hv_fetch(fields, key, keylen, FALSE);

			if(!(svp && SvROK(*svp))){
				Perl_croak(aTHX_ "No such field \"%s\" for %s", key, stashname);
			}

			fieldhash_store(aTHX_ (HV*)SvRV(*svp), object, newSVsv(val));
		}
	}
	else{
		I32 i;

		if( ((items-1) % 2) != 0 ){
			Perl_croak(aTHX_ "Odd number of parameters for %s()", GvNAME(CvGV(cv)));
		}

		for(i = 1; i < items; i += 2){
			HE* const he = hv_fetch_ent(fields, ST(i), FALSE, 0U);

			if(!(he && SvROK(HeVAL(he)))){
				Perl_croak(aTHX_ "No such field \"%s\" for %s", SvPV_nolen_const(ST(i)), stashname);
			}

			fieldhash_store(aTHX_ (HV*)SvRV(HeVAL(he)), object, newSVsv(ST(i+1)));
		}
	}
	XSRETURN(1); /* returns the first argument */

HV*
to_hash(SV* object, ...)
PREINIT:
	HV*   stash;
	HV*   fields;
	char* key;
	I32   keylen;
	SV*   val;
	bool  fully_qualify = FALSE;
INIT:
	if(!sv_isobject(object)){
		Perl_croak(aTHX_ "The %s() method must be called as an instance method", GvNAME(CvGV(cv)));
	}
	while(items > 1){
		SV* const option = ST(--items);

		if(SvOK(option)){
			if(strEQ(SvPV_nolen_const(option), "-fully_qualify")){
				fully_qualify = TRUE;
			}
			else{
				Perl_croak(aTHX_ "Unknown option \"%"SVf"\"", option);
			}
		}
	}
CODE:
	stash = SvSTASH(SvRV(object));
	fields = hf_get_named_fields(aTHX_ stash, NULL, NULL);
	RETVAL = newHV();

	hv_iterinit(fields);
	while((val = hv_iternextsv(fields, &key, &keylen))){
		bool const need_to_store = strchr(key, ':') ? fully_qualify : !fully_qualify;
		if( need_to_store && SvROK(val) ){
			HV* const fieldhash = (HV*)SvRV(val);
			SV* const value     = fieldhash_fetch(aTHX_ fieldhash, object);
			(void)hv_store(RETVAL, key, keylen, newSVsv(value), 0U);
		}
	}
OUTPUT:
	RETVAL
