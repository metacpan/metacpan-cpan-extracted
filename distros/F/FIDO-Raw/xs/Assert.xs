MODULE = FIDO::Raw         PACKAGE = FIDO::Raw::Assert

Assert
new (class)
	SV *class

	PREINIT:
		Assert asrt;

	CODE:
		asrt = fido_assert_new();
		if (asrt == NULL)
			croak ("could not create a fido_assert_t object");

		RETVAL = asrt;

	OUTPUT: RETVAL

void
allow_cred (self, cred)
	Assert self
	SV *cred

	PREINIT:
		int rc;

	CODE:
		if (!SvOK (cred))
			croak ("cred not specified");

		rc = fido_assert_allow_cred (self, (const unsigned char *)SvPVX (cred), SvCUR (cred));
		if (rc != FIDO_OK)
			croak ("could not allow cred: %d", rc);

SV *
authdata (self, ...)
	Assert self

	PREINIT:
		int rc;
		size_t idx = 0;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		if (items >= 3)
		{
			if (!SvOK (ST (2)))
				croak ("data not specified");

			rc = fido_assert_set_authdata (self, idx, (const unsigned char *)SvPVX (ST (2)), SvCUR (ST (2)));
			if (rc != FIDO_OK)
				croak ("could not set authdata: %d", rc);
		}


		ptr = fido_assert_authdata_ptr (self, idx);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_assert_authdata_len (self, idx);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

void
authdata_raw (self, data, ...)
	Assert self
	SV *data

	PREINIT:
		int rc;
		size_t idx = 0;

	CODE:
		if (!SvOK (data))
			croak ("data not specified");

		if (items >= 3)
		{
			if (!SvIOK (ST (2)))
				croak ("index is not valid");

			idx = SvUV (ST (2));
		}

		rc = fido_assert_set_authdata_raw (self, idx, (const unsigned char *)SvPVX (data), SvCUR (data));
		if (rc != FIDO_OK)
			croak ("could not set authdata: %d", rc);

SV *
clientdata_hash (self, ...)
	Assert self

	PREINIT:
		int rc;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2)
		{
			if (!SvOK (ST (1)))
				croak ("data not specified");

			rc = fido_assert_set_clientdata_hash (self, (const unsigned char *)SvPVX (ST (1)), SvCUR (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set sig: %d", rc);
		}

		ptr = fido_assert_clientdata_hash_ptr (self);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_assert_clientdata_hash_len (self);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

void
hmac_salt (self, data)
	Assert self
	SV *data

	PREINIT:
		int rc;

	CODE:
		if (!SvOK (data))
			croak ("data not specified");

		rc = fido_assert_set_hmac_salt (self, (const unsigned char *)SvPVX (data), SvCUR (data));
		if (rc != FIDO_OK)
			croak ("could not set sig: %d", rc);

SV *
hmac_secret (self, ...)
	Assert self

	PREINIT:
		size_t idx = 0;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2)
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		ptr = fido_assert_hmac_secret_ptr (self, idx);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_assert_hmac_secret_len (self, idx);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

void
extensions (self, flags)
	Assert self
	int flags

	PREINIT:
		int rc;

	CODE:
		rc = fido_assert_set_extensions (self, flags);
		if (rc != FIDO_OK)
			croak ("could not set extensions: %d", rc);

unsigned int
count (self, ...)
	Assert self

	PREINIT:
		int rc;

	CODE:
		if (items >= 2)
		{
			if (!SvIOK (ST (1)))
				croak ("count is not valid");

			rc = fido_assert_set_count (self, SvUV (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set count: %d", rc);
		}

		RETVAL = fido_assert_count (self);

	OUTPUT: RETVAL

unsigned int
sigcount (self, ...)
	Assert self

	PREINIT:
		size_t idx = 0;

	CODE:
		if (items >= 2)
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		RETVAL = fido_assert_sigcount (self, idx);

	OUTPUT: RETVAL

SV *
sig (self, ...)
	Assert self

	PREINIT:
		int rc;
		size_t idx = 0;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		if (items >= 3)
		{
			if (!SvOK (ST (2)))
				croak ("data not specified");

			rc = fido_assert_set_sig (self, idx, (const unsigned char *)SvPVX (ST (2)), SvCUR (ST (2)));
			if (rc != FIDO_OK)
				croak ("could not set sig: %d", rc);
		}

		ptr = fido_assert_sig_ptr (self, idx);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_assert_sig_len (self, idx);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

void
uv (self, ...)
	Assert self

	PREINIT:
		int rc;
		fido_opt_t o = FIDO_OPT_OMIT;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
			o = SvIV (ST (1));

		rc = fido_assert_set_uv (self, o);
		if (rc != FIDO_OK)
			croak ("could not set uv: %d", rc);

void
up (self, ...)
	Assert self

	PREINIT:
		int rc;
		fido_opt_t o = FIDO_OPT_OMIT;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
			o = SvIV (ST (1));

		rc = fido_assert_set_up (self, o);
		if (rc != FIDO_OK)
			croak ("could not set uv: %d", rc);

SV *
rp (self, ...)
	Assert self

	PREINIT:
		int rc;
		const char *rp;

	CODE:
		if (items >= 2)
		{
			if (!SvOK (ST (1)))
				croak ("id is not valid");

			rc = fido_assert_set_rp (self, SvPVX (ST (1)));
			if (rc != FIDO_OK)
				croak ("could not set rp: %d", rc);
		}

		rp = fido_assert_rp_id (self);
		if (rp == NULL)
			XSRETURN_UNDEF;

		RETVAL = newSVpv (rp, 0);

	OUTPUT: RETVAL

SV *
user (self, ...)
	Assert self

	PREINIT:
		size_t idx = 0;
		const unsigned char *user_id;
		const char *user_name;
		const char *user_diplay_name;
		const char *user_icon;
		size_t len;
		HV *result;

	CODE:
		if (items >= 2)
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		result = newHV();

		user_id = fido_assert_user_id_ptr (self, idx);
		if (user_id)
		{
			len = fido_assert_user_id_len (self, idx);
			hv_stores (result, "id", newSVpvn ((const char *)user_id, len));
		}

		user_name = fido_assert_user_name (self, idx);
		if (user_name)
			hv_stores (result, "name", newSVpv (user_name, 0));

		user_diplay_name = fido_assert_user_display_name (self, idx);
		if (user_diplay_name)
			hv_stores (result, "display_name", newSVpv (user_diplay_name, 0));

		user_icon = fido_assert_user_icon (self, idx);
		if (user_icon)
			hv_stores (result, "icon", newSVpv (user_icon, 0));

		RETVAL = newRV_noinc (MUTABLE_SV (result));

	OUTPUT: RETVAL

unsigned int
flags (self, ...)
	Assert self

	PREINIT:
		size_t idx = 0;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		RETVAL = fido_assert_flags (self, idx);

	OUTPUT: RETVAL

SV *
id (self, ...)
	Assert self

	PREINIT:
		size_t idx = 0;
		const unsigned char *ptr;
		size_t len;

	CODE:
		if (items >= 2 && SvOK (ST (1)))
		{
			if (!SvIOK (ST (1)))
				croak ("index is not valid");

			idx = SvUV (ST (1));
		}

		ptr = fido_assert_id_ptr (self, idx);
		if (ptr == NULL)
			XSRETURN_UNDEF;

		len = fido_assert_id_len (self, idx);

		RETVAL = newSVpv ((const char *)ptr, len);

	OUTPUT: RETVAL

int
verify (self, idx, alg, pk)
	Assert self
	unsigned int idx;
	int alg
	SV *pk

	CODE:
		if (!SvOK (pk))
			croak ("pk not specified");

		if (!sv_isobject (pk) || !(
			sv_derived_from (pk, "FIDO::Raw::PublicKey::ES256") ||
			sv_derived_from (pk, "FIDO::Raw::PublicKey::RS256") ||
			sv_derived_from (pk, "FIDO::Raw::PublicKey::EDDSA")))
		{
			croak ("unsupported/invalid private key");
		}

		RETVAL = fido_assert_verify (self, idx, alg,
			INT2PTR (const void *, SvIV((SV *) SvRV (pk))));

	OUTPUT: RETVAL

void
DESTROY(self)
	Assert self

	CODE:
		fido_assert_free (&self);
