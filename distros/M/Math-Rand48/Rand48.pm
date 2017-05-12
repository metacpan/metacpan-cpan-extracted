package Math::Rand48;
require DynaLoader;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.00';
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(drand48 erand48 seed48);
@EXPORT_OK = qw(lrand48 nrand48 mrand48 jrand48);

bootstrap Math::Rand48 $VERSION;

1;
__END__

=head1 NAME

Math::Rand48 - perl bindings for drand48() family of random functions

=head1 SYNOPSIS

  use Math::Rand48;
  
  my $n = drand48();        # Float value [0.0,1.0)
  my $seed = seed48();      # Get seed for drand48, lrand48, mrand48
  my $m = erand48($seed);   # Float value [0.0,1.0) - modifies $seed

  seed48($seed);            # Set seed for drand48, lrand48, mrand48

  use Math::Rand48 qw(lrand48);
  my $un = lrand48();
  my $um = nrand48($seed);

=head1 DESCRIPTION

This package provides an interface to the 48-bit family of random number 
functions, commonly provided on UNIX systems.

=over 4                                

=item C<seed48>

Returns the current seed used by C<drand48>, C<lrand48>, C<mrand48>.
If given an argument sets the seed to that value.

=item C<drand48>

=item C<erand48>($seed) 

Return float value in range [0.0,1.0).
Multiple independent streams of numbers can be obtained using C<erand48>.

=item C<lrand48>

=item C<nrand48>($seed) 

Return integer in range [0,2**31).
Multiple independent streams of numbers can be obtained using C<nrand48>.

=item C<mrand48>

=item C<jrand48>($seed) 

Return integer in range [-2**31,2**31).
Multiple independent streams of numbers can be obtained using C<jrand48>.

=back

=head2 Seed values

The I<$seed> above are perl scalars. When in use they are converted
to 6 byte binary "strings". If the incoming value is a string of less 
then 6 bytes it is padded with 0xFF. If the incoming value is a string of more
than 6 bytes it is "hashed" using perl's hash function to yield a 32 bit 
value which is then padded with two bytes of 0xFF. If the incoming value
is an integer it is used for 4 bytes, with two bytes of 0xFF.

=head1 AUTHOR

Nick Ing-Simmons <nick@ni-s.u-net.com>

=cut

