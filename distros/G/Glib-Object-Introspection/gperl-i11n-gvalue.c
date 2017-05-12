/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

/* Semi-private package for marshalling into GValues. */
#define GVALUE_WRAPPER_PACKAGE "Glib::Object::Introspection::GValueWrapper"

static GValue *
SvGValueWrapper (SV *sv)
{
	return sv_derived_from (sv, GVALUE_WRAPPER_PACKAGE)
		? INT2PTR (GValue*, SvIV (SvRV (sv)))
		: NULL;
}

static SV *
newSVGValueWrapper (GValue *v)
{
	SV *sv;
	sv = newSV (0);
	sv_setref_pv (sv, GVALUE_WRAPPER_PACKAGE, v);
	return sv;
}
