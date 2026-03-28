# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::NOR::Num2Word;
# ABSTRACT: Number 2 word conversion in NOR.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';

my %group1 = qw(  0 null         1 en           2 to
                  3 tre          4 fire         5 fem
                  6 seks         7 sju          8 åtte
                  9 ni          10 ti          11 ellve
                 12 tolv        13 tretten     14 fjorten
                 15 femten      16 seksten     17 sytten
                 18 atten       19 nitten
               );
my %group2 = qw( 20 tjue        30 tretti      40 førti
                 50 femti       60 seksti      70 sytti
                 80 åtti        90 nitti
               );
my %group3 = (  100, 'ett hundre',  200, 'to hundre',     300, 'tre hundre',
                400, 'fire hundre', 500, 'fem hundre',    600, 'seks hundre',
                700, 'sju hundre',  800, 'åtte hundre',   900, 'ni hundre'
             );

my $singleton;

# }}}

# {{{ new

sub new
{
    my $invocant = shift;

    my $class = ref ( $invocant ) || $invocant;
    $singleton ||= bless {}, $class;

    return $singleton;
}

# }}}
# {{{ num2no_cardinal

sub num2no_cardinal {
    my $self = shift;

    my $result = '';
    my $number = shift // return $result;
    #print "$number -> "; 

    # check if number has decimals > 0, allowing whole numbers written as 2.00
    $number =~ /(\d+)\.(\d+)/;

    # numbers less than 0 are not supported and numbers containg decimals greater than 0 
    return $result if ( $number < 0 || ( defined $2 && $2 > 0 ) );

    my $reminder = 0;

    if ($number < 20) {
      $result = $group1{$number};
    }
    elsif ( $number < 100 ) {
      $reminder = $number % 10;
      if ( $reminder == 0 ) {
          $result = $group2{$number};
      }
      else {
          $result = $group2{$number - $reminder} . ' ' . $self->num2no_cardinal( $reminder );
      }
    }
    elsif ($number < 1000) {
        $reminder = $number % 100;
        if ( $reminder == 0 ) {
            $result = $group3{$number};
        }
        else {
            $result = $group3{$number - $reminder} . ' og ' . $self->num2no_cardinal( $reminder );
        }
    }
    elsif ( $number < 1000000 ) {
        $reminder = $number % 1000;

        my $tmp1 = ( $reminder != 0 ) ? ' '.$self->num2no_cardinal($reminder) : '';
        my $tmp2 = substr( $number, 0, length( $number ) - 3 );
        my $tmp3 = $tmp2 % 10;

        my $space = '';
        $space = ' og' if ( $reminder < 100 && $reminder != 0 );

        if ( $tmp3 == 1 && $tmp2 == 1 ) {
            $tmp2 = 'ett tusen';
        }
        else {
            $tmp2 = $self->num2no_cardinal($tmp2) . ' tusen';
        }

        $result = $tmp2 . $space . $tmp1;
    }
    elsif ( $number < 1_000_000_000 ) {
        $reminder = $number % 1000000;

        my $tmp1 = ( $reminder != 0 ) ? ' ' . $self->num2no_cardinal($reminder) : '';
        my $tmp2 = substr( $number, 0, length( $number ) - 6 );
        my $tmp3 = $tmp2 % 10;

        my $space = ($reminder && $reminder < 100000) ? ' og' : '';

        if ( $tmp3 == 1 && $tmp2 == 1 ) {
            $tmp2 = 'en million';
        }
        else {
            $tmp2 = $self->num2no_cardinal( $tmp2 ) . ' millioner';
        }
        $result = $tmp2 . $space . $tmp1;
    }
    else {
        # >= 1 000 000 000 unsupported
    }

    return $result;
}

# }}}

# {{{ num2no_ordinal / num2nor_ordinal   convert number to ordinal text

sub num2no_ordinal :Export { goto &num2nor_ordinal }

sub num2nor_ordinal :Export {
    my $number = shift;

    return if !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Fully irregular 1-3
    return 'første' if $number == 1;
    return 'andre'  if $number == 2;
    return 'tredje' if $number == 3;

    # Irregular 4-12
    my %irregular = (
         4 => 'fjerde',
         5 => 'femte',
         6 => 'sjette',
         7 => 'sjuende',
         8 => 'åttende',
         9 => 'niende',
        10 => 'tiende',
        11 => 'ellevte',
        12 => 'tolvte',
    );
    return $irregular{$number} if exists $irregular{$number};

    # 13-19: teens
    my %teens = (
        13 => 'trettende',
        14 => 'fjortende',
        15 => 'femtende',
        16 => 'sekstende',
        17 => 'syttende',
        18 => 'attende',
        19 => 'nittende',
    );
    return $teens{$number} if exists $teens{$number};

    # Tens ordinal forms (exact multiples)
    my %tens_ord = (
        20 => 'tjuende',
        30 => 'trettiende',
        40 => 'førtiende',
        50 => 'femtiende',
        60 => 'sekstiende',
        70 => 'syttiende',
        80 => 'åttiende',
        90 => 'nittiende',
    );

    # Helper: get an OO instance for calling num2no_cardinal
    my $obj = Lingua::NOR::Num2Word->new();

    # 20-99
    if ($number < 100) {
        my $tens = int($number / 10) * 10;
        my $ones = $number % 10;
        return $tens_ord{$tens} if $ones == 0;

        # Compound: cardinal tens prefix + ordinal of ones
        # Norwegian tens cardinals: tjue, tretti, førti, femti, seksti, sytti, åtti, nitti
        my %tens_card = (
            20 => 'tjue',    30 => 'tretti',  40 => 'førti',
            50 => 'femti',   60 => 'seksti',  70 => 'sytti',
            80 => 'åtti',    90 => 'nitti',
        );
        return $tens_card{$tens} . num2nor_ordinal($ones);
    }

    # 100-999
    if ($number < 1000) {
        my $remain = $number % 100;
        if ($remain == 0) {
            return $obj->num2no_cardinal(int($number / 100) * 100) . 'de';
        }
        return $obj->num2no_cardinal(int($number / 100) * 100) . ' og ' . num2nor_ordinal($remain);
    }

    # 1000-999_999
    if ($number < 1_000_000) {
        my $remain = $number % 1000;
        my $thousands = int($number / 1000);
        if ($remain == 0) {
            if ($thousands == 1) {
                return 'ett tusende';
            }
            return $obj->num2no_cardinal($thousands) . ' tusende';
        }
        if ($thousands == 1) {
            return 'ett tusen ' . num2nor_ordinal($remain);
        }
        return $obj->num2no_cardinal($thousands) . ' tusen ' . num2nor_ordinal($remain);
    }

    # 1_000_000 - 999_999_999
    if ($number < 1_000_000_000) {
        my $millions = int($number / 1_000_000);
        my $remain   = $number % 1_000_000;

        if ($remain == 0) {
            if ($millions == 1) {
                return 'en millionte';
            }
            return $obj->num2no_cardinal($millions) . ' millionte';
        }
        if ($millions == 1) {
            return 'en million ' . num2nor_ordinal($remain);
        }
        return $obj->num2no_cardinal($millions) . ' millioner ' . num2nor_ordinal($remain);
    }

    return;
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;

__END__

=head1 NAME

Lingua::NOR::Num2Word - convert whole number to norwegian text. Output text is in utf-8 encoding.

=head1 VERSION

version 0.2603270

=head1 SYNOPSIS

 use Lingua::NOR::Num2Word;

 my $no_num2word = Lingua::NOR::Num2Word->new();

 my $text = $no_num2word->num2no_cardinal( 1000000 );

 print $text || "Sorry, can't convert this number into norwegian.";

=head1 DESCRIPTION

Number 2 word conversion in NOR.

This module is based on and inspired by Roman Vasicek module
Lingua::CS::Num2Word.  Lingua::NOR::Num2Word is a module for
converting whole numbers into their norwegian textual
representation. Converts numbers from 0 up to 999 999 999.

=head1 METHODS

The following methods are provided by the Lingua::NOR::Num2Word class.

=over 2

=item B<new>

Create a singleton object.

 my $no_num2word = Lingua::NOR::Num2Word->new();

=item B<num2no_cardinal>

Converts a whole number to norwegian language.

  my $text = $no_num2word->num2no_cardinal( 1000000 );

=item B<num2nor_ordinal>

Convert number to its Norwegian ordinal text representation.
Exported function (not a method). Handles irregular forms
(første, andre, tredje, etc.) and applies correct suffixes
for regular forms.

  use Lingua::NOR::Num2Word qw(num2nor_ordinal);
  my $ord = num2nor_ordinal(3);    # "tredje"

=back

=head1 AUTHORS

 initial coding:
   Kjetil Fikkan E<lt>kjetil@fikkan.orgE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 coding (until 2005):
   Roman Vasicek E<lt>info@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

 Copyright (c) 2004 Kjetil Fikkan
 Copyright (c) PetaMem, s.r.o. 2010-present

 This module is free software. It may be used, redistributed
 and/or modified under the same terms as Perl itself.


=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut
