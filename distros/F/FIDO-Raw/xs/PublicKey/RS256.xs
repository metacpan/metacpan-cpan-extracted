MODULE = FIDO::Raw         PACKAGE = FIDO::Raw::PublicKey::RS256

PublicKey_RS256
new (class, data)
	SV *class
	SV *data

	PREINIT:
		rs256_pk_t *pk;
		int rc;

	CODE:
		if (!SvOK (data))
			croak ("data not specified");

		pk = rs256_pk_new();
		rc = rs256_pk_from_ptr (pk, (const void *)SvPVX (data), SvCUR (data));
		if (rc != FIDO_OK)
		{
			rs256_pk_free (&pk);
			croak ("could not set pk from data");
		}

		RETVAL = pk;

	OUTPUT: RETVAL

void
DESTROY (self)
	PublicKey_RS256 self

	CODE:
		rs256_pk_free (&self);

