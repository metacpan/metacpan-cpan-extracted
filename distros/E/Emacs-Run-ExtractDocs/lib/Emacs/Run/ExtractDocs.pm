package Emacs::Run::ExtractDocs;
use base qw( Class::Base );

=head1 NAME

Emacs::Run::ExtractDocs - extract elisp docstrings to html form

=head1 SYNOPSIS

   use Emacs::Run::ExtractDocs;
   my $reed = Emacs::Run::ExtractDocs->new({
              html_output_location => "/tmp/html",
   });

   # needed only if extract-docstrings.el isn't in load-path
   $reed->set_main_library("/tmp/new/elisp/extract-doctrings.el");

   $reed->elisp_docstrings_to_html("my-elisp-with-a-lot-of-docstrings.el");

=head1 DESCRIPTION

Emacs::Run::ExtractDocs is a module that provides ways of working
with the "docstrings" from emacs lisp packages and transforming
them to other formats (at present, just html).

The central feature is the elisp_docstrings_to_html method,
which can create a web page displaying the docstrings of any
given elisp package.

Note that this is a very unusual "perl" package, in that it
depends on having emacs installed (most likely, GNU/Emacs).
Also, the extract-docstrings.el file that is shipped with this
perl package must be installed somewhere in the emacs load-path.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util     qw( lock_keys unlock_keys );
use File::Basename qw( fileparse basename dirname );
use Env qw( $HOME );

use Emacs::Run;

our $VERSION = '0.03';
my $DEBUG = 0;  # TODO change to 0 before shipping

# needed for accessor generation
our $AUTOLOAD;
my %ATTRIBUTES = ();

=item new

Creates a new Emacs::Run::ExtractDocs object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item html_output_location

Directory to put generated html.

=item main_library

Defaults to the elisp library name "extract-doctrings",
so the system can find "extract-doctrings.el" once it's
installed in the emacs load_path.

This can be set to a different library name, or more likely
to a full path to the extract-docstrings.el in an unusual
location.  (This is very useful for testing, so that the
code can run before it's installed.)

=item emacs_runner

An Emacs::Run object, used internally to call utility
routines to probe the emacs installation, and run pieces
of emacs lisp code.  This will normally be created automatically,
but if some unusual options are needed, one can be created
externally and passed in as an attribute.

=back

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

=cut

# Note: "new" is inherited from Class::Base and
# calls the following "init" routine automatically.

=item init

Method that initializes object attributes and then locks them
down to prevent accidental creation of new ones.

Any class that inherits from this one should have an B<init> of
it's own that calls this B<init>.  Otherwise, it's an internally
used routine that is not of much interest to client coders.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  if ($DEBUG) {
    $self->debugging(1);
  }

  my @attributes = qw(
                       html_output_location
                       main_library
                       emacs_runner
                      );

  foreach my $field (@attributes) {
    $ATTRIBUTES{ $field } = 1;
    $self->{ $field } = $args->{ $field };
  }

  # default to the lib name (works once extract-docstrings.el
  # is installed)
  $self->{ main_library } ||= 'extract-docstrings';
  my $main_library = $self->{ main_library };

  unless ( $self->emacs_runner ) {
    my $er = Emacs::Run->new({
                              emacs_libs => [ $main_library ],
                            });
    $self->set_emacs_runner( $er );
  }

  lock_keys( %{ $self } );
  return $self;
}

=back

=head2 main methods

=over

=item elisp_docstrings_to_html

Given the name of an emacs lisp library (sans path or extension),
or the file name of the library (with extension *.el), generates
an html file in the standard location defined in the object:
html_output_location

The output file naming convention is: <lib_name>_el.html

=cut

sub elisp_docstrings_to_html {
  my $self    = shift;
  my $thingie = shift;  # either file or library
  my $progname = ( caller(0) )[3];
  my $er = $self->emacs_runner;

  # Add the given library to the ones loaded by the Emacs::Run object
  $er->push_emacs_libs( $thingie );

  my $loader_elisp = $er->generate_elisp_to_load_library( $thingie );
  $loader_elisp    = $er->quote_elisp( $loader_elisp );

  my ($elisp_file, $elisp_lib);
  if ( $thingie =~ m/\.el$/ ) {
    $elisp_file = $thingie;
    ($elisp_lib, undef, undef) = fileparse( $elisp_file, qr{ \.el$ }x );
  } else {
    $elisp_lib = $thingie;
    $elisp_file = $self->emacs_runner->elisp_file_from_library_name_if_in_loadpath( $elisp_lib );
  }

  my $output_loc = $self->html_output_location;
  my $output_file = "$output_loc/$elisp_lib" . '_el.html';

  unlink $output_file if -e $output_file; # redundant with elisp feature

  my $extractor_elisp = qq{
    (extract-doctrings-generate-html-for-elisp-file
       "$elisp_file"
       "$output_file"
       "Documentation for $elisp_lib.el (extracted docstrings)")
  };

  $self->emacs_runner->eval_elisp( $extractor_elisp );  # Note: eval_elisp does a quote_elisp internally.

  my $output_created_flag = -e $output_file;

  # check that there's a closing </HTML> at the bottom
  if ($output_created_flag) {
    open my $fh, '<', $output_file or die "Could not open $output_file for read: $!";
    local $/;
    my $content = <$fh>;
    close( $fh );
    unless( $content =~ m{ </HTML> \s* \z }xmsi ) {
      $output_created_flag = 0;
    }
  }

  return $output_created_flag;
}

=back

=head2 setters and getters

The naming convention in use here is that setters begin with
"set_", but getters have *no* prefix: the most commonly used case
deserves the simplest syntax (and mutators are deprecated).

These accessors exist for all of the object attributes (documented
above) irrespective of whether they're expected to be externally useful.

=head2  automatic generation of accessors

=over

=item AUTOLOAD

=cut

sub AUTOLOAD {
  return if $AUTOLOAD =~ /DESTROY$/;  # skip calls to DESTROY ()

  my ($name) = $AUTOLOAD =~ /([^:]+)$/; # extract method name
  (my $field = $name) =~ s/^set_//;

  # check that this is a valid accessor call
  croak("Unknown method '$AUTOLOAD' called")
    unless defined( $ATTRIBUTES{ $field } );

  { no strict 'refs';

    # create the setter and getter and install them in the symbol table

    if ( $name =~ /^set_/ ) {

      *$name = sub {
        my $self = shift;
        $self->{ $field } = shift;
        return $self->{ $field };
      };

      goto &$name;              # jump to the new method.
    } elsif ( $name =~ /^get_/ ) {
      carp("Apparent attempt at using a getter with unneeded 'get_' prefix.");
    }

    *$name = sub {
      my $self = shift;
      return $self->{ $field };
    };

    goto &$name;                # jump to the new method.
  }
}


1;

=back

=head1 MOTIVATION

Publishing code to a web site is essentially a systems
administration task that is a very good fit for perl, but when
the code you're publishing is emacs lisp, then emacs lisp is
convenient for some of the tasks: hence this franken-project,
gluing an emacs lisp package (extract-docstrings.el) into a perl
module framework.

Emacs lisp has a feature where a "docstring" can be defined for
each function or variable.  This was primarily intended for the
use of the emacs on-line help system, as opposed to the texinfo
format used by the Gnu project for it's more formal documentation.

A practice started by Ilya Zakharovich when he wrote
cperl-mode was to abuse this system of docstrings, in
order to lower the bar to writing documentation: essentially
it's a way of faking "pod" in elisp.

If your documentation is embedded in the emacs help system in
the form of these docstrings, then when creating web pages about
the code, it's useful to be able to extract the docstrings and
format them as an html page.

And that's the small need this lash-up of a module fills.


=head1 TODO

o  With this version, I use the (rather cheesy, in my opinion)
   cop-out of instructing the user to manually install the elisp
   somewhere in the load-path.  Question: can this be automated?

o  Currently, this is file-oriented: one *.el in, one *.html out.
   Would like to work on a set of elisp files, and handle
   internal links inside the set appropriately.

o  Look into skeleton or tempo to do html headers and footers.
   At present, these are hardcoded strings (to dodge the old
   dependency on the non-standard template.el).

=head1 SEE ALSO

L<Emacs::Run>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
02 Mar 2008

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
