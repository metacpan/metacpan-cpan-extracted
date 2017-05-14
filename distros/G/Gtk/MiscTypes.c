#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */

#include "MiscTypes.h"

void CroakOpts(char * name, char * value, struct opts * o)
{
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
	croak(SvPV(result, na));
}

void CroakOptsHash(char * name, char * value, HV * o)
{
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
	croak(SvPV(result, na));
}

long SvOpt(SV * name, char * optname, struct opts * o) 
{
	int i;
	char * n = SvPV(name, na);
	for(i=0;o[i].name;i++) 
		if (strEQ(o[i].name, n))
			return o[i].value;
	CroakOpts(optname, n, o);
}

SV * newSVOpt(long value, char * optname, struct opts * o) 
{
	int i;
	for(i=0;o[i].name;i++)
		if (o[i].value == value)
			return newSVpv(o[i].name, 0);
	croak("invalid %s value %d", optname, value);
}


SV * newSVMiscRef(void * object, char * classname, int * newref)
{
	HV * previous = RetrieveMisc(object);
	SV * result;
	if (previous) {
		/*printf("Retriveing object %d as HV %d\n", object, previous);*/
		result = newRV((SV*)previous);
		if (newref)
			*newref = 0;
	} else {
		HV * h = newHV();
		hv_store(h, "_gtk", 4, newSViv((int)object), 0);
		result = newRV((SV*)h);
		RegisterMisc(h, object);
		/*printf("Storing object %d as HV %d\n", object, h);*/
		sv_bless(result, gv_stashpv(classname, FALSE));
		SvREFCNT_dec(h);
		if (newref)
			*newref = 1;
	}
	return result;
}

long SvOptsHash(SV * name, char * optname, HV * o) 
{
	int i;
	int len;
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
}

SV * newSVOptsHash(long value, char * optname, HV * o) 
{
	int i;
	HE * h;
	SV * result = 0;
	hv_iterinit(o);
	while(h = hv_iternext(o)) {
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
		while(h = hv_iternext(r)) {
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

SV * newSVFlagsHash(long value, char * optname, HV * o, int hash) 
{
	SV * target, *result;
	HV * h = newHV();
	int i;
	HE * he;
	if (hash) 
		target = (SV*)newHV();
	else
		target = (SV*)newAV();
		
	
	hv_iterinit(o);
	while(he = hv_iternext(o)) {
		char *key;
		I32 len;
		SV * s = hv_iternextsv(o, &key, &len);
		int val = SvIV(s);
			
		if ((value & val) == val) {
			if (hash)
				hv_store((HV*)target, key, len, newSVsv(s), 0);
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

SV * newSVOptFlags(long value, char * optname, struct opts * o, int hash) 
{
	SV * result;
	if (hash) {
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


void * SvMiscRef(SV * o, char * classname)
{
	HV * q;
	SV ** s;
	if (!o || !SvOK(o) || !(q=(HV*)SvRV(o)) || (SvTYPE(q) != SVt_PVHV))
		return 0;
	if (classname && !sv_derived_from(o, classname))
		croak("variable is not of type %s", classname);
	s = hv_fetch(q, "_gtk", 4, 0);
	if (!s || !SvIV(*s))
		croak("variable is damaged %s", classname);
	return (void*)SvIV(*s);
}

static HV * MiscCache = 0;

void UnregisterMisc(HV * hv_object, void * gtk_object)
{
	int i;
	char buffer[40];
	sprintf(buffer, "%lu", (unsigned long)gtk_object);
	if (!MiscCache)
		MiscCache = newHV();
	
	/*printf("Removing object %d, HV %d\n", gtk_object, hv_object);*/
	
	hv_delete(hv_object, "_gtk", 4, G_DISCARD);
	hv_delete(MiscCache, buffer, strlen(buffer), G_DISCARD);
}

void RegisterMisc(HV * hv_object, void * gtk_object)
{
	char buffer[40];
	sprintf(buffer, "%lu", (unsigned long)gtk_object);
	if (!MiscCache)
		MiscCache = newHV();
	hv_store(MiscCache, buffer, strlen(buffer), newSViv((int)hv_object), 0);
}

HV * RetrieveMisc(void * gtk_object)
{
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
}

void * alloc_temp(int size)
{
    SV * s = sv_2mortal(newSVpv("",0));
    SvGROW(s, size);
    return SvPV(s, na);
}
