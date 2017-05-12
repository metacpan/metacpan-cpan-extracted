# For Emacs: -*- mode:cperl; mode:folding -*-

package Lingua::IND::Words2Nums;
# ABSTRACT: Word 2 number conversion in IND.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

our $VERSION = 0.0682;

our %Digits = (
        nol => 0, kosong => 0,
        se => 1, satu => 1,
        dua => 2,
        tiga => 3,
        empat => 4,
        lima => 5,
        enam => 6,
        tujuh => 7,
        delapan => 8,
        sembilan => 9
);

our %Mults = ( 
        puluh => 1e1, 
        ratus => 1e2, 
        ribu => 1e3, 
        juta => 1e6,
        milyar => 1e9, milyard => 1e9, miliar => 1e9, miliard => 1e9,
        triliun => 1e12, trilyun => 1e12
);

our %Words = (
        %Digits,
        %Mults,
        belas => 0
);

our $Neg_pat  = '(?:negatif|min|minus)';
our $Exp_pat  = '(?:(?:di)?kali(?:kan)? sepuluh pangkat)';
our $Dec_pat  = '(?:koma|titik)';

# }}}

### public subs
# {{{ words2nums

sub words2nums :Export {
    my @a = @_;
    return w2n1(@a);
}

# }}}
# {{{ words2nums

sub words2nums_simple :Export {
    my @a = @_;
    return w2n5(@a);
}

# }}}

### private subs


# for debugging
our $DEBUG = 0;
sub hmm___ {my @a = @_; print "(", (caller 1)[3], ") Hmm, ", @a if $DEBUG; return; }


# {{{                         handle exponential
sub w2n1 {
        my $words = shift // '';
        $words = lc $words;
        my ($num1, $num2);

        if( $words =~ /(.+)\b$Exp_pat\b(.+)/ ) { 
                hmm___ "it's an exponent.\n";
                $num1 = w2n2($1);
                $num2 = w2n2($2);
                hmm___ "\$num1 is $num1, \$num2 is $num2\n";
                not defined $num1 or not defined $num2 and return;
                return $num1 * 10 ** $num2
        } else {
                hmm___ "not an exponent.\n";
                $num1 = w2n2($words);
                not defined $num1 and return;
                hmm___ "\$num1 = $num1\n";
                return $num1 
        }
}

# }}}
# {{{                         handle negative

sub w2n2 {
        my $words = lc shift;
        my $num1;

        if( $words =~ /^[\s\t]*$Neg_pat\b(.+)/ ) {
                hmm___ "it's negative.\n";
                $num1 = -w2n3($1);
                not defined $num1 and return;
                hmm___ "\$num1 = $num1\n";
                return $num1
        } else {
                hmm___ "it's not negative.\n";
                $num1 = w2n3($words);
                not defined $num1 and return;
                hmm___ "\$num1 = $num1\n";
                return $num1
        }
}

# }}}
# {{{                         handle decimal

sub w2n3 {
        my $words = lc shift;
        my ($num1, $num2);

        if( $words =~ /(.+)\b$Dec_pat\b(.+)/ ) {
                hmm___ "it has decimals.\n";
                $num1 = w2n4($1);
                $num2 = w2n5($2);
                not defined $num1 or not defined $num2 and return;
                hmm___ "\$num1 is $num1, \$num2 is $num2\n";
                return $num1 + "0.".$num2
        } else {
                hmm___ "it's an integer.\n";
                $num1 = w2n4($words);
                not defined $num1 and return;
                hmm___ "\$num1 is $num1\n";
                return $num1
        }
}

# }}}
# {{{                         handle words before decimal (e.g, 'seratus dua puluh tiga', ...)

sub w2n4 {
        my @words = &split_it( lc shift );
        my ($num, $mult);
        my $seen_digits = 0;
        my ($aa, $subtot, $tot);
        my @nums = ();

        (defined $words[0] and $words[0] eq 'ERR') and return;
        hmm___ "the words are @words.\n";

        for my $w (@words) {
                if( defined $Digits{$w} ) { # digits (satuan)
                        hmm___ "saw a digit: $w.\n";
                        $seen_digits and do { push @nums, ((10 * (pop @nums)) + $Digits{$w}) }
                        or do { push @nums, $Digits{$w} ; $seen_digits = 1 }
                }

                elsif( $w eq 'belas' ) { # special case, teens (belasan)
                        hmm___ "saw a teen: $w.\n";
                        return unless $seen_digits ; # (salah penulisan belasan)
                        push @nums, 10 + pop @nums;
                        $seen_digits = 0;
                }

                else{ # must be a multiplier
                        hmm___ "saw a multiplier: $w.\n";
                        return unless @nums ; # (salah penulisan puluhan/pengali)

                        $a = 0 ; $subtot = 0;
                        do { $aa = pop @nums ; $subtot += $aa } 
                        until ( $aa > $Mults{$w} || !@nums );

                        if( $aa > $Mults{$w} ) { push @nums, $aa; $subtot -= $aa }
                        push @nums, $Mults{$w}*$subtot;
                        $seen_digits = 0;
                }
        }

        # calculate total
        $tot = 0;
        while( @nums ){ $tot += shift @nums }

        return $tot;
}


# {{{                         handle words after decimal (simple with no 'belas', 'puluh', 'ratus', ...)
sub w2n5 {
        my $words = shift // '';
        my @words = &split_it( lc $words );
        my ($num, $mult);

        (defined $words[0] and $words[0] eq 'ERR') and return;

        $num = 0;
        $mult = 1;
        for my $w (reverse @words) {
                not defined $Digits{$w} and return;
                $num += $Digits{$w}*$mult;
                $mult *= 10;
        }

        return $num;
}

# }}}
# {{{                         split string into array of words. also splits 'sepuluh' -> (se, puluh), 'tigabelas' -> (tiga, belas), etc.

sub split_it {
        my $words = lc shift;
        my @words = ();

        for my $w ($words =~ /\b(\w+)\b/g) {
                hmm___ "saw $w.\n";
                if( $w =~ /^se(.+)$/ and defined $Words{$1} ) {
                        hmm___ "i should split $w.\n";
                        push @words, 'se', $1 }
                elsif( $w =~ /^(.+)(belas|puluh|ratus|ribu|juta|mil[iy]ard?|tril[iy]un)$/ and defined $Words{$1} ) {
                        hmm___ "i should split $w.\n";
                        push @words, $1, $2 }
                elsif( defined $Words{$w} ) {
                        push @words, $w }
                else {
                        hmm___ "i don't recognize $w.\n";
                        unshift @words, 'ERR';
                        last }
        }

        return @words;
}

# }}}

1;
__END__

# {{{ module documentation

=head1 NAME

Lingua::IND::Words2Nums - convert Indonesian verbage to number.

=head1 VERSION

version 0.0682

=head1 SYNOPSIS

  use Lingua::IND::Words2Nums;

  print words2nums("seratus dua puluh tiga") ; # 123
  print words2nums_simple("satu dua tiga") ;   # 123

=head1 DESCRIPTION

Word 2 number conversion in IND.

Lingua::IND::Words2Nums currently can handle real numbers in normal and scientific
form in the order of hundreds of trillions.

Lingua::IND::Words2Nums will return B<undef> is its argument contains unknown
verbage or "syntax error".

Lingua::IND::words2nums will produce unexpected result if you feed it stupid
verbage.

=head1 FUNCTIONS

=over

=item words2nums

Convert number in Indonesian verbage into number

=item words2nums_simple

Convert sequence of ciphers in Indonesian verbage into number

=item hmm___

private

=item split_it

private

=item w2n1

private

=item w2n2

private

=item w2n3

private

=item w2n4

private

=item w2n5

private

=back

=head1 AUTHOR

Steven Haryanto E<lt>sh@hhh.indoglobal.comE<gt>

Maintenance
PetaMem <info@petamem.com>

=head1 SEE ALSO

L<Lingua::IND::Nums2Words>

=cut

# }}}
