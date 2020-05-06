MODULE = FIDO::Raw         PACKAGE = FIDO::Raw::Cred

Cred
new (class)
	SV *class

	PREINIT:
		Cred cred;

	CODE:
		cred = fido_cred_new();
		if (cred == NULL)
			croak ("could not create a fido_cred_t object");

		RETVAL = cred;

	OUTPUT: RETVAL

const char *
fmt (self, ...)
	Cred self

	PREINIT:
		int rc;
	CODE:
		if (items >= 2)
		{
			rc = fido_cred_set_fmt (self, SvPV_nolen (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set fmt: %d", rc);
		}

		RETVAL = fido_cred_fmt (self);

	OUTPUT: RETVAL

int
prot (self, ...)
	Cred self

	PREINIT:
		int rc;

	CODE:
		if (items >= 2)
		{
			rc = fido_cred_set_prot (self, SvIV (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set prot: %d", rc);
		}

		RETVAL = fido_cred_prot (self);

	OUTPUT: RETVAL

SV *
rp (self, ...)
	Cred self

	PREINIT:
		int rc;
		HV *result;
		const char *rp_id = NULL;
		const char *rp_name = NULL;

	CODE:
		if (items >= 2)
		{
			if (SvOK (ST (1)))
			{
				/* rp_id may be undef */
				if (!SvPOK (ST (1)))
					croak ("id not vlid");
				rp_id = SvPV_nolen (ST (1));
			}

			if (items < 3 || !SvOK (ST (2)) || !SvPOK (ST (2)))
				croak ("name is not valid");

			rp_name = SvPV_nolen (ST (2));

			rc = fido_cred_set_rp (self, rp_id, rp_name);
			if (rc != FIDO_OK)
				croak ("could not set rp: %d", rc);
		}

		result = newHV();

		rp_id = fido_cred_rp_id (self);
		if (rp_id)
			hv_stores (result, "id", newSVpv (rp_id, 0));

		rp_name = fido_cred_rp_name (self);
		if (rp_name)
			hv_stores (result, "name", newSVpv (rp_name, 0));

		RETVAL = newRV_noinc (MUTABLE_SV (result));

	OUTPUT: RETVAL

SV *
user (self, ...)
	Cred self

	PREINIT:
		int rc;
		const unsigned char *user_id = NULL;
		size_t user_id_len = 0;
		const char *user_name = NULL;
		const char *display_name = NULL;
		const char *icon = NULL;

		HV *result;

	CODE:
		if (items >= 2)
		{
			user_id = (const unsigned char*)SvPVX (ST (1));
			user_id_len = SvCUR (ST (1));

			if (items >= 3)
				user_name = SvPV_nolen (ST (2));
			if (items >= 4)
				display_name = SvPV_nolen (ST (3));
			if (items >= 5)
				icon = SvPV_nolen (ST (4));

			rc = fido_cred_set_user (self, user_id, user_id_len,
				user_name, display_name, icon);
			if (rc != FIDO_OK)
				croak ("could not set user: %d", rc);
		}

		result = newHV();

		user_id = fido_cred_user_id_ptr (self);
		if (user_id)
		{
			user_id_len = fido_cred_user_id_len (self);
			hv_stores (result, "id", newSVpvn ((const char *)user_id, user_id_len));
		}

		user_name = fido_cred_user_name (self);
		if (user_name)
		{
			hv_stores (result, "name", newSVpv (user_name, 0));
		}

		display_name = fido_cred_display_name (self);
		if (display_name)
		{
			hv_stores (result, "display_name", newSVpv (display_name, 0));
		}

		RETVAL = newRV_noinc (MUTABLE_SV (result));

	OUTPUT: RETVAL

int
type (self, ...)
	Cred self

	PREINIT:
		int rc;

	CODE:
		if (items >= 2)
		{
			if (!SvIOK (ST (1)))
				croak ("cose_alg is not valid");

			rc = fido_cred_set_type (self, SvIV (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set type: %d", rc);
		}

		RETVAL = fido_cred_type (self);

	OUTPUT: RETVAL

unsigned int
flags (self)
	Cred self

	CODE:
		RETVAL = fido_cred_flags (self);

	OUTPUT: RETVAL

void
extensions (self, flags)
	Cred self
	int flags

	PREINIT:
		int rc;

	CODE:
		rc = fido_cred_set_extensions (self, flags);
		if (rc != FIDO_OK)
			croak ("could not set extensions: %d", rc);

void
rk (self, ...)
	Cred self

	PREINIT:
		int rc;
		fido_opt_t o = FIDO_OPT_OMIT;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
			o = SvIV (ST (1));

		rc = fido_cred_set_rk (self, o);
		if (rc != FIDO_OK)
			croak ("could not set rk: %d", rc);

void
uv (self, ...)
	Cred self

	PREINIT:
		int rc;
		fido_opt_t o = FIDO_OPT_OMIT;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
			o = SvIV (ST (1));

		rc = fido_cred_set_uv (self, o);
		if (rc != FIDO_OK)
			croak ("could not set uv: %d", rc);

void
exclude (self, ex)
	Cred self
	SV *ex

	PREINIT:
		int rc;

	CODE:
		if (!SvOK (ex))
			croak ("ex not specified");

		rc = fido_cred_exclude (self, (const unsigned char *)SvPVX (ex), SvCUR (ex));
		if (rc != FIDO_OK)
			croak ("could not add exclude: %d", rc);

SV *
authdata (self, ...)
	Cred self

	PREINIT:
		int rc;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2)
		{
			if (!SvOK (ST (1)))
				croak ("data not specified");

			rc = fido_cred_set_authdata (self, (const unsigned char *)SvPVX (ST (1)), SvCUR (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set authdata: %d", rc);
		}

		ptr = fido_cred_authdata_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_authdata_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

void
authdata_raw (self, data)
	Cred self
	SV *data

	PREINIT:
		int rc;

	CODE:
		if (!SvOK (data))
			croak ("data not specified");

		rc = fido_cred_set_authdata_raw (self, (const unsigned char *)SvPVX (data), SvCUR (data));
		if (rc != FIDO_OK)
			croak ("could not set authdata: %d", rc);

SV *
id (self)
	Cred self

	PREINIT:
		const unsigned char *ptr;
		size_t len;

	CODE:
		ptr = fido_cred_id_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_id_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

SV *
aaguid (self)
	Cred self

	PREINIT:
		const unsigned char *ptr;
		size_t len;

	CODE:
		ptr = fido_cred_aaguid_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_aaguid_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

SV *
pubkey (self)
	Cred self

	PREINIT:
		const unsigned char *ptr;
		size_t len;

	CODE:
		ptr = fido_cred_pubkey_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_pubkey_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

SV *
x509 (self, ...)
	Cred self

	PREINIT:
		int rc;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2)
		{
			if (!SvOK (ST (1)))
				croak ("data not specified");

			rc = fido_cred_set_x509 (self, (const unsigned char *)SvPVX (ST (1)), SvCUR (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set x509: %d", rc);
		}

		ptr = fido_cred_x5c_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_x5c_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

SV *
sig (self, ...)
	Cred self

	PREINIT:
		int rc;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2)
		{
			if (!SvOK (ST (1)))
				croak ("data not specified");

			rc = fido_cred_set_sig (self, (const unsigned char *)SvPVX (ST (1)), SvCUR (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set sig: %d", rc);
		}

		ptr = fido_cred_sig_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_sig_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

SV *
clientdata_hash (self, ...)
	Cred self

	PREINIT:
		int rc;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2)
		{
			if (!SvOK (ST (1)))
				croak ("data not specified");

			rc = fido_cred_set_clientdata_hash (self, (const unsigned char *)SvPVX (ST (1)), SvCUR (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set sig: %d", rc);
		}

		ptr = fido_cred_clientdata_hash_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_cred_clientdata_hash_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

int
verify (self)
	Cred self

	CODE:
		RETVAL = fido_cred_verify (self);

	OUTPUT: RETVAL

void
DESTROY(self)
	Cred self

	CODE:
		fido_cred_free (&self);

