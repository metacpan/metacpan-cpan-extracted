# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::POL::Num2Word;
# ABSTRACT: Perl module for converting numeric values into their Polish equivalents

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use vars qw($Idziesiatka);

use lib $ENV{PMLIB_INC};

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';

# }}}

# {{{ new

sub new {
    my $class = shift;
    my $number = shift || '';
    $Idziesiatka=0;

    my $self = {};
    bless $self, $class;

    if( $number =~ /\d+/ ) {
        return( $self->parse($number) );
    }

    return( $self );
}

# }}}
# {{{ parse

sub num2pol_cardinal :Export {
    my $number = shift;
    my $obj = Lingua::POL::Num2Word->new();
    return $obj->parse($number);
}

sub parse :Export {
    my $self = shift;
    my $number = shift;

    return( SLOWNIE($number,0) );
}

# }}}
# {{{ currency

sub currency {
    my $self = shift;
    my $number = shift;

    return( SLOWNIE($number,1) );
}

# }}}
# {{{ SLOWNIE

sub SLOWNIE {
    my $Numer = shift // 0;
    my $currency = shift;

    my ($temps, $tempd, $tempj, $zlote, $grosze, $Licznik, $grd, $grj, $MiejsceDz, $T_S, $SLOWNIE);

    if ($Numer == 0) {
        if ($currency) {
            $SLOWNIE = "zero zl zero gr";
        } else {
            $SLOWNIE = "zero";
        }
    }
    else {
        if ($Numer > 9999999999999.99 || $Numer < 0) {
            #carp "out of range in $Numer";
            $SLOWNIE = "out of range";
        }
        else {
            $Numer = Trim($Numer);
            $MiejsceDz = InStr($Numer);
            if ($MiejsceDz > 0 && Right($Numer,2) ne "00") {
                if ($currency) {
                    $grosze = Left(Mid($Numer, $MiejsceDz + 1)."00", 2);
                    $grd = Dziesiatki(Right($grosze, 2));
                    if ($Idziesiatka!=1) {
                        $grj = Jednostki(Right($grosze, 1));
                    }
                    $grosze = " ".$grd.$grj."gr";
                    $Numer = Trim(Left($Numer, $MiejsceDz - 1));
                }
                else {
                    carp "no decimals allowed in parse mode in $Numer";
                    $zlote = "no decimals allowed in parse mode in $Numer";
                }
            }
            elsif ($currency) {
                $grosze = " zero gr";
            }
            if ($Numer>0 && ($currency || !$MiejsceDz)) {
                $Licznik = 1;
                while ($Numer ne "") {
                    $tempj = "";
                    $temps = Setki(Right("000".$Numer, 3)) // '';
                    $tempd = Dziesiatki(Right("00".$Numer, 2)) // '';
                    if ($Idziesiatka!=1) {
                        $tempj = Jednostki(Right($Numer, 1)) // '';
                    }
                    if ($Licznik==1) {
                        $T_S = $temps.$tempd.$tempj;
                    }
                    elsif ($Licznik==2) {
                        $T_S = $temps.$tempd.$tempj.KTys($Numer);
                    } elsif ($Licznik==3||$Licznik==4||$Licznik==5) {
                        $T_S = $temps.$tempd.$tempj.KMil($Numer, $Licznik);
                    }
                    $zlote = $T_S.($zlote // '');

                    if (length($Numer) > 3) {
                        $Numer = Left($Numer, length($Numer) - 3);
                        $Licznik++;
                    }
                    else {
                        $Numer = "";
                    }
                }
            } elsif ($currency || !$MiejsceDz) {
                $zlote = "zero "
            }
            if ($Numer !~ /^\d+$/ or $Numer > -1) {
                if ($currency) {
                    $SLOWNIE = $zlote."zl".$grosze;
                } else {
                    $SLOWNIE = $zlote;
                }
            }
        }
    }

    return $SLOWNIE;
}

# }}}
# {{{ KTys

sub KTys {
    my $Numer = shift;
    my $KTys;
    my $tys=Val(Right("000".$Numer, 3));

    if ($tys == 0) {
        $KTys = "";
    }
    else {
        $tys = Val(Right($Numer, 2));
        if ($tys == 1) {
            $KTys = "ąc ";
        }
        else {
            if ($tys == 12 || $tys == 13 || $tys == 14) {
                $KTys = "ęcy ";
            }
            else {
                $tys = Val(Right($Numer, 1));
            }
            if ( $tys == 2 || $tys == 3 || $tys == 4) {
                $KTys = "ące ";
            }
            else {
                $KTys = "ęcy ";
            }
        }
        $KTys = "tysi".$KTys;
    }

    return $KTys;
}

# }}}
# {{{ KMil

sub KMil {
    my ($Numer, $L)=@_;
    my ($KMil,$mil);
    my @RzadW;
    $RzadW[3] = "milion";
    $RzadW[4] = "miliard";
    $RzadW[5] = "bilion";
    $mil = Val(Right("000".$Numer, 3));
    if ($mil == 0) {
        $KMil = "";
    }
    else {
        $mil = Val(Right($Numer, 2));
        if ($mil == 1) {
            $KMil = " ";
        }
        else {
            if ($mil == 12 || $mil == 13 || $mil == 14) {
                $KMil = "ów ";
            }
            else {
                $mil = Val(Right($Numer, 1));
                if ($mil == 2 || $mil == 3 || $mil == 4) {
                    $KMil = "y ";
                } else {
                    $KMil = "ów ";
                }
            }
        }
        $KMil = $RzadW[$L].$KMil;
    }

    return $KMil;
}

# }}}
# {{{ Setki

sub Setki {
    my $Numer=shift;
    my ($setka, $wynik);
    $setka = Val(Left($Numer, 1));
    if ($setka == 1) {
        $wynik= "sto ";
    } elsif ($setka == 2) {
        $wynik = 'dwieście ';
    } elsif ($setka == 3) {
        $wynik = 'trzysta ';
    } elsif ($setka == 4) {
        $wynik = 'czterysta ';
    } elsif ($setka == 5) {
        $wynik = 'pięćset ';
    } elsif ($setka == 6) {
        $wynik = 'sześćset ';
    } elsif ($setka == 7) {
        $wynik = 'siedemset ';
    } elsif ($setka == 8) {
        $wynik = 'osiemset ';
    } elsif ($setka == 9) {
        $wynik = 'dziewięćset ';
    } else {
        $wynik = '';
    }

    return $wynik;
}

# }}}
# {{{ Dziesiatki

sub Dziesiatki {
    my $Number = shift;
    my $wynik = '';

    $Idziesiatka = Val(Left($Number, 1));
    if ($Idziesiatka == 1) {
        my $valnum = Val($Number);
        if ($valnum == 10) { $wynik = 'dziesięć '; }
        elsif ($valnum == 11) { $wynik = 'jedenaście '; }
        elsif ($valnum == 12) { $wynik = 'dwanaście '; }
        elsif ($valnum == 13) { $wynik = 'trzynaście '; }
        elsif ($valnum == 14) { $wynik = 'czternaście '; }
        elsif ($valnum == 15) { $wynik = 'piętnaście '; }
        elsif ($valnum == 16) { $wynik = 'szesnaście '; }
        elsif ($valnum == 17) { $wynik = 'siedemnaście '; }
        elsif ($valnum == 18) { $wynik = 'osiemnaście '; }
        elsif ($valnum == 19) { $wynik = 'dziewiętnaście '; }
    }
    else {
        if ($Idziesiatka == 2) { $wynik = 'dwadzieścia '; }
        if ($Idziesiatka == 3) { $wynik = 'trzydzieści '; }
        if ($Idziesiatka == 4) { $wynik = 'czterdzieści '; }
        if ($Idziesiatka == 5) { $wynik = 'pięćdziesiąt '; }
        if ($Idziesiatka == 6) { $wynik = 'sześćdziesiąt '; }
        if ($Idziesiatka == 7) { $wynik = 'siedemdziesiąt '; }
        if ($Idziesiatka == 8) { $wynik = 'osiemdziesiąt '; }
        if ($Idziesiatka == 9) { $wynik = 'dziewięćdziesiąt '; }
    }

    return $wynik;
}

# }}}
# {{{ Jednostki

sub Jednostki {
        my $Numer=shift;
        my ($jedst, $wynik);
        $jedst = Val(Right($Numer, 1));
        if ($jedst == 1) {
                $wynik = "jeden ";
        } elsif ($jedst == 2) {
                $wynik = "dwa ";
        } elsif ($jedst == 3) {
                $wynik = "trzy ";
        } elsif ($jedst == 4) {
                $wynik = "cztery ";
        } elsif ($jedst == 5) {
                $wynik = "pięć ";
        } elsif ($jedst == 6) {
                $wynik = "sześć ";
        } elsif ($jedst == 7) {
                $wynik = "siedem ";
        } elsif ($jedst == 8) {
                $wynik = "osiem ";
        } elsif ($jedst == 9) {
                $wynik = "dziewięć ";
        }
        return $wynik;
}

# }}}
# {{{ Left

sub Left {
    my ($Numer, $count) = @_;
    $Numer = substr($Numer,0,$count);

    return $Numer;
}

# }}}
# {{{ Right

sub Right {
    my ($Numer, $count) = @_;
    $Numer = substr($Numer,-$count);

    return $Numer;
}

# }}}
# {{{ Trim

sub Trim {
    my $Numer = shift;
    $Numer=~s/^\s+//;
    $Numer=~s/\s+$//;

    return $Numer;
}

# }}}
# {{{ Val

sub Val {
    my $Numer = shift;

    $Numer=~s/\D//g;

    return $Numer;
}

# }}}
# {{{ Mid

sub Mid {
    my ($Numer, $count) = @_;

    return ($Numer = substr($Numer,$count-1));
}

# }}}
# {{{ InStr

sub InStr {
    my $Numer = shift;
    my $ret=0;
    if ($Numer=~/^(\d+)\./) {
        $ret=length($1)+1;
    }

    return $ret;
}

# }}}


# {{{ num2pol_ordinal           number to ordinal string conversion

sub num2pol_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # Irregular ordinals 0-19
    my %base = (
        0  => 'zerowy',
        1  => 'pierwszy',
        2  => 'drugi',
        3  => 'trzeci',
        4  => 'czwarty',
        5  => 'piąty',
        6  => 'szósty',
        7  => 'siódmy',
        8  => 'ósmy',
        9  => 'dziewiąty',
        10 => 'dziesiąty',
        11 => 'jedenasty',
        12 => 'dwunasty',
        13 => 'trzynasty',
        14 => 'czternasty',
        15 => 'piętnasty',
        16 => 'szesnasty',
        17 => 'siedemnasty',
        18 => 'osiemnasty',
        19 => 'dziewiętnasty',
    );

    return $base{$number} if exists $base{$number};

    # Tens ordinals
    my %tens_ord = (
        20 => 'dwudziesty',
        30 => 'trzydziesty',
        40 => 'czterdziesty',
        50 => 'pięćdziesiąty',
        60 => 'sześćdziesiąty',
        70 => 'siedemdziesiąty',
        80 => 'osiemdziesiąty',
        90 => 'dziewięćdziesiąty',
    );

    # Hundreds ordinals
    my %hundreds_ord = (
        100 => 'setny',
        200 => 'dwusetny',
        300 => 'trzechsetny',
        400 => 'czterechsetny',
        500 => 'pięćsetny',
        600 => 'sześćsetny',
        700 => 'siedemsetny',
        800 => 'osiemsetny',
        900 => 'dziewięćsetny',
    );

    # For compound numbers, Polish uses: ordinal of each significant part
    # 21 = "dwudziesty pierwszy", 100 = "setny", 125 = "sto dwudziesty piąty"
    # For large numbers: cardinal prefix + ordinal of last significant part

    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        my $remainder = $number % 1_000_000;
        if ($remainder == 0) {
            return 'milionowy' if $millions == 1;
            return SLOWNIE($millions, 0) . 'milionowy';
        }
        my $prefix = SLOWNIE($millions * 1_000_000, 0);
        return $prefix . num2pol_ordinal($remainder);
    }

    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        my $remainder = $number % 1_000;
        if ($remainder == 0) {
            return 'tysięczny' if $thousands == 1;
            return SLOWNIE($thousands, 0) . 'tysięczny';
        }
        my $prefix = SLOWNIE($thousands * 1_000, 0);
        return $prefix . num2pol_ordinal($remainder);
    }

    if ($number >= 100) {
        my $h = int($number / 100) * 100;
        my $remainder = $number % 100;
        if ($remainder == 0) {
            return $hundreds_ord{$h};
        }
        # Cardinal hundreds prefix + ordinal of remainder
        my $cardinal_prefix = Setki(sprintf('%03d', $number));
        return $cardinal_prefix . num2pol_ordinal($remainder);
    }

    # 20-99 compound
    if ($number >= 20) {
        my $t = int($number / 10) * 10;
        my $remainder = $number % 10;
        if ($remainder == 0) {
            return $tens_ord{$t};
        }
        return $tens_ord{$t} . ' ' . $base{$remainder};
    }

    # Should not reach here
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

# {{{ POD

=pod

=encoding utf-8

=head1 NAME

Lingua::POL::Num2Word - Perl module for converting numeric values into their Polish equivalents

=head1 VERSION

version 0.2603300

=head1 DESCRIPTION

Number 2 word conversion in POL.

This is PetaMem release in iso-639-3 namespace.

=head1 SYNOPSIS

  use Lingua::POL::Num2Word;

  my $numbers = Lingua::POL::Num2Word->new;

  my $text = $numbers->parse( 123 );

  # prints 'sto dwadzieścia trzy'
  print $text;

  my $currency = $numbers->currency ( 123.45 );

  # prints 'sto dwadzieścia trzy zl czterdzieści pięć gr'
  print $currency;

=head1 FUNCTIONS

=over

=item new

Constructor

=item parse

Converts number into Polish

=item Dziesiatki

private

=item InStr

private

=item Jednostki

private

=item KMil

private

=item KTys

private

=item Left

private

=item Mid

private

=item Right

private

=item SLOWNIE

private

=item Setki

private

=item Trim

private

=item Val

private

=item num2pol_ordinal

Converts number to Polish ordinal (e.g. 1 => "pierwszy", 21 => "dwudziesty pierwszy").

=item currency

private


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHORS

 initial coding:
   Henrik Steffen E<lt>cpan@topconcepts.deE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 LICENSE

Original license is not known.
PetaMem added Perl 5 licesne as default.

=cut

# }}}
