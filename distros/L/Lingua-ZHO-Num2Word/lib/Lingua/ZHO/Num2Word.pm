# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-
#
# (c) 2003-2010 PetaMem, s.r.o.
#

package Lingua::ZHO::Num2Word;
# ABSTRACT: Converts numeric values into their Chinese string equivalents

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Exporter;
use base 'Exporter';
use vars qw($Charset @EXPORT_OK);

# }}}
# {{{ variables declaration
our $VERSION = '0.2603300';

@EXPORT_OK = ('number_to_zh', 'num2zho_ordinal');

$Charset = 'pinyin';

our %MAP = (
($] >= 5.006) ? eval  ## no critic
  q(
    'traditional'   => {
        mag => [ '', split(' ', "萬 億 兆 京 垓 秭 穰 溝 澗 正 載 極 恆河沙 阿僧祇 那由他 不可思議 無量大數") ],
        ord => [ '', split(' ', "十 百 千") ],
        dig => [ split(' ', "零 一 二 三 四 五 六 七 八 九 十") ],
        dot => "點",
        neg => "負",
    },
    'simplified'    => {
        mag => [ '', split(' ', "万 亿 兆 京 垓 秭 穰 沟 涧 正 载 极 恒河沙 阿僧祗 那由他 不可思议 无量大数") ],
        ord => [ '', split(' ', "十 百 千") ],
        dig => [ split(' ', "零 一 二 三 四 五 六 七 八 九 十") ],
        dot => "点",
        neg => "负",
    },
) : (),
    'big5'          => {
        mag => [ '', split(' ', "\xB8U \xBB\xF5 \xA5\xFC \xA8\xCA \xAB\xB2 \xD2\xF1 \xF6\xF8 \xB7\xBE \xBC\xEE \xA5\xBF \xB8\xFC \xB7\xA5 \xAB\xED\xAAe\xA8F \xAA\xFC\xB9\xAC\xAC\xE9 \xA8\xBA\xA5\xD1\xA5L \xA4\xA3\xA5i\xAB\xE4\xC4\xB3 \xB5L\xB6q\xA4j\xBC\xC6") ],
        ord => [ '', split(' ', "\xA4Q \xA6\xCA \xA4d") ],
        dig => [ split(' ', "\xB9s \xA4\@ \xA4G \xA4T \xA5| \xA4\xAD \xA4\xBB \xA4C \xA4K \xA4E \xA4Q") ],
        dot => "\xC2I",
        neg => "\xADt",
    },
    'gb'            => {
        mag => [ '', split(' ', "\xCD\xF2 \xD2\xDA \xD5\xD7 \xBE\xA9 \xDB\xF2 \xEF\xF6 \xF0\xA6 \xB9\xB5 \xBD\xA7 \xD5\xFD \xD4\xD8 \xBC\xAB \xBA\xE3\xBA\xD3\xC9\xB3 \xB0\xA2\xC9\xAE\xEC\xF3 \xC4\xC7\xD3\xC9\xCB\xFB \xB2\xBB\xBF\xC9\xCB\xBC\xD2\xE9 \xCE\xDE\xC1\xBF\xB4\xF3\xCA\xFD") ],
        ord => [ '', split(' ', "\xCA\xAE \xB0\xD9 \xC7\xA7") ],
        dig => [ split(' ', "\xC1\xE3 \xD2\xBB \xB6\xFE \xC8\xFD \xCB\xC4 \xCE\xE5 \xC1\xF9 \xC6\xDF \xB0\xCB \xBE\xC5 \xCA\xAE") ],
        dot => "\xB5\xE3",
        neg => "\xB8\xBA",
    },
    'pinyin'        => {
        mag => [ '', map {$_ } qw(
            Wan Yi Zhao Jing Gai Zi Rang Gou Jian Zheng Zai Ji
            HengHeSha AZengZhi NaYouTa BuKeSiYi WuLiangDaShu
        ) ],
        ord => [ '', map {$_ } qw(Shi Bai Qian) ],
        dig => [ qw(Ling Yi Er San Si Wu Liu Qi Ba Jiu Shi) ],
        dot => ' Dian ',
        neg => 'Fu ',
    },
);
# }}}

# {{{ import

sub import {
    my ($class, $charset) = @_;
    $class->charset($charset);
    return $class->export_to_level(1, $class);
}

# }}}
# {{{ charset

sub charset {
    my ($class, $charset) = @_;

    no strict 'refs'; ## no critic
    return ${"$class\::Charset"} unless defined $charset;

    $charset = 'gb' if $charset =~ /^gb/i or $charset =~ /^euc-cn$/i;
    $charset = 'big5' if $charset =~ /big5/i;
    return ${"$class\::Charset"} = lc($charset) if exists ${"$class\::MAP"}{lc($charset)};
}

# }}}
# {{{ map_zho

sub map_zho {
    return \%MAP;
}

# }}}
# {{{ new

sub new {
    my ($class, $num) = @_;
    bless (\$num, $class);
}

# }}}
# {{{ parse

sub parse {
    my ($self, $num) = @_;
    ${$self} = $num;
}

# }}}
# {{{ get_string

sub get_string {
    my ($self) = @_;
    return number_to_zh($$self);
}

# }}}
# {{{ number_to_zh

sub num2zho_cardinal { goto &number_to_zh }

sub number_to_zh {
    my @a = @_;
    return __PACKAGE__->_convert($MAP{$Charset}, @a);
}

# }}}
# {{{ convert

sub _convert {
    my ($class, $map, $input) = @_;

    croak 'You should specify a number from interval [0, trillion)'
        if    !defined $input
           || $input !~ m{\A[\-\.\d]+\z}xms
           || $input >= 10 ** 15;

    $input =~ s/[^\d\.\-]//;

    my @dig = @{$map->{dig}};
    my @ord = @{$map->{ord}};
    my @mag = @{$map->{mag}};
    my $dot = $map->{dot};
    my $neg = $map->{neg};

    my $out = '';
    my $delta;
    if ($input =~ s/\.(.*)//) {
        $delta = $1;
    }

    $out = $neg if $input =~ s/^\-//;
    $input =~ s/^0+//;
    $input ||= '0';

    my @chunks;
    unshift @chunks, $1 while ($input =~ s/(\d{1,4})$//g);
    my $mag = $#chunks;
    my $zero = ($] >= 5.005) ? eval 'qr/$dig[0]$/' : quotemeta($dig[0]) . '$'; ## no critic

    foreach my $num (@chunks) {
        my $tmp = '';

        for (reverse 0..3) {
            my $n = int($num / (10 ** $_)) % 10;
            next unless $tmp or $n;
            $tmp .= $dig[$n] unless ($n == 0 and $tmp =~ $zero)
                                 or ($_ == 1 and $n == 1 and not $tmp);
            $tmp .= $ord[$_] if $n;
        }

        $tmp =~ s/$zero// unless $tmp eq $dig[0];
        $tmp .= $mag[$mag] if $tmp;
        $tmp = $dig[0].$tmp if $num < 1000 and $mag != $#chunks
                                           and $out !~ $zero;
        $out .= $tmp;
        $mag--;
    }

    $out =~ s/$zero// unless $out eq $dig[0];

    if ($delta) {
        $delta =~ s/^0\.//;
        $out .= $dot;
        $out .= $dig[$_] for split(//, $delta);
    }

    return $out || $dig[0];
}

# }}}


# {{{ num2zho_ordinal                 convert number to ordinal text

sub num2zho_ordinal {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999_999;

    # Chinese ordinals: 第 (dì) + cardinal in traditional characters
    my $cardinal = __PACKAGE__->_convert($MAP{'traditional'}, $number);

    return '第' . $cardinal;
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;
__END__

# {{{ module documentation

=encoding utf-8

=head1 NAME

Lingua::ZHO::Num2Word - Converts numeric values into their Chinese string equivalents

=head1 VERSION

version 0.2603300

=head1 SYNOPSIS

    # OO Style
    use Lingua::ZHO::Num2Word 'pinyin';
    my $shuzi = Lingua::ZHO::Num2Word->new( 123 );
    print $shuzi->get_string;

    my $lingyige_shuzi = Lingua::ZHO::Num2Word->new;
    $lingyige_shuzi->parse( 7340 );
    $chinese_string = $lingyige_shuzi->get_string;

    # Function style
    print number_to_zh( 345 );  # automatically exported

    # Change output format
    Lingua::ZHO::Num2Word->charset('big5');

    Only numbers from interval [0, trillion) can be converted.

=head1 DESCRIPTION

Number 2 word conversion in ZHO.

This module tries to convert a number into Chinese cardinal number.
It supports decimals number, and five representation systems
(I<charsets>): C<traditional>, C<simplified>, C<big5>, C<gb> and
C<pinyin>.  The first two are returned as unicode strings; hence
they are only available for Perl 5.6 and later versions.

The interface conforms to the one defined in B<Lingua::EN::Number>,
but you can also use this module in a functionnal manner by invoking
the C<number_to_zh()> function.

=head1 FUNCTIONS

=over

=item charset

=item get_string

=item map_zho

=item new

=item number_to_zh

=item num2zho_ordinal

Convert number to ordinal text using traditional Chinese characters.
Prepends 第 (dì) to the traditional cardinal form.
Only numbers from interval [1, 999_999_999_999] will be converted.

=item parse


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=head1 SEE ALSO

L<Lingua::EN::Numbers>

=head1 ACKNOWLEDGMENTS

Sean Burke for suggesting me to write this module.

=head1 AUTHORS

 initial coding:
   Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright 2002, 2003, 2004 by Autrijus Tang <autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
