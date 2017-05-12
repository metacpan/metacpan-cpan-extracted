
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Param		PREFIX=g_mime_param_

MIME::Fast::Param
g_mime_param_new(Class = "MIME::Fast::Param", name = 0, value = 0)
    CASE: items == 2
        char *		Class;
        const char *	name;
    CODE:
        RETVAL = g_mime_param_new_from_string(name);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL
    CASE: items == 3
        char *		Class;
        const char *	name;
        const char *	value;
    CODE:
        RETVAL = g_mime_param_new(name, value);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(param)
        MIME::Fast::Param	param
    CODE:
        if (gmime_debug)
	  warn("g_mime_param_DESTROY: 0x%x", param);
        if (g_list_find(plist,param)) {
          g_mime_param_destroy (param);
          plist = g_list_remove(plist, param);
        }

 # char *
 # g_mime_param_to_string(param)
 #       MIME::Fast::Param	param

MIME::Fast::Param
g_mime_param_append(params, name, value)
	MIME::Fast::Param	params
	const char *		name
	const char *		value
    CODE:
    	RETVAL = g_mime_param_append(params, name, value);
    OUTPUT:
	RETVAL

MIME::Fast::Param
g_mime_param_append_param(params, param)
	MIME::Fast::Param	params
	MIME::Fast::Param	param
    CODE:
    	RETVAL = g_mime_param_append_param(params, param);
    OUTPUT:
	RETVAL

void
g_mime_param_write_to_string(params, fold, svtext)
	MIME::Fast::Param	params
	gboolean		fold
	SV *			&svtext
    PREINIT:
	GString			*textdata;
    CODE:
        textdata = g_string_new ("");
    	g_mime_param_write_to_string (params, fold, textdata);
	sv_catpv(svtext, textdata->str);
	g_string_free (textdata, TRUE);
    OUTPUT:
	svtext



