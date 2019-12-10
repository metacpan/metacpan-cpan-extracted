/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

/* transfer and may_be_null can be gotten from arg_info, but sv_to_arg is also
 * called from places which don't have access to a GIArgInfo. */
static void
sv_to_arg (SV * sv,
           GIArgument * arg,
           GIArgInfo * arg_info,
           GITypeInfo * type_info,
           GITransfer transfer,
           gboolean may_be_null,
           GPerlI11nInvocationInfo * invocation_info)
{
	GITypeTag tag = g_type_info_get_tag (type_info);

	dwarn ("type info = %p, arg info = %p, tag = %d (%s)\n",
	       type_info, arg_info, tag, g_type_tag_to_string (tag));

	if (!gperl_sv_is_defined (sv)) {
		/* Interfaces, booleans and void types need to be able to
		 * handle undef separately.*/
		if (!may_be_null && tag != GI_TYPE_TAG_INTERFACE
		                 && tag != GI_TYPE_TAG_BOOLEAN
		                 && tag != GI_TYPE_TAG_VOID)
		{
			if (arg_info) {
				ccroak ("undefined value for mandatory argument '%s' encountered",
				        g_base_info_get_name ((GIBaseInfo *) arg_info));
			} else {
				ccroak ("undefined value encountered");
			}
		}
	}

	switch (tag) {
	    case GI_TYPE_TAG_VOID:
		/* returns NULL if no match is found */
		arg->v_pointer = sv_to_callback_data (sv, invocation_info);
		dwarn ("  -> pointer %p\n", arg->v_pointer);
		break;

	    case GI_TYPE_TAG_BOOLEAN:
		arg->v_boolean = SvTRUE (sv);
		break;

	    case GI_TYPE_TAG_INT8:
		arg->v_int8 = (gint8) SvIV (sv);
		break;

	    case GI_TYPE_TAG_UINT8:
		arg->v_uint8 = (guint8) SvUV (sv);
		break;

	    case GI_TYPE_TAG_INT16:
		arg->v_int16 = (gint16) SvIV (sv);
		break;

	    case GI_TYPE_TAG_UINT16:
		arg->v_uint16 = (guint16) SvUV (sv);
		break;

	    case GI_TYPE_TAG_INT32:
		arg->v_int32 = (gint32) SvIV (sv);
		break;

	    case GI_TYPE_TAG_UINT32:
		arg->v_uint32 = (guint32) SvUV (sv);
		break;

	    case GI_TYPE_TAG_INT64:
		arg->v_int64 = SvGInt64 (sv);
		break;

	    case GI_TYPE_TAG_UINT64:
		arg->v_uint64 = SvGUInt64 (sv);
		break;

	    case GI_TYPE_TAG_FLOAT:
		arg->v_float = (gfloat) SvNV (sv);
		break;

	    case GI_TYPE_TAG_DOUBLE:
		arg->v_double = SvNV (sv);
		break;

	    case GI_TYPE_TAG_UNICHAR:
		arg->v_uint32 = g_utf8_get_char (SvGChar (sv));
		break;

	    case GI_TYPE_TAG_GTYPE:
		/* GType == gsize */
		arg->v_size = gperl_type_from_package (SvPV_nolen (sv));
		if (!arg->v_size)
			arg->v_size = g_type_from_name (SvPV_nolen (sv));
		break;

	    case GI_TYPE_TAG_ARRAY:
		arg->v_pointer = sv_to_array (transfer, type_info, sv, invocation_info);
		break;

	    case GI_TYPE_TAG_INTERFACE:
		sv_to_interface (arg_info, type_info, transfer, may_be_null,
		                 sv, arg, invocation_info);
		break;

	    case GI_TYPE_TAG_GLIST:
	    case GI_TYPE_TAG_GSLIST:
		arg->v_pointer = sv_to_glist (transfer, type_info, sv, invocation_info);
		break;

	    case GI_TYPE_TAG_GHASH:
		arg->v_pointer = sv_to_ghash (transfer, type_info, sv);
		break;

	    case GI_TYPE_TAG_ERROR:
		if (gperl_sv_is_ref (sv)) {
			gperl_gerror_from_sv (sv, (GError **) &arg->v_pointer);
			g_assert (transfer == GI_TRANSFER_EVERYTHING);
		} else if (gperl_sv_is_defined (sv)) {
			arg->v_pointer = NULL;
			g_set_error ((GError **) &arg->v_pointer, 0, 0, "%s", SvPV_nolen (sv));
			g_assert (transfer == GI_TRANSFER_EVERYTHING);
		} else {
			arg->v_pointer = NULL;
		}
		break;

	    case GI_TYPE_TAG_UTF8:
		arg->v_string = gperl_sv_is_defined (sv) ? SvGChar (sv) : NULL;
		if (transfer >= GI_TRANSFER_CONTAINER)
			arg->v_string = g_strdup (arg->v_string);
		break;

	    case GI_TYPE_TAG_FILENAME:
		/* FIXME: Should we use SvPVbyte_nolen here? */
		arg->v_string = gperl_sv_is_defined (sv) ? SvPV_nolen (sv) : NULL;
		if (transfer >= GI_TRANSFER_CONTAINER)
			arg->v_string = g_strdup (arg->v_string);
		break;

	    default:
		ccroak ("Unhandled info tag %d in sv_to_arg", tag);
	}
}

/* This may call Perl code (via interface_to_sv, glist_to_sv, ghash_to_sv or
 * array_to_sv), so it needs to be wrapped with PUTBACK/SPAGAIN by the
 * caller. */
static SV *
arg_to_sv (GIArgument * arg,
           GITypeInfo * info,
           GITransfer transfer,
           GPerlI11nMemoryScope mem_scope,
           GPerlI11nInvocationInfo *iinfo)
{
	GITypeTag tag = g_type_info_get_tag (info);
	gboolean own = transfer >= GI_TRANSFER_CONTAINER;

	dwarn ("info = %p, tag = %d (%s), transfer = %d, own = %d\n",
	       info, tag, g_type_tag_to_string (tag), transfer, own);

	switch (tag) {
	    case GI_TYPE_TAG_VOID:
	    {
		/* returns NULL if no match is found */
		SV *sv = callback_data_to_sv (arg->v_pointer, iinfo);
		if (sv) {
			SvREFCNT_inc (sv);
		}
		dwarn ("  -> SV %p\n", sv);
		return sv ? sv : &PL_sv_undef;
	    }

	    case GI_TYPE_TAG_BOOLEAN:
		return boolSV (arg->v_boolean);

	    case GI_TYPE_TAG_INT8:
		return newSViv (arg->v_int8);

	    case GI_TYPE_TAG_UINT8:
		return newSVuv (arg->v_uint8);

	    case GI_TYPE_TAG_INT16:
		return newSViv (arg->v_int16);

	    case GI_TYPE_TAG_UINT16:
		return newSVuv (arg->v_uint16);

	    case GI_TYPE_TAG_INT32:
		return newSViv (arg->v_int32);

	    case GI_TYPE_TAG_UINT32:
		return newSVuv (arg->v_uint32);

	    case GI_TYPE_TAG_INT64:
		return newSVGInt64 (arg->v_int64);

	    case GI_TYPE_TAG_UINT64:
		return newSVGUInt64 (arg->v_uint64);

	    case GI_TYPE_TAG_FLOAT:
		return newSVnv (arg->v_float);

	    case GI_TYPE_TAG_DOUBLE:
		return newSVnv (arg->v_double);

	    case GI_TYPE_TAG_UNICHAR:
	    {
		SV *sv;
		gchar buffer[6];
		gint length = g_unichar_to_utf8 (arg->v_uint32, buffer);
		g_assert (length >= 0);
		sv = newSVpv (buffer, (STRLEN) length);
		SvUTF8_on (sv);
		return sv;
	    }

	    case GI_TYPE_TAG_GTYPE:
	    {
		GType gtype = arg->v_size;
		const char *package;
		if (G_TYPE_INVALID == gtype || G_TYPE_NONE == gtype)
			return &PL_sv_undef;
		package = gperl_package_from_type (gtype);
		if (!package)
			package = g_type_name (gtype);
		return package ? newSVpv (package, 0) : &PL_sv_undef;
	    }

	    case GI_TYPE_TAG_ARRAY:
		return array_to_sv (info, arg->v_pointer, transfer, iinfo);

	    case GI_TYPE_TAG_INTERFACE:
		return interface_to_sv (info, arg, own, mem_scope, iinfo);

	    case GI_TYPE_TAG_GLIST:
	    case GI_TYPE_TAG_GSLIST:
		return glist_to_sv (info, arg->v_pointer, transfer);

	    case GI_TYPE_TAG_GHASH:
		return ghash_to_sv (info, arg->v_pointer, transfer);

	    case GI_TYPE_TAG_ERROR:
		ccroak ("FIXME - GI_TYPE_TAG_ERROR");
		break;

	    case GI_TYPE_TAG_UTF8:
	    {
		SV *sv = newSVGChar (arg->v_string);
		if (own)
			g_free (arg->v_string);
		return sv;
	    }

	    case GI_TYPE_TAG_FILENAME:
	    {
		SV *sv = newSVpv (arg->v_string, 0);
		if (own)
			g_free (arg->v_string);
		return sv;
	    }

	    default:
		ccroak ("Unhandled info tag %d in arg_to_sv", tag);
	}

	return NULL;
}
