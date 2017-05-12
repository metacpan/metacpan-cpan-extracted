/*
 *	Cclient.xs
 *
 *	Copyright (c) 1998,1999,2000 Malcolm Beattie
 *
 *	You may distribute under the terms of either the GNU General Public
 *	License or the Artistic License, as specified in the README file.
 */

/*
 * Must include mail.h before perl's stuff since mail.h uses op
 * and we can't simply undef it because we need it too for GIMME.
 * mail.h also defines INIT and OP_PROTOTYPE so we have to undefine
 * them afterwards since perl needs to define them too. Still worse:
 * we actually need the cclient INIT macro so we copy its definition
 * from mail.h and call it CCLIENT_LOCAL_INIT instead. This macro
 * therefore needs keeping in sync with mail.h.
 * For imap-2000 we also need to include stddef.h first to ensure
 * size_t is defined since misc.h needs it.
 */
#include <stddef.h>
#include "mail.h"
#include "misc.h"
#include "rfc822.h"

#define CCLIENT_LOCAL_INIT(s,d,data,size) \
    ((*((s)->dtb = &d)->init) (s,data,size))
#undef INIT

#ifdef OP_PROTOTYPE
#undef OP_PROTOTYPE
#endif

/* Ensure na and sv_undef get defined */
#define PERL_POLLUTE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef MAILSTREAM *Mail__Cclient;

/* Magic signature for Cclient's mg_private is "Cc" */
#define Mail__Cclient_MAGIC_SIGNATURE 0x4363

#define MUST_EXIST	1

static HV *mailstream2sv;	/* Map MAILSTREAM* to SV* */
static HV *stash_Cclient;	/* Mail::Cclient:: stash */
static HV *stash_Address;	/* Mail::Cclient::Address stash */
static HV *stash_Envelope;	/* Mail::Cclient::Envelope stash */
static HV *stash_Body;		/* Mail::Cclient::Body stash */
static HV *stash_Elt;		/* Mail::Cclient::Elt stash */
static HV *callback;		/* Maps callback names to Perl SV callbacks */
static SV *address_fields;	/* \%Mail::Cclient::Address::FIELDS */
static SV *envelope_fields;	/* \%Mail::Cclient::Envelope::FIELDS */
static SV *body_fields;		/* \%Mail::Cclient::Body::FIELDS */
static SV *elt_fields;		/* \%Mail::Cclient::Elt::FIELDS */

#include "patchlevel.h"
#if PATCHLEVEL < 4
static SV *
newRV_noinc(SV *ref)
{
    SV *sv = newRV(ref);
    SvREFCNT_dec(ref);
    return sv;
}
#endif

static SV *str_to_sv(char *str)
{
    return str ? newSVpv(str, 0) : newSVsv(&sv_undef);
}

static SV *get_mailstream_sv(MAILSTREAM *stream, char *class)
{
    SV **svp = hv_fetch(mailstream2sv, (char*)&stream, sizeof(stream), FALSE);
    SV *sv;

#ifdef PERL_CCLIENT_DEBUG
    fprintf(stderr, "get_mailstream_sv(%p, %s), hv_fetch returns SV %p\n",
	    stream, class, svp ? *svp : 0); /* debug */
#endif
    if (svp)
	sv = *svp;
    else {
	SV *rv = (SV*)newHV();
	sv = sv_bless(newRV(rv), stash_Cclient);
	SvREFCNT_dec(rv);
	sv_magic(rv, newSViv((IV)stream), '~', 0, 0);
	SvMAGIC(rv)->mg_private = Mail__Cclient_MAGIC_SIGNATURE;
	hv_store(mailstream2sv, (char*)&stream, sizeof(stream), sv, 0);
    }
#ifdef PERL_CCLIENT_DEBUG
    fprintf(stderr, "returning %p, type %d\n", sv, SvTYPE(sv)); /* debug */
#endif
    return sv;
}

static SV *
mm_callback(char *name)
{
    dSP;
    SV **svp = hv_fetch(callback, name, strlen(name), FALSE);

#ifdef PERL_CCLIENT_DEBUG
    fprintf(stderr, "mm_callback(%s)\n", name);
#endif
    if (svp && SvOK(*svp))
	return *svp;
    return 0;
}

/*
 * C-client data structure manipulation
 */

/*
 * make_address turns a C-client ADDRESS (representing a list of
 * email addresses) into a Perl ref to a list of addresses. Each
 * single address is represented by Perl as a list ref
 *     [keyref, personal, adl, mailbox, host, error]
 * (though the error entry is optional and may be absent)
 * blessed into class Mail::Cclient::Address. keyref is a ref to
 * %Mail::Cclient::Address::FIELDS for 5.005 pseudo-hash access to the
 * object. Note that make_address returns an AV*, not a ref to one.
 */
static AV *
make_address(ADDRESS *address)
{
    AV *alist = newAV();
    for (; address; address = address->next) {
	AV *a = newAV();
	av_push(a, SvREFCNT_inc(address_fields));
	av_push(a, str_to_sv(address->personal));
	av_push(a, str_to_sv(address->adl));
	av_push(a, str_to_sv(address->mailbox));
	av_push(a, str_to_sv(address->host));
	if (address->error)
	    av_push(a, str_to_sv(address->error));
	av_push(alist, sv_bless(newRV_noinc((SV*)a), stash_Address));
    }
    return alist;
}

/*
 * make_envelope turns a C-client ENVELOPE (representing the
 * RFC822 headers of a message) into a Perl list ref of the form
 *     [keyref, remail, return_path, date, from, sender, reply_to,
 *      subject, to, cc, bcc, in_reply_to, message_id,
 *      newsgroups, followup_to, references]
 * blessed into Mail::Cclient::Envelope. keyref is a ref to
 * %Mail::Cclient::Envelope::FIELDS for 5.005 pseudo-hash access
 * to the object.
 */
static SV *
make_envelope(ENVELOPE *envelope)
{
    AV *e = newAV();
    av_push(e, SvREFCNT_inc(envelope_fields));
    av_push(e, str_to_sv(envelope->remail));
    av_push(e, newRV_noinc((SV*)make_address(envelope->return_path)));
    av_push(e, str_to_sv(envelope->date));
    av_push(e, newRV_noinc((SV*)make_address(envelope->from)));
    av_push(e, newRV_noinc((SV*)make_address(envelope->sender)));
    av_push(e, newRV_noinc((SV*)make_address(envelope->reply_to)));
    av_push(e, str_to_sv(envelope->subject));
    av_push(e, newRV_noinc((SV*)make_address(envelope->to)));
    av_push(e, newRV_noinc((SV*)make_address(envelope->cc)));
    av_push(e, newRV_noinc((SV*)make_address(envelope->bcc)));
    av_push(e, str_to_sv(envelope->in_reply_to));
    av_push(e, str_to_sv(envelope->message_id));
    av_push(e, str_to_sv(envelope->newsgroups));
    av_push(e, str_to_sv(envelope->followup_to));
    av_push(e, str_to_sv(envelope->references));
    return sv_bless(newRV_noinc((SV*)e), stash_Envelope);
}

/*
 * make_elt turns a C-client MESSAGECACHE ("elt") into a Perl list
 * ref of the form
 *     [keyref, msgno, date, flags, rfc822_size]
 * blessed into Mail::Cclient::Elt. Date contains the internal date
 * information which held in separate bit fields in the underlying
 * C structure but which is presented in Perl as a string in the form
 *     yyyy-mm-dd hh:mm:ss [+-]hhmm
 * The flags field is a ref to a list of strings such as
 * \Deleted, \Flagged, \Answered etc (as per RFC 2060) plus
 * user-defined flag names set via the Mail::Cclient setflag method.
 * %Mail::Cclient::Envelope::FIELDS for 5.005 pseudo-hash access
 * to the object. keyref is a ref to %Mail::Cclient::Elt::FIELDS for
 * 5.005 pseudo-hash access to the object.
 */
static SV *
make_elt(MAILSTREAM *stream, MESSAGECACHE *elt)
{
    AV *av = newAV();
    AV *flags = newAV();
    char datebuf[26]; /* to fit "yyyy-mm-dd hh:mm:ss [+-]hhmm\0" */
    int i;
    
    av_push(av, SvREFCNT_inc(elt_fields));
    av_push(av, newSViv(elt->msgno));
    /*
     * year field is OK until 2098 since it's an offset from BASEYEAR
     * which in newer cclients is 1970 (was 1969) and elt->year is a
     * bitfield with 7 bits.
     */
    sprintf(datebuf, "%04d-%02d-%02d %02d:%02d:%02d %c%02d%02d",
	    BASEYEAR + elt->year, elt->month, elt->day, elt->hours,
	    elt->minutes, elt->seconds,
	    elt->zoccident ? '-' : '+', elt->zhours, elt->zminutes);
    av_push(av, newSVpv(datebuf, sizeof(datebuf)));
    if (elt->seen)
	av_push(flags, newSVpv("\\Seen", 5));
    if (elt->deleted)
	av_push(flags, newSVpv("\\Deleted", 8));
    if (elt->flagged)
	av_push(flags, newSVpv("\\Flagged", 8));
    if (elt->answered)
	av_push(flags, newSVpv("\\Answered", 9));
    if (elt->draft)
	av_push(flags, newSVpv("\\Draft", 6));
    if (elt->valid)
	av_push(flags, newSVpv("\\Valid", 6));
    if (elt->recent)
	av_push(flags, newSVpv("\\Recent", 7));
    if (elt->searched)
	av_push(flags, newSVpv("\\Searched", 9));
    for (i = 0; i < NUSERFLAGS; i++) {
	if (elt->user_flags & (1 << i)) {
	    char *fl = stream->user_flags[i];
	    SV *sv = fl ? newSVpv(fl, 0) : newSVpvf("user_flag_%d", i);
	    av_push(flags, sv);
	}
    }
    av_push(av, newRV_noinc((SV*)flags));
    av_push(av, newSViv(elt->rfc822_size)); 
    return sv_bless(newRV_noinc((SV*)av), stash_Elt);
}

static AV *
stringlist_to_av(STRINGLIST *s)
{
    AV *av = newAV();
    for (; s; s = s->next)
	av_push(av, newSVpv(s->text.data, s->text.size));
    return av;
}

static STRINGLIST *av_to_stringlist(AV *av)
{
    STRINGLIST *rets = 0;
    STRINGLIST **s = &rets;
    SV **svp = AvARRAY(av);
    I32 count;
    for (count = AvFILL(av); count >= 0; count--) {
	STRLEN len;
	*s =  mail_newstringlist();
	(*s)->text.data = cpystr(SvPV(*svp, len));
	(*s)->text.size = len;
	s = &(*s)->next;
	svp++;
    }
    return rets;
}

static AV *
push_parameter(AV *av, PARAMETER *param)
{
    for (; param; param = param->next) {
	av_push(av, newSVpv(param->attribute, 0));
	av_push(av, newSVpv(param->value, 0));
    }
    return av;
}

static SV *
make_body(BODY *body)
{
    AV *av = newAV();
    SV *nest;
    AV *paramav = newAV();

    av_push(av, SvREFCNT_inc(body_fields));
    av_push(av, newSVpv(body_types[body->type], 0));
    av_push(av, newSVpv(body_encodings[body->encoding], 0));
    av_push(av, str_to_sv(body->subtype));
    av_push(av, newRV_noinc((SV*)push_parameter(newAV(), body->parameter)));
    av_push(av, str_to_sv(body->id));
    av_push(av, str_to_sv(body->description));
    if (body->type == TYPEMULTIPART) {
	AV *parts = newAV();
	PART *p;
	for (p = body->nested.part; p; p = p->next)
	    av_push(parts, make_body(&p->body));
	nest = newRV_noinc((SV*)parts);
    }
    else if (body->type == TYPEMESSAGE && strEQ(body->subtype, "RFC822")) {
	AV *mess = newAV();
	MESSAGE *msg = body->nested.msg;
	av_push(mess, msg ? make_envelope(msg->env) : &sv_undef);
	av_push(mess, msg ? make_body(msg->body) : &sv_undef);
	nest = newRV_noinc((SV*)mess);
    }
    else {
	nest = newSVsv(&sv_undef);
    }
    av_push(av, nest);
    av_push(av, newSViv(body->size.lines));
    av_push(av, newSViv(body->size.bytes));
    av_push(av, str_to_sv(body->md5));
    av_push(paramav, str_to_sv(body->disposition.type));
    paramav = push_parameter(paramav, body->disposition.parameter);
    av_push(av, newRV_noinc((SV*)paramav));
    return sv_bless(newRV_noinc((SV*)av), stash_Body);
}

/*
 * Interfaces to C-client callbacks
 */

void mm_searched(MAILSTREAM *stream, unsigned long number)
{
    dSP;
    SV *sv = mm_callback("searched");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSViv(number)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_exists(MAILSTREAM *stream, unsigned long number)
{
    dSP;
    SV *sv = mm_callback("exists");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSViv(number)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_expunged(MAILSTREAM *stream, unsigned long number)
{
    dSP;
    SV *sv = mm_callback("expunged");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSViv(number)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_flags(MAILSTREAM *stream, unsigned long number)
{
    dSP;
    SV *sv = mm_callback("flags");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSViv(number)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_notify(MAILSTREAM *stream, char *string, long errflg)
{
    dSP;
    SV *sv = mm_callback("notify");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    XPUSHs(sv_2mortal(newSViv(errflg)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_list(MAILSTREAM *stream, int delimiter, char *mailbox, long attributes)
{
    dSP;
    char delimchar;
    SV *sv = mm_callback("list");
    if (!sv)
	return;
    delimchar = (char)delimiter;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSVpv(&delimchar, 1)));
    XPUSHs(sv_2mortal(newSVpv(mailbox, 0)));
    if (attributes & LATT_NOINFERIORS)
	XPUSHs(sv_2mortal(newSVpv("noinferiors", 0)));
    if (attributes & LATT_NOSELECT)
	XPUSHs(sv_2mortal(newSVpv("noselect", 0)));
    if (attributes & LATT_MARKED)
	XPUSHs(sv_2mortal(newSVpv("marked", 0)));
    if (attributes & LATT_UNMARKED)
	XPUSHs(sv_2mortal(newSVpv("unmarked", 0)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_lsub(MAILSTREAM *stream, int delimiter, char *mailbox, long attributes)
{
    dSP;
    SV *sv = mm_callback("lsub");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSViv(delimiter)));
    XPUSHs(sv_2mortal(newSVpv(mailbox, 0)));
    XPUSHs(sv_2mortal(newSViv(attributes)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_status(MAILSTREAM *stream, char *mailbox, MAILSTATUS *status)
{
    dSP;
    SV *sv = mm_callback("status");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSVpv(mailbox, 0)));
    if (status->flags & SA_MESSAGES) {
	XPUSHs(sv_2mortal(newSVpv("messages", 0)));
	XPUSHs(sv_2mortal(newSViv(status->messages)));
    }
    if (status->flags & SA_RECENT) {
	XPUSHs(sv_2mortal(newSVpv("recent", 0)));
	XPUSHs(sv_2mortal(newSViv(status->recent)));
    }
    if (status->flags & SA_UNSEEN) {
	XPUSHs(sv_2mortal(newSVpv("unseen", 0)));
	XPUSHs(sv_2mortal(newSViv(status->unseen)));
    }
    if (status->flags & SA_UIDVALIDITY) {
	XPUSHs(sv_2mortal(newSVpv("uidvalidity", 0)));
	XPUSHs(sv_2mortal(newSViv(status->uidvalidity)));
    }
    if (status->flags & SA_UIDNEXT) {
	XPUSHs(sv_2mortal(newSVpv("uidnext", 0)));
	XPUSHs(sv_2mortal(newSViv(status->uidnext)));
    }
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_log(char *string, long errflg)
{
    dSP;
    SV *sv = mm_callback("log");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    XPUSHs(sv_2mortal(newSVpv((
	errflg == NIL ? "info" :
	errflg == PARSE ? "parse" :
	errflg == WARN ? "warn" :
	errflg == ERROR ? "error" : "unknown"), 0)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_dlog(char *string)
{
    dSP;
    SV *sv = mm_callback("dlog");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_fatal (char *string)
{
    dSP;
    SV *sv = mm_callback("fatal");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_login(NETMBX *mb, char *user, char *password, long trial)
{
    dSP;
    SV *sv = mm_callback("login");
    HV *hv;
    SV *retsv;
    STRLEN len;
    char *str;
    I32 items;

    if (!sv)
	croak("mandatory login callback not set");
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    hv = newHV();
    hv_store(hv, "host", 4, str_to_sv(mb->host), 0);
    hv_store(hv, "user", 4, str_to_sv(mb->user), 0);
    hv_store(hv, "mailbox", 7, str_to_sv(mb->mailbox), 0);
    hv_store(hv, "service", 7, str_to_sv(mb->service), 0);
    hv_store(hv, "port", 4, newSViv(mb->port), 0);
    if (mb->anoflag)
	hv_store(hv, "anoflag", 7, newSViv(1), 0);
    if (mb->dbgflag)
	hv_store(hv, "dbgflag", 7, newSViv(1), 0);
    XPUSHs(sv_2mortal(newRV((SV*)hv)));
    SvREFCNT_dec((SV*)hv);
    XPUSHs(sv_2mortal(newSViv(trial)));
    PUTBACK;
    items = perl_call_sv(sv, G_ARRAY);
    SPAGAIN;
    if (items != 2)
	croak("login callback failed to return (user, password)");
    retsv = POPs;	/* password */
    str = SvPV(retsv, len);
    /*
     * By brief inspection (but it's not documented), c-client seems
     * to pass a buffer of size MAILTMPLEN for the user and password
     * strings so we make sure we don't copy in more than that.
     * We don't use strcnpy all the time since it pads its destination
     * with \0 characters and there may be parts of c-client that
     * don't actually pass in that large a buffer.
     */
    if (len >= MAILTMPLEN)
	strncpy(password, str, MAILTMPLEN - 1);
    else
	strcpy(password, str);
    retsv = POPs;	/* user */
    str = SvPV(retsv, len);
    if (len >= MAILTMPLEN)
	strncpy(user, str, MAILTMPLEN - 1);
    else
	strcpy(user, str);
    
    PUTBACK;
    FREETMPS;
    LEAVE;
}

void mm_critical(MAILSTREAM *stream)
{
    dSP;
    SV *sv = mm_callback("critical");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

void mm_nocritical(MAILSTREAM *stream)
{
    dSP;
    SV *sv = mm_callback("nocritical");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

long mm_diskerror(MAILSTREAM *stream, long errcode, long serious)
{
    dSP;
    SV *sv = mm_callback("diskerror");
    if (!sv)
	return;
    PUSHMARK(sp);
    XPUSHs(sv_mortalcopy(get_mailstream_sv(stream, 0)));
    XPUSHs(sv_2mortal(newSViv(errcode)));
    XPUSHs(sv_2mortal(newSViv(serious)));
    PUTBACK;
    perl_call_sv(sv, G_DISCARD);
}

MODULE = Mail::Cclient	PACKAGE = Mail::Cclient	PREFIX = mail_

PROTOTYPES: DISABLE

Mail::Cclient
mail_open(stream, mailbox, ...)
	Mail::Cclient	stream
	char *		mailbox
    PREINIT:
	int i;
	long options = 0;
    CODE:
	for (i = 2; i < items; i++) {
	    char *option = SvPV(ST(i), na);
	    if (strEQ(option, "debug"))
		options |= OP_DEBUG;
	    else if (strEQ(option, "readonly"))
		options |= OP_READONLY;
	    else if (strEQ(option, "anonymous"))
		options |= OP_ANONYMOUS;
	    else if (strEQ(option, "shortcache"))
		options |= OP_SHORTCACHE;
	    else if (strEQ(option, "silent"))
		options |= OP_SILENT;
	    else if (strEQ(option, "prototype"))
		options |= OP_PROTOTYPE;
	    else if (strEQ(option, "halfopen"))
		options |= OP_HALFOPEN;
	    else if (strEQ(option, "expunge"))
		options |= OP_EXPUNGE;
	    else {
		croak("unknown option \"%s\" passed to Mail::Cclient::open",
		      option);
	    }
	}
	if (stream)
	    hv_delete(mailstream2sv, (char*)stream, sizeof(stream), G_DISCARD);
	RETVAL = mail_open(stream, mailbox, options);
	if (!RETVAL)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL
    CLEANUP:
#ifdef PERL_CCLIENT_DEBUG
	fprintf(stderr, "storing stream %p\n", RETVAL); /*debug*/
#endif
	hv_store(mailstream2sv, (char*)&RETVAL, sizeof(RETVAL),
		 SvREFCNT_inc(ST(0)), 0);

void
mail_close(stream, ...)
	Mail::Cclient	stream
    CODE:
	hv_delete(mailstream2sv, (char*)stream, sizeof(stream), G_DISCARD);
	if (items == 1)
	    mail_close(stream);
	else {
	    long options = 0;
	    int i;
	    for (i = 1; i < items; i++) {
		char *option = SvPV(ST(i), na);
		if (strEQ(option, "expunge"))
		    options |= CL_EXPUNGE;
		else {
		    croak("unknown option \"%s\" passed to"
			  " Mail::Cclient::close", option);
		}
	    }
	    mail_close_full(stream, options);
	}



void
mail_list(stream, ref, pat)
	Mail::Cclient	stream
	char *		ref
	char *		pat

void
mail_scan(stream, ref, pat, contents)
	Mail::Cclient	stream
	char *		ref
	char *		pat
	char *		contents

void
mail_lsub(stream, ref, pat)
	Mail::Cclient	stream
	char *		ref
	char *		pat

unsigned long
mail_subscribe(stream, mailbox)
	Mail::Cclient	stream
	char *		mailbox

unsigned long
mail_unsubscribe(stream, mailbox)
	Mail::Cclient	stream
	char *		mailbox

unsigned long
mail_create(stream, mailbox)
	Mail::Cclient	stream
	char *		mailbox

unsigned long
mail_delete(stream, mailbox)
	Mail::Cclient	stream
	char *		mailbox

unsigned long
mail_rename(stream, oldname, newname)
	Mail::Cclient	stream
	char *		oldname
	char *		newname

long
mail_status(stream, mailbox, ...)
	Mail::Cclient	stream
	char *		mailbox
    PREINIT:
	int i;
	long flags = 0;
    CODE:
	for (i = 2; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "messages"))
		flags |= SA_MESSAGES;
	    else if (strEQ(flag, "recent"))
		flags |= SA_RECENT;
	    else if (strEQ(flag, "unseen"))
		flags |= SA_UNSEEN;
	    else if (strEQ(flag, "uidnext"))
		flags |= SA_UIDNEXT;
	    else if (strEQ(flag, "uidvalidity"))
		flags |= SA_UIDVALIDITY;
	    else {
		croak("unknown flag \"%s\" passed to Mail::Cclient::status",
		      flag);
	    }
	}
	RETVAL = mail_status(stream, mailbox, flags);
    OUTPUT:
	RETVAL


MODULE = Mail::Cclient	PACKAGE = Mail::Cclient	PREFIX = mailstream_

#define mailstream_mailbox(stream) stream->mailbox
#define mailstream_use(stream) stream->use
#define mailstream_sequence(stream) stream->sequence
#define mailstream_rdonly(stream) stream->rdonly
#define mailstream_anonymous(stream) stream->anonymous
#define mailstream_halfopen(stream) stream->halfopen
#define mailstream_perm_seen(stream) stream->perm_seen
#define mailstream_perm_deleted(stream) stream->perm_deleted
#define mailstream_perm_flagged(stream) stream->perm_flagged
#define mailstream_perm_answered(stream) stream->perm_answered
#define mailstream_perm_draft(stream) stream->perm_draft
#define mailstream_kwd_create(stream) stream->kwd_create
#define mailstream_nmsgs(stream) stream->nmsgs
#define mailstream_recent(stream) stream->recent
#define mailstream_uid_validity(stream) stream->uid_validity
#define mailstream_uid_last(stream) stream->uid_last

char *
mailstream_mailbox(stream)
	Mail::Cclient	stream

unsigned short
mailstream_use(stream)
	Mail::Cclient stream

unsigned short
mailstream_sequence(stream)
	Mail::Cclient stream

unsigned int
mailstream_rdonly(stream)
	Mail::Cclient stream

unsigned int
mailstream_anonymous(stream)
	Mail::Cclient stream

unsigned int
mailstream_halfopen(stream)
	Mail::Cclient stream

unsigned int
mailstream_perm_seen(stream)
	Mail::Cclient stream

unsigned int
mailstream_perm_deleted(stream)
	Mail::Cclient stream

unsigned int
mailstream_perm_flagged(stream)
	Mail::Cclient stream

unsigned int
mailstream_perm_answered(stream)
	Mail::Cclient stream

unsigned int
mailstream_perm_draft(stream)
	Mail::Cclient stream

unsigned int
mailstream_kwd_create(stream)
	Mail::Cclient stream

unsigned long
mailstream_nmsgs(stream)
	Mail::Cclient stream

unsigned long
mailstream_recent(stream)
	Mail::Cclient stream

unsigned long
mailstream_uid_validity(stream)
	Mail::Cclient stream

unsigned long
mailstream_uid_last(stream)
	Mail::Cclient stream

void
mailstream_perm_user_flags(stream)
	Mail::Cclient stream
    PREINIT:
	int i;
    PPCODE:
	for (i = 0; i < NUSERFLAGS; i++)
	    if (stream->perm_user_flags & (1 << i))
		XPUSHs(sv_2mortal(newSVpv(stream->user_flags[i], 0)));

MODULE = Mail::Cclient	PACKAGE = Mail::Cclient	PREFIX = mail_

 #
 # Message Data Fetching Functions
 #

void
mail_fetchfast(stream, sequence, ...)
	Mail::Cclient	stream
	char *		sequence
    PREINIT:
	int i;
	long flags = 0;
    PPCODE:
	for (i = 2; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "uid"))
		flags |= FT_UID;
	    else {
		croak("unknown flag \"%s\" passed to Mail::Cclient::fetchfast",
		      flag);
	    }
	}
	mail_fetchfast_full(stream, sequence, flags);
	ST(0) = &sv_yes;

void
mail_fetchflags(stream, sequence, ...)
	Mail::Cclient	stream
	char *		sequence
    PREINIT:
	int i;
	long flags = 0;
    PPCODE:
	for (i = 2; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "uid"))
		flags |= FT_UID;
	    else {
		croak("unknown flag \"%s\" passed to"
		      " Mail::Cclient::fetchflags", flag);
	    }
	}
	mail_fetchflags_full(stream, sequence, flags);
	ST(0) = &sv_yes;

void
mail_fetchstructure(stream, msgno, ...)
	Mail::Cclient	stream
	unsigned long	msgno
    PREINIT:
	int i;
	long flags = 0;
	ENVELOPE *e;
	BODY **bodyp = 0;
	BODY *body = 0;
    PPCODE:
	for (i = 2; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "uid"))
		flags |= FT_UID;
	    else {
		croak("unknown flag \"%s\" passed to"
		      " Mail::Cclient::fetchstructure", flag);
	    }
	}
	if (GIMME == G_ARRAY)
	    bodyp = &body;
	e = mail_fetchstructure_full(stream, msgno, bodyp, flags);
	XPUSHs(sv_2mortal(make_envelope(e)));
	if (GIMME == G_ARRAY)
	    XPUSHs(sv_2mortal(make_body(body)));

void
mail_fetchheader(stream, msgno, ...)
	Mail::Cclient	stream
	unsigned long	msgno
    PREINIT:
	int i;
	long flags = 0;
	STRINGLIST *lines = 0;
	unsigned long len;
	char *hdr;
    PPCODE:
	for (i = 2; i < items; i++) {
	    SV *sv = ST(i);
	    if (SvROK(sv)) {
		sv = (SV*)SvRV(sv);
		if (SvTYPE(sv) != SVt_PVAV) {
		    croak("reference to non-list passed to"
			  " Mail::Cclient::fetchheader");
		}
		lines = av_to_stringlist((AV*)sv);
	    }
	    else {
		char *flag = SvPV(sv, na);
		if (strEQ(flag, "uid"))
		    flags |= FT_UID;
		else if (strEQ(flag, "not"))
		    flags |= FT_NOT;
		else if (strEQ(flag, "internal"))
		    flags |= FT_INTERNAL;
		else if (strEQ(flag, "prefetchtext"))
		    flags |= FT_PREFETCHTEXT;
		else {
		    croak("unknown flag \"%s\" passed to"
			  " Mail::Cclient::fetchheader", flag);
		}
	    }
	}
	hdr = mail_fetchheader_full(stream, msgno, lines, &len, flags);
	XPUSHs(sv_2mortal(newSVpv(hdr, len)));
	if (lines)
	    mail_free_stringlist(&lines);

void
mail_fetchtext(stream, msgno, ...)
	Mail::Cclient	stream
	unsigned long	msgno
    PREINIT:
	int i;
	long flags = 0;
	unsigned long len;
	char *text;
    PPCODE:
	for (i = 2; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "uid"))
		flags |= FT_UID;
	    else if (strEQ(flag, "peek"))
		flags |= FT_NOT;
	    else if (strEQ(flag, "internal"))
		flags |= FT_INTERNAL;
	    else {
		croak("unknown flag \"%s\" passed to"
		      " Mail::Cclient::fetchtext", flag);
	    }
	}
	text = mail_fetchtext_full(stream, msgno, &len, flags);
	XPUSHs(sv_2mortal(newSVpv(text, len)));

void
mail_fetchbody(stream, msgno, section, ...)
	Mail::Cclient	stream
	unsigned long	msgno
	char *		section
    PREINIT:
	int i;
	long flags = 0;
	unsigned long len;
	char *body;
    PPCODE:
	for (i = 3; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "uid"))
		flags |= FT_UID;
	    else if (strEQ(flag, "peek"))
		flags |= FT_NOT;
	    else if (strEQ(flag, "internal"))
		flags |= FT_INTERNAL;
	    else {
		croak("unknown flag \"%s\" passed to Mail::Cclient::fetchbody",
		      flag);
	    }
	}
	body = mail_fetchbody_full(stream, msgno, section, &len, flags);
	XPUSHs(sv_2mortal(newSVpv(body, len)));

unsigned long
mail_uid(stream, msgno)
	Mail::Cclient	stream
	unsigned long	msgno

void
mail_elt(stream, msgno)
	Mail::Cclient	stream
	unsigned long	msgno
    PREINIT:
	MESSAGECACHE *elt;
    PPCODE:
	elt = mail_elt(stream, msgno);
	XPUSHs(elt ? sv_2mortal(make_elt(stream, elt)) : &sv_undef);

 #
 # Message Status Manipulation Functions
 #

void
mail_setflag(stream, sequence, flag, ...)
	Mail::Cclient	stream
	char *		sequence
	char *		flag
    PREINIT:
	int i;
	long flags = 0;
    ALIAS:
	clearflag = 1
    CODE:
	for (i = 3; i < items; i++) {
	    char *fl = SvPV(ST(i), na);
	    if (strEQ(fl, "uid"))
		flags |= ST_UID;
	    else if (strEQ(fl, "silent"))
		flags |= ST_SILENT;
	    else {
		croak("unknown flag \"%s\" passed to Mail::Cclient::%s",
		      fl, ix == 1 ? "setflag" : "clearflag");
	    }
	}
	if (ix == 1)
	    mail_clearflag_full(stream, sequence, flag, flags);
	else
	    mail_setflag_full(stream, sequence, flag, flags);


 #
 # Miscellaneous Mailbox and Message Functions
 #

long
mail_ping(stream)
	Mail::Cclient	stream

void
mail_check(stream)
	Mail::Cclient	stream

void
mail_expunge(stream)
	Mail::Cclient	stream

long
mail_copy(stream, sequence, mailbox, ...)
	Mail::Cclient	stream
	char *		sequence
	char *		mailbox
    ALIAS:
	move = 1
    PREINIT:
	int i;
	long flags = 0;
    CODE:
	for (i = 3; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "uid"))
		flags |= CP_UID;
	    else if (strEQ(flag, "move"))
		flags |= CP_MOVE;
	    else {
		croak("unknown flag \"%s\" passed to Mail::Cclient::%s",
		      flag, ix == 1 ? "move" : "copy");
	    }
	}
	if (ix == 1)
	    flags |= CP_MOVE;
	RETVAL = mail_copy_full(stream, sequence, mailbox, flags);
    OUTPUT:
	RETVAL

 #
 # mail_append slightly tweaked from code submitted by
 # Kevin Sullivan <ksulliva@kludge.psc.edu>.
 #

long
mail_append(stream, mailbox, message, date = 0, flags = 0)
	Mail::Cclient	stream
	char *		mailbox
	SV *		message
	char *		date
	char *		flags
    PREINIT:
	STRING s;
	char *str;
	STRLEN len;
    CODE:
	str = SvPV(message, len);
	CCLIENT_LOCAL_INIT(&s, mail_string, (void *)str, len);
	RETVAL = mail_append_full(stream, mailbox, date, flags, &s);
     OUTPUT:
	RETVAL

void
mail_search(stream, criteria)
	Mail::Cclient	stream
	char *		criteria

void
mail_real_gc(stream, ...)
	Mail::Cclient	stream
    PREINIT:
	int i;
	long flags = 0;
    CODE:
	for (i = 1; i < items; i++) {
	    char *flag = SvPV(ST(i), na);
	    if (strEQ(flag, "elt"))
		flags |= GC_ELT;
	    else if (strEQ(flag, "env"))
		flags |= GC_ENV;
	    else if (strEQ(flag, "texts"))
		flags |= GC_TEXTS;
	    else
		croak("unknown flag \"%s\" passed to Mail::Cclient::gc", flag);
	}
	mail_gc(stream, flags);

 #
 # This is _parameters which handles a single extra argument (equivalent
 # to GET_FOO) or two extra arguments (equivalent to SET_FOO). The
 # "parameters" method in Cclient.pm handles multiple pairs of arguments
 # for SET_.
 #

void
mail__parameters(stream, param, sv = 0)
	Mail::Cclient	stream
	char *		param
	SV *		sv
    PREINIT:
	char *res_str = 0;
	int res_int;
    CODE:
	if (strEQ(param, "USERNAME")) {
	    if (sv)
		mail_parameters(stream, SET_USERNAME, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_USERNAME, 0);
	} else if (strEQ(param, "HOMEDIR")) {
	    if (sv)
		mail_parameters(stream, SET_HOMEDIR, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_HOMEDIR, 0);
	} else if (strEQ(param, "LOCALHOST")) {
	    if (sv)
		mail_parameters(stream, SET_LOCALHOST, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_LOCALHOST, 0);
	} else if (strEQ(param, "SYSINBOX")) {
	    if (sv)
		mail_parameters(stream, SET_SYSINBOX, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_SYSINBOX, 0);
	} else if (strEQ(param, "NEWSACTIVE")) {
	    if (sv)
		mail_parameters(stream, SET_NEWSACTIVE, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_NEWSACTIVE, 0);
	} else if (strEQ(param, "NEWSSPOOL")) {
	    if (sv)
		mail_parameters(stream, SET_NEWSSPOOL, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_NEWSSPOOL, 0);
	} else if (strEQ(param, "NEWSRC")) {
	    if (sv)
		mail_parameters(stream, SET_NEWSRC, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_NEWSRC, 0);
	} else if (strEQ(param, "ANONYMOUSHOME")) {
	    if (sv)
		mail_parameters(stream, SET_ANONYMOUSHOME, SvPV(sv, na));
	    else
		res_str = mail_parameters(stream, GET_ANONYMOUSHOME, 0);
	} else if (strEQ(param, "OPENTIMEOUT")) {
	    if (sv)
		mail_parameters(stream, SET_OPENTIMEOUT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_OPENTIMEOUT, 0);
	} else if (strEQ(param, "READTIMEOUT")) {
	    if (sv)
		mail_parameters(stream, SET_READTIMEOUT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_READTIMEOUT, 0);
	} else if (strEQ(param, "WRITETIMEOUT")) {
	    if (sv)
		mail_parameters(stream, SET_WRITETIMEOUT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_WRITETIMEOUT, 0);
	} else if (strEQ(param, "CLOSETIMEOUT")) {
	    if (sv)
		mail_parameters(stream, SET_CLOSETIMEOUT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_CLOSETIMEOUT, 0);
	} else if (strEQ(param, "RSHTIMEOUT")) {
	    if (sv)
		mail_parameters(stream, SET_RSHTIMEOUT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_RSHTIMEOUT, 0);
	} else if (strEQ(param, "MAXLOGINTRIALS")) {
	    if (sv)
		mail_parameters(stream, SET_MAXLOGINTRIALS, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_MAXLOGINTRIALS, 0);
	} else if (strEQ(param, "LOOKAHEAD")) {
	    if (sv)
		mail_parameters(stream, SET_LOOKAHEAD, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_LOOKAHEAD, 0);
	} else if (strEQ(param, "IMAPPORT")) {
	    if (sv)
		mail_parameters(stream, SET_IMAPPORT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_IMAPPORT, 0);
	} else if (strEQ(param, "PREFETCH")) {
	    if (sv)
		mail_parameters(stream, SET_PREFETCH, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_PREFETCH, 0);
	} else if (strEQ(param, "CLOSEONERROR")) {
	    if (sv)
		mail_parameters(stream, SET_CLOSEONERROR, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_CLOSEONERROR, 0);
	} else if (strEQ(param, "POP3PORT")) {
	    if (sv)
		mail_parameters(stream, SET_POP3PORT, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_POP3PORT, 0);
	} else if (strEQ(param, "UIDLOOKAHEAD")) {
	    if (sv)
		mail_parameters(stream, SET_UIDLOOKAHEAD, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_UIDLOOKAHEAD, 0);
	} else if (strEQ(param, "MBXPROTECTION")) {
	    if (sv)
		mail_parameters(stream, SET_MBXPROTECTION, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_MBXPROTECTION, 0);
	} else if (strEQ(param, "DIRPROTECTION")) {
	    if (sv)
		mail_parameters(stream, SET_DIRPROTECTION, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_DIRPROTECTION, 0);
	} else if (strEQ(param, "LOCKPROTECTION")) {
	    if (sv)
		mail_parameters(stream, SET_LOCKPROTECTION, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_LOCKPROTECTION, 0);
	} else if (strEQ(param, "FROMWIDGET")) {
	    if (sv)
		mail_parameters(stream, SET_FROMWIDGET, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_FROMWIDGET, 0);
	} else if (strEQ(param, "DISABLEFCNTLLOCK")) {
	    if (sv)
		mail_parameters(stream, SET_DISABLEFCNTLLOCK, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_DISABLEFCNTLLOCK, 0);
	} else if (strEQ(param, "LOCKEACCESERROR")) {
	    if (sv)
		mail_parameters(stream, SET_LOCKEACCESERROR, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_LOCKEACCESERROR, 0);
	} else if (strEQ(param, "LISTMAXLEVEL")) {
	    if (sv)
		mail_parameters(stream, SET_LISTMAXLEVEL, (void*)SvIV(sv));
	    else
		res_int = (int) mail_parameters(stream, GET_LISTMAXLEVEL, 0);
	} else {
	    croak("no such parameter name: %s", param);
	}
	if (sv)
	    ST(0) = &sv_yes;
	else {
	    if (res_str)
		XPUSHs(sv_2mortal(newSVpv(res_str, 0)));
	    else
		XPUSHs(sv_2mortal(newSViv(res_int)));
	}

 #
 # Utility Functions
 #

void
mail_debug(stream)
	Mail::Cclient	stream

void
mail_nodebug(stream)
	Mail::Cclient	stream

#define mail_set_sequence(stream, seq) mail_sequence(stream, seq)

long
mail_set_sequence(stream, sequence)
	Mail::Cclient	stream
	char *		sequence

#define mail_uid_set_sequence(stream, seq) mail_uid_sequence(stream, seq)

long
mail_uid_set_sequence(stream, sequence)
	Mail::Cclient	stream
	char *		sequence

MODULE = Mail::Cclient	PACKAGE = Mail::Cclient

 #
 # MIME type conversion functions
 #

void
rfc822_base64(source)
	SV *	source
    PREINIT:
	STRLEN srcl;
	unsigned long len;
	unsigned char *s;
    PPCODE:
	s = (unsigned char*)SvPV(source, srcl);
	s = rfc822_base64(s, (unsigned long)srcl, &len);
	XPUSHs(sv_2mortal(newSVpv((char*)s, (STRLEN)len)));

void
rfc822_qprint(source)
	SV *	source
    PREINIT:
	STRLEN srcl;
	unsigned long len;
	unsigned char *s;
    PPCODE:
	s = (unsigned char*)SvPV(source, srcl);
	s = rfc822_qprint(s, (unsigned long)srcl, &len);
	XPUSHs(sv_2mortal(newSVpv((char*)s, (STRLEN)len)));


 #
 # Utility functions
 #

#define DATE_BUFF_SIZE 64

char *
rfc822_date()
    PREINIT:
	static char date[DATE_BUFF_SIZE];
    CODE:
	rfc822_date(date);
	RETVAL = date;
    OUTPUT:
	RETVAL

BOOT:
#include "linkage.c"
	mailstream2sv = newHV();
	stash_Cclient = gv_stashpv("Mail::Cclient", TRUE);
	stash_Address = gv_stashpv("Mail::Cclient::Address", TRUE);
	stash_Envelope = gv_stashpv("Mail::Cclient::Envelope", TRUE);
	stash_Body = gv_stashpv("Mail::Cclient::Body", TRUE);
	stash_Elt = gv_stashpv("Mail::Cclient::Elt", TRUE);
	callback = perl_get_hv("Mail::Cclient::_callback", TRUE);
	address_fields = newRV((SV*)perl_get_hv("Mail::Cclient::"
						"Address::FIELDS", TRUE));
	envelope_fields = newRV((SV*)perl_get_hv("Mail::Cclient::"
						 "Envelope::FIELDS", TRUE));
	body_fields = newRV((SV*)perl_get_hv("Mail::Cclient::Body::FIELDS",
					     TRUE));
	elt_fields = newRV((SV*)perl_get_hv("Mail::Cclient::Elt::FIELDS",
					    TRUE));
