package Lingua::StopWords::IT;

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
            ad al allo ai agli all agl alla alle con col coi da dal dallo
            dai dagli dall dagl dalla dalle di del dello dei degli dell
            degl della delle in nel nello nei negli nell negl nella nelle
            su sul sullo sui sugli sull sugl sulla sulle per tra contro io
            tu lui lei noi voi loro mio mia miei mie tuo tua tuoi tue suo
            sua suoi sue nostro nostra nostri nostre vostro vostra vostri
            vostre mi ti ci vi lo la li le gli ne il un uno una ma ed se
            perch√© anche come dov dove che chi cui non pi√π quale quanto
            quanti quanta quante quello quelli quella quelle questo questi
            questa queste si tutto tutti a c e i l o ho hai ha abbiamo
            avete hanno abbia abbiate abbiano avr√≤ avrai avr√† avremo
            avrete avranno avrei avresti avrebbe avremmo avreste avrebbero
            avevo avevi aveva avevamo avevate avevano ebbi avesti ebbe
            avemmo aveste ebbero avessi avesse avessimo avessero avendo
            avuto avuta avuti avute sono sei √® siamo siete sia siate siano
            sar√≤ sarai sar√† saremo sarete saranno sarei saresti sarebbe
            saremmo sareste sarebbero ero eri era eravamo eravate erano fui
            fosti fu fummo foste furono fossi fosse fossimo fossero essendo
            faccio fai facciamo fanno faccia facciate facciano far√≤ farai
            far√† faremo farete faranno farei faresti farebbe faremmo
            fareste farebbero facevo facevi faceva facevamo facevate
            facevano feci facesti fece facemmo faceste fecero facessi
            facesse facessimo facessero facendo sto stai sta stiamo stanno
            stia stiate stiano star√≤ starai star√† staremo starete
            staranno starei staresti starebbe staremmo stareste starebbero
            stavo stavi stava stavamo stavate stavano stetti stesti stette
            stemmo steste stettero stessi stesse stessimo stessero stando 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            ad al allo ai agli all agl alla alle con col coi da dal dallo
            dai dagli dall dagl dalla dalle di del dello dei degli dell
            degl della delle in nel nello nei negli nell negl nella nelle
            su sul sullo sui sugli sull sugl sulla sulle per tra contro io
            tu lui lei noi voi loro mio mia miei mie tuo tua tuoi tue suo
            sua suoi sue nostro nostra nostri nostre vostro vostra vostri
            vostre mi ti ci vi lo la li le gli ne il un uno una ma ed se
            perchÈ anche come dov dove che chi cui non pi˘ quale quanto
            quanti quanta quante quello quelli quella quelle questo questi
            questa queste si tutto tutti a c e i l o ho hai ha abbiamo
            avete hanno abbia abbiate abbiano avrÚ avrai avr‡ avremo avrete
            avranno avrei avresti avrebbe avremmo avreste avrebbero avevo
            avevi aveva avevamo avevate avevano ebbi avesti ebbe avemmo
            aveste ebbero avessi avesse avessimo avessero avendo avuto
            avuta avuti avute sono sei Ë siamo siete sia siate siano sarÚ
            sarai sar‡ saremo sarete saranno sarei saresti sarebbe saremmo
            sareste sarebbero ero eri era eravamo eravate erano fui fosti
            fu fummo foste furono fossi fosse fossimo fossero essendo
            faccio fai facciamo fanno faccia facciate facciano farÚ farai
            far‡ faremo farete faranno farei faresti farebbe faremmo
            fareste farebbero facevo facevi faceva facevamo facevate
            facevano feci facesti fece facemmo faceste fecero facessi
            facesse facessimo facessero facendo sto stai sta stiamo stanno
            stia stiate stiano starÚ starai star‡ staremo starete staranno
            starei staresti starebbe staremmo stareste starebbero stavo
            stavi stava stavamo stavate stavano stetti stesti stette stemmo
            steste stettero stessi stesse stessimo stessero stando 
        );
        return \%stoplist;
    }
}

1;
