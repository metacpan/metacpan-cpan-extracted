# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::GLG::Num2Word;
# ABSTRACT: Converts numbers to Galician words

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';

# }}}

# {{{ num2word
sub num2glg_cardinal :Export { goto &num2word }

sub num2word :Export {
    my @a = @_;
    @a || return ();
    my @numbers = wantarray ? @a : shift @a;
    my @results = map { ## no critic
        $_ < 0 && return $_;
        $_ > 999999999999999 && return $_;
        if ( $_ > 999999999999 ) {
            my ($bil,$mil) = /(.*)(\d{12})$/;
            my $a = num2word($bil);
            my $b = num2word($mil);
            my $e = "";
            if ($b && $mil =~ /^0{9}/) {
                $e = " e";
            }
            my $s = $b ? ' ' : '';
            return $a . ($bil == 1 ? ' billón' : ' billóns') . $e . $s . $b;
        }
        elsif ( $_ > 999999 ) {
            my ($mil,$uni) = /(.*)(\d{6})$/;
            my $a = num2word($mil);
            my $b = num2word($uni);
            my $e = "";
            my $s = $b ? ' ' : '';
            if ($uni =~ /^000\d{0,2}[1-9]\d{0,2}|0\d?[1-9]\d?000|[1-9]0{5}/) {
                $e = " e";
            }
            return $a . ($mil == 1 ? ' millón' : ' millóns') . $e . $s . $b;
        }
        elsif ( $_ > 9999 ) {
            $_ =~ /\d\d\d$/;
            my $a = num2word($`);
            my $b = num2word( 1000 + $& );
            return "$a $b";
        }
        else {
            s!^00+!!;
            s!^0+(?=[1-9])!!;
            s!9(?=\d\d\d)!nove mil e !;
            s!8(?=\d\d\d)!oito mil e !;
            s!7(?=\d\d\d)!sete mil e !;
            s!6(?=\d\d\d)!seis mil e !;
            s!5(?=\d\d\d)!cinco mil e !;
            s!4(?=\d\d\d)!catro mil e !;
            s!3(?=\d\d\d)!tres mil e !;
            s!2(?=\d\d\d)!dous mil e !;
            s!1(?=\d\d\d)!mil e !;
            s!9(?=\d\d)!novecentos e !;
            s!8(?=\d\d)!oitocentos e !;
            s!7(?=\d\d)!setecentos e !;
            s!6(?=\d\d)!seiscentos e !;
            s!5(?=\d\d)!cincocentos e !;
            s!4(?=\d\d)!catrocentos e !;
            s!3(?=\d\d)!trescentos e !;
            s!2(?=\d\d)!douscentos e !;
            s!100!cen!;
            s!mil e 0+(?=[1-9])!mil e !;
            s!1(?=\d\d)!cento e !;
            s!9(?=\d)!noventa e !;
            s!8(?=\d)!oitenta e !;
            s!7(?=\d)!setenta e !;
            s!6(?=\d)!sesenta e !;
            s!5(?=\d)!cincuenta e !;
            s!4(?=\d)!corenta e !;
            s!3(?=\d)!trinta e !;
            s!2(?=\d)!vinte e !;
            s/ e 0+(?=[1-9])/ e /;
            s/ e 0+//;
            s/19/dezanove/;
            s/18/dezaoito/;
            s/17/dezasete/;
            s/16/dezaseis/;
            s/15/quince/;
            s/14/catorce/;
            s/13/trece/;
            s/12/doce/;
            s/11/once/;
            s/10/dez/;
            s/9/nove/;
            s/8/oito/;
            s/7/sete/;
            s/6/seis/;
            s/5/cinco/;
            s/4/catro/;
            s/3/tres/;
            s/2/dous/;
            s/1/un/;
            s/0/cero/;

            s!mil e (novecentos|oitocentos|setecentos|seiscentos) e!mil $1 e!;
            s!mil e (cincocentos|catrocentos|trescentos|douscentos) e!mil $1 e!;
            s!mil e cento!mil cento!;

            $_;
        }
    } @numbers;

    return wantarray ? @results : $results[0];
}

# }}}

# {{{ num2glg_ordinal                  convert number to ordinal text

sub num2glg_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Irregular ordinals 1-10
    my %irregular = (
        1  => 'primeiro',
        2  => 'segundo',
        3  => 'terceiro',
        4  => 'cuarto',
        5  => 'quinto',
        6  => 'sexto',
        7  => 'sétimo',
        8  => 'oitavo',
        9  => 'noveno',
        10 => 'décimo',
    );

    return $irregular{$number} if exists $irregular{$number};

    # For 11+, get the cardinal form and append "ésimo"
    # Drop trailing vowel if present, then add "ésimo"
    my $cardinal = num2word($number);

    $cardinal =~ s/[aeiou]$//;

    return $cardinal . 'ésimo';
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

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::GLG::Num2Word - Converts numbers to Galician words

=head1 VERSION

version 0.2603300

=head1 SYNOPSIS

  use Lingua::GLG::Num2Word qw/num2word/;

  $result = num2word(5);
  # $result now holds 'cinco'

  @results = num2word(1,2,10,100,1000,9999);
  # @results now holds ('un', 'dous', 'dez', 'cen', 'mil',
  #                     'nove mil novecentos e noventa e nove')

=head1 DESCRIPTION

Number 2 word conversion in GLG.

Nums2Words converts numbers to Galician words (works with numbers
ranging from 0 to 999.999.999.999.999).

Does not support negative numbers.

=head2 num2word

This is the main function in this module. It turns numbers into words.

  $number = num2word(77);
  # $number now holds "setenta e sete"

=head2 num2glg_cardinal

Alias for num2word.

=head2 num2glg_ordinal

Converts a number to its Galician ordinal form.

  my $ord = num2glg_ordinal(1);   # 'primeiro'
  my $ord = num2glg_ordinal(5);   # 'quinto'
  my $ord = num2glg_ordinal(21);  # 'vinte e unésimo'

Only numbers from interval [1, 999_999_999] are supported.

=head2 capabilities

Returns a hash reference describing supported conversion features.

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
