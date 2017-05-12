package Lingua::StopWords::FI;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] ); 
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.08;

sub getStopWords {
    if ( @_ and $_[0] eq 'UTF-8' ) {
        # adding U0 causes the result to be flagged as UTF-8
        my %stoplist = map { ( pack("U0a*", $_), 1 ) } qw( 
            olla olen olet on olemme olette ovat ole oli olisi olisit
            olisin olisimme olisitte olisivat olit olin olimme olitte
            olivat ollut olleet en et ei emme ette eiv√§t min√§ minun minut
            minua minussa minusta minuun minulla minulta minulle sin√§
            sinun sinut sinua sinussa sinusta sinuun sinulla sinulta
            sinulle h√§n h√§nen h√§net h√§nt√§ h√§ness√§ h√§nest√§ h√§neen
            h√§nell√§ h√§nelt√§ h√§nelle me meid√§n meid√§t meit√§ meiss√§
            meist√§ meihin meill√§ meilt√§ meille te teid√§n teid√§t teit√§
            teiss√§ teist√§ teihin teill√§ teilt√§ teille he heid√§n
            heid√§t heit√§ heiss√§ heist√§ heihin heill√§ heilt√§ heille
            t√§m√§ t√§m√§n t√§t√§ t√§ss√§ t√§st√§ t√§h√§n tall√§ t√§lt√§
            t√§lle t√§n√§ t√§ksi tuo tuon tuot√§ tuossa tuosta tuohon
            tuolla tuolta tuolle tuona tuoksi se sen sit√§ siin√§ siit√§
            siihen sill√§ silt√§ sille sin√§ siksi n√§m√§ n√§iden n√§it√§
            n√§iss√§ n√§ist√§ n√§ihin n√§ill√§ n√§ilt√§ n√§ille n√§in√§
            n√§iksi nuo noiden noita noissa noista noihin noilla noilta
            noille noina noiksi ne niiden niit√§ niiss√§ niist√§ niihin
            niill√§ niilt√§ niille niin√§ niiksi kuka kenen kenet ket√§
            keness√§ kenest√§ keneen kenell√§ kenelt√§ kenelle kenen√§
            keneksi ketk√§ keiden ketk√§ keit√§ keiss√§ keist√§ keihin
            keill√§ keilt√§ keille kein√§ keiksi mik√§ mink√§ mink√§ mit√§
            miss√§ mist√§ mihin mill√§ milt√§ mille min√§ miksi mitk√§ joka
            jonka jota jossa josta johon jolla jolta jolle jona joksi jotka
            joiden joita joissa joista joihin joilla joilta joille joina
            joiksi ett√§ ja jos koska kuin mutta niin sek√§ sill√§ tai vaan
            vai vaikka kanssa mukaan noin poikki yli kun niin nyt itse 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            olla olen olet on olemme olette ovat ole oli olisi olisit
            olisin olisimme olisitte olisivat olit olin olimme olitte
            olivat ollut olleet en et ei emme ette eiv‰t min‰ minun minut
            minua minussa minusta minuun minulla minulta minulle sin‰ sinun
            sinut sinua sinussa sinusta sinuun sinulla sinulta sinulle h‰n
            h‰nen h‰net h‰nt‰ h‰ness‰ h‰nest‰ h‰neen h‰nell‰ h‰nelt‰
            h‰nelle me meid‰n meid‰t meit‰ meiss‰ meist‰ meihin meill‰
            meilt‰ meille te teid‰n teid‰t teit‰ teiss‰ teist‰ teihin
            teill‰ teilt‰ teille he heid‰n heid‰t heit‰ heiss‰ heist‰
            heihin heill‰ heilt‰ heille t‰m‰ t‰m‰n t‰t‰ t‰ss‰ t‰st‰ t‰h‰n
            tall‰ t‰lt‰ t‰lle t‰n‰ t‰ksi tuo tuon tuot‰ tuossa tuosta
            tuohon tuolla tuolta tuolle tuona tuoksi se sen sit‰ siin‰
            siit‰ siihen sill‰ silt‰ sille sin‰ siksi n‰m‰ n‰iden n‰it‰
            n‰iss‰ n‰ist‰ n‰ihin n‰ill‰ n‰ilt‰ n‰ille n‰in‰ n‰iksi nuo
            noiden noita noissa noista noihin noilla noilta noille noina
            noiksi ne niiden niit‰ niiss‰ niist‰ niihin niill‰ niilt‰
            niille niin‰ niiksi kuka kenen kenet ket‰ keness‰ kenest‰
            keneen kenell‰ kenelt‰ kenelle kenen‰ keneksi ketk‰ keiden
            ketk‰ keit‰ keiss‰ keist‰ keihin keill‰ keilt‰ keille kein‰
            keiksi mik‰ mink‰ mink‰ mit‰ miss‰ mist‰ mihin mill‰ milt‰
            mille min‰ miksi mitk‰ joka jonka jota jossa josta johon jolla
            jolta jolle jona joksi jotka joiden joita joissa joista joihin
            joilla joilta joille joina joiksi ett‰ ja jos koska kuin mutta
            niin sek‰ sill‰ tai vaan vai vaikka kanssa mukaan noin poikki
            yli kun niin nyt itse 
        );
        return \%stoplist;
    }
}

1;
