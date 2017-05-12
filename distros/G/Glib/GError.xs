/*
 * Copyright (C) 2004-2009 by the gtk2-perl team (see the file AUTHORS for the full
 * list)
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * $Id$
 */

#include "gperl.h"
#include "gperl-gtypes.h"

=head2 GError Exception Objects

GError is a facility for propagating run-time error / exception information
around in C, which is a language without native support for exceptions.
GError uses a simple error code, usually defined as an enum.  Since the
enums will overlap, GError includes the GQuark corresponding to a particular
error "domain" to tell you which error codes will be used.  There's also a
string containing a specific error message.  The strings are arbitrary, and
may be translated, but the domains and codes are definite.

Perl has native support for exceptions, using C<eval> as "try", C<croak> or
C<die> as "throw", and C<< if ($@) >> as "catch".  C<$@> may, in fact, be
any scalar, including blessed objects.

So, GPerl maps GLib's GError to Perl exceptions.

Since, as we described above, error messages are not guaranteed to be unique
everywhere, we need to support the use of the error domains and codes.
The obvious choice here is to use exception objects; however, to support
blessed exception objects, we must perform a little bit of black magic in
the bindings.   There is no built-in association between an error domain
quark and the GType of the corresponding error code enumeration, so the
bindings supply both of these when specifying the name of the package into
which to bless exceptions of this domain.  All GError-based exceptions 
derive from Glib::Error, of course, and this base class provides all of the
functionality, including stringification.

All you'll really ever need to do is register error domains with
C<gperl_register_error_domain>, and throw errors with C<gperl_croak_gerror>.

=over

=cut

typedef struct {
	GQuark  domain;
	GType   error_enum;
	char  * package;
} ErrorInfo;

static ErrorInfo *
error_info_new (GQuark domain, GType error_enum, const char * package)
{
	ErrorInfo * info = g_new (ErrorInfo, 1);
	info->domain = domain;
	info->error_enum = error_enum;
	info->package = package ? g_strdup (package) : NULL;
	return info;
}

static void
error_info_free (ErrorInfo * info)
{
	if (info) {
		info->domain = 0;
		info->error_enum = 0;
		if (info->package)
			g_free (info->package);
		info->package = NULL;
		g_free (info);
	}
}

static GHashTable * errors_by_domain = NULL;

=item void gperl_register_error_domain (GQuark domain, GType error_enum, const char * package)

Tell the bindings to bless GErrors with error->domain == I<domain> into
I<package>, and use I<error_enum> to find the nicknames for the error codes.
This will call C<gperl_set_isa> on I<package> to add "Glib::Error" to
I<package>'s @ISA.

I<domain> may not be 0, and I<package> may not be NULL; what would be the 
point?  I<error_enum> may be 0, in which case you'll get no fancy stringified
error values.

=cut
void
gperl_register_error_domain (GQuark domain,
                             GType error_enum,
                             const char * package)
{
	g_return_if_fail (domain != 0); /* pointless without this */
	g_return_if_fail (package != NULL); /* or this */

	if (!errors_by_domain)
		errors_by_domain = g_hash_table_new_full
					(g_direct_hash,
					 g_direct_equal,
					 NULL,
					 (GDestroyNotify) error_info_free);

	g_hash_table_insert (errors_by_domain,
	                     GUINT_TO_POINTER (domain),
	                     error_info_new (domain, error_enum, package));
	gperl_set_isa (package, "Glib::Error");
}

struct FindData {
	const char * package;
	ErrorInfo * info;
};

static void
find_package (gpointer key,
              ErrorInfo * info,
              struct FindData * find_data)
{
	PERL_UNUSED_VAR (key);
	if (g_str_equal (find_data->package, info->package))
		find_data->info = info;
}

static ErrorInfo *
error_info_from_package (const char * package)
{
	struct FindData find_data;
	find_data.package = package;
	find_data.info = NULL;
	g_hash_table_foreach (errors_by_domain,
	                      (GHFunc) find_package,
	                      &find_data);
	return find_data.info;
}

static ErrorInfo *
error_info_from_domain (GQuark domain)
{
	return (ErrorInfo*) g_hash_table_lookup (errors_by_domain,
	                                         GUINT_TO_POINTER (domain));
}

=item SV * gperl_sv_from_gerror (GError * error)

You should rarely, if ever, need to call this function.  This is what turns
a GError into a Perl object.

=cut
SV *
gperl_sv_from_gerror (GError * error)
{
	HV * hv;
	ErrorInfo * info;
	char * package;

	if (!error)
		return newSVsv (&PL_sv_undef);

	info = error_info_from_domain (error->domain);

	hv = newHV ();
	gperl_hv_take_sv_s (hv, "domain",
	                    newSVGChar (g_quark_to_string (error->domain)));
	gperl_hv_take_sv_s (hv, "code", newSViv (error->code));
	if (info)
		gperl_hv_take_sv_s (hv, "value",
		                    gperl_convert_back_enum (info->error_enum,
		                                             error->code));
	gperl_hv_take_sv_s (hv, "message", newSVGChar (error->message));

	/* WARNING: using evil undocumented voodoo.  mess() is the function
	 * that die(), warn(), and croak() use to format messages, and it's
	 * what knows how to find the code location.  don't want to do that
	 * ourselves, since that's blacker magic, so we'll call this and 
	 * hope the perl API doesn't change.  */
	gperl_hv_take_sv_s (hv, "location", newSVsv (mess ("%s", "")));

	package = info ? info->package : "Glib::Error";

	return sv_bless (newRV_noinc ((SV*) hv), gv_stashpv (package, TRUE)); 
}


=item gperl_gerror_from_sv (SV * sv, GError ** error)

You should rarely need this function.  This parses a perl data structure into
a GError.  If I<sv> is undef (or the empty string), sets *I<error> to NULL,
otherwise, allocates a new GError with C<g_error_new_literal()> and writes
through I<error>; the caller is responsible for calling C<g_error_free()>.
(gperl_croak_gerror() does this, for example.)

=cut
void
gperl_gerror_from_sv (SV * sv, GError ** error)
{
	ErrorInfo * info = NULL;
	const char * package;
	GError scratch;
	HV * hv;
	SV ** svp;

	/* pass back NULL if the sv is false.  we need to allow for the
	 * empty string because $@ is often '' rather than undef; as a 
	 * side effect, 0 is also allowed.  we just won't advertise that.
	 * the logic here is a bit ugly to avoid running the overloaded
	 * stringification operator via SvTRUE(). */
	if (!gperl_sv_is_defined (sv) ||		/* not defined */
	    (!SvROK (sv) && !SvTRUE (sv)))	/* not a ref, but still false */
	{
		*error = NULL;
		return;
	}

	/*
	 * now we must parse a hash.
	 */
	if (!gperl_sv_is_hash_ref (sv))
		croak ("expecting undef or a hash reference for a GError");

	/*
	 * error domain.  prefer the type into which the object is blessed,
	 * fall back to the 'domain' key.
	 */
	package = sv_reftype (SvRV (sv), TRUE);
	hv = (HV*) SvRV (sv);
	if (package)
		info = error_info_from_package (package);
	if (!info) {
		const char * domain;
		GQuark qdomain;
		svp = hv_fetch (hv, "domain", 6, FALSE);
		if (!svp || !gperl_sv_is_defined (*svp))
			g_error ("key 'domain' not found in plain hash for GError");
		domain = SvPV_nolen (*svp);
		qdomain = g_quark_try_string (domain);
		if (!qdomain)
			g_error ("%s is not a valid quark, did you remember to register an error domain?", domain);

		info = error_info_from_domain (qdomain);
	}
	if (!info)
		croak ("%s is neither a Glib::Error derivative nor a valid GError domain",
		       SvPV_nolen (sv));
		
	scratch.domain = info->domain;

	/*
	 * error code.  prefer the 'value' key, fall back to 'code'.
	 */
	svp = hv_fetch (hv, "value", 5, FALSE);
	if (svp && gperl_sv_is_defined (*svp))
		scratch.code = gperl_convert_enum (info->error_enum, *svp);
	else {
		svp = hv_fetch (hv, "code", 4, FALSE);
		if (!svp || !gperl_sv_is_defined (*svp))
			croak ("error hash contains neither a 'value' nor 'code' key; no error valid error code found");
		scratch.code = SvIV (*svp);
	}

	/*
	 * the message is the easy part.
	 */
	svp = hv_fetch (hv, "message", 7, FALSE);
	if (!svp || !gperl_sv_is_defined (*svp))
		croak ("error has contains no error message");
	scratch.message = SvGChar (*svp);

	*error = g_error_new_literal (scratch.domain,
	                              scratch.code,
	                              scratch.message);
}

=item void gperl_croak_gerror (const char * ignored, GError * err)

Croak with an exception based on I<err>.  I<err> may not be NULL.  I<ignored>
exists for backward compatibility, and is, well, ignored.  This function
calls croak(), which does not return.

Since croak() does not return, this function handles the magic behind 
not leaking the memory associated with the #GError.  To use this you'd
do something like

 PREINIT:
   GError * error = NULL;
 CODE:
   if (!funtion_that_can_fail (something, &error))
      gperl_croak_gerror (NULL, error);

It's just that simple!

=cut
void
gperl_croak_gerror (const char * ignored, GError * err)
{
	PERL_UNUSED_VAR (ignored);
	/* this really could only happen if there's a problem with XS bindings
	 * so we'll use a assertion to catch it, rather than handle null */
	g_return_if_fail (err != NULL);

	sv_setsv (ERRSV, gperl_sv_from_gerror (err));

	/* croak() does not return; free this now to avoid leaking it. */
	g_error_free (err);
	croak (Nullch);
}

=back

=cut

MODULE = Glib::Error	PACKAGE = Glib::Error	

BOOT:
	/* i can't quite decide whether i'm happy about registering all
	 * of these here.  in theory, it's possible to get any of these,
	 * so we should define them for later use; in practice, we may
	 * never see a few of them. */
#if GLIB_CHECK_VERSION (2, 12, 0)
	/* gbookmarkfile.h */
	gperl_register_error_domain (G_BOOKMARK_FILE_ERROR,
				     GPERL_TYPE_BOOKMARK_FILE_ERROR,
				     "Glib::BookmarkFile::Error");
#endif /* GLIB_CHECK_VERSION (2, 12, 0) */
	/* gconvert.h */
	gperl_register_error_domain (G_CONVERT_ERROR,
	                             GPERL_TYPE_CONVERT_ERROR,
	                             "Glib::Convert::Error");
	/* gfileutils.h */
	gperl_register_error_domain (G_FILE_ERROR,
	                             GPERL_TYPE_FILE_ERROR,
	                             "Glib::File::Error");
#if GLIB_CHECK_VERSION (2, 6, 0)
	/* gkeyfile.h */
	gperl_register_error_domain (G_KEY_FILE_ERROR,
				     GPERL_TYPE_KEY_FILE_ERROR,
				     "Glib::KeyFile::Error");
#endif /* GLIB_CHECK_VERSION (2, 6, 0) */
	/* giochannel.h */
	gperl_register_error_domain (G_IO_CHANNEL_ERROR,
	                             GPERL_TYPE_IO_CHANNEL_ERROR,
	                             "Glib::IOChannel::Error");
	/* gmarkup.h */
	gperl_register_error_domain (G_MARKUP_ERROR,
	                             GPERL_TYPE_MARKUP_ERROR,
	                             "Glib::Markup::Error");
	/* gshell.h */
	gperl_register_error_domain (G_SHELL_ERROR,
	                             GPERL_TYPE_SHELL_ERROR,
	                             "Glib::Shell::Error");
	/* gspawn.h */
	gperl_register_error_domain (G_SPAWN_ERROR,
	                             GPERL_TYPE_SPAWN_ERROR,
	                             "Glib::Spawn::Error");
	/* gthread.h */
	gperl_register_error_domain (G_THREAD_ERROR,
	                             GPERL_TYPE_THREAD_ERROR,
	                             "Glib::Thread::Error");
#if GLIB_CHECK_VERSION (2, 28, 0)
	/* gvariant.h */
	gperl_register_error_domain (G_VARIANT_PARSE_ERROR,
	                             GPERL_TYPE_VARIANT_PARSE_ERROR,
	                             "Glib::Variant::ParseError");
#endif

	PERL_UNUSED_VAR (file);

=for object Glib::Error Exception Objects based on GError
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  eval {
     my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($filename);
     $image->set_from_pixbuf ($pixbuf);
  };
  if ($@) {
     print "$@\n";
     if (Glib::Error::matches ($@, 'Gtk2::Gdk::Pixbuf::Error',
                                   'unknown-format')) {
        change_format_and_try_again ();
     } elsif (Glib::Error::matches ($@, 'Glib::File::Error', 'noent')) {
        change_source_dir_and_try_again ();
     } else {
        # don't know how to handle this
        die $@;
     }
  }

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2-Perl translates GLib's GError runtime errors into Perl exceptions, by
creating exception objects based on Glib::Error.  Glib::Error overloads the
stringification operator, so a Glib::Error object will act like a string if
used with print() or warn(), so most code using $@ will not even know the
difference.

The point of having exception objects, however, is that the error messages
in GErrors are often localized with NLS translation.  Thus, it's not good
for your code to attempt to handle errors by string matching on the the 
error message.  Glib::Error provides a way to get to the deterministic
error code.

You will typically deal with objects that inherit from Glib::Error, such as
Glib::Convert::Error, Glib::File::Error, Gtk2::Gdk::Pixbuf::Error, etc; these
classes are provided by the libraries that define the error domains.  However,
it is possible to get a base Glib::Error when the bindings encounter an unknown
or unbound error domain.  The interface used here degrades nicely in such a
situation, but in general you should submit a bug report to the binding
maintainer if you get such an exception.

=cut

##
## evil trick here -- define xsubs that xsdocparse can see, but which
## xsubpp will not compile, so we get documentation on them.
##

#if 0

=for apidoc

The source line and file closest to the emission of the exception, in the same
format that you'd get from croak() or die().

If there's non-ascii characters in the filename Perl leaves them as
raw bytes, so you may have to put the string through
Glib::filename_display_name for a wide-char form.

=cut
char * location (SV * error)

=for apidoc

The error message.  This may be localized, as it is intended to be shown to a
user.

=cut
char * message (SV * error)

=for apidoc

The error domain.  You normally do not need this, as the object will be blessed
into a corresponding class.

=cut
char * domain (SV * error)

=for apidoc

The enumeration value nickname of the integer value in C<< $error->code >>, 
according to this error domain.  This will not be available if the error
object is a base Glib::Error, because the bindings will have no idea how to
get to the correct nickname.

=cut
char * value (SV * error)

=forapidoc

This is the numeric error code.  Normally, you'll want to use C<value> instead,
for readability.

=cut
int code (SV * error)

#endif

=for apidoc Glib::Error::throw
=for signature scalar = Glib::Error::throw ($class, $code, $message)
=for signature scalar = $class->throw ($code, $message)
=for arg code (GEnum) an enumeration value, depends on I<$class>

Throw an exception with a Glib::Error exception object.
Equivalent to C<< croak (Glib::Error::new ($class, $code, $message)); >>.

=cut

=for apidoc
=for signature scalar = Glib::Error::new ($class, $code, $message)
=for signature scalar = $class->new ($code, $message)
=for arg code (GEnum) an enumeration value, depends on I<$class>

Create a new exception object of type I<$class>, where I<$class> is associated
with a GError domain.  I<$code> should be a value from the enumeration type
associated with this error domain.  I<$message> can be anything you like, but
should explain what happened from the point of view of a user.

=cut
SV *
new (const char * class, SV * code, const gchar * message)
    ALIAS:
	Glib::Error::throw = 1
    PREINIT:
	ErrorInfo * info = NULL;
    CODE:
	info = error_info_from_package (class);
	if (!info) {
		GQuark d;
		if (0 != (d = g_quark_try_string (class)))
			info = error_info_from_domain (d);
	}
	if (info) {
		/* this is rather wasteful, as it converts one way and
		 * then back, but that effectively launders everything
		 * for us. */
		GError error;
		error.domain = info->domain;
		error.code = gperl_convert_enum (info->error_enum, code);
		error.message = (gchar*)message;
		RETVAL = gperl_sv_from_gerror (&error);
	} else {
		warn ("%s is neither a Glib::Error derivative nor a valid GError domain",
		      class);
		RETVAL = newSVGChar (message);
	}
	if (ix == 1) {
		/* go ahead and throw it. */
		SvSetSV (ERRSV, RETVAL);
		croak (Nullch);
	}
    OUTPUT:
	RETVAL


=for apidoc __function__
=for arg package class name to register as a Glib::Error.
=for arg enum_package class name of the enum type to use for this domain's error codes.
Register a new error domain.  Glib::Error will be added @I<package>::ISA for
you.  I<enum_package> must be a valid Glib::Enum type, either from a C library
or registered with C<< Glib::Type::register_enum >>.  After registering an
error domain, you can create or throw exceptions of this type.
=cut
void
register (char * package, char * enum_package)
    PREINIT:
	GQuark qdomain;
	GType enum_type;
    CODE:
	enum_type = gperl_fundamental_type_from_package (enum_package);
	if (!enum_type)
		croak ("%s is not registered as a Glib enum", enum_package);

	ENTER;
	SAVESPTR (DEFSV);
	sv_setpv (DEFSV, package);
	eval_pv ("$_ = lc $_; s/::/-/g;", G_VOID);
	qdomain = g_quark_from_string (SvPV_nolen (DEFSV));
	LEAVE;

	gperl_register_error_domain (qdomain, enum_type, package);


=for apidoc
Returns true if the exception in I<$error> matches the given I<$domain> and
I<$code>.  I<$domain> may be a class name or domain quark (that is, the real
string used in C).  I<$code> may be an integer value or an enum nickname;
the enum type depends on the value of I<$domain>.
=cut
gboolean
matches (SV * error, const char * domain, SV * code)
    PREINIT:
	GError * real_error;
	ErrorInfo * info;
	int real_code;
    CODE:
	gperl_gerror_from_sv (error, &real_error);
	info = error_info_from_package (domain);
	if (!info) {
		GQuark q = g_quark_try_string (domain);
		if (!q)
			croak ("%s is not a valid error domain", domain);
		info = error_info_from_domain (q);
	}
	if (!info)
		croak ("%s is not a registered error domain", domain);
	real_code = looks_like_number (code)
	          ? SvIV (code)
	          : gperl_convert_enum (info->error_enum, code);
	RETVAL = g_error_matches (real_error, info->domain, real_code);
	if (real_error)
		g_error_free (real_error);
    OUTPUT:
	RETVAL

