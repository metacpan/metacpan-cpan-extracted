#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Device::Chip::ProtocolBase::SPI;

use strict;
use warnings;

our $VERSION = '0.15';

=head1 NAME

C<Device::Chip::ProtocolBase::SPI> - a base class for implementing SPI protocols

=head1 DESCRIPTION

This abstract base class provides some convenient wrapper methods for
providing higher-level SPI protocol implementations, by using simpler
lower-level ones. It can be used by implementation classes to help provide
parts of the API.

=cut

=head1 WRAPPER METHODS

=cut

=head2 write

   $protocol->write( $words )->get

A wrapper for L</readwrite> that ignores the result.

=cut

sub write
{
   my $self = shift;
   my ( $words ) = @_;

   $self->readwrite( $words )->then_done();
}

=head2 read

   $words = $protocol->read( $len )->get

A wrapper for L</readwrite> that sends unspecified data which the chip will
ignore, returning the result.

This implementation currently sends all-bits-low.

=cut

sub read
{
   my $self = shift;
   my ( $len ) = @_;

   $self->readwrite( "\x00" x $len );
}

=head2 write_no_ss

A wrapper for L</readwrite_no_ss> that ignores the result.

=cut

sub write_no_ss
{
   my $self = shift;
   my ( $words ) = @_;

   $self->readwrite_no_ss( $words )->then_done();
}

=head2 read_no_ss

A wrapper for L</readwrite_no_ss> that sends unspecified data which the chip
will ignore, returning the result.

This implemention currenetly sends all-bits-low.

=cut

sub read_no_ss
{
   my $self = shift;
   my ( $len ) = @_;

   $self->readwrite_no_ss( "\x00" x $len );
}

=head2 readwrite

   $words_in = $protocol->readwrite( $words_out )->get

A wrapper for performing a complete SPI transfer, using L</assert_ss>,
L</readwrite_no_ss>, L</release_ss>.

=cut

sub readwrite
{
   my $self = shift;
   my ( $words_out ) = @_;

   $self->assert_ss
      ->then( sub { $self->readwrite_no_ss( $words_out ) } )
      ->followed_by( sub {
         my ( $f ) = @_;
         $self->release_ss->then( sub { $f } );
      });
}

=head2 write_then_read

   $words_in = $protocol->write_then_read( $words_out, $len_in )

A wrapper for performing a complete SPI transfer in two phases, using
L</assert_ss>, L</write_no_ss>, L</read_no_ss> and L</release_ss>.

=cut

sub write_then_read
{
   my $self = shift;
   my ( $words_out, $len_in ) = @_;

   $self->assert_ss
      ->then( sub { $self->write_no_ss( $words_out ) } )
      ->then( sub { $self->read_no_ss( $len_in ) } )
      ->followed_by( sub {
         my ( $f ) = @_;
         $self->release_ss->then( sub { $f } );
      });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
