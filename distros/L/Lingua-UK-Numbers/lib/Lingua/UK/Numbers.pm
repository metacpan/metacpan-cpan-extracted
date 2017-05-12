package Lingua::UK::Numbers;

use strict;
use warnings;
use v5.10;
use utf8;

use Exporter;
our $VERSION   = '0.07';
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(uah_in_words number_in_words);

use Carp;

my %diw = (
    0 => {
        0  => { 0 => "нуль",          1 => 1},
        1  => { 0 => "",              1 => 2},
        2  => { 0 => "",              1 => 3},
        3  => { 0 => "три",           1 => 0},
        4  => { 0 => "чотири",        1 => 0},
        5  => { 0 => "п'ять",         1 => 1},
        6  => { 0 => "шість",         1 => 1},
        7  => { 0 => "сім",           1 => 1},
        8  => { 0 => "вісім",         1 => 1},
        9  => { 0 => "дев'ять",       1 => 1},
        10 => { 0 => "десять",        1 => 1},
        11 => { 0 => "одинадцять",    1 => 1},
        12 => { 0 => "дванадцять",    1 => 1},
        13 => { 0 => "тринадцять",    1 => 1},
        14 => { 0 => "чотирнадцять",  1 => 1},
        15 => { 0 => "п'ятнадцять",   1 => 1},
        16 => { 0 => "шістнадцять",   1 => 1},
        17 => { 0 => "сімнадцять",    1 => 1},
        18 => { 0 => "вісімнадцять",  1 => 1},
        19 => { 0 => "дев'ятнадцять", 1 => 1},
    },
    1 => {
        2  => { 0 => "двадцять",   1 => 1},
        3  => { 0 => "тридцять",   1 => 1},
        4  => { 0 => "сорок",      1 => 1},
        5  => { 0 => "п'ятдесят",   1 => 1},
        6  => { 0 => "шістдесят",   1 => 1},
        7  => { 0 => "сімдесят",   1 => 1},
        8  => { 0 => "вісімдесят", 1 => 1},
        9  => { 0 => "дев'яносто", 1 => 1},
    },
    2 => {
        1  => { 0 => "сто",       1 => 1},
        2  => { 0 => "двісті",    1 => 1},
        3  => { 0 => "триста",    1 => 1},
        4  => { 0 => "чотириста", 1 => 1},
        5  => { 0 => "п'ятсот",   1 => 1},
        6  => { 0 => "шістсот",   1 => 1},
        7  => { 0 => "сімсот",    1 => 1},
        8  => { 0 => "вісімсот", 1 => 1},
        9  => { 0 => "дев`ятсот", 1 => 1}
    }
);

my %nom = (
    0  =>  {0 => "копійки",  1 => "копійок",    2 => "одна копійка",  3 => "дві копійки"},
    1  =>  {0 => "гривні",   1 => "гривень",    2 => "одна гривня",   3 => "дві гривні"},
    2  =>  {0 => "тисячі",   1 => "тисяч",      2 => "одна тисяча",   3 => "дві тисячі"},
    3  =>  {0 => "мільйона", 1 => "мільйонів",  2 => "один мільйон",  3 => "два мільйони"},
    4  =>  {0 => "мільярди", 1 => "мільярдів",  2 => "один мільярд",  3 => "два мільярди"},
    5  =>  {0 => "трильйон", 1 => "трильйонів", 2 => "один трильйон", 3 => "два трильйони"}
);

my $out_hrn;

sub uah_in_words {
	my $sum = shift;
	return "нуль гривень нуль копійок" if $sum == 0;

	my ( $retval, $i, $sum_hrn, $sum_kop );

	$retval  = "";
	$out_hrn = ( $sum >= 1 ) ? 0 : 1;
	$sum_hrn = sprintf( "%0.0f", $sum );
	$sum_hrn-- if ( ( $sum_hrn - $sum ) > 0 );
	$sum_kop = sprintf( "%0.2f", ( $sum - $sum_hrn ) ) * 100;

	my $kop = get_string( $sum_kop, 0 );

	for ( $i = 1 ; $i < 6 && $sum_hrn >= 1 ; $i++ ) {
		my $sum_tmp = $sum_hrn / 1000;
		my $sum_part = sprintf( "%0.3f", $sum_tmp - int($sum_tmp) ) * 1000;
		$sum_hrn = sprintf( "%0.0f", $sum_tmp );

		$sum_hrn-- if ( $sum_hrn - $sum_tmp > 0 );
		$retval = get_string( $sum_part, $i ) . " " . $retval;
	}
	$retval .= " гривень" if ( $out_hrn == 0 );
	$retval .= " " . $kop;
	$retval =~ s/\s+/ /g;
	return $retval;
}

sub number_in_words {
	my ( $sum, $gender ) = @_;
	croak 'gender should be "FEMININE" or "MASCULINE"' if $gender ne 'FEMININE' && $gender ne 'MASCULINE';

	return "нуль" if $sum == 0;

	local $nom{1} = {
		0 => "",
		1 => "",
		2 => $gender eq 'FEMININE' ? 'одна': 'один',
		3 => $gender eq 'FEMININE' ? 'дві': 'два'
	};

	my ( $retval, $i, $sum_words );

	$retval  = "";

	$sum_words = sprintf( "%0.0f", $sum );
	$sum_words-- if ( ( $sum_words - $sum ) > 0 );

	for ( $i = 1 ; $i < 6 && $sum_words >= 1 ; $i++ ) {
		my $sum_tmp = $sum_words / 1000;
		my $sum_part = sprintf( "%0.3f", $sum_tmp - int($sum_tmp) ) * 1000;
		$sum_words = sprintf( "%0.0f", $sum_tmp );

		$sum_words-- if ( $sum_words - $sum_tmp > 0 );
		$retval = get_string( $sum_part, $i ) . " " . $retval;
	}

	$retval =~ s/\s+/ /g;
	$retval =~ s/\s+$//g;

	return $retval;;
}

sub get_string {
	my ( $sum, $nominal ) = @_;
	my ( $retval, $nom ) = ( '', -1 );

	if ( ( $nominal == 0 && $sum < 100 ) || ( $nominal > 0 && $nominal < 6 && $sum < 1000 ) ) {
		my $s2 = int( $sum / 100 );
		if ( $s2 > 0 ) {
			$retval .= " " . $diw{2}{$s2}{0};
			$nom = $diw{2}{$s2}{1};
		}
		my $sx = sprintf( "%0.0f", $sum - $s2 * 100 );
		$sx-- if ( $sx - ( $sum - $s2 * 100 ) > 0 );

		if ( ( $sx < 20 && $sx > 0 ) || ( $sx == 0 && $nominal == 0 ) ) {
			$retval .= " " . $diw{0}{$sx}{0};
			$nom = $diw{0}{$sx}{1};
		} else {
			my $s1 = sprintf( "%0.0f", $sx / 10 );
			$s1-- if ( ( $s1 - $sx / 10 ) > 0 );
			my $s0 = int( $sum - $s2 * 100 - $s1 * 10 + 0.5 );
			if ( $s1 > 0 ) {
				$retval .= " " . $diw{1}{$s1}{0};
				$nom = $diw{1}{$s1}{1};
			}
			if ( $s0 > 0 ) {
				$retval .= " " . $diw{0}{$s0}{0};
				$nom = $diw{0}{$s0}{1};
			}
		}
	}
	if ( $nom >= 0 ) {
		$retval .= " " . $nom{$nominal}{$nom};
		$out_hrn = 1 if ( $nominal == 1 );
	}
	$retval =~ s/^\s*//g;
	$retval =~ s/\s*$//g;

	return $retval;
}

=head1 NAME

Lingua::UK::Numbers - Converts numbers to money sum in words (in Ukrainian hryvnas)

=head1 SYNOPSIS

  use Lingua::UK::Numbers qw(number_in_words uah_in_words);

  print number_in_words(100);

  print uah_in_words(1.01);


=head1 DESCRIPTION

B<Lingua::UK::Numbers> helps you to convert number to words.

=head1 FUNCTIONS

=head2 number_in_words( $NUMBER, $GENDER )

returns number in words in ukrainian (UTF-8)

$GENDER can be 'MASCULINE' or 'FEMININE'

=head2 uah_in_words( $NUMBER )

returns money sum in ukrainian words(UTF-8)

e.g.: 1.01 converted to I<odna hryvnya odna kopijka>, 2.22 converted to I<dwi hryvni dwadcyat' dwi kopijki>.

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Lingua-UK-Numbers>

=head1 SEE ALSO

L<Lingua-RU-Number>

=cut

1;    # End of Lingua::UK::Numbers
