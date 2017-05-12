/*
 * This module is Copyright 2012 Khera Communications, Inc.
 * Copyright 2015 Matthew Seaman
 * It is licensed under the same terms as Perl itself.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <opendkim/dkim.h>

/* h2xs -A -n Mail::OpenDKIM */

/* callbacks */
static SV *dns_callback = (SV *)NULL;
static SV *final_callback = (SV *)NULL;
static SV *key_lookup_callback = (SV *)NULL;
static SV *prescreen_callback = (SV *)NULL;
static SV *signature_handle_callback = (SV *)NULL;
static SV *signature_handle_free_callback = (SV *)NULL;
static SV *signature_tagvalues_callback = (SV *)NULL;
static SV *dns_query_cancel_callback = (SV *)NULL;
static SV *dns_query_service_callback = (SV *)NULL;
static SV *dns_query_start_callback = (SV *)NULL;
static SV *dns_query_waitreply_callback = (SV *)NULL;

/*
 * dkim.h doesn't specify the contents of the DKIM and DKIM_SIGINFO structures, it just
 * declares them :-(
 * So this is an overkill size, that SHOULD be large enough.  See dkim-types.h for more
 * information about the structures
 */
#define	SIZEOF_DKIM		4096
#define	SIZEOF_DKIM_SIGINFO	1024

/*
 * These routines allow us to call callbacks that are written in and supplied using Perl that
 * are maintained and called from within the OpenDKIM library
 *
 * e.g.
 * sub dns_callback {
 *  my $context = shift;
 *
 *   print "DNS called back with context $context\n";
 * }
 *
 * set_dns_callback({ function => \&callback, interval => 1 });
 *
 * These are all dummy callbacks that we pass to OpenDKIM, and when OpenDKIM calls them they
 * call the Perl routines supplied by the caller
 */

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_dns_callback
 */
static void
call_dns_callback(const void *context)
{
	dSP;
	SV *sv = dns_callback;

	if(sv == NULL) {
		croak("Internal error: call_dns_callback called, but nothing to call");
		return;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(context, 0)));
	PUTBACK;

	call_sv(sv, G_DISCARD);
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_final
 */
static DKIM_CBSTAT
call_final_callback(DKIM *dkim, DKIM_SIGINFO **sigs, int nsigs)
{
	dSP;
	int count, status;
	SV *sv = final_callback;

	if(sv == NULL) {
		croak("Internal error: call_final_callback called, but nothing to call");
		return DKIM_CBSTAT_ERROR;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv((void *)dkim, SIZEOF_DKIM)));
	XPUSHs(sv_2mortal(newSVpv((void *)sigs, nsigs * SIZEOF_DKIM_SIGINFO)));
	XPUSHs(sv_2mortal(newSViv(nsigs)));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: final_callback routine returned %d items, 1 was expected",
			count);
		return DKIM_CBSTAT_ERROR;
	}

	status = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_key_lookup
 */
static DKIM_CBSTAT
call_key_lookup_callback(DKIM *dkim, DKIM_SIGINFO *siginfo, unsigned char *buf, size_t buflen)
{
	dSP;
	int count, status;
	SV *sv = key_lookup_callback;

	if(sv == NULL) {
		croak("Internal error: call_key_lookup_callback called, but nothing to call");
		return DKIM_CBSTAT_ERROR;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv((void *)dkim, SIZEOF_DKIM)));
	XPUSHs(sv_2mortal(newSVpv((void *)siginfo, SIZEOF_DKIM_SIGINFO)));
	XPUSHs(sv_2mortal(newSVpv((void *)buf, buflen + 1)));
	XPUSHs(sv_2mortal(newSViv(buflen)));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: key_lookup_callback routine returned %d items, 1 was expected",
			count);
		return DKIM_CBSTAT_ERROR;
	}

	status = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_prescreen
 */
static DKIM_CBSTAT
call_prescreen_callback(DKIM *dkim, DKIM_SIGINFO **sigs, int nsigs)
{
	dSP;
	int count, status;
	SV *sv = prescreen_callback;

	if(sv == NULL) {
		croak("Internal error: call_prescreen_callback called, but nothing to call");
		return DKIM_CBSTAT_ERROR;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv((void *)dkim, SIZEOF_DKIM)));
	XPUSHs(sv_2mortal(newSVpv((void *)sigs, nsigs * SIZEOF_DKIM_SIGINFO)));
	XPUSHs(sv_2mortal(newSViv(nsigs)));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: prescreen_callback routine returned %d items, 1 was expected",
			count);
		return DKIM_CBSTAT_ERROR;
	}

	status = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_signature_handle
 */
static void *
call_signature_handle_callback(void *closure)
{
	dSP;
	int count;
	void *v;
	SV *sv = signature_handle_callback;

	if(sv == NULL) {
		croak("Internal error: call_signature_handle_callback called, but nothing to call");
		return NULL;
	}

	PUSHMARK(SP);
	/* libOpenDKIM doesn't tell us the size of closure, so use best guess :-( */
	XPUSHs(sv_2mortal(newSVpv((void *)closure, BUFSIZ)));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: signature_handle_callback routine returned %d items, 1 was expected",
			count);
		return NULL;
	}

	v = POPp;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return v;
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_signature_handle_free
 */
static void
call_signature_handle_free_callback(void *closure, void *ptr)
{
	dSP;
	SV *sv = signature_handle_free_callback;

	if(sv == NULL) {
		croak("Internal error: call_handle_free_callback called, but nothing to call");
		return;
	}

	PUSHMARK(SP);
	/* libOpenDKIM doesn't tell us the size of closure, so use best guess :-( */
	XPUSHs(sv_2mortal(newSVpv((void *)closure, BUFSIZ)));
	XPUSHs(sv_2mortal(newSVpv((void *)ptr, BUFSIZ)));
	PUTBACK;

	call_sv(sv, G_DISCARD);
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_signature_tagvalues
 */
static void
call_signature_tagvalues_callback(void *user, dkim_param_t pcode, const unsigned char *param, const unsigned char *value)
{
	dSP;
	SV *sv = signature_tagvalues_callback;

	if(sv == NULL) {
		croak("Internal error: call_signature_tagvalues_callback called, but nothing to call");
		return;
	}

	PUSHMARK(SP);
	/* libOpenDKIM doesn't tell us the size of user, so use best guess :-( */
	XPUSHs(sv_2mortal(newSVpv((void *)user, BUFSIZ)));
	XPUSHs(sv_2mortal(newSViv(pcode)));
	XPUSHs(sv_2mortal(newSVpv(param, 0)));
	XPUSHs(sv_2mortal(newSVpv(value, 0)));
	PUTBACK;

	call_sv(sv, G_DISCARD);
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_query_cancel
 */
static int
call_dns_query_cancel_callback(void *a, void *b)
{
	dSP;
	int count, ret;
	SV *sv = dns_query_cancel_callback;

	if(sv == NULL) {
		croak("Internal error: call_dns_query_cancel called, but nothing to call");
		return -1;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(a, sizeof(void *))));
	XPUSHs(sv_2mortal(newSVpv(b, sizeof(void *))));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: dns_query_cancel_callback routine returned %d items, 1 was expected",
			count);
		return -1;
	}

	ret = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_query_service
 */
static void
call_dns_query_service_callback(void *service)
{
	dSP;
	SV *sv = dns_query_service_callback;

	if(sv == NULL) {
		croak("Internal error: call_dns_query_service called, but nothing to call");
		return;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(service, sizeof(void *))));
	PUTBACK;

	call_sv(sv, G_DISCARD);
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_set_query_start
 */
static int
call_dns_query_start_callback(void *a, int b, unsigned char *c, unsigned char *d, size_t e, void **f)
{
	dSP;
	int count, ret;
	SV *sv = dns_query_start_callback;

	if(sv == NULL) {
		croak("Internal error: call_dns_query_service called, but nothing to call");
		return -1;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(a, sizeof(void *))));
	XPUSHs(sv_2mortal(newSViv(b)));
	XPUSHs(sv_2mortal(newSVpv(c, 0)));
	XPUSHs(sv_2mortal(newSVpv(d, e + 1)));
	XPUSHs(sv_2mortal(newSViv(e)));
	XPUSHs(sv_2mortal(newSVpv((void *)f, sizeof(void **))));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: dns_query_start_callback routine returned %d items, 1 was expected",
			count);
		return -1;
	}

	ret = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

/*
 * called when the OpenDKIMlibrary wants to call the callback function provided to
 * dkim_dns_set_query_waitreply
 */
static int
call_dns_query_waitreply_callback(void *a, void *b, struct timeval *c, size_t *d, int *e, int *f)
{
	dSP;
	int count, ret;
	SV *sv = dns_query_start_callback;

	if(sv == NULL) {
		croak("Internal error: call_dns_query_service called, but nothing to call");
		return -1;
	}

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(a, sizeof(void *))));
	XPUSHs(sv_2mortal(newSVpv(b, sizeof(void *))));
	XPUSHs(sv_2mortal(newSVpv((void *)c, sizeof(struct timeval))));
	XPUSHs(sv_2mortal(newSVpv((void *)d, sizeof(size_t))));
	XPUSHs(sv_2mortal(newSVpv((void *)e, sizeof(int))));
	XPUSHs(sv_2mortal(newSVpv((void *)f, sizeof(int))));
	PUTBACK;

	count = call_sv(sv, G_SCALAR);

	SPAGAIN;

	if(count != 1) {
		croak("Internal error: dns_query_waitreply_callback routine returned %d items, 1 was expected",
			count);
		return -1;
	}

	ret = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

MODULE = Mail::OpenDKIM		PACKAGE = Mail::OpenDKIM
PROTOTYPES: DISABLE

# These routines are called directly from the end user Perl code
unsigned long
dkim_ssl_version()
	CODE:
		RETVAL = dkim_ssl_version();
	OUTPUT:
		RETVAL

unsigned long
dkim_libversion()
	CODE:
		RETVAL = dkim_libversion();
	OUTPUT:
		RETVAL

const char *
dkim_getresultstr(result)
		DKIM_STAT result
	CODE:
		RETVAL = dkim_getresultstr(result);
	OUTPUT:
		RETVAL

const char *
dkim_sig_geterrorstr(sigerr)
		DKIM_SIGERROR sigerr
	CODE:
		RETVAL = dkim_sig_geterrorstr(sigerr);
	OUTPUT:
		RETVAL

int
dkim_mail_parse(line, user_out, domain_out)
		char *line
		unsigned char *user_out = NO_INIT
		unsigned char *domain_out = NO_INIT
	CODE:
		RETVAL = dkim_mail_parse(line, &user_out, &domain_out);
	OUTPUT:
		user_out
		domain_out
		RETVAL

# These routines are called by the glue layer which supplies them with an OO interface
DKIM_LIB *
_dkim_init()
	CODE:
		RETVAL = dkim_init(NULL, NULL);
	OUTPUT:
		RETVAL

void
_dkim_close(d)
		DKIM_LIB *d
	CODE:
		dkim_close(d);

DKIM_STAT
_dkim_options(lib, op, opt, data, len)
		DKIM_LIB *lib
		int op
		int opt
		void *data
		size_t len
	CODE:
		RETVAL = dkim_options(lib, op, opt, data, len);
	OUTPUT:
		RETVAL

_Bool
_dkim_libfeature(d, fc)
		DKIM_LIB *d
		unsigned int fc
	CODE:
		RETVAL = dkim_libfeature(d, fc);
	OUTPUT:
		RETVAL

int
_dkim_flush_cache(d)
		DKIM_LIB *d
	CODE:
		RETVAL = dkim_flush_cache(d);
	OUTPUT:
		RETVAL

#if OPENDKIM_LIB_VERSION >= 0x02080000
DKIM_STAT
_dkim_getcachestats(libhandle, queries, hits, expired, keys)
		DKIM_LIB *libhandle
		unsigned int queries = NO_INIT
		unsigned int hits = NO_INIT
		unsigned int expired = NO_INIT
		unsigned int keys = NO_INIT
	CODE:
		RETVAL = dkim_getcachestats(libhandle, &queries, &hits, &expired, &keys, 0);
	OUTPUT:
		queries
		hits
		expired
		keys
		RETVAL

#else
DKIM_STAT
_dkim_getcachestats(queries, hits, expired)
		unsigned int queries = NO_INIT
		unsigned int hits = NO_INIT
		unsigned int expired = NO_INIT
	CODE:
		RETVAL = dkim_getcachestats(&queries, &hits, &expired);
	OUTPUT:
		queries
		hits
		expired
		RETVAL

#endif

DKIM *
_dkim_sign(libhandle, id, secretkey, selector, domain, hdrcanon_alg, bodycanon_alg, sign_alg, length, statp)
		DKIM_LIB *libhandle
		const char *id
		const char *secretkey
		const char *selector
		const char *domain
		dkim_canon_t hdrcanon_alg
		dkim_canon_t bodycanon_alg
		dkim_alg_t sign_alg
		off_t length
		DKIM_STAT statp = NO_INIT
	CODE:
		RETVAL = dkim_sign(libhandle, (const unsigned char *)id, NULL, (dkim_sigkey_t)secretkey, (const unsigned char *)selector, (const unsigned char *)domain, hdrcanon_alg, bodycanon_alg, sign_alg, length, &statp);
	OUTPUT:
		statp
		RETVAL

# TODO: memclosure, if that is ever needed
DKIM *
_dkim_verify(libhandle, id,  statp)
		DKIM_LIB *libhandle
		const char *id
		DKIM_STAT statp = NO_INIT
	CODE:
		RETVAL = dkim_verify(libhandle, id, NULL, &statp);
	OUTPUT:
		statp
		RETVAL

DKIM_STAT
_dkim_set_dns_callback(libopendkim, func, interval)
		DKIM_LIB *libopendkim
		SV *func
		unsigned int interval
	CODE:
		if(dns_callback == (SV *)NULL)
			dns_callback = newSVsv(func);
		else
			SvSetSV(dns_callback, func);

		RETVAL = dkim_set_dns_callback(libopendkim, call_dns_callback, interval);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_final(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(final_callback == (SV *)NULL)
			final_callback = newSVsv(func);
		else
			SvSetSV(final_callback, func);

		RETVAL = dkim_set_final(libopendkim, call_final_callback);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_key_lookup(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(key_lookup_callback == (SV *)NULL)
			key_lookup_callback = newSVsv(func);
		else
			SvSetSV(key_lookup_callback, func);

		RETVAL = dkim_set_key_lookup(libopendkim, call_key_lookup_callback);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_prescreen(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(prescreen_callback == (SV *)NULL)
			prescreen_callback = newSVsv(func);
		else
			SvSetSV(prescreen_callback, func);

		RETVAL = dkim_set_prescreen(libopendkim, call_prescreen_callback);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_signature_handle(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(signature_handle_callback == (SV *)NULL)
			signature_handle_callback = newSVsv(func);
		else
			SvSetSV(signature_handle_callback, func);

		RETVAL = dkim_set_signature_handle(libopendkim, call_signature_handle_callback);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_signature_handle_free(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(signature_handle_free_callback == (SV *)NULL)
			signature_handle_free_callback = newSVsv(func);
		else
			SvSetSV(signature_handle_free_callback, func);

		RETVAL = dkim_set_signature_handle_free(libopendkim, call_signature_handle_free_callback);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_signature_tagvalues(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(signature_tagvalues_callback == (SV *)NULL)
			signature_tagvalues_callback = newSVsv(func);
		else
			SvSetSV(signature_tagvalues_callback, func);

		RETVAL = dkim_set_signature_tagvalues(libopendkim, call_signature_tagvalues_callback);
	OUTPUT:
		RETVAL

void
_dkim_dns_set_query_cancel(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(dns_query_cancel_callback == (SV *)NULL)
			dns_query_cancel_callback = newSVsv(func);
		else
			SvSetSV(dns_query_cancel_callback, func);

		dkim_dns_set_query_cancel(libopendkim, call_dns_query_cancel_callback);

void
_dkim_dns_set_query_service(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(dns_query_service_callback == (SV *)NULL)
			dns_query_service_callback = newSVsv(func);
		else
			SvSetSV(dns_query_service_callback, func);

		dkim_dns_set_query_service(libopendkim, call_dns_query_service_callback);

void
_dkim_dns_set_query_start(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(dns_query_start_callback == (SV *)NULL)
			dns_query_start_callback = newSVsv(func);
		else
			SvSetSV(dns_query_start_callback, func);

		dkim_dns_set_query_start(libopendkim, call_dns_query_start_callback);

void
_dkim_dns_set_query_waitreply(libopendkim, func)
		DKIM_LIB *libopendkim
		SV *func
	CODE:
		if(dns_query_waitreply_callback == (SV *)NULL)
			dns_query_waitreply_callback = newSVsv(func);
		else
			SvSetSV(dns_query_waitreply_callback, func);

		dkim_dns_set_query_waitreply(libopendkim, call_dns_query_waitreply_callback);

DKIM_STAT
_dkim_free(d)
		DKIM *d
	CODE:
		RETVAL = dkim_free(d);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_header(dkim, header, len)
		DKIM *dkim
		unsigned char *header
		size_t len
	CODE:
		RETVAL = dkim_header(dkim, header, len);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_body(dkim, bodyp, len)
		DKIM *dkim
		unsigned char *bodyp
		size_t len
	CODE:
		RETVAL = dkim_body(dkim, bodyp, len);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_eoh(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_eoh(dkim);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_chunk(dkim, chunkp, len)
		DKIM *dkim
		unsigned char *chunkp
		size_t len
	CODE:
		RETVAL = dkim_chunk(dkim, chunkp, len);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_eom(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_eom(dkim, NULL);
	OUTPUT:
		RETVAL

const char *
_dkim_getid(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_getid(dkim);
	OUTPUT:
		RETVAL

#if OPENDKIM_LIB_VERSION < 0x02070000

uint64_t
_dkim_get_msgdate(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_get_msgdate(dkim);
	OUTPUT:
		RETVAL

#endif

DKIM_STAT
_dkim_get_sigsubstring(dkim, sig, buf, buflen)
		DKIM *dkim
		DKIM_SIGINFO *sig
		char *buf
		size_t buflen
	CODE:
		RETVAL = dkim_get_sigsubstring(dkim, sig, buf, &buflen);
	OUTPUT:
		buflen
		RETVAL

DKIM_STAT
_dkim_key_syntax(dkim, str, len)
		DKIM *dkim
		unsigned char *str
		size_t len
	CODE:
		RETVAL = dkim_key_syntax(dkim, str, len);
	OUTPUT:
		RETVAL

unsigned char *
_dkim_get_signer(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_get_signer(dkim);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_signer(dkim, signer)
		DKIM *dkim
		const char *signer
	CODE:
		RETVAL = dkim_set_signer(dkim, signer);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_margin(dkim, margin)
		DKIM *dkim
		int margin
	CODE:
		RETVAL = dkim_set_margin(dkim, margin);
	OUTPUT:
		RETVAL

void *
_dkim_get_user_context(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_get_user_context(dkim);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_set_user_context(dkim, ctx)
		DKIM *dkim
		void *ctx
	CODE:
		RETVAL = dkim_set_user_context(dkim, ctx);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_atps_check(dkim, sig, timeout, res)
		DKIM *dkim
		DKIM_SIGINFO *sig
		struct timeval *timeout
		dkim_atps_t res = NO_INIT;
	CODE:
		RETVAL = dkim_atps_check(dkim, sig, timeout, &res);
	OUTPUT:
		res
		RETVAL

DKIM_STAT
_dkim_diffheaders(dkim, canon, maxcost, ohdrs, nohdrs, out, nout)
		DKIM *dkim
		dkim_canon_t canon
		int maxcost
		char *&ohdrs
		int nohdrs
		struct dkim_hdrdiff *out = NO_INIT
		int nout = NO_INIT
	CODE:
		RETVAL = dkim_diffheaders(dkim, canon, maxcost, &ohdrs, nohdrs, &out, &nout);
	OUTPUT:
		out
		nout
		RETVAL

DKIM_STAT
_dkim_getsighdr(dkim, buf, len, initial)
		DKIM *dkim
		unsigned char *buf
		size_t len
		size_t initial
	CODE:
		RETVAL = dkim_getsighdr(dkim, buf, len, initial);
	OUTPUT:
		buf
		RETVAL

DKIM_STAT
_dkim_getsighdr_d(dkim, initial, buf, len)
		DKIM *dkim
		size_t initial
		unsigned char *&buf = NO_INIT
		size_t len = NO_INIT
	CODE:
		RETVAL = dkim_getsighdr_d(dkim, initial, &buf, &len);
	OUTPUT:
		buf
		len
		RETVAL

DKIM_SIGINFO *
_dkim_getsignature(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_getsignature(dkim);
	OUTPUT:
		RETVAL

# Returns 3 values: $rc, $nsigs, @sigs

void
_dkim_getsiglist(dkim)
		DKIM *dkim
	PPCODE:
		DKIM_SIGINFO **s = NULL;
		int nsigs;
		DKIM_STAT rc = dkim_getsiglist(dkim, &s, &nsigs);

		/*
		 * Push the sigs on to the stack so that they appear to Perl as a @list
		 */
		XPUSHs(sv_2mortal(newSViv(rc)));
		if(rc == DKIM_STAT_OK) {
			int i;

			XPUSHs(sv_2mortal(newSViv(nsigs)));

			for(i = 0; i < nsigs; i++, s++)
				XPUSHs(sv_2mortal(newSVpv((char *)*s, sizeof(DKIM_SIGINFO *))));

			XSRETURN(i + 2);	/* number of items put on the stack */
		} else {
			XPUSHs(sv_2mortal(newSViv(0)));

			XSRETURN(2);
		}

DKIM_STAT
_dkim_ohdrs(dkim, sig, ptrs, cnt)
		DKIM *dkim
		DKIM_SIGINFO *sig
		unsigned char &ptrs = NO_INIT
		int cnt
	CODE:
		RETVAL = dkim_ohdrs(dkim, sig, &ptrs, &cnt);
	OUTPUT:
		ptrs
		cnt
		RETVAL

_Bool
_dkim_getpartial(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_getpartial(dkim);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_setpartial(dkim, value)
		DKIM *dkim
		_Bool value
	CODE:
		RETVAL = dkim_setpartial(dkim, value);
	OUTPUT:
		RETVAL

const char *
_dkim_getdomain(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_getdomain(dkim);
	OUTPUT:
		RETVAL

const char *
_dkim_getuser(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_getuser(dkim);
	OUTPUT:
		RETVAL

unsigned long
_dkim_minbody(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_minbody(dkim);
	OUTPUT:
		RETVAL

int
_dkim_getmode(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_getmode(dkim);
	OUTPUT:
		RETVAL

unsigned int
_dkim_sig_getbh(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_getbh(sig);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_sig_getcanonlen(dkim, sig, msglen, canonlen, signlen)
		DKIM *dkim
		DKIM_SIGINFO *sig
		off_t msglen = NO_INIT
		off_t canonlen = NO_INIT
		off_t signlen = NO_INIT
	CODE:
		RETVAL = dkim_sig_getcanonlen(dkim, sig, &msglen, &canonlen, &signlen);
	OUTPUT:
		msglen
		canonlen
		signlen
		RETVAL

DKIM_STAT
_dkim_sig_getcanons(sig, hdr, body)
		DKIM_SIGINFO *sig
		dkim_canon_t hdr = NO_INIT
		dkim_canon_t body = NO_INIT
	CODE:
		RETVAL = dkim_sig_getcanons(sig, &hdr, &body);
	OUTPUT:
		hdr
		body
		RETVAL

void *
_dkim_sig_getcontext(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_getcontext(sig);
	OUTPUT:
		RETVAL

int
_dkim_sig_getdnssec(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_getdnssec(sig);
	OUTPUT:
		RETVAL

const char *
_dkim_sig_getdomain(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_getdomain(sig);
	OUTPUT:
		RETVAL

int
_dkim_sig_geterror(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_geterror(sig);
	OUTPUT:
		RETVAL

unsigned int
_dkim_sig_getflags(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_getflags(sig);
	OUTPUT:
		RETVAL

void
_dkim_sig_ignore(sig)
		DKIM_SIGINFO *sig
	CODE:
		dkim_sig_ignore(sig);

DKIM_STAT
_dkim_sig_getidentity(dkim, sig, val, vallen)
		DKIM *dkim
		DKIM_SIGINFO *sig
		char *val
		size_t vallen
	CODE:
		RETVAL = dkim_sig_getidentity(dkim, sig, val, vallen);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_sig_getkeysize(sig, bits)
		DKIM_SIGINFO *sig
		unsigned int bits = NO_INIT
	CODE:
		RETVAL = dkim_sig_getkeysize(sig, &bits);
	OUTPUT:
		bits
		RETVAL

DKIM_STAT
_dkim_sig_getreportinfo(dkim, sig, hfd, bfd, addrbuf, addrlen, optsbuf, optslen, smtpbuf, smtplen, interval)
		DKIM *dkim
		DKIM_SIGINFO *sig
		int *hfd
		int *bfd
		char *addrbuf
		size_t addrlen
		char *optsbuf
		size_t optslen
		char *smtpbuf
		size_t smtplen
		unsigned int interval = NO_INIT
	CODE:
		RETVAL = dkim_sig_getreportinfo(dkim, sig, hfd, bfd, addrbuf, addrlen, optsbuf, optslen, smtpbuf, smtplen, &interval);
	OUTPUT:
		interval
		RETVAL

const char *
_dkim_sig_getselector(sig)
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_getselector(sig);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_sig_getsignalg(sig, alg)
		DKIM_SIGINFO *sig
		dkim_alg_t alg = NO_INIT
	CODE:
		RETVAL = dkim_sig_getsignalg(sig, &alg);
	OUTPUT:
		alg
		RETVAL

DKIM_STAT
_dkim_sig_getsignedhdrs(dkim, sig, hdrs, hdrlen, nhdrs)
		DKIM *dkim
		DKIM_SIGINFO *sig
		unsigned char *hdrs
		size_t hdrlen
		unsigned int nhdrs
	CODE:
		RETVAL = dkim_sig_getsignedhdrs(dkim, sig, hdrs, hdrlen, &nhdrs);
	OUTPUT:
		nhdrs
		RETVAL

DKIM_STAT
_dkim_sig_getsigntime(sig, when)
		DKIM_SIGINFO *sig
		time_t when
	CODE:
		RETVAL = dkim_sig_getsigntime(sig, &when);
	OUTPUT:
		when
		RETVAL

bool
_dkim_sig_hdrsigned(sig, hdr)
		DKIM_SIGINFO *sig
		char *hdr
	CODE:
		RETVAL = dkim_sig_hdrsigned(sig, hdr);
	OUTPUT:
		RETVAL

DKIM_STAT
_dkim_sig_process(dkim, sig)
		DKIM *dkim
		DKIM_SIGINFO *sig
	CODE:
		RETVAL = dkim_sig_process(dkim, sig);
	OUTPUT:
		RETVAL

int
_dkim_sig_syntax(dkim, str, len)
                DKIM *dkim
                unsigned char *str
                size_t len
	CODE:
		RETVAL = dkim_sig_syntax(dkim, str, len);
	OUTPUT:
                RETVAL

unsigned char *
_dkim_sig_gettagvalue(sig, keytag, tag)
		DKIM_SIGINFO *sig
		_Bool keytag
		char *tag
	CODE:
		RETVAL = dkim_sig_gettagvalue(sig, keytag, tag);
	OUTPUT:
		RETVAL

const char *
_dkim_geterror(dkim)
		DKIM *dkim
	CODE:
		RETVAL = dkim_geterror(dkim);
	OUTPUT:
		RETVAL
