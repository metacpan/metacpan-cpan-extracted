# For Emacs: -*- mode:cperl; mode:folding -*-

package Lingua::FRA::Nums2Words;
# ABSTRACT: Number 2 word conversion in FRA.

# {{{ use block

use 5.10.1;

use strict;
use warnings;
use utf8;

use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

our $VERSION = 0.0682;

my @major = (
        "",
        " mille",
        " million",
        " milliard",
        " trillion",
        " quadrillion",
        " quintillion"
);

my @ten = (
        "",
        " dix",
        " vingt",
        " trente",
        " quarante",
        " cinquante",
        " soixante",
        " soixante-dix",
        " quatre-vingt",
        " quatre-vingt-dix"
);

my @num = (
        "",
        " un",
        " deux",
        " trois",
        " quatre",
        " cinq",
        " six",
        " sept",
        " huit",
        " neuf",
        " dix",
        " onze",
        " douze",
        " treize",
        " quatorze",
        " quinze",
        " seize",
        " dix-sept",
        " dix-huit",
        " dix-neuf"
);

# }}}
# {{{ num2word

sub num2word :Export {
    my @numbers = @_;
    return () unless (@numbers);

    my @results = map { _num2word($_) } @numbers;

    return wantarray ? @results : $results[0];
}

# }}}
# {{{ _num2words_less_1000

sub _num2words_less_1000 {
        my ($number) = @_;

        my $result;
        if ($number % 100 < 20){
                # 19 et moins
                $result = $num[$number % 100];
                $number /= 100;
        } else {
                # 9 et moins
                $result = $num[$number % 10];
                $number /= 10;

                # 90, 80, ... 20
                $result = $ten[$number % 10].$result;
                $number /= 10;
        }

        # reste les centaines
        # y'en a pas
        if (int($number) == 0) { return $result; }

        if (int($number) == 1) {
                # on ne retourne "un cent xxxx" mais "cent xxxx"
                return " cent$result";
        } else {
                return $num[$number]." cent".$result;
        }
}

# }}}
# {{{ _num2word

sub _num2word {
        my $number = shift // 0;

        return 'zéro' if ($number == 0);

        my $prefix = '';
        if ($number < 0) {
                $prefix = 'moins';
                $number = -$number;
        }

        my $place = 0;
        my $result = '';
        my $plural_possible = 1;
        my $plural_form = 0;
        while ($number > 0) {
                my $n = ($number % 1000);

                # par tranche de 1000
                if ($n != 0) {
                        my $s = _num2words_less_1000($n);
                        if (($s =~ /\s*un\s*/) and ($place == 1)) {
                                # on donne pas le un pour mille
                                $result = $major[$place].$result;
                        } else {
                                if ($place == 0) {
                                        if (($s =~ /cent\s*$/) and ($s !~ /^\s*cent/)) {
                                                # nnn200 ... nnn900 avec "s"
                                                $plural_form = 1;
                                        } else {
                                                # pas de "s" jamais
                                                $plural_possible = 0;
                                        }
                                }

                                if (($place > 0) and ($plural_possible)) {
                                        if ($s !~ /^\s*un/) {
                                                # avec "s"
                                                $plural_form = 1;
                                        } else {
                                                # jamais de "s"
                                                $plural_possible = 0;
                                        }
                                }

                                return if (!defined $major[$place]);

                                $result = $s.$major[$place].$result;
                        }
                }

                $place++;
                $number /= 1000;
        }

        $result = _trim($prefix.$result);

        return $plural_form ? $result.'s' : $result;
}

# }}}
# {{{ _trim

sub _trim {
        my ($string) = @_;

        $string =~ s/^\s+//;
        $string =~ s/\s+$//;

        return $string;
}

# }}}

1;

__END__

=head1 NAME

Lingua::FRA::Nums2Words - Converts numbers to French words

=head1 VERSION

version 0.0682

=head1 SYNOPSIS

  use Lingua::FRA::Nums2Words;

  $result = num2word(5);
  # $result now holds 'cinq'

  @results = num2word(1, -2, 10, 100, 1000, 9999);
  # @results now holds ('un', 'moins deux', 'dix', 'cent', 'mil',
  #                     'neuf mille neuf cent quatre-vingt-dix neuf')

=head1 DESCRIPTION

Number 2 word conversion in FRA.

=head1 FUNCTIONS

=over

=item num2word

Converts number to French words

=back

=head1 AUTHOR

Fabien POTENCIER, E<lt>fabpot@cpan.orgE<gt>

Maintenance
PetaMem <info@petamem.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 by Fabien POTENCIER

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
