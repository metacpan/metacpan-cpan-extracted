/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static GIFunctionInfo *
_find_struct_method (GIStructInfo *info, const gchar *method)
{
	/* g_struct_info_find_method is broken for class structs like
	 * GtkWidgetClass, so we search manually.  See
	 * <https://bugzilla.gnome.org/show_bug.cgi?id=700338>. */
	gint n_methods;
	gint i;
	n_methods = g_struct_info_get_n_methods (info);
	for (i = 0; i < n_methods; i++) {
		GIFunctionInfo *method_info =
			g_struct_info_get_method (info, i);
		if (strEQ (g_base_info_get_name (method_info), method))
			return method_info;
		g_base_info_unref (method_info);
	}
	return NULL;
}

static GIFunctionInfo *
_find_enum_method (GIEnumInfo *info, const gchar *method)
{
#if GI_CHECK_VERSION (1, 29, 17)
	gint n_methods;
	gint i;
	n_methods = g_enum_info_get_n_methods (info);
	for (i = 0; i < n_methods; i++) {
		GIFunctionInfo *method_info =
			g_enum_info_get_method (info, i);
		if (strEQ (g_base_info_get_name (method_info), method))
			return method_info;
		g_base_info_unref (method_info);
	}
#endif
	return NULL;
}

/* Caller owns return value */
static GIFunctionInfo *
get_function_info (GIRepository *repository,
                   const gchar *basename,
                   const gchar *namespace,
                   const gchar *method)
{
	dwarn ("%s, %s, %s\n", basename, namespace, method);

	if (namespace) {
		GIFunctionInfo *function_info = NULL;
		GIBaseInfo *namespace_info = g_irepository_find_by_name (
			repository, basename, namespace);
		if (!namespace_info)
			ccroak ("Can't find information for namespace %s",
			       namespace);

		switch (g_base_info_get_type (namespace_info)) {
		    case GI_INFO_TYPE_OBJECT:
			function_info = g_object_info_find_method (
				(GIObjectInfo *) namespace_info,
				method);
			break;
		    case GI_INFO_TYPE_INTERFACE:
			function_info = g_interface_info_find_method (
				(GIInterfaceInfo *) namespace_info,
				method);
			break;
		    case GI_INFO_TYPE_BOXED:
		    case GI_INFO_TYPE_STRUCT:
			function_info = _find_struct_method (
				(GIStructInfo *) namespace_info,
				method);
			break;
                    case GI_INFO_TYPE_UNION:
			function_info = g_union_info_find_method (
				(GIUnionInfo *) namespace_info,
				method);
			break;
		    case GI_INFO_TYPE_ENUM:
		    case GI_INFO_TYPE_FLAGS:
			function_info = _find_enum_method (
				(GIEnumInfo *) namespace_info,
				method);
			break;
		    default:
			ccroak ("Base info for namespace %s has incorrect type",
			       namespace);
		}

		if (!function_info)
			ccroak ("Can't find information for method "
			       "%s::%s", namespace, method);

		g_base_info_unref (namespace_info);

		return function_info;
	} else {
		GIBaseInfo *method_info = g_irepository_find_by_name (
			repository, basename, method);

		if (!method_info)
			ccroak ("Can't find information for method %s", method);

		switch (g_base_info_get_type (method_info)) {
		    case GI_INFO_TYPE_FUNCTION:
			return (GIFunctionInfo *) method_info;
		    default:
			ccroak ("Base info for method %s has incorrect type",
			       method);
		}
	}

	return NULL;
}

/* Caller owns return value */
static GIFieldInfo *
get_field_info (GIBaseInfo *info, const gchar *field_name)
{
	GIInfoType info_type;
	info_type = g_base_info_get_type (info);
	switch (info_type) {
	    case GI_INFO_TYPE_BOXED:
	    case GI_INFO_TYPE_STRUCT:
	    {
		gint n_fields, i;
		n_fields = g_struct_info_get_n_fields ((GIStructInfo *) info);
		for (i = 0; i < n_fields; i++) {
			GIFieldInfo *field_info;
			field_info = g_struct_info_get_field ((GIStructInfo *) info, i);
			if (0 == strcmp (field_name, g_base_info_get_name (field_info))) {
				return field_info;
			}
			g_base_info_unref (field_info);
		}
		break;
	    }
	    case GI_INFO_TYPE_UNION:
	    {
		gint n_fields, i;
		n_fields = g_union_info_get_n_fields ((GIStructInfo *) info);
		for (i = 0; i < n_fields; i++) {
			GIFieldInfo *field_info;
			field_info = g_union_info_get_field ((GIStructInfo *) info, i);
			if (0 == strcmp (field_name, g_base_info_get_name (field_info))) {
				return field_info;
			}
			g_base_info_unref (field_info);
		}
		break;
	    }
	    default:
		break;
	}
	return NULL;
}

/* Caller owns return value */
static GISignalInfo *
get_signal_info (GIBaseInfo *container_info, const gchar *signal_name)
{
	if (GI_IS_OBJECT_INFO (container_info)) {
		return g_object_info_find_signal (container_info, signal_name);
	} else if (GI_IS_INTERFACE_INFO (container_info)) {
#if GI_CHECK_VERSION (1, 35, 4)
		return g_interface_info_find_signal (container_info, signal_name);
#else
{
		gint n_signals;
		gint i;
		n_signals = g_interface_info_get_n_signals (container_info);
		for (i = 0; i < n_signals; i++) {
			GISignalInfo *siginfo =
				g_interface_info_get_signal (container_info, i);
			if (strEQ (g_base_info_get_name (siginfo), signal_name))
				return siginfo;
			g_base_info_unref (siginfo);
		}
		return NULL;
}
#endif
	}
	return NULL;
}

/* Caller owns return value. */
static gchar *
synthesize_gtype_name (GIBaseInfo *info)
{
	const gchar *namespace = g_base_info_get_namespace (info);
	const gchar *name = g_base_info_get_name (info);
	if (0 == strncmp (namespace, "GObject", 8) ||
	    0 == strncmp (namespace, "GLib", 5))
	{
		namespace = "G";
	}
	return g_strconcat (namespace, name, NULL);
}

/* Caller owns return value. */
static gchar *
synthesize_prefixed_gtype_name (GIBaseInfo *info)
{
	const gchar *namespace = g_base_info_get_namespace (info);
	const gchar *name = g_base_info_get_name (info);
	if (0 == strncmp (namespace, "GObject", 8) ||
	    0 == strncmp (namespace, "GLib", 5))
	{
		namespace = "G";
	}
	return g_strconcat ("GPerlI11n", namespace, name, NULL);
}

static GType
get_gtype (GIRegisteredTypeInfo *info)
{
	GType gtype = g_registered_type_info_get_g_type (info);
	/* Fall back to the registered type name, and if that doesn't work
	 * either, construct the full name and the prefixed full name and try
	 * them. */
	if (!gtype || gtype == G_TYPE_NONE) {
		const gchar *type_name = g_registered_type_info_get_type_name (info);
		if (type_name) {
			gtype = g_type_from_name (type_name);
		}
	}
	if (!gtype || gtype == G_TYPE_NONE) {
		gchar *full_name = synthesize_gtype_name (info);
		gtype = g_type_from_name (full_name);
		g_free (full_name);
	}
	if (!gtype || gtype == G_TYPE_NONE) {
		gchar *full_name = synthesize_prefixed_gtype_name (info);
		gtype = g_type_from_name (full_name);
		g_free (full_name);
	}
	return gtype ? gtype : G_TYPE_NONE;
}

static const gchar *
get_package_for_basename (const gchar *basename)
{
	SV **svp;
	HV *basename_to_package =
		get_hv ("Glib::Object::Introspection::_BASENAME_TO_PACKAGE", 0);
	g_assert (basename_to_package);
	svp = hv_fetch (basename_to_package, basename, strlen (basename), 0);
	if (!svp || !gperl_sv_is_defined (*svp))
	    return NULL;
	return SvPV_nolen (*svp);
}

static gboolean
is_forbidden_sub_name (const gchar *name)
{
	HV *forbidden_sub_names =
		get_hv ("Glib::Object::Introspection::_FORBIDDEN_SUB_NAMES", 0);
	g_assert (forbidden_sub_names);
	return hv_exists (forbidden_sub_names, name, strlen (name));
}
