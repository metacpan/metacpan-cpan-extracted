/* Copyright (c) 2015-2018 by Pali <pali@cpan.org> */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dovecot-parser.h"

/* Perl pre 5.6.1 support */
#if PERL_VERSION < 6 || (PERL_VERSION == 6 && PERL_SUBVERSION < 1)
#define BROKEN_SvPVutf8
#endif

/* Perl pre 5.7.2 support */
#ifndef SvPV_nomg
#define WITHOUT_SvPV_nomg
#endif

/* Perl pre 5.8.0 support */
#ifndef UTF8_IS_INVARIANT
#define UTF8_IS_INVARIANT(c) (((U8)c) < 0x80)
#endif

/* Perl pre 5.9.5 support */
#ifndef SVfARG
#define SVfARG(p) ((void*)(p))
#endif

/* Perl pre 5.13.1 support */
#ifndef warn_sv
#define warn_sv(scalar) warn("%" SVf, SVfARG(scalar))
#endif
#ifndef croak_sv
#define croak_sv(scalar) croak("%" SVf, SVfARG(scalar))
#endif

/* Perl pre 5.15.4 support */
#ifndef sv_derived_from_pvn
#define sv_derived_from_pvn(scalar, name, len, flags) sv_derived_from(scalar, name)
#endif

/* Exported i_panic function for other C files */
void i_panic(const char *format, ...)
{
	dTHX;
	va_list args;

	va_start(args, format);
	vcroak(format, &args);
	va_end(args);
}

static void append_carp_shortmess(pTHX_ SV *scalar)
{
	dSP;
	int count;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	count = call_pv("Carp::shortmess", G_SCALAR);

	SPAGAIN;

	if (count > 0)
		sv_catsv(scalar, POPs);

	PUTBACK;
	FREETMPS;
	LEAVE;
}

#define CARP_WARN false
#define CARP_DIE true
static void carp(bool fatal, const char *format, ...)
{
	dTHX;
	va_list args;
	SV *scalar;

	va_start(args, format);
	scalar = sv_2mortal(vnewSVpvf(format, &args));
	va_end(args);

	append_carp_shortmess(aTHX_ scalar);

	if (!fatal)
		warn_sv(scalar);
	else
		croak_sv(scalar);
}

static bool string_needs_utf8_upgrade(const char *str, STRLEN len)
{
	STRLEN i;

	for (i = 0; i < len; ++i)
		if (!UTF8_IS_INVARIANT(str[i]))
			return true;

	return false;
}

static const char *get_perl_scalar_value(pTHX_ SV *scalar, STRLEN *len, bool utf8, bool nomg)
{
	const char *string;

#ifndef WITHOUT_SvPV_nomg
	if (!nomg)
		SvGETMAGIC(scalar);

	if (!SvOK(scalar))
		return NULL;

	string = SvPV_nomg(scalar, *len);
#else
	COP cop;

	if (!SvGMAGICAL(scalar) && !SvOK(scalar))
		return NULL;

	/* Temporary turn off all warnings because SvPV can throw uninitialized warning */
	cop = *PL_curcop;
	cop.cop_warnings = pWARN_NONE;

	ENTER;
	SAVEVPTR(PL_curcop);
	PL_curcop = &cop;

	string = SvPV(scalar, *len);

	LEAVE;

	if (SvGMAGICAL(scalar) && !SvOK(scalar))
		return NULL;
#endif

	if (utf8 && !SvUTF8(scalar) && string_needs_utf8_upgrade(string, *len)) {
		scalar = sv_2mortal(newSVpvn(string, *len));
#ifdef BROKEN_SvPVutf8
		sv_utf8_upgrade(scalar);
		*len = SvCUR(scalar);
		return SvPVX(scalar);
#else
		return SvPVutf8(scalar, *len);
#endif
	}

	return string;
}

static const char *get_perl_scalar_string_value(pTHX_ SV *scalar, STRLEN *len, const char *name, bool utf8)
{
	const char *string;

	string = get_perl_scalar_value(aTHX_ scalar, len, utf8, false);
	if (!string) {
		carp(CARP_WARN, "Use of uninitialized value for %s", name);
		*len = 0;
		return "";
	}

	return string;
}

static SV *get_perl_hash_scalar(pTHX_ HV *hash, const char *key)
{
	I32 klen;
	SV **scalar_ptr;

	klen = strlen(key);

	if (!hv_exists(hash, key, klen))
		return NULL;

	scalar_ptr = hv_fetch(hash, key, klen, 0);
	if (!scalar_ptr)
		return NULL;

	return *scalar_ptr;
}

static const char *get_perl_hash_value(pTHX_ HV *hash, const char *key, STRLEN *len, bool utf8, bool *taint)
{
	SV *scalar;

	scalar = get_perl_hash_scalar(aTHX_ hash, key);
	if (!scalar)
		return NULL;

	if (!*taint && SvTAINTED(scalar))
		*taint = true;

	return get_perl_scalar_value(aTHX_ scalar, len, utf8, true);
}

static void set_perl_hash_value(pTHX_ HV *hash, const char *key, const char *value, STRLEN len, bool utf8, bool taint)
{
	I32 klen;
	SV *scalar;

	klen = strlen(key);

	if (!len && value && value[0])
		value = NULL;

	if (value)
		scalar = newSVpvn(value, len);
	else
		scalar = newSV(0);

	if (utf8 && value)
		sv_utf8_decode(scalar);

	if (taint)
		SvTAINTED_on(scalar);

	(void)hv_store(hash, key, klen, scalar, 0);
}

static HV *get_perl_class_from_perl_cv(pTHX_ CV *cv)
{
	GV *gv;
	HV *class;

	class = NULL;
	gv = CvGV(cv);

	if (gv)
		class = GvSTASH(gv);

	if (!class)
		class = CvSTASH(cv);

	if (!class)
		class = PL_curstash;

	if (!class)
		carp(CARP_DIE, "Cannot retrieve class");

	return class;
}

static HV *get_perl_class_from_perl_scalar(pTHX_ SV *scalar)
{
	HV *class;
	STRLEN class_len;
	const char *class_name;

	class_name = get_perl_scalar_string_value(aTHX_ scalar, &class_len, "class", true);

	if (class_len == 0) {
		carp(CARP_WARN, "Explicit blessing to '' (assuming package main)");
		class_name = "main";
		class_len = strlen(class_name);
	}

	class = gv_stashpvn(class_name, class_len, GV_ADD | SVf_UTF8);
	if (!class)
		carp(CARP_DIE, "Cannot retrieve class %" SVf, SVfARG(scalar));

	return class;
}

static HV *get_perl_class_from_perl_scalar_or_cv(pTHX_ SV *scalar, CV *cv)
{
	if (scalar)
		return get_perl_class_from_perl_scalar(aTHX_ scalar);
	else
		return get_perl_class_from_perl_cv(aTHX_ cv);
}

static bool is_class_object(pTHX_ SV *class, const char *class_name, STRLEN class_len, SV *object)
{
	dSP;
	SV *sv;
	bool ret;
	int count;

	if (!sv_isobject(object))
		return false;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 2);

	if (class) {
		sv = newSVsv(class);
	} else {
		sv = newSVpvn(class_name, class_len);
		SvUTF8_on(sv);
	}

	PUSHs(sv_2mortal(newSVsv(object)));
	PUSHs(sv_2mortal(sv));

	PUTBACK;

	count = call_method("isa", G_SCALAR);

	SPAGAIN;

	if (count > 0) {
		sv = POPs;
		ret = SvTRUE(sv);
	} else {
		ret = false;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

static void fill_element_message(char *buffer, size_t len, I32 index1, I32 index2)
{
	static const char message[] = "Element at index ";

	if (len < 10 || buffer[0])
		return;

	if (len+10+1+10 < sizeof(message)) {
		buffer[0] = 0;
		return;
	}

	if (index2 == -1) {
		strcpy(buffer, "Argument");
		return;
	}

	memcpy(buffer, message, sizeof(message));

	if (index1 == -1)
		sprintf(buffer+sizeof(message)-1, "%d", (int)index2);
	else
		sprintf(buffer+sizeof(message)-1, "%d/%d", (int)index1, (int)index2);
}

static HV* get_object_hash_from_perl_array(pTHX_ AV *array, I32 index1, I32 index2, const char *class_name, STRLEN class_len, bool warn)
{
	SV *scalar;
	SV *object;
	SV **object_ptr;
	char buffer[40] = { 0 };

#ifdef WITHOUT_SvPV_nomg
	warn = true;
#endif

	object_ptr = av_fetch(array, (index2 == -1 ? 0 : index2), 0);
	if (!object_ptr) {
		if (warn) {
			fill_element_message(buffer, sizeof(buffer), index1, index2);
			carp(CARP_WARN, "%s is NULL", buffer);
		}
		return NULL;
	}

	object = *object_ptr;
	if (!is_class_object(aTHX_ NULL, class_name, class_len, object)) {
		if (warn) {
			fill_element_message(buffer, sizeof(buffer), index1, index2);
			carp(CARP_WARN, "%s is not %s object", buffer, class_name);
		}
		return NULL;
	}

	scalar = SvRV(object);
	if (SvTYPE(scalar) != SVt_PVHV) {
		if (warn) {
			fill_element_message(buffer, sizeof(buffer), index1, index2);
			carp(CARP_WARN, "%s is not HASH reference", buffer);
		}
		return NULL;
	}

	return (HV *)scalar;

}

static void message_address_add_from_perl_array(pTHX_ struct message_address **first_address, struct message_address **last_address, bool utf8, bool *taint, AV *array, I32 index1, I32 index2, const char *class_name, STRLEN class_len)
{
	HV *hash;
	const char *name;
	const char *mailbox;
	const char *domain;
	const char *comment;
	STRLEN name_len;
	STRLEN mailbox_len;
	STRLEN domain_len;
	STRLEN comment_len;
	char buffer[40] = { 0 };

	hash = get_object_hash_from_perl_array(aTHX_ array, index1, index2, class_name, class_len, false);
	if (!hash)
		return;

	name = get_perl_hash_value(aTHX_ hash, "phrase", &name_len, utf8, taint);
	mailbox = get_perl_hash_value(aTHX_ hash, "user", &mailbox_len, utf8, taint);
	domain = get_perl_hash_value(aTHX_ hash, "host", &domain_len, utf8, taint);
	comment = get_perl_hash_value(aTHX_ hash, "comment", &comment_len, utf8, taint);

	if (mailbox && !mailbox[0] && mailbox_len == 0)
		mailbox = NULL;

	if (domain && !domain[0] && domain_len == 0)
		domain = NULL;

	if (!mailbox && !domain) {
		fill_element_message(buffer, sizeof(buffer), index1, index2);
		carp(CARP_WARN, "%s contains empty address", buffer);
		return;
	}

	if (!mailbox) {
		fill_element_message(buffer, sizeof(buffer), index1, index2);
		carp(CARP_WARN, "%s contains empty user portion of address", buffer);
		return;
	}

	if (!domain) {
		fill_element_message(buffer, sizeof(buffer), index1, index2);
		carp(CARP_WARN, "%s contains empty host portion of address", buffer);
		return;
	}

	message_address_add(first_address, last_address, name, name_len, NULL, 0, mailbox, mailbox_len, domain, domain_len, comment, comment_len);
}

static AV *get_perl_array_from_scalar(SV *scalar, const char *group_name, bool warn)
{
	SV *scalar_ref;

#ifdef WITHOUT_SvPV_nomg
	warn = true;
#endif

	if (scalar && !SvROK(scalar)) {
		if (warn)
			carp(CARP_WARN, "Value for group '%s' is not reference", group_name);
		return NULL;
	}

	scalar_ref = SvRV(scalar);

	if (!scalar_ref || SvTYPE(scalar_ref) != SVt_PVAV) {
		if (warn)
			carp(CARP_WARN, "Value for group '%s' is not ARRAY reference", group_name);
		return NULL;
	}

	return (AV *)scalar_ref;
}

static void message_address_add_from_perl_group(pTHX_ struct message_address **first_address, struct message_address **last_address, bool utf8, bool *taint, SV *scalar_group, SV *scalar_list, I32 index1, const char *class_name, STRLEN class_len)
{
	I32 len;
	I32 index2;
	AV *array;
	STRLEN group_len;
	const char *group_name;

	group_name = get_perl_scalar_value(aTHX_ scalar_group, &group_len, utf8, true);
	array = get_perl_array_from_scalar(scalar_list, group_name, false);
	len = array ? (av_len(array) + 1) : 0;

	if (index1 == -1 && group_name)
		index1 = 0;

	if (group_name)
		message_address_add(first_address, last_address, NULL, 0, NULL, 0, group_name, group_len, NULL, 0, NULL, 0);

	for (index2 = 0; index2 < len; ++index2)
		message_address_add_from_perl_array(aTHX_ first_address, last_address, utf8, taint, array, index1, ((index1 == -1 && len == 1) ? -1 : index2), class_name, class_len);

	if (group_name)
		message_address_add(first_address, last_address, NULL, 0, NULL, 0, NULL, 0, NULL, 0, NULL, 0);

	if (!*taint && SvTAINTED(scalar_group))
		*taint = true;
}

#ifndef WITHOUT_SvPV_nomg
static bool perl_group_needs_utf8(pTHX_ SV *scalar_group, SV *scalar_list, I32 index1, const char *class_name, STRLEN class_len)
{
	I32 len;
	I32 index2;
	SV *scalar;
	HV *hash;
	AV *array;
	STRLEN len_na;
	bool utf8;
	const char *group_name;
	const char **hash_key_ptr;

	static const char *hash_keys[] = { "phrase", "user", "host", "comment", NULL };

	utf8 = false;

	group_name = get_perl_scalar_value(aTHX_ scalar_group, &len_na, false, false);
	if (SvUTF8(scalar_group))
		utf8 = true;

	if (index1 == -1 && group_name)
		index1 = 0;

	array = get_perl_array_from_scalar(scalar_list, group_name, true);
	len = array ? (av_len(array) + 1) : 0;

	for (index2 = 0; index2 < len; ++index2) {
		hash = get_object_hash_from_perl_array(aTHX_ array, index1, ((index1 == -1 && len == 1) ? -1 : index2), class_name, class_len, true);
		if (!hash)
			continue;
		for (hash_key_ptr = hash_keys; *hash_key_ptr; ++hash_key_ptr) {
			scalar = get_perl_hash_scalar(aTHX_ hash, *hash_key_ptr);
			if (scalar && get_perl_scalar_value(aTHX_ scalar, &len_na, false, false) && SvUTF8(scalar))
				utf8 = true;
		}
	}

	return utf8;
}
#endif

static int count_address_groups(struct message_address *first_address)
{
	int count;
	bool in_group;
	struct message_address *address;

	count = 0;
	in_group = false;

	for (address = first_address; address; address = address->next) {
		if (!address->domain)
			in_group = !in_group;
		if (in_group)
			continue;
		++count;
	}

	return count;
}

static bool get_next_perl_address_group(pTHX_ struct message_address **address, SV **group_scalar, SV **addresses_scalar, HV *class, bool utf8, bool taint)
{
	HV *hash;
	SV *object;
	SV *hash_ref;
	bool in_group;
	AV *addresses_array;

	if (!*address)
		return false;

	in_group = !(*address)->domain;

	if (in_group && (*address)->mailbox)
		*group_scalar = sv_2mortal(newSVpvn((*address)->mailbox, (*address)->mailbox_len));
	else
		*group_scalar = sv_newmortal();

	if (utf8 && in_group && (*address)->mailbox)
		sv_utf8_decode(*group_scalar);

	if (taint)
		SvTAINTED_on(*group_scalar);

	addresses_array = newAV();
	*addresses_scalar = sv_2mortal(newRV_noinc((SV *)addresses_array));

	if (in_group)
		*address = (*address)->next;

	while (*address && (*address)->domain) {
		hash = newHV();

		set_perl_hash_value(aTHX_ hash, "phrase", (*address)->name, (*address)->name_len, utf8, taint);
		set_perl_hash_value(aTHX_ hash, "user", ( (*address)->mailbox && (*address)->mailbox[0] ) ? (*address)->mailbox : NULL, (*address)->mailbox_len, utf8, taint);
		set_perl_hash_value(aTHX_ hash, "host", ( (*address)->domain && (*address)->domain[0] ) ? (*address)->domain : NULL, (*address)->domain_len, utf8, taint);
		set_perl_hash_value(aTHX_ hash, "comment", (*address)->comment, (*address)->comment_len, utf8, taint);
		set_perl_hash_value(aTHX_ hash, "original", (*address)->original, (*address)->original_len, utf8, taint);

		if ((*address)->invalid_syntax)
			(void)hv_store(hash, "invalid", sizeof("invalid")-1, newSViv(1), 0);

		hash_ref = newRV_noinc((SV *)hash);
		object = sv_bless(hash_ref, class);

		av_push(addresses_array, object);

		*address = (*address)->next;
	}

	if (in_group && *address)
		*address = (*address)->next;

	return true;
}


MODULE = Email::Address::XS		PACKAGE = Email::Address::XS		

PROTOTYPES: DISABLE

void
format_email_groups(...)
PREINIT:
	I32 i;
	bool utf8;
	bool taint;
	char *string;
	size_t string_len;
	struct message_address *first_address;
	struct message_address *last_address;
	SV *string_scalar;
INPUT:
	const char *this_class_name = "$Package";
	STRLEN this_class_len = sizeof("$Package")-1;
INIT:
	if (items % 2 == 1) {
		carp(CARP_WARN, "Odd number of elements in argument list");
		XSRETURN_UNDEF;
	}
PPCODE:
	first_address = NULL;
	last_address = NULL;
	taint = false;
#ifndef WITHOUT_SvPV_nomg
	utf8 = false;
	for (i = 0; i < items; i += 2)
		if (perl_group_needs_utf8(aTHX_ ST(i), ST(i+1), (items == 2 ? -1 : i), this_class_name, this_class_len))
			utf8 = true;
#else
	utf8 = true;
#endif
	for (i = 0; i < items; i += 2)
		message_address_add_from_perl_group(aTHX_ &first_address, &last_address, utf8, &taint, ST(i), ST(i+1), (items == 2 ? -1 : i), this_class_name, this_class_len);
	message_address_write(&string, &string_len, first_address);
	message_address_free(&first_address);
	string_scalar = sv_2mortal(newSVpvn(string, string_len));
	string_free(string);
	if (utf8)
		sv_utf8_decode(string_scalar);
	if (taint)
		SvTAINTED_on(string_scalar);
	EXTEND(SP, 1);
	PUSHs(string_scalar);

void
parse_email_groups(...)
PREINIT:
	SV *string_scalar;
	SV *class_scalar;
	int count;
	HV *hv_class;
	SV *group_scalar;
	SV *addresses_scalar;
	bool utf8;
	bool taint;
	STRLEN input_len;
	const char *input;
	struct message_address *address;
	struct message_address *first_address;
INPUT:
	const char *this_class_name = "$Package";
	STRLEN this_class_len = sizeof("$Package")-1;
INIT:
	string_scalar = items >= 1 ? ST(0) : &PL_sv_undef;
	class_scalar = items >= 2 ? ST(1) : NULL;
	input = get_perl_scalar_string_value(aTHX_ string_scalar, &input_len, "string", false);
	utf8 = SvUTF8(string_scalar);
	taint = SvTAINTED(string_scalar);
	hv_class = get_perl_class_from_perl_scalar_or_cv(aTHX_ class_scalar, cv);
	if (class_scalar && !sv_derived_from_pvn(class_scalar, this_class_name, this_class_len, SVf_UTF8)) {
		carp(CARP_WARN, "Class %" SVf " is not derived from %s", SVfARG(class_scalar), this_class_name);
		XSRETURN_EMPTY;
	}
PPCODE:
	first_address = message_address_parse(input, input_len, UINT_MAX, false);
	count = count_address_groups(first_address);
	EXTEND(SP, count * 2);
	address = first_address;
	while (get_next_perl_address_group(aTHX_ &address, &group_scalar, &addresses_scalar, hv_class, utf8, taint)) {
		PUSHs(group_scalar);
		PUSHs(addresses_scalar);
	}
	message_address_free(&first_address);

void
compose_address(...)
PREINIT:
	char *string;
	const char *mailbox;
	const char *domain;
	size_t string_len;
	STRLEN mailbox_len;
	STRLEN domain_len;
	bool mailbox_utf8;
	bool domain_utf8;
	bool utf8;
	bool taint;
	SV *mailbox_scalar;
	SV *domain_scalar;
	SV *string_scalar;
INIT:
	mailbox_scalar = items >= 1 ? ST(0) : &PL_sv_undef;
	domain_scalar = items >= 2 ? ST(1) : &PL_sv_undef;
	mailbox = get_perl_scalar_string_value(aTHX_ mailbox_scalar, &mailbox_len, "mailbox", false);
	domain = get_perl_scalar_string_value(aTHX_ domain_scalar, &domain_len, "domain", false);
	mailbox_utf8 = SvUTF8(mailbox_scalar);
	domain_utf8 = SvUTF8(domain_scalar);
	utf8 = (mailbox_utf8 || domain_utf8);
	if (utf8 && !mailbox_utf8)
		mailbox = get_perl_scalar_value(aTHX_ mailbox_scalar, &mailbox_len, true, true);
	if (utf8 && !domain_utf8)
		domain = get_perl_scalar_value(aTHX_ domain_scalar, &domain_len, true, true);
	taint = (SvTAINTED(mailbox_scalar) || SvTAINTED(domain_scalar));
PPCODE:
	compose_address(&string, &string_len, mailbox, mailbox_len, domain, domain_len);
	string_scalar = sv_2mortal(newSVpvn(string, string_len));
	string_free(string);
	if (utf8)
		sv_utf8_decode(string_scalar);
	if (taint)
		SvTAINTED_on(string_scalar);
	EXTEND(SP, 1);
	PUSHs(string_scalar);

void
split_address(...)
PREINIT:
	const char *string;
	char *mailbox;
	char *domain;
	STRLEN string_len;
	size_t mailbox_len;
	size_t domain_len;
	bool utf8;
	bool taint;
	SV *string_scalar;
	SV *mailbox_scalar;
	SV *domain_scalar;
INIT:
	string_scalar = items >= 1 ? ST(0) : &PL_sv_undef;
	string = get_perl_scalar_string_value(aTHX_ string_scalar, &string_len, "string", false);
	utf8 = SvUTF8(string_scalar);
	taint = SvTAINTED(string_scalar);
PPCODE:
	split_address(string, string_len, &mailbox, &mailbox_len, &domain, &domain_len);
	mailbox_scalar = mailbox ? sv_2mortal(newSVpvn(mailbox, mailbox_len)) : sv_newmortal();
	domain_scalar = domain ? sv_2mortal(newSVpvn(domain, domain_len)) : sv_newmortal();
	string_free(mailbox);
	string_free(domain);
	if (utf8) {
		sv_utf8_decode(mailbox_scalar);
		sv_utf8_decode(domain_scalar);
	}
	if (taint) {
		SvTAINTED_on(mailbox_scalar);
		SvTAINTED_on(domain_scalar);
	}
	EXTEND(SP, 2);
	PUSHs(mailbox_scalar);
	PUSHs(domain_scalar);

bool
is_obj(...)
PREINIT:
	SV *class = items >= 1 ? ST(0) : &PL_sv_undef;
	SV *object = items >= 2 ? ST(1) : &PL_sv_undef;
CODE:
	RETVAL = is_class_object(aTHX_ class, NULL, 0, object);
OUTPUT:
	RETVAL
