/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static GPerlI11nPerlCallbackInfo *
create_perl_callback_closure (GICallableInfo *cb_info, SV *code)
{
	GPerlI11nPerlCallbackInfo *info;

	info = g_new0 (GPerlI11nPerlCallbackInfo, 1);
	if (!gperl_sv_is_defined (code))
		return info;

	info->interface = g_base_info_ref (cb_info);
	info->cif = g_new0 (ffi_cif, 1);

#if GI_CHECK_VERSION (1, 72, 0)
        info->closure =
                g_callable_info_create_closure (info->interface,
                                                info->cif,
                                                invoke_perl_code,
                                                info);
#else
        G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	info->closure =
		g_callable_info_prepare_closure (info->interface,
                                                 info->cif,
		                                 invoke_perl_code,
                                                 info);
        G_GNUC_END_IGNORE_DEPRECATIONS
#endif
	/* FIXME: This should most likely use SvREFCNT_inc instead of
	 * newSVsv. */
	info->code = newSVsv (code);
	info->sub_name = NULL;

	/* These are only relevant for signal marshalling; if needed, they get
	 * set in invoke_perl_signal_handler. */
	info->swap_data = FALSE;
	info->args_converter = NULL;

#ifdef PERL_IMPLICIT_CONTEXT
	info->priv = aTHX;
#endif

	return info;
}

static void
attach_perl_callback_data (GPerlI11nPerlCallbackInfo *info, SV *data)
{
	/* FIXME: SvREFCNT_inc? */
	info->data = newSVsv (data);
}

/* assumes ownership of sub_name */
static GPerlI11nPerlCallbackInfo *
create_perl_callback_closure_for_named_sub (GICallableInfo *cb_info, gchar *sub_name)
{
	GPerlI11nPerlCallbackInfo *info;

	info = g_new0 (GPerlI11nPerlCallbackInfo, 1);
	info->interface = g_base_info_ref (cb_info);
	info->cif = g_new0 (ffi_cif, 1);

#if GI_CHECK_VERSION (1, 72, 0)
	info->closure =
		g_callable_info_create_closure (info->interface,
                                                info->cif,
		                                invoke_perl_code,
                                                info);
#else
        G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	info->closure =
		g_callable_info_prepare_closure (info->interface,
                                                 info->cif,
		                                 invoke_perl_code,
                                                 info);
        G_GNUC_END_IGNORE_DEPRECATIONS
#endif

	info->sub_name = sub_name;
	info->code = NULL;
	info->data = NULL;

#ifdef PERL_IMPLICIT_CONTEXT
	info->priv = aTHX;
#endif

	return info;
}

static void
release_perl_callback (gpointer data)
{
	GPerlI11nPerlCallbackInfo *info = data;
	dwarn ("info = %p\n", info);

	/* g_callable_info_free_closure reaches into info->cif, so it needs to
	 * be called before we free it.  See
	 * <https://bugzilla.gnome.org/show_bug.cgi?id=652954>. */
#if defined(GI_CHECK_VERSION) && GI_CHECK_VERSION (1, 72, 0)
        if (info->closure)
                g_callable_info_destroy_closure (info->interface, info->closure);
#else
        G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	if (info->closure)
		g_callable_info_free_closure (info->interface, info->closure);
        G_GNUC_END_IGNORE_DEPRECATIONS
#endif
	if (info->cif)
		g_free (info->cif);

	if (info->interface)
		g_base_info_unref ((GIBaseInfo*) info->interface);

	if (info->code)
		SvREFCNT_dec (info->code);
	if (info->data)
		SvREFCNT_dec (info->data);
	if (info->sub_name)
		g_free (info->sub_name);

	if (info->args_converter)
		SvREFCNT_dec (info->args_converter);

	g_free (info);
}

/* -------------------------------------------------------------------------- */

static GPerlI11nCCallbackInfo *
create_c_callback_closure (GIBaseInfo *interface, gpointer func)
{
	GPerlI11nCCallbackInfo *info;

	info = g_new0 (GPerlI11nCCallbackInfo, 1);
	if (!func)
		return info;

	info->interface = interface;
	g_base_info_ref (interface);
	info->func = func;

	return info;
}

static void
attach_c_callback_data (GPerlI11nCCallbackInfo *info, gpointer data)
{
	info->data = data;
}

static void
release_c_callback (gpointer data)
{
	GPerlI11nCCallbackInfo *info = data;
	dwarn ("info = %p\n", info);

	/* FIXME: we cannot call the destroy notify here because it might be
	 * our own release_perl_callback which would try to free the ffi stuff
	 * that is currently running. */
	/* if (info->destroy) */
	/* 	info->destroy (info->data); */

	if (info->interface)
		g_base_info_unref (info->interface);

	g_free (info);
}
