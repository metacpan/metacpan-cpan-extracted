package Math::ModInt::Perl;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);

# ----- object definition -----

# Math::ModInt::Perl=ARRAY(...)

# .......... index ..........   # .......... value ..........
use constant F_RESIDUE => 0;    # residue r, 0 <= r < m
use constant F_MODULUS => 1;    # modulus m
use constant NFIELDS   => 2;

# ----- class data -----

use constant _OPT_THRESHOLD =>   256;
use constant _OPT_LIMIT     => 32768;

BEGIN {
    require Math::ModInt;
    our @ISA     = qw(Math::ModInt);
    our $VERSION = '0.013';
}

my %inverses = ();

# ----- private methods -----

# special case of _NEW, not using modulo, no class method
sub _make {
    my ($this, $r) = @_;
    return bless [$r, $this->[F_MODULUS]], ref $this;
}

sub _mod_inv {
    my ($r, $mod) = @_;
    my $inv = $inverses{$mod};
    if ($inv) {
        my $i = $inv->[$r];
        return $i if defined $i;
    }
    elsif (!defined($inv) && $mod <= _OPT_THRESHOLD) {
        $inv = $inverses{$mod} = [0];
    }
    my ($d, $dd, $i, $ii) = ($mod, $r, 0, 1);
    while ($dd) {
        my $f     = int($d / $dd);
        ($d, $dd) = ($dd, $d - $f * $dd);
        ($i, $ii) = ($ii, $i - $f * $ii);
    }
    if (1 != $d) {
        $i = 0;
    }
    elsif ($i < 0) {
        $i += $mod;
    }
    if ($inv) {
        $inv->[$r] = $i;
        if ($i) {
            $inv->[$i] = $r;
        }
    }
    return $i;
}

sub _NEG {
    my ($this) = @_;
    my ($r, $mod) = @{$this};
    return $this if !$r;
    return $this->_make($mod-$r);
}

sub _ADD {
    my ($this, $that) = @_;
    my $r = $this->[F_RESIDUE] + $that->[F_RESIDUE];
    my $mod = $this->[F_MODULUS];
    if ($mod <= $r) {
        $r -= $mod;
    }
    return $this->_make($r);
}

sub _SUB {
    my ($this, $that) = @_;
    my $r = $this->[F_RESIDUE] - $that->[F_RESIDUE];
    my $mod = $this->[F_MODULUS];
    if ($r < 0) {
        $r += $mod;
    }
    return $this->_make($r);
}

sub _MUL {
    my ($this, $that) = @_;
    return $this->_NEW($this->[F_RESIDUE]*$that->[F_RESIDUE]);
}

sub _DIV {
    my ($this, $that) = @_;
    my $mod = $this->[F_MODULUS];
    my $i = _mod_inv($that->[F_RESIDUE], $mod);
    return $this->undefined if !$i;
    return $this->_NEW($this->[F_RESIDUE]*$i);
}

sub _POW {
    my ($this, $exp) = @_;
    my ($r, $mod) = @{$this};
    return $this->_make(1) if !$exp;
    if ($exp < 0) {
        $r = _mod_inv($r, $mod);
        return $this->undefined if !$r;
        $exp = -$exp;
    }
    elsif (!$r) {
        return $this;
    }
    my $p = 1;
    while ($exp) {
        if (1 & $exp) {
            $p = $p*$r % $mod;
        }
        $exp >>= 1 and $r = $r*$r % $mod;
    }
    return $this->_make($p);
}

sub _INV {
    my ($this) = @_;
    my ($r, $mod) = @{$this};
    my $i = _mod_inv($r, $mod);
    return $this->undefined if !$i;
    return $this->_NEW($i);
}

sub _NEW {
    my ($this, $residue, $modulus) = @_;
    my $class = ref $this;
    if ($class) {
        $modulus = $this->[F_MODULUS];
    }
    else {
        $class = $this;
    }
    return bless [$residue % $modulus, $modulus], $class;
}

# ----- public methods -----

sub residue {
    my ($this) = @_;
    return $this->[F_RESIDUE];
}

sub modulus {
    my ($this) = @_;
    return $this->[F_MODULUS];
}

sub optimize_time {
    my ($this) = @_;
    my $mod = $this->modulus;
    if ($mod <= _OPT_LIMIT) {
        $inverses{$mod} ||= [0];
    }
    return $this;
}

sub optimize_space {
    my ($this) = @_;
    $inverses{$this->modulus} = 0;
    return $this;
}

sub optimize_default {
    my ($this) = @_;
    my $mod = $this->modulus;
    if (exists $inverses{$mod} and $mod > _OPT_THRESHOLD || !$inverses{$mod}) {
        delete $inverses{$mod};
    }
    return $this;
}

1;

__END__

=head1 NAME

Math::ModInt::Perl - modular integer arithmetic, powered by native Perl

=head1 VERSION

This documentation refers to version 0.013 of Math::ModInt::Perl.

=head1 SYNOPSIS

  use Math::ModInt::Perl;

  $a = Math::ModInt::Perl->new(3, 7);             # 3 [mod 7]
  $b = $a->new(4);                                # 4 [mod 7]
  $c = $a + $b;                                   # 0 [mod 7]
  $d = $a**2 - $b/$a;                             # 3 [mod 7]

  $m = $b->modulus;                               # 7
  $r = $b->residue;                               # 4
  $r = $b->signed_residue;                        # -3
  $t = "$b";                                      # 'mod(4, 7)'

  $bool = $c == $d;                               # false

  $a->optimize_time;                  # aim for less cpu cycles
  $a->optimize_space;                 # aim for less memory space
  $a->optimize_default;               # reset optimization choice

=head1 DESCRIPTION

Math::ModInt::Perl is a generic implementation of Math::ModInt for
small moduli, using native Perl integer arithmetic.  Like all
Math::ModInt implementations, it is loaded behind the scenes when
there is demand for it, without applications needing to worry about
it.

This implementation is capable of different optimization strategies
per modulus.  See I<optimize_time>, I<optimize_space>, I<optimize_default>
in L<Math::ModInt>.

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt>

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2021 Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
