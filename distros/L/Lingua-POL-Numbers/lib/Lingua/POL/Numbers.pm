# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::POL::Numbers;
# ABSTRACT: Number 2 word conversion in POL.

# {{{ use block

use warnings;
use strict;
use 5.10.1;
use vars qw($Idziesiatka);
use utf8;

use Carp;
use Perl6::Export::Attrs;

no if $] >= 5.018, 'warnings', "experimental::smartmatch";

# }}}
# {{{ variables declarations

our $VERSION = 0.135;

# }}}
# {{{ new

sub new
{
        my $class = shift;
        my $number = shift || '';
        $Idziesiatka=0;

        my $self = {};
        bless $self, $class;

        if( $number =~ /\d+/ ) {
                return( $self->parse($number) );
        };

        return( $self );
};

# }}}
# {{{ parse

sub parse :Export
{
        my $self = shift;
        my $number = shift;
        return( SLOWNIE($number,0) );
};

# }}}
# {{{ currency

sub currency
{
        my $self = shift;
        my $number = shift;
        return( SLOWNIE($number,1) );
};

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
        } else {
                if ($Numer > 9999999999999.99 || $Numer < 0) {
                        #carp "out of range in $Numer";
                        $SLOWNIE = "out of range";
                } else {
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
                                } else {
                                        carp "no decimals allowed in parse mode in $Numer";
                                        $zlote = "no decimals allowed in parse mode in $Numer";
                                }
                        } elsif ($currency) {
                                $grosze = " zero gr";
                        }
                        if ($Numer>0 && ($currency || !$MiejsceDz)) {
                                $Licznik = 1;
                                while ($Numer ne "") {
                                        $temps = "";
                                        $tempd = "";
                                        $tempj = "";
                                        $temps = Setki(Right("000".$Numer, 3));
                                        $tempd = Dziesiatki(Right("00".$Numer, 2));
                                        if ($Idziesiatka!=1) {
                                                $tempj = Jednostki(Right($Numer, 1));
                                        }
                                        if ($Licznik==1) {
                                                $T_S = $temps.$tempd.$tempj;
                                        } elsif ($Licznik==2) {
                                                $T_S = $temps.$tempd.$tempj.KTys($Numer);
                                        } elsif ($Licznik==3||$Licznik==4||$Licznik==5) {
                                                $T_S = $temps.$tempd.$tempj.KMil($Numer, $Licznik);
                                        }
                                        $zlote = $T_S.($zlote // '');

                                        if (length($Numer) > 3) {
                                                $Numer = Left($Numer, length($Numer) - 3);
                                                $Licznik++;
                                        } else {
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
        } else {
                $mil = Val(Right($Numer, 2));
                if ($mil == 1) {
                        $KMil = " ";
                } else {
                        if ($mil == 12 || $mil == 13 || $mil == 14) {
                                $KMil = "ów ";
                        } else {
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
        given(Val($Number)) {
            when (10) { $wynik = 'dziesięćdz '; }
            when (11) { $wynik = 'jedenaście '; }
            when (12) { $wynik = 'dwanaście '; }
            when (13) { $wynik = 'trzynaście '; }
            when (14) { $wynik = 'czternaście '; }
            when (15) { $wynik = 'pietnaście '; }
            when (16) { $wynik = 'szesnaście '; }
            when (17) { $wynik = 'siedemnaście '; }
            when (18) { $wynik = 'osiemnaście '; }
            when (19) { $wynik = 'dziewiętnaście '; }
        }
    }
    else {
        given ($Idziesiatka) {
            when (2) { $wynik = 'dwadzieścia '; }
            when (3) { $wynik = 'trzydzieści '; }
            when (4) { $wynik = 'czterdzieści '; }
            when (5) { $wynik = 'piędzieśąt '; }
            when (6) { $wynik = 'sześdzieśąt '; }
            when (7) { $wynik = 'siedemdzieśąt '; }
            when (8) { $wynik = 'osiemdzieśąt '; }
            when (9) { $wynik = 'dziewiędzieśąt '; }
        }
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

1;

# {{{ POD

=pod

=encoding utf-8

=head1 NAME

Lingua::POL::Numbers - Perl module for converting numeric values into their Polish equivalents

=head1 VERSION

version 0.135

=head1 DESCRIPTION

Number 2 word conversion in POL.

This is PetaMem release in iso-639-3 namespace.

=head1 SYNOPSIS

  use Lingua::POL::Numbers;

  my $numbers = Lingua::POL::Numbers->new;


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

=item currency

private

=back

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHOR

Henrik Steffen, <cpan@topconcepts.de>

Maintenance
PetaMem s.r.o., <info@petamem.com>

=head1 LICENSE

Original license is not known.
PetaMem added Perl 5 licesne as default.

=cut

# }}}
