package Lingua::JA::Hepburn::Passport;

use strict;
our $VERSION = '0.02';

use utf8;
use Carp;

our %Map = (
    "あ", "A",
    "い", "I",
    "う", "U",
    "え", "E",
    "お", "O",
    "か", "KA",
    "き", "KI",
    "く", "KU",
    "け", "KE",
    "こ", "KO",
    "さ", "SA",
    "し", "SHI",
    "す", "SU",
    "せ", "SE",
    "そ", "SO",
    "た", "TA",
    "ち", "CHI",
    "つ", "TSU",
    "て", "TE",
    "と", "TO",
    "な", "NA",
    "に", "NI",
    "ぬ", "NU",
    "ね", "NE",
    "の", "NO",
    "は", "HA",
    "ひ", "HI",
    "ふ", "FU",
    "へ", "HE",
    "ほ", "HO",
    "ま", "MA",
    "み", "MI",
    "む", "MU",
    "め", "ME",
    "も", "MO",
    "や", "YA",
    "ゆ", "YU",
    "よ", "YO",
    "ら", "RA",
    "り", "RI",
    "る", "RU",
    "れ", "RE",
    "ろ", "RO",
    "わ", "WA",
    "ゐ", "I",
    "ゑ", "E",
    "を", "O",
    "ん", "N",
    "ぁ", "A",
    "ぃ", "I",
    "ぅ", "U",
    "ぇ", "E",
    "ぉ", "O",
    "が", "GA",
    "ぎ", "GI",
    "ぐ", "GU",
    "げ", "GE",
    "ご", "GO",
    "ざ", "ZA",
    "じ", "JI",
    "ず", "ZU",
    "ぜ", "ZE",
    "ぞ", "ZO",
    "だ", "DA",
    "ぢ", "JI",
    "づ", "ZU",
    "で", "DE",
    "ど", "DO",
    "ば", "BA",
    "び", "BI",
    "ぶ", "BU",
    "べ", "BE",
    "ぼ", "BO",
    "ぱ", "PA",
    "ぴ", "PI",
    "ぷ", "PU",
    "ぺ", "PE",
    "ぽ", "PO",
    "きゃ", "KYA",
    "きゅ", "KYU",
    "きょ", "KYO",
    "しゃ", "SHA",
    "しゅ", "SHU",
    "しょ", "SHO",
    "ちゃ", "CHA",
    "ちゅ", "CHU",
    "ちょ", "CHO",
    "ちぇ", "CHE",
    "にゃ", "NYA",
    "にゅ", "NYU",
    "にょ", "NYO",
    "ひゃ", "HYA",
    "ひゅ", "HYU",
    "ひょ", "HYO",
    "みゃ", "MYA",
    "みゅ", "MYU",
    "みょ", "MYO",
    "りゃ", "RYA",
    "りゅ", "RYU",
    "りょ", "RYO",
    "ぎゃ", "GYA",
    "ぎゅ", "GYU",
    "ぎょ", "GYO",
    "じゃ", "JA",
    "じゅ", "JU",
    "じょ", "JO",
    "びゃ", "BYA",
    "びゅ", "BYU",
    "びょ", "BYO",
    "ぴゃ", "PYA",
    "ぴゅ", "PYU",
    "ぴょ", "PYO",
);

sub new {
    my($class, %opt) = @_;
    bless { %opt }, $class;
}

sub _hepburn_for {
    my($string, $index) = @_;

    my($hepburn, $char);
    if ($index + 1 < length $string) {
        $char    = substr $string, $index, 2;
        $hepburn = $Map{$char};
    }
    if (!$hepburn && $index < length $string) {
        $char    = substr $string, $index, 1;
        $hepburn = $Map{$char};
    }

    return { char => $char, hepburn => $hepburn };
}

sub romanize {
    my($self, $string) = @_;

    unless (utf8::is_utf8($string)) {
        croak "romanize(string): should be UTF-8 flagged string";
    }

    $string =~ tr/ア-ン/あ-ん/;

    if ($self->{strict}) {
        $string =~ /^\p{Hiragana}*$/
            or croak "romanize(string): should be all Hiragana/Katakana";
    }

    my $output;
    my $last_hepburn;
    my $last_char;
    my $i = 0;

    while ($i < length $string) {
        my $hr = _hepburn_for($string, $i);

        # １．撥音 ヘボン式ではB ・M ・P の前に N の代わりに M をおく
        if ($hr->{char} eq 'ん') {
            my $next = _hepburn_for($string, $i + 1);
            $hr->{hepburn} = $next->{hepburn} && $next->{hepburn} =~ /^[BMP]/
                ? 'M' : 'N';
        }

        # ２．促音 子音を重ねて示す
        elsif ($hr->{char} eq 'っ') {
            my $next = _hepburn_for($string, $i + 1);

            # チ（CH I）、チャ（CHA）、チュ（CHU）、チョ（CHO）音に限り、その前に T を加える。
            if ($next->{hepburn}) {
                $hr->{hepburn} = $next->{hepburn} =~ /^CH/
                    ? 'T' : substr($next->{hepburn}, 0, 1);
            }
        }

        # ３．長音 ヘボン式では長音を表記しない
        elsif ($hr->{char} eq "ー") {
            $hr->{hepburn} = "";
        }

        # Japanese Passport table doesn't have entries for ぁ-ぉ
        elsif ($hr->{char} =~ /[ぁ-ぉ]/ && $self->{strict}) {
            croak "$hr->{char} is not allowed";
        }

        if (defined $hr->{hepburn}) {
            if ($last_hepburn) {
                my $h_test = $last_hepburn . $hr->{hepburn};
                if (length $h_test > 2) {
                    $h_test = substr $h_test, -2;
                }

                # ３．長音 ヘボン式では長音を表記しない
                if (grep $h_test eq $_, qw( AA II UU EE )) {
                    $hr->{hepburn} = '';
                }

                # 氏名に「オウ」又は「オオ」の長音が含まれる場合、
                # 「 O 」 か 「 OH 」 のいずれかの表記を選択することができる
                if (grep $h_test eq $_, qw( OO OU )) {
                    $hr->{hepburn} = $self->{long_vowels_h} ? 'H' : '';
                }
            }

            $output .= $hr->{hepburn};
        } else {
            if ($self->{strict}) {
                croak "Can't find hepburn replacement for $hr->{char}";
            }
            $output .= $hr->{char};
        }

        $last_hepburn = $hr->{hepburn};
        $last_char    = $hr->{char};
        $i += length $hr->{char};
    }

    return $output;
}

1;
__END__

=encoding utf-8

=head1 NAME

Lingua::JA::Hepburn::Passport - Hepburn Romanization using Japanese passport rules

=head1 SYNOPSIS

  use utf8;
  use Lingua::JA::Hepburn::Passport;

  my $hepburn = Lingua::JA::Hepburn::Passport->new;
  $hepburn->romanize("みやがわ");     # MIYAGAWA
  $hepburn->romanize("おおの");       # ONO
  $hepburn->romanize("かとう");       # KATO
  $hepburn->romanize("ゆうこ");       # YUKO
  $hepburn->romanize("なんば");       # NAMBA
  $hepburn->romanize("はっちょう");   # HATCHO

  # Indicate long vowels by "h"
  my $hepburn = Lingua::JA::Hepburn::Passport->new( long_vowels_h => 1 );
  $hepburn->romanize("おおの");       # OHNO
  $hepburn->romanize("かとう");       # KATOH

=head1 DESCRIPTION

Lingua::JA::Hepburn::Passport is a Hiragana/Katakana to Romanization
engine using Japanese passport rules.

=head1 WHY

There is already a couple of Hepburn romanization modules on CPAN (See
L</"SEE ALSO">), but none of them conform to the conversion rule
defined in Japanese passport regulation. This one does.

=head1 METHODS

=over 4

=item new

  $hepburn = Lingua::JA::Hepburn::Passport->new;
  $hepburn = Lingua::JA::Hepburn::Passport->new( long_vowels_h => 1 );

Creates a new object. Optionally you can pass I<long_vowels_h>
parameter to 1, with which this module tries to add I<H> to the long
vowels I<OO> and I<OU>, as allowed in Japanese passport rules.

=item romanize

  $roman = $hepburn->romanize( $kana );

Romanizes the string I<$kana> using Hepburn romanization. I<$kana>
should be either Hiragana or Katakana, as an Unicode string in Perl
(a.k.a UTF-8 flagged), otherwise it throws an error. Returned
I<$roman> would be all upper case roman letters.

=back

This module doesn't come with I<deromanize> method (yet), which would
do the Roman to Katakana/Hiragana translation, since I don't think we
need it. Other modules on CPAN already do the job quite nicely.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Code algorithm is based on L<http://www.d-project.com/hebonconv/>

=head1 SEE ALSO

L<http://www.seikatubunka.metro.tokyo.jp/hebon/>, L<http://en.wikipedia.org/wiki/Hepburn_romanization>, L<Lingua::JA::Romanize::Kana>, L<Lingua::JA::Kana>

=cut
