# Copyrights 2021 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# vim: syntax=c
# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

use warnings;
use strict;

package HTML::Inspect::Normalize;
use vars '$VERSION';
$VERSION = '1.00';

use parent 'Exporter';

use Log::Report 'html-inspect';

use Encode       qw(encode);
use Scalar::Util qw(dualvar);

use Inline 'C' => config => libs => '-lidn2';
use Inline 'C' => 'DATA';
Inline->init;

our @EXPORT = qw(set_page_base normalize_url);

# The INHERITANCE chapter is overruled, because Inline::C changes ISA


sub set_page_base($) {
    my ($val, $rc, $msg) = _set_base(encode utf8 => $_[0]);
    return ($val, $rc, $msg) if wantarray;

    defined $val
        or error __x"Invalid base '{base}': {msg}", base => $_[0], msg => $msg, _code => $rc;

    $val;
}



sub normalize_url($) {
    my ($val, $rc, $msg) = _normalize_url(encode utf8 => $_[0]);
    return ($val, $rc, $msg) if wantarray;

    defined $val
        or error __x"Invalid url '{url}': {msg}", url => $_[0], msg => $msg, _code => $rc;

    $val;
}


1;

__DATA__
__C__

/*
 * We go to great extend to avoid mallocs.  The code is "hit and run": when
 * the url has been processed, the internal data is not needed anymore.  So,
 * preallocation is not a problem but NOT THREAD SAFE.
 */

#include <arpa/inet.h>
#include <idn2.h>

/* Detailed discussion 
   https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers
 */
#define MAX_INPUT_URL   2047
#define MAX_STORE_PART  (4*(MAX_INPUT_URL+1))

#define EOL    '\0'

#define UNSAFE_CHARS    "<>{}|\\^~[]`\""   # rfc1738
#define RESERVED_CHARS  ";/?:@=&"
#define BLANKS          " \t\v\r\n"
#define DIGITS          "0123456789"
#define ALPHA           "abcdefghijklmnopqrstuvwxyz" \
                        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define UNENCODED       ALPHA DIGITS "$-_.!*'(),"
#define SCHEMA_CHARS    ALPHA "-"
#define IPv6_CHARS      DIGITS ":"
#define IPv4_CHARS      DIGITS "."
#define MAX_PORT_NUMBER 65535

typedef unsigned char byte;

typedef struct url {
   char scheme   [8];                 /* http or https */
   char port     [8];
   char username [MAX_STORE_PART];
   char password [MAX_STORE_PART];
   char host     [MAX_STORE_PART];
   char path     [MAX_STORE_PART];
   char query    [MAX_STORE_PART];
} url;

url default_url = { "https", "", "", "", "localhost", "/", "" };

url global_base;

static char * rc;
static char * errmsg;

static int strip_blanks(char **str) {
    char * end;
    *str += strspn(*str, BLANKS);     /* leading blanks */

    end = *str + strlen(*str) -1;     /* trailing blanks */
    while(end >= *str) {
        if(strrchr(BLANKS, end[0])==NULL) {
            break;
        }

        end[0] = EOL;
        end--;
    }

    return 1;
}

static int strip_fragment(char **str) {
    char * end;
    if(end = index(*str, '#')) {
        end[0] = EOL;
    }

    return 1;
}

static int reslash(char *str) {
    while(*str) {
        if(*str=='\\') *str = '/';
        str++;
    }
    return 1;
}

inline int utf8cont(unsigned char c) {
    return (c & 0b11000000) == 0b10000000;
}

static int clean_part(char *part) {
   /* The part does not contain url serialization anymore.  The
    * changes are made in-place, because we reduce the number of
    * characters when %XX is found.  normalize_part() with put
    * then back in, only if needed.
    */
   unsigned char * reader = part;
   unsigned char * writer = part;
   unsigned char   c;

   while(c = *reader++) {
       if(c=='%')
       {   char h1 = tolower(*reader++);
           char h2 = h1 ? tolower(*reader++) : EOL;

           if( !isxdigit(h1) || !isxdigit(h2) ) {
               rc     = "HIN_ILLEGAL_HEX";
               errmsg = "Illegal hexadecimal digit";
               return 0;
           }
           int d1 = h1 <= '9' ? h1 - '0' : h1 - 'a' +10;
           int d2 = h2 <= '9' ? h2 - '0' : h2 - 'a' +10;
           c = (d1 << 4) + d2;

           if(c==0) {
               rc     = "HIN_CONTAINS_ZERO";   /* spoofing attempt? */
               errmsg = "Illegal use of NUL byte";
               return 0;
           }
       }
       else
       if(c=='+' || c==' ') {       /* very special hex and space */
           c = ' ';
       }
       else
       if(isspace(c)) {             /* ignore other whitespaces */
           c = EOL;
           while(reader[0]==' ') {  /* ignore blanks after line fold */
               reader++;
           }
       }

       if(c) *writer++ = c;          /* do not take NUL/EOL */
   }
   *writer = EOL;

   /*
    * Check validity utf8
    */

   reader = part;
   while(*reader) {
       unsigned char c = *reader++;
       if(utf8cont(c)) {
           /* follower without lead */
       }
       else
       if( (c & 0b10000000)==0
       ||( (c & 0b11100000)==0b11000000 && utf8cont(*reader++))
       ||( (c & 0b11110000)==0b11100000 && utf8cont(*reader++) && utf8cont(*reader++))
       ||( (c & 0b11111000)==0b11110000 && utf8cont(*reader++) && utf8cont(*reader++)
             && utf8cont(*reader++))) {
           continue;
       }

       rc     = "HIN_INCORRECT_UTF8";
       errmsg = "Incorrect UTF8 encoding, broken characters";
       return 0;
   }

   return 1;
}

static int rehex(char *out, char *part) {
    char *writer = out;
    unsigned char this;

    /*TODO? check utf8 bytes */
    while(this = (*part++ & 0xFF)) {

       if(strchr(UNENCODED, this)) {
          *writer++ = this;
       }
       else {
          sprintf(writer, "%%%02X", this);
          writer += 3;
       }

    }

    *writer = EOL;
    return 1;
}

static int normalize_part(char *out, char *part) {
    clean_part(part);
    if( !rehex(out, part)) return 0;
    return 1;
}

static int normalize_scheme(url *norm, char **relative, url *base) {
    if(strncasecmp(*relative, "http://", 7)==0) {
        *relative += 5;                   /* keep the // */
        strcpy(norm->scheme, "http");
    }
    else
    if(strncasecmp(*relative, "https://", 8)==0) {
        *relative += 6;
        strcpy(norm->scheme, "https");
    }
    else
    if((*relative)[0]=='/' && (*relative)[1]=='/') {
        strcpy(norm->scheme, base->scheme);
    }
    else
    {
        size_t len = strspn(*relative, SCHEMA_CHARS);
        if((*relative)[len]==':') {
            rc     = "HIN_UNSUPPORTED_SCHEME";
            errmsg = "Only http(s) is supported";
            return 0;
        }
    }

    return 1;
}

static int normalize_authorization(url *norm, char *auth, url *base) {
    char * passwd = NULL;       /* points inside auth buffer */
    char * colon;

    if(colon = index(auth, ':')) {
        colon[0] = EOL;         /* chop username */
        passwd   = colon+1;     /* remainer is password */
        if( ! clean_part(passwd)) return 0;
    }
    else {
        passwd   = auth + strlen(auth);  /* EOL */
    }

    if( ! clean_part(auth)) return 0;
    if( ! normalize_part(norm->username, auth)) return 0;
    if(strcmp(norm->username, "anonymous")==0) {
        norm->username[0] = EOL;
    }

    if( ! normalize_part(norm->password, passwd)) return 0;
    return 1;
}

static int normalize_host(url *norm, char *host) {
    if( ! clean_part(host)) return 0;

    if(host[0]=='[') {
        /* IPv6 address */
        host[strlen(host) -1] = EOL;  /* remove trailing ] */
        norm->host[0] = '[';
        byte bin_addr[sizeof(struct in6_addr)];
        if(! inet_pton(AF_INET6, host+1, bin_addr)) {
            rc     = "HIN_IPV6_BROKEN";
            errmsg = "The IPv6 host address incorrect";
            return 0;
        }

        inet_ntop(AF_INET6, bin_addr, norm->host +1, INET6_ADDRSTRLEN);
        strcat(norm->host, "]");
        return 1;
    }

    if(strspn(host, IPv4_CHARS)==strlen(host)) {
        /* IPv4 address */
        byte bin_addr[sizeof(struct in_addr)];
        if(! inet_pton(AF_INET, host, bin_addr)) {
            rc     = "HIN_IPV4_BROKEN";
            errmsg = "The IPv4 host address incorrect";
            return 0;
        }
        inet_ntop(AF_INET, bin_addr, norm->host, INET_ADDRSTRLEN);
        return 1;
    }

    /* Normal or utf8 hostname.
     * Whether we need IDN is not important: it also validates and
     * sets domain to lower-case.
     */

    uint8_t * idn;
    int idn_rc = idn2_lookup_u8(host, &idn, IDN2_NFC_INPUT);
    if(idn_rc != IDN2_OK) {
        rc     = (char *)idn2_strerror_name(idn_rc);
        errmsg = (char *)idn2_strerror(idn_rc);
        return 0;
    }

    /* idn libs keeps trailing dot. */
    int len = strlen(idn);
    if(len > 1 && idn[len-1]=='.') idn[len-1] = EOL;

    strcpy(norm->host, idn);
    idn2_free(idn);

    return 1;
}

static int normalize_port(url *norm, char *port) {
    if( ! clean_part(port)) return 0;

    int portnr = 0;
    while(isdigit(port[0])) {
        portnr = portnr * 10 + *port++ - '0';
    }

    if(port[0] != EOL) {
        rc     = "HIN_PORT_NON_DIGIT";
        errmsg = "The portnumber contains a non-digit";
        return 0;
    }

    if(portnr > MAX_PORT_NUMBER) {
        rc     = "HIN_PORT_NUMBER_TOO_HIGH";
        errmsg = "The portnumber is out of range";
        return 0;
    }

    if(portnr==80 && strcmp(norm->scheme, "http")==0) {
        norm->port[0] = EOL;  /* ignore default for http */
    }
    else
    if(portnr==431 && strcmp(norm->scheme, "https")==0) {
        norm->port[0] = EOL;  /* ignore default for https */
    }
    else {
        sprintf(norm->port, "%d", portnr);
    }

    return 1;
}

static int normalize_hostport(url *norm, char *host, url *base) {
    if(strlen(host)==0) {
        /* We had auth, but no host or port. */
        strcpy(norm->host, base->host);
        strcpy(norm->port, base->port);
        return 1;
    }

    char *port = NULL;
    if(host[0]=='[') {
        /* IPv6 address.  It contains ':' which may confuse ":port" */
        char *end = strpbrk(host, "]");
        if(!end) {
            rc     = "HIN_IPV6_UNTERMINATED";
            errmsg = "The IPv6 host address is not terminated";
            return 0;
        }

        end++;
        if(end[0]!=EOL && end[0]!=':' && end[0]!='/') {
            rc     = "HIN_IPV6_ENDS_INCORRECTLY";
            errmsg = "The IPv6 host address terminated unexpectedly";
            return 0;
        }

        if(end[0]==':') {
            *end++ = EOL;
            port   = end;
        }
    }
    else
    if(port = index(host, ':')) {
        *port++ = EOL;
    }

    if(strlen(host)==0) {
        strcpy(norm->host, base->host);
    }
    else {
        if( !normalize_host(norm, host)) return 0;
    }

    if(port && strlen(port)) {
       if( !normalize_port(norm, port)) return 0;
    }
    else {
       norm->port[0] = EOL;
    }

    return 1;
}

static int resolve_external_address(url *norm, char **relative, url *base) {

    if((*relative)[0]==EOL || (*relative)[0]=='/') {
        /* empty location */
        strcpy(norm->username, base->username);
        strcpy(norm->password, base->password);
        strcpy(norm->host, base->host);
        strcpy(norm->port, base->port);
        return 1;
    }

    char *end = strpbrk(*relative, "@/?");
    if(end && end[0]=='@') {
        /* Authorization */
        size_t auth_strlen = end - *relative;
        char   auth[MAX_STORE_PART];

        strncpy(auth, *relative, auth_strlen);
        auth[auth_strlen] = EOL;
        *relative = end +1;

        if( !normalize_authorization(norm, auth, base)) return 0;
        end = index(*relative, '/');
    }
    else {
        /* No authorization, but have something else: no base */
        norm->username[0] = EOL;
        norm->password[0] = EOL;
    }

    char host[MAX_STORE_PART];
    if(end) {
        size_t len = end - *relative;
        strncpy(host, *relative, len);
        host[len] = EOL;
        *relative = end;
    }
    else {
        strcpy(host, *relative);
        *relative += strlen(*relative);
    }

    if( !normalize_hostport(norm, host, base)) return 0;

    return 1;
}

static int normalize_path(url *out, char *path) {
    /* XXX split on / and ;, normalize all parts, rejoin */
    /* remove ./ and ../ */
    char   *begin, *end;
    char   sep;
    char   segment[MAX_STORE_PART];
    size_t len;
    char  *norm = (char *)&out->path;

    if(path[0]==EOL) {
        norm[0] = '/';
        norm[1] = EOL;
        return 1;
    }

    while(*path) {
        begin   = path;
        len     = strcspn(begin, "/;");
        sep     = begin[len];

        if(len==0 && sep=='/' && strlen(norm)) {
            /* Remove double slash */
            path++;
            continue;
        }

        strncpy(segment, begin, len);
        segment[len] = EOL;
        path   += len;

        if(segment[0]=='.' && segment[1]==EOL && norm[strlen(norm)-1]=='/') {
            /* Remove "." segments.     /./ -> /
             *   /.; -> ;   only when not first /
             *   .  at end, simply remove
             */
            if(sep=='/' && strlen(norm)) {
                norm[strlen(norm)-1] = EOL;
            }
        }
        else
        if(segment[0]=='.' && segment[1]=='.' && segment[2]==EOL
           && sep!=';' && norm[strlen(norm)-1]=='/'
          ) {
            /* Remove ".." segments.   /a/../ => /
             *   /a/..$ -> /   a/..;b unmodified
             *   leading ..'s removed
             */
            if(strlen(norm) > 1) { norm[strlen(norm)-1] = EOL; }
            end = rindex(norm, '/');
            end[1] = EOL;
            if(sep != EOL) { path++;  sep = EOL; }
        }
        else
        if( !normalize_part(&norm[strlen(norm)], segment)) return 0;

        if(sep != EOL) {
            strncat(norm, &sep, 1);
            path++;
        }
    }

    return 1;
}

static int normalize_query(url *out, char *query) {
    /* XXX split on & and =, normalize all parts, rejoin */
    char   *begin, *end;
    char   sep;
    char   segment[MAX_STORE_PART];
    size_t len;
    char  *norm = (char *)&out->query;

    while(*query) {
        begin   = query;
        len     = strcspn(begin, "&=");
        sep     = begin[len];
        strncpy(segment, begin, len);
        segment[len] = EOL;
        query  += len;

        if( !normalize_part(&norm[strlen(norm)], segment)) return 0;
        if(sep != EOL) {
            strncat(norm, &sep, 1);
            query++;
        }
    }

    return 1;
}

static int normalize(url *norm, char *relative, url *base) {
    char *end, *path, *query;
    char constructed_path[MAX_STORE_PART];

    if(strlen(relative) > MAX_INPUT_URL) {
        rc     = "HIN_INPUT_TOO_LONG";
        errmsg = "Input url too long";
        return 0;
    }

    if( !strip_blanks(&relative)) return 0;
    if( !strip_fragment(&relative)) return 0;
    if( !reslash(relative)) return 0;

    norm->scheme[0] = norm->username[0] = norm->password[0] = norm->host[0] =
    norm->port[0] = norm->path[0] = norm->query[0] = EOL;

    if( !normalize_scheme(norm, &relative, base)) return 0;

    if(relative[0]=='/' && relative[1]=='/') {
        /* Absolute address */
        relative += 2;
        if( !resolve_external_address(norm, &relative, base)) return 0;

        if(relative[0]==EOL) {
            /* Empty path */
            norm->path[0] = '/';
            norm->path[1] = EOL;
            return 1;
        }

        path = relative;
    }
    else {
        /* Local reference */
        strcpy(norm->scheme,   base->scheme);
        strcpy(norm->username, base->username);
        strcpy(norm->password, base->password);
        strcpy(norm->host,     base->host);
        strcpy(norm->port,     base->port);

        if(relative[0]==EOL) {
            /* Empty path: take base which is normalized already */
            strcpy(norm->path, base->path);
            strcpy(norm->query, base->query);
            return 1;
        }

        if(relative[0]=='/') {
            /* Absolute path */
            path = relative;
        }
        else {
            /* Relative path */
            if(relative[0]==EOL) {
                strcpy(norm->path, base->path);
                strcpy(norm->query, base->query);
                return 1;
            }

            path = constructed_path;
            strcpy(path, base->path);
            if(relative[0]=='?') {
                strcat(path, relative);
            }
            else {
                rindex(path, '/')[1] = EOL;
                strcat(path, relative);
            }
        }
    }

    /* Strip query from path */
    query  = NULL;
    if(end = index(path, '?')) {
        end[0] = EOL;
        query  = end+1;
    }

    if( !normalize_path(norm, path) ) return 0;

    if(query) {
        if( !normalize_query(norm, query) ) return 0;
    }

    return 1;
}

static void serialize(char *out, url *norm) {
    strcpy(out, norm->scheme);
    strcat(out, "://");
    if(strlen(norm->username)) {
        strcat(out, norm->username);
    }
    if(strlen(norm->password)) {
        strcat(out, ":");
        strcat(out, norm->password);
    }
    if(strlen(norm->username) || strlen(norm->password)) {
        strcat(out, "@");
    }
    strcat(out, norm->host);
    if(strlen(norm->port)) {
        strcat(out, ":");
        strcat(out, norm->port);
    }
    strcat(out, norm->path);
    if(strlen(norm->query)) {
        strcat(out, "?");
        strcat(out, norm->query);
    }
}

static void answer(url *result) {
    char normalized[MAX_STORE_PART];
    inline_stack_vars;

    serialize(normalized, result);

    if(strlen(rc)==0) errmsg = "";

    inline_stack_reset;
    inline_stack_push(sv_2mortal(newSVpv(strlen(rc) ? NULL : normalized, PL_na)));
    inline_stack_push(sv_2mortal(newSVpv(rc, PL_na)));
    inline_stack_push(sv_2mortal(newSVpv(errmsg, PL_na)));
    inline_stack_done;
}

void _set_base(char *b) {
    rc = "";
    normalize(&global_base, b, &default_url);
    answer(&global_base);  /* Useful for debugging */
}

/* returns a LIST */
void _normalize_url(char *r) {
    url  absolute;

    rc = "";
    normalize(&absolute, r, &global_base);
    answer(&absolute);
}
