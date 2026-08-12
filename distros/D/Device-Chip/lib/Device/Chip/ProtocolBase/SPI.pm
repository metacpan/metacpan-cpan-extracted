#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::ProtocolBase::SPI 0.27;
role Device::Chip::ProtocolBase::SPI :compat(invokable);

use Future::AsyncAwait;

=head1 NAME

C<Device::Chip::ProtocolBase::SPI> - a role for implementing SPI protocols

=head1 DESCRIPTION

=for highlighter language=perl

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

async method write ( $words )
{
   await $self->readwrite( $words );
   return;
}

=head2 read

   $words = await $protocol->read( $len );

A wrapper for L</readwrite> that sends unspecified data which the chip will
ignore, returning the result.

This implementation currently sends all-bits-low.

=cut

async method read ( $len )
{
   return await $self->readwrite( "\x00" x $len );
}

=head2 write_no_ss

   await $protocol->write_no_ss( $words );

A wrapper for L</readwrite_no_ss> that ignores the result.

=cut

async method write_no_ss ( $words )
{
   await $self->readwrite_no_ss( $words );
   return
}

=head2 read_no_ss

   $words = await $protocol->read_no_ss( $len );

A wrapper for L</readwrite_no_ss> that sends unspecified data which the chip
will ignore, returning the result.

This implemention currenetly sends all-bits-low.

=cut

async method read_no_ss ( $len )
{
   return await $self->readwrite_no_ss( "\x00" x $len );
}

=head2 readwrite

   $words_in = await $protocol->readwrite( $words_out );

A wrapper for performing a complete SPI transfer, using L</assert_ss>,
L</readwrite_no_ss>, L</release_ss>.

=cut

# We can't use try/finally because you can't await inside finally blocks
# We can't defer {} for the same reason
# We'll use some eval {} hackery here

async method readwrite ( $words_out )
{
   my $words_in;
   my ( $ok, $e ) = eval {
      await $self->assert_ss;
      $words_in = await $self->readwrite_no_ss( $words_out );
      1;
   } ? ( 1 ) : ( 0, $@ );
   await $self->release_ss;
   $ok ? return $words_in : die $e;
}

=head2 write_then_read

   $words_in = await $protocol->write_then_read( $words_out, $len_in );

A wrapper for performing a complete SPI transfer in two phases, using
L</assert_ss>, L</write_no_ss>, L</read_no_ss> and L</release_ss>.

=cut

async method write_then_read ( $words_out, $len_in )
{
   my $words_in;
   my ( $ok, $e ) = eval {
      await $self->assert_ss;
      await $self->write_no_ss( $words_out );
      $words_in = await $self->read_no_ss( $len_in );
      1;
   } ? ( 1 ) : ( 0, $@ );
   await $self->release_ss;
   $ok ? return $words_in : die $e;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
