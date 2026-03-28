# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::LTZ::Num2Word;
# ABSTRACT: Number to word conversion in Luxembourgish

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

# {{{ num2ltz_cardinal                 convert number to text

sub num2ltz_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # 0..12 are irregular standalone forms
    my @tokens1 = qw(null een zwee dräi véier fënnef sechs siwen aacht néng zéng eelef zwielef);

    # tens 20..90 (index 0=20, 1=30, ...)
    my @tokens2 = qw(zwanzeg drësseg véierzeg fofzeg sechzeg siwwenzeg achtzeg nonzeg);

    # standalone 0
    return 'null'           if $positive == 0;

    # standalone 1 has trailing 't'
    return 'eent'           if $positive == 1;

    return $tokens1[$positive]              if ($positive >= 2 && $positive < 13);   # 2 .. 12
    return 'fofzéng'                        if ($positive == 15);                    # 15 exception
    return 'siechzéng'                      if ($positive == 16);                    # 16 exception
    return 'siwwenzéng'                     if ($positive == 17);                    # 17 exception
    return 'uechtzéng'                      if ($positive == 18);                    # 18 exception
    return 'nonzéng'                        if ($positive == 19);                    # 19 exception
    return $tokens1[$positive-10] . 'zéng'  if ($positive > 12 && $positive < 20);  # 13, 14

    my $out;          # string for return value construction
    my $one_idx;      # index for array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 100) {              # 20 .. 99
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        if ($remain) {
            my $unit = $tokens1[$remain];
            my $tens = $tokens2[$one_idx - 2];
            my $connector = _connector($tens);
            $out = $unit . $connector . $tens;
        }
        else {
            $out = $tokens2[$one_idx - 2];
        }
    }
    elsif ($positive >= 100 && $positive < 1000) {      # 100 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        $out  = ($one_idx == 1 ? '' : $tokens1[$one_idx]) . 'honnert';
        $out .= $remain ? num2ltz_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {  # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = ($one_idx == 1 ? '' : num2ltz_cardinal($one_idx)) . 'dausend';
        $out .= $remain ? num2ltz_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        # "eng Millioun" for 1M, "zwee Milliounen" for 2M+
        if ($one_idx == 1) {
            $out = 'eng Millioun';
        }
        else {
            $out = num2ltz_cardinal($one_idx) . ' Milliounen';
        }
        $out .= $remain ? ' ' . num2ltz_cardinal($remain) : '';
    }

    return $out;
}

# }}}
# {{{ _connector                       apply n-rule (Eifel rule) for 'an'

sub _connector {
    my $tens = shift;

    # The Eifel rule (n-Regel): final 'n' is dropped before a consonant,
    # EXCEPT before n, d, t, z, h.
    # Applied to the connector 'an' before the tens word.
    my $first_char = substr($tens, 0, 1);

    # Before a vowel: keep 'n'
    return 'an' if $first_char =~ m/[aeiouäëéAEIOU]/;

    # Before consonants n, d, t, z, h: keep 'n'
    return 'an' if $first_char =~ m/[ndtzh]/;

    # Before all other consonants: drop 'n'
    return 'a';
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

Lingua::LTZ::Num2Word - Number to word conversion in Luxembourgish


=head1 VERSION

version 0.2603270

Lingua::LTZ::Num2Word is module for converting numbers into their written
representation in Luxembourgish (Lëtzebuergesch). Converts whole numbers
from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LTZ::Num2Word;

 my $text = Lingua::LTZ::Num2Word::num2ltz_cardinal( 123 );
 print $text || "sorry, can't convert this number into Luxembourgish.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ltz_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<capabilities> (void)

  =>  hashref  supported features (cardinal => 1, ordinal => 0)

Returns a hashref indicating which conversion types are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2ltz_cardinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 coding:
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
