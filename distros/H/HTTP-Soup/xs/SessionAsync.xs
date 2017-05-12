#include "soup-perl.h"
#include "soup-perl-private.h"


MODULE = HTTP::Soup::SessionAsync  PACKAGE = HTTP::Soup::SessionAsync  PREFIX = soup_session_async_


void
soup_session_async_queue_message (SoupSessionAsync *session, SoupMessage *msg, SV  *sv_callback, SV *sv_user_data = NULL);
	CODE:
		soupperl_queue_message(SOUP_SESSION(session), msg, sv_callback, sv_user_data);
