package Lingua::StopWords::HU;

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
        my %stoplist = map { ( encode("iso-8859-2", $_), 1 ) } _stopwords();
        return \%stoplist;
    }
}

sub _stopwords {
    return qw(
            a ahogy ahol aki akik akkor alatt által általában amely amelyek
            amelyekben amelyeket amelyet amelynek ami amit amolyan amíg
            amikor át abban ahhoz annak arra arról az azok azon azt azzal
            azért aztán azután azonban bár be belül benne cikk cikkek
            cikkeket csak de e eddig egész egy egyes egyetlen egyéb egyik
            egyre ekkor el elég ellen elő először előtt első én éppen ebben
            ehhez emilyen ennek erre ez ezt ezek ezen ezzel ezért és fel
            felé hanem hiszen hogy hogyan igen így illetve ill. ill ilyen
            ilyenkor ison ismét itt jó jól jobban kell kellett keresztül
            keressünk ki kívül között közül legalább lehet lehetett legyen
            lenne lenni lesz lett maga magát majd majd már más másik meg
            még mellett mert mely melyek mi mit míg miért milyen mikor
            minden mindent mindenki mindig mint mintha mivel most nagy
            nagyobb nagyon ne néha nekem neki nem néhány nélkül nincs olyan
            ott össze ő ők őket pedig persze rá s saját sem semmi sok sokat
            sokkal számára szemben szerint szinte talán tehát teljes tovább
            továbbá több úgy ugyanis új újabb újra után utána utolsó vagy
            vagyis valaki valami valamint való vagyok van vannak volt
            voltam voltak voltunk vissza vele viszont volna
    );
}

1;
