/*
 * copied and amended from a simple http socket program:
 * "Simple Internet client program - by Dan Drown <abob@linux.com>"
 * available (last I looked) at: 
 *      http://linux.omnipotent.net/article.php?article_id=5424
 */

#include <sys/types.h>  /* for socket,connect */
#include <sys/socket.h> /* for socket,connect */
#include <netinet/in.h> /* for htons */
#include <netdb.h>      /* for gethostbyname */
#include <string.h>     /* for memcpy */
#include <stdio.h>      /* for perror */
#include <stdlib.h>     /* for exit */
#include <unistd.h>     /* for read,write */
#include <stdarg.h>     /* needed for argument processing in debug */
#include <time.h>       /* needed for getting timestamp in debug */

#ifdef GOTSSL
#include <openssl/crypto.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif


// how big is everything
#define MAX_STR 1025
#define MAX_HDR_STR 2048
#define MAX_BUFFERS 1025
#define MAX_HEADERS 257
#define READ_BUF 80

// fake up a definition of bool if it doesnt exist
#ifndef bool
typedef unsigned char    bool;
#endif

// create my true and false
#ifndef false
typedef enum { false, true } mybool;
#endif


#ifdef DOHERROR
void herror(char * str);
#endif


struct mhttp_conn_st
{
    char       *host;
    int        port;
    bool       is_ssl;
    bool       is_chunked;
    int        fd;
#ifdef GOTSSL
    SSL_CTX*   ctx;
    SSL*       ssl;
    SSL_METHOD *meth;
    X509*      server_cert;
#endif
};

typedef struct mhttp_conn_st *mhttp_conn_t;



char *construct_request(char *action, char *url);

mhttp_conn_t mhttp_new_conn(void);

void mhttp_end_conn(mhttp_conn_t conn);

#ifdef GOTSSL
static int mhttp_verify_callback(int ok, X509_STORE_CTX* ctx);
#endif

int write_socket(mhttp_conn_t conn, const void *buf, size_t count);

int read_socket(mhttp_conn_t conn, void *buf);

int read_headers(mhttp_conn_t conn, char *str);

int find_content_length(void);

bool find_transfer_encoding(void);

int find_chunk(mhttp_conn_t conn, char **ptr, int *rem);

int check_url(char *purl, char **url, char **host);

int check_action(char *paction, char **action);

int get_port_and_uri(char *url, char *host, char **surl);

int mhttp_build_inet_addr(struct sockaddr_in *addr, const char *hostname, unsigned short int port);

int mhttp_connect_inet_addr(const char *hostname, unsigned short int port);

void mhttp_switch_debug(int set);

void mhttp_reset(void);

void mhttp_init(void);

void mhttp_add_header(char *hdr);

void mhttp_set_protocol(int proto);

void mhttp_set_body(char *bdy);

char *mhttp_get_response_headers(void);

char *mhttp_get_reason(void);

char *mhttp_get_response(void);

int mhttp_call(char *paction, char *purl);

int mhttp_get_status_code(void);

int mhttp_get_response_length(void);

void mhttp_debug(const char *msgfmt, ...);

