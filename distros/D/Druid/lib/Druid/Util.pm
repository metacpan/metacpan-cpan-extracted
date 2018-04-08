package Druid::Util;

use strict;
use warnings;
use Exporter qw< import >;

# Exporter settings
our @EXPORT_OK = qw(
    iso8601_yyyy_mm_dd_hh_mm_ss
    yyyy_mm_dd_hh_mm_ss_iso8601
);

my $ISO8601_RE = qr{
    ^
    ( [0-9]{4} )   # YYYY (Year)
    -
    ( [0-9]{2} )   # MM (Month)
    -
    ( [0-9]{2} ) T # DD (Day)

    # HH:MM:SS.mmm
    # Hour:Minute:Second.milliseconds
    ( [0-9]{2} ) : ( [0-9]{2} ) : ([0-9]{2} ) . ( [0-9]{3} ) Z
    $
}xms;

my $YYYYMMDD_RE = qr{
    ^
    ( [0-9]{4} )    # YY
    -?
    ( [0-9]{2} )    # MM
    -?
    ( [0-9]{2} )    # DD
    \s*

    # HH:MM:SS or HHMMSS
    # Hour:Minute:Second or HourMinuteSecond
    ( [0-9]{2} ) :? ( [0-9]{2} ) :? ( [0-9]{2} )
    $
}xms;

sub iso8601_yyyy_mm_dd_hh_mm_ss {
    my $iso_date = shift;

    if ( $iso_date =~ $ISO8601_RE ) {
        return sprintf '%s-%02d-%02d %02d:%02d:%02d', $1, $2, $3, $4, $5, $6;
    } else {
        die "'$iso_date' not a valid ISO8601 format.\n";
    }
}


sub yyyy_mm_dd_hh_mm_ss_iso8601 {
    my $yyyy_mm_dd_hh_mm_ss = shift;

    if ( $yyyy_mm_dd_hh_mm_ss =~ $YYYYMMDD_RE ) {
        return sprintf '%s-%02d-%02dT%02d:%02d:%02d', $1, $2, $3, $4, $5, $6;
    } else {
        die "'$yyyy_mm_dd_hh_mm_ss' not a valid YYYYMMDDHHMMSS or YYYY-MM-DD HH:MM:SS format.\n";
    }
}

1;
