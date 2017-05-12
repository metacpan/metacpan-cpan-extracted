package Lingua::StopWords::NL;

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
            de en van ik te dat die in een hij het niet zijn is was op aan
            met als voor had er maar om hem dan zou of wat mijn men dit zo
            door over ze zich bij ook tot je mij uit der daar haar naar heb
            hoe heeft hebben deze u want nog zal me zij nu ge geen omdat
            iets worden toch al waren veel meer doen toen moet ben zonder
            kan hun dus alles onder ja eens hier wie werd altijd doch wordt
            wezen kunnen ons zelf tegen na reeds wil kon niets uw iemand
            geweest andere 
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw( 
            de en van ik te dat die in een hij het niet zijn is was op aan
            met als voor had er maar om hem dan zou of wat mijn men dit zo
            door over ze zich bij ook tot je mij uit der daar haar naar heb
            hoe heeft hebben deze u want nog zal me zij nu ge geen omdat
            iets worden toch al waren veel meer doen toen moet ben zonder
            kan hun dus alles onder ja eens hier wie werd altijd doch wordt
            wezen kunnen ons zelf tegen na reeds wil kon niets uw iemand
            geweest andere 
        );
        return \%stoplist;
    }
}

1;
