#include <netinet/in.h>
#include <ei.h>
#include <erl_interface.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "const-c.inc"

typedef ETERM * PERL_ETERM;
typedef struct in_addr hoge;

MODULE = Erlang::Interface		PACKAGE = Erlang::Interface
INCLUDE: const-xs.inc
INCLUDE: Interface_macros.xs

#pragma erl_connect_init(number, cookie, creation)



void erl_init(x, y)
    void* x
    long y

void erl_set_compat_rel(release_number)
	unsigned release_number

int erl_connect_init(number, cookie, creation)
    int number
    char *cookie
    short creation

int erl_connect_xinit(host, alive, node, addr, cookie, creation)
    char* host
    char* alive
    char* node
    void* addr
    char* cookie
    short creation

int erl_connect(node)
    char* node

int erl_xconnect(addr, alive)
    void* addr
    char* alive
CODE:
{
    RETVAL = erl_xconnect((struct in_addr*)&addr, alive);
}
OUTPUT:
    RETVAL

int erl_close_connection(fd)
	int fd

int erl_receive(fd, bufp, bufsize)
	int fd
	SV *bufp
	int bufsize
PREINIT:
	char buf[10240];
	char *p;
CODE:
	if(bufsize > 10240){
		p = malloc(bufsize);
		RETVAL = erl_receive(fd, p, bufsize);
        sv_setpvn(bufp, p, RETVAL);
		free(p);
	}else{
		RETVAL = erl_receive(fd, buf, bufsize);
        sv_setpvn(bufp, buf, RETVAL);
	}
OUTPUT:
	RETVAL
	bufp

int erl_receive_msg(fd, bufp, bufsize, emsg)
	int fd
	SV *bufp
	int bufsize
	SV *emsg
PREINIT:
	char *p;
    ErlMessage *msg;
CODE:
	Newx(msg, sizeof(ErlMessage), ErlMessage);
	p = malloc(bufsize);
	RETVAL = erl_receive_msg(fd, p, bufsize, msg);
    sv_setpvn(bufp, p, RETVAL);
	free(p);
	sv_setiv(emsg, (IV)msg);
OUTPUT:
	RETVAL
	bufp
	emsg

int erl_xreceive_msg(fd, bufpp, bufsizep, emsg)
	int fd
	SV *bufpp
	SV *bufsizep
	SV *emsg
PREINIT:
	unsigned char *p;
    ErlMessage *msg;
	int bufsize;
CODE:
	Newx(msg, sizeof(ErlMessage), ErlMessage);
	bufsize = SvIV(bufsizep);
	p = malloc(bufsize);
	RETVAL = erl_xreceive_msg(fd, &p, &bufsize, msg);
	free(p);
	sv_setiv(bufsizep, bufsize);
	sv_setiv(emsg, (IV)msg);
OUTPUT:
	RETVAL
	bufsizep
	emsg

int erl_send(fd, to, msg)
    int fd
    ETERM *to
    ETERM *msg

int erl_reg_send(fd, to, msg)
    int fd
    char *to
    ETERM *msg

void erl_msg_free(emsg)
	SV *emsg
PREINIT:
    ErlMessage *msg;
CODE:
    msg=(ErlMessage*)SvIV(emsg);
	erl_print_term(stdout, msg->msg);


int erl_publish(port)
	int port

int erl_accept(listensock, conp)
	int listensock
	ErlConnect *conp

const char *erl_thiscookie()

const char *erl_thisnodename()                                             

const char *erl_thishostname()

const char *erl_thisalivename()

short erl_thiscreation()

int erl_length(list)
    ETERM* list

ETERM* erl_mk_atom(string)
    char* string

ETERM* erl_mk_binary(bptr)
    char* bptr
CODE:
    int size = strlen(bptr);
    RETVAL = erl_mk_binary(bptr, size);
OUTPUT:
    RETVAL

ETERM* erl_mk_empty_list()

ETERM* erl_mk_estring(string, len)
    char* string
	int len

ETERM* erl_mk_float(f)
    double f

ETERM* erl_mk_int(n)
    int n

ETERM* erl_mk_list(array)
    AV* array
CODE:
	int i;
    int size = av_len(array) + 1;
	ETERM** earray = malloc(sizeof(ETERM*) * size);

	for(i=0; i<size; i++){
		SV** sv = av_fetch(array, i, 0);
		earray[i] = (ETERM*)SvRV(*sv);
//		erl_print_term(stdout, SvIV(*tmp));
	}
    RETVAL = erl_mk_list(earray, size);
    free(earray);
OUTPUT:
    RETVAL

ETERM* erl_mk_pid(node, number, serial, creation)
	const char *node
	unsigned int number
	unsigned int serial
	unsigned int creation

ETERM* erl_mk_port(node, number, creation)
	const char *node
	unsigned int number
	unsigned int creation

ETERM* erl_mk_ref(node, number, creation)
	const char *node
	unsigned int number
	unsigned int creation

ETERM* erl_mk_long_ref(node, n1, n2, n3, creation)
	const char *node
	unsigned int n1
	unsigned int n2
	unsigned int n3
	unsigned int creation

ETERM* erl_mk_string(string)
    char* string

ETERM* erl_mk_tuple(array)
    AV* array
CODE:
	int i;
    int size = av_len(array) + 1;
	ETERM** earray = malloc(sizeof(ETERM*) * size);

	for(i=0; i<size; i++){
		SV** sv = av_fetch(array, i, 0);
		earray[i] = (ETERM*)SvIV(*sv);
	}
    RETVAL = erl_mk_tuple(earray, size);
    free(earray);
OUTPUT:
    RETVAL

ETERM* erl_mk_uint(n)
	unsigned int n

ETERM* erl_mk_var(name)
	char *name

int erl_print_term(stream, term)
	FILE *stream
	ETERM *term

int erl_size(term)
	ETERM *term

ETERM* erl_tl(list)
	ETERM *list

ETERM * erl_var_content(term, name)
	ETERM *term
	char *name
