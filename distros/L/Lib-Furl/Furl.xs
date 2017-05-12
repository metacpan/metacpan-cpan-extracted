/* $Id: Furl.xs 4 2012-11-01 17:05:56Z gomor $ */

/*
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <furl/furl.h>
#include <furl/decode.h>

typedef furl_handler_t   FurlHandler;

MODULE = Lib::Furl  PACKAGE = Lib::Furl
PROTOTYPES: DISABLE

FurlHandler *
furl_init()

char *
furl_get_version()

int
furl_decode(fh, url, url_size)
      FurlHandler *fh
      const char *url
      int url_size

void
furl_show(fh, sep_char, out)
      FurlHandler *fh
      char sep_char
      FILE *out

void
furl_terminate(fh)
      FurlHandler *fh

int
furl_get_scheme_pos(fh)
      FurlHandler *fh

int
furl_get_scheme_size(fh)
      FurlHandler *fh

int
furl_get_credential_pos(fh)
      FurlHandler *fh

int
furl_get_credential_size(fh)
      FurlHandler *fh

int
furl_get_subdomain_pos(fh)
      FurlHandler *fh

int
furl_get_subdomain_size(fh)
      FurlHandler *fh

int
furl_get_domain_pos(fh)
      FurlHandler *fh

int
furl_get_domain_size(fh)
      FurlHandler *fh

int
furl_get_host_pos(fh)
      FurlHandler *fh

int
furl_get_host_size(fh)
      FurlHandler *fh

int
furl_get_tld_pos(fh)
      FurlHandler *fh

int
furl_get_tld_size(fh)
      FurlHandler *fh

int
furl_get_port_pos(fh)
      FurlHandler *fh

int
furl_get_port_size(fh)
      FurlHandler *fh

int
furl_get_resource_path_pos(fh)
      FurlHandler *fh

int
furl_get_resource_path_size(fh)
      FurlHandler *fh

int
furl_get_query_string_pos(fh)
      FurlHandler *fh

int
furl_get_query_string_size(fh)
      FurlHandler *fh

int
furl_get_fragment_pos(fh)
      FurlHandler *fh

int
furl_get_fragment_size(fh)
      FurlHandler *fh
