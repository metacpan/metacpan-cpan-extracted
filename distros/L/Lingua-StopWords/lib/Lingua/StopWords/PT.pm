package Lingua::StopWords::PT;

use strict;
use warnings;

use utf8;

use Encode qw(encode);

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.12;

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
            de a o que e do da em um para com não uma os no se na por mais
            as dos como mas ao ele das à seu sua ou quando muito nos já eu
            também só pelo pela até isso ela entre depois sem mesmo aos
            seus quem nas me esse eles você essa num nem suas meu às minha
            numa pelos elas qual nós lhe deles essas esses pelas este dele
            tu te vocês vos lhes meus minhas teu tua teus tuas nosso nossa
            nossos nossas dela delas esta estes estas aquele aquela aqueles
            aquelas isto aquilo estou está estamos estão estive esteve
            estivemos estiveram estava estávamos estavam estivera
            estivéramos esteja estejamos estejam estivesse estivéssemos
            estivessem estiver estivermos estiverem hei há havemos hão
            houve houvemos houveram houvera houvéramos haja hajamos hajam
            houvesse houvéssemos houvessem houver houvermos houverem
            houverei houverá houveremos houverão houveria houveríamos
            houveriam sou somos são era éramos eram fui foi fomos foram
            fora fôramos seja sejamos sejam fosse fôssemos fossem for
            formos forem serei será seremos serão seria seríamos seriam
            tenho tem temos tém tinha tínhamos tinham tive teve tivemos
            tiveram tivera tivéramos tenha tenhamos tenham tivesse
            tivéssemos tivessem tiver tivermos tiverem terei terá teremos
            terão teria teríamos teriam
    );
}

1;
