#ifndef _HTTP_PARSER_H_INCLUDED_
#define _HTTP_PARSER_H_INCLUDED_

/* contains name and value of a header (name == NULL if is a continuing line
 * of a multiline header */
struct phr_header {
  const char* name;
  size_t name_len;
  const char* value;
  size_t value_len;
};

int parse_http_request(SV* buf, SV* envref);
int parse_http_response(SV* buf, SV* envref);
int parse_http_request_psgi(SV* buf, SV* envref);

#endif /* _HTTP_PARSER_H_INCLUDED_ */

