/* -*- mode: c; indent-tabs-mode: t; c-basic-offset: 8; -*- */

/* Call Carp's croak() so that errors are reported at their location in the
 * user's program, not in Introspection.pm.  Adapted from
 * <http://www.perlmonks.org/?node_id=865159>. */
static void
call_carp_croak (const char *msg)
{
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);
	XPUSHs (sv_2mortal (newSVpv(msg, 0)));
	PUTBACK;

	call_pv("Carp::croak", G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* Similarly for Carp's carp(). */
static void
call_carp_carp (const char *msg)
{
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);
	XPUSHs (sv_2mortal (newSVpv(msg, 0)));
	PUTBACK;

	call_pv("Carp::carp", G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}
