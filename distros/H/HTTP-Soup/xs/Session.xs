#include "soup-perl.h"


static GPerlCallback*
soupperl_message_callback_create (SV *func, SV *data) {
	GType param_types [] = {
		SOUP_TYPE_SESSION,
		SOUP_TYPE_MESSAGE,
	};

	return gperl_callback_new(
		func, data,
		G_N_ELEMENTS(param_types), param_types,
		G_TYPE_NONE
	);
}


static void
soupperl_message_callback (SoupSession *session, SoupMessage *msg, gpointer data) {
	GPerlCallback *callback = (GPerlCallback *) data;
	
	if (callback == NULL) {
		croak("HTTP::Soup::Session message callback is missing the data parameter");
	}
	
	gperl_callback_invoke(callback, NULL, session, msg, callback->data);
}

/* This function is shared with SessionAsync.xs */
void
soupperl_queue_message (SoupSession *session, SoupMessage *msg, SV  *sv_callback, SV *sv_user_data) {
	GPerlCallback *callback = NULL;

	g_object_ref(G_OBJECT(msg));
	callback = soupperl_message_callback_create(sv_callback, sv_user_data);
	soup_session_queue_message(session, msg, soupperl_message_callback, callback);
}


MODULE = HTTP::Soup::Session  PACKAGE = HTTP::Soup::Session  PREFIX = soup_session_


void
soup_session_queue_message (SoupSession *session, SoupMessage *msg, SV  *sv_callback, SV *sv_user_data = NULL);
	CODE:
		soupperl_queue_message(session, msg, sv_callback, sv_user_data);
