/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

#define PUSH_METHODS(prefix, av, info)                                  \
	gint i, n_methods = g_ ## prefix ## _info_get_n_methods (info); \
	for (i = 0; i < n_methods; i++) { \
		GIFunctionInfo *function_info; \
		const gchar *function_name; \
		function_info = g_ ## prefix ## _info_get_method (info, i); \
		function_name = g_base_info_get_name (function_info); \
		av_push (av, newSVpv (function_name, 0)); \
		g_base_info_unref (function_info); \
	}

static void
store_methods (HV *namespaced_functions, GIBaseInfo *info, GIInfoType info_type)
{
	const gchar *namespace;
	AV *av;

	namespace = g_base_info_get_name (info);
	av = newAV ();

	switch (info_type) {
	    case GI_INFO_TYPE_OBJECT:
	    {
		PUSH_METHODS (object, av, info);
		break;
	    }

	    case GI_INFO_TYPE_INTERFACE:
	    {
		PUSH_METHODS (interface, av, info);
		break;
	    }

	    case GI_INFO_TYPE_BOXED:
	    case GI_INFO_TYPE_STRUCT:
	    {
		PUSH_METHODS (struct, av, info);
		break;
	    }

	    case GI_INFO_TYPE_UNION:
	    {
		PUSH_METHODS (union, av, info);
		break;
	    }

	    case GI_INFO_TYPE_ENUM:
	    case GI_INFO_TYPE_FLAGS:
	    {
#if GI_CHECK_VERSION (1, 29, 17)
		PUSH_METHODS (enum, av, info);
#endif
		break;
	    }

	    default:
		ccroak ("store_methods: unsupported info type %d", info_type);
	}

	gperl_hv_take_sv (namespaced_functions, namespace, strlen (namespace),
	                  newRV_noinc ((SV *) av));
}
