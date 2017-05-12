/*
 * Copyright (C) 2005 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#include "gst2perl.h"

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_fourcc_wrapper_class;

static SV *
gst2perl_fourcc_wrap (const GValue *value)
{
	return newSVpvf ("%" GST_FOURCC_FORMAT,
	                 GST_FOURCC_ARGS (gst_value_get_fourcc (value)));
;
}

static void
gst2perl_fourcc_unwrap (GValue *value, SV *sv)
{
	STRLEN length = 0;
	const char *string = SvPV (sv, length);
	if (length != 4)
		croak ("GStreamer::Fourcc values must be strings of length 4");
	gst_value_set_fourcc (value, GST_STR_FOURCC (string));
}

static void
gst2perl_fourcc_initialize (void)
{
	gst2perl_fourcc_wrapper_class.wrap = gst2perl_fourcc_wrap;
	gst2perl_fourcc_wrapper_class.unwrap = gst2perl_fourcc_unwrap;

	gperl_register_fundamental_full (GST_TYPE_FOURCC,
	                                 "GStreamer::Fourcc",
	                                 &gst2perl_fourcc_wrapper_class);
}

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_double_range_wrapper_class;

static SV *
gst2perl_double_range_wrap (const GValue *value)
{
	AV *av = newAV ();

	av_push (av, newSVnv (gst_value_get_double_range_min (value)));
	av_push (av, newSVnv (gst_value_get_double_range_max (value)));

	return newRV_noinc ((SV *) av);
}

static void
gst2perl_double_range_unwrap (GValue *value, SV *sv)
{
	AV *av;
	SV **start, **end;

	if (!gperl_sv_is_array_ref (sv))
		croak ("GStreamer::DoubleRange values must be array references");

	av = (AV *) SvRV (sv);

	if (av_len (av) != 1)
		croak ("GStreamer::DoubleRange values must contain two values: start and end");

	start = av_fetch (av, 0, 0);
	end = av_fetch (av, 1, 0);

	if (start && gperl_sv_is_defined (*start) && end && gperl_sv_is_defined (*end))
		gst_value_set_double_range (value, SvNV (*start), SvNV (*end));
}

static void
gst2perl_double_range_initialize (void)
{
	gst2perl_double_range_wrapper_class.wrap = gst2perl_double_range_wrap;
	gst2perl_double_range_wrapper_class.unwrap = gst2perl_double_range_unwrap;

	gperl_register_fundamental_full (GST_TYPE_DOUBLE_RANGE,
	                                 "GStreamer::DoubleRange",
	                                 &gst2perl_double_range_wrapper_class);
}

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_int_range_wrapper_class;

static SV *
gst2perl_int_range_wrap (const GValue *value)
{
	AV *av = newAV ();

	av_push (av, newSViv (gst_value_get_int_range_min (value)));
	av_push (av, newSViv (gst_value_get_int_range_max (value)));

	return newRV_noinc ((SV *) av);
}

static void
gst2perl_int_range_unwrap (GValue *value, SV *sv)
{
	AV *av;
	SV **start, **end;

	if (!gperl_sv_is_array_ref (sv))
		croak ("GstIntRange must be an array reference");

	av = (AV *) SvRV (sv);

	if (av_len (av) != 1)
		croak ("GstIntRange must contain two values: start and end");

	start = av_fetch (av, 0, 0);
	end = av_fetch (av, 1, 0);

	if (start && gperl_sv_is_defined (*start) && end && gperl_sv_is_defined (*end))
		gst_value_set_int_range (value, SvIV (*start), SvIV (*end));
}

static void
gst2perl_int_range_initialize (void)
{
	gst2perl_int_range_wrapper_class.wrap = gst2perl_int_range_wrap;
	gst2perl_int_range_wrapper_class.unwrap = gst2perl_int_range_unwrap;

	gperl_register_fundamental_full (GST_TYPE_INT_RANGE,
	                                 "GStreamer::IntRange",
	                                 &gst2perl_int_range_wrapper_class);
}

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_value_list_wrapper_class;

static SV *
gst2perl_value_list_wrap (const GValue *value)
{
	AV *av = newAV ();
	guint size, i;

	size = gst_value_list_get_size (value);
	for (i = 0; i < size; i++) {
		const GValue *list_value = gst_value_list_get_value (value, i);
		AV *list_av = newAV ();

		/* FIXME: Can this cause deadlocks? */
		av_push (list_av, gperl_sv_from_value (list_value));
		av_push (list_av, newSVpv (gperl_package_from_type (G_VALUE_TYPE (list_value)), 0));

		av_push (av, newRV_noinc ((SV *) list_av));
	}

	return newRV_noinc ((SV *) av);
}

static void
gst2perl_value_list_unwrap (GValue *value, SV *sv)
{
	AV *av;
	int i;

	if (!gperl_sv_is_array_ref (sv))
		croak ("GstValueList must be an array reference");

	av = (AV *) SvRV (sv);
	for (i = 0; i <= av_len (av); i++) {
		SV **list_value, **element, **type;
		AV *list_av;

		list_value = av_fetch (av, i, 0);

		if (!list_value || !gperl_sv_is_array_ref (*list_value))
			croak ("GstValueList must contain array references");

		list_av = (AV *) SvRV (*list_value);

		if (av_len (list_av) != 1)
			croak ("GstValueList must contain array references with two elements: value and type");

		element = av_fetch (list_av, 0, 0);
		type = av_fetch (list_av, 1, 0);

		if (element && gperl_sv_is_defined (*element) && type && gperl_sv_is_defined (*type)) {
			GValue new_value = { 0, };

			const char *package = SvPV_nolen (*type);
			GType gtype = gperl_type_from_package (package);
			if (!type)
				croak ("unregistered package %s encountered", package);

			g_value_init (&new_value, gtype);
			/* FIXME: Can this cause deadlocks? */
			gperl_value_from_sv (&new_value, *element);
			gst_value_list_append_value (value, &new_value);

			g_value_unset (&new_value);
		}
	}

}

static void
gst2perl_value_list_initialize (void)
{
	gst2perl_value_list_wrapper_class.wrap = gst2perl_value_list_wrap;
	gst2perl_value_list_wrapper_class.unwrap = gst2perl_value_list_unwrap;

	gperl_register_fundamental_full (GST_TYPE_LIST,
	                                 "GStreamer::ValueList",
	                                 &gst2perl_value_list_wrapper_class);
}

/* ------------------------------------------------------------------------- */

/* This array stuff is a copy of the list stuff. */

static GPerlValueWrapperClass gst2perl_value_array_wrapper_class;

static SV *
gst2perl_value_array_wrap (const GValue *value)
{
	AV *av = newAV ();
	guint size, i;

	size = gst_value_array_get_size (value);
	for (i = 0; i < size; i++) {
		const GValue *list_value = gst_value_array_get_value (value, i);
		AV *list_av = newAV ();

		/* FIXME: Can this cause deadlocks? */
		av_push (list_av, gperl_sv_from_value (list_value));
		av_push (list_av, newSVpv (gperl_package_from_type (G_VALUE_TYPE (list_value)), 0));

		av_push (av, newRV_noinc ((SV *) list_av));
	}

	return newRV_noinc ((SV *) av);
}

static void
gst2perl_value_array_unwrap (GValue *value, SV *sv)
{
	AV *av;
	int i;

	if (!gperl_sv_is_array_ref (sv))
		croak ("GstValueArray must be an array reference");

	av = (AV *) SvRV (sv);
	for (i = 0; i <= av_len (av); i++) {
		SV **list_value, **element, **type;
		AV *list_av;

		list_value = av_fetch (av, i, 0);

		if (!list_value || !gperl_sv_is_array_ref (*list_value))
			croak ("GstValueArray must contain array references");

		list_av = (AV *) SvRV (*list_value);

		if (av_len (list_av) != 1)
			croak ("GstValueArray must contain array references with two elements: value and type");

		element = av_fetch (list_av, 0, 0);
		type = av_fetch (list_av, 1, 0);

		if (element && gperl_sv_is_defined (*element) && type && gperl_sv_is_defined (*type)) {
			GValue new_value = { 0, };

			const char *package = SvPV_nolen (*type);
			GType gtype = gperl_type_from_package (package);
			if (!type)
				croak ("unregistered package %s encountered", package);

			g_value_init (&new_value, gtype);
			/* FIXME: Can this cause deadlocks? */
			gperl_value_from_sv (&new_value, *element);
			gst_value_array_append_value (value, &new_value);

			g_value_unset (&new_value);
		}
	}

}

static void
gst2perl_value_array_initialize (void)
{
	gst2perl_value_array_wrapper_class.wrap = gst2perl_value_array_wrap;
	gst2perl_value_array_wrapper_class.unwrap = gst2perl_value_array_unwrap;

	gperl_register_fundamental_full (GST_TYPE_ARRAY,
	                                 "GStreamer::ValueArray",
	                                 &gst2perl_value_array_wrapper_class);
}

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_fraction_wrapper_class;

static SV *
gst2perl_fraction_wrap (const GValue *value)
{
	AV *av = newAV ();

	av_push (av, newSViv (gst_value_get_fraction_numerator (value)));
	av_push (av, newSViv (gst_value_get_fraction_denominator (value)));

	return newRV_noinc ((SV *) av);
}

static void
gst2perl_fraction_unwrap (GValue *value, SV *sv)
{
	AV *av;
	SV **numerator, **denominator;

	if (!gperl_sv_is_array_ref (sv))
		croak ("GstFraction must be an array reference");

	av = (AV *) SvRV (sv);

	if (av_len (av) != 1)
		croak ("GstFraction must contain two values: numerator and denominator");

	numerator = av_fetch (av, 0, 0);
	denominator = av_fetch (av, 1, 0);

	if (numerator && gperl_sv_is_defined (*numerator) && denominator && gperl_sv_is_defined (*denominator))
		gst_value_set_fraction (value, SvIV (*numerator), SvIV (*denominator));
}

static void
gst2perl_fraction_initialize (void)
{
	gst2perl_fraction_wrapper_class.wrap = gst2perl_fraction_wrap;
	gst2perl_fraction_wrapper_class.unwrap = gst2perl_fraction_unwrap;

	gperl_register_fundamental_full (GST_TYPE_FRACTION,
	                                 "GStreamer::Fraction",
	                                 &gst2perl_fraction_wrapper_class);
}

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_fraction_range_wrapper_class;

static SV *
gst2perl_fraction_range_wrap (const GValue *value)
{
	AV *av = newAV ();

	av_push (av, gperl_sv_from_value (gst_value_get_fraction_range_min (value)));
	av_push (av, gperl_sv_from_value (gst_value_get_fraction_range_max (value)));

	return newRV_noinc ((SV *) av);
}

static void
gst2perl_fraction_range_unwrap (GValue *value, SV *sv)
{
	AV *av;
	SV **start, **end;

	if (!gperl_sv_is_array_ref (sv))
		croak ("GstFractionRange must be an array reference");

	av = (AV *) SvRV (sv);

	if (av_len (av) != 1)
		croak ("GstFractionRange must contain two values: start and end");

	start = av_fetch (av, 0, 0);
	end = av_fetch (av, 1, 0);

	if (start && gperl_sv_is_defined (*start) && end && gperl_sv_is_defined (*end)) {
		GValue start_value = { 0, }, end_value = { 0, };

		g_value_init (&start_value, GST_TYPE_FRACTION);
		g_value_init (&end_value, GST_TYPE_FRACTION);

		/* FIXME: Can this cause deadlocks? */
		gperl_value_from_sv (&start_value, *start);
		gperl_value_from_sv (&end_value, *end);

		gst_value_set_fraction_range (value, &start_value, &end_value);

		g_value_unset (&start_value);
		g_value_unset (&end_value);
	}
}

static void
gst2perl_fraction_range_initialize (void)
{
	gst2perl_fraction_range_wrapper_class.wrap = gst2perl_fraction_range_wrap;
	gst2perl_fraction_range_wrapper_class.unwrap = gst2perl_fraction_range_unwrap;

	gperl_register_fundamental_full (GST_TYPE_FRACTION_RANGE,
	                                 "GStreamer::FractionRange",
	                                 &gst2perl_fraction_range_wrapper_class);
}

/* ------------------------------------------------------------------------- */

static GPerlBoxedWrapperClass gst2perl_date_wrapper_class;

static SV *
gst2perl_date_wrap (GType gtype,
		    const char *package,
                    GDate *date,
		    gboolean own)
{
	struct tm tm;
	time_t seconds;

	g_date_to_struct_tm (date, &tm);

	if (own)
		g_date_free (date);

	seconds = mktime (&tm);
	return seconds == -1 ? &PL_sv_undef : newSViv (seconds);
}

static GDate *
gst2perl_date_unwrap (GType gtype,
		      const char *package,
		      SV *sv)
{
	GDate *date;
	time_t seconds;

	date = g_date_new ();
	seconds = SvIV (sv);

#if GLIB_CHECK_VERSION (2, 10, 0)
	g_date_set_time_t (date, seconds);
#else
	g_date_set_time (date, (GTime) seconds);
#endif

	return date;
}

static void
gst2perl_date_initialize (void)
{
	GPerlBoxedWrapperClass *default_wrapper_class;

	default_wrapper_class = gperl_default_boxed_wrapper_class ();

	gst2perl_date_wrapper_class = *default_wrapper_class;
	gst2perl_date_wrapper_class.wrap =
		(GPerlBoxedWrapFunc) gst2perl_date_wrap;
	gst2perl_date_wrapper_class.unwrap =
		(GPerlBoxedUnwrapFunc) gst2perl_date_unwrap;

	gperl_register_boxed (GST_TYPE_DATE, "GStreamer::Date",
	                      &gst2perl_date_wrapper_class);
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Value	PACKAGE = GStreamer::Value	PREFIX = gst_value_

BOOT:
	gst2perl_fourcc_initialize ();
	gst2perl_int_range_initialize ();
	gst2perl_double_range_initialize ();
	gst2perl_value_list_initialize ();
	gst2perl_value_array_initialize ();
	gst2perl_fraction_initialize ();
	gst2perl_fraction_range_initialize ();
	gst2perl_date_initialize ();
