package Lingua::StopWords::FR;

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
            au aux avec ce ces dans de des du elle en et eux il je la le
            leur lui ma mais me mÃªme mes moi mon ne nos notre nous on ou
            par pas pour qu que qui sa se ses son sur ta te tes toi ton tu
            un une vos votre vous c d j l Ã  m n s t y Ã©tÃ© Ã©tÃ©e Ã©tÃ©es
            Ã©tÃ©s Ã©tant Ã©tante Ã©tants Ã©tantes suis es est sommes Ãªtes
            sont serai seras sera serons serez seront serais serait serions
            seriez seraient Ã©tais Ã©tait Ã©tions Ã©tiez Ã©taient fus fut
            fÃ»mes fÃ»tes furent sois soit soyons soyez soient fusse fusses
            fÃ»t fussions fussiez fussent ayant ayante ayantes ayants eu
            eue eues eus ai as avons avez ont aurai auras aura aurons aurez
            auront aurais aurait aurions auriez auraient avais avait avions
            aviez avaient eut eÃ»mes eÃ»tes eurent aie aies ait ayons ayez
            aient eusse eusses eÃ»t eussions eussiez eussent 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            au aux avec ce ces dans de des du elle en et eux il je la le
            leur lui ma mais me même mes moi mon ne nos notre nous on ou
            par pas pour qu que qui sa se ses son sur ta te tes toi ton tu
            un une vos votre vous c d j l à m n s t y été étée étées étés
            étant étante étants étantes suis es est sommes êtes sont serai
            seras sera serons serez seront serais serait serions seriez
            seraient étais était étions étiez étaient fus fut fûmes fûtes
            furent sois soit soyons soyez soient fusse fusses fût fussions
            fussiez fussent ayant ayante ayantes ayants eu eue eues eus ai
            as avons avez ont aurai auras aura aurons aurez auront aurais
            aurait aurions auriez auraient avais avait avions aviez avaient
            eut eûmes eûtes eurent aie aies ait ayons ayez aient eusse
            eusses eût eussions eussiez eussent 
        );
        return \%stoplist;
    }
}

1;
