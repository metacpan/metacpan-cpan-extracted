package Geography::JapanesePrefectures;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.11';

use Geography::JapanesePrefectures::Unicode;
use Carp   ();
use Encode ();

sub prefectures {
    my $self = shift;
    return
      map { Encode::encode_utf8($_) }
      Geography::JapanesePrefectures::Unicode->prefectures();
}

sub regions {
    my $self = shift;
    return
      map { Encode::encode_utf8($_) }
      Geography::JapanesePrefectures::Unicode->regions();
}

sub prefectures_in {
    my ( $self, $region ) = @_;
    return
      map { Encode::encode_utf8($_) }
      Geography::JapanesePrefectures::Unicode->prefectures_in(
        Encode::decode_utf8($region) );
}

sub prefectures_id {
    my ( $self, $prefecture ) = @_;
    return Geography::JapanesePrefectures::Unicode->prefectures_id(
        Encode::decode_utf8($prefecture) );
}

sub prefectures_infos {
    my $infos = Geography::JapanesePrefectures::Unicode->prefectures_infos;
    my @ret;
    for my $info (@$infos) {
        my %row;
        while (my ($key, $val) = each %$info) {
            $row{$key} = Encode::encode_utf8($val);
        }
        push @ret, \%row;
    }
    return \@ret;
}

1;
__END__

=encoding utf8

=for stopwords prefecture's

=head1 NAME

Geography::JapanesePrefectures - Japanese Prefectures Data.

=head1 DESCRIPTION

This module is deprecated.do not use directly.
You should call Geography::JapanesePrefectures::Unicode instead of this.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<http://ja.wikipedia.org/wiki/JIS_X_0401#.E9.83.BD.E9.81.93.E5.BA.9C.E7.9C.8C.E3.82.B3.E3.83.BC.E3.83.89>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
