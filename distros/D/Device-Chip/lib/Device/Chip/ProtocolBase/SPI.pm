#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.35; # role :compat(invokable)

package Device::Chip::ProtocolBase::SPI 0.16;
role Device::Chip::ProtocolBase::SPI :compat(invokable);

=head1 NAME

C<Device::Chip::ProtocolBase::SPI> - a role for implementing SPI protocols

=head1 DESCRIPTION

This role (or abstract base class) provides some convenient wrapper methods
for providing higher-level SPI protocol implementations, by using simpler
lower-level ones. It can be used by implementation classes to help provide
parts of the API.

=cut

=head1 WRAPPER METHODS

=cut

=head2 write

   await $protocol->write( $words );

A wrapper for L</readwrite> that ignores the result.

=cut

method write ( $words )
{
   $self->readwrite( $words )->then_done();
}

=head2 read

   $words = await $protocol->read( $len );

A wrapper for L</readwrite> that sends unspecified data which the chip will
ignore, returning the result.

This implementation currently sends all-bits-low.

=cut

method read ( $len )
{
   $self->readwrite( "\x00" x $len );
}

=head2 write_no_ss

A wrapper for L</readwrite_no_ss> that ignores the result.

=cut

method write_no_ss ( $words )
{
   $self->readwrite_no_ss( $words )->then_done();
}

=head2 read_no_ss

A wrapper for L</readwrite_no_ss> that sends unspecified data which the chip
will ignore, returning the result.

This implemention currenetly sends all-bits-low.

=cut

method read_no_ss ( $len )
{
   $self->readwrite_no_ss( "\x00" x $len );
}

=head2 readwrite

   $words_in = await $protocol->readwrite( $words_out );

A wrapper for performing a complete SPI transfer, using L</assert_ss>,
L</readwrite_no_ss>, L</release_ss>.

=cut

method readwrite ( $words_out )
{
   $self->assert_ss
      ->then( sub { $self->readwrite_no_ss( $words_out ) } )
      ->followed_by( sub {
         my ( $f ) = @_;
         $self->release_ss->then( sub { $f } );
      });
}

=head2 write_then_read

   $words_in = await $protocol->write_then_read( $words_out, $len_in )

A wrapper for performing a complete SPI transfer in two phases, using
L</assert_ss>, L</write_no_ss>, L</read_no_ss> and L</release_ss>.

=cut

method write_then_read ( $words_out, $len_in )
{
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
