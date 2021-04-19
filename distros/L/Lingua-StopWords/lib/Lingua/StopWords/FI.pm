package Lingua::StopWords::FI;

use strict;
use warnings;

use utf8;

use Encode qw(encode);

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION     = 0.12;

sub getStopWords {
    if ( @_ and $_[0] eq 'UTF-8' ) {
        my %stoplist = map { ( $_, 1 ) } _stopwords();
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( encode("iso-8859-1", $_), 1 ) } _stopwords();
        return \%stoplist;
    }
}

sub _stopwords {
    return qw(
            olla olen olet on olemme olette ovat ole oli olisi olisit
            olisin olisimme olisitte olisivat olit olin olimme olitte
            olivat ollut olleet en et ei emme ette eivät minä minun minut
            minua minussa minusta minuun minulla minulta minulle sinä sinun
            sinut sinua sinussa sinusta sinuun sinulla sinulta sinulle hän
            hänen hänet häntä hänessä hänestä häneen hänellä häneltä
            hänelle me meidän meidät meitä meissä meistä meihin meillä
            meiltä meille te teidän teidät teitä teissä teistä teihin
            teillä teiltä teille he heidän heidät heitä heissä heistä
            heihin heillä heiltä heille tämä tämän tätä tässä tästä tähän
            tallä tältä tälle tänä täksi tuo tuon tuotä tuossa tuosta
            tuohon tuolla tuolta tuolle tuona tuoksi se sen sitä siinä
            siitä siihen sillä siltä sille sinä siksi nämä näiden näitä
            näissä näistä näihin näillä näiltä näille näinä näiksi nuo
            noiden noita noissa noista noihin noilla noilta noille noina
            noiksi ne niiden niitä niissä niistä niihin niillä niiltä
            niille niinä niiksi kuka kenen kenet ketä kenessä kenestä
            keneen kenellä keneltä kenelle kenenä keneksi ketkä keiden
            ketkä keitä keissä keistä keihin keillä keiltä keille keinä
            keiksi mikä minkä minkä mitä missä mistä mihin millä miltä
            mille minä miksi mitkä joka jonka jota jossa josta johon jolla
            jolta jolle jona joksi jotka joiden joita joissa joista joihin
            joilla joilta joille joina joiksi että ja jos koska kuin mutta
            niin sekä sillä tai vaan vai vaikka kanssa mukaan noin poikki
            yli kun niin nyt itse
    );
}

1;
