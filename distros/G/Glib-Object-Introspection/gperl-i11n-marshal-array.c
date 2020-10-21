/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

/* Arrays containing non-basic types as non-pointers need to be treated
 * specially.  Prime example: GValue *values = g_new0 (GValue, n);
 */
static gboolean
_need_struct_value_semantics (GIArrayType array_type, GITypeInfo *param_info, GITypeTag param_tag)
{
	gboolean is_flat, need_struct_value_semantics;

	is_flat =
		/* is a raw array, and ... */
		(GI_ARRAY_TYPE_C == array_type || GI_ARRAY_TYPE_ARRAY == array_type) &&
		/* ... contains a compound type, and... */
		!G_TYPE_TAG_IS_BASIC (param_tag) &&
		/* ... contains non-pointers */
		!g_type_info_is_pointer (param_info);

	need_struct_value_semantics = is_flat;
	if (GI_TYPE_TAG_INTERFACE == param_tag) {
		/* FIXME: Try to use the invocation info here to avoid getting
		 * the interface info again? */
		GIBaseInfo *interface_info = g_type_info_get_interface (param_info);
		switch (g_base_info_get_type (interface_info)) {
		case GI_INFO_TYPE_ENUM:
		case GI_INFO_TYPE_FLAGS:
			need_struct_value_semantics = FALSE;
		default:
			break;
		}
		g_base_info_unref (interface_info);
	}

	return need_struct_value_semantics;
}

static void
_free_raw_array (gpointer raw_array)
{
	dwarn ("%p\n", raw_array);
	g_free (raw_array);
}

static void
_free_array (GArray *array, gboolean free_content)
{
	dwarn ("%p: free_content=%d\n", array, free_content);
	g_array_free (array, free_content);
}

static void
_free_array_and_content (gpointer array)
{
	_free_array (array, TRUE);
}

static void
_free_ptr_array (GPtrArray *array, gboolean free_content)
{
	dwarn ("%p: free_content=%d\n", array, free_content);
	g_ptr_array_free (array, free_content);
}

static void
_free_ptr_array_and_content (gpointer array)
{
	_free_ptr_array (array, TRUE);
}

static void
_free_byte_array (GByteArray *array, gboolean free_content)
{
	dwarn ("%p: free_content=%d\n", array, free_content);
	g_byte_array_free (array, free_content);
}

static void
_free_byte_array_and_content (gpointer array)
{
	_free_byte_array (array, TRUE);
}

/* This may call Perl code (via arg_to_sv), so it needs to be wrapped with
 * PUTBACK/SPAGAIN by the caller. */
static SV *
array_to_sv (GITypeInfo *info,
             gpointer pointer,
             GITransfer transfer,
             GPerlI11nInvocationInfo *iinfo)
{
	GIArrayType array_type;
	gpointer array = NULL, elements = NULL;
	GITypeInfo *param_info;
	GITypeTag param_tag;
	gsize item_size;
	GITransfer item_transfer;
	gboolean free_element_data;
	gboolean need_struct_value_semantics;
	gssize length = -1, i;
	AV *av;

	dwarn ("pointer %p\n", pointer);

	if (pointer == NULL) {
		return &PL_sv_undef;
	}

	array_type = g_type_info_get_array_type (info);

#define GET_LENGTH_AND_ELEMENTS(type, len_field, data_field) { \
		array = pointer; \
		length = ((type *) array)->len_field; \
		elements = ((type *) array)->data_field; }

	switch (array_type) {
	case GI_ARRAY_TYPE_C:
		array = pointer;
		elements = pointer;
		if (g_type_info_is_zero_terminated (info)) {
			length = g_strv_length (elements);
		} else {
			length = g_type_info_get_array_fixed_size (info);
			if (length < 0) {
				SV *conversion_sv;
				gint length_pos = g_type_info_get_array_length (info);
				g_assert (iinfo && iinfo->aux_args);
				conversion_sv = arg_to_sv (&(iinfo->aux_args[length_pos]),
				                           &(iinfo->arg_types[length_pos]),
				                           GI_TRANSFER_NOTHING,
				                           GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
				                           NULL);
				length = SvIV (conversion_sv);
				SvREFCNT_dec (conversion_sv);
			}
		}
		break;
	case GI_ARRAY_TYPE_ARRAY:
		GET_LENGTH_AND_ELEMENTS (GArray, len, data);
		break;
	case GI_ARRAY_TYPE_PTR_ARRAY:
		GET_LENGTH_AND_ELEMENTS (GPtrArray, len, pdata);
		break;
	case GI_ARRAY_TYPE_BYTE_ARRAY:
		GET_LENGTH_AND_ELEMENTS (GByteArray, len, data);
		break;
	default:
		ccroak ("Unhandled array type %d", array_type);
	}

#undef GET_LENGTH_AND_ELEMENTS

	if (length < 0) {
		ccroak ("Could not determine the length of the array");
	}

	param_info = g_type_info_get_param_type (info, 0);
	param_tag = g_type_info_get_tag (param_info);
	item_size = size_of_type_info (param_info);

	/* FIXME: What about an array containing arrays of strings, where the
	 * outer array is GI_TRANSFER_EVERYTHING but the inner arrays are
	 * GI_TRANSFER_CONTAINER? */
	item_transfer = transfer == GI_TRANSFER_EVERYTHING
		? GI_TRANSFER_EVERYTHING
		: GI_TRANSFER_NOTHING;

	av = newAV ();

	need_struct_value_semantics =
		_need_struct_value_semantics (array_type, param_info, param_tag);
	dwarn ("value semantics = %d\n", need_struct_value_semantics);

	dwarn ("type %d, array %p, elements %p\n",
	       array_type, array, elements);
	dwarn ("length %"G_GSSIZE_FORMAT", item size %"G_GSIZE_FORMAT", param_info %p, param_tag %d (%s)\n",
	       length,
	       item_size,
	       param_info,
	       param_tag,
	       g_type_tag_to_string (param_tag));

	for (i = 0; i < length; i++) {
		GIArgument arg;
		SV *value = NULL;
		gpointer element = elements + ((gsize) i) * item_size;
		gpointer raw_pointer = element;
		GPerlI11nMemoryScope mem_scope = GPERL_I11N_MEMORY_SCOPE_IRRELEVANT;
		if (need_struct_value_semantics) {
			raw_pointer = &element;
			mem_scope = GPERL_I11N_MEMORY_SCOPE_TEMPORARY;
		}
		dwarn ("  element %"G_GSSIZE_FORMAT": %p, pointer: %p\n", i, element, raw_pointer);
		raw_to_arg (raw_pointer, &arg, param_info);
		value = arg_to_sv (&arg, param_info, item_transfer, mem_scope, iinfo);
		if (value)
			av_push (av, value);
	}

	if (transfer >= GI_TRANSFER_CONTAINER) {
		/* When we were transfered ownership of the array, we need to
		   free it and its element storage here.  This is safe since,
		   if the array was flat, we made sure to take copies of the
		   elements above. */
		free_element_data = TRUE;
		switch (array_type) {
		case GI_ARRAY_TYPE_C:
			_free_raw_array (array);
			break;
		case GI_ARRAY_TYPE_ARRAY:
			_free_array (array, free_element_data);
			break;
		case GI_ARRAY_TYPE_PTR_ARRAY:
			_free_ptr_array (array, free_element_data);
			break;
		case GI_ARRAY_TYPE_BYTE_ARRAY:
			_free_byte_array (array, free_element_data);
			break;
		}
	}

	g_base_info_unref ((GIBaseInfo *) param_info);

	dwarn ("  -> AV %p of length %"G_GSIZE_FORMAT"\n",
	       av, av_len (av) + 1);

	return newRV_noinc ((SV *) av);
}

static gpointer
sv_to_array (GITransfer transfer,
             GITypeInfo *type_info,
             SV *sv,
             GPerlI11nInvocationInfo *iinfo)
{
	AV *av;
	GIArrayType array_type;
	GITransfer item_transfer;
	GITypeInfo *param_info;
	GITypeTag param_tag;
	gint length_pos;
	gsize i, length;
	GPerlI11nArrayInfo *array_info = NULL;
	gpointer array = NULL;
	gpointer return_array;
	GDestroyNotify return_array_free_func;
	gboolean is_zero_terminated = FALSE;
	gsize item_size;
	gboolean need_struct_value_semantics;

	dwarn ("sv %p\n", sv);

	/* Add an array info entry even before the undef check so that the
	 * corresponding length arg is set to zero later by
	 * _handle_automatic_arg. */
	length_pos = g_type_info_get_array_length (type_info);
	if (length_pos >= 0) {
		array_info = g_new0 (GPerlI11nArrayInfo, 1);
		array_info->length_pos = length_pos;
		array_info->length = 0;
		iinfo->array_infos = g_slist_prepend (iinfo->array_infos, array_info);
	}

	if (!gperl_sv_is_defined (sv))
		return NULL;

	array_type = g_type_info_get_array_type (type_info);

	item_transfer = transfer == GI_TRANSFER_CONTAINER
		      ? GI_TRANSFER_NOTHING
		      : transfer;

	param_info = g_type_info_get_param_type (type_info, 0);
	param_tag = g_type_info_get_tag (param_info);
	dwarn ("type %d, param_info %p, param_tag %d (%s), transfer %d\n",
	       array_type,
	       param_info,
	       param_tag,
	       g_type_tag_to_string (param_tag),
	       transfer);

	need_struct_value_semantics =
		_need_struct_value_semantics (array_type, param_info, param_tag);
	is_zero_terminated = g_type_info_is_zero_terminated (type_info);
	item_size = size_of_type_info (param_info);

	if (!gperl_sv_is_array_ref (sv)) {
		// special-case const guchar* with transfer=none
		if (SvPOK (sv) && param_tag == GI_TYPE_TAG_UINT8 && transfer == GI_TRANSFER_NOTHING) {
			STRLEN string_length = 0;
			char* string = SvPV (sv, string_length);
			if (length_pos >= 0) {
				array_info->length = is_zero_terminated ? string_length : string_length - 1;
			}
			return string;
		} else {
			ccroak ("need an array ref to convert to GArray");
		}
	}

	av = (AV *) SvRV (sv);
	length = (gsize) (av_len (av) + 1); /* av_len always returns at least -1 */

	switch (array_type) {
	case GI_ARRAY_TYPE_C:
	case GI_ARRAY_TYPE_ARRAY:
		array = g_array_sized_new (is_zero_terminated, FALSE, item_size, length);
		break;
	case GI_ARRAY_TYPE_PTR_ARRAY:
		array = g_ptr_array_sized_new (length);
		g_ptr_array_set_size (array, length);
		break;
	case GI_ARRAY_TYPE_BYTE_ARRAY:
		array = g_byte_array_sized_new (length);
		g_byte_array_set_size (array, length);
		break;
	}

	for (i = 0; i < length; i++) {
		SV **svp;
		svp = av_fetch (av, i, 0);
		dwarn ("  element %"G_GSIZE_FORMAT": svp = %p\n", i, svp);
		if (svp && gperl_sv_is_defined (*svp)) {
			GIArgument arg;

			/* FIXME: Is it OK to always allow undef here? */
			sv_to_arg (*svp, &arg, NULL, param_info,
			           item_transfer, TRUE, NULL);

			switch (array_type) {
			case GI_ARRAY_TYPE_C:
			case GI_ARRAY_TYPE_ARRAY:
				if (need_struct_value_semantics) {
					/* Copy from the memory area pointed to by
					 * arg.v_pointer. */
					g_array_insert_vals (array, i, arg.v_pointer, 1);
				} else {
					/* Copy from &arg, i.e. the memory area that is
					 * arg. */
					g_array_insert_val (array, i, arg);
				}
				break;
			case GI_ARRAY_TYPE_PTR_ARRAY:
				((GPtrArray *) array)->pdata[i] = arg.v_pointer;
				break;
			case GI_ARRAY_TYPE_BYTE_ARRAY:
				((GByteArray *) array)->data[i] = arg.v_uint8;
				break;
			}
		}
	}

	if (length_pos >= 0) {
		array_info->length = length;
	}

	return_array = array;
	return_array_free_func = NULL;
	switch (array_type) {
	case GI_ARRAY_TYPE_C:
		return_array = g_array_free (array, FALSE);
		return_array_free_func = _free_raw_array;
		break;
	case GI_ARRAY_TYPE_ARRAY:
		return_array_free_func = _free_array_and_content;
		break;
	case GI_ARRAY_TYPE_PTR_ARRAY:
		return_array_free_func = _free_ptr_array_and_content;
		break;
	case GI_ARRAY_TYPE_BYTE_ARRAY:
		return_array_free_func = _free_byte_array_and_content;
		break;
	}

	if (GI_TRANSFER_NOTHING == transfer) {
		free_after_call (iinfo, return_array_free_func, return_array);
	}

	g_base_info_unref ((GIBaseInfo *) param_info);

	dwarn ("  -> array %p of length %"G_GSIZE_FORMAT"\n",
	       return_array, length);

	return return_array;
}
