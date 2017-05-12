package Gtk2::CodeGen;

use strict;
use warnings;
use Carp;
use IO::File;
use base 'Glib::CodeGen';

our $VERSION = '0.03';


Glib::CodeGen->add_type_handler (GtkObject => \&gen_gtkobject_stuff);

Glib::CodeGen->add_type_handler (GEnumAlias => \&gen_fundamental_alias_stuff);
Glib::CodeGen->add_type_handler (GFlagsAlias => \&gen_fundamental_alias_stuff);
Glib::CodeGen->add_type_handler (GBoxedAlias => \&gen_boxed_alias_stuff);
Glib::CodeGen->add_type_handler (GObjectAlias => \&gen_object_alias_stuff);
Glib::CodeGen->add_type_handler (GInterfaceAlias => \&gen_object_alias_stuff);


=head1 NAME

Gtk2::CodeGen - code generation utilities for Glib-based bindings.

=head1 SYNOPSIS

 # usually in Makefile.PL
 use Gtk2::CodeGen;

 # most common, use all defaults
 Gtk2::CodeGen->parse_maps ('myprefix');
 Gtk2::CodeGen->write_boot;

 # more exotic, change everything
 Gtk2::CodeGen->parse_maps ('foo',
                            input => 'foo.maps',
                            header => 'foo-autogen.h',
                            typemap => 'foo.typemap',
                            register => 'register-foo.xsh');
 Gtk2::CodeGen->write_boot (filename => 'bootfoo.xsh',
                            glob => 'Foo*.xs',
                            ignore => '^(Foo|Foo::Bar)$');
 
=head1 DESCRIPTION

This module packages some of the boilerplate code needed for performing code
generation typically used by perl bindings for gobject-based libraries, using
the Glib module as a base.

The default output filenames are in the subdirectory 'build', which usually
will be present if you are using ExtUtils::Depends (as most Glib-based
extensions probably should).

=head2 METHODS

=over

=item Gtk2::CodeGen->write_boot;

=item Gtk2::CodeGen->write_boot (KEY => VAL, ...)

Many GObject-based libraries to be bound to perl will be too large to put in
a single XS file; however, a single PM file typically only bootstraps one
XS file's code.  C<write_boot> generates an XSH file to be included from
the BOOT section of that one bootstrapped module, calling the boot code for
all the other XS files in the project.

Options are passed to the function in a set of key/val pairs, and all options
may default.

  filename     the name of the output file to be created.
               the default is 'build/boot.xsh'.

  glob         a glob pattern that specifies the names of
               the xs files to scan for MODULE lines.
               the default is 'xs/*.xs'.

  xs_files     use this to supply an explicit list of file
               names (as an array reference) to use instead
               of a glob pattern.  the default is to use
               the glob pattern.

  ignore       regular expression matching any and all 
               module names which should be ignored, i.e.
               NOT included in the list of symbols to boot.
               this parameter is extremely important for
               avoiding infinite loops at startup; see the
               discussion for an explanation and rationale.
               the default is '^[^:]+$', or, any name that
               contains no colons, i.e., any toplevel
               package name.


This function performs a glob (using perl's builtin glob operator) on the
pattern specified by the 'glob' option to retrieve a list of file names.
It then scans each file in that list for lines matching the pattern
"^MODULE" -- that is, the MODULE directive in an XS file.  The module
name is pulled out and matched against the regular expression specified
by the ignore parameter.  If this module is not to be ignored, we next
check to see if the name has been seen.  If not, the name will be converted
to a boot symbol (basically, s/:/_/ and prepend "boot_") and this symbol
will be added to a call to GPERL_CALL_BOOT in the generated file; it is then
marked as seen so we don't call it again.


What is this all about, you ask?  In order to bind an XSub to perl, the C
function must be registered with the interpreter.  This is the function of the
"boot" code, which is typically called in the bootstrapping process.  However,
when multiple XS files are used with only one PM file, some other mechanism
must call the boot code from each XS file before any of the function therein
will be available.

A typical setup for a multiple-XS, single-PM module will be to call the 
various bits of boot code from the BOOT: section of the toplevel module's
XS file.

To use Gtk2 as an example, when you do 'use Gtk2', Gtk2.pm calls bootstrap
on Gtk2, which calls the C function boot_Gtk2.  This function calls the
boot symbols for all the other xs files in the module.  The distinction
is that the toplevel module, Gtk2, has no colons in its name.


C<xsubpp> generates the boot function's name by replacing the 
colons in the MODULE name with underscores and prepending "boot_".
We need to be careful not to include the boot code for the bootstrapped module,
(say Toplevel, or Gtk2, or whatever) because the bootstrap code in 
Toplevel.pm will call boot_Toplevel when loaded, and boot_Toplevel
should actually include the file we are creating here.

The default value for the ignore parameter ignores any name not containing
colons, because it is assumed that this will be a toplevel module, and any
other packages/modules it boots will be I<below> this namespace, i.e., they
will contain colons.  This assumption holds true for Gtk2 and Gnome2, but
obviously fails for something like Gnome2::Canvas.  To boot that module
properly, you must use a regular expression such as "^Gnome2::Canvas$".

Note that you can, of course, match more than just one name, e.g.
"^(Foo|Foo::Bar)$", if you wanted to have Foo::Bar be included in the same
dynamically loaded object but only be booted when absolutely necessary.
(If you get that to work, more power to you.)

Also, since this code scans for ^MODULE, you must comment the MODULE section
out with leading # marks if you want to hide it from C<write_boot>.

=cut

# sub write_boot is inherited from Glib::CodeGen.


=item Gtk2::CodeGen->parse_maps (PREFIX, [KEY => VAL, ...])

Convention within Glib/Gtk2 and friends is to use preprocessor macros in the
style of SvMyType and newSVMyType to get values in and out of perl, and to
use those same macros from both hand-written code as well as the typemaps.
However, if you have a lot of types in your library (such as the nearly 200
types in Gtk+ 2.x), then writing those macros becomes incredibly tedious, 
especially so when you factor in all of the variants and such.

So, this function can turn a flat file containing terse descriptions of the
types into a header containing all the cast macros, a typemap file using them,
and an XSH file containing the proper code to register each of those types
(to be included by your module's BOOT code).

The I<PREFIX> is mandatory, and is used in some of the resulting filenames,
You can also override the defaults by providing key=>val pairs:

  input    input file name.  default is 'maps'.  if this
           key's value is an array reference, all the
           filenames in the array will be scanned.
  header   name of the header file to create, default is
           build/$prefix-autogen.h
  typemap  name of the typemap file to create, default is
           build/$prefix.typemap
  register name of the xsh file to contain all of the 
           type registrations, default is build/register.xsh

the maps file is a table of type descriptions, one per line, with fields
separated by whitespace.  the fields should be:

  TYPE macro    e.g., GTK_TYPE_WIDGET 
  class name    e.g. GtkWidget, name of the C type
  base type     one of GObject, GBoxed, GEnum, GFlags.
                GtkObject is also supported, but the
                distinction is no longer necessary as
                of Glib 0.26.
  package       name of the perl package to which this
                class name should be mapped, e.g.
                Gtk2::Widget

As a special case, you can also use this same format to register error
domains; in this case two of the four columns take on slightly different
meanings:

  domain macro     e.g., GDK_PIXBUF_ERROR
  enum type macro  e.g., GDK_TYPE_PIXBUF_ERROR
  base type        GError
  package          name of the Perl package to which this
                   class name should be mapped, e.g.,
                   Gtk2::Gdk::Pixbuf::Error.

=cut


# sub parse_maps is inherited from Glib::CodeGen.


#
# GtkObject has different reference-counting semantics than GObject;
# in particular, the _noinc variant is meaningless for GtkObjects,
# as the bindings register gtk_object_sink().
#

sub gen_gtkobject_stuff {
    my ($typemacro, $classname, $root, $package) = @_;

    Glib::CodeGen::add_typemap "$classname *", "T_GPERL_GENERIC_WRAPPER";
    Glib::CodeGen::add_typemap "const $classname *", "T_GPERL_GENERIC_WRAPPER";
    Glib::CodeGen::add_typemap "$classname\_ornull *", "T_GPERL_GENERIC_WRAPPER";
    Glib::CodeGen::add_typemap "const $classname\_ornull *", "T_GPERL_GENERIC_WRAPPER";
    Glib::CodeGen::add_register "#ifdef $typemacro
gperl_register_object ($typemacro, \"$package\");
#endif /* $typemacro */";

    my $get_wrapper = 'gtk2perl_new_gtkobject (GTK_OBJECT (val))';
    Glib::CodeGen::add_header "#ifdef $typemacro
  /* $root derivative $classname */
# define Sv$classname(sv)	(($classname*)gperl_get_object_check (sv, $typemacro))
# define newSV$classname(val)	($get_wrapper)
  typedef $classname $classname\_ornull;
# define Sv$classname\_ornull(sv)	(gperl_sv_is_defined (sv) ? Sv$classname(sv) : NULL)
# define newSV$classname\_ornull(val)	(((val) == NULL) ? &PL_sv_undef : $get_wrapper)
#endif /* $typemacro */
";
}

sub gen_alias_stuff {
	my ($typemacro, $func, $package) = @_;
	Glib::CodeGen::add_register "#ifdef $typemacro
$func ($typemacro, \"$package\");
#endif /* $typemacro */";
}

sub gen_fundamental_alias_stuff {
	my ($typemacro, $classname, $root, $package) = @_;
	gen_alias_stuff ($typemacro, 'gperl_register_fundamental_alias', $package);
}

sub gen_boxed_alias_stuff {
	my ($typemacro, $classname, $root, $package) = @_;
	gen_alias_stuff ($typemacro, 'gperl_register_boxed_alias', $package);
}

sub gen_object_alias_stuff {
	my ($typemacro, $classname, $root, $package) = @_;
	gen_alias_stuff ($typemacro, 'gperl_register_object_alias', $package);
}


=item Gtk2::CodeGen->generate_constants_wrappers (KEY => VAL, ...)

Generates an XS file with XSUB wrappers for C constants.  The key-value pairs
may contain one or more of the following keys:

=over

=item I<prefix>: Specifies the package name the functions should be put into.

=item I<lists>: Reference to an array of filenames which specify the constants
that should be wrapped.

=item I<xs_file>: The name of the XS file that should be created.

=item I<header>: The name of the header file that should be included in the
generated XS file.

=item I<export_tag>: The name of the L<Exporter> tag that should be used for
the constants wrappers.

=back

All of the keys have mostly sane defaults.

Don't forget to add the generated XS file to the list of XS files to be
compiled.

The lists describing the constants to be wrapped should have the following
format:

  CONSTANT_NAME [ \t+ CONSTANT_CONVERTER ]

That is, the constant's name optionally followed by a tab and the converter
that is to be used to convert the constant to a Perl scalar.  If
CONSTANT_CONVERTER is a simple string like 'newSViv' it will be used as follows
to get a Perl scalar: CONSTANT_CONVERTER (CONSTANT_NAME).  If it contains
'$var', as in 'newSVpv ($var, 0)', then '$var' will be replaced with
CONSTANT_NAME and the resulting string will be used for conversion.

The default for CONSTANT_CONVERTER is 'newSViv'.

=cut

sub generate_constants_wrappers {
    my $class = shift @_;

    require File::Spec;
    my %options = (
        prefix => 'Glib',
        lists => ['constants'],
        xs_file => File::Spec->catfile ('build', 'constants.xs'),
        header => 'gperl.h',
        export_tag => 'constants',
        @_,
    );

    my $xsub_code = '';
    my @constants = ();
    foreach my $list (@{ $options{lists} }) {
        open my $list_fh, '<', $list
            or croak "Unable to open `$list´ for reading: $!";

        DESCRIPTION:
        while (my $description = <$list_fh>) {
            chomp $description;

            # skip comments and blanks
            next DESCRIPTION if $description =~ m/\A#|\A\s*\z/;

            my ($constant, $converter) = split /\t+/, $description;
            push @constants, [$constant, $converter];
        }

        close $list_fh
            or croak "Unable to close `$list´: $!";
    }

    my $boot_code = <<"__EOD__";
{
	HV *stash = gv_stashpv ("$options{prefix}", TRUE); /* create if needed */
	HV *tags_hv = get_hv ("$options{prefix}::EXPORT_TAGS", 1);
	AV *constants_av = NULL;
	SV *constants_ref_sv = NULL;
	SV **constants_svp = hv_fetch (tags_hv, "$options{export_tag}", strlen ("$options{export_tag}"), 0);
	if (constants_svp && gperl_sv_is_array_ref (*constants_svp)) {
		constants_av = (AV *) SvRV (*constants_svp);
		constants_ref_sv = *constants_svp;
	} else {
		constants_av = newAV ();
		constants_ref_sv = newRV_noinc ((SV *) constants_av);
	}
__EOD__

    foreach my $pair (@constants) {
        my ($constant, $converter) = @$pair;

        # default to ints
        $converter = 'newSViv' unless defined $converter;

        my $conversion;
        if ($converter =~ m/\$var/) {
            ($conversion = $converter) =~ s/\$var/$constant/;
        } else {
            $conversion = "$converter ($constant)";
        }

        $boot_code .= <<"__EOD__";
	newCONSTSUB (stash, "$constant", $conversion);
	av_push (constants_av, newSVpv ("$constant", 0));
__EOD__
    }

    if (!@constants) {
        $boot_code .= <<'__EOD__';
        PERL_UNUSED_VAR (stash);
__EOD__
    }

    $boot_code .= <<"__EOD__";
	gperl_hv_take_sv_s (tags_hv, "$options{export_tag}", constants_ref_sv);
}
__EOD__

    open my $xs_fh, '>', $options{xs_file}
        or croak "Unable to open `$options{xs_file}´ for writing: $!";

    print $xs_fh <<"__EOD__";
/**
 * This is a generated file.  Do not edit.
 */

#include "$options{header}"

MODULE = $options{prefix}::Constants	PACKAGE = $options{prefix}

BOOT:
$boot_code

__EOD__

    close $xs_fh
        or croak "Unable to close `$options{xs_file}´: $!";
}


1;
__END__

=back

=head1 SEE ALSO

L<Glib::CodeGen> does the actual work; Gtk2::CodeGen is now just a wrapper
which adds support for gtk-specific types.

=head1 AUTHOR

muppet <scott at asofyet dot org>

=head1 COPYRIGHT

Copyright (C) 2003-2005, 2013 by the gtk2-perl team (see the file AUTHORS for
the full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option)
any later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
more details.

You should have received a copy of the GNU Library General Public License
along with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.

=cut
