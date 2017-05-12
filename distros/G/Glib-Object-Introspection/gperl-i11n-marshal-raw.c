/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void
raw_to_arg (gpointer raw, GIArgument *arg, GITypeInfo *info)
{
	GITypeTag tag = g_type_info_get_tag (info);

	switch (tag) {
	    case GI_TYPE_TAG_VOID:
		if (g_type_info_is_pointer (info)) {
			arg->v_pointer = CAST_RAW (raw, gpointer);
		} else {
			/* do nothing */
		}
		break;

	    case GI_TYPE_TAG_BOOLEAN:
		arg->v_boolean = CAST_RAW (raw, gboolean);
		break;

	    case GI_TYPE_TAG_INT8:
		arg->v_int8 = CAST_RAW (raw, gint8);
		break;

	    case GI_TYPE_TAG_UINT8:
		arg->v_uint8 = CAST_RAW (raw, guint8);
		break;

	    case GI_TYPE_TAG_INT16:
		arg->v_int16 = CAST_RAW (raw, gint16);
		break;

	    case GI_TYPE_TAG_UINT16:
		arg->v_uint16 = CAST_RAW (raw, guint16);
		break;

	    case GI_TYPE_TAG_INT32:
		arg->v_int32 = CAST_RAW (raw, gint32);
		break;

	    case GI_TYPE_TAG_UINT32:
	    case GI_TYPE_TAG_UNICHAR:
		arg->v_uint32 = CAST_RAW (raw, guint32);
		break;

	    case GI_TYPE_TAG_INT64:
		arg->v_int64 = CAST_RAW (raw, gint64);
		break;

	    case GI_TYPE_TAG_UINT64:
		arg->v_uint64 = CAST_RAW (raw, guint64);
		break;

	    case GI_TYPE_TAG_FLOAT:
		arg->v_float = CAST_RAW (raw, gfloat);
		break;

	    case GI_TYPE_TAG_DOUBLE:
		arg->v_double = CAST_RAW (raw, gdouble);
		break;

	    case GI_TYPE_TAG_GTYPE:
		arg->v_size = CAST_RAW (raw, GType);
		break;

	    case GI_TYPE_TAG_ARRAY:
	    case GI_TYPE_TAG_INTERFACE:
	    case GI_TYPE_TAG_GLIST:
	    case GI_TYPE_TAG_GSLIST:
	    case GI_TYPE_TAG_GHASH:
	    case GI_TYPE_TAG_ERROR:
		arg->v_pointer = CAST_RAW (raw, gpointer);
		break;

	    case GI_TYPE_TAG_UTF8:
	    case GI_TYPE_TAG_FILENAME:
		arg->v_string = CAST_RAW (raw, gchar*);
		break;

	    default:
		ccroak ("Unhandled info tag %d in raw_to_arg", tag);
	}
}

static void
arg_to_raw (GIArgument *arg, gpointer raw, GITypeInfo *info)
{
	GITypeTag tag = g_type_info_get_tag (info);

	switch (tag) {
	    case GI_TYPE_TAG_VOID:
		/* do nothing */
		break;

	    case GI_TYPE_TAG_BOOLEAN:
		* (gboolean *) raw = arg->v_boolean;
		break;

	    case GI_TYPE_TAG_INT8:
		* (gint8 *) raw = arg->v_int8;
		break;

	    case GI_TYPE_TAG_UINT8:
		* (guint8 *) raw = arg->v_uint8;
		break;

	    case GI_TYPE_TAG_INT16:
		* (gint16 *) raw = arg->v_int16;
		break;

	    case GI_TYPE_TAG_UINT16:
		* (guint16 *) raw = arg->v_uint16;
		break;

	    case GI_TYPE_TAG_INT32:
		* (gint32 *) raw = arg->v_int32;
		break;

	    case GI_TYPE_TAG_UINT32:
	    case GI_TYPE_TAG_UNICHAR:
		* (guint32 *) raw = arg->v_uint32;
		break;

	    case GI_TYPE_TAG_INT64:
		* (gint64 *) raw = arg->v_int64;
		break;

	    case GI_TYPE_TAG_UINT64:
		* (guint64 *) raw = arg->v_uint64;
		break;

	    case GI_TYPE_TAG_FLOAT:
		* (gfloat *) raw = arg->v_float;
		break;

	    case GI_TYPE_TAG_DOUBLE:
		* (gdouble *) raw = arg->v_double;
		break;

	    case GI_TYPE_TAG_GTYPE:
		* (GType *) raw = arg->v_size;
		break;

	    case GI_TYPE_TAG_ARRAY:
	    case GI_TYPE_TAG_INTERFACE:
	    case GI_TYPE_TAG_GLIST:
	    case GI_TYPE_TAG_GSLIST:
	    case GI_TYPE_TAG_GHASH:
	    case GI_TYPE_TAG_ERROR:
		* (gpointer *) raw = arg->v_pointer;
		break;

	    case GI_TYPE_TAG_UTF8:
	    case GI_TYPE_TAG_FILENAME:
		* (gchar **) raw = arg->v_string;
		break;

	    default:
		ccroak ("Unhandled info tag %d in arg_to_raw", tag);
	}
}
