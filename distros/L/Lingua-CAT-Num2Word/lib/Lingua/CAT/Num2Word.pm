# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::CAT::Num2Word;
# ABSTRACT: Number to word conversion in Catalan

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2004-present';
our $VERSION = '0.2603270';

# }}}

# {{{ num2cat_cardinal                 convert number to text

sub num2cat_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(zero un dos tres quatre cinc sis set vuit nou);
    my @teens = qw(deu onze dotze tretze catorze quinze setze disset divuit dinou);
    my @tens  = qw(_ _ vint trenta quaranta cinquanta seixanta setanta vuitanta noranta);

    return $ones[$positive]              if $positive >= 0 && $positive <= 9;
    return $teens[$positive - 10]        if $positive >= 10 && $positive <= 19;

    if ($positive >= 20 && $positive <= 29) {
        return 'vint'                    if $positive == 20;
        return 'vint-i-' . $ones[$positive - 20];
    }

    my $out;

    if ($positive >= 30 && $positive <= 99) {
        my $ten_idx = int($positive / 10);
        my $remain  = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= '-' . $ones[$remain]     if $remain;
        return $out;
    }

    if ($positive >= 100 && $positive <= 999) {
        my $hun_idx = int($positive / 100);
        my $remain  = $positive % 100;

        if ($hun_idx == 1) {
            $out = 'cent';
        }
        else {
            $out = $ones[$hun_idx] . '-cents';
        }
        $out .= ' ' . num2cat_cardinal($remain) if $remain;
        return $out;
    }

    if ($positive >= 1000 && $positive <= 999_999) {
        my $tho_idx = int($positive / 1000);
        my $remain  = $positive % 1000;

        if ($tho_idx == 1) {
            $out = 'mil';
        }
        else {
            $out = num2cat_cardinal($tho_idx) . ' mil';
        }
        $out .= ' ' . num2cat_cardinal($remain) if $remain;
        return $out;
    }

    if ($positive >= 1_000_000 && $positive <= 999_999_999) {
        my $mil_idx = int($positive / 1_000_000);
        my $remain  = $positive % 1_000_000;

        if ($mil_idx == 1) {
            $out = 'un milió';
        }
        else {
            $out = num2cat_cardinal($mil_idx) . ' milions';
        }
        $out .= ' ' . num2cat_cardinal($remain) if $remain;
        return $out;
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

=encoding utf-8

=head1 NAME

Lingua::CAT::Num2Word - Number to word conversion in Catalan


=head1 VERSION

version 0.2603270

Lingua::CAT::Num2Word is a module for converting numbers into their written
representation in Catalan. Converts whole numbers from 0 up to 999 999 999.

Output text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::CAT::Num2Word;

 my $text = Lingua::CAT::Num2Word::num2cat_cardinal( 123 );

 print $text || "sorry, can't convert this number into Catalan.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2cat_cardinal> (positional)

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

=item num2cat_cardinal

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

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
