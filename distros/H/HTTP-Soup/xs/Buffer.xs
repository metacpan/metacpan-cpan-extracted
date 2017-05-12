#include "soup-perl.h"


MODULE = HTTP::Soup::Buffer  PACKAGE = HTTP::Soup::Buffer  PREFIX = soup_buffer_


SoupBuffer*
soup_buffer_new (CLASS, int use, SV *sv_data)
	C_ARGS: use, data, length
	PREINIT:
		gconstpointer data;
		gsize length;

	CODE:
		data = SvPV(sv_data, length);
		RETVAL = soup_buffer_new(use, data, length);

	OUTPUT:
		RETVAL


SV*
data (SoupBuffer *buffer, const char *val = NULL)
	CODE:
		if (items > 1) {
			buffer->data = val;
			/* We can't return the 'data' array since we don't know its length yet */
			RETVAL = NULL;
		}
		else {
			RETVAL = newSVpv(buffer->data, buffer->length);
		}

	OUTPUT:
		RETVAL


gsize
length (SoupBuffer *buffer, gsize val = 0)
	CODE:
		if (items > 1) buffer->length = val;
		RETVAL = buffer->length;

	OUTPUT:
		RETVAL

