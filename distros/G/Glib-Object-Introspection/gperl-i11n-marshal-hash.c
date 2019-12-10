/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

/* This may call Perl code (via arg_to_sv), so it needs to be wrapped with
 * PUTBACK/SPAGAIN by the caller. */
static SV *
ghash_to_sv (GITypeInfo *info,
             gpointer pointer,
             GITransfer transfer)
{
	GITypeInfo *key_param_info, *value_param_info;
#ifdef NOISY
	GITypeTag key_type_tag, value_type_tag;
#endif
	gpointer key_p, value_p;
	GITransfer item_transfer;
	GHashTableIter iter;
	HV *hv;

	dwarn ("pointer = %p\n", pointer);

	if (pointer == NULL) {
		return &PL_sv_undef;
	}

	item_transfer = transfer == GI_TRANSFER_EVERYTHING
	              ? GI_TRANSFER_EVERYTHING
	              : GI_TRANSFER_NOTHING;

	key_param_info = g_type_info_get_param_type (info, 0);
	value_param_info = g_type_info_get_param_type (info, 1);

#ifdef NOISY
	key_type_tag = g_type_info_get_tag (key_param_info);
	value_type_tag = g_type_info_get_tag (value_param_info);
#endif

	dwarn ("  key tag = %d (%s), value tag = %d (%s)\n",
	       key_type_tag, g_type_tag_to_string (key_type_tag),
	       value_type_tag, g_type_tag_to_string (value_type_tag));

	hv = newHV ();

	g_hash_table_iter_init (&iter, pointer);
	while (g_hash_table_iter_next (&iter, &key_p, &value_p)) {
		GIArgument arg = { 0, };
		SV *key_sv, *value_sv;

		dwarn ("  key pointer %p\n", key_p);
		arg.v_pointer = key_p;
		key_sv = arg_to_sv (&arg,
		                    key_param_info,
		                    item_transfer,
		                    GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
		                    NULL);
		if (key_sv == NULL)
                        break;

		dwarn ("  value pointer %p\n", value_p);
		arg.v_pointer = value_p;
		value_sv = arg_to_sv (&arg,
		                      value_param_info,
		                      item_transfer,
		                      GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
		                      NULL);
		if (value_sv == NULL)
			break;

		(void) hv_store_ent (hv, key_sv, value_sv, 0);
	}

	g_base_info_unref ((GIBaseInfo *) key_param_info);
	g_base_info_unref ((GIBaseInfo *) value_param_info);

	return newRV_noinc ((SV *) hv);
}

static gpointer
sv_to_ghash (GITransfer transfer,
             GITypeInfo *type_info,
             SV *sv)
{
	HV *hv;
	HE *he;
	GITransfer item_transfer;
	gpointer hash;
	GITypeInfo *key_param_info, *value_param_info;
	GITypeTag key_type_tag;
	GHashFunc hash_func;
	GEqualFunc equal_func;
	I32 n_keys;

	dwarn ("sv = %p\n", sv);

	if (!gperl_sv_is_defined (sv))
		return NULL;

	if (!gperl_sv_is_hash_ref (sv))
		ccroak ("need an hash ref to convert to GHashTable");

	hv = (HV *) SvRV (sv);

	item_transfer = GI_TRANSFER_NOTHING;
	switch (transfer) {
	    case GI_TRANSFER_EVERYTHING:
		item_transfer = GI_TRANSFER_EVERYTHING;
		break;
	    case GI_TRANSFER_CONTAINER:
		/* nothing special to do */
		break;
	    case GI_TRANSFER_NOTHING:
		/* FIXME: need to free hash after call */
		break;
	}

	key_param_info = g_type_info_get_param_type (type_info, 0);
	value_param_info = g_type_info_get_param_type (type_info, 1);

	key_type_tag = g_type_info_get_tag (key_param_info);

	switch (key_type_tag) {
	    case GI_TYPE_TAG_FILENAME:
	    case GI_TYPE_TAG_UTF8:
		hash_func = g_str_hash;
		equal_func = g_str_equal;
		break;

	    default:
		hash_func = NULL;
		equal_func = NULL;
		break;
	}

	dwarn ("  transfer = %d, key info = %p, key tag = %d (%s), value info = %p, value tag = %d (%s)\n",
	       transfer,
	       key_param_info,
	       g_type_info_get_tag (key_param_info),
	       g_type_tag_to_string (g_type_info_get_tag (key_param_info)),
	       value_param_info,
	       g_type_info_get_tag (value_param_info),
	       g_type_tag_to_string (g_type_info_get_tag (value_param_info)));

	hash = g_hash_table_new (hash_func, equal_func);

	n_keys = hv_iterinit (hv);
	if (n_keys == 0)
		goto out;

	while ((he = hv_iternext (hv)) != NULL) {
		SV *sv;
		GIArgument arg = { 0, };
		gpointer key_p, value_p;

		key_p = value_p = NULL;

		sv = hv_iterkeysv (he);
		dwarn ("  key SV %p\n", sv);
		if (sv && gperl_sv_is_defined (sv)) {
			/* FIXME: Is it OK to always allow undef here? */
			sv_to_arg (sv, &arg, NULL, key_param_info,
			           item_transfer, TRUE, NULL);
			key_p = arg.v_pointer;
		}

		sv = hv_iterval (hv, he);
		dwarn ("  value SV %p\n", sv);
		if (sv && gperl_sv_is_defined (sv)) {
			sv_to_arg (sv, &arg, NULL, key_param_info,
			           item_transfer, TRUE, NULL);
			value_p = arg.v_pointer;
		}

		if (key_p != NULL && value_p != NULL)
			g_hash_table_insert (hash, key_p, value_p);
	}

out:
	dwarn ("  -> hash %p of size %d\n", hash, g_hash_table_size (hash));

	g_base_info_unref ((GIBaseInfo *) key_param_info);
	g_base_info_unref ((GIBaseInfo *) value_param_info);

	return hash;
}
