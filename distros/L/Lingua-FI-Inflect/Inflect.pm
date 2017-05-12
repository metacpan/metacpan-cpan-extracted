package Lingua::FI::Inflect;

use 5.008;
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(taivuta to_number %sijamuodot) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.02';

our %sijamuodot=(
   monikko     => 0,
   genetiivi   => 1,
   inessiivi   => 2,
   elatiivi    => 3,
   adessiivi   => 4,
   ablatiivi   => 5,
   partitiivi  => 6,
   essiivi     => 7,
   illatiivi   => 8,
   translatiivi=> 9,
);

# haluaa taivuttamattoman sanan
# palauttaa taivutetun sanan
sub taivuta{
    my($sijamuoto_id,$sana)=@_;

    # järjestä ao. lista ensin pituuden mukaan, sitten aakkosjärjestykseen
    # konsonantit
    # viimeinen id=6

    my $k ="bcdfghjklmnpqrstvwxz";
    my $k2="smnl";
    my $k5="k";
    my $k4="lr";
    my $k3="vh";
    my $k6="h";
    my $k7="kptq";
   
    # järjestä ao. lista ensin pituuden mukaan, sitten aakkosjärjestykseen
    # vokaalit
    # viimeinen id=2

    my $v ="aeiouy:;";
    my $v2="i";


    # muuta ä-kirjaimet kaksoispisteiksi ja ö-kirjaimet puolipisteiksi
    # hae käytetäänkö sanassa skandeja vai ei
    # $a == a tai ä
    # $o == o tai ö

    (local $_,my $a,my $o)=to_number($sana);


    # määritä sijamuodon sijapääte $p-muuttujaan
    # määritä $p1-muuttujaan sijapääte ilman skandeja
    # määritä $p2-muuttujaan sijapääte skandeilla varustettuna

    my($p)=(
         $sijamuoto_id == 0 ? "t"      # monikko
       : $sijamuoto_id == 1 ? "n"      # genetiivi
       : $sijamuoto_id == 2 ? "ss$a"   # inessiivi
       : $sijamuoto_id == 3 ? "st$a"   # elatiivi
       : $sijamuoto_id == 4 ? "ll$a"   # adessiivi
       : $sijamuoto_id == 5 ? "lt$a"   # ablatiivi
       : $sijamuoto_id == 6 ? "$a"     # partitiivi
       : $sijamuoto_id == 7 ? "n$a"    # essiivi
       : $sijamuoto_id == 8 ? "$a"."n" # illatiivi
       : $sijamuoto_id == 9 ? "ksi"    # translatiivi
    : die "Wrong case");
    (my $p1=$p) =~ tr/y:;/uao/;
    (my $p2=$p) =~ tr/aou/:;y/;


    # 1 = regex
    # 2 = käytettävän säännön id; viimeinen id = 111
    # 3 = esimerkkisanan alku
    # 4 = esimerkkisanan loppu         ; isolla kirjaimet, jotka ovat aina juuri nämä
    # 5 = esimerkkisanan lopun käännös ; isolla kirjaimet, jotka ovat aina juuri nämä
    # 6 = ryhmän id, johon regex kuuluu; viimeinen id = 10
    # 7 = ryhmän järjestys; pienin ensin. Laita perään +, jos järjestys jaetaan jonkun muun kanssa
    #
    #  1                                         2       3      4      5      6 7

       # illatiivi (kotiin)
       $sijamuoto_id == 8 && (
             s/(.*[$v])([$v])             $ /$1$2h$2n    !77 /x

          # poikkeukset
          || s/^([th])(uu?l)i             $ /$1$2een     !92 /x
          || s/^kivi                      $ /kiveen      !93 /x #

          # monikko
          || s/(.*)([$v])(\2)t            $ /$1$2isiin   !94 /x # lampaat lampaisiin
          || s/(.*)([$k])([a:])t          $ /$1$2$o\0ihin!95 /x # perunat perunoihin

          || s/(.*)(s)                    $ /$1kseen     !96 /x # sirkus kseen
          || s/(.*)(e)                    $ /$1$2$2seen  !78 /x # hame   hameeseen
          || s/(.*)(nk)(i)                $ /$1$2een     !79 /x # henki  henkeen
          || s/(.*)([$v])                 $ /$1$2$2n     !80 /x # kissa  kissaan
          || s/(.*)([$k]+)                $ /$1$2iin     !81 /x # kiss   kissiin
       ) 

       # partitiivi
       || $sijamuoto_id == 6 && (
             s/(.*[$v])([$v])             $ /$1$2t$a     !82 /x

          # poikkeukset
          || s/^([th])(uu?l)i             $ /$1$2ta      !108/x #
          || s/^kivi                      $ /kive$a      !98 /x #

          # monikko
          || s/(.*)([$v])(\2)t            $ /$1$2it$a    !99 /x # lampaat lampaita
          || s/(.*)([$v])([$k])([a:])t    $ /$1$2$3$o\0it$a!100/x # perunat perunoita
          || s/(.*)([$k])([a:])t          $ /$1$2$o\0j$a !   /x # aika    aikoja
          || s/(.*)([$k])([$v])t          $ /$1$2$3j$a   !   /x # jauhot  jauhoja

          || s/(.*)(s)                    $ /$1$2ta      !109/x # sirkus ta
          || s/(.*)(e)                    $ /$1$2tt$a    !83 /x # hame   hametta
          || s/(.*)(nk)(i)                $ /$1$2e$a     !84 /x # henki  henkeä
          || s/(.*)([$v])                 $ /$1$2$a      !85 /x # kissa  kissaa
          || s/(.*)([$k]+)                $ /$1$2i$a     !86 /x # kiss   kissiä
       ) 

       # essiivi
       || $sijamuoto_id == 7 && (
             s/(.*[$v])([$v])             $ /$1$2n$a     !87 /x

          # poikkeukset
          || s/^([th])(uu?l)i             $ /$1$2ena     !110/x
          || s/^kivi                      $ /kiven$a     !102/x #

          # monikko
          || s/(.*)([$v])(\2)t            $ /$1$2in$a    !103/x # lampaat lampaina
          || s/(.*)([$k])([a:])t          $ /$1$2$o\0in$a!104/x # perunat perunoina

          || s/(.*)(s)                    $ /$1ksena     !111/x # sirkus ksena
          || s/(.*)(e)                    $ /$1$2$2n$a   !88 /x # hame   hameena
          || s/(.*)(nk)i                  $ /$1$2en$a    !89 /x # henki  henkenä
          || s/(.*)([$v])                 $ /$1$2n$a     !90 /x # kissa  kissana
          || s/(.*)([$k]+)                $ /$1$2in$a    !91 /x # kiss   kissinä
       ) 

       # lainasanat, jotka päättyvät vokaaliin
       || s/(
          andante
          |anime
          |apache
          |appassionato
          |beta
          |beeta
          |blanko
          |byte
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
          |deadline
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
          )                       $ /$1$p       !59 /x

    # lainasanat, jotka päättyvät konsonanttiin

    || s/(
           blues
          |charleston
          |evergreen
          |automarket
          |bouquet
          |bullshit
          |burnout
          |chat
          |debet
          |et
          |exit
          |fahrenheit
          |kermit
          )                       $ /$1i$p      !60 /x

    # monikko
    || /t$/ && (
         s/([a:])t                    $ /$o\0i$p     !105/x # kal   AT     oi   10 2
      || s/([$v])t                    $ /$1$p        !106/x # pul   u      u    
      || s/(.)                        $ /$1i$p       !107/x # marke T      tIT    
    ) 

    # numerot 8-10

    || s/(
          seitsem:
         |ykdeks:
         |kahdeksa
         |kymmene
         )n                         $ /$1$p        !73 /x #                  10 1

    # säännöt, jotka toimivat myös nimille

    || s/nen                        $ /se$p        !22 /x # kisu NEN    SEN  10 2

    # nimet
    || s/^([A-Z45].*)([$k7])\2([$v])$ /$1$2$3$p    !67 /x # Ja   tta    ta    9 0
    || s/^([A-Z45].*[$v])           $ /$1$p        !61 /x # Vil  e      e     9 1
    || s/^([A-Z45].*)               $ /$1i$p       !62 /x # Ki   m      mI    9 2

    # pronominit

    || $sijamuoto_id == 0 && (
          s/^min:                   $ /me          !63 /x
       || s/^sin:                   $ /te          !63 /x
       || s/^h:n                    $ /he          !63 /x
       || s/^t:m:                   $ /n:m:        !63 /x
       || s/^tuo                    $ /nuo         !63 /x
       || s/^se                     $ /ne          !63 /x
    )

    || (
          s/^min:                   $ /minu$p1     !63 /x
       || s/^sin:                   $ /sinu$p1     !63 /x
       || s/^h:n                    $ /h:ne$p2     !63 /x
       || s/^me                     $ /meid:$p2    !63 /x
       || s/^te                     $ /teid:$p2    !63 /x
       || s/^he                     $ /heid:$p2    !63 /x
       || s/^n:m:                   $ /n:ide$p2    !63 /x
       || s/^nuo                    $ /noide$p1    !63 /x
       || s/^ne                     $ /niide$p2    !63 /x
       || s/^t:m:                   $ /t:m:$p2     !63 /x
       || s/^tuo                    $ /tuo$p1      !63 /x
       || s/^se                     $ /se$p2       !63 /x
    )

    # yksittäiset sanat, joita ei voi laittaa yhdyssanaan

    || s/^aika                   $ /aja$p       !64 /x # vrt. taika   -> taia
    || s/^([th])(uu?l)i          $ /$1$2e$p     !64 /x # vrt. kuli    -> kulin

    # yksittäiset sanat, mahdolliset myös yhdyssanoissa

    || s/poika                   $ /poja$p      !66 /x # reliikki
    || s/mies                    $ /miehe$p     !66 /x # vrt. hies    -> hiekse
    || s/yhteys                  $ /yhteyde$p   !66 /x # vrt. risteys -> risteykse
    || s/haku                    $ /hau$p       !66 /x # vrt. laku    -> laku
    || s/laki                    $ /lai$p       !66 /x # vrt. khaki   -> khaki
    || s/tuoli                   $ /tuoli$p     !66 /x # vrt. huoli   -> huole
    || s/henki                   $ /henge$p     !66 /x # vrt. renki   -> rengi
    || s/puomi                   $ /puomi$p     !66 /x # vrt. luomi   -> luome
    || s/(th])uli                $ /$1uule$p    !66 /x # vrt. muuli   -> muuli
    || s/nauris                  $ /naurii$p    !66 /x
    || s/veli                    $ /velje$p     !66 /x # vrt. peli    -> peli
    || s/ruis                    $ /rukii$p     !66 /x
    || s/ananas                  $ /ananakse$p  !66 /x
    || s/business                $ /businekse$p !66 /x
    || s/kirves                  $ /kirvee$p    !66 /x

    # numerot 1-6

    || s/(y|ka)ksi               $ /$1hde$p     !1  /x
    || s/(kolme|nelj:)           $ /$1$p        !1  /x
    || s/^(vii)si                $ /$1de$p      !1  /x # numero - kuitenkin aviisi -> aviisi
    || s/(kuu)si                 $ /$1de$p      !1  /x

    # numerot 11-19

    || s/(.+)(toista)            $ /(taivuta($sijamuoto_id,$1))[0].$2.'!74' /ex

    # järjestysluvut 1-10

    || s/(
          yhde
         |kahde
         |kolma
         |nelj:
         |viide
         |kuude
         |seitsem:
         |kahdeksa
         |yhdeks:
         |kymmene
         )s                      $ /$1nne$p     !75 /x



    # varmat säännöt, joissa etsimisosan säännöt ovat ilman muuttujia (esim. $1)
    || s/^([vm])(er)i            $ /$1$2e$p     !33 /x #        vERI  > verE 
    || s/(n)si                   $ /$1$1e$p     !38 /x # ka     NSI   > nnE 
    || s/(m)pi                   $ /$1$1e$p     !11 /x # la     MPI   > mmE 
    || s/(iel)i                  $ /$1e$p       !19 /x # k      IELI  > elE 
    || s/([yu]psi)               $ /$1$p        !55 /x # r      yPSI  > ypsi    8 1
    || s/(p)(s)i                 $ /$1$2e$p     !32 /x # la     PSI   > psE     8 2
    || s/d([a:])s                $ /t$1$1$p     !24 /x # hi     DAS   > TAA 
    || s/([st])(([ou]u)|([;y]y))s$ /$1$2de$p    !44 /x # out    oUS   > ouDE 
    || s/([$v])\1                $ /$1$1$p      !58 /x # atelj  ee    > ee 

    # sekalaiset säännöt

    || s/(m)\1([a:])s            $ /$1p$2$2$p   !41 /x # ha     MmAS  > hamPaa  3 -2
    || s/(n)\1([a:])s            $ /$1$1$2kse$p !42 /x # ka     NnAS  > nnaKSE  3 0
    || s/([$k])\1([a:])s         $ /$1t$2$2$p   !36 /x # ma     llAS  > malTaa  3 -1
    || s/([$k])d([a:])s          $ /$1t$2$2$p   !40 /x # a      hDAS  > ahTaa   3 -0.5
    || s/(n)\1e                  $ /$1tee$p     !12 /x # la     NnE   > nTEE    3 1+
    || s/(m)\1e                  $ /$1$1ee$p    !13 /x # a      MmE   > mmEE    3 1+
    || s/([$k2])\1([$v])         $ /$1$1$2$p    !29 /x # ki     ssa   > ssa     3 2
    || s/([$k7])\1([$v])         $ /$1$2$p      !02 /x # ta     tti   > ti    
    || s/(r)si                   $ /$1$1e$p     !43 /x # vi     RSI   > rrE 
    || s/(sv|rm|sm)(i)           $ /$1$2$p      !68 /x # ka     RmI   > rmI 
    || s/([$k])([$k3])$v2        $ /$1$2e$p     ! 3 /x # hi     rvi   > rvE 
    || s/([$v])\1s               $ /$1$1de$p    ! 4 /x # tilais uus   > uuDE    1 1
    || s/([$v])([$v])s           $ /$1$2kse$p   ! 5 /x # lauk   auS   > auKSE   1 2
    || s/([$v])([$v])k([a:])     $ /$1$2$3$p    ! 9 /x # s      iiKA  > iiA 
    || s/([$v])p([$v])           $ /$1v$2$p     !16 /x # n      aPa   > aVa 
    || s/([$v])([$k])([a:])s     $ /$1$2$2$3$3$p!25 /x # hi     DAS   > TAA     4 0
    || s/([$k])([$k])([a:])s     $ /$1$2$3$3$p  !37 /x # ka     rvAS  > karvaa  3 0
    || s/([$v])s                 $ /$1kse$p     !23 /x # tik    aS    > aKSE    4 1
    || s/(tt)([$v])n             $ /$1$2i$p     !28 /x #                        4 3 
    || s/(t)(i)n                 $ /$1$1$2me$p  !45 /x # lii    TIN   > ttiME   4 4+ 
    || s/(t)([o;])n              $ /$1$1$2m$a$p !26 /x # ehdo   TON   > ttoMA   4 4+ 
    || s/(l)(i)n                 $ /$1$2me$p    !30 /x # puhe   LIN   > liME    4 4+ 
    || s/(e)(n)                  $ /$1$2e$p     !49 /x # ahv    EN    > enE     4 5
    || s/([$v])([$k])            $ /$1$2i$p     !17 /x # kerm   it    > itI     4 6
    || s/([$v])(\1si)            $ /$1$2$p      !52 /x # m      uuSI  > uusi    6 1
    || s/([$v])si                $ /$1de$p      ! 6 /x # ka     uSI   > uDE     6 2
    || s/([$v])(t)(e)            $ /$1$2$2$3$3$p!20 /x # ka     TE    > ttee    2 -2
    || s/d(e)                    $ /t$1$1$p     !21 /x # kai    DE    > Tee     2 -1
    || s/(sk)(e)                 $ /$1$2$2$p    !50 /x # rui    SKE   > skee    2 -0.5
    || s/(k)(e)                  $ /$1$1$2$2$p  !46 /x # pil    KE    > kkee    2 -0.5
    || s/(e)                     $ /$1$1$p      !18 /x # ven    E     > ee      2 0
    || s/(te[$k6])ti             $ /$1di$p      !56 /x # arkki  TEhTI > tehDI   2 1.1
    || s/(e[$k6])ti              $ /$1de$p      !57 /x # le     hTI   > hDE     2 1.2
    || s/([$k6])t([$v])          $ /$1d$2$p     !27 /x # jo     hTo   > hDo     2 1
    || s/([$v])t([$v])           $ /$1d$2$p     !10 /x # ha     uTa   > uDa     2 2
    || s/([$k])(i)(v)i           $ /$1$2$3e$p   !14 /x # k      ivI   > ivE     2 3
    || s/([$k])([o;])([$k])i     $ /$1$2$3i$p   !51 /x # aero   sOlI  > olI     5 1
    || s/([o;]ni)                $ /$1$p        !54 /x # p      ONI   > oni     5 3
    || s/([o;])\1([$k])i         $ /$1$1$2i$p   !69 /x # b      OolI  > ooli    5 4
    || s/([o;])([$k])i           $ /$1$2e$p     !31 /x # hu     OlI   > olE     5 5
    || s/([$k4])t([a:])          $ /$1$1$2$p    ! 7 /x # si     lTA   > llA 
    || s/(n)k([$v])              $ /$1g$2$p     !28 /x # la     NKo   > ngo 
    || s/(n)t([$v])              $ /$1$1$2$p    !15 /x # ka     NTo   > nno 
    || s/((au)|(:y))ki           $ /$1e$p       !47 /x # h      AUKI  > auE 
    || s/([o;]im|ie[$k])i        $ /$1e$p       !48 /x # t      OIMI  > oimE
    || s/(l)t([$v])              $ /$1$1$2$p    !70 /x # pe     LTi   > lli
    || s/(l)k([i])               $ /$1je$p      !72 /x # ky     LKI   > lJE
    || s/(l)k([a:])              $ /$1$2$p      !71 /x # su     LKa   > a

    # perussäännöt
    || s/([$v])                  $/$1$p         ! 8 /x # kirj   a    > a        7 1
    || s/(.*)                    $/$1i$p        !53 /x # aid    S    > sI       7 2
    ;

    tr/:;/\ä\ö/;

    m/^(.*?) *!(.*)/;
    return $1,$2;
}

# change scandinavic letters 'ä' to ':' and 'ö' to ';' in the given word
# return changed word,a-skand,o-scand
# a-skand == 'a' if scands are not used and ':' if they are
# o-skand == 'o' if scands are not used and ';' if they are
sub to_number{
   my($temp)=@_;
   my($muisti,$apu,$scand)=undef;
   $scand=1;
   foreach my $kirjain(split //,$temp){
      my $ascii=ord($kirjain);     
      if($ascii == 195){
         $muisti=1;
      }else{
         if($ascii == 164 && $muisti){
            $kirjain=":";
         }elsif($ascii == 182 && $muisti){
            $kirjain=";";
         }
         $muisti=0;
         $apu.=$kirjain;
      }
      $scand=1 if $kirjain =~ /[y:;]/;
      $scand=0 if $kirjain =~ /[aou]/;
   }
   return $apu,$scand ? ":" : "a",$scand ? ";" : "o";
}

1;

__END__

=head1 NAME

Lingua::FI::Inflect - Finnish inflect

=head1 NIMI

Lingua::FI::Inflect - suomen taivutus

=head1 SYNOPSIS

    use Lingua::FI::Inflect qw(taivuta to_number %sijamuodot);

    my($inflected)=taivuta($sijamuodot{genetiivi},"kissa");   # inflects word "kissa" to its genitive

    print $inflected; # prints "kissan"

or

    use Lingua::FI::Inflect qw(taivuta to_number %sijamuodot);

    foreach my $sijamuoto(sort keys %sijamuodot){ # käy läpi kaikki sijamuodot

        my($taivutettu,$rule_id)=taivuta($sijamuodot{$sijamuoto},"kissa");   # taivuttaa sanan ko. sijamuotoon

        print "$sijamuoto: $taivutettu (sääntö == $rule_id)\n";

    }

=head1 KÄYTTÖ

    use Lingua::FI::Inflect qw(taivuta to_number %sijamuodot);

    my($taivutettu)=taivuta($sijamuodot{genetiivi},"kissa");   # taivuttaa sanan "kissa" genetiiviin

    print $taivutettu; # tulostaa ruutuun "kissan"

tai

    use Lingua::FI::Inflect qw(taivuta to_number %sijamuodot);

    foreach my $sijamuoto(sort keys %sijamuodot){ # käy läpi kaikki sijamuodot

        my($taivutettu,$rule_id)=taivuta($sijamuodot{$sijamuoto},"kissa");   # taivuttaa sanan ko. sijamuotoon

        print "$sijamuoto: $taivutettu (sääntö == $rule_id)\n";

    }

=head1 DESCRIPTION

taivuta() returns an inputted word inflected to the chosen case.

Supposes that given word is a name if the first letter is capilalized.

=head1 KUVAUS

taivuta() palauttaa annetun sanan taivutettuna haluttuun sijamuotoon.

Olettaa, että sana on nimi, mikäli ensimmäinen kirjain on iso.

=head1 KNOWN CASES AND HOW WELL THEY ARE BEING INFLECTED

CASE          SINGULAR      PLURAL

genetiivi     very good     poor

inessiivi     good          poor

elatiivi      good          poor

adessiivi     good          poor

ablatiivi     good          poor

partitiivi    good          poor

essiivi       good          poor

illatiivi     good          poor

translatiivi  good          poor

plural        good          -

Plural is being considered as one of the cases. For example if You want to inflect word "kissa" - that is cat - to plural translative, first inflect "kissa" to plural ("kissat") and then inflect "kissat" to translative ("kissoiksi").

=head1 TUETUT SIJAMUODOT JA NIIDEN TOIMIVUUS

SIJAMUOTO     YKSIKKÖ       MONIKKO

genetiivi     erittäin hyvä huono

inessiivi     hyvä          huono

elatiivi      hyvä          huono

adessiivi     hyvä          huono

ablatiivi     hyvä          huono

partitiivi    hyvä          huono

essiivi       hyvä          huono

illatiivi     hyvä          huono

translatiivi  hyvä          huono

monikko       hyvä          -

Monikko tulkitaan ykdeksi sijamuodoista. Jos haluat esim taivuttaa yksikössä olevan sanan "kissa" monikon translatiiviin, taivuta "kissa" ensin monikkoon ("kissat") ja taivuta se sitten translatiiviin ("kissoiksi").

=head1 KNOWN BUGS

Doesn't know all odd words.

Works only the inputted word is non-inflected (plural is also ok).

What comes to names, works well only with Christian names.

Works good only with numbers smaller than twenty.

=head1 BUGIT

Ei tunne kaikkia erikoisesti taipuvia sanoja.

Toimii vain yksikön tai monikon perusmuodossa oleville sanoille.

Nimistä taivuttaa hyvin vain etunimet

Taivuttaa hyvin vain kahtakymmentä pienemmät luvut.

=head1 AUTHOR

Ville Jungman

<ville_jungman@hotmail.com, ville.jungman@frakkipalvelunam.fi>

If You just use this module or have some comments I would be glad to hear them.

=head1 OHJELMAN TEKIJÄ

Ville Jungman

<ville_jungman@hotmail.com, ville.jungman@frakkipalvelunam.fi>

Jos käytät tätä moduulia tai jos on jotain parannusehdotuksia, niin olis tosi hauskaa saada palautetta.

=head1 COPYRIGHT / TEKIJÄNOIKEUS

Copyright 2004 Ville Jungman

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 LISENSSI

Tämä kirjastomoduli on vapaa; voit jakaa ja/tai muuttaa sitä samojen
ehtojen mukaisesti kuin Perliä itseään.

=cut
