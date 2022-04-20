#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;  # :does

package Test::Device::Chip::Adapter 0.22;
class Test::Device::Chip::Adapter
   :does(Device::Chip::Adapter);

use Carp;

use Future::AsyncAwait;

use Test::Future::Deferred;
use List::Util 1.33 qw( first any );
use Test::Builder;

use Test::ExpectAndCheck::Future;

=encoding UTF-8

=head1 NAME

C<Test::Device::Chip::Adapter> - unit testing on C<Device::Chip>

=head1 SYNOPSIS

   use Test::More;
   use Test::Device::Chip::Adapter;

   use Future::AsyncAwait;

   my $adapter = Test::Device::Chip::Adapter->new;

   $chip_under_test->mount( $adapter );

   # An actual test
   $adapter->expect_readwrite( "123" )
      ->returns( "45" );

   is( await $chip->do_thing( "123" ), "45", 'result of ->do_thing' );

   $adapter->check_and_clear( '->do_thing' );

=head1 DESCRIPTION

This package provides a concrete implementation of L<Device::Chip::Adapter>
convenient for using in a unit-test script used to test a L<Device::Chip>
instance. It operates in an "expect-and-check" style of mocking, requiring the
test script to declare upfront what methods are expected to be called, and
what values they return.

Futures returned by this module will not yield results immediately; they must
be awaited by a toplevel C<await> keyword or invoking the C<< ->get >> method.
This ensures that unit tests correctly perform the required asynchronisation.

=cut

has $_protocol;

has $_controller;
has $_obj;
has $_txn_helper;

ADJUST
{
   ( $_controller, $_obj ) = Test::ExpectAndCheck::Future->create;
}

method make_protocol_GPIO ()
{
   $_protocol = "GPIO";
   return Test::Future::Deferred->done_later( $self );
}

method make_protocol_I2C ()
{
   $_protocol = "I2C";
   return Test::Future::Deferred->done_later( $self );
}

method make_protocol_SPI ()
{
   $_protocol = "SPI";
   return Test::Future::Deferred->done_later( $self );
}

method make_protocol_UART ()
{
   $_protocol = "UART";
   return Test::Future::Deferred->done_later( $self );
}

method configure ( % )
{
   Test::Future::Deferred->done_later;
}

=head1 EXPECTATIONS

Each of the actual methods to be used by the L<Device::Chip> under test has an
associated expectation method, whose name is prefixed C<expect_>. Each returns
an expectation object, which has additional methods to control the behaviour of
that invocation.

   $exp = $adapter->expect_write_gpios( \%gpios );
   $exp = $adapter->expect_read_gpios( \@gpios );
   $exp = $adapter->expect_tris_gpios( \@gpios );
   $exp = $adapter->expect_write( $bytes );
   $exp = $adapter->expect_read( $len );
   $exp = $adapter->expect_write_then_read( $bytes, $len );
   $exp = $adapter->expect_readwrite( $bytes_out );
   $exp = $adapter->expect_assert_ss;
   $exp = $adapter->expect_release_ss;
   $exp = $adapter->expect_readwrite_no_ss( $bytes_out );
   $exp = $adapter->expect_write_no_ss( $bytes );

The returned expectation object allows the test script to specify what such an
invocation should return or throw.

   $exp->returns( $bytes_in );
   $exp->fails( $failure );

Expectations for an atomic I²C transaction are performed inline, using the
following additional methods:

   $adapter->expect_txn_start();
   $adapter->expect_txn_stop();

=cut

BEGIN {
   my %METHODS = (
      sleep           => [ undef,
                           [qw( GPIO SPI I2C UART )] ],
      write_gpios     => [ sub { my ( $v ) = @_; join ",", map { $v->{$_} ? $_ : "!$_" } sort keys %$v },
                           [qw( GPIO SPI I2C UART )] ],
      read_gpios      => [ sub { my ( $v ) = @_; join ",", @$v },
                           [qw( GPIO SPI I2C UART )] ],
      tris_gpios      => [ sub { my ( $v ) = @_; join ",", @$v },
                           [qw( GPIO SPI I2C UART )] ],
      write           => [ undef,
                           [qw( SPI I2C UART )] ],
      read            => [ undef,
                           [qw( SPI I2C UART )] ],
      write_then_read => [ undef,
                           [qw( SPI I2C )] ],
      readwrite       => [ undef,
                           [qw( SPI )] ],
      assert_ss       => [ undef,
                           [qw( SPI )] ],
      release_ss      => [ undef,
                           [qw( SPI )] ],
      write_no_ss     => [ undef,
                           [qw( SPI )] ],
      readwrite_no_ss => [ undef,
                           [qw( SPI )] ],
   );

   use Object::Pad ':experimental(mop)';
   my $meta = Object::Pad::MOP::Class->for_caller;

   foreach my $method ( keys %METHODS ) {
      my ( $canonicalise, $allowed_protos ) = @{ $METHODS{$method} };

      $meta->add_method(
         "expect_$method" => method {
            @_ = $canonicalise->( @_ ) if $canonicalise;

            return $_controller->expect( $method => @_ );
         }
      );

      $meta->add_method(
         "$method" => method {
            @_ = $canonicalise->( @_ ) if $canonicalise;

            my @args = @_;

            any { $_ eq $_protocol } @$allowed_protos or
               croak "Method ->$method not allowed in $_protocol protocol";

            return $_obj->$method( @args );
         }
      );
   }

   class Test::Device::Chip::Adapter::_TxnHelper {
      has $_adapter :param;

      async method write { await $_adapter->write( @_ ) }
      async method read  { return await $_adapter->read( @_ ) }
      async method write_then_read { return await $_adapter->write_then_read( @_ ) }
   }

   async method txn ( $code )
   {
      $_protocol eq "I2C" or
         croak "Method ->txn not allowed in $_protocol protocol";

      $_txn_helper //= Test::Device::Chip::Adapter::_TxnHelper->new( adapter => $self );

      $_obj->txn_start;

      my $result = await $code->( $_txn_helper );

      $_obj->txn_stop;

      return $result;
   }

   async method expect_txn_start () { $_controller->expect( txn_start => ) }
   async method expect_txn_stop  () { $_controller->expect( txn_stop => ) }
}

=head1 METHODS

This class has the methods available on L<Device::Chip::Adapter>, which would
normally be used by the chip instance under test. The following additional
methods would be used by the unit test script controlling it.

=cut

=head2 check_and_clear

   $adapter->check_and_clear( $name );

Checks that by now, every expected method has indeed been called, and emits a
new test output line via L<Test::Builder>. Regardless, the expectations are
also cleared out ready for the start of the next test.

=cut

method check_and_clear ( $name )
{
   $_controller->check_and_clear( $name );
   return;
}

=head1 TODO

=over 4

=item *

Handle C<list_gpios> method

=item *

Handle C<configure>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
