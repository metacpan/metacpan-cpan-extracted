package Encode::Base58;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use base qw(Exporter);
our @EXPORT = qw( encode_base58 decode_base58 );

my @alpha = qw(
    1 2 3 4 5 6 7 8 9
    a b c d e f g h i
    j k m n o p q r s
    t u v w x y z A B
    C D E F G H J K L
    M N P Q R S T U V
    W X Y Z
);

my $i = 0;
my %alpha = map { $_ => $i++ } @alpha;

sub encode_base58 {
    my $num = shift;

    return $alpha[0] if $num == 0;

    my $res = '';
    my $base = @alpha;

    while ($num > 0) {
        my $remain = $num % $base;
        $num = int($num / $base);
        $res = $alpha[$remain] . $res;
    }

    return $res;
}

sub decode_base58 {
    my $str = shift;

    my $decoded = 0;
    my $multi   = 1;
    my $base    = @alpha;

    while (length $str > 0) {
        my $digit = chop $str;
        $decoded += $multi * $alpha{$digit};
        $multi   *= $base;
    }

    return $decoded;
}

1;
__END__

=encoding utf-8

=for stopwords
Flickr Flickr's

=for test_synopsis
my $number;

=head1 NAME

Encode::Base58 - Base58 encodings (for Flickr short URI)

=head1 SYNOPSIS

  use Encode::Base58;

  my $short  = encode_base58($number);
  my $number = decode_base58($short);

=head1 DESCRIPTION

Encode::Base58 is a base58 encoder/decoder implementation in
Perl. Base58 encoding is used in shortening ID numbers into a short
string for Flickr's short URL (C<flic.kr>).

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.flickr.com/groups/api/discuss/72157616713786392/>

L<http://gist.github.com/101753> (in Ruby)

L<http://gist.github.com/101674> (in Objective-C and unit tests)

=cut
