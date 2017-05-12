
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Func	PREFIX=g_mime_filter_func_

 # unsupported:
 # g_mime_filter_filter
 # g_mime_filter_complete
 # g_mime_filter_backup

MIME::Fast::Filter::Func
g_mime_filter_func_new(Class, svstep, svcomplete = 0, svsizeout = 0, svdata = 0)
    CASE: items == 5
    	const char *		Class
        SV *			svstep
	SV *			svcomplete
	SV *			svsizeout
        SV *			svdata
    PREINIT:
	struct _user_data_sv    *data;
    CODE:
	data = g_new0 (struct _user_data_sv, 1);
	data->svuser_data  = newSVsv(svdata);
	data->svfunc  = newSVsv(svstep);
	data->svfunc_complete = newSVsv(svcomplete);
	data->svfunc_sizeout  = newSVsv(svsizeout);
	RETVAL = g_mime_filter_func_new (call_filter_step_func,
			call_filter_complete_func, call_filter_sizeout_func, data);
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL
    CASE: items == 4
    	const char *		Class
        SV *			svstep
	SV *			svcomplete
	SV *			svsizeout
    PREINIT:
	struct _user_data_sv    *data;
    CODE:
	data = g_new0 (struct _user_data_sv, 1);
	data->svfunc  = newSVsv(svstep);
	data->svfunc_complete = newSVsv(svcomplete);
	data->svfunc_sizeout  = newSVsv(svsizeout);
	RETVAL = g_mime_filter_func_new(call_filter_step_func,
			call_filter_complete_func, call_filter_sizeout_func, data);
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL
    CASE: items == 3
    	const char *		Class
        SV *			svstep
	SV *			svcomplete
    PREINIT:
	struct _user_data_sv    *data;
    CODE:
	data = g_new0 (struct _user_data_sv, 1);
	data->svfunc  = newSVsv(svstep);
	data->svfunc_complete = newSVsv(svcomplete);
	RETVAL = g_mime_filter_func_new(call_filter_step_func,
			call_filter_complete_func, NULL, data);
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL
    CASE: items == 2
    	const char *		Class
        SV *			svstep
    PREINIT:
	struct _user_data_sv    *data;
    CODE:
	data = g_new0 (struct _user_data_sv, 1);
	data->svfunc  = newSVsv(svstep);
	data->svfunc_complete = newSVsv(svstep);
	RETVAL = g_mime_filter_func_new(call_filter_step_func,
			call_filter_complete_func, NULL, data);
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

