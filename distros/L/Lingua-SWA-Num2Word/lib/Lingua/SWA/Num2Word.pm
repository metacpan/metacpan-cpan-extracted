# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::SWA::Num2Word;
# ABSTRACT: Number to word conversion in Swahili

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2002-present';
our $VERSION = '0.2603270';

# }}}

# {{{ num2swa_cardinal                 convert number to text

sub num2swa_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(sifuri moja mbili tatu nne tano sita saba nane tisa);
    my @tens = qw(kumi ishirini thelathini arobaini hamsini sitini sabini themanini tisini);

    return $ones[$positive]             if ($positive >= 0 && $positive < 10);  # 0 .. 9
    return 'kumi'                       if ($positive == 10);                   # 10
    return 'kumi na ' . $ones[$positive - 10]
                                        if ($positive > 10 && $positive < 20);  # 11 .. 19

    my $out;
    my $remain;

    if ($positive > 19 && $positive < 100) {                    # 20 .. 99
        my $ten_idx = int($positive / 10) - 1;                  # tens[0]=kumi, tens[1]=ishirini
        $remain = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= ' na ' . $ones[$remain] if ($remain);
    }
    elsif ($positive > 99 && $positive < 1000) {                # 100 .. 999
        my $hun = int($positive / 100);
        $remain = $positive % 100;

        $out = 'mia ' . $ones[$hun];
        $out .= ' na ' . num2swa_cardinal($remain) if ($remain);
    }
    elsif ($positive > 999 && $positive < 1_000_000) {          # 1000 .. 999_999
        my $thou = int($positive / 1000);
        $remain  = $positive % 1000;

        $out = 'elfu ' . num2swa_cardinal($thou);
        $out .= ' na ' . num2swa_cardinal($remain) if ($remain);
    }
    elsif ($positive > 999_999 && $positive < 1_000_000_000) {  # 1_000_000 .. 999_999_999
        my $mil = int($positive / 1_000_000);
        $remain = $positive % 1_000_000;

        $out = 'milioni ' . num2swa_cardinal($mil);
        $out .= ' ' . num2swa_cardinal($remain) if ($remain);
    }

    return $out;
}

# }}}


# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 0,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::SWA::Num2Word - Number to word conversion in Swahili


=head1 VERSION

version 0.2603270

Lingua::SWA::Num2Word is a module for converting numbers into their written
representation in Swahili. Converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SWA::Num2Word qw(num2swa_cardinal);

 my $text = num2swa_cardinal( 123 );

 print $text || "sorry, can't convert this number into Swahili.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2swa_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2swa_cardinal

=back

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

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
