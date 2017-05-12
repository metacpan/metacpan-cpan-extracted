#include "soup-perl.h"


MODULE = HTTP::Soup::MessageBody  PACKAGE = HTTP::Soup::MessageBody  PREFIX = soup_message_body_


SV*
data (SoupMessageBody *body, const char *val = NULL)
	CODE:
		if (items > 1) {
			body->data = val;
			/* We can't return the 'data' array since we don't know its length yet */
			RETVAL = NULL;
		}
		else {
			RETVAL = newSVpv(body->data, body->length);
		}

	OUTPUT:
		RETVAL


gint64
length (SoupMessageBody *body, gint64 val = 0)
	CODE:
		if (items > 1) body->length = val;
		RETVAL = body->length;

	OUTPUT:
		RETVAL


void
soup_message_body_append (SoupMessageBody *body, SV *sv)
	PREINIT:
		gsize length;
		char *data;

	CODE:
		data = SvPV(sv, length);
		soup_message_body_append(body, SOUP_MEMORY_COPY, data, length);


void
soup_message_body_append_take (SoupMessageBody *body, SV *sv)
	PREINIT:
		gsize length;
		char *data;

	CODE:
		data = SvPV(sv, length);
		/*
		   append_take() implies that g_free() will be used, this will not do
		   the right thing with Perl scalars since they are not allocated with
		   g_malloc(). The best is to simply call append().
		*/
		soup_message_body_append(body, SOUP_MEMORY_COPY, data, length);
