package Lingua::StopWords::DA;

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
            og i jeg det at en den til er som pÃ¥ de med han af for ikke
            der var mig sig men et har om vi min havde ham hun nu over da
            fra du ud sin dem os op man hans hvor eller hvad skal selv her
            alle vil blev kunne ind nÃ¥r vÃ¦re dog noget ville jo deres
            efter ned skulle denne end dette mit ogsÃ¥ under have dig anden
            hende mine alt meget sit sine vor mod disse hvis din nogle hos
            blive mange ad bliver hendes vÃ¦ret thi jer sÃ¥dan 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            og i jeg det at en den til er som på de med han af for ikke der
            var mig sig men et har om vi min havde ham hun nu over da fra
            du ud sin dem os op man hans hvor eller hvad skal selv her alle
            vil blev kunne ind når være dog noget ville jo deres efter ned
            skulle denne end dette mit også under have dig anden hende mine
            alt meget sit sine vor mod disse hvis din nogle hos blive mange
            ad bliver hendes været thi jer sådan 
        );
        return \%stoplist;
    }
}

1;
