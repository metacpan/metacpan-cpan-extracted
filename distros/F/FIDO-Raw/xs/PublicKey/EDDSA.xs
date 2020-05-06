MODULE = FIDO::Raw         PACKAGE = FIDO::Raw::PublicKey::EDDSA

PublicKey_EDDSA
new (class, data)
	SV *class
	SV *data

	PREINIT:
		eddsa_pk_t *pk;
		int rc;

	CODE:
		if (!SvOK (data))
			croak ("data not specified");

		pk = eddsa_pk_new();
		rc = eddsa_pk_from_ptr (pk, (const void *)SvPVX (data), SvCUR (data));
		if (rc != FIDO_OK)
		{
			eddsa_pk_free (&pk);
			croak ("could not set pk from data");
		}

		RETVAL = pk;

	OUTPUT: RETVAL

void
DESTROY (self)
	PublicKey_EDDSA self

	CODE:
		eddsa_pk_free (&self);

