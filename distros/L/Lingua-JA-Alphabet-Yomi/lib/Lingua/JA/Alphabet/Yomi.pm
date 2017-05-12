package Lingua::JA::Alphabet::Yomi;
use strict;
use warnings;
our $VERSION = '0.02';

use utf8;
use Carp;
use Unicode::Japanese;

use base 'Exporter';
our @EXPORT_OK = qw( alphabet2yomi );

our $alphabet2yomi = {
    en => {qw(
        A エー B ビー C シー D ディー E イー F エフ G ジー H エッチ I アイ
        J ジェイ K ケー L エル M エム N エヌ O オー P ピー Q キュー R アール
        S エス T ティー U ユー V ブイ W ダブリュー X エックス Y ワイ Z ゼット
    )},

    fr => {qw(
        A アー B ベー C セー D デー E ウー F エフ G ジェー H アッシュ I イー
        J ジー K カー L エル M エム N エヌ O オー P ペー Q クー R エル
        S エス T テー U ユー V ヴェー W ドゥブラ X イクス Y イグレッグ Z ゼド
    )},

    it => {qw(
        A アー B ビー C チー D ディー E エー F エッフェ G ジー H アッカ I イー
        J イルンガ K カッパ L エッレ M エンメ N エンネ O オー P ピー Q クー R エッレ
        S エッセ T ティー U ウー V ヴー W ドッピオヴ X イクス Y イプシロン Z ゼータ
    )},
    
    de => {qw(
        A アー B ベー C ツェー D デー E エー F エフ G ゲー H ハー I イー
        J ヨット K カー L エル M エム N エヌ O オー P ペー Q クー R エール
        S エス T テー U ウー V ファウ W ヴェー X イクス Y ユプスィロン Z ツェット
    )},
};

sub alphabet2yomi {
    my $class = shift if $_[0] eq __PACKAGE__; ## no critic
    my ($text, $lang) = @_;
    
    $text ||= "";
    $lang = lc $lang || 'en';
     
    croak "lang:$lang is not supported"
        unless exists $alphabet2yomi->{$lang};
     
    $text =~ s{(\p{Latin})}{
        my $char = $1;
        my $work = Unicode::Japanese->new($char);
           $work = uc $work->z2hAlpha->getu;
        
        $alphabet2yomi->{$lang}{$work} || $char;
    }ge;

    $text;
}

1;
__END__

=encoding utf-8

=head1 NAME

Lingua::JA::Alphabet::Yomi - Alphabet Katakana pronunciations

=head1 SYNOPSIS

  use Lingua::JA::Alphabet::Yomi qw(alphabet2yomi);
  use utf8;

  print alphabet2yomi("ＡBc");       # エービーシー
  print alphabet2yomi("ＡBc", 'fr'); # アーペーセー
  print alphabet2yomi("ＡBc", 'it'); # アービーチー
  print alphabet2yomi("ＡBc", 'de'); # アーベーツェー

=head1 DESCRIPTION

Lingua::JA::Alphabet::Yomi tells the pronunciation of the alphabet
by the Japanese katakana.

=head1 METHODS

=over 4

=item alphabet2yomi( $text, [ $lang ] )

exportable.

C<$lang> can take B<'en'>(英語), B<'fr'>(フランス語), B<'it'>(イタリア語)
and B<'de'>(ドイツ語) currently. 'en' is default.

I chose the pronunciation that seemed a de facto standard it.
but you can adjust C<$Lingua::JA::Alphabet::Yomi::alphabet2yomi> hashref
like below.

  local $Lingua::JA::Alphabet::Yomi::alphabet2yomi->{it}{J} = 'ヨータ';

=back

=head1 SEE ALSO

L<http://coderepos.org/share/browser/lang/perl/Lingua-JA-Alphabet-Yomi> (repository)

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
