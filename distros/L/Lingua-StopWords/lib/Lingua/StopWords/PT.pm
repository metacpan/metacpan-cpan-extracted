package Lingua::StopWords::PT;

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
            de a o que e do da em um para com n√£o uma os no se na por mais
            as dos como mas ao ele das √† seu sua ou quando muito nos j√°
            eu tamb√©m s√≥ pelo pela at√© isso ela entre depois sem mesmo
            aos seus quem nas me esse eles voc√™ essa num nem suas meu √†s
            minha numa pelos elas qual n√≥s lhe deles essas esses pelas
            este dele tu te voc√™s vos lhes meus minhas teu tua teus tuas
            nosso nossa nossos nossas dela delas esta estes estas aquele
            aquela aqueles aquelas isto aquilo estou est√° estamos est√£o
            estive esteve estivemos estiveram estava est√°vamos estavam
            estivera estiv√©ramos esteja estejamos estejam estivesse
            estiv√©ssemos estivessem estiver estivermos estiverem hei h√°
            havemos h√£o houve houvemos houveram houvera houv√©ramos haja
            hajamos hajam houvesse houv√©ssemos houvessem houver houvermos
            houverem houverei houver√° houveremos houver√£o houveria
            houver√≠amos houveriam sou somos s√£o era √©ramos eram fui foi
            fomos foram fora f√¥ramos seja sejamos sejam fosse f√¥ssemos
            fossem for formos forem serei ser√° seremos ser√£o seria
            ser√≠amos seriam tenho tem temos t√©m tinha t√≠nhamos tinham
            tive teve tivemos tiveram tivera tiv√©ramos tenha tenhamos
            tenham tivesse tiv√©ssemos tivessem tiver tivermos tiverem
            terei ter√° teremos ter√£o teria ter√≠amos teriam 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            de a o que e do da em um para com n„o uma os no se na por mais
            as dos como mas ao ele das ‡ seu sua ou quando muito nos j· eu
            tambÈm sÛ pelo pela atÈ isso ela entre depois sem mesmo aos
            seus quem nas me esse eles vocÍ essa num nem suas meu ‡s minha
            numa pelos elas qual nÛs lhe deles essas esses pelas este dele
            tu te vocÍs vos lhes meus minhas teu tua teus tuas nosso nossa
            nossos nossas dela delas esta estes estas aquele aquela aqueles
            aquelas isto aquilo estou est· estamos est„o estive esteve
            estivemos estiveram estava est·vamos estavam estivera
            estivÈramos esteja estejamos estejam estivesse estivÈssemos
            estivessem estiver estivermos estiverem hei h· havemos h„o
            houve houvemos houveram houvera houvÈramos haja hajamos hajam
            houvesse houvÈssemos houvessem houver houvermos houverem
            houverei houver· houveremos houver„o houveria houverÌamos
            houveriam sou somos s„o era Èramos eram fui foi fomos foram
            fora fÙramos seja sejamos sejam fosse fÙssemos fossem for
            formos forem serei ser· seremos ser„o seria serÌamos seriam
            tenho tem temos tÈm tinha tÌnhamos tinham tive teve tivemos
            tiveram tivera tivÈramos tenha tenhamos tenham tivesse
            tivÈssemos tivessem tiver tivermos tiverem terei ter· teremos
            ter„o teria terÌamos teriam 
        );
        return \%stoplist;
    }
}

1;
