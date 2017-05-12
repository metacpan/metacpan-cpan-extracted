package Lingua::ZH::Numbers;
$Lingua::ZH::Numbers::VERSION = '0.04';

use 5.001;
use strict;
use Exporter;
use base 'Exporter';
use vars qw($Charset %MAP $VERSION @EXPORT);
@EXPORT = 'number_to_zh';

=head1 NAME

Lingua::ZH::Numbers - Converts numeric values into their Chinese string equivalents

=head1 VERSION

This document describes version 0.04 of Lingua::ZH::Numbers, released
September 8, 2004.

=head1 SYNOPSIS

    # OO Style
    use Lingua::ZH::Numbers 'pinyin';
    my $shuzi = Lingua::ZH::Numbers->new( 123 );
    print $shuzi->get_string;

    my $lingyige_shuzi = Lingua::ZH::Numbers->new;
    $lingyige_shuzi->parse( 7340 );
    $chinese_string = $lingyige_shuzi->get_string;

    # Function style
    print number_to_zh( 345 );	# automatically exported

    # Change output format
    Lingua::ZH::Numbers->charset('big5');

=head1 DESCRIPTION

This module tries to convert a number into Chinese cardinal number.
It supports decimals number, and five representation systems
(I<charsets>): C<traditional>, C<simplified>, C<big5>, C<gb> and
C<pinyin>.  The first two are returned as unicode strings; hence
they are only available for Perl 5.6 and later versions.

The interface conforms to the one defined in B<Lingua::EN::Number>,
but you can also use this module in a functionnal manner by invoking
the C<number_to_zh()> function.

=cut

# Global Constants {{{

$Charset = 'pinyin';

%MAP = (
($] >= 5.006) ? eval q(
    'traditional'   => {
	mag => [ '', split(' ', "\x{842c} \x{5104} \x{5146} \x{4eac} \x{5793} \x{79ed} \x{7a70} \x{6e9d} \x{6f97} \x{6b63} \x{8f09} \x{6975} \x{6046}\x{6cb3}\x{6c99} \x{963f}\x{50e7}\x{7947} \x{90a3}\x{7531}\x{4ed6} \x{4e0d}\x{53ef}\x{601d}\x{8b70} \x{7121}\x{91cf}\x{5927}\x{6578}") ],
	ord => [ '', split(' ', "\x{5341} \x{767e} \x{5343}") ],
	dig => [ split(' ', "\x{96f6} \x{4e00} \x{4e8c} \x{4e09} \x{56db} \x{4e94} \x{516d} \x{4e03} \x{516b} \x{4e5d} \x{5341}") ],
	dot => "\x{9ede}",
	neg => "\x{8ca0}",
    },
    'simplified'    => {
	mag => [ '', split(' ', "\x{4e07} \x{4ebf} \x{5146} \x{4eac} \x{5793} \x{79ed} \x{7a70} \x{6c9f} \x{6da7} \x{6b63} \x{8f7d} \x{6781} \x{6052}\x{6cb3}\x{6c99} \x{963f}\x{50e7}\x{7957} \x{90a3}\x{7531}\x{4ed6} \x{4e0d}\x{53ef}\x{601d}\x{8bae} \x{65e0}\x{91cf}\x{5927}\x{6570}") ],
	ord => [ '', split(' ', "\x{5341} \x{767e} \x{5343}") ],
	dig => [ split(' ', "\x{96f6} \x{4e00} \x{4e8c} \x{4e09} \x{56db} \x{4e94} \x{516d} \x{4e03} \x{516b} \x{4e5d} \x{5341}") ],
	dot => "\x{70b9}",
	neg => "\x{8d1f}",
    },
) : (),
    'big5'	    => {
        mag => [ '', split(' ', "\xB8U \xBB\xF5 \xA5\xFC \xA8\xCA \xAB\xB2 \xD2\xF1 \xF6\xF8 \xB7\xBE \xBC\xEE \xA5\xBF \xB8\xFC \xB7\xA5 \xAB\xED\xAAe\xA8F \xAA\xFC\xB9\xAC\xAC\xE9 \xA8\xBA\xA5\xD1\xA5L \xA4\xA3\xA5i\xAB\xE4\xC4\xB3 \xB5L\xB6q\xA4j\xBC\xC6") ],
        ord => [ '', split(' ', "\xA4Q \xA6\xCA \xA4d") ],
        dig => [ split(' ', "\xB9s \xA4\@ \xA4G \xA4T \xA5| \xA4\xAD \xA4\xBB \xA4C \xA4K \xA4E \xA4Q") ],
        dot => "\xC2I",
	neg => "\xADt",
    },
    'gb'	    => {
        mag => [ '', split(' ', "\xCD\xF2 \xD2\xDA \xD5\xD7 \xBE\xA9 \xDB\xF2 \xEF\xF6 \xF0\xA6 \xB9\xB5 \xBD\xA7 \xD5\xFD \xD4\xD8 \xBC\xAB \xBA\xE3\xBA\xD3\xC9\xB3 \xB0\xA2\xC9\xAE\xEC\xF3 \xC4\xC7\xD3\xC9\xCB\xFB \xB2\xBB\xBF\xC9\xCB\xBC\xD2\xE9 \xCE\xDE\xC1\xBF\xB4\xF3\xCA\xFD") ],
        ord => [ '', split(' ', "\xCA\xAE \xB0\xD9 \xC7\xA7") ],
        dig => [ split(' ', "\xC1\xE3 \xD2\xBB \xB6\xFE \xC8\xFD \xCB\xC4 \xCE\xE5 \xC1\xF9 \xC6\xDF \xB0\xCB \xBE\xC5 \xCA\xAE") ],
        dot => "\xB5\xE3",
	neg => "\xB8\xBA",
    },
    'pinyin'	    => {
	mag => [ '', map "$_ ", qw(
	    Wan Yi Zhao Jing Gai Zi Rang Gou Jian Zheng Zai Ji
	    HengHeSha AZengZhi NaYouTa BuKeSiYi WuLiangDaShu
	) ],
	ord => [ '', map "$_ ", qw(Shi Bai Qian) ],
	dig => [ qw(Ling Yi Er San Si Wu Liu Qi Ba Jiu Shi) ],
	dot => ' Dian ',
	neg => 'Fu ',
    },
);
# }}}

sub import {
    my ($class, $charset) = @_;
    $class->charset($charset);
    $class->export_to_level(1, $class);
}

sub charset {
    my ($class, $charset) = @_;

    no strict 'refs';
    return ${"$class\::Charset"} unless defined $charset;

    $charset = 'gb' if $charset =~ /^gb/i or $charset =~ /^euc-cn$/i;
    $charset = 'big5' if $charset =~ /big5/i;
    ${"$class\::Charset"} = lc($charset) if exists ${"$class\::MAP"}{lc($charset)};
}

sub map {
    return \%MAP;
}

sub new {
    my ($class, $num) = @_;
    bless (\$num, $class);
}

sub parse {
    my ($self, $num) = @_;
    ${$self} = $num;
}

sub get_string {
    my ($self) = @_;
    return number_to_zh($$self);
}

sub number_to_zh {
    __PACKAGE__->_convert($MAP{$Charset}, @_);
}

sub _convert {
    my ($class, $map, $input) = @_;
    $input =~ s/[^\d\.\-]//;

    my @dig = @{$map->{dig}};
    my @ord = @{$map->{ord}};
    my @mag = @{$map->{mag}};
    my $dot = $map->{dot};
    my $neg = $map->{neg};

    my $out = '';
    my $delta = $1 if $input =~ s/\.(.*)//;
    $out = $neg if $input =~ s/^\-//;
    $input =~ s/^0+//;
    $input ||= '0';

    my @chunks;
    unshift @chunks, $1 while ($input =~ s/(\d{1,4})$//g);
    my $mag = $#chunks;
    my $zero = ($] >= 5.005) ? eval 'qr/$dig[0]$/' : quotemeta($dig[0]) . '$';

    foreach my $num (@chunks) {
	my $tmp = '';

	for (reverse 0..3) {
	    my $n = int($num / (10 ** $_)) % 10;
	    next unless $tmp or $n;
	    $tmp .= $dig[$n] unless ($n == 0 and $tmp =~ $zero)
				 or ($_ == 1 and $n == 1 and !$tmp);
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

1;

=head1 SEE ALSO

L<Lingua::EN::Numbers>

=head1 ACKNOWLEDGMENTS

Sean Burke for suggesting me to write this module.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002, 2003, 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
