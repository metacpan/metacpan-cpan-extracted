/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

#define FILL_VALUES(values, value_type)                                 \
	{ gint i; \
	for (i = 0; i < n_values; i++) { \
		GIValueInfo *value_info = g_enum_info_get_value (info, i); \
		(values)[i].value = (value_type) g_value_info_get_value (value_info); \
		/* FIXME: Can we assume that the strings will stick around long enough? */ \
		(values)[i].value_nick = g_base_info_get_name (value_info); \
		(values)[i].value_name = g_base_info_get_attribute (value_info, "c:identifier"); \
		if (!(values)[i].value_name) \
			(values)[i].value_name = (values)[i].value_nick; \
		g_base_info_unref (value_info); \
	} }

static GType
register_unregistered_enum (GIEnumInfo *info)
{
	GType gtype = G_TYPE_NONE;
	gchar *full_name;
	GIInfoType info_type;
	void *values;
	gint n_values;

	/* Abort if there already is a GType under this name. */
	full_name = synthesize_prefixed_gtype_name (info);
	if (g_type_from_name (full_name)) {
		g_free (full_name);
		return gtype;
	}

	info_type = g_base_info_get_type (info);

	/* We have to leak 'values' as g_enum_register_static and
	 * g_flags_register_static assume that what we pass in will be valid
	 * throughout the lifetime of the program. */
	n_values = g_enum_info_get_n_values (info);
	if (info_type == GI_INFO_TYPE_ENUM) {
		values = g_new0 (GEnumValue, n_values+1); /* zero-terminated */
		FILL_VALUES ((GEnumValue *) values, gint);
	} else {
		values = g_new0 (GFlagsValue, n_values+1); /* zero-terminated */
		FILL_VALUES ((GFlagsValue *) values, guint);
	}

	if (info_type == GI_INFO_TYPE_ENUM) {
		gtype = g_enum_register_static (full_name, (GEnumValue *) values);
	} else {
		gtype = g_flags_register_static (full_name, (GFlagsValue *) values);
	}

	g_free (full_name);
	return gtype;
}
