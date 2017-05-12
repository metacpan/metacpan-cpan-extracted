/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

#define UNION_REBLESSERS_HV "Glib::Object::Introspection::_REBLESSERS"
#define UNION_MEMBER_TYPE_SUFFIX "::_i11n_gtype"

static SV *
rebless_union_sv (GType type, const char *package, gpointer mem, gboolean own)
{
	SV *sv, **reblesser_p;
	HV *reblessers;

	sv = gperl_default_boxed_wrapper_class ()->wrap (type, package, mem, own);

	reblessers = get_hv (UNION_REBLESSERS_HV, 0);
	g_assert (reblessers);
	reblesser_p = hv_fetch (reblessers, package, strlen (package), 0);
	if (reblesser_p && gperl_sv_is_defined (*reblesser_p)) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK (SP);
		XPUSHs (sv_2mortal (SvREFCNT_inc (sv)));
		PUTBACK;
		call_sv (*reblesser_p, G_DISCARD);
		FREETMPS;
		LEAVE;
	}

	return sv;
}

static void
associate_union_members_with_gtype (GIUnionInfo *info, const gchar *package, GType type)
{
	gint i, n_fields;
	n_fields = g_union_info_get_n_fields (info);
	for (i = 0; i < n_fields; i++) {
		GIFieldInfo *field_info;
		GITypeInfo *field_type;
		GIBaseInfo *field_interface;
		const gchar *type_name;
		gchar *full_name;
		SV *sv;

		field_info = g_union_info_get_field (info, i);
		field_type = g_field_info_get_type (field_info);
		field_interface = g_type_info_get_interface (field_type);
		/* If this field has a basic type, then we cannot associate its
		 * parent's GType with it. */
		if (!field_interface) {
			g_base_info_unref ((GIBaseInfo *) field_type);
			g_base_info_unref ((GIBaseInfo *) field_info);
			continue;
		}

		type_name = g_base_info_get_name (field_interface);
		full_name = g_strconcat (package, "::", type_name, UNION_MEMBER_TYPE_SUFFIX, NULL);
		dwarn ("%s::%s => %"G_GSIZE_FORMAT" (%s)\n",
		       package, type_name, type, g_type_name (type));
		sv = get_sv (full_name, GV_ADD);
		sv_setuv (sv, type);
		g_free (full_name);

		g_base_info_unref ((GIBaseInfo *) field_interface);
		g_base_info_unref ((GIBaseInfo *) field_type);
		g_base_info_unref ((GIBaseInfo *) field_info);
	}
}

static GType
find_union_member_gtype (const gchar *package, const gchar *namespace)
{
	gchar *type_sv_name;
	SV *type_sv;
	type_sv_name = g_strconcat (package, "::", namespace,
	                            UNION_MEMBER_TYPE_SUFFIX, NULL);
	type_sv = get_sv (type_sv_name, 0);
	g_free (type_sv_name);
	return type_sv ? SvUV (type_sv) : G_TYPE_NONE;
}
