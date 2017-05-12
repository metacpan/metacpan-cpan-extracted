#include "soup-perl.h"


MODULE = HTTP::Soup::Message  PACKAGE = HTTP::Soup::Message  PREFIX = soup_message_


const char*
method (SoupMessage *message, const char *val = NULL)
	CODE:
		if (items > 1) message->method = val;
		RETVAL = message->method;

	OUTPUT:
		RETVAL


guint
status_code (SoupMessage *message, guint val = 0)
	CODE:
		if (items > 1) message->status_code = val;
		RETVAL = message->status_code;

	OUTPUT:
		RETVAL


char*
reason_phrase (SoupMessage *message, char *val = NULL)
	CODE:
		if (items > 1) message->reason_phrase = val;
		RETVAL = message->reason_phrase;

	OUTPUT:
		RETVAL


SoupMessageBody*
request_body (SoupMessage *message, SoupMessageBody *val = NULL)
	CODE:
		if (items > 1) message->request_body = val;
		RETVAL = message->request_body;

	OUTPUT:
		RETVAL


SoupMessageHeaders*
request_headers (SoupMessage *message, SoupMessageHeaders *val = NULL)
	CODE:
		if (items > 1) message->request_headers = val;
		RETVAL = message->request_headers;

	OUTPUT:
		RETVAL


SoupMessageBody*
response_body (SoupMessage *message, SoupMessageBody *val = NULL)
	CODE:
		if (items > 1) message->response_body = val;
		RETVAL = message->response_body;

	OUTPUT:
		RETVAL


SoupMessageHeaders*
response_headers (SoupMessage *message, SoupMessageHeaders *val = NULL)
	CODE:
		if (items > 1) message->response_headers = val;
		RETVAL = message->response_headers;

	OUTPUT:
		RETVAL
