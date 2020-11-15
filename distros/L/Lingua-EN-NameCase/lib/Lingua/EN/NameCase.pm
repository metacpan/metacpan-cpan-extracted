package Lingua::EN::NameCase;

=head1 NAME

Lingua::EN::NameCase - Correctly case a person's name from UPERCASE or lowcase

=cut

use warnings;
use strict;
use locale;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $HEBREW $SPANISH $ROMAN $POSTNOMINAL );

=head1 VERSION

Version 1.21

=cut

our $VERSION = '1.21';

=head1 SYNOPSIS

    # Working with scalars; complementing lc and uc.

    use Lingua::EN::NameCase qw( nc );

    $FixedCasedName  = nc( $OriginalName );

    $FixedCasedName  = nc( \$OriginalName );

    # Working with arrays or array references.

    use Lingua::EN::NameCase 'NameCase';

    $FixedCasedName  = NameCase( $OriginalName );
    @FixedCasedNames = NameCase( @OriginalNames );

    $FixedCasedName  = NameCase( \$OriginalName );
    @FixedCasedNames = NameCase( \@OriginalNames );

    NameCase( \@OriginalNames ) ; # In-place.

    # NameCase will not change a scalar in-place, i.e.
    NameCase( \$OriginalName ) ; # WRONG: null operation.

    $Lingua::EN::NameCase::SPANISH = 1;
    # Now 'El' => 'El' instead of (default) Greek 'El' => 'el'.
    # Now 'La' => 'La' instead of (default) French 'La' => 'la'.

    $Lingua::EN::NameCase::HEBREW = 0;
    # Now 'Aharon BEN Amram Ha-Kohein' => 'Aharon Ben Amram Ha-Kohein'
    #   instead of (default) => 'Aharon ben Amram Ha-Kohein'.

    $Lingua::EN::NameCase::ROMAN = 0;
    # Now 'Li' => 'Li' instead of (default) 'Li' => 'LI'.

    $Lingua::EN::NameCase::POSTNOMINAL = 0;
    # Now 'PHD' => 'PhD' instead of (default) 'PHD' => 'Phd'.

=head1 DESCRIPTION

Forenames and surnames are often stored either wholly in UPPERCASE
or wholly in lowercase. This module allows you to convert names into
the correct case where possible.

Although forenames and surnames are normally stored separately if they
do appear in a single string, whitespace separated, NameCase and nc deal
correctly with them.

NameCase currently correctly name cases names which include any of the
following:

    Mc, Mac, al, el, ap, da, de, delle, della, di, du, del, der,
    la, le, lo, van and von.

It correctly deals with names which contain apostrophes and hyphens too.

=head2 EXAMPLE FIXES

    Original            Name Case
    --------            ---------
    KEITH               Keith
    LEIGH-WILLIAMS      Leigh-Williams
    MCCARTHY            McCarthy
    O'CALLAGHAN         O'Callaghan
    ST. JOHN            St. John

plus "son (daughter) of" etc. in various languages, e.g.:

    VON STREIT          von Streit
    VAN DYKE            van Dyke
    AP LLWYD DAFYDD     ap Llwyd Dafydd
    etc.

plus names with roman numerals (up to 89, LXXXIX), e.g.:

    henry viii          Henry VIII
    louis xiv           Louis XIV

=cut

#--------------------------------------------------------------------------
# Modules

use Carp;
use Exporter();

@ISA        = qw( Exporter );
@EXPORT     = qw( nc );
@EXPORT_OK  = qw( NameCase nc );

#--------------------------------------------------------------------------
# Variables

$HEBREW         = 1;
$SPANISH        = 0;
$ROMAN          = 1;
$POSTNOMINAL    = 1;

my @POST_NOMINAL_INITIALS = qw(
    VC GC KG LG KT LT KP GCB OM GCSI GCMG GCIE GCVO GBE CH KCB DCB KCSI KCMG
    DCMG KCIE KCVO DCVO KBE DBE CB CSI CMG CIE CVO CBE DSO LVO OBE ISO MVO MBE
    IOM CGC RRC DSC MC DFC AFC ARRC OBI DCM CGM GM IDSM DSM MM DFM AFM SGM IOM
    CPM QGM RVM BEM QPM QFSM QAM CPM MSM ERD VD TD UD ED RD VRD AE

    PC ADC QHP QHS QHDS QHNS QHC SCJ J LJ QS SL QC KC JP DL MP MSP MSYP AM AM
    MLA MEP  DBEnv DConstMgt DREst EdD DPhil PhD DLitt DSocSci MD EngD DD LLD
    DProf MA MArch MAnth MSc MMORSE MMath MMathStat MPharm MPhil MSc MSci MSt
    MRes MEng MChem MBiochem MSocSc MMus LLM BCL MPhys MComp MAcc MFin MBA MPA
    MEd MEP MEnt MCGI MGeol MLitt MEarthSc MClinRes BA BSc LLB BEng MBChB FdA
    FdSc FdEng PgDip PgD PgCert PgC PgCLTHE AUH AKC AUS HNC HNCert HND HNDip
    DipHE Dip OND CertHE ACSM MCSM DIC AICSM ARSM ARCS LLB LLM BCL MJur DPhil
    PhD LLD DipLP FCILEx GCILEx ACILEx CQSW DipSW BSW MSW FCILT CMILT MILT CPL
    CTP CML PLS CTL DLP PLog EJLog ESLog EMLog JrLog Log SrLog BArch MArch ARB
    RIBA RIAS RIAI RSAW MB BM BS BCh BChir MRCS FRCS MS MCh. MRCP FRCP MRCPCH
    FRCPCH MRCPath MFPM FFPM BDS MRCPsych FRCPsych MRCOG FRCOG MCEM FCEM FRCA
    FFPMRCA MRCGP FRCGP BSc MScChiro MChiro MSc DC LFHOM MFHOM FFHOM FADO FBDO
    FCOptom MCOptom MOst DPT MCSP FCSP. SROT MSCR FSCR. CPhT RN VN RVN BVSc
    BVetMed VetMB BVM&S MRCVS FRCVS FAWM PGCAP PGCHE PGCE PGDE BEd NPQH QTS
    CSci CSciTeach RSci RSciTech CEng IEng EngTech ICTTech DEM MM CMarEng
    CMarSci CMarTech IMarEng MarEngTech RGN SRN RMN RSCN SEN EN RNMH RN RM RN1
    RNA RN2 RN3 RNMH RN4 RN5 RNLD RN6 RN8 RNC RN7 RN9 RHV RSN ROH RFHN SPAN
    SPMH SPCN SPLD SPHP SCHM SCLD SPCC SPDN V100 V200 V300 LPE MSc
);

#--------------------------------------------------------------------------
# Functions

=head2 NameCase

Takes a scalar, scalarref, array or arrayref, and changes the case of the
contents, as appropriate. Essentially a wrapper around nc().

=cut

sub NameCase {
    croak "Usage: \$SCALAR|\@ARRAY = NameCase [\\]\$SCALAR|\@ARRAY"
        if ref $_[0] and ( ref $_[0] ne 'ARRAY' and ref $_[0] ne 'SCALAR' );

    local( $_ );

    if( wantarray and ( scalar @_ > 1 or ref $_[0] eq 'ARRAY' ) ) {
        # We have received an array or array reference in a list context
        # so we will return an array.
        map { nc( $_ ) } @{ ref( $_[0] ) ? $_[0] : \@_ };

    } elsif( ref $_[0] eq 'ARRAY' ) {
        # We have received an array reference in a scalar or void context
        # so we will work on the array in-place.
        foreach ( @{ $_[0] } ) {
            $_ = nc( $_ );
        }

    } elsif( ref $_[0] eq 'SCALAR' ) {
        # We don't work on scalar references in-place; we take the value
        # and return a name-cased copy.
        nc( ${ $_[0] } );

    } elsif( scalar @_ == 1 ) {
        # We've received a scalar: we return a name-cased copy.
        nc( $_[0] );

    } else {
        croak "NameCase only accepts a single scalar, array or array ref";
    }
}

=head2 nc

Takes a scalar or scalarref, and change the case of the name in the
corresponding string appropriately.

=cut

sub nc {
    croak "Usage: nc [[\\]\$SCALAR]"
        if scalar @_ > 1 or ( ref $_[0] and ref $_[0] ne 'SCALAR' );

    local( $_ ) = @_ if @_;
    $_ = ${$_} if ref( $_ ) ;           # Replace reference with value.

    return $_   unless($_);

    $_ = lc ;                           # Lowercase the lot.
    s{ \b (\w)   }{\u$1}gx;             # Uppercase first letter of every word.
    s{ (\'\w) \b }{\L$1}gx;             # Lowercase 's.

    # Name case Mcs and Macs - taken straight from NameParse.pm incl. comments.
    # Exclude names with 1-2 letters after prefix like Mack, Macky, Mace
    # Exclude names ending in a,c,i,o, or j are typically Polish or Italian

    if ( /\bMac[A-Za-z]{2,}[^aciozj]\b/ or /\bMc/ ) {
        s/\b(Ma?c)([A-Za-z]+)/$1\u$2/g;

        # Now correct for "Mac" exceptions
        s/\bMacEvicius/Macevicius/g;    # Lithuanian
        s/\bMacHado/Machado/g;          # Portuguese
        s/\bMacHar/Machar/g;
        s/\bMacHin/Machin/g;
        s/\bMacHlin/Machlin/g;
        s/\bMacIas/Macias/g;
        s/\bMacIulis/Maciulis/g;
        s/\bMacKie/Mackie/g;
        s/\bMacKle/Mackle/g;
        s/\bMacKlin/Macklin/g;
        s/\bMacQuarie/Macquarie/g;
        s/\bMacOmber/Macomber/g;
        s/\bMacIn/Macin/g;
        s/\bMacKintosh/Mackintosh/g;
        s/\bMacKen/Macken/g;
        s/\bMacHen/Machen/g;
        s/\bMacisaac/MacIsaac/g;
        s/\bMacHiel/Machiel/g;
        s/\bMacIol/Maciol/g;
        s/\bMacKell/Mackell/g;
        s/\bMacKlem/Macklem/g;
        s/\bMacKrell/Mackrell/g;
        s/\bMacLin/Maclin/g;
        s/\bMacKey/Mackey/g;
        s/\bMacKley/Mackley/g;
        s/\bMacHell/Machell/g;
        s/\bMacHon/Machon/g;
    }
    s/Macmurdo/MacMurdo/g;

    # Fixes for "son (daughter) of" etc. in various languages.
    s{ \b Al(?=\s+\w)  }{al}gx;                     # al Arabic or forename Al.
    s{ \b Ap        \b }{ap}gx;                     # ap Welsh.
    # <http://www.jewfaq.org/jnames.htm> search for: followed by ben
    # without first (?<=\S\s), first name of 'ben jones' remains lowercase
    s{ (?<=\S\s)\bBen(?=\s+\w) }{ben}gx if $HEBREW; # ben Hebrew or forename Ben.
    s{ (?<=\S\s)\bBat(?=\s+\w) }{bat}gx if $HEBREW; # bat Hebrew or forename Bat.
    s{ \b Dell([ae])\b }{dell$1}gx;                 # della and delle Italian.
    s{ \b D([aeiu]) \b }{d$1}gx;                    # da, de, di Italian; du French.
    s{ \b De([lr])  \b }{de$1}gx;                   # del Italian; der Dutch/Flemish.
    s{ \b El        \b }{el}gx  unless $SPANISH;    # el Greek or El Spanish.
    s{ \b La        \b }{la}gx  unless $SPANISH;    # la French or La Spanish.
    s{ \b L([eo])   \b }{l$1}gx;                    # lo Italian; le French.
    s{ \b Van(?=\s+\w) }{van}gx;                    # van German or forename Van.
    s{ \b Von       \b }{von}gx;                    # von Dutch/Flemish

    if($ROMAN) {
        # Fixes for roman numeral names, e.g. Henry VIII, up to 89, LXXXIX
        s{ \b ( (?: [Xx]{1,3} | [Xx][Ll]   | [Ll][Xx]{0,3} )?
                (?: [Ii]{1,3} | [Ii][VvXx] | [Vv][Ii]{0,3} )? ) \b }{\U$1}gx;
    }

    if($POSTNOMINAL) {
        # post-nominal initials
        for my $pni (@POST_NOMINAL_INITIALS) {
            s{ \b ($pni)    $}{$pni}ix;
        }
    }

    $_;
}

=head1 BUGS

The module covers the rules that I know of. There are probably a lot
more rules, exceptions etc. for "Western"-style languages which could be
incorporated.

There are probably lots of exceptions and problems - but as a general
data 'cleaner' it may be all you need.

Use Kim Ryan's L<Lingua::EN::NameParse> for any really sophisticated name parsing.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::EN::NameCase

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Lingua-EN-NameCase>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-NameCase>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Lingua-EN-NameCase>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Lingua-EN-NameCase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-EN-NameCase>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Lingua::EN::NameCase>

=back

=head1 AUTHOR

  1998-2014    Mark Summerfield <summer@qtrac.eu>
  2014-present Barbie <barbie@cpan.org>

  2020- Maintained by Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Kim Ryan <kimaryan@ozemail.com.au> for his Mc/Mac solution.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 1998-2014. All Rights Reserved.
Copyright (c) Barbie 2014-2015. All Rights Reserved.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut

1;

