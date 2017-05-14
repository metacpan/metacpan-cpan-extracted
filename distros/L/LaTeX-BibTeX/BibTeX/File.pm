# ----------------------------------------------------------------------
# NAME       : BibTeX/File.pm
# CLASSES    : LaTeX::BibTeX::File
# RELATIONS  : 
# DESCRIPTION: Provides an object-oriented interface to whole BibTeX
#              files.
# CREATED    : March 1997, Greg Ward
# MODIFIED   : 
# VERSION    : $Id: File.pm,v 1.12 2000/03/23 02:08:40 greg Rel $
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights
#              reserved.
# 
#              This file is part of the LaTeX::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

package LaTeX::BibTeX::File;

use strict;
use Carp;
use IO::File;

=head1 NAME

LaTeX::BibTeX::File - interface to whole BibTeX files

=head1 SYNOPSIS

   use LaTeX::BibTeX;     # this loads LaTeX::BibTeX::File

   $bib = new LaTeX::BibTeX::File "foo.bib" or die "foo.bib: $!\n";
   # or:
   $bib = new LaTeX::BibTeX::File;
   $bib->open ("foo.bib") || die "foo.bib: $!\n";

   $bib->set_structure ($structure_name,
                        $option1 => $value1, ...);

   $at_eof = $bib->eof;

   $bib->close;

=head1 DESCRIPTION

C<LaTeX::BibTeX::File> provides an object-oriented interface to BibTeX
files.  Its most obvious purpose is to keep track of a filename and
filehandle together for use by the C<LaTeX::BibTeX::Entry> module (which
is much more interesting).  In addition, it allows you to specify
certain options which are applicable to a whole database (file), rather
than having to specify them for each entry in the file.  Currently, you
can specify the I<database structure> and some I<structure options>.
These concepts are fully documented in L<LaTeX::BibTeX::Structure>.

=head1 METHODS

=head2 Object creation, file operations

=over 4

=item new ([FILENAME [,MODE [,PERMS]]]) 

Creates a new C<LaTeX::BibTeX::File> object.  If FILENAME is supplied,
passes it to the C<open> method (along with MODE and PERMS if they
are supplied).  If the C<open> fails, C<new> fails and returns false; if
the C<open> succeeds (or if FILENAME isn't supplied), C<new> returns the
new object reference.

=item open (FILENAME [,MODE [,PERMS]])

Opens the file specified by FILENAME, possibly using MODE and PERMS.
See L<IO::File> for full semantics; this C<open> is just a front end for
C<IO::File::open>.

=item close ()

Closes the filehandle associated with the object.  If there is no such
filehandle (i.e., C<open> was never called on the object), does nothing.

=item eof ()

Returns the end-of-file state of the filehandle associated with the
object: a true value means we are at the end of the file.

=back

=cut

sub new
{
   my $class = shift;

   $class = ref ($class) || $class;
   my $self = bless {}, $class;
   ($self->open (@_) || return undef) if @_; # filename [, mode [, perms]]
   $self;
}

sub open
{
   my $self = shift;

   $self->{filename} = $_[0];
   $self->{handle} = new IO::File;
   $self->{handle}->open (@_);          # filename, maybe mode, maybe perms
}

sub close
{
   my $self = shift;
   $self->{handle}->close if $self->{handle};   
}

sub eof
{
   eof (shift->{handle});
}
      
sub DESTROY
{
   my $self = shift;
   $self->close;
}

=head2 Object properties

=over 4

=item set_structure (STRUCTURE [, OPTION =E<gt> VALUE, ...])

Sets the database structure for a BibTeX file.  At the simplest level,
this means that entries from the file are expected to conform to certain
field requirements as specified by the I<structure module>.  It also
gives you full access to the methods of the particular I<structured
entry class> for this structure, allowing you to perform operations
specific to this kind of database.  See L<LaTeX::BibTeX::Structure/"CLASS
INTERACTIONS"> for all the consequences of setting the database
structure for a C<LaTeX::BibTeX::File> object.

=item structure ()

Returns the name of the database structure associated with the object
(as set by C<set_structure>).

=cut

sub set_structure
{
   my ($self, $structure, @options) = @_;

   require LaTeX::BibTeX::Structure;
   croak "LaTeX::BibTeX::File::set_structure: options list must have even " .
         "number of elements"
      unless @options % 2 == 0;
   $self->{structure} = new LaTeX::BibTeX::Structure ($structure, @options);
}

sub structure { shift->{structure} }


=item preserve_values ([PRESERVE])

Sets the "preserve values" flag, to control all future parsing of entries
from this file.  If PRESERVE isn't supplied, returns the current state of
the flag.  See L<LaTeX::BibTeX::Value> for details on parsing in "value
preservation" mode.

=back

=cut

sub preserve_values
{
   my $self = shift;

   $self->{'preserve_values'} = shift if @_;
   $self->{'preserve_values'};
}


1;

=head1 SEE ALSO

L<LaTeX::BibTeX>, L<LaTeX::BibTeX::Entry>, L<LaTeX::BibTeX::Structure>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the LaTeX::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.
