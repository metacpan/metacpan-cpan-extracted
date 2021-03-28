package Math::ModInt::GF3;

use 5.006;
use strict;
use warnings;

# ----- object definition -----

# Math::ModInt::GF3=ARRAY(...)

# .......... index ..........   # .......... value ..........
use constant F_RESIDUE => 0;    # residue r, 0 .. 2
use constant NFIELDS   => 1;

# ----- class data -----

BEGIN {
    require Math::ModInt;
    our @ISA     = qw(Math::ModInt);
    our $VERSION = '0.013';
}

my @base = map { bless [$_] } 0..2;     # singletons
my @sgn  = (0, 1, -1);
my @neg  = @base[0, 2, 1];
my @add  = (\@base,           [@base[1, 2, 0]], [@base[2, 0, 1]]);
my @sub  = (\@neg,            [@base[1, 0, 2]], [@base[2, 1, 0]]);
my @mul  = ([@base[0, 0, 0]], \@base,           \@neg           );
my @pow  = (
    sub { $_[0] < 0? Math::ModInt->undefined: $base[!$_[0]] },
    sub { $base[            1] },
    sub { $base[$_[0] % 2 + 1] },
);

*centered_residue = \&signed_residue;

# ----- private methods -----

sub _NEG { $neg[$_[0]->[F_RESIDUE]] }
sub _ADD { $add[$_[0]->[F_RESIDUE]]->[$_[1]->[F_RESIDUE]] }
sub _SUB { $sub[$_[0]->[F_RESIDUE]]->[$_[1]->[F_RESIDUE]] }
sub _MUL { $mul[$_[0]->[F_RESIDUE]]->[$_[1]->[F_RESIDUE]] }
sub _POW { $pow[$_[0]->[F_RESIDUE]]->($_[1]) }
sub _INV { $_[0]->[F_RESIDUE]? $_[0]: Math::ModInt->undefined }
sub _NEW { $base[$_[1] % 3] }

sub _DIV {
    my $this = $_[0]->[F_RESIDUE];
    my $that = $_[1]->[F_RESIDUE];
    return $that? $mul[$this]->[$that]: Math::ModInt->undefined;
}

sub residue        {      $_[0]->[F_RESIDUE]  }
sub signed_residue { $sgn[$_[0]->[F_RESIDUE]] }
sub modulus        { 3 }

1;

__END__

=head1 NAME

Math::ModInt::GF3 - integer arithmetic modulo 3

=head1 VERSION

This documentation refers to version 0.013 of Math::ModInt::GF3.

=head1 SYNOPSIS

  use Math::ModInt;

  $a = Math::ModInt->new(2, 3);                   # 2 [mod 3]
  $b = $a->new(0);                                # 0 [mod 3]
  $c = $a + $b;                                   # 2 [mod 3]
  $d = $a**2 - $b/$a;                             # 1 [mod 3]

  print $d->residue, " [mod ", $b->modulus, "]";  # prints 1 [mod 3]
  print "$d";                                     # prints mod(1, 3)

  $bool = $c == $d;                               # false

=head1 DESCRIPTION

Math::ModInt::GF3 is an implementation of Math::ModInt for modulus
three.  Like all Math::ModInt implementations, it is loaded behind
the scenes when there is demand for it, without applications needing
to worry about it.  Implementations for special cases like this can
take advantage of properties specific to their subdomain and be
therefore substantially more efficient than generic ones.

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt>

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2021 Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
