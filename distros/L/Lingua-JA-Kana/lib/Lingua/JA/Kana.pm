package Lingua::JA::Kana;
use warnings;
use strict;
use utf8;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.7 $ =~ /(\d+)/g;

use re ();
require Exporter;
use base qw/Exporter/;
our @EXPORT = qw(
 hira2kata hiragana2katakana
 kata2hira katakana2hiragana
 romaji2hiragana romaji2katakana
 kana2romaji
 hankaku2zenkaku zenkaku2hankaku
);

our $USE_REGEXP_ASSEMBLE = do {
    eval 'require Regexp::Assemble';
    $@ ? 0 : 1;
};


our $Re_Vowels     = qr/[aeiou]/i;
our $Re_Consonants = qr/[bcdfghjklpqrstvwxyz]/i; # note the absense of n and m

our %Kata2Hepburn = qw(
  ア   a       イ   i       ウ   u       エ   e       オ   o
  ァ   xa      ィ   xi      ゥ   xu      ェ   xe      ォ   xo
  カ   ka      キ   ki      ク   ku      ケ   ke      コ   ko
  ガ   ga      ギ   gi      グ   gu      ゲ   ge      ゴ   go
  キャ kya                  キュ kyu                  キョ kyo
  ギャ gya                  ギュ gyu                  ギョ gyo
  サ   sa      シ   shi     ス   su      セ   se      ソ   so
  ザ   za      ジ   ji      ズ   zu      ゼ   ze      ゾ   zo
  シャ sha                  シュ shu                  ショ sho
  ジャ ja                   ジュ ju                   ジョ jo
  タ   ta      チ   chi     ツ   tsu     テ   te      ト   to
               ティ ti      トゥ tu
  ダ   da      ディ di      ドゥ du      デ   de      ド   do
               ヂ   dhi     ヅ   dhu
  チャ cha                  チュ chu     チェ che     チョ cho
  ヂャ dha                  ヂュ dhu     ヂェ dhe     ヂョ dho
  ナ   na      ニ   ni      ヌ   nu      ネ   ne      ノ   no
  ニャ nya                  ニュ nyu                  ニョ nyo
  ハ   ha      ヒ   hi      フ   fu      ヘ   he      ホ   ho
  ヒャ hya                  ヒュ hyu                  ヒョ hyo
  バ   ba      ビ   bi      ブ   bu      ベ   be      ボ   bo
  ビャ bya                  ビュ byu                  ビョ byo
  パ   pa      ピ   pi      プ   pu      ペ   pe      ポ   po
  ピャ pya                  ピュ pyu                  ピョ pyo
  ファ fa      フィ fi                   フェ fe      フォ fo
  マ   ma      ミ   mi      ム   mu      メ   me      モ   mo
  ミャ mya                  ミュ myu                  ミョ myo
  ヤ   ya                   ユ   yu      イェ ye      ヨ   yo
  ャ   xya                  ュ   xyu                  ョ   xyo
  ラ   ra      リ   ri      ル   ru      レ   re      ロ   ro
  リャ rya                  リュ ryu                  リョ ryo
  ワ   wa      ヰ   wi                   ヱ   we      ヲ   wo
  ウァ wa      ウィ wi                   ウェ we      ウォ wo
  ヴァ va      ヴィ vi      ヴ   vu      ヴェ ve      ヴォ vo
  ン   n
);

our %Kana2Hepburn =
  ( %Kata2Hepburn, map { katakana2hiragana($_) } %Kata2Hepburn );

our $Re_Kana2Hepburn = do {
    if ($USE_REGEXP_ASSEMBLE) {
        my $ra = Regexp::Assemble->new();
        $ra->add($_) for keys %Kana2Hepburn;
        $ra->re;
    }
    else {
        my $str = join '|', keys %Kana2Hepburn;
        qr/(?:$str)/;
    }
};

our %Romaji2Kata = qw(
  a    ア      i    イ      u    ウ      e    エ      o    オ
  xa   ァ      xi   ィ      xu   ゥ      xe   ェ      xo   ォ
  ka   カ      ki   キ      ku   ク      ke   ケ      ko   コ
  ga   ガ      gi   ギ      gu   グ      ge   ゲ      go   ゴ
  kya  キャ                 kyu キュ                  kyo  キョ
  gya  ギャ                 gyu ギュ                  gyo  ギョ 
  sa   サ      shi  シ      su   ス      se   セ      so   ソ
               si   シ
  za   ザ      ji   ジ      zu   ズ      ze   ゼ      zo   ゾ
               zi   ジ
  sha  シャ                 shu  シュ                 sho  ショ
  ja   ジャ                 ju   ジュ                 jo   ジョ
  sya  シャ                 syu  シュ                 syo  ショ
  ta   タ      chi  チ      tsu  ツ      te   テ      to   ト
                            xtu  ッ 
               ti   ティ    tu   トゥ
  da   ダ      di   ディ    du   ドゥ    de   デ      do   ド
               dhi  ヂ      dhu  ヅ
  cha  チャ                 chu  チュ    che  チェ    cho  チョ
  tya  チャ                 tyu  チュ    tye  チェ    tyo  チョ
  dha  ヂャ                 dhu  ヂュ    dhe  ヂェ    dho  ヂョ
  dya  ヂャ                 tyu  ヂュ    tye  ヂェ    tyo  ヂョ
  na   ナ      ni   ニ      nu   ヌ      ne   ネ      no   ノ
  nya ニャ                  nyu ニュ                  nyo ニョ 
  ha   ハ      hi   ヒ      fu   フ      he   ヘ      ho   ホ
                            hu   フ
  hya  ヒャ                 hyu  ヒュ                 hyo  ヒョ
  ba   バ      bi   ビ      bu   ブ      be   ベ      bo   ボ
  bya  ビャ                 byu  ビュ                 byo  ビョ
  pa   パ      pi   ピ      pu   プ      pe   ペ      po   ポ
  pya  ピャ                 pyu  ピュ                 pyo  ピョ
  fa   ファ    fi   フィ                 fe   フェ    fo   フォ
  ma   マ      mi   ミ      mu   ム      me   メ      mo   モ
  mya ミャ                  myu ミュ                  myo ミョ 
  ya   ヤ                   yu   ユ      ye   イェ    yo   ヨ
  xya  ャ                   xyu  ュ                   xyo  ョ
  ra   ラ      ri   リ      ru   ル      re   レ      ro   ロ
  rya  リャ                 ryu  リュ                 ryo  リョ
  la   ラ      li   リ      lu   ル      le   レ      lo   ロ
  wa   ワ                                             wo   ヲ
               wi   ウィ                 we   ウェ
  va   ヴァ    vi   ヴィ    vu   ヴ      ve   ヴェ    vo   ヴォ
);

our $Re_Romaji2Kata = do {
    if ($USE_REGEXP_ASSEMBLE) {
        my $ra = Regexp::Assemble->new();
        $ra->add($_) for keys %Romaji2Kata;
        my $str = $ra->re;
        if ($] >= 5.009005) {
            my ($pattern, $mod) = re::regexp_pattern($str);
            $str = $pattern;
        } else {
            substr( $str, 0,  8, '' );    # remove '(?-xism:'
            substr( $str, -1, 1, '' );    # and ')';
        }
        qr/$str/i;                    # and recompile with i
    }
    else {
        my $str = join '|', sort {length($b) <=> length($a)} keys %Romaji2Kata;
        qr/(?:$str)/i;
    }
};


our %Kana2Romaji    = %Kana2Hepburn;
our $Re_Kana2Romaji = $Re_Kana2Hepburn;

sub katakana2hiragana{
  my $str = shift;
  $str =~ tr/ァ-ンヴ/ぁ-んゔ/;
  $str;
}

sub hiragana2katakana{
  my $str = shift;
  $str =~ tr/ぁ-んゔ/ァ-ンヴ/;
  $str;
}

{
    no warnings 'once';
    *kata2hira = \&katakana2hiragana;
    *hira2kata = \&hiragana2katakana;
}

sub romaji2katakana{
  my $str = shift;
  # step 1; tta -> ッta
  $str =~ s{ ($Re_Consonants) \1 }{ "ッ$1" }msxgei;
  # step 2;
  $str =~ s{ ($Re_Romaji2Kata) }{ $Romaji2Kata{lc $1} || $1 }msxgei;
  # step 3;
  $str =~ s{ ([ァ-ン])[mn] }{ "$1ン" }msxgei;
  $str;
}

sub romaji2hiragana{ katakana2hiragana(romaji2katakana(shift)) };

sub kana2romaji{
  my $str = shift;
  # step 1;
  $str =~ s{ ($Re_Kana2Romaji) }{ $Kana2Romaji{$1} || $1 }msxge;
  # step 2; ッta -> tta
  $str =~ s{ [っッ]($Re_Consonants) }{ "$1$1" }msxge;
  # step 3; oー -> oo
  $str =~ s{ ($Re_Vowels)ー }{ "$1$1" }msxge;
  $str;
}


if ($0 eq __FILE__){
    warn $USE_REGEXP_ASSEMBLE;
    binmode STDOUT, ':utf8';
    local $\ = "\n";
    warn $Re_Romaji2Kata;
    print romaji2katakana("Dan Kogai");
    print romaji2katakana("shimbashi");
    print romaji2katakana("konnichiwa");
    print romaji2hiragana("Dan Kogai");
    print romaji2hiragana("shimbashi");
    warn $Re_Kana2Romaji;
    print kana2romaji("ダンコガイ");
    print kana2romaji("マイッタ");
    print kana2romaji("シンバシ");
    print romaji2hiragana("ryoukai");   # RT#39590
    print romaji2hiragana("virama");    # RT#45402
}

use Encode;
use Encode::JP::H2Z;
my $eucjp = Encode::find_encoding('eucjp');
sub hankaku2zenkaku { 
    my $str = $eucjp->encode(shift);
    Encode::JP::H2Z::h2z(\$str);
    $eucjp->decode($str);
}

sub zenkaku2hankaku { 
    my $str = $eucjp->encode(shift);
    Encode::JP::H2Z::z2h(\$str);
    $eucjp->decode($str);
}


1; # End of Lingua::JA::Kana
__END__

=head1 NAME

Lingua::JA::Kana - Kata-Romaji related utilities

=head1 VERSION

$Id: Kana.pm,v 0.7 2012/08/06 01:56:17 dankogai Exp $

=head1 SYNOPSIS

    use Lingua::JA::Kana;

    my $hiragana = romaji2hiragana("ohayou");
    my $katakana = romaji2katakana("ohasumi");
    my $romaji   = kana2romaji($str);

=head1 DESCRIPTION

This module is a simple utility to convert katakana, hiragana, and romaji
at ease.  This module makes use of utf8 semantics which is introduced in
Perl 5.8.0 and became stable enough in Perl 5.8.1 so you need Perl 5.8.1
or better.

Also note that strings in this module must be utf8-flagged.  If they are
not, you can use L<Encode> to do so.

  use Encode;
  use Lingua::JA::Kana
  my $romaji = kana2romaji(decode_utf8 $octet);

See L<Encode>, L<perluniintro>, and L<perlunicode> for details.

=head1 EXPORT

This module exports functions below:

=head2 hiragana2katakana

Converts all occurance of hiragana to katakana.

  my $hiragana = hiragana2katakana($str);

=over 2

=item hira2kata

its alias.

=back

=head2 katakana2hiragana

Converts all occurance of katakana to hiragana. C<kata2hira> is an alias thereof.

  my $katakana = katakana2hiragana($str);

=over 2

=item kata2hira

its alias.

=back

=head2 romaji2katakana

Converts all occurance of romaji to katakana.

  my $romaji = romaji2hiragana($str);

=head2 romaji2hiragana

Converts all occurance of romaji to hiragana.

  my $katakana = romaji2hiragana($str);

=head2 kana2romaji

Converts all occurance of kana (both katakana and hiragana) to romaji.

  my $romaji = kana2romaji($str);

=head2 hankaku2zenkaku

Converts all occurance of hankaku to zenkaku.

  my $romaji = hankaku2zenkaku($str);

=head2 zenkaku2hankaku

Converts all occurance  of zenkaku to hankaku.

  my $romaji = zenkaku2hankaku($str);

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-ja-kana at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-JA-Kana>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::JA::Kana


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-JA-Kana>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-JA-Kana>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-JA-Kana>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-JA-Kana>

=back

=head1 ACKNOWLEDGEMENTS

L<Lingua::JA::Romaji>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

