# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::UIG::Num2Word;
# ABSTRACT: Number to word conversion in Uyghur

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

# {{{ num2uig_cardinal                 convert number to text

sub num2uig_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # Uyghur numerals in Arabic script
    my @ones = ('نۆل', 'بىر', 'ئىككى', 'ئۈچ', 'تۆت', 'بەش',
                'ئالتە', 'يەتتە', 'سەككىز', 'توققۇز');
    my @tens = ('ئون', 'يىگىرمە', 'ئوتتۇز', 'قىرىق', 'ئەللىك',
                'ئاتمىش', 'يەتمىش', 'سەكسەن', 'توقسان');

    return $ones[$positive]                    if ($positive >= 0 && $positive < 10);  # 0 .. 9
    return $tens[$positive / 10 - 1]           if ($positive >= 10 && $positive < 100 && $positive % 10 == 0);  # 10,20,..,90

    my $out;
    my $remain;

    if ($positive > 9 && $positive < 100) {                     # 11 .. 99
        my $ten_idx = int($positive / 10);
        $remain     = $positive % 10;

        $out = $tens[$ten_idx - 1] . ' ' . $ones[$remain];
    }
    elsif ($positive == 100) {                                   # 100
        $out = 'يۈز';
    }
    elsif ($positive > 100 && $positive < 1000) {                # 101 .. 999
        my $hun_idx = int($positive / 100);
        $remain     = $positive % 100;

        $out  = $hun_idx == 1 ? 'يۈز' : $ones[$hun_idx] . ' يۈز';
        $out .= $remain ? ' ' . num2uig_cardinal($remain) : '';
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {         # 1000 .. 999_999
        my $tho_idx = int($positive / 1000);
        $remain     = $positive % 1000;

        $out  = $tho_idx == 1 ? 'مىڭ' : num2uig_cardinal($tho_idx) . ' مىڭ';
        $out .= $remain ? ' ' . num2uig_cardinal($remain) : '';
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) { # 1_000_000 .. 999_999_999
        my $mil_idx = int($positive / 1_000_000);
        $remain     = $positive % 1_000_000;

        $out  = num2uig_cardinal($mil_idx) . ' مىليون';
        $out .= $remain ? ' ' . num2uig_cardinal($remain) : '';
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

Lingua::UIG::Num2Word - Number to word conversion in Uyghur


=head1 VERSION

version 0.2603300

Lingua::UIG::Num2Word is a module for converting numbers into their written
representation in Uyghur (Arabic script). Converts whole numbers from 0 up
to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::UIG::Num2Word qw(num2uig_cardinal);

 my $text = num2uig_cardinal( 123 );

 print $text || "sorry, can't convert this number into Uyghur.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2uig_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
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

=item num2uig_cardinal

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
