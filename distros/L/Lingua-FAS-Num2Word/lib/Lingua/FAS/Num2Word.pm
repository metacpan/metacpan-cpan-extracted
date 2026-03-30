# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::FAS::Num2Word;
# ABSTRACT: Number to word conversion in Persian

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
our $VERSION = '0.2603300';

# }}}

# {{{ num2fas_cardinal                 convert number to text

sub num2fas_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = ('صفر', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه');
    my @teens = ('ده', 'یازده', 'دوازده', 'سیزده', 'چهارده', 'پانزده',
                 'شانزده', 'هفده', 'هجده', 'نوزده');
    my @tens = ('بیست', 'سی', 'چهل', 'پنجاه', 'شصت', 'هفتاد', 'هشتاد', 'نود');
    my @hundreds = ('صد', 'دویست', 'سیصد', 'چهارصد', 'پانصد',
                    'ششصد', 'هفتصد', 'هشتصد', 'نهصد');

    # 0 .. 9
    return $ones[$positive] if $positive < 10;

    # 10 .. 19
    return $teens[$positive - 10] if $positive < 20;

    # 20 .. 99
    if ($positive < 100) {
        my $ten_idx = int($positive / 10) - 2;
        my $remain  = $positive % 10;

        return $tens[$ten_idx] if $remain == 0;
        return $tens[$ten_idx] . ' و ' . $ones[$remain];
    }

    my $out;
    my $remain;

    # 100 .. 999
    if ($positive < 1000) {
        my $hun_idx = int($positive / 100) - 1;
        $remain     = $positive % 100;

        $out  = $hundreds[$hun_idx];
        $out .= $remain ? ' و ' . num2fas_cardinal($remain) : '';
    }
    # 1000 .. 999_999
    elsif ($positive < 1_000_000) {
        my $tho_idx = int($positive / 1000);
        $remain     = $positive % 1000;

        $out  = $tho_idx == 1 ? 'هزار' : num2fas_cardinal($tho_idx) . ' هزار';
        $out .= $remain ? ' و ' . num2fas_cardinal($remain) : '';
    }
    # 1_000_000 .. 999_999_999
    elsif ($positive < 1_000_000_000) {
        my $mil_idx = int($positive / 1_000_000);
        $remain     = $positive % 1_000_000;

        $out  = $mil_idx == 1 ? 'یک میلیون' : num2fas_cardinal($mil_idx) . ' میلیون';
        $out .= $remain ? ' و ' . num2fas_cardinal($remain) : '';
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

Lingua::FAS::Num2Word - Number to word conversion in Persian


=head1 VERSION

version 0.2603300

Lingua::FAS::Num2Word is module for converting numbers into their written
representation in Persian (Farsi). Converts whole numbers from 0 up to
999 999 999.

Text is encoded in UTF-8 and uses Arabic script as standard for Persian.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FAS::Num2Word;

 my $text = Lingua::FAS::Num2Word::num2fas_cardinal( 123 );

 print $text || "sorry, can't convert this number into Persian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2fas_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation in Persian.
Only numbers from interval [0, 999_999_999] will be converted.


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2fas_cardinal

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
