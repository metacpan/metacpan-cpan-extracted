# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-
#
# Copyright (c) Mike Schilli, 2001 (m@perlmeister.com)
# Copyright (c) PetaMem, s.r.o. 2002-present

package Lingua::JPN::Num2Word;
# ABSTRACT: Number to word conversion in Japanese

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ variables declaration
our $VERSION = '0.2604300';

# {{{ lexicons — kanji / hiragana / romaji per script

my %DIGIT = (
    kanji    => [ qw( 〇 一 二 三 四 五 六 七 八 九 ) ],
    hiragana => [ qw( ぜろ いち に さん よん ご ろく なな はち きゅう ) ],
    romaji   => [ qw( zero ichi ni san yon go roku nana hachi kyu ) ],
);

# Scale words at each magnitude. Hundred (百), thousand (千), ten-thousand (万),
# hundred-million (億), trillion (兆) — the canonical Japanese scale ladder.
my %SCALE = (
    kanji    => { 10 => '十',  100 => '百',    1000 => '千',  10_000 => '万',
                  100_000_000 => '億', 1_000_000_000_000 => '兆' },
    hiragana => { 10 => 'じゅう', 100 => 'ひゃく', 1000 => 'せん', 10_000 => 'まん',
                  100_000_000 => 'おく', 1_000_000_000_000 => 'ちょう' },
    romaji   => { 10 => 'ju', 100 => 'hyaku', 1000 => 'sen', 10_000 => 'man',
                  100_000_000 => 'oku', 1_000_000_000_000 => 'cho' },
);

# Irregular hundreds (rendaku/gemination):
#   300 さんびゃく sanbyaku
#   600 ろっぴゃく roppyaku
#   800 はっぴゃく happyaku
my %HUNDRED_IRREGULAR = (
    kanji    => { 3 => '三百',     6 => '六百',      8 => '八百'      },
    hiragana => { 3 => 'さんびゃく', 6 => 'ろっぴゃく', 8 => 'はっぴゃく' },
    romaji   => { 3 => 'sanbyaku',  6 => 'roppyaku',  8 => 'happyaku'  },
);

# Irregular thousands:
#   3000 さんぜん  sanzen   (rendaku)
#   8000 はっせん  hassen   (gemination)
my %THOUSAND_IRREGULAR = (
    kanji    => { 3 => '三千',    8 => '八千'   },
    hiragana => { 3 => 'さんぜん', 8 => 'はっせん' },
    romaji   => { 3 => 'sanzen',  8 => 'hassen' },
);

# Irregular trillion-block leaders (cho-prefixes):
#   1兆  いっちょう  itcho
#   8兆  はっちょう  hatcho
#   10兆 じゅっちょう jutcho
my %CHO_IRREGULAR = (
    kanji    => { 1 => '一兆',    8 => '八兆',     10 => '十兆'      },
    hiragana => { 1 => 'いっちょう', 8 => 'はっちょう', 10 => 'じゅっちょう' },
    romaji   => { 1 => 'itcho',   8 => 'hatcho',   10 => 'jutcho'   },
);

# }}}

# }}}

# {{{ num2jpn_cardinal           number → text in chosen script

sub num2jpn_cardinal :Export {
    my $n      = shift;
    my $script = shift // 'kanji';

    croak "Unknown script '$script' (expected: kanji, hiragana, romaji)"
        unless exists $DIGIT{$script};

    croak "Number must be in range [1, 1E16)"
        if !defined $n || $n !~ m{\A\d+\z}xms || $n < 1 || $n >= 1E16;

    return _render($n, $script);
}

# }}}
# {{{ num2jpn_ordinal            number → ordinal text in chosen script

sub num2jpn_ordinal :Export {
    my $n      = shift;
    my $script = shift // 'kanji';

    croak "Unknown script '$script' (expected: kanji, hiragana, romaji)"
        unless exists $DIGIT{$script};

    croak "Number must be in range [1, 1E16)"
        if !defined $n || $n !~ m{\A\d+\z}xms || $n < 1 || $n >= 1E16;

    my $cardinal = _render($n, $script);
    if ($script eq 'romaji') {
        # Conventional ordinal romaji is fully hyphen-joined: spaces between
        # block-tokens become hyphens, and the suffix attaches with a hyphen.
        $cardinal =~ tr/ /-/;
        return $cardinal . '-ban-me';
    }
    my %suffix = (kanji => '番目', hiragana => 'ばんめ');
    return $cardinal . $suffix{$script};
}

# }}}
# {{{ to_string                  legacy romaji-list interface (DEPRECATED)

# Mike Schilli's 2001 lexicon — preserved verbatim so to_string output is
# bit-for-bit identical to the historical contract. New code should use
# num2jpn_cardinal($n, 'romaji') instead.
my %_LEGACY_N2J = qw(
    1 ichi 2 ni 3 san 4 yon 5 go 6 roku 7 nana
    8 hachi 9 kyu 10 ju 100 hyaku 1000 sen);

my %_LEGACY_N2J_EXCP = qw(
    300 san-byaku 600 ro-p-pyaku 800 ha-p-pyaku
    3000 san-zen 8000 ha-s-sen);

my @_LEGACY_N2J_BLOCK = ('', 'man', 'oku', 'cho');

my %_LEGACY_N2J_BLOCK_EXCP = qw( 1 i-t-cho 8 ha-t-cho 0 ju-t-cho );

sub to_string :Export {
    my $n = shift;

    if (!defined $n || $n < 1 || $n >= 1E16) {
        warn "$n needs to be >=1 and <1E16.\n";
        return;
    }

    my @result;
    $n         = reverse $n;
    my $bix    = 0;

    while ($n =~ /(\d{1,4})/g) {
        my $b = scalar reverse($1);
        my @r = _legacy_blockof4($b);

        if ($bix && @r) {
            if ($bix == 3 && $b =~ /[1-9]0$|[18]$/) {
                $r[-1] = $_LEGACY_N2J_BLOCK_EXCP{$b % 10};
            }
            else {
                push @r, $_LEGACY_N2J_BLOCK[$bix];
            }
        }
        unshift @result, @r;
        $bix++;
    }

    return @result;
}

sub _legacy_blockof4 {
    my $n = shift;
    return if $n > 9999 or $n < 0;
    return ''  unless $n;

    my @result;
    my @digits  = split //, sprintf('%04d', $n);
    my @weights = (1000, 100, 10, 1);

    for my $i (0..3) {
        next unless $digits[$i];
        my $v = $digits[$i] * $weights[$i];
        push @result, $_LEGACY_N2J_EXCP{$v}
                   || $_LEGACY_N2J{$v}
                   || ($_LEGACY_N2J{$digits[$i]}, $_LEGACY_N2J{$weights[$i]});
    }

    return @result;
}

# }}}
# {{{ _render                    core: number → string in given script

sub _render {
    my ($n, $script) = @_;

    # Decompose into 4-digit blocks, weighted by 10^(4*k):
    #   block 0 → 1
    #   block 1 → 万 (10^4)
    #   block 2 → 億 (10^8)
    #   block 3 → 兆 (10^12)
    my @block_scales = (1, 10_000, 100_000_000, 1_000_000_000_000);
    my @parts;
    my $bix = 0;

    while ($n > 0) {
        my $block = $n % 10_000;
        $n = int($n / 10_000);
        if ($block) {
            my $piece;
            if ($bix == 3 && exists $CHO_IRREGULAR{$script}{$block}) {
                # Whole-block chō irregulars: 1兆, 8兆, 10兆 fuse digit+scale.
                $piece = $CHO_IRREGULAR{$script}{$block};
            }
            else {
                $piece = _render_block4($block, $script);
                $piece .= $SCALE{$script}{$block_scales[$bix]} if $bix > 0;
            }
            unshift @parts, $piece;
        }
        $bix++;
    }

    return _join_parts(\@parts, $script);
}

# }}}
# {{{ _render_block4             render integer 1..9999 in given script

sub _render_block4 {
    my ($n, $script) = @_;

    return '' unless $n;

    # In romaji, digit and scale fuse into a single word ("nihyaku", "sanju",
    # "yonsen"). Block boundaries get whitespace ("sen nihyaku sanju yon"
    # for 1234). Kanji and hiragana have no whitespace at all.
    my @parts;

    # Thousands (1000..9999)
    if (my $th = int($n / 1000)) {
        if (exists $THOUSAND_IRREGULAR{$script}{$th}) {
            push @parts, $THOUSAND_IRREGULAR{$script}{$th};
        }
        elsif ($th == 1) {
            push @parts, $SCALE{$script}{1000};
        }
        else {
            push @parts, $DIGIT{$script}[$th] . $SCALE{$script}{1000};
        }
        $n %= 1000;
    }

    # Hundreds (100..999)
    if (my $h = int($n / 100)) {
        if (exists $HUNDRED_IRREGULAR{$script}{$h}) {
            push @parts, $HUNDRED_IRREGULAR{$script}{$h};
        }
        elsif ($h == 1) {
            push @parts, $SCALE{$script}{100};
        }
        else {
            push @parts, $DIGIT{$script}[$h] . $SCALE{$script}{100};
        }
        $n %= 100;
    }

    # Tens (10..99)
    if (my $t = int($n / 10)) {
        if ($t == 1) {
            push @parts, $SCALE{$script}{10};
        }
        else {
            push @parts, $DIGIT{$script}[$t] . $SCALE{$script}{10};
        }
        $n %= 10;
    }

    # Units (1..9)
    push @parts, $DIGIT{$script}[$n] if $n;

    return _join_parts(\@parts, $script);
}

# }}}
# {{{ _join_parts                concatenate parts with script-appropriate sep

sub _join_parts {
    my ($parts_lr, $script) = @_;
    return '' unless @{$parts_lr};
    # Romaji is the only script that uses whitespace as a word separator.
    # Kanji and hiragana are written as a continuous string.
    return $script eq 'romaji' ? join(' ', @{$parts_lr}) : join('', @{$parts_lr});
}

# }}}
# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
        scripts  => [ 'kanji', 'hiragana', 'romaji' ],
    };
}

# }}}
1;

__END__

# {{{ module documentation

=encoding utf-8

=head1 NAME

Lingua::JPN::Num2Word - Number to word conversion in Japanese

=head1 VERSION

version 0.2604300

=head1 SYNOPSIS

  use Lingua::JPN::Num2Word qw(num2jpn_cardinal num2jpn_ordinal);

  # Default output is kanji
  say num2jpn_cardinal(3000);              # 三千
  say num2jpn_cardinal(1234);              # 千二百三十四

  # Hiragana
  say num2jpn_cardinal(3000, 'hiragana');  # さんぜん

  # Romaji (canonical, with rendaku)
  say num2jpn_cardinal(3000, 'romaji');    # sanzen

  # Ordinals
  say num2jpn_ordinal(3);                  # 三番目
  say num2jpn_ordinal(3, 'romaji');        # san-ban-me

=head1 DESCRIPTION

Converts numbers in the range [1, 1E16) to their textual Japanese
representation in any of three scripts: B<kanji> (default, e.g. 三千),
B<hiragana> (e.g. さんぜん), or B<romaji> (e.g. sanzen).

Romaji output uses the canonical native pronunciation with rendaku
(連濁) and gemination applied — that is, three thousand is rendered
as C<sanzen>, not C<san sen>; six hundred as C<roppyaku>, not C<roku
hyaku>.

Japanese decimal scaling proceeds in groups of four digits:
1 (一), 10 (十), 100 (百), 1000 (千), 10000 (万), 10^8 (億),
10^12 (兆).

=head1 FUNCTIONS

=over 2

=item B<num2jpn_cardinal>($number, [$script])

Convert C<$number> to its Japanese cardinal text. C<$script> is one of
C<'kanji'> (default), C<'hiragana'>, or C<'romaji'>.

  num2jpn_cardinal(1234)              # 千二百三十四
  num2jpn_cardinal(1234, 'hiragana')  # せんにひゃくさんじゅうよん
  num2jpn_cardinal(1234, 'romaji')    # 'sen ni hyaku san ju yon'

=item B<num2jpn_ordinal>($number, [$script])

Convert C<$number> to its Japanese ordinal text by appending the
ordinal suffix (番目 / ばんめ / -ban-me) to the cardinal form.

  num2jpn_ordinal(3)                  # 三番目
  num2jpn_ordinal(3, 'hiragana')      # さんばんめ
  num2jpn_ordinal(3, 'romaji')        # san-ban-me

=item B<to_string>($number)

DEPRECATED. Returns the romaji form as a list of words (no rendaku).
Maintained for backward compatibility with Mike Schilli's original
interface from 2001. New code should use C<num2jpn_cardinal($n, 'romaji')>.

=item B<capabilities> (void)

Returns a hashref:

  { cardinal => 1, ordinal => 1, scripts => ['kanji', 'hiragana', 'romaji'] }

=back

=head1 EXPORT_OK

=over 2

=item num2jpn_cardinal

=item num2jpn_ordinal

=item to_string (deprecated)

=back

=head1 AUTHORS

 initial coding:
   Mike Schilli E<lt>m@perlmeister.comE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) 2001 Mike Schilli.
Copyright (c) PetaMem, s.r.o. 2002-present.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
