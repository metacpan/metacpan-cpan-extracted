/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

static void
generic_interface_init (gpointer iface, gpointer data)
{
	GIInterfaceInfo *info = data;
	GIStructInfo *struct_info;
	gint n, i;
	struct_info = g_interface_info_get_iface_struct (info);
	n = g_interface_info_get_n_vfuncs (info);
	for (i = 0; i < n; i++) {
		GIVFuncInfo *vfunc_info;
		const gchar *vfunc_name;
		GIFieldInfo *field_info;
		gint field_offset;
		GITypeInfo *field_type_info;
		GIBaseInfo *field_interface_info;
		gchar *perl_method_name;
		GPerlI11nPerlCallbackInfo *callback_info;

		vfunc_info = g_interface_info_get_vfunc (info, i);
		vfunc_name = g_base_info_get_name (vfunc_info);

		perl_method_name = g_ascii_strup (vfunc_name, -1);
		if (is_forbidden_sub_name (perl_method_name)) {
			/* If the method name coincides with the name of one of
			 * perl's special subs, add "_VFUNC". */
			gchar *replacement = g_strconcat (perl_method_name, "_VFUNC", NULL);
			g_free (perl_method_name);
			perl_method_name = replacement;
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
		       iface);

#if GI_CHECK_VERSION (1, 72, 0)
		G_STRUCT_MEMBER (gpointer, iface, field_offset) =
                        g_callable_info_get_closure_native_address (vfunc_info, callback_info->closure);
#else
		G_STRUCT_MEMBER (gpointer, iface, field_offset) = callback_info->closure;
#endif

		g_base_info_unref (field_interface_info);
		g_base_info_unref (field_type_info);
		g_base_info_unref (field_info);
		g_base_info_unref (vfunc_info);
	}
	g_base_info_unref (struct_info);
}

static void
generic_interface_finalize (gpointer iface, gpointer data)
{
	GIInterfaceInfo *info = data;
	PERL_UNUSED_VAR (iface);
	dwarn ("info = %p\n", info);
	g_base_info_unref ((GIBaseInfo *) info);
}
