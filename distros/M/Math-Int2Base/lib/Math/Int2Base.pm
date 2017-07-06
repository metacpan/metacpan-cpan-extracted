package Math::Int2Base;

use 5.008006;
use strict;
use warnings;
use Carp;

our $VERSION = '1.01';

require Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw( int2base base2int base_chars ); 

my @Chars   = ('0'..'9', 'A'..'Z', 'a'..'z');
my $MaxBase = scalar @Chars;
my $CharStr = join '', @Chars;

#---------------------------------------------------------------------
# int2base( $num, $base, $minlen );  # base ||= 10 minlen ||= 1
sub int2base {

    my( $ret, $num, $base, $minlen ) = ( '', @_ );
    $num    ||= 0;
    $base   ||= 10;
    $minlen ||= 1;

    if( $num        < 0
        || $base    < 2
        || $MaxBase < $base
        || $minlen  < 1
        # || $num    != int( $num )  # XXX[1] do we care?
        ) {
        croak "not supported: int2base( '$num', $base, $minlen )" }

    for (; $num; $num = int($num/$base) ) { $ret .= $Chars[$num % $base] }
    no warnings 'numeric';  # negative repeat count
    return scalar reverse $ret . '0'x($minlen - length($ret));
}

#---------------------------------------------------------------------
# base2int( $num, $base );  # base ||= 10
sub base2int {

    my( $ret, $num, $base ) = ( 0, @_ );
    $num    ||= 0;
    $base   ||= 10;
    my $chars = substr $CharStr, 0, $base;

    if( $num       !~ /^[$chars]+$/
        || $base    <  2
        || $MaxBase <  $base         ) {
        croak "not supported: base2int( '$num', $base )" }

    $num =~ s/^0+//;  # trim leading zeros
    for( my $i = length($num)-1, my $c = 0; $i >= 0; --$i ) {
        $ret += index($CharStr, substr($num, $i, 1)) * $base**$c++ }
    return $ret;
} 

#---------------------------------------------------------------------
# base_chars( $base );  # base ||= 10
sub base_chars {
    my( $base ) = @_;
    $base ||= 10;
    return substr $CharStr, 0, $base;
} 

1;
__END__

=head1 NAME

Math::Int2Base - Perl extension for converting decimal (base-10)
integers into another number base from base-2 to base-62, and back
to decimal.

=head1 SYNOPSIS

  use Math::Int2Base qw( int2base base2int base_chars );

  my $base = 16;  # i.e., hexidecimal
  my $hex = int2base( 255,  $base );  # FF
  my $dec = base2int( $hex, $base );  # 255

  my $sixdig = int2base( 100, 36, 6  ); # 00002S
  my $decno  = base2int( $sixdig, 36 ); # 100, i.e., leading zeros no problem

  my $chars = base_chars( 24 );  # 0123...KLMN
  my $regex = qr/^[$chars]$/;    # used as character class

  use bigint;  # if needed
  my $googol = 10**100;
  my $base62 = int2base( $googol, 62 );  # QCyvrY2MJnQFGlUHTCA95Xz8AHOrLuoIO0fuPkHHCcyXy9ytM5N1lqsa
  my $bigint = base2int( $base62, 62 );  # back to 1e+100

  # from one base to another (via base-10)
  sub base_convert {
      my( $num, $from_base, $to_base ) = @_;
      return int2base( base2int( $num, $from_base ), $to_base );
  }

=head1 DESCRIPTION

Math::Int2Base provides

=over

=item

C<int2base( $int, $base, $minlen )> for converting from decimal to
another number base,

=item

C<base2int( $num, $base )> for converting from another base to decimal,
and

=item

C<base_chars( $base )> for retrieving the string of characters used to
represent digits in a number base.

=back

This module only works with positive integers.
Fractions are silently truncated to integers.

=head1 CONSTRAINTS

=over

=item

Only (so far) supports bases from 2 to 62

=item

Does not (yet) support bases that skip digits (e.g., base-24 skips
C<I> and C<O>, Math::Int2Base doesn't)

=item

Only supports positive integers.

=item

Does not support flexible case letters, e.g., in hexidecimal, C<F> == C<f>.

In Math::Int2Base, C<f> is not a hex digit, and
C<A>(base-16) == C<A>(base-36) == C<A>(base-62).

=back

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Category:Positional_numeral_systems
Math::BaseCnv
Math::BaseCalc

The code is based on newsgroup discussion
http://groups.google.com/group/comp.lang.perl.misc/browse_thread/thread/3f3b416e3a79fd2/d2f62e10c837e782
particularly that of Dr. Ruud. Errors are my own.

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

