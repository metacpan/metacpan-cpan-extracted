# For Emacs: -*- mode:cperl; mode:folding -*-

package Lingua::IND::Nums2Words;
# ABSTRACT: Number 2 word conversion in IND.

# {{{ use block

use 5.10.1;
use strict;
use warnings;

use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

our $VERSION = 0.0708;

our $Dec_char  = ".";
our $Neg_word  = "negatif";
our $Dec_word  = "koma";
our $Exp_word  = "dikali sepuluh pangkat";
our $Zero_word = "nol";

our %Digit_words = (
        0 => $Zero_word, 
        1 => 'satu',
        2 => 'dua',
        3 => 'tiga',
        4 => 'empat',
        5 => 'lima',
        6 => 'enam',
        7 => 'tujuh',
        8 => 'delapan',
        9 => 'sembilan'
);

our %Mult_words = (
        0 => '',
        1 => 'ribu',
        2 => 'juta',
        3 => 'milyar',
        4 => 'triliun'
);

# }}}

### public subs
# {{{ nums2words

sub nums2words :Export {
    my @a = @_;
    return join_it(n2w1(@a));
}

# }}}
# {{{ nums2words_simple

sub nums2words_simple :Export {
    my @a = @_;
    return join_it(n2w5(@a));
}

# }}}

### private subs

# for debugging
our $DEBUG = 0;
sub hmm___ { my @a = @_;print "(", (caller 1)[3], ") Hmm, ", @a if $DEBUG; return; }
# {{{ n2w1                    handle scientific notation
sub n2w1 {
        my $num = shift // return '';

        return $Zero_word if $num >= 10 ** 15;    # not quadrillion and more

        my @words;

        $num =~ /^(.+)[Ee](.+)$/ and
        @words = (n2w2($1), $Exp_word, n2w2($2)) or
        @words = n2w2($num);

        return @words;
}

# }}}
# {{{ n2w2                    handle negative sign and decimal

sub n2w2 {
        my $num = shift // return '';
        my $is_neg;
        my @words = ();

        # negative 
        $num < 0 and $is_neg++;
        $num =~ s/^[\s\t]*[+-]*(.*)/$1/;

        # decimal 
        $num =~ /^(.+)\Q$Dec_char\E(.+)$/o and 
        @words = (n2w3($1), $Dec_word, n2w5($2)) or

        $num =~ /^\Q$Dec_char\E(.+)$/o and 
        @words = ($Digit_words{0}, $Dec_word, n2w5($1)) or 

        $num =~ /^(.+)(?:\Q$Dec_char\E)?$/o and 
        @words = n2w3($1);

        $is_neg and
        unshift @words, $Neg_word;

        return @words;
}


# }}}
# {{{ n2w3                    handle digits before decimal

sub n2w3 {
        my $num = shift // return '';
        my @words = ();
        my $order = 0;
        my $t;

        while($num =~ /^(.*?)([\d\D*]{1,3})$/) {
                $num = $1;
                ($t = $2) =~ s/\D//g;
                $t = $t || 0;
                unshift @words, $Mult_words{$order} if $t > 0;
                unshift @words, n2w4($t, $order);
                $order++;
        }

        @words = ($Zero_word) if not join('',@words)=~/\S/;
        hmm___ "for the left part of decimal i get: @words\n";
        return @words;
}

# }}}
# {{{ n2w4                    handle clusters of thousands

sub n2w4 {
        my $num = shift // return '';
        my $order = shift;
        my @words = ();

        my $n1 = $num % 10;
        my $n2 = ($num % 100 - $n1) / 10;
        my $n3 = ($num - $n2*10 - $n1) / 100;

        ($n3 == 0 && $n2 == 0 && $n1 > 0) && (((
                $n1 == 1 && $order == 1) && (@words = ("se"))) ||
                (@words = ($Digit_words{$n1}) ));

        $n3 == 1 and @words = ("seratus") or
        $n3 >  1 and @words = ($Digit_words{$n3}, "ratus");

        $n2 == 1 and (
                $n1 == 0 and push(@words, "sepuluh") or
                $n1 == 1 and push(@words, "sebelas") or
                push(@words, $Digit_words{$n1}, "belas") 
        );

        $n2 > 1 and do { 
                push @words, $Digit_words{$n2}, "puluh";
                push @words, $Digit_words{$n1} if $n1 > 0;
        };

        ($n3 > 0 && $n2 == 0 && $n1 > 0) &&
        push @words, $Digit_words{$n1} ; 

        ($n3 != 0 || $n2 != 0 || $n1 != 0) &&
        return @words;
}

# }}}
# {{{ n2w5                    handle digits after decimal
sub n2w5 {
        my $num = shift // return '';

        return $Zero_word if $num >= 10 ** 15;    # not quadrillion and more

        my @words = ();
        my $i;
        my $t;

        for( $i=0 ; $i<=length($num)-1 ; $i++ ) {
                $t = substr($num, $i, 1);
                exists $Digit_words{$t} and
                push @words, $Digit_words{$t};
        }

        @words = ($Zero_word) if not join('',@words)=~/\S/;
        return @words;
}

# }}}
# {{{ join_it                 join array of words, also join (se, ratus) -> seratus, etc.
sub join_it {
        my @a = @_;
        my $words = '';
        my $w;

        while(defined( $w = shift @a)) {
                $words .= $w;
                $words .= ' ' unless not length $w or $w eq 'se' or not @a;
        }
        return $words;
}

# }}}

1;
__END__

# {{{ module documentation

=head1 NAME

Lingua::IND::Nums2Words - convert number to Indonesian verbage.

=head1 VERSION

version 0.0708

=head1 SYNOPSIS

  use Lingua::IND::Nums2Words;

  print nums2words(123)        ; # "seratus dua puluh tiga "
  print nums2words_simple(123) ; # "satu dua tiga"

=head1 DESCRIPTION

Number 2 word conversion in IND.

Lingua::IND::nums2words currently can handle real numbers in normal and scientific
form in the order of hundreds of trillions. It also preserves formatting
in the number string (e.g, given "1.00" Lingua::IND::nums2words will pronounce the
zeros).

Numbers > 10 ** 15 returns 0.

=head1 FUNCTIONS

=over

=item hmm___

=item join_it

=item n2w1

=item n2w2

=item n2w3

=item n2w4

=item n2w5

=item nums2words

=item nums2words_simple

=back

=head1 AUTHOR

Steven Haryanto E<lt>sh@hhh.indoglobal.comE<gt>

Maintenance
PetaMem <info@petamem.com>

=head1 SEE ALSO

L<Lingua::IND::Words2Nums>

=cut

# }}}
