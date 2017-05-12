package Encode::Base58::BigInt;
use strict;
use warnings;

our $VERSION = '0.03';
use Math::BigInt;
use Carp;

use base qw(Exporter);
our @EXPORT = qw( encode_base58 decode_base58 );

# except 0 O D / 1 l I
my $chars = [qw(
    1 2 3 4 5 6 7 8 9
    a b c d e f g h i
    j k m n o p q r s
    t u v w x y z A B
    C D E F G H J K L
    M N P Q R S T U V
    W X Y Z
)];

my $reg = qr/^[@{[ join "", @$chars ]}]+$/;

my $map = do {
    my $i = 0;
    +{ map { $_ => $i++ } @$chars };
};

sub encode_base58 {
    my ($num) = @_;
    return $chars->[0] unless $num;

    $num = Math::BigInt->new($num);

    my $res = '';
    my $base = @$chars;

    while ($num->is_pos) {
        my ($quo, $rem) = $num->bdiv($base);
        $res = $chars->["$rem"] . $res;
    }

    $res;
}

sub decode_base58 {
    my $str = shift;
    $str =~ tr/0OlI/DD11/;
    $str =~ $reg or croak "Invalid Base58";

    my $decoded = Math::BigInt->new(0);
    my $multi   = Math::BigInt->new(1);
    my $base    = @$chars;

    while (length $str > 0) {
        my $digit = chop $str;
        $decoded->badd($multi->copy->bmul($map->{$digit}));
        $multi->bmul($base);
    }

    "$decoded";
}

1;
__END__

=head1 NAME

Encode::Base58::BigInt - Base58 encodings with BigInt

=head1 SYNOPSIS

  use Encode::Base58::BigInt;
  my $bigint  = '9235113611380768826';
  my $encoded = encode_base58($bigint);
  my $decoded = decode_base58($short); # decoded is bigint string


=head1 DESCRIPTION

Encode::Base58::BigInt is a base58 encoder/decoder implementation in Perl.

Generated strings excludes confusing characters, "0" and "O" is treated as "D", "l" and "I" is treated as "1".

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

L<Encode::Base58>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
