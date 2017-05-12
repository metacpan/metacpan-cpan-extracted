package MColPro::Util::TimeHelper;

=head1 NAME

 MColPro::Util::TimeHelper - time expressions

=cut

use warnings;
use strict;

use constant { MINUTE => 60, HOUR => 3600, DAY => 86400 };

sub rel2sec
{
    my $time = shift;
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

sub sec2hms
{
    my $sec = shift;
    my $hour = int( $sec / 3600 );
    my $min = int( ( $sec %= 3600 ) / 60 );

    sprintf '%02i:%02i:%02i', $hour, $min, $sec % 60;
}

sub hms2sec
{
    my $hms = shift;
    my @hms = split ':', $hms;

    unshift @hms, 0 while @hms < 3;
    return $hms[0] * 3600 + $hms[1] * 60 + $hms[2];
}

1;

__END__
