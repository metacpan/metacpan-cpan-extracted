MODULE = FIDO::Raw         PACKAGE = FIDO::Raw::PublicKey::ES256

PublicKey_ES256
new (class, data)
	SV *class
	SV *data

	PREINIT:
		es256_pk_t *pk;
		int rc;

	CODE:
		if (!SvOK (data))
			croak ("data not specified");

		pk = es256_pk_new();
		rc = es256_pk_from_ptr (pk, (const void *)SvPVX (data), SvCUR (data));
		if (rc != FIDO_OK)
		{
			es256_pk_free (&pk);
			croak ("could not set pk from data");
		}

		RETVAL = pk;

	OUTPUT: RETVAL

void
DESTROY (self)
	PublicKey_ES256 self

	CODE:
		es256_pk_free (&self);

