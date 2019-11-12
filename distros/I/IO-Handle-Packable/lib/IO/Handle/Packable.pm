#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package IO::Handle::Packable;

use strict;
use warnings;
use base qw( IO::File );

our $VERSION = '0.01';

use constant {
   BYTES_FMT_i => length( pack "i", 0 ),
   BYTES_FMT_f => length( pack "f", 0 ),
   BYTES_FMT_d => length( pack "d", 0 ),
};

=head1 NAME

C<IO::Handle::Packable> - add C<pack> and C<unpack> methods to an C<IO::Handle>

=head1 SYNOPSIS

   use IO::Handle::Packable;

   my $fh = IO::Handle::Packable->new;
   $fh->open( "my-data.dat", ">" );

   while( my ( $x, $y, $value ) = $fh->unpack( "S S i" ) ) {
      print "Value at ($x,$y) is $value\n";
   }

=head1 DESCRIPTION

This subclass of L<IO::File> adds two new methods to an IO handle; L</pack>
and L</unpack>. These provide the ability to write or read packed binary
values to and from the filehandle, using the same kind of format strings as
the core perl functions of the same names.

=head2 Unpack Format

Note that due to limitations in the way core perl's C<unpack()> function
works, this module has to know in advance how many bytes will be needed per
C<read()> call, before it can unpack the data. As a result, it cannot cope
with all of the features that core's C<unpack()> can do.

The following features are supported:

   a A                  # binary and ASCII data of fixed length

   c C s S i I l L q Q  # integers

   n N v V              # legacy fixed-endian integers

   f d                  # native floating-point

   s< s>                # endian specifiers

   a123  i45            # repeat counts

The following features are not currently supported, though should be
relatively easy to add:

   b B                  # bitstrings

   F D                  # perl-internal floating-point

   i!                   # native-length integers

   (c c s)              # groups

   #                    # comments

Due to needing to know lengths in advance, the following features will be much
harder to implement without at least some redesign to the current
implementation:

   z*                   # NUL-terminated ASCIIZ strings

   n/A                  # length-prefixed strings

   . @ x                # positioning control

=head1 METHODS

=cut

sub _length_of_packformat
{
   my ( $format ) = @_;
   local $_ = $format;

   my $bytes = 0;
   while( length ) {
      s/^\s+//;
      length or last;

      my $this;

      # Basic template
      s/^[aAcC]// and $this = 1 or
      s/^[sSnv]// and $this = 2 or
      s/^[iI]//   and $this = BYTES_FMT_i or
      s/^[lLNV]// and $this = 4 or
      s/^[qQ]//   and $this = 8 or
      s/^f//      and $this = BYTES_FMT_f or
      s/^d//      and $this = BYTES_FMT_d or
         die "TODO: unrecognised template char ${\substr $_, 0, 1}\n";

      # Ignore endian specifiers
      s/^[<>]//;

      # Repeat count
      s/^(\d+)// and $this *= $1;

      $bytes += $this;
   }

   return $bytes;
}

=head2 pack

   $fh->pack( $format, @values )

Uses the core C<pack> function to pack the values given the format into a
binary string, then writes the result to the filehandle.

=cut

sub pack
{
   my $self = shift;
   my ( $format, @values ) = @_;

   $self->print( pack $format, @values );
}

=head2 unpack

   @values = $fh->unpack( $format )

Uses the core C<unpack> function to unpack bytes read from the filehandle
using the given format.

=cut

sub unpack
{
   my $self = shift;
   my ( $format ) = @_;

   my $len = _length_of_packformat $format;
   defined( my $ret = $self->read( my $buf, $len ) ) or return undef;
   $ret or return;

   return unpack $format, $buf;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
