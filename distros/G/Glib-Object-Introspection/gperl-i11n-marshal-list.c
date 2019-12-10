/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void
_free_list (gpointer list)
{
	dwarn ("%p\n", list);
	g_list_free (list);
}

static void
_free_slist (gpointer list)
{
	dwarn ("%p\n", list);
	g_slist_free (list);
}

/* This may call Perl code (via arg_to_sv), so it needs to be wrapped with
 * PUTBACK/SPAGAIN by the caller. */
static SV *
glist_to_sv (GITypeInfo* info,
             gpointer pointer,
             GITransfer transfer)
{
	GITypeInfo *param_info;
	GITransfer item_transfer;
	gboolean is_slist;
	GSList *i;
	AV *av;
	SV *value;

	if (pointer == NULL) {
		return &PL_sv_undef;
	}

	/* FIXME: What about an array containing arrays of strings, where the
	 * outer array is GI_TRANSFER_EVERYTHING but the inner arrays are
	 * GI_TRANSFER_CONTAINER? */
	item_transfer = GI_TRANSFER_EVERYTHING == transfer
		? GI_TRANSFER_EVERYTHING
		: GI_TRANSFER_NOTHING;

	param_info = g_type_info_get_param_type (info, 0);
	dwarn ("pointer = %p, param_info = %p, param tag = %d (%s)\n",
	       pointer,
	       param_info,
	       g_type_info_get_tag (param_info),
	       g_type_tag_to_string (g_type_info_get_tag (param_info)));

	is_slist = GI_TYPE_TAG_GSLIST == g_type_info_get_tag (info);

	av = newAV ();
	for (i = pointer; i; i = i->next) {
		GIArgument arg = {0,};
		dwarn ("  element %p: %p\n", i, i->data);
		arg.v_pointer = i->data;
		value = arg_to_sv (&arg,
		                   param_info,
		                   item_transfer,
		                   GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
		                   NULL);
		if (value)
			av_push (av, value);
	}

	if (transfer >= GI_TRANSFER_CONTAINER) {
		if (is_slist)
			g_slist_free (pointer);
		else
			g_list_free (pointer);
	}

	g_base_info_unref ((GIBaseInfo *) param_info);

	dwarn ("  -> AV = %p, length = %ld\n", av, av_len (av) + 1);

	return newRV_noinc ((SV *) av);
}

static gpointer
sv_to_glist (GITransfer transfer, GITypeInfo * type_info, SV * sv, GPerlI11nInvocationInfo *iinfo)
{
	AV *av;
	GITransfer item_transfer;
	gpointer list = NULL;
	GITypeInfo *param_info;
	gboolean is_slist;
	gint i, length;

	dwarn ("sv = %p\n", sv);

	if (!gperl_sv_is_defined (sv))
		return NULL;

	if (!gperl_sv_is_array_ref (sv))
		ccroak ("need an array ref to convert to GList");
	av = (AV *) SvRV (sv);

	item_transfer = GI_TRANSFER_EVERYTHING == transfer
		? GI_TRANSFER_EVERYTHING
		: GI_TRANSFER_NOTHING;

	param_info = g_type_info_get_param_type (type_info, 0);
	dwarn ("  param_info = %p, param tag = %d (%s), transfer = %d\n",
	       param_info,
	       g_type_info_get_tag (param_info),
	       g_type_tag_to_string (g_type_info_get_tag (param_info)),
	       transfer);

	is_slist = GI_TYPE_TAG_GSLIST == g_type_info_get_tag (type_info);

	length = av_len (av) + 1;
	for (i = 0; i < length; i++) {
		SV **svp;
		svp = av_fetch (av, i, 0);
		dwarn ("  element %d: svp = %p\n", i, svp);
		if (svp && gperl_sv_is_defined (*svp)) {
			GIArgument arg;
			/* FIXME: Is it OK to always allow undef here? */
			sv_to_arg (*svp, &arg, NULL, param_info,
			           item_transfer, TRUE, NULL);
			/* ENHANCEME: Could use g_[s]list_prepend and
			 * later _reverse for efficiency. */
			if (is_slist)
				list = g_slist_append (list, arg.v_pointer);
			else
				list = g_list_append (list, arg.v_pointer);
		}
	}

	if (GI_TRANSFER_NOTHING == transfer)
		free_after_call (iinfo,
		                 is_slist ? _free_slist : _free_list,
		                 list);

	dwarn ("  -> list = %p, length = %d\n", list, g_list_length (list));

	g_base_info_unref ((GIBaseInfo *) param_info);

	return list;
}
