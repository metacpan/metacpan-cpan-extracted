#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2018 -- leonerd@leonerd.org.uk

package Test::Device::Chip::Adapter;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );

our $VERSION = '0.12';

use Carp;

use Future;
use List::Util 1.33 qw( first any );
use Test::Builder;

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

=cut

sub new
{
   my $class = shift;
   return bless {
      builder => Test::Builder->new,
      expect  => [],
   }, $class;
}

sub make_protocol_GPIO
{
   my $self = shift;
   $self->{protocol} = "GPIO";
   return Future->done( $self );
}

sub make_protocol_I2C
{
   my $self = shift;
   $self->{protocol} = "I2C";
   return Future->done( $self );
}

sub make_protocol_SPI
{
   my $self = shift;
   $self->{protocol} = "SPI";
   return Future->done( $self );
}

sub configure
{
   Future->done;
}

sub _stringify
{
   my ( $v ) = @_;
   if( $v =~ m/^-?[0-9]+$/ ) {
      return sprintf "0x%X", $v;
   }
   elsif( $v =~ m/^[\x20-\x7E]*$/ ) {
      $v =~ s/([\\'])/\\$1/g;
      return qq('$v');
   }
   else {
      $v =~ s{(.)}{sprintf "\\x%02X", ord $1}gse;
      return qq("$v");
   }
}

sub _stringify_args
{
   join ", ", map { _stringify $_ } @_;
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
                        [qw( GPIO SPI I2C )] ],
   write_gpios     => [ sub { my ( $v ) = @_; join ",", map { $v->{$_} ? $_ : "!$_" } sort keys %$v },
                        [qw( GPIO SPI I2C )] ],
   read_gpios      => [ sub { my ( $v ) = @_; join ",", @$v },
                        [qw( GPIO SPI I2C )] ],
   tris_gpios      => [ sub { my ( $v ) = @_; join ",", @$v },
                        [qw( GPIO SPI I2C )] ],
   write           => [ undef,
                        [qw( SPI I2C )] ],
   read            => [ undef,
                        [qw( I2C )] ],
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

      push @{ $self->{expect} }, my $e = bless [ $method, [ @_ ], 0 ],
         "Test::Device::Chip::Adapter::_Expectation";

      return $e;
   };

   my $actual = sub {
      my $self = shift;
      @_ = $canonicalise->( @_ ) if $canonicalise;

      my @args = @_;

      any { $_ eq $self->{protocol} } @$allowed_protos or
         croak "Method ->$method not allowed in $self->{protocol} protocol";

      my $e = first { not $_->complete } @{ $self->{expect} };

      $e and $e->consume( $method, \@args ) or
         # TODO: reflect this in test result
         croak "Unexpected call to ->$method(${\ _stringify_args @args })";

      return $e->future;
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

   my $builder = $self->{builder};

   $builder->subtest( $name, sub {
      my $count = 0;
      foreach my $e ( @{ $self->{expect} } ) {
         $e->check( $builder );
         $count++;
      }

      $builder->ok( 1, "No calls made" ) if !$count;
   });

   $self->{expect} = [];
}

package
   Test::Device::Chip::Adapter::_Expectation;

use List::Util qw( all );

use constant {
   METHOD  => 0,
   ARGS    => 1,
   CALLED  => 2,
   RETURN  => 3,
   FAILURE => 4,
};

sub complete
{
   my $self = shift;
   return $self->[CALLED];
}

sub consume
{
   my $self = shift;
   my ( $method, $args ) = @_;

   $method eq $self->[METHOD] or return 0;
   @$args == @{ $self->[ARGS] } or return 0;
   all { $args->[$_] eq $self->[ARGS][$_] } 0 .. $#$args or return 0;

   $self->[CALLED]++;
   return 1;
}

sub check
{
   my $self = shift;
   my ( $builder ) = @_;

   $builder->ok( $self->[CALLED], $self->[METHOD] );
}

sub returns
{
   my $self = shift;
   $self->[FAILURE] and die "Cannot set a return value for a failing expectation\n";
   $self->[RETURN] = [ @_ ];
}

sub fails
{
   my $self = shift;
   $self->[RETURN] and die "Cannot set a failure for a returning expectation\n";
   $self->[FAILURE] = [ @_ ];
}

sub future
{
   my $self = shift;
   $self->[FAILURE] ? Future->fail( @{ $self->[FAILURE] } )
                    : Future->done( @{ $self->[RETURN] } )
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
