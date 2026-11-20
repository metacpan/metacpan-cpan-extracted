package Langertha::Holmgang::Random;
# ABSTRACT: The seeded private random source for case generators

use Moose;
use namespace::autoclean;

use Carp qw( croak );

our $VERSION = '0.002';


my $M32 = 0xFFFFFFFF;

has seed => (
  is       => 'ro',
  required => 1,
);


has _s => (
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_s',
);

sub BUILD {
  my ( $self ) = @_;
  my $seed = $self->seed;
  croak __PACKAGE__.': seed must be an integer from 0 to 4294967295'
    unless defined $seed && !ref $seed && $seed =~ /\A[0-9]{1,10}\z/ && $seed <= $M32;
  $self->_s;
  return;
}

# a * b mod 2**32 without leaving 48 bits
sub _mul32 {
  my ( $x, $y ) = @_;
  return ( ( $x * ( $y & 0xFFFF ) ) + ( ( ( $x * ( $y >> 16 ) ) & 0xFFFF ) << 16 ) ) & $M32;
}

sub _rotl { my ( $x, $k ) = @_; return ( ( $x << $k ) | ( $x >> ( 32 - $k ) ) ) & $M32 }

sub _build_s {
  my ( $self ) = @_;
  my $x = $self->seed & $M32;
  my @s;
  for ( 1 .. 4 ) {    # splitmix32
    $x = ( $x + 0x9E3779B9 ) & $M32;
    my $z = $x;
    $z = _mul32( $z ^ ( $z >> 16 ), 0x85EBCA6B );
    $z = _mul32( $z ^ ( $z >> 13 ), 0xC2B2AE35 );
    push @s, $z ^ ( $z >> 16 );
  }
  $s[0] = 1 unless grep { $_ } @s;
  return \@s;
}

sub next_u32 {
  my ( $self ) = @_;
  my $s = $self->_s;
  my $result = _mul32( _rotl( _mul32( $s->[1], 5 ), 7 ), 9 );
  my $t = ( $s->[1] << 9 ) & $M32;
  $s->[2] ^= $s->[0];
  $s->[3] ^= $s->[1];
  $s->[1] ^= $s->[2];
  $s->[0] ^= $s->[3];
  $s->[2] ^= $t;
  $s->[3] = _rotl( $s->[3], 11 );
  return $result;
}


sub int {
  my ( $self, $lo, $hi ) = @_;
  for ( $lo, $hi ) {
    croak __PACKAGE__.'::int: bounds must be integers' unless defined && !ref && /\A-?[0-9]+\z/;
  }
  croak __PACKAGE__.'::int: lower bound above upper bound' if $lo > $hi;
  my $n = $hi - $lo + 1;
  croak __PACKAGE__.'::int: range wider than 2**32' if $n > 4294967296;
  # rejection keeps every value equally likely
  my $limit = 4294967296 - ( 4294967296 % $n );
  my $u;
  do { $u = $self->next_u32 } until $u < $limit;
  return $lo + $u % $n;
}


sub float { $_[0]->next_u32 / 4294967296 }


sub pick {
  my ( $self, @list ) = @_;
  croak __PACKAGE__.'::pick: nothing to pick from' unless @list;
  return $list[ $self->int( 0, $#list ) ];
}


sub shuffle {
  my ( $self, @list ) = @_;
  for ( my $i = $#list; $i > 0; $i-- ) {
    my $j = $self->int( 0, $i );
    @list[ $i, $j ] = @list[ $j, $i ];
  }
  return @list;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Random - The seeded private random source for case generators

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Random;

  my $rng = Langertha::Holmgang::Random->new( seed => 4711 );

  my $n    = $rng->int( 10, 99 );            # 10 .. 99, both included
  my $f    = $rng->float;                    # 0 <= $f < 1
  my $host = $rng->pick(qw( web1 web2 db1 ));
  my @deck = $rng->shuffle( 1 .. 10 );

=head1 DESCRIPTION

The random source a generator of the case DSL gets
(L<Langertha::Holmgang/generate>, ADR 0007): a seeded object of its own, so
the same seed gives the same numbers on every perl and platform, and no other
module's use of C<rand> or C<srand> can move it.

The algorithm is fixed: xoshiro128** (Blackman and Vigna) over four 32-bit
words, seeded by splitmix32 from the seed. Changing it changes every generated
suite, so it never changes without a version raised in every suite that
generates. Pure Perl; it needs a perl with 64-bit integers, as
L<Langertha::Holmgang::Haystack> does.

Never C<srand>/C<rand> in a generator: the global generator is shared with
every other module, so the cases would depend on what ran before.

=head2 seed

Required. An integer from 0 to 4294967295 (2**32 - 1).

=head2 next_u32

The next raw value, an integer from 0 to 4294967295. The other methods draw
from it.

=head2 int

  my $n = $rng->int( 1, 6 );

An integer from C<$lo> to C<$hi>, both included, every value equally likely.

=head2 float

A number from 0 (included) to 1 (excluded), in steps of 2**-32.

=head2 pick

  my $host = $rng->pick( @hosts );

One element of the list.

=head2 shuffle

  my @order = $rng->shuffle( @items );

The list in a random order (Fisher–Yates).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
