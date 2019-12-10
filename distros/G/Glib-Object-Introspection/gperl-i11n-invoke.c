/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void
prepare_invocation_info (GPerlI11nInvocationInfo *iinfo,
                         GICallableInfo *info)
{
	gint orig_n_args;
	guint i;

	dwarn ("%s\n", g_base_info_get_name (info));

	iinfo->interface = info;

	iinfo->is_function = GI_IS_FUNCTION_INFO (info);
	iinfo->is_vfunc = GI_IS_VFUNC_INFO (info);
	iinfo->is_callback = (g_base_info_get_type (info) == GI_INFO_TYPE_CALLBACK);
	iinfo->is_signal = GI_IS_SIGNAL_INFO (info);
	dwarn ("  is_function = %d, is_vfunc = %d, is_callback = %d\n",
	       iinfo->is_function, iinfo->is_vfunc, iinfo->is_callback);

	orig_n_args = g_callable_info_get_n_args (info);
	g_assert (orig_n_args >= 0);
	iinfo->n_args = (guint) orig_n_args;
	dwarn ("  n_args = %u\n", iinfo->n_args);

	if (iinfo->n_args) {
		iinfo->arg_infos = gperl_alloc_temp (sizeof (GITypeInfo) * iinfo->n_args);
		iinfo->arg_types = gperl_alloc_temp (sizeof (GITypeInfo) * iinfo->n_args);
		iinfo->aux_args = gperl_alloc_temp (sizeof (GIArgument) * iinfo->n_args);
	} else {
		iinfo->arg_infos = NULL;
		iinfo->arg_types = NULL;
		iinfo->aux_args = NULL;
	}

	for (i = 0 ; i < iinfo->n_args ; i++) {
		g_callable_info_load_arg (info, (gint) i, &(iinfo->arg_infos[i]));
		g_arg_info_load_type (&(iinfo->arg_infos[i]), &(iinfo->arg_types[i]));
	}

	g_callable_info_load_return_type (info, &iinfo->return_type_info);
	iinfo->has_return_value =
		GI_TYPE_TAG_VOID != g_type_info_get_tag (&iinfo->return_type_info);
	iinfo->return_type_ffi = g_type_info_get_ffi_type (&iinfo->return_type_info);
	iinfo->return_type_transfer = g_callable_info_get_caller_owns (info);

	iinfo->callback_infos = NULL;
	iinfo->array_infos = NULL;

	iinfo->free_after_call = NULL;
}

static void
_free_array_info (gpointer ai, gpointer user_data)
{
	PERL_UNUSED_VAR (user_data);
	g_free (ai);
}

static void
clear_invocation_info (GPerlI11nInvocationInfo *iinfo)
{
	g_slist_free (iinfo->free_after_call);
	iinfo->free_after_call = NULL;

	/* The actual callback infos might be needed later, so we cannot free
	 * them here. */
	g_slist_free (iinfo->callback_infos);
	iinfo->callback_infos = NULL;

	g_slist_foreach (iinfo->array_infos, _free_array_info, NULL);
	g_slist_free (iinfo->array_infos);
	iinfo->array_infos = NULL;
}

/* ------------------------------------------------------------------------- */

typedef struct {
	GDestroyNotify func;
	gpointer data;
} FreeClosure;

static void
free_after_call (GPerlI11nInvocationInfo *iinfo, GDestroyNotify func, gpointer data)
{
	FreeClosure *closure = g_new (FreeClosure, 1);
	closure->func = func;
	closure->data = data;
	iinfo->free_after_call
		= g_slist_prepend (iinfo->free_after_call, closure);
}

static void
_invoke_free_closure (gpointer closure_in, gpointer user_data)
{
	FreeClosure *closure = closure_in;
	PERL_UNUSED_VAR (user_data);
	closure->func (closure->data);
	g_free (closure);
}

static void
invoke_free_after_call_handlers (GPerlI11nInvocationInfo *iinfo)
{
	/* We free the FreeClosures themselves directly after invoking them.  The list
	   is freed in clear_invocation_info. */
	g_slist_foreach (iinfo->free_after_call,
	                 _invoke_free_closure, NULL);
}
