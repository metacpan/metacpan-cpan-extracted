#include "soup-perl.h"


MODULE = HTTP::Soup::Cookie  PACKAGE = HTTP::Soup::Cookie  PREFIX = soup_cookie_


char*
name (SoupCookie *cookie, char *val = NULL)
	CODE:
		if (items > 1) cookie->name = val;
		RETVAL = cookie->name;

	OUTPUT:
		RETVAL


char*
value (SoupCookie *cookie, char *val = NULL)
	CODE:
		if (items > 1) cookie->value = val;
		RETVAL = cookie->value;

	OUTPUT:
		RETVAL


char*
domain (SoupCookie *cookie, char *val = NULL)
	CODE:
		if (items > 1) cookie->domain = val;
		RETVAL = cookie->domain;

	OUTPUT:
		RETVAL


char*
path (SoupCookie *cookie, char *val = NULL)
	CODE:
		if (items > 1) cookie->path = val;
		RETVAL = cookie->path;

	OUTPUT:
		RETVAL


gboolean
secure (SoupCookie *cookie, gboolean val = FALSE)
	CODE:
		if (items > 1) cookie->secure = val;
		RETVAL = cookie->secure;

	OUTPUT:
		RETVAL


gboolean
http_only (SoupCookie *cookie, gboolean val = FALSE)
	CODE:
		if (items > 1) cookie->http_only = val;
		RETVAL = cookie->http_only;

	OUTPUT:
		RETVAL
