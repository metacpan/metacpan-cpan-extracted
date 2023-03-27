/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void _prepare_perl_invocation_info (GPerlI11nPerlInvocationInfo *iinfo,
                                           GICallableInfo *info,
                                           gpointer *args);
static void _clear_perl_invocation_info (GPerlI11nPerlInvocationInfo *iinfo);
static void _fill_ffi_return_value (GITypeInfo *return_info,
                                    gpointer resp,
                                    GIArgument *arg);


static void
invoke_perl_code (ffi_cif* cif, gpointer resp, gpointer* args, gpointer userdata)
{
	GPerlI11nPerlCallbackInfo *info;
	GICallableInfo *cb_interface;
	GPerlI11nPerlInvocationInfo iinfo;
	guint args_offset = 0, i;
	guint in_inout;
	guint n_return_values;
	I32 n_returned;
	I32 context;
	SV *first_sv = NULL, *last_sv = NULL;
	dGPERL_CALLBACK_MARSHAL_SP;

	PERL_UNUSED_VAR (cif);

	/* unwrap callback info struct from userdata */
	info = (GPerlI11nPerlCallbackInfo *) userdata;
	cb_interface = (GICallableInfo *) info->interface;

	/* set perl context */
	GPERL_CALLBACK_MARSHAL_INIT (info);

	ENTER;
	SAVETMPS;

	_prepare_perl_invocation_info (&iinfo, cb_interface, args);

	PUSHMARK (SP);

	if (info->args_converter) {
		/* if we are given an args converter, we will call it directly
		 * after we pushed the original args onto the stack.  we then
		 * want to invoke the Perl code with whatever the args
		 * converter returned.  to achieve this, we do a double
		 * PUSHMARK, which puts on the markstack two pointers to the
		 * same place on the stack.  after the args converter returns,
		 * the markstack pointer is decremented, and the invocation of
		 * the normal Perl code then sees the other entry we put on the
		 * markstack. */
		PUSHMARK (SP);
	}

	/* convert the implicit instance argument and push the first SV onto
	 * the stack; depending on the "swap" setting, this might be the
	 * instance or the user data.  this is only relevant for signals. */
	if (iinfo.base.is_signal) {
		SV *instance_sv, *data_sv;
		args_offset = 1;
		instance_sv = SAVED_STACK_SV (instance_pointer_to_sv (
		                                cb_interface,
		                                CAST_RAW (args[0], gpointer)));
		data_sv = info->data ? SvREFCNT_inc (info->data) : NULL;
		first_sv = info->swap_data ? data_sv     : instance_sv;
		last_sv  = info->swap_data ? instance_sv : data_sv;
		dwarn ("info->data = %p, info->swap_data = %d\n",
		       info->data, info->swap_data);
		dwarn ("instance = %p, data = %p, first = %p, last = %p\n",
		       instance_sv, data_sv, first_sv, last_sv);
		if (first_sv)
			XPUSHs (sv_2mortal (first_sv));
	}

	/* find arguments; use type information from interface to find in and
	 * in-out args and their types, count in-out and out args, and find
	 * suitable converters; push in and in-out arguments onto the perl
	 * stack */
	in_inout = 0;
	for (i = 0; i < iinfo.base.n_args; i++) {
		GIArgInfo *arg_info = &(iinfo.base.arg_infos[i]);
		GITypeInfo *arg_type = &(iinfo.base.arg_types[i]);
		GITransfer transfer = g_arg_info_get_ownership_transfer (arg_info);
		GIDirection direction = g_arg_info_get_direction (arg_info);

		iinfo.base.current_pos = i;

		dwarn ("arg %d: info = %p (%s)\n",
		       i, arg_info, g_base_info_get_name (arg_info));
		dwarn ("  dir = %d, is retval = %d, is optional = %d, may be null = %d, transfer = %d\n",
		       direction,
		       g_arg_info_is_return_value (arg_info),
		       g_arg_info_is_optional (arg_info),
		       g_arg_info_may_be_null (arg_info),
		       transfer);
		dwarn ("  arg type = %p, is pointer = %d, tag = %d (%s)\n",
		       arg_type,
		       g_type_info_is_pointer (arg_type),
		       g_type_info_get_tag (arg_type),
		       g_type_tag_to_string (g_type_info_get_tag (arg_type)));

		if (direction == GI_DIRECTION_IN ||
		    direction == GI_DIRECTION_INOUT)
		{
			gpointer raw;
			GIArgument arg;
			SV *sv;
			/* If the arg is in-out, then the ffi arg is a pointer
			 * to a pointer to a value, so we need to dereference
			 * it once. */
			raw = direction == GI_DIRECTION_INOUT
				? *((gpointer *) args[i+args_offset])
				: args[i+args_offset];
			raw_to_arg (raw, &arg, arg_type);
			sv = SAVED_STACK_SV (arg_to_sv (&arg,
			                                arg_type,
			                                transfer,
			                                GPERL_I11N_MEMORY_SCOPE_IRRELEVANT,
			                                &iinfo.base));
			/* If arg_to_sv returns NULL, we take that as 'skip
			 * this argument'; happens for GDestroyNotify, for
			 * example. */
			if (sv)
				XPUSHs (sv_2mortal (sv));
		}

		if (direction == GI_DIRECTION_INOUT ||
		    direction == GI_DIRECTION_OUT)
		{
			in_inout++;
		}
	}

	/* push the last SV onto the stack; this might be the user data or the
	 * instance.  this is only relevant for signals. */
	if (last_sv)
		XPUSHs (sv_2mortal (last_sv));

	PUTBACK;

	/* invoke the args converter with the original args on the stack.
	 * since we created two identical entries on the markstack, the
	 * call_method or call_sv below will invoke the Perl code with whatever
	 * the args converter returned. */
	if (info->args_converter) {
		call_sv (info->args_converter, G_ARRAY);
		SPAGAIN;
	}

	/* determine suitable Perl call context */
	context = G_VOID | G_DISCARD;
	if (iinfo.base.has_return_value) {
		context = in_inout > 0
		  ? G_ARRAY
		  : G_SCALAR;
	} else {
		if (in_inout == 1) {
			context = G_SCALAR;
		} else if (in_inout > 1) {
			context = G_ARRAY;
		}
	}

	/* do the call, demand #in-out+#out+#return-value return values */
	n_return_values = iinfo.base.has_return_value
	  ? in_inout + 1
	  : in_inout;
	n_returned = info->sub_name
		? call_method (info->sub_name, context)
		: call_sv (info->code, context);
	if (n_return_values != 0 && (n_returned < 0 || ((guint) n_returned) != n_return_values)) {
		ccroak ("callback returned %d values "
		        "but is supposed to return %u values",
		        n_returned, n_return_values);
	}

	/* call-scoped callback infos are freed by
	 * Glib::Object::Introspection::_FuncWrapper::DESTROY */

	SPAGAIN;

	/* convert in-out and out values and stuff them back into args */
	if (in_inout > 0) {
		SV **returned_values;
		int out_index;

		returned_values = g_new0 (SV *, in_inout);

		/* pop scalars off the stack and put them into the array;
		 * reverse the order since POPs pops items off of the end of
		 * the stack. */
		for (i = 0; i < in_inout; i++) {
			returned_values[in_inout - i - 1] = POPs;
		}

		out_index = 0;
		for (i = 0; i < iinfo.base.n_args; i++) {
			GIArgInfo *arg_info = &(iinfo.base.arg_infos[i]);
			GITypeInfo *arg_type = &(iinfo.base.arg_types[i]);
			GIDirection direction = g_arg_info_get_direction (arg_info);
			gpointer out_pointer = * (gpointer *) args[i+args_offset];

			if (!out_pointer) {
				dwarn ("skipping out arg %d\n", i);
				continue;
			}

			if (direction == GI_DIRECTION_INOUT ||
			    direction == GI_DIRECTION_OUT)
			{
				GIArgument tmp_arg;
				GITransfer transfer = g_arg_info_get_ownership_transfer (arg_info);
				/* g_arg_info_may_be_null (arg_info) is not
				 * appropriate here as it describes whether the
				 * out/inout arg itself may be NULL.  But we're
				 * asking here whether it is OK store NULL
				 * inside the out/inout arg.  This information
				 * does not seem to be present in the typelib
				 * (nor is there an annotation for it). */
				gboolean may_be_null = TRUE;
				gboolean is_caller_allocated = g_arg_info_is_caller_allocates (arg_info);
				dwarn ("out/inout arg, pos = %d, is_caller_allocated = %d\n",
				       i, is_caller_allocated);
				if (is_caller_allocated) {
					tmp_arg.v_pointer = out_pointer;
				}
				sv_to_arg (returned_values[out_index], &tmp_arg,
				           arg_info, arg_type,
				           transfer, may_be_null, &iinfo.base);
				if (!is_caller_allocated) {
					arg_to_raw (&tmp_arg, out_pointer, arg_type);
				}
				out_index++;
			}
		}

		g_free (returned_values);
	}

	/* store return value in resp, if any */
	if (iinfo.base.has_return_value) {
		GIArgument arg;
		GITypeInfo *type_info;
		GITransfer transfer;
		gboolean may_be_null;

		type_info = &iinfo.base.return_type_info;
		transfer = iinfo.base.return_type_transfer;
		may_be_null = g_callable_info_may_return_null (cb_interface); /* FIXME */

		dwarn ("return value: type = %p\n", type_info);
		dwarn ("  is pointer = %d, tag = %d (%s), transfer = %d\n",
		       g_type_info_is_pointer (type_info),
		       g_type_info_get_tag (type_info),
		       g_type_tag_to_string (g_type_info_get_tag (type_info)),
		       transfer);

		sv_to_arg (POPs, &arg, NULL, type_info,
		           transfer, may_be_null, &iinfo.base);
		_fill_ffi_return_value (type_info, resp, &arg);
	}

	PUTBACK;

	_clear_perl_invocation_info (&iinfo);

	FREETMPS;
	LEAVE;

	/* FIXME: We can't just free everything here because ffi will use parts
	 * of this after we've returned.
	 *
	 * if (info->free_after_use) {
	 * 	release_callback (info);
	 * }
	 *
	 * Gjs uses a global list of callback infos instead and periodically
	 * frees unused ones.
	 */
}

/* ------------------------------------------------------------------------- */

#if GI_CHECK_VERSION (1, 33, 10)

static void
invoke_perl_signal_handler (ffi_cif* cif, gpointer resp, gpointer* args, gpointer userdata)
{
	GClosure *closure = CAST_RAW (args[0], GClosure*);
	GValue *return_value = CAST_RAW (args[1], GValue*);
	guint n_param_values = CAST_RAW (args[2], guint);
	const GValue *param_values = CAST_RAW (args[3], const GValue*);
	gpointer invocation_hint = CAST_RAW (args[4], gpointer);
	gpointer marshal_data = CAST_RAW (args[5], gpointer);

	GPerlI11nPerlSignalInfo *signal_info = userdata;

	GPerlClosure *perl_closure = (GPerlClosure *) closure;
	GPerlI11nPerlCallbackInfo *cb_info;
	GCClosure c_closure;

	PERL_UNUSED_VAR (cif);
	PERL_UNUSED_VAR (resp);
	PERL_UNUSED_VAR (marshal_data);

	dwarn ("%s, n_args = %d\n",
	       g_base_info_get_name (signal_info->interface),
	       g_callable_info_get_n_args (signal_info->interface));

	cb_info = create_perl_callback_closure (signal_info->interface,
	                                        perl_closure->callback);
	attach_perl_callback_data (cb_info, perl_closure->data);
	cb_info->swap_data = GPERL_CLOSURE_SWAP_DATA (perl_closure);
	if (signal_info->args_converter)
		cb_info->args_converter = SvREFCNT_inc (signal_info->args_converter);

	c_closure.closure = *closure;

#if GI_CHECK_VERSION (1, 72, 0)
        c_closure.callback = g_callable_info_get_closure_native_address (signal_info->interface, cb_info->closure);
#else
	c_closure.callback = cb_info->closure;
#endif
	/* If marshal_data is non-NULL, gi_cclosure_marshal_generic uses it as
	 * the callback.  Hence we pass NULL so that c_closure.callback is
	 * used. */
	gi_cclosure_marshal_generic ((GClosure *) &c_closure,
	                             return_value,
	                             n_param_values, param_values,
	                             invocation_hint,
	                             NULL /* instead of marshal_data */);

	release_perl_callback (cb_info);
}

#endif

/* -------------------------------------------------------------------------- */

static void
_prepare_perl_invocation_info (GPerlI11nPerlInvocationInfo *iinfo,
                               GICallableInfo *info,
                               gpointer *args)
{
	guint i;

	prepare_invocation_info ((GPerlI11nInvocationInfo *) iinfo, info);

	dwarn ("%s, n_args = %d\n",
	       g_base_info_get_name (info),
	       g_callable_info_get_n_args (info));

	/* When invoking Perl code, we currently always use a complete
	 * description of the callable (from a record field or some callback
	 * typedef) for functions, vfuncs and calllbacks.  This implies that
	 * there is no implicit invocant; it always appears explicitly in the
	 * arg list.  For signals, however, the invocant is implicit. */

	/* FIXME: 'throws'? */

	/* Find array length arguments and store their value in aux_args so
	 * that array_to_sv can later fetch them. */
	for (i = 0 ; i < iinfo->base.n_args ; i++) {
		GITypeInfo *arg_type = &(iinfo->base.arg_types[i]);
		GITypeTag arg_tag = g_type_info_get_tag (arg_type);

		if (arg_tag == GI_TYPE_TAG_ARRAY) {
			gint pos = g_type_info_get_array_length (arg_type);
			if (pos >= 0) {
				GITypeInfo *length_arg_type;
				guint args_pos = iinfo->base.is_signal ? pos+1 : pos;
				length_arg_type = &(iinfo->base.arg_types[pos]);
				raw_to_arg (args[args_pos], &iinfo->base.aux_args[pos], length_arg_type);
				dwarn ("  pos %d is array length => %"G_GSIZE_FORMAT"\n",
				       pos, iinfo->base.aux_args[pos].v_size);
			}
		}
	}
}

static void
_clear_perl_invocation_info (GPerlI11nPerlInvocationInfo *iinfo)
{
	clear_invocation_info ((GPerlI11nInvocationInfo *) iinfo);
}

/* ------------------------------------------------------------------------- */

/* Copied from pygobject's pygi-closure.c. */
static void
_fill_ffi_return_value (GITypeInfo *return_info,
                        gpointer resp,
                        GIArgument *arg)
{
	if (!resp)
		return;
	switch (g_type_info_get_tag (return_info)) {
	    case GI_TYPE_TAG_BOOLEAN:
		*((ffi_sarg *) resp) = arg->v_boolean;
		break;
	    case GI_TYPE_TAG_INT8:
		*((ffi_sarg *) resp) = arg->v_int8;
		break;
	    case GI_TYPE_TAG_UINT8:
		*((ffi_arg *) resp) = arg->v_uint8;
		break;
	    case GI_TYPE_TAG_INT16:
		*((ffi_sarg *) resp) = arg->v_int16;
		break;
	    case GI_TYPE_TAG_UINT16:
		*((ffi_arg *) resp) = arg->v_uint16;
		break;
	    case GI_TYPE_TAG_INT32:
		*((ffi_sarg *) resp) = arg->v_int32;
		break;
	    case GI_TYPE_TAG_UINT32:
		*((ffi_arg *) resp) = arg->v_uint32;
		break;
	    case GI_TYPE_TAG_INT64:
		*((ffi_sarg *) resp) = arg->v_int64;
		break;
	    case GI_TYPE_TAG_UINT64:
		*((ffi_arg *) resp) = arg->v_uint64;
		break;
	    case GI_TYPE_TAG_FLOAT:
		*((gfloat *) resp) = arg->v_float;
		break;
	    case GI_TYPE_TAG_DOUBLE:
		*((gdouble *) resp) = arg->v_double;
		break;
	    case GI_TYPE_TAG_GTYPE:
		*((ffi_arg *) resp) = arg->v_size;
		break;
	    case GI_TYPE_TAG_UNICHAR:
		*((ffi_arg *) resp) = arg->v_uint32;
		break;
	    case GI_TYPE_TAG_INTERFACE:
		{
			GIBaseInfo *interface_info;
			interface_info = g_type_info_get_interface (return_info);
			switch (g_base_info_get_type (interface_info)) {
			    case GI_INFO_TYPE_ENUM:
				*(ffi_sarg *) resp = arg->v_int;
				break;
			    case GI_INFO_TYPE_FLAGS:
				*(ffi_arg *) resp = arg->v_uint;
				break;
			    default:
				*(ffi_arg *) resp = (ffi_arg) arg->v_pointer;
				break;
			}
			g_base_info_unref (interface_info);
			break;
		}
	    default:
		*(ffi_arg *) resp = (ffi_arg) arg->v_pointer;
		break;
	}
}
