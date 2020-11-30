#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2020 -- leonerd@leonerd.org.uk

package Test::Device::Chip::Adapter;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );

our $VERSION = '0.15';

use Carp;

use Test::Future::Deferred;
use List::Util 1.33 qw( first any );
use Test::Builder;

use Test::ExpectAndCheck::Future;

=head1 NAME

C<Test::Device::Chip::Adapter> - unit testing on C<Device::Chip>

=head1 SYNOPSIS

   use Test::More;
   use Test::Device::Chip::Adapter;

   my $adapter = Test::Device::Chip::Adapter->new;

   $chip_under_test->mount( $adapter );

   # An actual test
   $adapter->expect_readwrite( "123" )
      ->returns( "45" );

   is( $chip->do_thing( "123" )->get, "45", 'result of ->do_thing' );

   $adapter->check_and_clear( '->do_thing' );

=head1 DESCRIPTION

This package provides a concrete implementation of L<Device::Chip::Adapter>
convenient for using in a unit-test script used to test a L<Device::Chip>
instance. It operates in an "expect-and-check" style of mocking, requiring the
test script to declare upfront what methods are expected to be called, and
what values they return.

Futures returned by this module will not yield results immediately; they must
be awaited by invoking the C<< ->get >> method. This ensures that unit tests
correctly perform the required asynchronisation.

=cut

sub new
{
   my $class = shift;

   my ( $controller, $obj ) = Test::ExpectAndCheck::Future->create;

   return bless {
      builder => Test::Builder->new,
      controller => $controller,
      obj        => $obj,
   }, $class;
}

sub make_protocol_GPIO
{
   my $self = shift;
   $self->{protocol} = "GPIO";
   return Test::Future::Deferred->done_later( $self );
}

sub make_protocol_I2C
{
   my $self = shift;
   $self->{protocol} = "I2C";
   return Test::Future::Deferred->done_later( $self );
}

sub make_protocol_SPI
{
   my $self = shift;
   $self->{protocol} = "SPI";
   return Test::Future::Deferred->done_later( $self );
}

sub make_protocol_UART
{
   my $self = shift;
   $self->{protocol} = "UART";
   return Test::Future::Deferred->done_later( $self );
}

sub configure
{
   Test::Future::Deferred->done_later;
}

=head1 EXPECTATIONS

Each of the actual methods to be used by the L<Device::Chip> under test has an
associated expectation method, whose name is prefixed C<expect_>. Each returns
an expectation object, which has additional methods to control the behaviour of
that invocation.

   $exp = $adapter->expect_write_gpios( \%gpios )
   $exp = $adapter->expect_read_gpios( \@gpios )
   $exp = $adapter->expect_tris_gpios( \@gpios )
   $exp = $adapter->expect_write( $bytes )
   $exp = $adapter->expect_read( $len )
   $exp = $adapter->expect_write_then_read( $bytes, $len )
   $exp = $adapter->expect_readwrite( $bytes_out )
   $exp = $adapter->expect_assert_ss
   $exp = $adapter->expect_release_ss
   $exp = $adapter->expect_readwrite_no_ss( $bytes_out )
   $exp = $adapter->expect_write_no_ss( $bytes )

The returned expectation object allows the test script to specify what such an
invocation should return or throw.

   $exp->returns( $bytes_in )
   $exp->fails( $failure )

=cut

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
foreach my $method ( keys %METHODS ) {
   my ( $canonicalise, $allowed_protos ) = @{ $METHODS{$method} };

   my $expect = sub {
      my $self = shift;
      @_ = $canonicalise->( @_ ) if $canonicalise;

      return $self->{controller}->expect( $method => @_ );
   };

   my $actual = sub {
      my $self = shift;
      @_ = $canonicalise->( @_ ) if $canonicalise;

      my @args = @_;

      any { $_ eq $self->{protocol} } @$allowed_protos or
         croak "Method ->$method not allowed in $self->{protocol} protocol";

      return $self->{obj}->$method( @args );
   };

   no strict 'refs';
   *{"expect_$method"} = $expect;
   *{$method}          = $actual;
}

=head1 METHODS

This class has the methods available on L<Device::Chip::Adapter>, which would
normally be used by the chip instance under test. The following additional
methods would be used by the unit test script controlling it.

=cut

=head2 check_and_clear

   $adapter->check_and_clear( $name )

Checks that by now, every expected method has indeed been called, and emits a
new test output line via L<Test::Builder>. Regardless, the expectations are
also cleared out ready for the start of the next test.

=cut

sub check_and_clear
{
   my $self = shift;
   my ( $name ) = @_;

   $self->{controller}->check_and_clear( $name );
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
