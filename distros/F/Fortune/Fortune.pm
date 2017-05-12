#
# Fortune.pm
#
# interface to fortune cookie databases
#
# by Greg Ward, 1999/02/20
#
# $Id: Fortune.pm,v 1.4 2000/02/27 02:22:31 greg Exp $
#

package Fortune;
require 5.004;

use strict;
use Carp;
use IO::File;


$Fortune::VERSION = '0.2';

=head1 NAME

Fortune - read and write fortune (strfile) databases

=head1 SYNOPSIS

   # input
   $ffile = new Fortune ($base_filename);
   $ffile->read_header ();
   $num_fortunes = $ffile->num_fortunes ();
   $fortune = $ffile->read_fortune ($num);
   $fortune = $ffile->get_random_fortune ();

   # create header file from data file -- NOT IMPLEMENTED YET
   $ffile = new Fortune ($base_filename);
   $ffile->write_header ();

   # write to data file -- NOT IMPLEMENTED YET
   $ffile = new Fortune (">>$base_filename");
   $ffile->write_fortune ($fortune);

=head1 DESCRIPTION

The C<fortune> program is a small but important part of the Unix
culture, and this module aims to provide support for its "fortune
cookie" databases to Perl programmers.  For efficiency, all versions of
C<fortune> rely on a binary header consisting mainly of offsets into the
fortune file proper.  Modern versions of fortune keep this header in a
separate file, and this is the style adopted by the C<Fortune> module;
the older style of munging the header and data into one large "compiled"
file is not (currently) supported.

Using the C<Fortune> module makes it trivial to write a simplified
version of the C<fortune> program:

   # trivial 'fortune' progam
   my $fortune_filename = $ARGV[0];
   my $fortune_file = new Fortune ($fortune_filename);
   $fortune_file->read_header ();
   my $fortune = $fortune_file->get_random_fortune ();
   print $fortune;

This can be compressed considerably:

   print new Fortune ($ARGV[0])->read_header()->get_random_fortune();

Of course, this doesn't provide all of C<fortune>'s interesting
features, such as parallel databases of offensive fortunes, selection of
long or short fortunes, dealing with multiple fortune files, etc.  If
you want C<fortune>, use it -- but if you just want a simple Perl
interface to its data files, the C<Fortune> module is for you.

Currently, the C<Fortune> module does not support writing fortune
databases.  If it did, writing a simplified C<strfile> (the program that
processes a fortune database to create the header file) would also be
trivial:

   # trivial (and hypothetical) 'strfile' program
   my $fortune_filename = @ARGV[0];
   my $fortune_file = new Fortune ($fortune_filename);
   $fortune_file->write_header ();

Note that the header filename is assumed to be just the name of the main
fortune database, with C<".dat"> appended.  You can supply an alternate
header filename to the constructor, C<new()>, if you wish.

=head1 METHODS

=head2 Initialization/cleanup

=over 4

=item new (FILE [, HEADER_FILE])

Opens a fortune cookie database.  FILE is the name of the data file to
open, and HEADER_FILE (if given) the name of the header file that
contains (or will contain) meta-data about the fortune database.  If
HEADER_FILE is not given, it defaults to FILE with C<".dat"> appended.

The data file is opened via C<open_file()>, which C<die>s if the file
cannot be opened.  The header file is I<not> opened, whether you supply
its filename or not -- after all, it might not exist yet.  Rather, you
must explicitly call C<read_header()> or C<write_header()> as
appropriate.

=cut

sub new
{
   my ($class, $filename, $header_filename) = @_;
   $class = ref $class || $class;
   my $self = bless {
                     filename => $filename,
                     header_filename => $header_filename || $filename . ".dat",
                    }, $class;
   $self->open_file ();
   return $self;
}


sub DESTROY
{
   my $self = shift;
   $self->close_file ();
}


=item open_file ()

Opens the fortune file whose name was supplied to the constructor.  Dies
on failure.

=cut

sub open_file
{
   my $self = shift;

   my $file = new IO::File $self->{'filename'} or 
      die "unable to open $self->{'filename'}: $!\n";
   $self->{'file'} = $file;
}


=item close_file ()

Closes the fortune file if it's open; does nothing otherwise.

=cut

sub close_file
{
   my $self = shift;
   $self->{'file'}->close () if defined $self->{'file'};
}

=back 

=head2 Header functions (read and write)

=over 4

=item read_header ()

Reads the header file associated with this fortune database.  The name
of the header file is determined by the constructor C<new>: either it is
based on the name of the data file, or supplied by the caller.

If the header file does not exist, this function calls C<compute_header()>
automatically, which has the same effect as reading the header from a file.

The header contains the following values, which are stored as attributes
of the C<Fortune> object:

=over 4

=item C<version>

version number

=item C<numstr>

number of strings (fortunes) in the file

=item C<max_length>

length of longest string in the file

=item C<min_length>

length of shortest string in the file

=item C<flags>

bit field for flags (see strfile(1) man page)

=item C<delim>

character that delimits fortunes

=back

C<numstr> is available via the C<num_fortunes()> method; if you're
interested in the others, you'll have to go grubbing through the
C<Fortune> object, e.g.:

   $fortune_file = new Fortune ('fortunes');
   $fortune_file->read_header ();
   $delim = $fortune_file->{'delim'};

C<read_header()> C<die>s if there are any problems reading the header file,
e.g. if it seems to be corrupt or truncated.

C<read_header()> returns the current C<Fortune> object, to allow for
sneaky one-liners (see the examples above).

=cut

sub read_header
{
   my ($self) = @_;

   my $filename = $self->{'header_filename'};
   if (! -f $filename && -f $self->{'filename'})
      { return $self->compute_header(); }
      
   my $hdr_file = new IO::File $filename or
      die "couldn't open $filename: $!\n|";
   binmode ($hdr_file);

   # from the strfile(1) man page:
   #       unsigned long str_version;  /* version number */
   #       unsigned long str_numstr;   /* # of strings in the file */
   #       unsigned long str_longlen;  /* length of longest string */
   #       unsigned long str_shortlen; /* shortest string length */
   #       unsigned long str_flags;    /* bit field for flags */
   #       char str_delim;             /* delimiting character */
   # that 'char' is padded out to a full word, so the header is 24 bytes

   my $header;
   read ($hdr_file, $header, 24) == 24
      or die "failed to read full header\n";
   @{$self}{qw(version numstr max_length min_length flags delim)} =
      unpack ("NNNNNaxxx", $header);

   my $expected_offsets = $self->{'numstr'} + 1;
   my $amount_data = 4 * $expected_offsets;
   my $data;
   read ($hdr_file, $data, $amount_data) == $amount_data
      or die "failed to read offsets for all fortunes\n";
   my @offsets = unpack ("N*", $data);
   die sprintf ("found %d offsets (expected %d)\n", 
                scalar @offsets, $expected_offsets)
      unless @offsets == $expected_offsets;
   $self->{'offsets'} = \@offsets;

   close ($hdr_file);
   return $self;
}  # read_header


=item compute_header ([DELIM])

Reads the contents of the fortune file and computes the header
information that would normally be found in a header (F<.dat>) file.
This is useful if you maintain a file of fortunes by hand and do not
have the corresponding data file.

An optional delimiter argument may be passed to this function; if
present, that delimiter will be used to separate entries in the fortune
file.  If not provided, the existing C<delim> attribute of the Fortune
object will be used.  If that is not defined, then a percent sign ("%")
will be used.

=cut

sub compute_header
{
   my ($self, $delim) = @_;
   $delim = $self->{'delim'} || '%'
      unless defined $delim;

   local $/ = $delim . "\n";            # read whole fortunes
   my $filename = $self->{'filename'};
   my $file = new IO::File $filename
      or die "couldn't open $filename: $!\n";
   my @offsets = (0);                   # start with offset of first fortune
   my $fortune = '';
   my($min, $max);
   while (defined ($fortune = <$file>))
   {
      chomp $fortune;
      my $len = length $fortune;
      if    (!defined $min || $len < $min) { $min = $len }
      elsif (!defined $max || $len > $max) { $max = $len }
      push (@offsets, tell $file);
   }
   $self->{'version'}    = 1;
   $self->{'numstr'}     = $#offsets;
   $self->{'max_length'} = $max;
   $self->{'min_length'} = $min;
   $self->{'flags'}      = 0;
   $self->{'delim'}      = $delim;
   $self->{'offsets'}    = \@offsets;
}

=item num_fortunes ()

Returns the number of fortunes found by C<read_header()>.

=cut

sub num_fortunes
{
   my $self = shift;
   croak "header not read" unless defined $self->{'numstr'};
   return $self->{'numstr'};
}


=item write_header ([DELIM])

is not yet implemented.

=cut

=back

=head2 Fortune input

=over 4

=item get_fortune (NUM)

Reads string number NUM from the open fortune file.  NUM is zero-based,
ie. it must be between 0 and C<num_fortunes()-1> (inclusive).  C<croak>s if
you haven't opened the file and read the header, or if NUM is out of range.
(Opening the file is pretty hard to screw up, since it's taken care of for
you by the constructor, but you have to read the header explicitly with
C<read_header()>.)  Returns the text of the fortune as a (possibly)
multiline string.

=cut

sub read_fortune
{
   my ($self, $num) = @_;

   croak "fortune file not open" 
      unless defined $self->{'file'} and defined fileno ($self->{'file'});
   croak "header file not read"
      unless defined $self->{'numstr'};
   croak "invalid fortune number (max " . ($self->{'numstr'}-1) . ")"
      unless $num < $self->{'numstr'} && $num >= 0;

   my $start = $self->{'offsets'}[$num];
   my $end = $self->{'offsets'}[$num+1];
   my $length = $end - $start;

   # decrement length 2 bytes for most fortunes (to drop trailing "%\n"),
   # and none for the last one (keep trailing newline)
   my $delimlength = length $self->{'delim'} || 1;
   $length -= ($num == $self->{'numstr'}-1) ? 0 : ($delimlength+1);

   my $file = $self->{'file'};
   my $fortune;
   seek ($file, $start, 0);
   read ($file, $fortune, $length) == $length
      or die "unable to read entire fortune\n";
   return $fortune;
}  # get_fortune


=item get_random_fortune ()

Picks a random fortune for you and reads it with C<read_fortune()>.

=cut

sub get_random_fortune
{
   my ($self) = @_;

   croak "header file not read"
      unless defined $self->{'numstr'};
   my $num = int (rand $self->{'numstr'});
   return $self->read_fortune ($num);
}


=back

=head2 Fortune output

=over 4

=item write_fortune (FORTUNE)

is not yet implemented.

=back

=cut

1;

=head1 AUTHOR AND COPYRIGHT

Written by Greg Ward E<lt>gward@python.netE<gt>, 20 February 1999.

Copyright (c) 1999-2000 Gregory P. Ward. All rights reserved.  This is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 AVAILABILITY

You can download the C<Fortune> module from my web page:

   http://starship.python.net/~gward/perl/

and it can also be found on CPAN.

If you are using an operating system lacking a sufficient sense of
humour to include C<fortune> as part of its standard installation (most
commercial Unices seem to be so afflicted), the Linux world has a
solution: the C<fortune-mod> distribution.  The latest version as of
this writing is C<fortune-mod-9708>, and the README file says you can
find it at

   http://www.progsoc.uts.edu.au/~dbugger/hacks/hacks.html

This is the C<fortune> implementation on which the C<Fortune> module is
based.
