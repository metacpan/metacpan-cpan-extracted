package Lingua::StopWords::RO;

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
            a abia acea aceasta această această aceea aceia acel acela acelaşi acelaşi
            acele acelea aceluiaşi acest acesta aceste acestea acestei aceşti aceştia
            acestor acestora acestui acolo acum adică ai aia aici al ăla alături ale
            alt alta altă altceva alte altele altfel alţi alţii altul am anume apoi
            ar are aş aşa asemenea asta astăzi astfel asupra atare atât atâta atâtea
            atâţi atâţia aţi atît atîti atîţia atunci au avea avem avut azi ba bine
            ca că cam când care căreia cărora căruia cât câtă câte câţi către ce cea
            ceea cei ceilalţi cel cele celelalte celor ceva chiar ci cînd cine cineva
            cît cîte cîteva cîţi cîţiva cu cui cum cumva da daca dacă dar de deasupra
            decât deci decît deja deşi despre din dintr dintre doar după ea ei el ele
            era este eu fără fecăreia fel fi fie fiecare fiecărui fiecăruia fiind foarte
            fost i-au iar ieri îi îl îmi împotriva în în înainte înapoi înca încît însă
            însă însuşi într între între îşi îţi l-am la le li lor lui mă mai mare mereu
            mod mult multă multe mulţi ne nici niciodata nimeni nimic nişte noi noştri
            noştri nostru nouă nu numai o oarecare oarece oarecine oarecui or orice
            oricum până pe pentru peste pînă plus poată prea prin printr-o puţini s-ar
            sa să să-i să-mi să-şi să-ţi săi sale sau său se şi sînt sîntem sînteţi spre
            sub sunt suntem sunteţi te ţi toată toate tocmai tot toţi totul totuşi tu
            tuturor un una unde unei unele uneori unii unor unui unul va vă voi vom vor
            vreo vreun
    );
}

1;
