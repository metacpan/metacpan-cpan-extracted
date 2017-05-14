# ----------------------------------------------------------------------
# NAME       : BibTeX.pm
# DESCRIPTION: Code for the LaTeX::BibTeX module; loads up everything 
#              needed for parsing BibTeX files (both Perl and C code).
# CREATED    : February 1997, Greg Ward
# MODIFIED   : 
# VERSION    : $Id: BibTeX.pm,v 1.27 2000/03/23 02:08:40 greg Rel $
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.
#
#              This file is part of the LaTeX::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

package LaTeX::BibTeX;

require 5.004;                          # needed for LaTeX::BibTeX::Entry

use strict;
use UNIVERSAL qw(isa can);              # for 'check_class' subroutine
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
%EXPORT_TAGS = (nodetypes => [qw(BTAST_STRING BTAST_MACRO BTAST_NUMBER)],
                metatypes => [qw(BTE_UNKNOWN BTE_REGULAR BTE_COMMENT 
                                 BTE_PREAMBLE BTE_MACRODEF)],
                nameparts => [qw(BTN_FIRST BTN_VON BTN_LAST BTN_JR BTN_NONE)],
                joinmethods => [qw(BTJ_MAYTIE BTJ_SPACE 
                                   BTJ_FORCETIE BTJ_NOTHING)],
                subs      => [qw(bibloop split_list
                                 purify_string change_case)],
                macrosubs => [qw(add_macro_text
                                 delete_macro
                                 delete_all_macros
                                 macro_length
                                 macro_text)]);
@EXPORT_OK = (@{$EXPORT_TAGS{'subs'}},
              @{$EXPORT_TAGS{'macrosubs'}},
              @{$EXPORT_TAGS{'nodetypes'}},
              @{$EXPORT_TAGS{'nameparts'}},
              @{$EXPORT_TAGS{'joinmethods'}},
              'check_class', 'display_list');
@EXPORT = @{$EXPORT_TAGS{'metatypes'}};

=head1 NAME

LaTeX::BibTeX - interface to read and parse BibTeX files

=head1 SYNOPSIS

   use LaTeX::BibTeX;

   $bibfile = new LaTeX::BibTeX::File "foo.bib";
   $newfile = new LaTeX::BibTeX::File ">newfoo.bib";

   while ($entry = new LaTeX::BibTeX::Entry $bibfile)
   {
      next unless $entry->parse_ok;

         .             # hack on $entry contents, using various
         .             # LaTeX::BibTeX::Entry methods
         .

      $entry->write ($newfile);
   }

=head1 DESCRIPTION

The C<LaTeX::BibTeX> module serves mainly as a high-level introduction to
the C<LaTeX::BibTeX> library, for both code and documentation purposes.
The code loads the two fundamental modules for processing BibTeX files
(C<LaTeX::BibTeX::File> and C<LaTeX::BibTeX::Entry>), and this
documentation gives a broad overview of the whole library that isn't
available in the documentation for the individual modules that comprise
it.

In addition, the C<LaTeX::BibTeX> module provides a number of
miscellaneous functions that are useful in processing BibTeX data
(especially the kind that comes from bibliographies as defined by BibTeX
0.99, rather than generic database files).  These functions don't
generally fit in the object-oriented class hierarchy centred around the
C<LaTeX::BibTeX::Entry> class, mainly because they are specific to
bibliographic data and operate on generic strings (rather than being
tied to a particular BibTeX entry).  These are also documented here, in
L<"MISCELLANEOUS FUNCTIONS">.

Note that every module described here begins with the C<LaTeX::BibTeX>
prefix.  For brevity, I have dropped this prefix from most class and
module names in the rest of this manual page (and in most of the other
manual pages in the library).

=head1 MODULES AND CLASSES

The C<LaTeX::BibTeX> library includes a number of modules, many of which
provide classes.  Usually, the relationship is simple and obvious: a
module provides a class of the same name---for instance, the
C<LaTeX::BibTeX::Entry> module provides the C<LaTeX::BibTeX::Entry> class.
There are a few exceptions, though: most obviously, the C<LaTeX::BibTeX>
module doesn't provide any classes itself, it merely loads two modules
(C<LaTeX::BibTeX::Entry> and C<LaTeX::BibTeX::File>) that do.  The other
exceptions are mentioned in the descriptions below, and discussed in
detail in the documentation for the respective modules.

The modules are presented roughly in order of increasing specialization:
the first three are essential for any program that processes BibTeX data
files, regardless of what kind of data they hold.  The later modules are
specialized for use with bibliographic databases, and serve both to
emulate BibTeX 0.99's standard styles and to provide an example of how
to define a database structure through such specialized modules.  Each
module is fully documented in its respective manual page.

=over 4

=item C<LaTeX::BibTeX>

Loads the two fundamental modules (C<Entry> and C<File>), and provides a
number of miscellaneous functions that don't fit anywhere in the class
hierarchy.

=item C<LaTeX::BibTeX::File>

Provides an object-oriented interface to BibTeX database files.  In
addition to the obvious attributes of filename and filehandle, the
"file" abstraction manages properties such as the database structure and
options for it.

=item C<LaTeX::BibTeX::Entry>

Provides an object-oriented interface to BibTeX entries, which can be
parsed from C<File> objects, arbitrary filehandles, or strings.  Manages
all the properties of a single entry: type, key, fields, and values.
Also serves as the base class for the I<structured entry classes>
(described in detail in L<LaTeX::BibTeX::Structure>).

=item C<LaTeX::BibTeX::Value>

Provides an object-oriented interface to I<values> and I<simple values>,
high-level constructs that can be used to represent the strings
associated with each field in an entry.  Normally, field values are
returned simply as Perl strings, with macros expanded and multiple
strings "pasted" together.  If desired, you can instruct C<LaTeX::BibTeX>
to return C<LaTeX::BibTeX::Value> objects, which give you access to the
original form of the data.

=item C<LaTeX::BibTeX::Structure>

Provides the C<Structure> and C<StructuredEntry> classes, which serve
primarily as base classes for the two kinds of classes that define
database structures.  Read this man page for a comprehensive description
of the mechanism for implementing Perl classes analogous to BibTeX
"style files".

=item C<LaTeX::BibTeX::Bib>

Provides the C<BibStructure> and C<BibEntry> classes, which serve two
purposes: they fulfill the same role as the standard style files of
BibTeX 0.99, and they give an example of how to write new database
structures.  These ultimately derive from, respectively, the
C<Structure> and C<StructuredEntry> classes provided by the C<Structure>
module.

=item C<LaTeX::BibTeX::BibSort>

One of the C<BibEntry> class's base classes: handles the generation of
sort keys for sorting prior to output formatting.

=item C<LaTeX::BibTeX::BibFormat>

One of the C<BibEntry> class's base classes: handles the formatting of
bibliographic data for output in a markup language such as LaTeX.

=item C<LaTeX::BibTeX::Name>

A class used by the C<Bib> structure and specific to bibliographic data
as defined by BibTeX itself: parses individual author names into
"first", "von", "last", and "jr" parts.

=item C<LaTeX::BibTeX::NameFormat>

Also specific to bibliographic data: puts split-up names (as parsed by
the C<Name> class) back together in a custom way.

=back

For a first time through the library, you'll probably want to confine
your reading to L<LaTeX::BibTeX::File> and L<LaTeX::BibTeX::Entry>.  The
other modules will come in handy eventually, especially if you need to
emulate BibTeX in a fairly fine grained way (e.g. parsing names,
generating sort keys).  But for the simple database hacks that are the
bread and butter of the C<LaTeX::BibTeX> library, the C<File> and
C<Entry> classes are the bulk of what you'll need.  You may also find
some of the material in this manual page useful, namely L<"CONSTANT
VALUES"> and L<"UTILITY FUNCTIONS">.

=cut

sub AUTOLOAD
{
   # This AUTOLOAD is used to 'autoload' constants from the constant()
   # XS function.

#   print "AUTOLOAD: \$AUTOLOAD=$AUTOLOAD\n";

   my ($constname, $ok, $val);
   ($constname = $AUTOLOAD) =~ s/.*:://;
   carp ("Recursive AUTOLOAD--probable compilation error"), return
      if $constname eq 'constant';
   $val = constant ($constname)
      if $constname =~ /^BT/;
   croak ("Unknown LaTeX::BibTeX function: \"$constname\"")
      unless (defined $val);
   
#   print "          constant ($constname) returned \"$val\"\n";

   eval "sub $AUTOLOAD { $val }";
   $val;
}

# Load the two fundamental classes in the LaTeX::BibTeX hierarchy
require LaTeX::BibTeX::File;
require LaTeX::BibTeX::Entry;

# Load the XSUB code that's needed to parse BibTeX entries and 
# the strings in them
bootstrap LaTeX::BibTeX;

# For the curious: I don't put the call to &initialize into a BEGIN block,
# because then it would come before the bootstrap above, and &initialize is
# XS code -- bad!  (The manifestation of this error is rather interesting:
# Perl calls my AUTOLOAD routine, which then tries to call `constant', but
# that's also an as-yet-unloaded XS routine, so it falls back to AUTOLOAD,
# which tries to call `constant' again, ad infinitum.  The moral of the
# story: beware of what you put in BEGIN blocks in XS-dependent modules!)

&initialize;                            # these are both XS functions
END { &cleanup; }


=head1 EXPORTS

The C<LaTeX::BibTeX> module has a number of optional exports, most of
them constant values described in L<"CONSTANT VALUES"> below.  The
default exports are a subset of these constant values that are used
particularly often, the "entry metatypes" (also accessible via the
export tag C<metatypes>).  Thus, the following two lines are equivalent:

   use LaTeX::BibTeX;
   use LaTeX::BibTeX qw(:metatypes);

Some of the various subroutines provided by the module are also
exportable.  C<bibloop>, C<split_list>, C<purify_string>, and
C<change_case> are all useful in everyday processing of BibTeX data, but
don't really fit anywhere in the class hierarchy.  They may be imported
from C<LaTeX::BibTeX> using the C<subs> export tag.  C<check_class> and
C<display_list> are also exportable, but only by name; they are not
included in any export tag.  (These two mainly exist for use by other
modules in the library.)  For instance, to use C<LaTeX::BibTeX> and
import the entry metatype constants and the common subroutines:

   use LaTeX::BibTeX qw(:metatypes :subs);

Another group of subroutines exists for direct manipulation of the macro
table maintained by the underlying C library.  These functions (see
L<"Macro table functions">, below) allow you to define, delete, and
query the value of BibTeX macros (or "abbreviations").  They may be
imported I<en masse> using the C<macrosubs> export tag:

   use LaTeX::BibTeX qw(:macrosubs);

=head1 CONSTANT VALUES

The C<LaTeX::BibTeX> module makes a number of constant values available.
These correspond to the values of various enumerated types in the
underlying C library, B<btparse>, and their meanings are more fully
explained in the B<btparse> documentation.  

Each group of constants is optionally exportable using an export tag
given in the descriptions below.

=over 4

=item Entry metatypes

C<BTE_UNKNOWN>, C<BTE_REGULAR>, C<BTE_COMMENT>, C<BTE_PREAMBLE>,
C<BTE_MACRODEF>.  The C<metatype> method in the C<Entry> class always
returns one of these values.  The latter three describe, respectively,
C<comment>, C<preamble>, and C<string> entries; C<BTE_REGULAR> describes
all other entry types.  C<BTE_UNKNOWN> should never be seen (it's mainly
useful for C code that might have to detect half-baked data structures).
See also L<btparse>.  Export tag: C<metatypes>.

=item AST node types

C<BTAST_STRING>, C<BTAST_MACRO>, C<BTAST_NUMBER>.  Used to distinguish
the three kinds of simple values---strings, macros, and numbers.  The
C<SimpleValue> class' C<type> method always returns one of these three
values.  See also L<LaTeX::BibTeX::Value>, L<btparse>.  Export tag:
C<nodetypes>.

=item Name parts

C<BTN_FIRST>, C<BTN_VON>, C<BTN_LAST>, C<BTN_JR>, C<BTN_NONE>.  Used to
specify the various parts of a name after it has been split up.  These
are mainly useful when using the C<NameFormat> class.  See also
L<bt_split_names> and L<bt_format_names>.  Export tag: C<nameparts>.

=item Join methods

C<BTJ_MAYTIE>, C<BTJ_SPACE>, C<BTJ_FORCETIE>, C<BTJ_NOTHING>.  Used to
tell the C<NameFormat> class how to join adjacent tokens together; see
L<LaTeX::BibTeX::NameFormat> and L<bt_format_names>.  Export tag:
C<joinmethods>.

=back

=head1 UTILITY FUNCTIONS

C<LaTeX::BibTeX> provides several functions that operate outside of the
normal class hierarchy.  Of these, only C<bibloop> is likely to be of
much use to you in writing everyday BibTeX-hacking programs; the other
two (C<check_class> and C<display_list>) are mainly provided for the use
of other modules in the library.  They are documented here mainly for
completeness, but also because they might conceivably be useful in other
circumstances.

=over 4

=item bibloop (ACTION, FILES [, DEST])

Loops over all entries in a set of BibTeX files, performing some
caller-supplied action on each entry.  FILES should be a reference to
the list of filenames to process, and ACTION a reference to a subroutine
that will be called on each entry.  DEST, if given, should be a
C<LaTeX::BibTeX::File> object (opened for output) to which entries might
be printed.

The subroutine referenced by ACTION is called with exactly one argument:
the C<LaTeX::BibTeX::Entry> object representing the entry currently being
processed.  Information about both the entry itself and the file where
it originated is available through this object; see
L<LaTeX::BibTeX::Entry>.  The ACTION subroutine is only called if the
entry was successfully parsed; any syntax errors will result in a
warning message being printed, and that entry being skipped.  Note that
I<all> successfully parsed entries are passed to the ACTION subroutine,
even C<preamble>, C<string>, and C<comment> entries.  To skip these
pseudo-entries and only process "regular" entries, then your action
subroutine should look something like this:

   sub action {
      my $entry = shift;
      return unless $entry->metatype == BTE_REGULAR;
      # process $entry ...
   }

If your action subroutine needs any more arguments, you can just create
a closure (anonymous subroutine) as a wrapper, and pass it to
C<bibloop>:

   sub action {
      my ($entry, $extra_stuff) = @_;
      # ...
   }

   my $extra = ...;
   LaTeX::BibTeX::bibloop (sub { &action ($_[0], $extra) }, \@files);

If the ACTION subroutine returns a true value and DEST was given, then
the processed entry will be written to DEST.

=cut

# ----------------------------------------------------------------------
# NAME       : bibloop
# INPUT      : $action
#              $files
#              $dest
# OUTPUT     : 
# RETURNS    : 
# DESCRIPTION: Loops over all entries in a set of files, calling
#              &$action on each one.
# CREATED    : summer 1996 (in original Bibtex.pm module)
# MODIFIED   : May 1997 (added to LaTeX::BibTeX with revisions)
#              Feb 1998 (simplified and documented)
# ----------------------------------------------------------------------
sub bibloop (&$;$)
{
   my ($action, $files, $dest) = @_;

   my $file;
   while ($file = shift @$files)
   {
      my $bib = new LaTeX::BibTeX::File $file;
      
      while (! $bib->eof())
      {
         my $entry = new LaTeX::BibTeX::Entry $bib;
         next unless $entry->parse_ok;

         my $result = &$action ($entry);
         $entry->write ($dest, 1)
            if ($result && $dest)
      }
   }
}

=item check_class (PACKAGE, DESCRIPTION, SUPERCLASS, METHODS)

Ensures that a PACKAGE implements a class meeting certain requirements.
First, it inspects Perl's symbol tables to ensure that a package named
PACKAGE actually exists.  Then, it ensures that the class named by
PACKAGE derives from SUPERCLASS (using the universal method C<isa>).
This derivation might be through multiple inheritance, or through
several generations of a class hierarchy; the only requirement is that
SUPERCLASS is somewhere in PACKAGE's tree of base classes.  Finally, it
checks that PACKAGE provides each method listed in METHODS (a reference
to a list of method names).  This is done with the universal method
C<can>, so the methods might actually come from one of PACKAGE's base
classes.

DESCRIPTION should be a brief string describing the class that was
expected to be provided by PACKAGE.  It is used for generating warning
messages if any of the class requirements are not met.

This is mainly used by the supervisory code in
C<LaTeX::BibTeX::Structure>, to ensure that user-supplied structure
modules meet the rules required of them.

=cut

# ----------------------------------------------------------------------
# NAME       : check_class
# INPUT      : $package - the name of a package that is expected to exist
#              $description 
#                       - string describing what the package is
#              $superclass
#                       - a package name from which $package is expected
#                         to inherit
#              $methods - ref to list of method names expected to be
#                         available via $package (possibly through
#                         inheritance)
# OUTPUT     : 
# RETURNS    : 
# DESCRIPTION: Makes sure that a package named by $package exists 
#              (by following the chain of symbol tables starting
#              at %::)  Dies if not.
# CALLERS    : LaTeX::BibTeX::Structure::new
# CREATED    : 1997/09/09, GPW
# MODIFIED   : 
# ----------------------------------------------------------------------
sub check_class
{
   my ($package, $description, $superclass, $methods) = @_;
   my (@components, $component, $prev_symtab);

   @components = split ('::', $package);
   $prev_symtab = \%::;
   while (@components)
   {
      $component = (shift @components) . '::';
      unless (defined ($prev_symtab = $prev_symtab->{$component}))
      {
         die "LaTeX::BibTeX::Structure: $description " .
             "\"$package\" apparently not supplied\n";
      }
   }

   if ($superclass && ! isa ($package, $superclass))
   {
      die "LaTeX::BibTeX::Structure: $description \"$package\" " .
          "improperly defined: ! isa ($superclass)\n";
   }

   my $method;
   for $method (@$methods)
   {
      unless (can ($package, $method))
      {
         die "LaTeX::BibTeX::Structure: $description \"$package\" " .
             "improperly defined: no method \"$method\"\n";
      }
   }      
}  # &check_class


=item display_list (LIST, QUOTE)

Converts a list of strings to the grammatical conventions of a human
language (currently, only English rules are supported).  LIST must be a
reference to a list of strings.  If this list is empty, the empty string
is returned.  If it has one element, then just that element is
returned.  If it has two elements, then they are joined with the string
C<" and "> and the resulting string is returned.  Otherwise, the list
has I<N> elements for I<N> E<gt>= 3; elements 1..I<N>-1 are joined with
commas, and the final element is tacked on with an intervening 
C<", and ">.

If QUOTE is true, then each string is encased in single quotes before
anything else is done.

This is used elsewhere in the library for two very distinct purposes:
for generating warning messages describing lists of fields that should
be present or are conflicting in an entry, and for generating lists of
author names in formatted bibliographies.

=cut

# ----------------------------------------------------------------------
# NAME       : display_list
# INPUT      : $list - reference to list of strings to join
#              $quote - if true, they will be single-quoted before join
# OUTPUT     : 
# RETURNS    : elements of @$list, joined together into a single string
#              with commas and 'and' as appropriate
# DESCRIPTION: Formats a list of strings for display as English text.
# CALLERS    : LaTeX::BibTeX::Structure::check_interacting_fields
# CALLS      : 
# CREATED    : 1997/09/23, GPW
# MODIFIED   : 
# ----------------------------------------------------------------------
sub display_list
{
   my ($list, $quote) = @_;
   my @list;

   return '' if @$list == 0;
   @list = $quote ? map { "'$_'" } @$list : @$list;
   return $list[0] if @list == 1;
   return $list[0] . ' and ' . $list[1] if @list == 2;
   return join (', ', @list[0 .. ($#list-1)]) . ', and ' . $list[-1];
}


=back

=head1 MISCELLANEOUS FUNCTIONS

In addition to loading the C<File> and C<Entry> modules, C<LaTeX::BibTeX>
loads the XSUB code which bridges the Perl modules to the underlying C
library, B<btparse>.  This XSUB code provides a number of miscellaneous
utility functions, most of which are put into other packages in the
C<LaTeX::BibTeX> family for use by the corresponding classes.  (For
instance, the XSUB code loaded by C<LaTeX::BibTeX> provides a function
C<LaTeX::BibTeX::Entry::parse>, which is actually documented as the
C<parse> method of the C<LaTeX::BibTeX::Entry> class---see
L<LaTeX::BibTeX::Entry>.  However, for completeness this function---and
all the other functions that become available when you C<use
LaTeX::BibTeX>---are at least mentioned here.  The only functions from
this group that you're ever likely to use are described in L<"Generic
string-processing functions">.

=head2 Startup/shutdown functions

These just initialize and shutdown the underlying C library.  Don't call
either one of them; the C<LaTeX::BibTeX> startup/shutdown code takes care
of it as appropriate.  They're just mentioned here for completeness.

=over 4 

=item initialize ()

=item cleanup ()

=back

=head2 Generic string-processing functions

=over 4

=item split_list (STRING, DELIM [, FILENAME [, LINE [, DESCRIPTION]]])

Splits a string on a fixed delimiter according to the BibTeX rules for
splitting up lists of names.  With BibTeX, the delimiter is hard-coded
as C<"and">; here, you can supply any string.  Instances of DELIM in
STRING are considered delimiters if they are at brace-depth zero,
surrounded by whitespace, and not at the beginning or end of STRING; the
comparison is case-insensitive.  See L<bt_split_names> for full details
of how splitting is done (it's I<not> the same as Perl's C<split>
function).

Returns the list of strings resulting from splitting STRING on DELIM.

=item purify_string (STRING [, OPTIONS])

"Purifies" STRING in the BibTeX way (usually for generation of sort
keys).  See L<bt_misc> for details; note that, unlike the C interface,
C<purify_string> does I<not> modify STRING in-place.  A purified copy of
the input string is returned.

OPTIONS is currently unused.

=item change_case (TRANFORM, STRING [, OPTIONS])

Transforms the case of STRING according to TRANSFORM (a single
character, one of C<'u'>, C<'l'>, or C<'t'>).  See L<bt_misc> for
details; again, C<change_case> differs from the C interface in that
STRING is not modified in-place---the input string is copied, and the
transformed copy is returned.

=back

=head2 Entry-parsing functions

Although these functions are provided by the C<LaTeX::BibTeX> module,
they are actually in the C<LaTeX::BibTeX::Entry> package.  That's because
they are implemented in C, and thus loaded with the XSUB code that
C<LaTeX::BibTeX> loads; however, they are actually methods in the
C<LaTeX::BibTeX::Entry> class.  Thus, they are documented as methods in
L<LaTeX::BibTeX::Entry>.

=over 4

=item parse (ENTRY_STRUCT, FILENAME, FILEHANDLE)

=item parse_s (ENTRY_STRUCT, TEXT)

=back

=head2 Macro table functions

These functions allow direct access to the macro table maintained by
B<btparse>, the C library underlying C<LaTeX::BibTeX>.  In the normal
course of events, macro definitions always accumulate, and are only
defined as a result of parsing a macro definition (C<@string>) entry.
B<btparse> never deletes old macro definitions for you, and doesn't have
any built-in default macros.  If, for example, you wish to start fresh
with new macros for every file, use C<delete_all_macros>.  If you wish
to pre-define certain macros, use C<add_macro_text>.  (But note that the
C<Bib> structure, as part of its mission to emulate BibTeX 0.99, defines
the standard "month name" macros for you.)

See also L<bt_macros> in the B<btparse> documentation for a description
of the C interface to these functions.

=over 4

=item add_macro_text (MACRO, TEXT [, FILENAME [, LINE]])

Defines a new macro, or redefines an old one.  MACRO is the name of the
macro, and TEXT is the text it should expand to.  FILENAME and LINE are
just used to generate any warnings about the macro definition.  The only
such warning occurs when you redefine an old macro: its value is
overridden, and C<add_macro_text()> issues a warning saying so.

=item delete_macro (MACRO)

Deletes a macro from the macro table.  If MACRO isn't defined,
takes no action.

=item delete_all_macros ()

Deletes all macros from the macro table.

=item macro_length (MACRO)

Returns the length of a macro's expansion text.  If the macro is
undefined, returns 0; no warning is issued.

=item macro_text (MACRO [, FILENAME [, LINE]])    

Returns the expansion text of a macro.  If the macro is not defined,
issues a warning and returns C<undef>.  FILENAME and LINE, if supplied,
are used for generating this warning; they should be supplied if you're
looking up the macro as a result of finding it in a file.

=back

=head2 Name-parsing functions

These are both private functions for the use of the C<Name> class, and
therefore are put in the C<LaTeX::BibTeX::Name> package.  You should use
the interface provided by that class for parsing names in the BibTeX
style.

=over 4

=item _split (NAME_STRUCT, NAME, FILENAME, LINE, NAME_NUM, KEEP_CSTRUCT)

=item free (NAME_STRUCT)

=back

=head2 Name-formatting functions

These are private functions for the use of the C<NameFormat> class, and
therefore are put in the C<LaTeX::BibTeX::NameFormat> package.  You
should use the interface provided by that class for formatting names in
the BibTeX style.

=over 4

=item create ([PARTS [, ABBREV_FIRST]])

=item free (FORMAT_STRUCT)

=item _set_text (FORMAT_STRUCT, PART, PRE_PART, POST_PART, PRE_TOKEN, POST_TOKEN)

=item _set_options (FORMAT_STRUCT, PART, ABBREV, JOIN_TOKENS, JOIN_PART)

=item format_name (NAME_STRUCT, FORMAT_STRUCT)

=back

=head1 BUGS AND LIMITATIONS

C<LaTeX::BibTeX> inherits several limitations from its base C library,
B<btparse>; see L<btparse/BUGS AND LIMITATIONS> for details.  In addition,
C<LaTeX::BibTeX> will not work with a Perl binary built using the C<sfio>
library.  This is because Perl's I/O abstraction layer does not extend to
third-party C libraries that use stdio, and B<btparse> most certainly does
use stdio.

=head1 SEE ALSO

L<btool_faq>, L<LaTeX::BibTeX::File>, L<LaTeX::BibTeX::Entry>,
L<LaTeX::BibTeX::Value>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the LaTeX::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The btOOL home page, where you can get up-to-date information about
C<LaTeX::BibTeX> (and download the latest version) is

   http://starship.python.net/~gward/btOOL/

You will also find the latest version of B<btparse>, the C library
underlying C<LaTeX::BibTeX>, there.  B<btparse> is needed to build
C<LaTeX::BibTeX>, and must be downloaded separately.

Both libraries are also available on CTAN (the Comprehensive TeX Archive
Network, C<http://www.ctan.org/tex-archive/>) and CPAN (the Comprehensive
Perl Archive Network, C<http://www.cpan.org/>).  Look in
F<biblio/bibtex/utils/btOOL/> on CTAN, and F<authors/Greg_Ward/> on
CPAN.  For example,

   http://www.ctan.org/tex-archive/biblio/bibtex/utils/btOOL/
   http://www.cpan.org/authors/Greg_Ward

will both get you to the latest version of C<LaTeX::BibTeX> and B<btparse>
-- but of course, you should always access busy sites like CTAN and CPAN
through a mirror.

=cut

1;
