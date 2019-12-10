/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void _prepare_c_invocation_info (GPerlI11nCInvocationInfo *iinfo,
                                        GICallableInfo *info,
                                        IV items,
                                        UV internal_stack_offset,
                                        const gchar *package,
                                        const gchar *namespace,
                                        const gchar *function);
static void _clear_c_invocation_info (GPerlI11nCInvocationInfo *iinfo);
static void _check_n_args (GPerlI11nCInvocationInfo *iinfo);
static void _handle_automatic_arg (guint pos,
                                   GIArgInfo * arg_info,
                                   GITypeInfo * arg_type,
                                   GIArgument * arg,
                                   GPerlI11nCInvocationInfo * invocation_info);
static gpointer _allocate_out_mem (GITypeInfo *arg_type);

static void
invoke_c_code (GICallableInfo *info,
               gpointer func_pointer,
               SV **sp, I32 ax, SV **mark, I32 items, /* these correspond to dXSARGS */
               UV internal_stack_offset,
               const gchar *package,
               const gchar *namespace,
               const gchar *function)
{
	ffi_cif cif;
	gpointer instance = NULL;
	guint i;
	GPerlI11nCInvocationInfo iinfo;
	guint n_return_values;
#if GI_CHECK_VERSION (1, 32, 0)
	GIFFIReturnValue ffi_return_value;
#endif
	gpointer return_value_p;
	GIArgument return_value;
	GError * local_error = NULL;
	gpointer local_error_address = &local_error;

	PERL_UNUSED_VAR (mark);

	_prepare_c_invocation_info (&iinfo, info, items, internal_stack_offset,
	                            package, namespace, function);

	_check_n_args (&iinfo);

	if (iinfo.is_method) {
		instance = instance_sv_to_pointer (info, ST (0 + iinfo.stack_offset), &iinfo.base);
		iinfo.arg_types_ffi[0] = &ffi_type_pointer;
		iinfo.args[0] = &instance;
	}

	/*
	 * --- handle arguments -----------------------------------------------
	 */

	for (i = 0 ; i < iinfo.base.n_args ; i++) {
		GIArgInfo * arg_info;
		GITypeInfo * arg_type;
		GITransfer transfer;
		gboolean may_be_null = FALSE, is_skipped = FALSE;
		gint perl_stack_pos, ffi_stack_pos;
		SV *current_sv;

		arg_info = &(iinfo.base.arg_infos[i]);
		arg_type = &(iinfo.base.arg_types[i]);
		transfer = g_arg_info_get_ownership_transfer (arg_info);
		may_be_null = g_arg_info_may_be_null (arg_info);
#if GI_CHECK_VERSION (1, 29, 0)
		is_skipped = g_arg_info_is_skip (arg_info);
#endif
		perl_stack_pos = (gint) i
		               + (gint) iinfo.constructor_offset
		               + (gint) iinfo.method_offset
		               + (gint) iinfo.stack_offset
		               + iinfo.dynamic_stack_offset;
		ffi_stack_pos = (gint) i
		              + (gint) iinfo.method_offset;
		g_assert (perl_stack_pos >= 0 && ffi_stack_pos >= 0);

		/* FIXME: Is this right?  I'm confused about the relation of
		 * the numbers in g_callable_info_get_arg and
		 * g_arg_info_get_closure and g_arg_info_get_destroy.  We used
		 * to add method_offset, but that stopped being correct at some
		 * point. */
		iinfo.base.current_pos = i; /* + method_offset; */

		dwarn ("arg %d: tag = %d (%s), is_pointer = %d, is_automatic = %d\n",
		       i,
		       g_type_info_get_tag (arg_type),
		       g_type_tag_to_string (g_type_info_get_tag (arg_type)),
		       g_type_info_is_pointer (arg_type),
		       iinfo.is_automatic_arg[i]);

		/* Use undef for missing args (due to the checks above, these
		 * must be nullable). */
		current_sv = perl_stack_pos < items ? ST (perl_stack_pos) : &PL_sv_undef;

		switch (g_arg_info_get_direction (arg_info)) {
		    case GI_DIRECTION_IN:
			if (iinfo.is_automatic_arg[i]) {
				iinfo.dynamic_stack_offset--;
			} else if (is_skipped) {
				iinfo.dynamic_stack_offset--;
			} else {
				sv_to_arg (current_sv,
				           &iinfo.in_args[i], arg_info, arg_type,
				           transfer, may_be_null, &iinfo.base);
			}
			iinfo.arg_types_ffi[ffi_stack_pos] =
				g_type_info_get_ffi_type (arg_type);
			iinfo.args[ffi_stack_pos] = &iinfo.in_args[i];
			break;

		    case GI_DIRECTION_OUT:
			if (g_arg_info_is_caller_allocates (arg_info)) {
				iinfo.base.aux_args[i].v_pointer =
					_allocate_out_mem (arg_type);
				iinfo.out_args[i].v_pointer = &iinfo.base.aux_args[i];
				iinfo.args[ffi_stack_pos] = &iinfo.base.aux_args[i];
			} else {
				iinfo.out_args[i].v_pointer = &iinfo.base.aux_args[i];
				iinfo.args[ffi_stack_pos] = &iinfo.out_args[i];
			}
			iinfo.arg_types_ffi[ffi_stack_pos] = &ffi_type_pointer;
			/* Adjust the dynamic stack offset so that this out
			 * argument doesn't inadvertedly eat up an in argument. */
			iinfo.dynamic_stack_offset--;
			break;

		    case GI_DIRECTION_INOUT:
			iinfo.in_args[i].v_pointer =
				iinfo.out_args[i].v_pointer =
					&iinfo.base.aux_args[i];
			if (iinfo.is_automatic_arg[i]) {
				iinfo.dynamic_stack_offset--;
			} else if (is_skipped) {
				iinfo.dynamic_stack_offset--;
			} else {
				/* We pass iinfo.in_args[i].v_pointer here,
				 * not &iinfo.in_args[i], so that the value
				 * pointed to is filled from the SV. */
				sv_to_arg (current_sv,
				           iinfo.in_args[i].v_pointer, arg_info, arg_type,
				           transfer, may_be_null, &iinfo.base);
			}
			iinfo.arg_types_ffi[ffi_stack_pos] = &ffi_type_pointer;
			iinfo.args[ffi_stack_pos] = &iinfo.in_args[i];
			break;
		}
	}

	/* do another pass to handle automatic args */
	for (i = 0 ; i < iinfo.base.n_args ; i++) {
		GIArgInfo * arg_info;
		GITypeInfo * arg_type;
		if (!iinfo.is_automatic_arg[i])
			continue;
		arg_info = &(iinfo.base.arg_infos[i]);
		arg_type = &(iinfo.base.arg_types[i]);
		switch (g_arg_info_get_direction (arg_info)) {
		    case GI_DIRECTION_IN:
			_handle_automatic_arg (i, arg_info, arg_type, &iinfo.in_args[i], &iinfo);
			break;
		    case GI_DIRECTION_INOUT:
			_handle_automatic_arg (i, arg_info, arg_type, &iinfo.base.aux_args[i], &iinfo);
			break;
		    case GI_DIRECTION_OUT:
			/* handled later */
			break;
		}
	}

	if (iinfo.throws) {
		iinfo.args[iinfo.n_invoke_args - 1] = &local_error_address;
		iinfo.arg_types_ffi[iinfo.n_invoke_args - 1] = &ffi_type_pointer;
	}

	/*
	 * --- prepare & call -------------------------------------------------
	 */

	/* prepare and call the function */
	if (FFI_OK != ffi_prep_cif (&cif, FFI_DEFAULT_ABI, iinfo.n_invoke_args,
	                            iinfo.base.return_type_ffi, iinfo.arg_types_ffi))
	{
		_clear_c_invocation_info (&iinfo);
		ccroak ("Could not prepare a call interface");
	}

#if GI_CHECK_VERSION (1, 32, 0)
	return_value_p = &ffi_return_value;
#else
	return_value_p = &return_value;
#endif

	/* Wrap the call in PUTBACK/SPAGAIN because the C function might end up
	 * calling Perl code (via a vfunc), which might reallocate the stack
	 * and hence invalidate 'sp'. */
	PUTBACK;
	ffi_call (&cif, func_pointer, return_value_p, iinfo.args);
	SPAGAIN;

	/* free call-scoped data */
	invoke_free_after_call_handlers (&iinfo.base);

	if (local_error) {
		_clear_c_invocation_info (&iinfo);
		gperl_croak_gerror (NULL, local_error);
	}

	/*
	 * --- handle return values -------------------------------------------
	 */

#if GI_CHECK_VERSION (1, 32, 0)
	/* libffi has special semantics for return value storage; see `man
	 * ffi_call`.  We use gobject-introspection's extraction helper. */
	gi_type_info_extract_ffi_return_value (&iinfo.base.return_type_info,
	                                       &ffi_return_value,
	                                       &return_value);
#endif

	n_return_values = 0;

	/* place return value and output args on the stack */
	if (iinfo.base.has_return_value
#if GI_CHECK_VERSION (1, 29, 0)
	    && !g_callable_info_skip_return ((GICallableInfo *) info)
#endif
	   )
	{
		SV *value;
		dwarn ("return value: type = %p\n", &iinfo.base.return_type_info);
		value = SAVED_STACK_SV (arg_to_sv (&return_value,
		                                   &iinfo.base.return_type_info,
		                                   iinfo.base.return_type_transfer,
		                                   GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
		                                   &iinfo.base));
		if (value) {
			XPUSHs (sv_2mortal (value));
			n_return_values++;
		}
	}

	/* out args */
	for (i = 0 ; i < iinfo.base.n_args ; i++) {
		GIArgInfo * arg_info;
		if (iinfo.is_automatic_arg[i])
			continue;
		arg_info = &(iinfo.base.arg_infos[i]);
#if GI_CHECK_VERSION (1, 29, 0)
		if (g_arg_info_is_skip (arg_info)) {
			continue;
		}
#endif
		switch (g_arg_info_get_direction (arg_info)) {
		    case GI_DIRECTION_OUT:
		    case GI_DIRECTION_INOUT:
		    {
			GITransfer transfer;
			SV *sv;
			dwarn ("out/inout arg at pos %d\n", i);
			/* If we allocated the memory ourselves, we always own it. */
			transfer = g_arg_info_is_caller_allocates (arg_info)
			         ? GI_TRANSFER_CONTAINER
			         : g_arg_info_get_ownership_transfer (arg_info);
			sv = SAVED_STACK_SV (arg_to_sv (iinfo.out_args[i].v_pointer,
			                                &(iinfo.base.arg_types[i]),
			                                transfer,
			                                GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
			                                &iinfo.base));
			if (sv) {
				XPUSHs (sv_2mortal (sv));
				n_return_values++;
			}
			break;
		    }

		    default:
			break;
		}
	}

	_clear_c_invocation_info (&iinfo);

	dwarn ("n_return_values = %d\n", n_return_values);

	PUTBACK;
}

/* ------------------------------------------------------------------------- */

static void
_prepare_c_invocation_info (GPerlI11nCInvocationInfo *iinfo,
                            GICallableInfo *info,
                            IV items,
                            UV internal_stack_offset,
                            const gchar *package,
                            const gchar *namespace,
                            const gchar *function)
{
	guint i;

	prepare_invocation_info ((GPerlI11nInvocationInfo *) iinfo, info);

	dwarn ("%s::%s::%s => %s\n",
	       package, namespace, function,
	       g_base_info_get_name (info));

	iinfo->target_package = package;
	iinfo->target_namespace = namespace;
	iinfo->target_function = function;

	iinfo->stack_offset = (guint) internal_stack_offset;
	g_assert (items >= iinfo->stack_offset);
	iinfo->n_given_args = ((guint) items) - iinfo->stack_offset;
	iinfo->n_invoke_args = iinfo->base.n_args;

	iinfo->is_constructor = FALSE;
	if (iinfo->base.is_function) {
		iinfo->is_constructor =
			g_function_info_get_flags (info) & GI_FUNCTION_IS_CONSTRUCTOR;
	}

	/* FIXME: can a vfunc not throw? */
	iinfo->throws = FALSE;
	if (iinfo->base.is_function) {
		iinfo->throws =
			g_function_info_get_flags (info) & GI_FUNCTION_THROWS;
	}
	if (iinfo->throws) {
		/* Add one for the implicit GError arg. */
		iinfo->n_invoke_args++;
	}

	if (iinfo->base.is_vfunc) {
		iinfo->is_method = TRUE;
	} else if (iinfo->base.is_callback) {
		iinfo->is_method = FALSE;
	} else {
		iinfo->is_method =
			(g_function_info_get_flags (info) & GI_FUNCTION_IS_METHOD)
			&& !iinfo->is_constructor;
	}
	if (iinfo->is_method) {
		/* Add one for the implicit invocant arg. */
		iinfo->n_invoke_args++;
	}

	dwarn ("  args = %u, given = %u, invoke = %u\n",
	       iinfo->base.n_args,
	       iinfo->n_given_args,
	       iinfo->n_invoke_args);

	dwarn ("  symbol = %s\n",
	       iinfo->base.is_vfunc ? g_base_info_get_name (info) : g_function_info_get_symbol (info));

	dwarn ("  is_constructor = %d, is_method = %d, throws = %d\n",
	       iinfo->is_constructor, iinfo->is_method, iinfo->throws);

	/* allocate enough space for all args in both the out and in lists.
	 * we'll only use as much as we need.  since function argument lists
	 * are typically small, this shouldn't be a big problem. */
	if (iinfo->n_invoke_args) {
		guint n = iinfo->n_invoke_args;
		iinfo->in_args = gperl_alloc_temp (sizeof (GIArgument) * n);
		iinfo->out_args = gperl_alloc_temp (sizeof (GIArgument) * n);
		iinfo->arg_types_ffi = gperl_alloc_temp (sizeof (ffi_type *) * n);
		iinfo->args = gperl_alloc_temp (sizeof (gpointer) * n);
		iinfo->is_automatic_arg = gperl_alloc_temp (sizeof (gboolean) * n);
	}

	/* If we call a constructor, we skip the initial package name resulting
	 * from the "Package->new" syntax.  If we call a method, we handle the
	 * invocant separately. */
	iinfo->constructor_offset = iinfo->is_constructor ? 1 : 0;
	iinfo->method_offset = iinfo->is_method ? 1 : 0;
	iinfo->dynamic_stack_offset = 0;

	/* Make a first pass to mark args that are filled in automatically, and
	 * thus have no counterpart on the Perl side. */
	for (i = 0 ; i < iinfo->base.n_args ; i++) {
		GIArgInfo * arg_info = &(iinfo->base.arg_infos[i]);
		GITypeInfo * arg_type = &(iinfo->base.arg_types[i]);
		GITypeTag arg_tag = g_type_info_get_tag (arg_type);

		if (arg_tag == GI_TYPE_TAG_ARRAY) {
			gint pos = g_type_info_get_array_length (arg_type);
			if (pos >= 0) {
				dwarn ("  pos %d is automatic (array length)\n", pos);
				iinfo->is_automatic_arg[pos] = TRUE;
			}
		}

		else if (arg_tag == GI_TYPE_TAG_INTERFACE) {
			GIBaseInfo * interface = g_type_info_get_interface (arg_type);
			GIInfoType info_type = g_base_info_get_type (interface);
			if (info_type == GI_INFO_TYPE_CALLBACK) {
				gint pos = g_arg_info_get_destroy (arg_info);
				if (pos >= 0) {
					dwarn ("  pos %d is automatic (callback destroy notify)\n", pos);
					iinfo->is_automatic_arg[pos] = TRUE;
				}
			}
			g_base_info_unref ((GIBaseInfo *) interface);
		}
	}

	/* Make another pass to count the expected args. */
	iinfo->n_expected_args = iinfo->constructor_offset + iinfo->method_offset;
	iinfo->n_nullable_args = 0;
	for (i = 0 ; i < iinfo->base.n_args ; i++) {
		GIArgInfo * arg_info = &(iinfo->base.arg_infos[i]);
		GITypeInfo * arg_type = &(iinfo->base.arg_types[i]);
		GITypeTag arg_tag = g_type_info_get_tag (arg_type);
		gboolean is_out = GI_DIRECTION_OUT == g_arg_info_get_direction (arg_info);
		gboolean is_automatic = iinfo->is_automatic_arg[i];
		gboolean is_skipped = FALSE;
#if GI_CHECK_VERSION (1, 29, 0)
		is_skipped = g_arg_info_is_skip (arg_info);
#endif

		if (!is_out && !is_automatic && !is_skipped)
			iinfo->n_expected_args++;
		/* Callback user data may always be NULL. */
		if (g_arg_info_may_be_null (arg_info) || arg_tag == GI_TYPE_TAG_VOID)
			iinfo->n_nullable_args++;
	}

	/* If the return value is an array which comes with an outbound length
	 * arg, then mark that length arg as automatic, too. */
	if (g_type_info_get_tag (&iinfo->base.return_type_info) == GI_TYPE_TAG_ARRAY) {
		gint pos = g_type_info_get_array_length (&iinfo->base.return_type_info);
		if (pos >= 0) {
			GIArgInfo * arg_info = &(iinfo->base.arg_infos[pos]);
			if (GI_DIRECTION_OUT == g_arg_info_get_direction (arg_info)) {
				dwarn ("  pos %d is automatic (array length)\n", pos);
				iinfo->is_automatic_arg[pos] = TRUE;
			}
		}
	}

	/* We need to undo the special handling that GInitiallyUnowned
	 * descendants receive from gobject-introspection: values of this type
	 * are always marked transfer=none, even for constructors.
	 *
	 * FIXME: This is not correct for GtkWindow and its descendants, as
	 * gtk+ keeps an internal reference to each window.  Hence,
	 * constructors like gtk_window_new return a non-floating object and do
	 * not pass ownership of a reference on to us.  But the sink func
	 * currently registered for GInitiallyUnowned (sink_initially_unowned
	 * in GObject.xs in Glib) is actually inadvertently conforming to this
	 * requirement.  It runs ref_sink+unref regardless of whether the
	 * object is floating or not.  So, in the non-floating window case, it
	 * does nothing, resulting in an extra reference taken, despite the
	 * request to transfer ownership.
	 *
	 * If we ever encounter a constructor of a GInitiallyUnowned descendant
	 * that returns a non-floating object and passes ownership of a
	 * reference on to us, or a constructor of a GInitiallyUnowned
	 * descendant that returns a floating object but passes no reference on
	 * to us, then we need to revisit this. */
	if (iinfo->is_constructor &&
	    g_type_info_get_tag (&iinfo->base.return_type_info) == GI_TYPE_TAG_INTERFACE)
	{
		GIBaseInfo * interface = g_type_info_get_interface (&iinfo->base.return_type_info);
		if (GI_IS_REGISTERED_TYPE_INFO (interface) &&
		    g_type_is_a (get_gtype (interface),
		                 G_TYPE_INITIALLY_UNOWNED))
		{
			iinfo->base.return_type_transfer = GI_TRANSFER_EVERYTHING;
		}
		g_base_info_unref ((GIBaseInfo *) interface);
	}
}

static void
_clear_c_invocation_info (GPerlI11nCInvocationInfo *iinfo)
{
	clear_invocation_info ((GPerlI11nInvocationInfo *) iinfo);
}

/* ------------------------------------------------------------------------- */

static gchar *
_format_target (GPerlI11nCInvocationInfo *iinfo)
{
	gchar *caller = NULL;
	if (iinfo->target_package && iinfo->target_namespace && iinfo->target_function) {
		caller = g_strconcat (iinfo->target_package, "::",
		                      iinfo->target_namespace, "::",
		                      iinfo->target_function,
		                      NULL);
	} else if (iinfo->target_package && iinfo->target_function) {
		caller = g_strconcat (iinfo->target_package, "::",
		                      iinfo->target_function,
		                      NULL);
	} else {
		caller = g_strconcat ("Callable ",
		                      g_base_info_get_name (iinfo->base.interface),
		                      NULL);
	}
	return caller;
}

static void
_check_n_args (GPerlI11nCInvocationInfo *iinfo)
{
	if (iinfo->n_expected_args != iinfo->n_given_args) {
		/* Avoid the cost of formatting the target until we know we
		 * need it. */
		gchar *caller = NULL;
		if (iinfo->n_given_args < (iinfo->n_expected_args - iinfo->n_nullable_args)) {
			caller = _format_target (iinfo);
			ccroak ("%s: passed too few parameters "
			        "(expected %u, got %u)",
			        caller, iinfo->n_expected_args, iinfo->n_given_args);
		} else if (iinfo->n_given_args > iinfo->n_expected_args) {
			caller = _format_target (iinfo);
			cwarn ("*** %s: passed too many parameters "
			       "(expected %u, got %u); ignoring excess",
			       caller, iinfo->n_expected_args, iinfo->n_given_args);
		}
		if (caller)
			g_free (caller);
	}
}

/* ------------------------------------------------------------------------- */

static void
_handle_automatic_arg (guint pos,
                       GIArgInfo * arg_info,
                       GITypeInfo * arg_type,
                       GIArgument * arg,
                       GPerlI11nCInvocationInfo * invocation_info)
{
	GSList *l;

	/* array length */
	for (l = invocation_info->base.array_infos; l != NULL; l = l->next) {
		GPerlI11nArrayInfo *ainfo = l->data;
		if (((gint) pos) == ainfo->length_pos) {
			SV *conversion_sv;
			dwarn ("  setting automatic arg %d (array length) to %"G_GSIZE_FORMAT"\n",
			       pos, ainfo->length);
			conversion_sv = newSVuv (ainfo->length);
			sv_to_arg (conversion_sv, arg, arg_info, arg_type,
			           GI_TRANSFER_NOTHING, FALSE, NULL);
			SvREFCNT_dec (conversion_sv);
			return;
		}
	}

	/* callback destroy notify */
	for (l = invocation_info->base.callback_infos; l != NULL; l = l->next) {
		GPerlI11nPerlCallbackInfo *cinfo = l->data;
		if (((gint) pos) == cinfo->destroy_pos) {
			dwarn ("  setting automatic arg %d (destroy notify for calllback %p)\n",
			       pos, cinfo);
			/* If the code pointer is NULL, then the user actually
			 * specified undef for the callback or nothing at all,
			 * in which case we must not install our destroy notify
			 * handler. */
			arg->v_pointer = cinfo->code ? release_perl_callback : NULL;
			return;
		}
	}

	ccroak ("Could not handle automatic arg %d", pos);
}

static gpointer
_allocate_out_mem (GITypeInfo *arg_type)
{
	GIBaseInfo *interface_info;
	GIInfoType type;
	gboolean is_boxed = FALSE;
	GType gtype = G_TYPE_INVALID;

	interface_info = g_type_info_get_interface (arg_type);
	g_assert (interface_info);
	type = g_base_info_get_type (interface_info);
	if (GI_IS_REGISTERED_TYPE_INFO (interface_info)) {
		gtype = get_gtype (interface_info);
		is_boxed = g_type_is_a (gtype, G_TYPE_BOXED);
	}
	g_base_info_unref (interface_info);

	switch (type) {
	    case GI_INFO_TYPE_STRUCT:
	    {
		/* No plain g_struct_info_get_size (interface_info) here so
		 * that we get the GValue override. */
		gsize size;
		gpointer mem;
		size = size_of_interface (arg_type);
		mem = g_malloc0 (size);
		if (is_boxed) {
			/* For a boxed type, malloc() might not be the right
			 * allocator.  For example, GtkTreeIter uses GSlice.
			 * So use g_boxed_copy() to make a copy of the newly
			 * allocated block using the correct allocator. */
			gpointer real_mem = g_boxed_copy (gtype, mem);
			g_free (mem);
			mem = real_mem;
		}
		return mem;
	    }
	    default:
		g_assert_not_reached ();
		return NULL;
	}
}
