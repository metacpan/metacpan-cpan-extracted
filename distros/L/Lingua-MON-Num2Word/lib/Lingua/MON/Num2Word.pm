# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::MON::Num2Word;
# ABSTRACT: Number to word conversion in Mongolian

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

# {{{ num2mon_cardinal                 convert number to text

sub num2mon_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # cardinal forms (standalone)
    my @units = qw(тэг нэг хоёр гурав дөрөв тав зургаа долоо найм ес);

    # combining forms (used before зуу, мянга, or as tens prefix)
    my @units_combining = qw(тэг нэг хоёр гурван дөрвөн таван зургаан долоон найман есөн);

    # tens standalone
    my @tens = ('', '', 'хорь', 'гуч', 'дөч', 'тави', 'жар', 'дал', 'ная', 'ер');

    # tens combining (before units)
    my @tens_combining = ('', 'арван', 'хорин', 'гучин', 'дөчин', 'тавин', 'жаран', 'далан', 'наян', 'ерэн');

    return $units[$positive]  if ($positive >= 0 && $positive < 10);
    return 'арав'             if ($positive == 10);

    my $out;
    my $idx;
    my $remain;

    if ($positive > 10 && $positive < 20) {                 # 11 .. 19
        $remain = $positive % 10;
        $out = "арван $units[$remain]";
    }
    elsif ($positive > 19 && $positive < 100) {             # 20 .. 99
        $idx    = int ($positive / 10);
        $remain = $positive % 10;

        if ($remain) {
            $out = "$tens_combining[$idx] $units[$remain]";
        }
        else {
            $out = $tens[$idx];
        }
    }
    elsif ($positive == 100) {                              # 100
        $out = 'зуу';
    }
    elsif ($positive > 100 && $positive < 1000) {           # 101 .. 999
        $idx    = int ($positive / 100);
        $remain = $positive % 100;

        if ($idx == 1) {
            $out = 'зуун';
        }
        else {
            $out = "$units_combining[$idx] зуун";
        }
        $out .= $remain ? ' ' . num2mon_cardinal($remain) : '';

        # standalone зуу if no remainder and idx == 1 already handled
    }
    elsif ($positive > 999 && $positive < 1_000_000) {      # 1000 .. 999_999
        $idx    = int ($positive / 1000);
        $remain = $positive % 1000;

        if ($idx == 1) {
            $out = 'мянга';
        }
        else {
            $out = num2mon_cardinal($idx) . ' мянга';
        }
        $out .= $remain ? ' ' . num2mon_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                   # 1_000_000 .. 999_999_999
        $idx    = int ($positive / 1000000);
        $remain = $positive % 1000000;

        if ($idx == 1) {
            $out = 'нэг сая';
        }
        else {
            $out = num2mon_cardinal($idx) . ' сая';
        }
        $out .= $remain ? ' ' . num2mon_cardinal($remain) : '';
    }

    return $out;
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::MON::Num2Word - Number to word conversion in Mongolian

=head1 VERSION

version 0.2603300

Lingua::MON::Num2Word is a module for converting numbers into their written
representation in Mongolian (Cyrillic script). Converts whole numbers from 0
up to 999 999 999.

Text is encoded in UTF-8 (Cyrillic script).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::MON::Num2Word;

 my $text = Lingua::MON::Num2Word::num2mon_cardinal( 123 );
 print $text || "sorry, can't convert this number into Mongolian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2mon_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Mongolian text representation (Cyrillic script).
Only numbers from interval [0, 999_999_999] will be converted.

=item B<capabilities> (void)

  =>  hashref    hash of supported conversion types

Returns a hashref indicating which conversion types this module supports.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2mon_cardinal

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
