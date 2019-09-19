package Lingua::pt_BR::Nums2Words;

use strict;
use warnings;
use Exporter 'import';
use Carp;
use utf8;

our $VERSION = '0.02';
our @EXPORT_OK = qw/num2word/;

=encoding utf8

=head1 NAME

Lingua::pt_BR::Nums2Words - Takes a number and gives back its written
form in Brazilian Portuguese

=head1 SYNOPSIS

  use Lingua::pt_BR::Nums2Words ('num2word');

  print num2word(91)        # prints 'noventa e um'
  print num2word('19')      # prints 'dezenove'

  print num2word(1000)      # prints 'mil'
  print num2word(1001)      # prints 'mil e um'
  print num2word(1_001_001) # prints 'um milhão, mil e um'
  print num2word(1_001_250) # prints 'um milhão, mil duzentos e cinquenta'

=head1 DESCRIPTION

Takes a number and gives back its written form in Brazilian
Portuguese.

B<Note>: 1000 will produce 'mil', and not 'um mil'.

=head1 METHODS

=cut

my %cardinals;

$cardinals{units}      = [undef, qw/um dois três quatro cinco seis sete oito
                          nove/];

$cardinals{first_tens} = [undef, qw/onze doze treze quatorze quinze dezesseis
                          dezessete dezoito dezenove/];

$cardinals{tens}       = [undef, qw/dez vinte trinta quarenta cinquenta sessenta
                          setenta oitenta noventa/];

$cardinals{hundreds}   = [undef, qw/cento duzentos trezentos quatrocentos
                       quinhentos seiscentos setecentos oitocentos novecentos/];

$cardinals{megas}      = [undef, qw/mil milh bilh trilh quadrilh quintilh/];

=head2 num2word( $number )

Receives a number and returns it written in words.

    my $written_number = nums2words(991);
    print $written_number        # prints 'novecentos e noventa e um'

=cut

sub num2word {
    my $number = shift;
    croak 'No argument provided' unless defined $number;
    croak "Not a workable number: $number" unless $number =~ /^\d{1,19}$/x;
    if ($number ==   0) { return 'zero' }

    return _solve_triads( _make_triads($number) );
}

=head1 INTERNALS

These methods should not be used directly (unless you know what you're
doing).  They are documented here just for the sake of completeness.

=head2 _make_triads( $number )

Receives a number, splits it in triads (according to the following
examples) and returns a list of triads. Examples: 123 turns to the
list (123). 12345 turns to the list (12, 345). 1234567 turns to the
list (1, 234, 567).

=cut

sub _make_triads {
    my $number = shift;
    my @triads;
    my $offset = (length $number) % 3 || 3;

    while (my $triad = substr $number, 0, $offset, '') {
        push @triads, $triad;
        if ($offset != 3) { $offset = 3 }
    }

    return @triads;
}

=head2 _solve_triads( @triads )

Receives a list of triads, calls the function _solve_triad in each of
them and apply the "megas" (millions, billions, trillions).

=cut

sub _solve_triads {
    my @triads = @_;
    my $megas_counter = $#triads;
    my @triads_str;

    for my $triad (@triads) {
        if ($triad == 0) {
            $megas_counter--;
            next;
        }

        my $triad_str = _solve_triad($triad);

        if ($megas_counter > 0) {
            my $mega = $cardinals{megas}->[$megas_counter];
            if ($megas_counter > 1) { $mega .= $triad == 1 ? 'ão' : 'ões' }
            $triad_str .= " $mega";

            if ($triad_str eq 'um mil') { $triad_str = 'mil' }

            $megas_counter--;
        }

        push @triads_str, $triad_str;
    }

    my $resp_str;

    if (@triads_str == 1) {
        $resp_str = $triads_str[0];
    }
    else {
        $resp_str .= join ', ', @triads_str[0 .. $#triads_str - 1];

        my $last_triad = $triads[-1];
        my $last_triad_str;

        if ($last_triad % 100 == 0 || $last_triad < 100) {
            $last_triad_str = "e $triads_str[-1]";
        }
        else {
            $last_triad_str = $triads_str[-1];
        }

        $resp_str .= " $last_triad_str";
    }

    return $resp_str;
}

=head2 _solve_triad( $number )

Receives a number with one to three digits (a triad) and returns it
written in words.

=cut

sub _solve_triad {
    my $number = shift;

    if ($number == 100) { return 'cem' }

    my $padded_number = sprintf "%03d", $number;
    my ($hundreds, $tens, $units) = split '', $padded_number;

    my @resp;

    if ($hundreds) { push @resp, $cardinals{hundreds}->[$hundreds] }

    my $first_tens = $tens . $units;

    if ($first_tens > 10 and $first_tens < 20) {
        push @resp, $cardinals{first_tens}->[$units];
    }
    else {
        if ($tens)  { push @resp, $cardinals{tens}->[$tens]   }
        if ($units) { push @resp, $cardinals{units}->[$units] }
    }

    return join ' e ', @resp;
}

1;

=head1 SEE ALSO

Lingua::PT::Nums2Words for pt_PT Portuguese.

=head1 AUTHOR

Gil Magno E<lt>gils@cpan.orgE<gt>

=head1 THANKS TO

Italo Gonçales (cpan:GONCALES) E<lt>italo.goncales@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Gil Magno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
