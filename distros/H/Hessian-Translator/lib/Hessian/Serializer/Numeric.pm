package  Hessian::Serializer::Numeric;

use Moose::Role;

use integer;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt try => 'GMP';
use POSIX qw/floor ceil/;

sub write_integer {    #{{{
    my ( $self, $integer ) = @_;
    my $result =
      -16 <= $integer && $integer <= 47 ? _write_single_octet( $integer, 0x90 )
      : -2048 <= $integer
      && $integer <= 2047 ? _write_double_octet( $integer, 0xc8 )
      : -262144 <= $integer
      && $integer <= 262143 ? _write_triple_octet( $integer, 0xd4 )
      :                       'I' . _write_quadruple_octet($integer);
    return $result;
}

sub write_long {    #{{{
    my ( $self, $long ) = @_;
    my $result =
        -8 <= $long && $long <= 15 ? _write_single_octet( $long, 0xe0 )
      : -2048 <= $long && $long <= 2047 ? _write_double_octet( $long, 0xf8 )
      : -262144 <= $long && $long <= 262143 ? _write_triple_octet( $long, 0x3c )
      :                                       'L' . _write_full_long($long);
    return $result;
}

sub write_double {    #{{{
    my ( $self, $double ) = @_;
    my $hessian_string;
    my $compare_with = $double < 0 ? ceil($double) : floor($double);
    if ( $double eq $compare_with ) {
        $hessian_string =
        $double == 0 ? "\x5b"    :
        $double == 1 ? "\x5c"    :
             $double > -129
          && $double < 128 ? "\x5d" . _write_single_octet_float($double)
          : $double > -32769
          && $double < 32768 ? "\x5e" . _write_double_octet_float($double)
          :                    "D" . _write_full_double($double);

    }
    else {
        $hessian_string = "D" . _write_full_double($double);
    }

    return $hessian_string;

}

sub write_boolean {    #{{{
    my ( $self, $bool_val ) = @_;
    return
        $bool_val =~ /(?:1|t(?:rue)?)/i  ? 'T'
      : $bool_val =~ /(?:0|f(?:alse)?)/i ? 'F'
      :                                    'N';
}

sub _write_quadruple_octet {    #{{{
    my $integer = shift;
    my $new_int = pack 'N', $integer;
    return $new_int;
}

sub _write_single_octet {    #{{{
    my ( $number, $octet_shift ) = @_;
    my $new_int = pack "C*", ( $number + $octet_shift );
    return $new_int;
}

sub _write_double_octet {    #{{{
    my ( $integer, $octet_shift ) = @_;

    # {-2048 >= x >= 2047: x = 256 * (b0 - xd8) + b1 }
    my $big_short = pack "n", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit = ( ( $integer - $bytes[0] ) >> 8 ) + $octet_shift;
    my $new_int = pack 'C*', $high_bit, $bytes[0];
    return $new_int;
}

sub _write_triple_octet {    #{{{
    my ( $integer, $octet_shift ) = @_;

    # { -262144 >= x >= 262143: x = 65536 * (b0 - x5c) + 256 * b1 + b0}
    my $big_short = pack "N", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit =
      ( ( $integer - $bytes[0] - ( $bytes[1] >> 8 ) ) >> 16 ) + $octet_shift;
    my $new_int = pack 'C*', $high_bit, $bytes[1], $bytes[0];
    return $new_int;
}

sub _write_full_long {    #{{{
        # This will probably only work with Math::BigInt or similar
    my $long       = shift;
    my $int64      = int64($long);
    my $net_string = int64_to_net($int64);
    return $net_string;
}

sub _write_single_octet_float {    #{{{
    my $double = shift;
    my $hessian_string = pack 'c*', $double;
    return $hessian_string;
}

sub _write_double_octet_float {    #{{{
    my $double = shift;
    my $hessian_string = pack 'n', unpack 'S', pack "s", $double;
    return $hessian_string;

}

sub _write_full_double {    #{{{
    my $double         = shift;
    my $native_float   = pack 'F', $double;
    my @chars          = unpack 'C*', $native_float;
    my $hessian_string = pack 'C*', reverse @chars;
    return $hessian_string;
}

"one, but we're not the same";

__END__



=head1 NAME

Hessian::Serializer::Numeric - Roles for serialization of integers, floating
point numbers, dates and boolean expressions into Hessian.


=head1 SYNOPSIS

These methods are only made to be used within the Hessian framework.

=head1 DESCRIPTION

This module provides methods for serializing numbers and boolean values into
Hessian.

=head1 INTERFACE

=head2   write_boolean


=head2   write_double


=head2   write_integer


=head2   write_long

