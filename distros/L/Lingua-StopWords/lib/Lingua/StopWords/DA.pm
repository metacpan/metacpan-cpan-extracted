package Lingua::StopWords::DA;

use strict;
use warnings;

use utf8;

use Encode qw(encode _utf8_on);

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
            og i jeg det at en den til er som på de med han af for ikke der
            var mig sig men et har om vi min havde ham hun nu over da fra
            du ud sin dem os op man hans hvor eller hvad skal selv her alle
            vil blev kunne ind når være dog noget ville jo deres efter ned
            skulle denne end dette mit også under have dig anden hende mine
            alt meget sit sine vor mod disse hvis din nogle hos blive mange
            ad bliver hendes været thi jer sådan
    );
}

1;
