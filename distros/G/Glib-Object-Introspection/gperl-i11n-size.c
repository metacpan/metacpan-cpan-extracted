/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

/* These three are basically copied from pygi's pygi-info.c. :-( */

static gsize
size_of_type_tag (GITypeTag type_tag)
{
	switch(type_tag) {
	    case GI_TYPE_TAG_BOOLEAN:
		return sizeof (gboolean);
	    case GI_TYPE_TAG_INT8:
	    case GI_TYPE_TAG_UINT8:
		return sizeof (gint8);
	    case GI_TYPE_TAG_INT16:
	    case GI_TYPE_TAG_UINT16:
		return sizeof (gint16);
	    case GI_TYPE_TAG_INT32:
	    case GI_TYPE_TAG_UINT32:
		return sizeof (gint32);
	    case GI_TYPE_TAG_INT64:
	    case GI_TYPE_TAG_UINT64:
		return sizeof (gint64);
	    case GI_TYPE_TAG_FLOAT:
		return sizeof (gfloat);
	    case GI_TYPE_TAG_DOUBLE:
		return sizeof (gdouble);
	    case GI_TYPE_TAG_GTYPE:
		return sizeof (GType);
	    case GI_TYPE_TAG_UNICHAR:
		return sizeof (gunichar);

	    case GI_TYPE_TAG_VOID:
	    case GI_TYPE_TAG_UTF8:
	    case GI_TYPE_TAG_FILENAME:
	    case GI_TYPE_TAG_ARRAY:
	    case GI_TYPE_TAG_INTERFACE:
	    case GI_TYPE_TAG_GLIST:
	    case GI_TYPE_TAG_GSLIST:
	    case GI_TYPE_TAG_GHASH:
	    case GI_TYPE_TAG_ERROR:
		ccroak ("Unable to determine the size of '%s'",
		        g_type_tag_to_string (type_tag));
		break;
	}

	return 0;
}

static gsize
size_of_interface (GITypeInfo *type_info)
{
	gsize size = 0;

	GIBaseInfo *info;
	GIInfoType info_type;

	info = g_type_info_get_interface (type_info);
	info_type = g_base_info_get_type (info);

	switch (info_type) {
	    case GI_INFO_TYPE_STRUCT:
		if (g_type_info_is_pointer (type_info)) {
			size = sizeof (gpointer);
		} else {
			/* FIXME: Remove this workaround once
			 * gobject-introspection is fixed:
			 * <https://bugzilla.gnome.org/show_bug.cgi?id=657040>. */
			GType type = get_gtype (info);
			if (type == G_TYPE_VALUE) {
				size = sizeof (GValue);
			} else {
				size = g_struct_info_get_size ((GIStructInfo *) info);
			}
		}
		break;

	    case GI_INFO_TYPE_UNION:
		if (g_type_info_is_pointer (type_info)) {
			size = sizeof (gpointer);
		} else {
			size = g_union_info_get_size ((GIUnionInfo *) info);
		}
		break;

	    case GI_INFO_TYPE_ENUM:
	    case GI_INFO_TYPE_FLAGS:
		if (g_type_info_is_pointer (type_info)) {
			size = sizeof (gpointer);
		} else {
			GITypeTag type_tag;
			type_tag = g_enum_info_get_storage_type ((GIEnumInfo *) info);
			size = size_of_type_tag (type_tag);
		}
		break;

	    case GI_INFO_TYPE_BOXED:
	    case GI_INFO_TYPE_OBJECT:
	    case GI_INFO_TYPE_INTERFACE:
	    case GI_INFO_TYPE_CALLBACK:
		size = sizeof (gpointer);
		break;

	    default:
		g_assert_not_reached ();
		break;
	}

	g_base_info_unref (info);

	return size;
}

static gsize
size_of_type_info (GITypeInfo *type_info)
{
	GITypeTag type_tag;

	type_tag = g_type_info_get_tag (type_info);
	switch (type_tag) {
	    case GI_TYPE_TAG_BOOLEAN:
	    case GI_TYPE_TAG_INT8:
	    case GI_TYPE_TAG_UINT8:
	    case GI_TYPE_TAG_INT16:
	    case GI_TYPE_TAG_UINT16:
	    case GI_TYPE_TAG_INT32:
	    case GI_TYPE_TAG_UINT32:
	    case GI_TYPE_TAG_INT64:
	    case GI_TYPE_TAG_UINT64:
	    case GI_TYPE_TAG_FLOAT:
	    case GI_TYPE_TAG_DOUBLE:
	    case GI_TYPE_TAG_GTYPE:
	    case GI_TYPE_TAG_UNICHAR:
		if (g_type_info_is_pointer (type_info)) {
			return sizeof (gpointer);
		} else {
			return size_of_type_tag (type_tag);
		}

	    case GI_TYPE_TAG_INTERFACE:
		return size_of_interface (type_info);

	    case GI_TYPE_TAG_ARRAY:
	    case GI_TYPE_TAG_VOID:
	    case GI_TYPE_TAG_UTF8:
	    case GI_TYPE_TAG_FILENAME:
	    case GI_TYPE_TAG_GLIST:
	    case GI_TYPE_TAG_GSLIST:
	    case GI_TYPE_TAG_GHASH:
	    case GI_TYPE_TAG_ERROR:
		return sizeof (gpointer);
	}

	return 0;
}
