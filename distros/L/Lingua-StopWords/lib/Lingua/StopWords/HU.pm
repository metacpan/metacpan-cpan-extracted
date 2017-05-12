package Lingua::StopWords::HU;

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
            a ahogy ahol aki akik akkor alatt Ã¡ltal Ã¡ltalÃ¡ban amely
            amelyek amelyekben amelyeket amelyet amelynek ami amit amolyan
            amÃ­g amikor Ã¡t abban ahhoz annak arra arrÃ³l az azok azon azt
            azzal azÃ©rt aztÃ¡n azutÃ¡n azonban bÃ¡r be belÃ¼l benne cikk
            cikkek cikkeket csak de e eddig egÃ©sz egy egyes egyetlen
            egyÃ©b egyik egyre ekkor el elÃ©g ellen elÃµ elÃµszÃ¶r elÃµtt
            elsÃµ Ã©n Ã©ppen ebben ehhez emilyen ennek erre ez ezt ezek
            ezen ezzel ezÃ©rt Ã©s fel felÃ© hanem hiszen hogy hogyan igen
            Ã­gy illetve ill. ill ilyen ilyenkor ison ismÃ©t itt jÃ³ jÃ³l
            jobban kell kellett keresztÃ¼l keressÃ¼nk ki kÃ­vÃ¼l kÃ¶zÃ¶tt
            kÃ¶zÃ¼l legalÃ¡bb lehet lehetett legyen lenne lenni lesz lett
            maga magÃ¡t majd majd mÃ¡r mÃ¡s mÃ¡sik meg mÃ©g mellett mert
            mely melyek mi mit mÃ­g miÃ©rt milyen mikor minden mindent
            mindenki mindig mint mintha mivel most nagy nagyobb nagyon ne
            nÃ©ha nekem neki nem nÃ©hÃ¡ny nÃ©lkÃ¼l nincs olyan ott Ã¶ssze
            Ãµ Ãµk Ãµket pedig persze rÃ¡ s sajÃ¡t sem semmi sok sokat
            sokkal szÃ¡mÃ¡ra szemben szerint szinte talÃ¡n tehÃ¡t teljes
            tovÃ¡bb tovÃ¡bbÃ¡ tÃ¶bb Ãºgy ugyanis Ãºj Ãºjabb Ãºjra utÃ¡n
            utÃ¡na utolsÃ³ vagy vagyis valaki valami valamint valÃ³ vagyok
            van vannak volt voltam voltak voltunk vissza vele viszont volna 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            a ahogy ahol aki akik akkor alatt által általában amely amelyek
            amelyekben amelyeket amelyet amelynek ami amit amolyan amíg
            amikor át abban ahhoz annak arra arról az azok azon azt azzal
            azért aztán azután azonban bár be belül benne cikk cikkek
            cikkeket csak de e eddig egész egy egyes egyetlen egyéb egyik
            egyre ekkor el elég ellen elõ elõször elõtt elsõ én éppen ebben
            ehhez emilyen ennek erre ez ezt ezek ezen ezzel ezért és fel
            felé hanem hiszen hogy hogyan igen így illetve ill. ill ilyen
            ilyenkor ison ismét itt jó jól jobban kell kellett keresztül
            keressünk ki kívül között közül legalább lehet lehetett legyen
            lenne lenni lesz lett maga magát majd majd már más másik meg
            még mellett mert mely melyek mi mit míg miért milyen mikor
            minden mindent mindenki mindig mint mintha mivel most nagy
            nagyobb nagyon ne néha nekem neki nem néhány nélkül nincs olyan
            ott össze õ õk õket pedig persze rá s saját sem semmi sok sokat
            sokkal számára szemben szerint szinte talán tehát teljes tovább
            továbbá több úgy ugyanis új újabb újra után utána utolsó vagy
            vagyis valaki valami valamint való vagyok van vannak volt
            voltam voltak voltunk vissza vele viszont volna 
        );
        return \%stoplist;
    }
}

1;
