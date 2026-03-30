# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::POR::Words2Nums;
# ABSTRACT: Converts Portuguese words to numbers

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';

my (%values,@values,%bigvalues,@bigvalues);

BEGIN {
  %values = (
    mil                 => 1000,

    novecentos          => 900,
    oitocentos          => 800,
    setecentos          => 700,
    seiscentos          => 600,
    quinhentos          => 500,
    quatrocentos        => 400,
    trezentos           => 300,
    duzentos            => 200,
    cem                 => 100,

    cento               => 100,

    noventa             => 90,
    oitenta             => 80,
    setenta             => 70,
    sessenta            => 60,
    cinquenta           => 50,
    quarenta            => 40,
    trinta              => 30,
    vinte               => 20,

    dezanove            => 19,
    dezoito             => 18,
    dezassete           => 17,
    dezasseis           => 16,
    quinze              => 15,
    catorze             => 14,
    treze               => 13,
    doze                => 12,
    onze                => 11,
    dez                 => 10,

    nove                => 9,
    oito                => 8,
    sete                => 7,
    seis                => 6,
    cinco               => 5,
    quatro              => 4,
    'três'              => 3,
    dois                => 2,
    um                  => 1,
    zero                => 0,
  );

  @values = sort {$values{$b} <=> $values{$a}} keys %values;

  %bigvalues = (
    bili => 1000000000000,
    milh => 1000000,
  );

  @bigvalues = sort {$bigvalues{$b} <=> $bigvalues{$a}} keys %bigvalues;

}

# }}}

# {{{ word2num

sub word2num :Export {
    $_         = shift // return;
    my $task   = $_;
    my $result = 0;

    for my $val (@bigvalues) {
        my $expr = "${val}ões|${val}ão";
        if (s/(.+)mil(?=.*(?:$expr))//) {
            my $big = $1;
            for my $value (@values) {
                $big =~ s/$value/
                    $result += ($values{$value} * $bigvalues{$val} * 1000)/e;
            }
        }
        if (s/(.+)(?:$expr)//) {
            my $sma = $1;
            for my $value (@values) {
                $sma =~ s/$value/
                    $result += ($values{$value} * $bigvalues{$val})/e;
            }
        }
    }

    if (s/(.+?)mil//) {
        my $thousands = $1;
        if ($thousands =~ /^\s*e?\s*$/) {
            $result += 1000;
        }
        else {
            for my $value (@values) {
                $thousands =~ s/$value/$result += ($values{$value} * 1000)/e;
            }
        }
    }

    for my $value (@values) {
        s/$value/$result += $values{$value}/e;
    }

    if ($result == 0 && $task !~ m{\Azero\z}xms ) {
        $result = undef;
    }

    return $result;
}

# }}}
# {{{ ordinal2cardinal                              convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Portuguese ordinals 1-10 are fully irregular
    state $irregular = {
        'primeiro'  => 'um',      'primeira'  => 'um',
        'segundo'   => 'dois',    'segunda'   => 'dois',
        'terceiro'  => 'três',    'terceira'  => 'três',
        'quarto'    => 'quatro',  'quarta'    => 'quatro',
        'quinto'    => 'cinco',   'quinta'    => 'cinco',
        'sexto'     => 'seis',    'sexta'     => 'seis',
        'sétimo'    => 'sete',    'sétima'    => 'sete',
        'oitavo'    => 'oito',    'oitava'    => 'oito',
        'nono'      => 'nove',    'nona'      => 'nove',
        'décimo'    => 'dez',     'décima'    => 'dez',
    };

    return $irregular->{$input} if exists $irregular->{$input};

    # Regular (11+): cardinal (drop final vowel) + "ésimo/ésima"
    $input =~ s{ésim[oa]\z}{}xms or return;

    # Portuguese drops the final vowel before adding -ésimo.  The dropped
    # vowel varies by word, so we restore it based on the stem ending.

    # stems ending in -z: onz→onze, doz→doze, trez→treze, catorz→catorze, quinz→quinze
    if    ($input =~ m{z\z}xms)                  { $input .= 'e' }
    # oito family: dezoit→dezoito, oit→oito
    elsif ($input =~ m{oit\z}xms)                { $input .= 'o' }
    # sete family: dezasset→dezassete, set→sete
    elsif ($input =~ m{set\z}xms)                { $input .= 'e' }
    # vinte: vint→vinte
    elsif ($input =~ m{vint\z}xms)               { $input .= 'e' }
    # decades (trinta, quarenta, etc.): trint→trinta, quarent→quarenta
    elsif ($input =~ m{nt\z}xms)                 { $input .= 'a' }
    # cinco: cinc→cinco
    elsif ($input =~ m{c\z}xms)                  { $input .= 'o' }
    # nove family: dezanov→dezanove, nov→nove
    elsif ($input =~ m{ov\z}xms)                 { $input .= 'e' }
    # quatro: quatr→quatro
    elsif ($input =~ m{tr\z}xms)                 { $input .= 'o' }

    return $input;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::POR::Words2Nums - Converts Portuguese words to numbers

=head1 VERSION

version 0.2603300

=head1 SYNOPSIS

  use Lingua::POR::Words2Nums qw/word2num/;

  $result = num2word("cinco");
  # $result now holds 5

=head1 DESCRIPTION

Word 2 number conversion in POR.

Words2Nums converts Portuguese words to numbers (works with numbers
ranging from 0 to 999.999.999.999.999.999).

Not all possible ways to write a number have been implemented (some
people write "nove mil novecentos e um", some people write "nove mil,
novecentos e um"; Words2Nums currently supports only the first way,
without commas; also, the word "bilião" is supported, but not "bilhão").

=head2 word2num

Turns a word into a number

=head2 ordinal2cardinal

  1   str    ordinal text (e.g. 'primeiro', 'segundo', 'décimo')
  =>  str    cardinal text (e.g. 'um', 'dois', 'dez')
      undef  if input is not recognised as an ordinal

Convert Portuguese ordinal text to cardinal text (morphological reversal).

  $result = num2word("cinco");
  # $result now holds 5

=head1 TO DO

=over 6

=item Implement function is_number()


=item B<ordinal2cardinal> (positional)

  1   str    ordinal text
  =>  str    cardinal text
      undef  if input is not recognised as an ordinal

Convert ordinal text to cardinal text (morphological reversal).

=back

=head1 SEE ALSO

More tools for the Portuguese language processing can be found at the
Natura project: http://natura.di.uminho.pt

=head1 AUTHORS

 initial coding:
   Jose Castro E<lt>cog@cpan.orgE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
