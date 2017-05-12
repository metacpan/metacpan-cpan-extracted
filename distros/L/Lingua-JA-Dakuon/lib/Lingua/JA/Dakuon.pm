package Lingua::JA::Dakuon;
use 5.008005;
use strict;
use warnings;
use utf8;
use Exporter 'import';

our $VERSION = "0.01";

our @EXPORT_OK = qw{
  dakuon handakuon seion
  dakuon_normalize
  handakuon_normalize
  all_dakuon_normalize
};
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

our $EnableCombining = 0;
our $PreferCombining = 0;

my %Dakuon = map { split // } qw{
  かが きぎ くぐ けげ こご
  さざ しじ すず せぜ そぞ
  ただ ちぢ つづ てで とど
  はば ひび ふぶ へべ ほぼ
  うゔ ゝゞ
  カガ キギ クグ ケゲ コゴ
  サザ シジ スズ セゼ ソゾ
  タダ チヂ ツヅ テデ トド
  ハバ ヒビ フブ ヘベ ホボ
  ウヴ ワヷ ヰヸ ヱヹ ヲヺ
  ヽヾ
};
my %DakuonRev = reverse %Dakuon;
my $DakuonRE = '[' . join('', keys %DakuonRev) . ']';
my %Handakuon = map { split // } qw{
  はぱ ひぴ ふぷ へぺ ほぽ
  ハパ ヒピ フプ ヘペ ホポ
};
my %HandakuonRev = reverse %Handakuon;
my $HandakuonRE = '[' . join('', keys %HandakuonRev) . ']';

my $HankakuKatakanaRE = '[ｦ-ﾝ]';

our $AllDakuonRE = "(?:$DakuonRE|.[゛\x{3099}]|$HankakuKatakanaRE\ﾞ)";
our $AllHandakuonRE = "(?:$HandakuonRE|.[゜\x{309a}]|$HankakuKatakanaRE\ﾟ)";

sub dakuon {
    my ($c) = @_;
    return if length($c) != 1; # Expected argument is a single char

    my $dc = $PreferCombining ? undef : $Dakuon{$c};
    if (!$dc) {
        if ($c =~ /^$HankakuKatakanaRE$/) {
            $dc = "$c\ﾞ";
        } else {
            $dc = ($EnableCombining || $PreferCombining) ? "$c\x{3099}" : $c;
        }
    }
    $dc;
}

sub handakuon {
    my ($c) = @_;
    return if length($c) != 1; # Expected argument is a single char

    my $dc = $PreferCombining ? undef : $Handakuon{$c};
    if (!$dc) {
        if ($c =~ /^$HankakuKatakanaRE$/) {
            $dc = "$c\ﾟ";
        } else {
            $dc = ($EnableCombining || $PreferCombining) ? "$c\x{309a}" : $c;
        }
    }
    $dc;
}

sub seion {
    my ($c) = @_;
    my $len = length($c);
    # Expected argument is a single char or single char followed by combining char
    return unless $len == 1 ||
        $len == 2 && $c =~ /[゛゜\x{3099}\x{309a}ﾞﾟ]$/;

    $DakuonRev{$c} || $HandakuonRev{$c} || substr($c, 0, 1);
}

sub dakuon_normalize {
    my ($s) = @_;

    if ($PreferCombining) {
        $s =~ s{($DakuonRE)}{"$DakuonRev{$1}\x{3099}"}ge;
        $s =~ s{゛}{\x{3099}}g;
    } else {
        $s =~ s{(.)[゛\x{3099}]}{dakuon($1)}ge;
    }
    $s =~ s{($HankakuKatakanaRE)[゛\x{3099}]}{$1ﾞ}g;
    $s;
}

sub handakuon_normalize {
    my ($s) = @_;

    if ($PreferCombining) {
        $s =~ s{($HandakuonRE)}{"$HandakuonRev{$1}\x{309a}"}ge;
        $s =~ s{゜}{\x{309a}}g;
    } else {
        $s =~ s{(.)[゜\x{309a}]}{handakuon($1)}ge;
    }
    $s =~ s{($HankakuKatakanaRE)[゜\x{309a}]}{$1ﾟ}g;
    $s;
}

sub all_dakuon_normalize {
    handakuon_normalize dakuon_normalize @_;
}

1;
__END__

=encoding utf-8

=head1 NAME

Lingua::JA::Dakuon - Convert between dakuon/handakuon and seion for Japanese

=head1 SYNOPSIS

    use utf8;
    use Lingua::JA::Dakuon ':all';

    # Convert char to dakuon/handakuon
    dakuon('か');    #=> 'が'(\x{304c})
    dakuon('ﾀ');     #=> 'ﾀﾞ'(\x{ff80}\x{ff9e})
    dakuon('あ');    #=> 'あ'(\x{3042})
    handakuon('は'); #=> 'ぱ'(\x{3071})
    {
        local $Lingua::JA::Dakuon::EnableCombining = 1;
        dakuon('あ'); #=> "\x{3042}\x{3099}"
    }
    {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        dakuon('か');    #=> "\x{304b}\x{3099}"
        handakuon('は'); #=> "\x{306f}\x{309a}"
    }

    # Convert char to seion
    seion('が');         #=> 'か'(\x{304b})
    seion('か゛');       #=> 'か'(\x{304b})
    seion('あ');         #=> 'あ'(\x{3042})
    seion("あ\x{3099}"); #=> 'あ'(\x{3042})
    seion('ﾀﾞ');         #=> 'ﾀ' (\x{ff80})
    seion('ぱ');         #=> 'は'(\x{306f})
    seion('は゜');       #=> 'は'(\x{306f})
    seion('ﾀﾟ');         #=> 'ﾀ' (\x{ff80})

    # Normalize dakuon/handakuon expression in string
    dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}");
        #=> 'あがざだなぱまゔﾊﾋﾞﾌﾞ'
    handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}");
        #=> 'あぱぴぴがまﾊﾋﾟﾌﾟ'
    {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}");
           #=> "あか\x{3099}さ\x{3099}た\x{3099}なぱま\x{3099}う\x{3099}ﾊﾋﾞﾌﾞ"
        handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}");
           #=> "あは\x{309a}ひ\x{309a}ひ\x{309a}がま\x{309a}ﾊﾋﾟﾌﾟ"
    }

    all_dakuon_normalize($string);
        #=> equivalent to dakuon_normalize(handakuon_normalize($string));

=head1 DESCRIPTION

This module provide routines to handle dakuon/handakuon in Japanese
which is expressed by Unicode.

=head1 VARIABLES

=head2 $Lingua::JA::Dakuon::EnableCombining (default: 0)

If this variable set to true, use unicode combining character if needed.
For example, there is no code corresponding to dakuon for 'あ'(\x{3042}).
But it can be forcely expressed with combining character "\x{3099}" as
"\x{3042}\x{3099}" if this flag was enabled.

=head2 $Lingua::JA::Dakuon::PreferCombining (default: 0)

If this variable set to true, use combining character instead of dakuon
character code even if it is avaiable.
For example, calling dakuon() with argument 'か' will return "か\x{3099}"
instead of returning "\x{304c}".

=head2 $Lingua::JA::Dakuon::AllDakuonRE

Regex *STRING*(not compiled) that matches all dakuon character(s)
can be passed to seion().

=head2 $Lingua::JA::Dakuon::AllHandakuonRE

Regex *STRING*(not compiled) that matches all handakuon character(s)
can be passed to seion().

=head1 FUNCTIONS

=head2 dakuon($char)

Convert passed character to dakuon character if it is possible.
Return undef if passed argument has more than 1 character.

    dakuon('か');   #=> 'が'(\x{304c})

=head2 handakuon($char)

Convert passed character to handakuon character if it is possible.
Return undef if passed argument has more than 1 character.

    handakuon('は'); #=> 'ぱ'(\x{3071})

=head2 seion($char)

Convert passed character to seion character if it is possible.
Return undef if passed argument has more than 2 character or second
character isn't a mark charactor which expresses dakuon/handakuon.

    seion('が'); #=> 'か'(\x{304b})
    seion('ぱ'); #=> 'は'(\x{306f})

=head2 dakuon_normalize($string)

Normalize string that maybe contains multiple expression of dakuon.

    dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}");
        #=> 'あがざだなぱまゔﾊﾋﾞﾌﾞ'

=head2 handakuon_normalize($string)

Normalize string that maybe contains multiple expression of handakuon.

    handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}");
        #=> 'あぱぴぴがまﾊﾋﾟﾌﾟ'

=head2 all_dakuon_normalize($string)

Equivalent to calling dakuon_normalize(handakuon_normalize($string));

=head1 SEE ALSO

=over

=item L<濁点 - Wikipedia|http://ja.wikipedia.org/wiki/%E6%BF%81%E7%82%B9>

=item L<半濁点 - Wikipedia|http://ja.wikipedia.org/wiki/%E5%8D%8A%E6%BF%81%E7%82%B9>

=item L<清音 - Wikipedia|http://ja.wikipedia.org/wiki/%E6%B8%85%E9%9F%B3>

=back

=head1 LICENSE

Copyright (C) Yuto KAWAMURA(kawamuray).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuto KAWAMURA(kawamuray) E<lt>kawamuray.dadada@gmail.comE<gt>

=cut

