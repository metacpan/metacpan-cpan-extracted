=head1 NAME

DynGig::Util::Time - Interpret time expressions

=cut
package DynGig::Util::Time;

use warnings;
use strict;

use DateTime;
use DynGig::Range::Time::Date;

use constant { MINUTE => 60, HOUR => 3600, DAY => 86400 };

=head1 METHODS

=head2 delta_epoch( epoch => time, delta => delta )

Returns seconds since epoch.

 my $time = DynGig::Util::Time->delta_epoch
 (
     epoch => seconds,
     delta => '3days,4weeks,-3hours,+4seconds'
 );

=cut
sub delta_epoch
{
    my ( $class, %param ) = @_;
    my ( $delta, %delta ) = $param{delta} || '';
    my $diff = qr/[+-]?\d+/;
    my $now = DateTime->from_epoch( epoch => $param{epoch} || time );

    $delta =~ s/\s+//;

    for ( split /,+/, $delta )
    {
        if ( /^($diff)(?:s|\b)/o ) { $delta{seconds} += $1 }
        elsif ( /^($diff)mi/o )    { $delta{minutes} += $1 }
        elsif ( /^($diff)h/o )     { $delta{hours}   += $1 }
        elsif ( /^($diff)d/o )     { $delta{days}    += $1 }
        elsif ( /^($diff)w/o )     { $delta{days}    += $1 * 7 }
        elsif ( /^($diff)mo/o )    { $delta{months}  += $1 }
        elsif ( /^($diff)q/o )     { $delta{months}  += $1 * 4 }
        elsif ( /^($diff)y/o )     { $delta{years}   += $1 }
    }

    $now->add( %delta )->epoch();
}

=head2 epoch( time, timezone )

Returns seconds since epoch.

 $time = DynGig::Util::Time->epoch( '-23459271.03' );
 $time = DynGig::Util::Time->epoch( '3days,4weeks,-3hours,+4seconds' );

 $time = DynGig::Util::Time->epoch( '2010-03-12', 'UTC' );
 $time = DynGig::Util::Time->epoch( '2010-03-12 00:12:24' );

 $time = DynGig::Util::Time->epoch( '09:12:42' );
 $time = DynGig::Util::Time->epoch( '09:12', 'America/Los_Angeles' );

=cut
sub epoch
{
    my ( $class, $time, $zone ) = @_;

    return $1 ? time + $time : $time if $time =~ /^([+-]?)\d+(?:\.\d+)?$/;

    my $range = DynGig::Range::Time::Date
        ->setenv( timezone => $zone )->new( $time );

    return $class->delta_epoch( delta => $time ) if $range->empty();
    return $range->abs()->min() if $range->rel()->empty();

    $time = DateTime->now();
    $time->set_time_zone( $zone ) if defined $zone;

    $time->set( DynGig::Range::Time::Date->sec2hms( $range->rel()->min() ) )
        ->epoch();
}

=head2 abs2sec( time, timezone )

Alias of epoch().

=cut
sub abs2sec { epoch( @_ ) }

=head2 rel2sec( expression )

Given a relative time expression, returns seconds.

 $sec = DynGig::Util::Time->rel2sec( '3minutes,-4weeks,+4seconds' );

=cut
sub rel2sec
{
    my ( $class, $time ) = @_;
    my $diff = qr/[+-]?\d+(?:\.\d+)?/;
    my $second = 0;

    return $second unless $time;

    $time =~ s/\s+//;

    for ( split /,+/, $time )
    {
        if ( /^($diff)(?:s|\b)/o ) { $second += $1 }
        elsif ( /^($diff)h/o )     { $second += $1 * HOUR }
        elsif ( /^($diff)d/o )     { $second += $1 * DAY }
        elsif ( /^($diff)w/o )     { $second += $1 * 7 * DAY }
        elsif ( /^($diff)m/o )     { $second += $1 * MINUTE }
    }

    return int $second;
}

=head2 sec2hms( seconds )

Given seconds, returns a HH::MM::SS string.

 $hms = DynGig::Util::Time->sec2hms( 37861 );

=cut
sub sec2hms
{
    my ( $class, $sec ) = @_;
    my $hour = int( $sec / 3600 );
    my $min = int( ( $sec %= 3600 ) / 60 );

    sprintf '%02i:%02i:%02i', $hour, $min, $sec % 60;
}

=head2 hms2sec( string )

Given a HH::MM::SS string, returns seconds.

 $sec = DynGig::Util::Time->hms2sec( '40:23:26' ); ## hour:min:sec
 $sec = DynGig::Util::Time->hms2sec( '23:26' );    ## min:sec
 $sec = DynGig::Util::Time->hms2sec( '26' );       ## sec

=cut
sub hms2sec
{
    my ( $class, $hms ) = @_;
    my @hms = split ':', $hms;

    unshift @hms, 0 while @hms < 3;
    return $hms[0] * 3600 + $hms[1] * 60 + $hms[2];
}

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
