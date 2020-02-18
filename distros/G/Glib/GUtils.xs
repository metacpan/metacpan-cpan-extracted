/*
 * Copyright (C) 2004-2005 by the gtk2-perl team (see the file AUTHORS for a
 * complete list)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * $Id$
 */
#include "gperl.h"
#include "gperl-gtypes.h"

#if GLIB_CHECK_VERSION (2, 14, 0)

GUserDirectory
SvGUserDirectory (SV *sv)
{
	return gperl_convert_enum (GPERL_TYPE_USER_DIRECTORY, sv);
}

SV *
newSVGUserDirectory (GUserDirectory dir)
{
	return gperl_convert_back_enum (GPERL_TYPE_USER_DIRECTORY, dir);
}

#endif

MODULE = Glib::Utils	PACKAGE = Glib	PREFIX = g_

BOOT:
#if GLIB_CHECK_VERSION (2, 14, 0)
	gperl_register_fundamental (GPERL_TYPE_USER_DIRECTORY,
	                            "Glib::UserDirectory");
#endif

=for object Glib::Utils Miscellaneous utility functions
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  use Glib;
  Glib::set_application_name (Glib::get_real_name."'s Cool Program");

  print "app name is ".Glib::get_application_name()."\n";

=for position DESCRIPTION

=head1 DESCRIPTION

Here are some useful miscellaneous utilities.
GLib is a portability library, providing portable utility functions for
C programs.  As such, most of these functions seem to violate the Glib
binding principle of not duplicating functionality that Perl already
provides, but there's a distinction for each one, i swear.  The functions
for dealing with user information are provided on all GLib-supported
platforms, not just where POSIX (which provides similar information) is
available, and even work on platforms where %ENV may not include the
expected information.  Also, the "application name" referred to by
(set|get)_application_name is a human readable name, distinct from the
actual program name provided by Perl's own $0.

=cut

### FIXME
### we should have a pod section called FUNCTIONS.

=for apidoc Glib::get_real_name __function__
Get the current user's real name.
=cut

=for apidoc Glib::get_home_dir __function__
Find the current user's home directory, by system-dependent/appropriate
means.
=cut

=for apidoc Glib::get_tmp_dir __function__
Get the temp dir as appropriate for the current system.  See the GLib docs
for info on how it works.
=cut

=for apidoc __function__
Get the current user's name by whatever system-dependent means necessary.
=cut
const gchar *
g_get_user_name ()
    ALIAS:
	Glib::get_real_name = 1
	Glib::get_home_dir  = 2
	Glib::get_tmp_dir   = 3
    CODE:
	switch (ix) {
	    case 0: RETVAL = g_get_user_name (); break;
	    case 1: RETVAL = g_get_real_name (); break;
	    case 2: RETVAL = g_get_home_dir ();  break;
	    case 3: RETVAL = g_get_tmp_dir ();   break;
	    default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

#if GLIB_CHECK_VERSION (2, 6, 0)

=for apidoc Glib::get_user_config_dir __function__
Gets the base directory in which to store user-specific application
configuration information such as user preferences and settings.
=cut

=for apidoc Glib::get_user_cache_dir __function__
Gets the base directory in which to store non-essential, cached data specific
to particular user.
=cut

=for apidoc __function__
Get the base directory for application data such as icons that is customized
for a particular user.
=cut
const gchar *
g_get_user_data_dir ()
    ALIAS:
	Glib::get_user_config_dir = 1
	Glib::get_user_cache_dir  = 2
    CODE:
	switch (ix) {
	    case 0: RETVAL = g_get_user_data_dir (); break;
	    case 1: RETVAL = g_get_user_config_dir (); break;
	    case 2: RETVAL = g_get_user_cache_dir (); break;
	    default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

=for apidoc Glib::get_system_config_dirs __function__
Returns an ordered list of base directories in which to access system-wide
configuration information.
=cut

=for apidoc Glib::get_language_names __function__
Computes a list of applicable locale names, which can be used to e.g. construct
locale-dependent filenames or search paths. The returned list is sorted from
most desirable to least desirable and always contains the default locale "C".
=cut

=for apidoc __function__
Returns an ordered list of base directories in which to access system-wide
application data.
=cut
void
g_get_system_data_dirs ()
    ALIAS:
	Glib::get_system_config_dirs = 1
	Glib::get_language_names     = 2
    PREINIT:
	const gchar * const * strings;
	int i;
    PPCODE:
	switch (ix) {
	    case 0: strings = g_get_system_data_dirs ();   break;
	    case 1: strings = g_get_system_config_dirs (); break;
	    case 2: strings = g_get_language_names ();     break;
	    default:
		strings = NULL;
		g_assert_not_reached ();
	}

	for (i = 0; strings[i]; i++)
		XPUSHs (sv_2mortal (newSVGChar (strings[i])));

#endif

#if GLIB_CHECK_VERSION (2, 14, 0)

=for apidoc __function__
Returns the full path of a special directory using its logical id.
=cut
const gchar* g_get_user_special_dir (GUserDirectory directory);

#endif

=for apidoc __function__
=cut
gchar_own * g_get_prgname ();

=for apidoc __function__
=cut
void g_set_prgname (const gchar *prgname);

#if GLIB_CHECK_VERSION(2, 2, 0)

=for apidoc __function__
Get the human-readable application name set by C<set_application_name>.
=cut
const gchar * g_get_application_name ();

=for apidoc __function__
Set the human-readable application name.
=cut
void g_set_application_name (const gchar *application_name);

#endif

###
### This stuff is functionality provided by File::Spec and friends.
### Thus we will not bind it.
###
#gboolean              g_path_is_absolute   (const gchar *file_name);
#G_CONST_RETURN gchar* g_path_skip_root     (const gchar *file_name);
#gchar*                g_get_current_dir    (void);
#gchar*                g_path_get_basename  (const gchar *file_name);
#gchar*                g_path_get_dirname   (const gchar *file_name);
#
#
## Look for an executable in PATH, following execvp() rules
#gchar*  g_find_program_in_path  (const gchar *program);

=for apidoc __function__
Return a string describing the given errno value, like "No such file
or directory" for ENOENT.  This is translated into the user's
preferred language and is a utf8 wide-char string (unlike a $!
string (L<perlvar>) or POSIX::strerror (L<POSIX>) which are locale
codeset bytes).
=cut
## note the returned string can be overwritten by the next call, so must copy
const gchar *g_strerror (gint err);

=for apidoc __function__
Return a string describing the given signal number, like "Segmentation
violation" for SIGSEGV.  This is translated into the user's preferred
language and is a utf8 wide-char string.
=cut
## note the returned string can be overwritten by the next call, so must copy
const gchar *g_strsignal (gint signum);

###
### Version information
###

## this is a ridiculous amount of doc for six numbers and one checker method.

=for object Glib::version Library Versioning Utilities
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  # require at least version 1.021 of the Glib module
  use Glib '1.021';

  # g_set_application_name() was introduced in GLib 2.2.0, and
  # first supported by version 1.040 of the Glib Perl module.
  if ($Glib::VERSION >= 1.040 and Glib->CHECK_VERSION (2,2,0)) {
     Glib::set_application_name ('My Cool Program');
  }

=for position DESCRIPTION

=head1 DESCRIPTION

Both the Glib module and the GLib C library are works-in-progress, and 
their interfaces grow over time.  As more features are added to each, 
and your code uses those new features, you will introduce 
version-specific dependencies, and naturally, you'll want to be able to 
code around them.  Enter the versioning API.

For simple Perl modules, a single version number is sufficient; 
however, Glib is a binding to another software library, and this 
introduces some complexity.  We have three versions that fully specify 
the API available to you.

=over

=item Perl Bindings Version

Perl modules use a version number, and Glib is no exception.  
I<$Glib::VERSION> is the version of the current Glib module.  By ad hoc 
convention, gtk2-perl modules generally use version numbers in the form 
x.yyz, where even yy values denote stable releases and z is a 
patchlevel.

   $Glib::VERSION
   use Glib 1.040; # require at least version 1.040

=item Compile-time ("Bound") Library Version

This is the version of the GLib C library that was available when the 
Perl module was compiled and installed.  These version constants are 
equivalent to the version macros provided in the GLib C headers.  GLib 
uses a major.minor.micro convention, where even minor versions are 
stable.  (gtk2-perl does not officially support unstable versions.)

   Glib::MAJOR_VERSION
   Glib::MINOR_VERSION
   Glib::MICRO_VERSION
   Glib->CHECK_VERSION($maj,$min,$mic)

=item Run-time ("Linked") Library Version

This is the version of the GLib C library that is available at run 
time; it may be newer than the compile-time version, but should never 
be older.  These are equivalent to the version variables exported by 
the GLib C library.

   Glib::major_version
   Glib::minor_version
   Glib::micro_version

=back

=head2 Which one do I use when?

Where do you use which version?  It depends entirely on what you're 
doing.  Let's explain by example:

=over

=item o Use the Perl module version for bindings support issues

You need to register a new enum for use as the type of an object 
property.  This is something you can do with all versions of the 
underlying C library, but which wasn't supported in the Glib Perl 
module until $Glib::VERSION >= 1.040.

=item o Use the bound version for library features

You want to call Glib::set_application_name to set a human-readable name
for your application (which is used by various parts of Gtk2 and Gnome2).
g_set_application_name() (the underlying C function) was added in version
2.2.0 of glib, and support for it was introduced into the Glib Perl module
in Glib version 1.040.  However, you can build the Perl module against any
stable 2.x.x version of glib, so you might not have that function available
even if your Glib module is new enough!
  Thus, you need to check two things to see if the this function is 
available:

   if ($Glib::VERSION >= 1.040 && Glib->CHECK_VERSION (2,2,0)) {
       # it's available, and we can call it!
       Glib::set_application_name ('My Cool Application');
   }

Now what happens if you installed the Perl module when your system had 
glib 2.0.6, and you upgraded glib to 2.4.1?  Wouldn't g_set_application_name() 
be available?  Well, it's there, under the hood, but the bindings were 
compiled when it wasn't there, so you won't be able to call it! 
That's why we check the "bound" or compile-time version.  By the way, to 
enable support for the new function, you'd need to reinstall (or upgrade)
the Perl module.

=item o Use the linked version for runtime work-arounds

Suppose there's a function whose API did not change, but whose 
implementation had a bug in one version that was fixed in another 
version.  To determine whether you need to apply a workaround, you 
would check the version that is actually being used at runtime.

   if (Glib::major_version == 2 &&
       Glib::minor_version == 2 &&
       Glib::micro_version == 1) {
      # work around bug that exists only in glib 2.2.1.
   }

In practice, such situations are very rare.

=back

=cut


=for apidoc Glib::MINOR_VERSION __function__
Provides access to the version information that Glib was compiled against.
Essentially equivalent to the #define's GLIB_MINOR_VERSION.
=cut

=for apidoc Glib::MICRO_VERSION __function__
Provides access to the version information that Glib was compiled against.
Essentially equivalent to the #define's GLIB_MICRO_VERSION.
=cut

=for apidoc Glib::major_version __function__
Provides access to the version information that Glib is linked against.
Essentially equivalent to the global variable glib_major_version.
=cut

=for apidoc Glib::minor_version __function__
Provides access to the version information that Glib is linked against.
Essentially equivalent to the global variable glib_minor_version.
=cut

=for apidoc Glib::micro_version __function__
Provides access to the version information that Glib is linked against.
Essentially equivalent to the global variable glib_micro_version.
=cut

=for apidoc __function__
Provides access to the version information that Glib was compiled against.
Essentially equivalent to the #define's GLIB_MAJOR_VERSION.
=cut
guint
MAJOR_VERSION ()
    ALIAS:
	Glib::MINOR_VERSION = 1
	Glib::MICRO_VERSION = 2
	Glib::major_version = 3
	Glib::minor_version = 4
	Glib::micro_version = 5
    CODE:
	switch (ix)
	{
	case 0: RETVAL = GLIB_MAJOR_VERSION; break;
	case 1: RETVAL = GLIB_MINOR_VERSION; break;
	case 2: RETVAL = GLIB_MICRO_VERSION; break;
	case 3: RETVAL = glib_major_version; break;
	case 4: RETVAL = glib_minor_version; break;
	case 5: RETVAL = glib_micro_version; break;
	default:
		RETVAL = -1;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

=for apidoc
=for signature (MAJOR, MINOR, MICRO) = Glib->GET_VERSION_INFO
Shorthand to fetch as a list the glib version for which Glib was compiled.
See C<Glib::MAJOR_VERSION>, etc.
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (GLIB_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GLIB_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GLIB_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

=for apidoc
Provides a mechanism for checking the version information that Glib was
compiled against. Essentially equvilent to the macro GLIB_CHECK_VERSION.
=cut
gboolean
CHECK_VERSION (class, guint required_major, guint required_minor, guint required_micro)
    CODE:
	RETVAL = GLIB_CHECK_VERSION (required_major, required_minor,
				    required_micro);
    OUTPUT:
	RETVAL

MODULE = Glib::Utils	PACKAGE = Glib::Markup	PREFIX = g_markup_

=for object Glib::Markup markup handling functions
=cut

=for apidoc __function__
=cut
# gchar* g_markup_escape_text (const gchar *text, gssize length);
gchar_own *
g_markup_escape_text (text)
	const gchar* text
    CODE:
	RETVAL = g_markup_escape_text (text, strlen (text));
    OUTPUT:
	RETVAL
