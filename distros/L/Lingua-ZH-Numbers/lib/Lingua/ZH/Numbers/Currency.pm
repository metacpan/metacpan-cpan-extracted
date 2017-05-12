# $File: //member/autrijus/Lingua-ZH-Numbers/Numbers/Currency.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 4128 $ $DateTime: 2003/02/08 06:01:51 $

package Lingua::ZH::Numbers::Currency;
$Lingua::ZH::Numbers::Currency::VERSION = '0.01';

use 5.001;
use strict;
use Lingua::ZH::Numbers ();
use base 'Lingua::ZH::Numbers';
use vars qw($Charset %MAP $VERSION @EXPORT @ISA);
@EXPORT = 'currency_to_zh';

=head1 NAME

Lingua::ZH::Numbers::Currency - Converts currency values into their Chinese string equivalents

=head1 VERSION

This document describes version 0.01 of Lingua::ZH::Numbers::Currency, released
November 23, 2002.

=head1 SYNOPSIS

    # OO Style
    use Lingua::ZH::Numbers::Currency 'big5';
    my $shuzi = Lingua::ZH::Numbers::Currency->new( 123 );
    print $shuzi->get_string;

    my $lingyige_shuzi = Lingua::ZH::Numbers::Currency->new;
    $lingyige_shuzi->parse( 7340 );
    $chinese_string = $lingyige_shuzi->get_string;

    # Function style
    print currency_to_zh( 345 );	# automatically exported

    # Change output format
    Lingua::ZH::Numbers::Currency->charset('gb');

=head1 DESCRIPTION

This module is a subclass of L<Lingua::ZH::Numbers>; it provides a
different set of characters used in currency numbers as used in
financial transactions.  All five representation systems
(I<charsets>): C<traditional>, C<simplified>, C<big5>, C<gb> and
C<pinyin> are still supported, although the C<pinyin> variant is
identical to the one used in L<Lingua::ZH::Numbers>.

You can also use this module in a functionnal manner by invoking
the C<currency_to_zh()> function.

=head1 CAVEATS

Fraction currency numbers are unsupported; you have to round the
number before passing it for conversion, via C<int()> or C<s/\.(.*)//>.

=cut

%MAP = (
($] >= 5.006) ? eval q(
    'traditional'   => {
	mag => [ '', split(' ', "\x{842c} \x{5104} \x{5146} \x{4eac} \x{5793} \x{79ed} \x{7a70} \x{6e9d} \x{6f97} \x{6b63} \x{8f09} \x{6975} \x{6046}\x{6cb3}\x{6c99} \x{963f}\x{50e7}\x{7947} \x{90a3}\x{7531}\x{4ed6} \x{4e0d}\x{53ef}\x{601d}\x{8b70} \x{7121}\x{91cf}\x{5927}\x{6578}") ],
	ord => [ '', split(' ', "\x{62fe} \x{4f70} \x{4edf}") ],
	dig => [ split(' ', "\x{96f6} \x{58f9} \x{8cb3} \x{53c3} \x{8086} \x{4f0d} \x{9678} \x{67d2} \x{634c} \x{7396}") ],
	dot => "\x{9ede}",
	neg => "\x{8ca0}",
	post => "\x{5713}\x{6574}",
    },
    'simplified'    => {
	mag => [ '', split(' ', "\x{4e07} \x{4ebf} \x{5146} \x{4eac} \x{5793} \x{79ed} \x{7a70} \x{6c9f} \x{6da7} \x{6b63} \x{8f7d} \x{6781} \x{6052}\x{6cb3}\x{6c99} \x{963f}\x{50e7}\x{7957} \x{90a3}\x{7531}\x{4ed6} \x{4e0d}\x{53ef}\x{601d}\x{8bae} \x{65e0}\x{91cf}\x{5927}\x{6570}") ],
	ord => [ '', split(' ', "\x{62fe} \x{4f70} \x{4edf}") ],
	dig => [ split(' ', "\x{96f6} \x{58f9} \x{8d30} \x{53c2} \x{8086} \x{4f0d} \x{9646}\x{67d2} \x{634c} \x{7396}") ],
	dot => "\x{70b9}",
	neg => "\x{8d1f}",
	post => "\x{5706}\x{6574}",
    },
) : (),
    'big5'	    => {
        mag => [ '', split(' ', "\xB8U \xBB\xF5 \xA5\xFC \xA8\xCA \xAB\xB2 \xD2\xF1 \xF6\xF8 \xB7\xBE \xBC\xEE \xA5\xBF \xB8\xFC \xB7\xA5 \xAB\xED\xAAe\xA8F \xAA\xFC\xB9\xAC\xAC\xE9 \xA8\xBA\xA5\xD1\xA5L \xA4\xA3\xA5i\xAB\xE4\xC4\xB3 \xB5L\xB6q\xA4j\xBC\xC6") ],
        ord => [ '', split(' ', "\xACB \xA8\xD5 \xA5a") ],
        dig => [ split(' ', "\xB9s \xB3\xFC \xB6L \xB0\xD1 \xB8v \xA5\xEE \xB3\xB0 \xACm \xAE\xC3 \xA8h") ],
        dot => "\xC2I",
	neg => "\xADt",
	post => "\xB6\xEA\xBE\xE3",
    },
    'gb'	    => {
        mag => [ '', split(' ', "\xCD\xF2 \xD2\xDA \xD5\xD7 \xBE\xA9 \xDB\xF2 \xEF\xF6 \xF0\xA6 \xB9\xB5 \xBD\xA7 \xD5\xFD \xD4\xD8 \xBC\xAB \xBA\xE3\xBA\xD3\xC9\xB3 \xB0\xA2\xC9\xAE\xEC\xF3 \xC4\xC7\xD3\xC9\xCB\xFB \xB2\xBB\xBF\xC9\xCB\xBC\xD2\xE9 \xCE\xDE\xC1\xBF\xB4\xF3\xCA\xFD") ],
        ord => [ '', split(' ', "\xCA\xB0 \xB0\xDB \xC7\xAA") ],
        dig => [ split(' ', "\xC1\xE3 \xD2\xBC \xB7\xA1 \xB2\xCE \xCB\xC1 \xCE\xE9 \xC2\xBD \xC6\xE2 \xB0\xC6 \xBE\xC1") ],
        dot => "\xB5\xE3",
	neg => "\xB8\xBA",
	post => "\xD4\xB2\xD5\xFB",
    },
    'pinyin'	    => $ISA[0]->map->{pinyin},
);
# }}}

$MAP{pinyin}{post} = "Yuan Zheng";
$Charset = 'pinyin';

sub get_string {
    my ($self) = @_;
    return currency_to_zh($$self);
}

sub currency_to_zh {
    my $input = shift;
    die "Fraction currency numbers not yet supported" if $input =~ s/\.(.*)//;
    my $num = __PACKAGE__->_convert($MAP{$Charset}, $input);
    $num .= $MAP{$Charset}{post};
}

1;

=head1 SEE ALSO

L<Lingua::ZH::Numbers::Currency>

=head1 ACKNOWLEDGMENTS

Dieter Simader for suggesting me to write this module.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
