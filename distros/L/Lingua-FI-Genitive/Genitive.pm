package Lingua::FI::Genitive;

use 5.008;
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(genetiivi) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.01';


# haluaa taivuttamattoman sanan
# palauttaa taivutetun sanan
sub genetiivi{
    my($sana)=@_;

    # järjestä ao. lista ensin pituuden mukaan, sitten aakkosjärjestykseen
    # konsonantit
    # viimeinen id=6
    my $k ="bcdfghjklmnpqrstvwxz";
    my $k2="smnl";
    my $k5="k";
    my $k4="lr";
    my $k3="vh";
    my $k6="h";
   
    # järjestä ao. lista ensin pituuden mukaan, sitten aakkosjärjestykseen
    # vokaalit
    # viimeinen id=2
    my $v ="aeiouy";
    my $v2="i";

    local $_=$sana;

    # 1 = regex
    # 2 = käytettävän säännön id; viimeinen id = 68
    # 3 = esimerkkisanan alku
    # 4 = esimerkkisanan loppu         ; isolla kirjaimet, jotka ovat aina juuri nämä
    # 5 = esimerkkisanan lopun käännös ; isolla kirjaimet, jotka ovat aina juuri nämä
    # 6 = ryhmän id, johon regex kuuluu; viimeinen id = 10
    # 7 = ryhmän järjestys; pienin ensin. Laita perään +, jos järjestys jaetaan jonkun muun kanssa
    #
    #  1                                         2       3      4      5      6 7

    # säännöt, jotka toimivat myös nimille
       s/nen                     $ /sen         !22 /x # kisu   NEN   > SEN

    # nimet
    || s/^([A-Z].*)([kpqt])\2([$v])$ /$1$2$3n     !67 /x # Ja   tta    tan    9 0
    || s/^([A-Z].*[$v])            $ /$1n         !61 /x # Vil  e      eN     9 1
    || s/^([A-Z].*)                $ /$1in        !62 /x # Ki   m      mIN    9 2

    # pronominit

    #|| s/^minä                   $ /minun       !63 /x # pronomini
    #|| s/^sinä                   $ /sinun       !63 /x # pronomini
    #|| s/^hän                    $ /hänen       !63 /x # pronomini
    #|| s/^me                     $ /meidän      !63 /x # pronomini
    #|| s/^te                     $ /teidän      !63 /x # pronomini
    #|| s/^he                     $ /heidän      !63 /x # pronomini
    #|| s/^nämä                   $ /näiden      !63 /x # pronomini
    || s/^tuo                    $ /tuon        !63 /x # pronomini
    || s/^se                     $ /sen         !63 /x # pronomini
    || s/^nuo                    $ /noiden      !63 /x # pronomini
    || s/^ne                     $ /niiden      !63 /x # pronomini

    # yksittäiset sanat, joita ei voi laittaa yhdyssanaan

    || s/^aika                   $ /ajan        !64 /x # vrt. taika   -> taian

    # yksittäiset sanat, mahdolliset myös yhdyssanoissa

    || s/poika                   $ /pojan       !65 /x # reliikki
    || s/mies                    $ /miehen      !65 /x # vrt. hies    -> hieksen
    || s/yhteys                  $ /yhteyden    !65 /x # vrt. risteys -> risteyksen
    || s/haku                    $ /haun        !65 /x # vrt. laku    -> lakun
    || s/laki                    $ /lain        !65 /x # vrt. khaki   -> khakin
    || s/tuoli                   $ /tuolin      !65 /x # vrt. huoli   -> huolen
    || s/henki                   $ /hengen      !65 /x # vrt. renki   -> rengin
    || s/puomi                   $ /puomin      !65 /x # vrt. luomi   -> luomen
    || s/[th]uuli                $ /tuulen      !65 /x # vrt. muuli   -> muulin

    # kummallisuudet

    || s/ruis                    $ /rukiin      !66 /x
    || s/ananas                  $ /ananaksen   !66 /x
    || s/business                $ /busineksen  !66 /x

    # numeraalit

    || s/yksi                    $ /yhden       !1  /x
    || s/kaksi                   $ /kahden      !1  /x
    || s/kolme                   $ /kolmen      !1  /x
    || s/^viisi                  $ /viiden      !1  /x # numero - kuitenkin aviisi -> aviisin
    || s/kuusi                   $ /kuuden      !1  /x
    || s/kolmas                  $ /kolmannen   !1  /x

    # lainasanat, jotka päättyvät vokaaliin

    || s/(
           andante
          |delta
          |data
          |desi
          |curry
          |copy
          |collie
          |college
          |chippendale
          |city
          |bluffi
          |beige
          |bridge
          |boutique
          |cache
          |case
          |freestyle 
          |foto 
          |fleece 
          |empire 
          |epo 
          |esperanto
          |extreme 
          |fluori 
          |expo
          |folklore 
          |ellipsi 
          |ensemble 
          |forte
          )                       $ /$1n        !59 /x

    # lainasanat, jotka päättyvät konsonanttiin

    || s/(
           charleston
          |evergreen
          )                       $ /$1in       !60 /x


    # varmat säännöt, joissa etsimisosan säännöt ovat ilman muuttujia (esim. $1)
    || s/^([vm])(er)i            $ /$1$2en      !33 /x #        vERI  > verEN
    || s/(n)si                   $ /$1$1en      !38 /x # ka     NSI   > nnEN
    || s/(m)pi                   $ /$1$1en      !11 /x # la     MPI   > mmEN
    || s/(iel)i                  $ /$1en        !19 /x # k      IELI  > elEN
    || s/([yu]psi)               $ /$1n         !55 /x # r      yPSI  > ypsiN   8 1
    || s/(p)(s)i                 $ /$1$2en      !32 /x # la     PSI   > psEN    8 2
    || s/das                     $ /taan        !24 /x # hi     DAS   > TAAN
    || s/([st])([ou]u)s          $ /$1$2den     !44 /x # out    oUS   > ouDEN
    || s/([$v])\1                $ /$1$1n       !58 /x # atelj  ee    > eeN

    # sekalaiset säännöt
    || s/(m)\1(a)s               $ /$1p$2$2n    !41 /x # ha     MmAS  > hamPaaN 3 -2
    || s/(n)\1(a)s               $ /$1$1$2ksen  !42 /x # ka     NnAS  > nnaKSEN 3 0
    || s/([$k ])\1(a)s           $ /$1t$2$2n    !36 /x # ma     llAS  > malTaaN 3 -1
    || s/([$k ])d(a)s            $ /$1t$2$2n    !40 /x # a      hDAS  > ahTaaN  3 -0.5
    || s/(n)\1e                  $ /$1teen      !12 /x # la     NnE   > nTEEN   3 1+
    || s/(m)\1e                  $ /$1$1een     !13 /x # a      MmE   > mmEEN   3 1+
    || s/([$k2])\1([$v ])        $ /$1$1$2n     !29 /x # ki     ssa   > ssaN    3 2
    || s/([$k ])\1([$v ])        $ /$1$2n       ! 2 /x # ta     tti   > tiN   
    || s/(r)si                   $ /$1$1en      !43 /x # vi     RSI   > rrEN
    || s/([$k ])([$k3])$v2       $ /$1$2en      ! 3 /x # hi     rvi   > rvEN
    || s/([$v ])\1s              $ /$1$1den     ! 4 /x # tilais uus   > uuDEN   1 1
    || s/([$v ])([$v ])s         $ /$1$2ksen    ! 5 /x # lauk   auS   > auKSEN  1 2
    || s/([$v ])([$v ])ka        $ /$1$2an      ! 9 /x # s      iiKA  > iiAN
    || s/([$v ])p([$v ])         $ /$1v$2n      !16 /x # n      aPa   > aVaN
    || s/([$v ])([$k ])(a)s      $ /$1$2$2$3$3n !25 /x # hi     DAS   > TAAN    4 0
    || s/([$k ])([$k ])(a)s      $ /$1$2$3$3n   !37 /x # ka     rvAS  > karvaaN 3 0
    || s/([$v ])s                $ /$1ksen      !23 /x # tik    aS    > aKSEN   4 1
    || s/(tt)([$v])n             $ /$1$2in      !28 /x #                        4 3 
    || s/(t)(i)n                 $ /$1$1$2men   !45 /x # lii    TIN   > ttiMEN  4 4+ 
    || s/(t)(o)n                 $ /$1$1$2man   !26 /x # ehdo   TON   > ttoMAN  4 4+ 
    || s/(l)(i)n                 $ /$1$2men     !30 /x # puhe   LIN   > liMEN   4 4+ 
    || s/(e)(n)                  $ /$1$2en      !49 /x # ahv    EN    > enEN    4 5
    || s/([$v ])([$k ])          $ /$1$2in      !17 /x # kerm   it    > itIN    4 6
    || s/([$v ])(\1si)           $ /$1$2n       !52 /x # m      uuSI  > uusiN   6 1
    || s/([$v ])si               $ /$1den       ! 6 /x # ka     uSI   > uDEN    6 2
    || s/([$v ])(t)(e)           $ /$1$2$2$3$3n !20 /x # ka     TE    > tteeN   2 -2
    || s/d(e)                    $ /t$1$1n      !21 /x # kai    DE    > TeeN    2 -1
    || s/(sk)(e)                 $ /$1$2$2n     !50 /x # rui    SKE   > skeeN   2 -0.5
    || s/(k)(e)                  $ /$1$1$2$2n   !46 /x # pil    KE    > kkeeN   2 -0.5
    || s/(e)                     $ /$1$1n       !18 /x # ven    E     > eeN     2 0
    || s/(te[$k6])ti             $ /$1din       !56 /x # arkki  TEhTI > tehDIN  2 1.1
    || s/(e[$k6])ti              $ /$1den       !57 /x # le     hTI   > hDEN    2 1.2
    || s/([$k6])t([$v ])         $ /$1d$2n      !27 /x # jo     hTo   > hDoN    2 1
    || s/([$v ])t([$v ])         $ /$1d$2n      !10 /x # ha     uTa   > uDaN    2 2
    || s/([$k ])(i)(v)i          $ /$1$2$3en    !14 /x # k      ivI   > ivEN    2 3
    || s/([$k ])(o)([$k ])i      $ /$1$2$3in    !51 /x # aero   sOlI  > olIN    5 1
    || s/(oni)                   $ /$1n         !54 /x # p      ONI   > oniN    5 3
    || s/(o)([$k ])i             $ /$1$2en      !31 /x # hu     OlI   > olEN    5 4
    || s/([$k4])ta               $ /$1$1an      ! 7 /x # si     lTA   > llAN
    || s/(n)k([$v ])             $ /$1g$2n      !28 /x # la     NKo   > ngoN
    || s/(n)t([$v ])             $ /$1$1$2n     !15 /x # ka     NTo   > nnoN
    || s/(au)ki                  $ /$1en        !47 /x # h      AUKI  > auEN
    || s/(oim|ie[$k])i           $ /$1en        !48 /x # t      OIMI  > oimEN

    # perussäännöt
    || s/([$v ])                 $/$1n          ! 8 /x # kirj   a    > aN       7 1
    || s/(.)                     $/$1in         !53 /x # aid    S    > sIN       7 2
    ;

    m/^([^ ]*) *!(.*)/;
    return $1,$2;
}

1;

__END__

=head1 NAME

Lingua::FI::Genitive - Finnish genitive

=head1 NIMI

Lingua::FI::Genitive - suomen genetiivi

=head1 SYNOPSIS

use Lingua::FI::Genitive qw(genetiivi);

my ($genetiivi,$rule_id) = genetiivi("koti");

print "$genetiivi\n"; # will print "kodin\n";

=head1 KÄYTTÖ

use Lingua::FI::Genitive qw(genetiivi);

my ($genetiivi,$rule_id) = genetiivi("koti");

print "$genetiivi\n"; # tulostaa ruudulle "kodin\n";

=head1 DESCRIPTION

genetiivi() returns the genitive of an inputted word.

Supposes that given word is a name if the first letter is capilalized.

=head1 KUVAUS

genetiivi() palauttaa annetun sanan genetiivin.

Olettaa, että sana on nimi, mikäli ensimmäinen kirjain on iso.

=head1 BUGS

Characters å, ä, ja ö are not working at all.

Doesn't know all odd words.

Works only for non-inflected words.

What comes to names, works well only with Christian names.

=head1 VIRHEET

Merkit å, ä ja ö eivät toimi.

Ei tunne kaikkia erikoisesti taipuvia sanoja.

Toimii vain perusmuodossa oleville sanoille.

Nimistä kääntää hyvin vain etunimet.

=head1 AUTHOR

Ville Jungman

<ville_jungman@hotmail.com, ville.jungman@frakkipalvelunam.fi>

=head1 COPYRIGHT

Copyright 2003 Ville Jungman

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


Ville Jungman

<ville_jungman@hotmail.com, ville.jungman@frakkipalvelunam.fi>

=head1 TEKIJANOIKEUS

Ville Jungman 

<ville_jungman@hotmail.com, ville.jungman@frakkipalvelunam.fi>

=head1 LISENSSI

Tämä kirjastomoduli on vapaa; voit jakaa ja/tai muuttaa sitä samojen
ehtojen mukaisesti kuin Perliä itseään.

=cut
