# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::ELL::Num2Word;
# ABSTRACT: Number to word conversion in Greek

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
our $VERSION = '0.2603260';

# }}}

# {{{ num2ell_cardinal                 convert number to text

sub num2ell_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(μηδέν ένα δύο τρία τέσσερα πέντε έξι επτά οκτώ εννέα δέκα έντεκα δώδεκα);
    my @teens = (
        'δεκατρία',     # 13
        'δεκατέσσερα',  # 14
        'δεκαπέντε',    # 15
        'δεκαέξι',      # 16
        'δεκαεπτά',     # 17
        'δεκαοκτώ',     # 18
        'δεκαεννέα',    # 19
    );
    my @tens = qw(είκοσι τριάντα σαράντα πενήντα εξήντα εβδομήντα ογδόντα ενενήντα);
    my @hundreds = (
        'εκατό',        # 100
        'διακόσια',     # 200
        'τριακόσια',    # 300
        'τετρακόσια',   # 400
        'πεντακόσια',   # 500
        'εξακόσια',     # 600
        'επτακόσια',    # 700
        'οκτακόσια',    # 800
        'εννιακόσια',   # 900
    );

    return $ones[$positive]           if ($positive >= 0 && $positive < 13);
    return $teens[$positive - 13]     if ($positive >= 13 && $positive < 20);

    my $out;
    my $remain;

    if ($positive > 19 && $positive < 100) {                   # 20 .. 99
        my $ten_idx = int($positive / 10) - 2;
        $remain     = $positive % 10;

        $out = $tens[$ten_idx];
        $out .= ' ' . $ones[$remain] if ($remain);
    }
    elsif ($positive == 100) {                                  # 100
        $out = 'εκατό';
    }
    elsif ($positive > 100 && $positive < 200) {                # 101 .. 199
        $remain = $positive % 100;
        $out    = 'εκατόν ' . num2ell_cardinal($remain);
    }
    elsif ($positive >= 200 && $positive < 1000) {              # 200 .. 999
        my $h_idx = int($positive / 100) - 1;
        $remain   = $positive % 100;

        $out = $hundreds[$h_idx];
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1000 && $positive < 2000) {             # 1000 .. 1999
        $remain = $positive % 1000;

        $out = 'χίλια';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 2000 && $positive < 1_000_000) {        # 2000 .. 999_999
        my $k_val = int($positive / 1000);
        $remain   = $positive % 1000;

        $out = num2ell_cardinal($k_val) . ' χιλιάδες';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1_000_000 && $positive < 2_000_000) {   # 1_000_000 .. 1_999_999
        $remain = $positive % 1_000_000;

        $out = 'ένα εκατομμύριο';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 2_000_000 && $positive < 1_000_000_000) { # 2_000_000 .. 999_999_999
        my $m_val = int($positive / 1_000_000);
        $remain   = $positive % 1_000_000;

        $out = num2ell_cardinal($m_val) . ' εκατομμύρια';
        $out .= ' ' . num2ell_cardinal($remain) if ($remain);
    }

    return $out;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::ELL::Num2Word - Number to word conversion in Greek


=head1 VERSION

version 0.2603260

Lingua::ELL::Num2Word is module for converting numbers into their written
representation in Modern Greek. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ELL::Num2Word;

 my $text = Lingua::ELL::Num2Word::num2ell_cardinal( 123 );

 print $text || "sorry, can't convert this number into Greek.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ell_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation in Modern Greek.
Only numbers from interval [0, 999_999_999] will be converted.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2ell_cardinal

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
