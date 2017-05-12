package Mail::Decency::Helper::IntervalParse;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use base qw/ Exporter /;
our @EXPORT_OK = qw/
    interval_to_int
/;

=head1 NAME

Mail::Decency::Helper::IP

=head1 DESCRIPTION

Helper for everything about ips ..

=cut

our %FACTOR = (
    m => 60,
    h => 3600,
    d => 3600 * 24,
    w => 3600 * 24 * 7
);

sub interval_to_int {
    my ( $interval ) = @_;
    
    if ( $interval =~ /^(\d+)([mhdw])$/ ) {
        $interval = $1 * $FACTOR{ $2 };
    }
    else {
        $interval = int( $interval );
    }
    return $interval;
}


1;
