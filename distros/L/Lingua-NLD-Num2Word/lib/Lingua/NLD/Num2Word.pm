# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::NLD::Num2Word;
# ABSTRACT: Number 2 word conversion in NLD.

# {{{ use block

use 5.16.0;
use utf8;

use Carp;
use Readonly;
use Export::Attrs;

# }}}
# {{{ var block

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2015-present';
our $VERSION = '0.2603230';

# }}}

# {{{ num2nld_cardinal                 convert number to text

sub num2nld_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @tokens1 = qw(nul een twee drie vier vijf zes zeven acht negen tien
                     elf twaalf dertien veertien vijftien zestien zeventien achtien negentien);
    my @tokens2 = qw(twintig dertig veertig vijftig zestig zeventig tachtig negentig honderd);

    return $tokens1[$positive]           if ($positive >= 0 && $positive < 20); # 0 .. 19

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens1 array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 101) {              # 20 .. 100
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = "$tokens1[$remain]en" if ($remain);
        $out .= $tokens2[$one_idx - 2];
    }
    elsif ($positive > 100 && $positive < 1000) {       # 101 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        $out  = "$tokens1[$one_idx]honderd";
        $out .= $remain ? num2nld_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {  # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = num2nld_cardinal($one_idx) . 'duizend ';
        $out .= $remain ? num2nld_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        $out  = num2nld_cardinal($one_idx) . " miljoen";
        $out .= $remain ? ' ' . num2nld_cardinal($remain) : '';
    }

    return $out;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::NLD::Num2Word  

=head1 VERSION

version 0.2603230

Number 2 word conversion in NLD.

Lingua::NLD::Num2Word is module for converting numbers into their written
representationin German. Converts whole numbers from 0 up to 999 999 999.

Text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::NLD::Num2Word;

 my $text = Lingua::NLD::Num2Word::num2nld_cardinal( 123 );

 print $text || "sorry, can't convert this number into dutch.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2nld_cardinal> (positional)

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

=item num2nld_cardinal


=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:


=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2015-present

=cut

# }}}
