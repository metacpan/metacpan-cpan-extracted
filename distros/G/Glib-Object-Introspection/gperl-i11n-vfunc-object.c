/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void
store_objects_with_vfuncs (AV *objects_with_vfuncs, GIObjectInfo *info)
{
	if (g_object_info_get_n_vfuncs (info) <= 0)
		return;
	av_push (objects_with_vfuncs,
	         newSVpv (g_base_info_get_name (info), 0));
}

/* ------------------------------------------------------------------------- */

static void
generic_class_init (GIObjectInfo *info, const gchar *target_package, gpointer class)
{
	GIStructInfo *struct_info;
	gint n, i;
	struct_info = g_object_info_get_class_struct (info);
	n = g_object_info_get_n_vfuncs (info);
	for (i = 0; i < n; i++) {
		GIVFuncInfo *vfunc_info;
		const gchar *vfunc_name;
		GIFieldInfo *field_info;
		gint field_offset;
		GITypeInfo *field_type_info;
		GIBaseInfo *field_interface_info;
		gchar *perl_method_name;
		GPerlI11nPerlCallbackInfo *callback_info;

		vfunc_info = g_object_info_get_vfunc (info, i);
		vfunc_name = g_base_info_get_name (vfunc_info);

		perl_method_name = g_ascii_strup (vfunc_name, -1);
		if (is_forbidden_sub_name (perl_method_name)) {
			/* If the method name coincides with the name of one of
			 * perl's special subs, add "_VFUNC". */
			gchar *replacement = g_strconcat (perl_method_name, "_VFUNC", NULL);
			g_free (perl_method_name);
			perl_method_name = replacement;
		}

		{
			/* If there is no implementation of this vfunc at INIT
			 * time, we assume that the intention is to provide no
			 * implementation and we thus skip setting up the class
			 * struct member. */
			HV * stash = gv_stashpv (target_package, 0);
			GV * slot = gv_fetchmethod (stash, perl_method_name);
			if (!slot || !GvCV (slot)) {
				dwarn ("skipping vfunc %s.%s because it has no implementation\n",
				      g_base_info_get_name (info), vfunc_name);
				g_base_info_unref (vfunc_info);
				g_free (perl_method_name);
				continue;
			}
		}

		/* We use the field information here rather than the vfunc
		 * information so that the Perl invoker does not have to deal
		 * with an implicit invocant. */
		field_info = get_field_info (struct_info, vfunc_name);
		g_assert (field_info);
		field_offset = g_field_info_get_offset (field_info);
		field_type_info = g_field_info_get_type (field_info);
		field_interface_info = g_type_info_get_interface (field_type_info);

		/* callback_info takes over ownership of perl_method_name. */
		callback_info = create_perl_callback_closure_for_named_sub (
		                  field_interface_info, perl_method_name);
		dwarn ("installing vfunc %s.%s as %s at offset %d (vs. %d) inside %p\n",
		       g_base_info_get_name (info), vfunc_name, perl_method_name,
		       field_offset, g_vfunc_info_get_offset (vfunc_info),
		       class);

#if GI_CHECK_VERSION (1, 72, 0)
                G_STRUCT_MEMBER (gpointer, class, field_offset) =
                        g_callable_info_get_closure_native_address (vfunc_info, callback_info->closure);
#else
		G_STRUCT_MEMBER (gpointer, class, field_offset) = callback_info->closure;
#endif

		g_base_info_unref (field_interface_info);
		g_base_info_unref (field_type_info);
		g_base_info_unref (field_info);
		g_base_info_unref (vfunc_info);
	}
	g_base_info_unref (struct_info);
}

/* ------------------------------------------------------------------------- */

static gint
get_vfunc_offset (GIObjectInfo *info, const gchar *vfunc_name)
{
	GIStructInfo *struct_info;
	GIFieldInfo *field_info;
	gint field_offset;

	struct_info = g_object_info_get_class_struct (info);
	g_assert (struct_info);

	field_info = get_field_info (struct_info, vfunc_name);
	g_assert (field_info);
	field_offset = g_field_info_get_offset (field_info);

	g_base_info_unref (field_info);
	g_base_info_unref (struct_info);

	return field_offset;
}


