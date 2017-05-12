#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */

#include "PerlGtkInt.h"

#include "ppport.h"

#include "MiscTypes.h"

#include "Derived.h"

void CroakOpts(char * name, char * value, struct opts * o)
{
	dTHR;

	SV * result = sv_newmortal();
	int i;
	
	sv_catpv(result, "invalid ");
	sv_catpv(result, name);
	sv_catpv(result, " ");
	sv_catpv(result, value);
	sv_catpv(result, ", expecting");
	for(i=0;o[i].name;i++) {
		if (i==0)
			sv_catpv(result," '");
		else if (o[i+1].name)
			sv_catpv(result,"', '");
		else
			sv_catpv(result,"', or '");
		sv_catpv(result, o[i].name);
	}
	sv_catpv(result,"'");
	croak(SvPV(result, PL_na));
}

void CroakOptsHash(char * name, char * value, HV * o)
{
	dTHR;

	SV * result = sv_newmortal();
	HE * he;
	int i=0;
	
	sv_catpv(result, "invalid ");
	sv_catpv(result, name);
	sv_catpv(result, " ");
	sv_catpv(result, value);
	sv_catpv(result, ", expecting");
	hv_iterinit(o);
	he = hv_iternext(o);
	while(he) {
		I32 len;
		char * key = hv_iterkey(he, &len);
		he = hv_iternext(o);
		if (i==0)
			sv_catpv(result," '");
		else if (he)
			sv_catpv(result,"', '");
		else
			sv_catpv(result,"', or '");
		i=1;
		sv_catpvn(result, key, len);
	}
	sv_catpv(result,"'");
	croak(SvPV(result, PL_na));
}

long SvOpt(SV * name, char * optname, struct opts * o) 
{
	dTHR;

	int i;
	char * n = SvPV(name, PL_na);
	for(i=0;o[i].name;i++) 
		if (strEQ(o[i].name, n))
			return o[i].value;
	CroakOpts(optname, n, o);
	return 0;
}

SV * newSVOpt(long value, char * optname, struct opts * o) 
{
	int i;
	for(i=0;o[i].name;i++)
		if (o[i].value == value)
			return newSVpv(o[i].name, 0);
	croak("invalid %s value %d", optname, value);
	return NULL;
}


SV * newSVMiscRef(void * object, char * classname, int * newref)
{
	HV * previous;
	SV * result;
	if (!object)
		return newSVsv(&PL_sv_undef);
	previous = RetrieveMisc(object);
	if (previous) {
		/*printf("Retriveing object %d as HV %d\n", object, previous);*/
		result = newRV((SV*)previous);
		if (newref)
			*newref = 0;
	} else {
		HV * h = newHV();
		hv_store(h, "_gtk", 4, newSViv((long)object), 0);
		result = newRV((SV*)h);
		RegisterMisc(h, object);
		sv_bless(result, gv_stashpv(classname, FALSE));
		SvREFCNT_dec(h);
		if (newref)
			*newref = 1;
		/*printf("Storing object %p (%s) as HV %p (refcount: %d, %d)\n", object, classname, h, SvREFCNT(h), SvREFCNT(result));*/
	}
	return result;
}

long SvOptsHash(SV * name, char * optname, HV * o) 
{
	int i;
	STRLEN len;
	char * n = SvPV(name, len);
	SV ** s;
	if (*n == '-') {
		n++;
		len--;
	}
	s = hv_fetch(o, n, len, 0);
	if (s)
		return SvIV(*s);
	CroakOptsHash(optname, n, o);
	return 0;
}

SV * newSVOptsHash(long value, char * optname, HV * o) 
{
	int i;
	HE * h;
	SV * result = 0;
	hv_iterinit(o);
	while((h = hv_iternext(o))) {
		SV * s = hv_iterval(o, h);
		if (SvIV(s) == value) {
			I32 len;
			char * p = hv_iterkey(h, &len);
			result = newSVpv(p, len);
		}
	}
	if (result)
		return result;
	croak("invalid %s value %d", optname, value);
}

long SvFlagsHash(SV * name, char * optname, HV * o) 
{
	int i;
	int val=0;
	if (!name || !SvOK(name))
		return 0;
	if (SvRV(name) && (SvTYPE(SvRV(name)) == SVt_PVAV)) {
		AV * r = (AV*)SvRV(name);
		for(i=0;i<=av_len(r);i++)
			val |= SvOptsHash(*av_fetch(r, i, 0), optname, o);
	} else if (SvRV(name) && (SvTYPE(SvRV(name)) == SVt_PVHV)) {
		HV * r = (HV*)SvRV(name);
		HE * h;
		hv_iterinit(r);
		while((h = hv_iternext(r))) {
			I32 len;
			char * key = hv_iterkey(h, &len);
			SV ** f;
			if (*key == '-') {
				key++;
				len--;
			}
			f = hv_fetch(o, key, len, 0);
			if (f)
				val |= SvIV(hv_iterval(o, h));
			else
				CroakOptsHash(optname, key, o);
		}
	} else
		val |= SvOptsHash(name, optname, o);
	return val;
}

SV * newSVFlagsHash(long value, char * optname, HV * o) 
{
	SV * target, *result;
	int i;
	HE * he;
	SV * s;
	I32 len;
	char * key;
	
	if (!pgtk_use_array) 
		target = (SV*)newHV();
	else
		target = (SV*)newAV();
		
	hv_iterinit(o);
	while((s = hv_iternextsv(o, &key, &len))) {
		int val = SvIV(s);
			
		if ((value & val) == val) {
			if (!pgtk_use_array)
				hv_store((HV*)target, key, len, newSViv(1), 0);
			else
				av_push((AV*)target, newSVpv(key, len));
			value &= ~val;
		}
	}
	
	result = newRV(target);
	SvREFCNT_dec(target);
	return result;
}


long SvOptFlags(SV * name, char * optname, struct opts * o) 
{
	int i;
	int val=0;
	if (!name || !SvOK(name))
		return 0;
	if (SvRV(name) && (SvTYPE(SvRV(name)) == SVt_PVAV)) {
		AV * r = (AV*)SvRV(name);
		for(i=0;i<=av_len(r);i++)
			val |= SvOpt(*av_fetch(r, i, 0), optname, o);
	} else if (SvRV(name) && (SvTYPE(SvRV(name)) == SVt_PVHV)) {
		HV * r = (HV*)SvRV(name);
		/* This is bad, as we don't catch members with invalid names */
		for(i=0;o[i].name;i++) {
			SV ** s = hv_fetch(r, o[i].name, strlen(o[i].name), 0);
			if (s && SvOK(*s) && SvTRUE(*s))
				val |= o[i].value;
		}
	} else
		val |= SvOpt(name, optname, o);
	return val;
}

SV * newSVOptFlags(long value, char * optname, struct opts * o) 
{
	SV * result;
	if (!pgtk_use_array) {
		HV * h = newHV();
		int i;
		result = newRV((SV*)h);
		SvREFCNT_dec(h);
		for(i=0;o[i].name;i++)
			if ((value & o[i].value) == o[i].value) {
				hv_store(h, o[i].name, strlen(o[i].name), newSViv(1), 0);
				value &= ~o[i].value;
			}
	} else {
		AV * a = newAV();
		int i;
		result = newRV((SV*)a);
		SvREFCNT_dec(a);
		for(i=0;o[i].name;i++)
			if ((value & o[i].value) == o[i].value) {
				av_push(a, newSVpv(o[i].name, 0));
				value &= ~o[i].value;
			}
	}
	return result;
}

SV * newSVDefEnumHash (GtkType type, long value) {
	GtkEnumValue * vals;
	SV * result;

	vals = gtk_type_enum_get_values(type);
	if (!vals) {
		warn("Invalid type for enum: %s", gtk_type_name(type));
		return newSViv(value);
	}
	while (vals && vals->value_nick) {
		if (vals->value == value) {
			result = newSVpv(vals->value_nick, 0);
			if (!pgtk_use_minus) {
				char *s = SvPV(result, PL_na);
				while (*s) {
					if (*s == '-') *s = '_';
					s++;
				}
			}
			return result;
		}
		vals++;
	}
	/* Gtk/Gdk may get something wrong here, it's better to return undef
	 * croak("Invalid value %d for %s", value, gtk_type_name(type));*/
	return newSVsv(&PL_sv_undef);
}

SV * newSVDefFlagsHash (GtkType type, long value) {
	GtkFlagValue * vals;
	SV * result;
	char *s, *p;
	
	vals = gtk_type_flags_get_values(type);
	if (!vals) {
		warn("Invalid type for flags: %s", gtk_type_name(type));
		return newSViv(value);
	}
	if (!pgtk_use_array) {
		HV * h = newHV();
		result = newRV((SV*)h);
		SvREFCNT_dec(h);
		while(vals && vals->value_nick) {
			if ((value & vals->value) == vals->value) {
				if (pgtk_use_minus)
					hv_store(h, vals->value_nick, strlen(vals->value_nick), newSViv(1), 0);
				else {
					p = s = g_strdup(vals->value_nick);
					while (*s) {
						if (*s == '-') *s = '_';
						s++;
					}
					hv_store(h, p, strlen(p), newSViv(1), 0);
					g_free(p);
				}
				value &= ~vals->value;
			}
			vals++;
		}
	} else {
		AV * a = newAV();
		result = newRV((SV*)a);
		SvREFCNT_dec(a);
		while(vals && vals->value_nick) {
			if ((value & vals->value) == vals->value) {
				if (pgtk_use_minus)
					av_push(a, newSVpv(vals->value_nick, 0));
				else {
					p = s = g_strdup(vals->value_nick);
					while (*s) {
						if (*s == '-') *s = '_';
						s++;
					}
					av_push(a, newSVpv(p, 0));
					g_free(p);
				}
				value &= ~vals->value;
			}
			vals++;
		}
	}
	/* check for unhandled bits in value ... */
	return result;
}

static int hystrEQ(register char* a, register char *b) {
	while (*a && *b) {
		if (*a == *b || ((*a == '-' || *a == '_') && (*b == '-' || *b == '_'))) {
			a++;
			b++;
		} else
			return 0;
	}
	return *a == *b;
}

long SvEFValueLookup (GtkEnumValue * vals, char* name, GtkType type) {
	GtkEnumValue *v;
	dTHR;

	if (!name)
		croak("Need a value in lookup");
	if (*name == '-')
		name++;
	v = vals;
	while (v && v->value_nick) {
		if (hystrEQ(name, v->value_nick))
			return v->value;
		v++;
	}
	{
		SV * r;
		char * endc=NULL;
		long val;
		
		/* last chanche: integer value... */
		val = strtol(name, &endc, 0);
		if (*name && endc && *endc == '\0')
			return val;
		v = vals;
		r = sv_newmortal();
		sv_catpv(r, "invalid ");
		sv_catpv(r, gtk_type_name(type));
		sv_catpv(r, " value ");
		sv_catpv(r, name);
		sv_catpv(r, ", expecting: ");
		while (v && v->value_nick) {
			sv_catpv(r, v->value_nick);
			if (++v)
				sv_catpv(r, ", ");
		}
		croak(SvPV(r, PL_na));
		return 0;
	}
}

long SvDefEnumHash (GtkType type, SV *name) {
	long val = 0;
	GtkEnumValue * vals;
	vals = gtk_type_enum_get_values(type);
	if (!vals) {
		warn("Invalid type for enum: %s", gtk_type_name(type));
		return SvIV(name);
	}
	return SvEFValueLookup(vals, SvPV(name, PL_na), type);
}

long SvDefFlagsHash (GtkType type, SV *name) {
	long val = 0;
	GtkFlagValue * vals;
	int i;
	vals = gtk_type_flags_get_values(type);
	if (!vals) {
		warn("Invalid type for flags: %s", gtk_type_name(type));
		return SvIV(name);
	}
	if (SvROK(name) && (SvTYPE(SvRV(name)) == SVt_PVAV)) {
		AV * r = (AV*)SvRV(name);
		for(i=0;i<=av_len(r);i++)
			val |= SvEFValueLookup(vals, SvPV(*av_fetch(r, i, 0), PL_na), type);
	} else if (SvROK(name) && (SvTYPE(SvRV(name)) == SVt_PVHV)) {
		HV * r = (HV*)SvRV(name);
		HE * he;
		I32 len;

		hv_iterinit(r);
		while ((he=hv_iternext(r))) {
			val |= SvEFValueLookup(vals, hv_iterkey(he, &len), type);
		}
	} else
		val |= SvEFValueLookup(vals, SvPV(name, PL_na), type);
	return val;
}

void * SvMiscRef(SV * o, char * classname)
{
	HV * q;
	SV ** s;
	if (!o || !SvOK(o) || !(q=(HV*)SvRV(o)) || (SvTYPE(q) != SVt_PVHV))
		return 0;
	if (classname && !PerlGtk_sv_derived_from(o, classname))
		croak("variable is not of type %s", classname);
	s = hv_fetch(q, "_gtk", 4, 0);
	if (!s || !SvIV(*s))
		croak("variable is damaged %s %p -> %p", classname, s, s?(void*)SvIV(*s):NULL);
	return (void*)SvIV(*s);
}

#define USE_GHASH
#ifdef USE_GHASH
static GHashTable * MiscCache = NULL;
#else
static HV * MiscCache = 0;
#endif

void UnregisterMisc(HV * hv_object, void * gtk_object)
{
	HV * old_hv = NULL;
#ifdef USE_GHASH
	if (!MiscCache)
		MiscCache = g_hash_table_new(g_direct_hash, g_direct_equal);
	old_hv = g_hash_table_lookup(MiscCache, gtk_object);
	g_hash_table_remove(MiscCache, gtk_object);
	/*if (old_hv != hv_object)
			G_BREAKPOINT();*/
#else
	char buffer[40];
	sprintf(buffer, "%lu", (unsigned long)gtk_object);
	if (!MiscCache)
		MiscCache = newHV();
	hv_delete(MiscCache, buffer, strlen(buffer), G_DISCARD);
#endif
	/*printf("Removing object %p, HV %p\n", gtk_object, hv_object);*/
	
	hv_delete(hv_object, "_gtk", 4, G_DISCARD);
}

void RegisterMisc(HV * hv_object, void * gtk_object)
{
#ifdef USE_GHASH
	if (!MiscCache)
		MiscCache = g_hash_table_new(g_direct_hash, g_direct_equal);
	g_hash_table_insert(MiscCache, gtk_object, hv_object);
#else
	char buffer[40];
	sprintf(buffer, "%lu", (unsigned long)gtk_object);
	if (!MiscCache)
		MiscCache = newHV();
	hv_store(MiscCache, buffer, strlen(buffer), newSViv((long)hv_object), 0);
#endif
	/*printf("Registering object %p, HV %p (%d)\n", gtk_object, hv_object, SvREFCNT(hv_object));*/
}

HV * RetrieveMisc(void * gtk_object)
{
	HV * hv_object;
#ifdef USE_GHASH
	if (!MiscCache)
		MiscCache = g_hash_table_new(g_direct_hash, g_direct_equal);
	hv_object = g_hash_table_lookup(MiscCache, gtk_object);
	/*printf("Retreiving object %p, HV %p (%d)\n", gtk_object, hv_object, hv_object?SvREFCNT(hv_object):0);*/
	return hv_object;
#else
	SV ** s;
	char buffer[40];
	if (!MiscCache)
		MiscCache = newHV();
	sprintf(buffer, "%lu", (unsigned long)gtk_object);
	s = hv_fetch(MiscCache, buffer, strlen(buffer), 0);
	if (s)
		return (HV*)SvIV(*s);
	else
		return 0;
#endif
}

void * pgtk_alloc_temp(int size)
{
    dTHR;

    SV * s = sv_2mortal(newSVpv("",0));
    SvGROW(s, size);
	memset(SvPV(s, PL_na), 0, size);
    return SvPV(s, PL_na);
}
