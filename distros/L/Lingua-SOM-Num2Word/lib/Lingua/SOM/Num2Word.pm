# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::SOM::Num2Word;
# ABSTRACT: Number to word conversion in Somali

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

# {{{ num2som_cardinal                 convert number to text

sub num2som_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    # Somali numerals: unit iyo ten (ones stated before tens)
    # Zero is not standard in Somali; we use "eber" (nothing).
    my @ones     = qw(eber ków lába sáddex áfar shán líx toddobá siddéed sagaal);
    my @ones_iyo = qw(eber koób lába sáddex áfar shán líx toddobá siddéed sagaál);
    my @tens     = qw(toban labaátan sóddon afártan kónton líxdan toddobaátan siddeétan sagaáshan);

    return $ones[$positive]             if ($positive >= 0 && $positive < 10);  # 0 .. 9
    return 'toban'                      if ($positive == 10);                   # 10

    my $out;
    my $remain;

    if ($positive > 10 && $positive < 20) {                       # 11 .. 19
        $out = $ones_iyo[$positive - 10] . ' iyo toban';
    }
    elsif ($positive >= 20 && $positive < 100) {                  # 20 .. 99
        my $ten_idx = int($positive / 10) - 1;                   # tens[0]=toban, tens[1]=labaátan
        $remain = $positive % 10;

        if ($remain) {
            $out = $ones_iyo[$remain] . ' iyo ' . $tens[$ten_idx];
        }
        else {
            $out = $tens[$ten_idx];
        }
    }
    elsif ($positive >= 100 && $positive < 1000) {                # 100 .. 999
        my $hun = int($positive / 100);
        $remain = $positive % 100;

        $out = $hun == 1 ? 'boqól' : $ones[$hun] . ' boqól';
        $out .= ' iyo ' . num2som_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {          # 1000 .. 999_999
        my $thou = int($positive / 1000);
        $remain  = $positive % 1000;

        $out = $thou == 1 ? 'kún' : num2som_cardinal($thou) . ' kún';
        $out .= ' iyo ' . num2som_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) { # 1_000_000 .. 999_999_999
        my $mil = int($positive / 1_000_000);
        $remain = $positive % 1_000_000;

        $out = $mil == 1 ? 'malyúun' : num2som_cardinal($mil) . ' malyúun';
        $out .= ' iyo ' . num2som_cardinal($remain) if ($remain);
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

Lingua::SOM::Num2Word - Number to word conversion in Somali


=head1 VERSION

version 0.2603300

Lingua::SOM::Num2Word is a module for converting numbers into their written
representation in Somali. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SOM::Num2Word qw(num2som_cardinal);

 my $text = num2som_cardinal( 123 );

 print $text || "sorry, can't convert this number into Somali.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2som_cardinal> (positional)

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

=item num2som_cardinal

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
