package Lingua::StopWords::IT;

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
            ad al allo ai agli all agl alla alle con col coi da dal dallo
            dai dagli dall dagl dalla dalle di del dello dei degli dell
            degl della delle in nel nello nei negli nell negl nella nelle
            su sul sullo sui sugli sull sugl sulla sulle per tra contro io
            tu lui lei noi voi loro mio mia miei mie tuo tua tuoi tue suo
            sua suoi sue nostro nostra nostri nostre vostro vostra vostri
            vostre mi ti ci vi lo la li le gli ne il un uno una ma ed se
            perché anche come dov dove che chi cui non più quale quanto
            quanti quanta quante quello quelli quella quelle questo questi
            questa queste si tutto tutti a c e i l o ho hai ha abbiamo
            avete hanno abbia abbiate abbiano avrò avrai avrà avremo avrete
            avranno avrei avresti avrebbe avremmo avreste avrebbero avevo
            avevi aveva avevamo avevate avevano ebbi avesti ebbe avemmo
            aveste ebbero avessi avesse avessimo avessero avendo avuto
            avuta avuti avute sono sei è siamo siete sia siate siano sarò
            sarai sarà saremo sarete saranno sarei saresti sarebbe saremmo
            sareste sarebbero ero eri era eravamo eravate erano fui fosti
            fu fummo foste furono fossi fosse fossimo fossero essendo
            faccio fai facciamo fanno faccia facciate facciano farò farai
            farà faremo farete faranno farei faresti farebbe faremmo
            fareste farebbero facevo facevi faceva facevamo facevate
            facevano feci facesti fece facemmo faceste fecero facessi
            facesse facessimo facessero facendo sto stai sta stiamo stanno
            stia stiate stiano starò starai starà staremo starete staranno
            starei staresti starebbe staremmo stareste starebbero stavo
            stavi stava stavamo stavate stavano stetti stesti stette stemmo
            steste stettero stessi stesse stessimo stessero stando
    );
}

1;
