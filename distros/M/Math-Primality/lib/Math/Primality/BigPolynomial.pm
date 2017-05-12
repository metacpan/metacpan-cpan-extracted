package Math::Primality::BigPolynomial;
{
  $Math::Primality::BigPolynomial::VERSION = '0.08';
}

use strict;
use warnings;
use Math::GMPz qw/:mpz/;

# ABSTRACT: Big Polynomials



sub new {
    my $self              = {};
    my $class             = shift;
    my $construction_junk = shift;
    if ($construction_junk) {
        my $type = ref $construction_junk;
        if ( $type eq 'ARRAY' ) {
            $self->{COEF}   = $construction_junk;
        } elsif ( $type eq 'Math::Primality::BigPolynomial') {
            foreach my $coef (@{$construction_junk->{COEF}}) {
              my $temp = Rmpz_init_set($coef);
              push @{$self->{COEF}}, $temp;
            }
        } else {
            my $a = [];
            for ( my $i = 0 ; $i < $construction_junk ; $i++ ) {
                push @$a, Math::GMPz->new(0);
            }
            $self->{COEF} = $a;
        }
    }
    else {
        $self->{COEF}   = [ Math::GMPz->new(0) ];
    }
    bless( $self, $class );
    return $self;
}

sub coef {
    my $self = shift;
    if (@_) { @{ $self->{COEF} } = @_ }
    return @{ $self->{COEF} };
}

sub degree {
    my $self = shift;
    return (scalar @{$self->{COEF}} - 1);
}

sub getCoef {
    my $self = shift;
    my $i    = shift;
    if ( $i > $self->degree() ) {
        return Math::GMPz->new(0);
    }
    return undef if $i < 0;
    return $self->{COEF}->[$i];
}

sub isEqual {
    my $self             = shift;
    my $other_polynomial = shift;
    if ( $self->degree() != $other_polynomial->degree() ) {
        return 0;
    }
    for ( my $i = 0 ; $i < $self->degree() ; $i++ ) {
        if ( $self->getCoef($i) != $other_polynomial->getCoef($i) ) {
            return 0;
        }
    }
    return 1;
}

sub setCoef {
    my $self     = shift;
    my $new_coef = shift;
    my $index    = shift;
    if ( $index < 0 ) {
        die "coef is less than 0";
    }

    if ( $index > $self->degree() ) {
        for ( my $j = $self->degree() + 1 ; $j < $index ; $j++ ) {
            push @{ $self->{COEF} }, Math::GMPz->new(0);
        }
        $self->{COEF}->[$index] = $new_coef;
        $self->degree($index);
    }
    else {
        $self->{COEF}->[$index] = $new_coef;
    }
}

sub compact {
    my $self = shift;
    my $i    = 0;
  LOOP: for ( $i = $self->degree(); $i > 0 ; $i-- ) {
        if ( Math::GMPz::Rmpz_cmp_ui( $self->getCoef($i), 0 ) != 0 ) {
            last LOOP;
        }
        pop @{ $self->{COEF} };
    }
    if ( $i != $self->degree() ) {
        $self->degree( $i );
    }
}

sub clear {
    my $self = shift;
    $self->{COEF}   = [ Math::GMPz->new(0) ];
}

sub mpz_poly_mod_mult {
    my ( $rop, $copy_x, $copy_y, $mod, $polymod ) = @_;
    my $x = Math::Primality::BigPolynomial->new($copy_x);
    my $y = Math::Primality::BigPolynomial->new($copy_y);

    die "mpz_poly_mod_mult: polymod must be defined!" unless $polymod;

    $rop->clear();

    my $xdeg   = ref $x ? $x->degree() : 0;
    my $ydeg   = ref $y ? $y->degree() : 0;
    my $maxdeg = $xdeg < $ydeg ? $ydeg : $xdeg;

  LOOP: for ( my $i = 0 ; $i < $polymod ; $i++ ) {
        my $sum  = Math::GMPz->new(0);
        my $temp = Math::GMPz->new(0);
        for ( my $j = 0 ; $j <= $i ; $j++ ) {
            Rmpz_add($temp, $y->getCoef( $i - $j ),
                     $y->getCoef( $i + $polymod - $j ) );
            Rmpz_mul( $temp, $x->getCoef($j), $temp );
            Rmpz_add( $sum, $sum, $temp );
        }

        for ( my $j = 0 ; $j < ( $i + $polymod ) ; $j++ ) {
            Rmpz_mul( $temp, $x->getCoef($j),
                $y->getCoef( $i + $polymod - $j ) );
            Rmpz_add( $sum, $sum, $temp );
        }

        Rmpz_mod( $temp, $sum, $mod );
        $rop->setCoef( $temp, $i );

        if ( $i > $maxdeg && Rmpz_cmp_ui( $sum, 0 ) == 0 ) {
            last LOOP;
        }
    }

    $rop->compact();
}

sub mpz_poly_mod_power {
    my ( $rop, $x, $power, $mult_mod, $poly_mod ) = @_;

    die "mpz_poly_mod_power: polymod must be defined!" unless $poly_mod;

    $rop->clear();
    $rop->setCoef( Math::GMPz->new(1), 0 );

    my $i = Rmpz_sizeinbase( $power, 2 );

  LOOP: for ( ; $i >= 0 ; $i-- ) {
        mpz_poly_mod_mult( $rop, $rop, $rop, $mult_mod, $poly_mod );

        if ( Rmpz_tstbit( $power, $i ) ) {
            mpz_poly_mod_mult( $rop, $rop, $x, $mult_mod, $poly_mod );
        }

        if ( $i == 0 ) {
            last LOOP;
        }
    }

    $rop->compact();
}

1;

__END__

=pod

=head1 NAME

Math::Primality::BigPolynomial - Big Polynomials

=head1 VERSION

version 0.08

=head1 NAME

Math::Primality::BigPolynomials - Polynomials with BigInts

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leto Labs LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
