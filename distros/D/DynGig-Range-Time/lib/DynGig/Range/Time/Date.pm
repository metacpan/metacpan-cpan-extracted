=head1 NAME

DynGig::Range::Time::Date -
Extends DynGig::Range::Time::Parse and DynGig::Range::Time::Object.

=cut
package DynGig::Range::Time::Date;

use base DynGig::Range::Time::Parse;
use base DynGig::Range::Time::Object;

use warnings;
use strict;

use DateTime;
use DynGig::Range::Integer;
use overload '*=' => \&filter;
use constant { ABS => 0, REL => 1 };

my %_ENV = ( timezone => 'UTC' );

=head1 METHODS

See base class for additional methods.

=head2 setenv( timezone => $TZ )

Sets private environment variable I<timezone>. Returns object/class.

=cut
sub setenv
{
    my ( $this, %param ) = @_;

    map { $_ENV{$_} = $param{$_} if defined $param{$_} } keys %_ENV;
    return $this;
}

=head2 abs()

Returns absolute time.

=cut
sub abs
{
    my ( $this ) = @_;
    return $this->[ABS];
}

=head2 rel()

Returns relative time.

=cut
sub rel
{
    my ( $this ) = @_;
    return $this->[REL];
}

=head2 sec2hms( seconds )

Converts seconds into a HASH of hour, minute, second. Returns HASH referece.

=cut
sub sec2hms
{
    my ( $this, $sec ) = @_;
    my %hms;

    if ( $sec )
    {
        $hms{hour} = int( $sec / 3600 );
        $sec %= 3600;
        $hms{minute} = int( $sec / 60 );
        $sec %= 60;
        $hms{second} = $sec;
    }

    return \%hms;
}

=head2 filter( object )

Overloads B<*=>.
Returns the object after I<semantic> intersection with another object.

=cut
sub filter
{
    my ( $this, $that ) = @_;
    my ( $abs, $rel );

    return $this->clear() if 1 != grep { ! $this->[$_]->empty() } 1 .. 2;
    return $this->clear() if 1 != grep { ! $that->[$_]->empty() } 1 .. 2;

    if ( $this->[ABS]->empty() )
    {
        if ( $that->[ABS]->empty() )
        {
            $this->[REL] &= $that->[REL];
            return $this;
        }

        $abs = $this->[ABS] = $that->[ABS]->clone();
        $rel = $this->[REL];
    }
    else
    {
        if ( $that->[REL]->empty() )
        {
            $this->[ABS] &= $that->[ABS];
            return $this;
        }

        $abs = $this->[ABS];
        $rel = $that->[REL];
    }

    my $filter = DynGig::Range::Integer->new();
    my ( @hms, %ymd );

    for my $rel ( $rel->list( skip => 1 ) )
    {
        push @hms, [ map { $this->sec2hms( $_ ) } @$rel ];
    }

    for my $abs ( $abs->list( skip => 1 ) )
    {
        my $dt = DateTime
           ->from_epoch( epoch => $abs->[ABS], time_zone => $_ENV{timezone} );

        while ( $dt->epoch() < $abs->[1] )
        {
            $ymd{ $dt->year() }{ $dt->month() }{ $dt->day() } = \@hms;
            $dt->add( days => 1 );
        }
    }

    for my $year ( keys %ymd )
    {
        for my $month ( keys %{ $ymd{$year} } )
        {
            for my $day ( keys %{ $ymd{$year}{$month} } )
            {
                for my $hms ( @{ $ymd{$year}{$month}{$day} } )
                {
                    $filter->insert
                    (
                        map { DateTime->new( %$_,
                            time_zone => $_ENV{timezone},
                            year => $year, month => $month,
                            day => $day )->epoch() } @$hms
                    );
                }
            }
        }
    }

    $this->[REL]->clear();
    $this->[ABS] &= $filter;

    return $this;
}

=head1 INTERNALS

See base class for additional details.

=head2 OBJECT

ARRAY of 2 DynGig::Range::Integer objects,
each represents I<absolute> and I<relative>.

=cut
sub _object
{
    my ( $this ) = @_;
    $this->_init( 2 );
}

=head2 LITERAL

A rudimentary range form. e.g.

 '10:25'                     ## 1 minute
 '14:35:00'                  ## 1 second
 '2010/10/13'                ## 1 day
 '2010/10/13 ~ 2010/10/24'   ## 11 days

 '10:25 ~ 14:35'
 '10:25:38 ~ 14:35:00'
 '2010/10/13 @ 10:25 ~ 2011/1/3 @ 14:35'

=cut
sub _parse_
{
    my ( $this, @range ) = @_;
    my ( $range, @time ) = $this->_object();

    return $range unless @range && @{ $range[0] } == @{ $range[-1] };

    for my $time ( @range )
    {
        return $range if ! grep { @$time == $_ } 3, 5, 9;
        return $range if $time->[0] !~ /^\d/;

        my %time = ( day => -1 );

        if ( @$time >= 5 && $time->[1] ne ':' )
        {
            $time{year} += 1900 if ($time{year} = $time->[0] ) < 1900;

            return $range unless ( $time{month} = $time->[2] )
                && $time{month} <= 12;

            return $range unless ( $time{day} = $time->[4] )
                && $time{day} <= 31;

            splice @$time, 0, 6;
        }

        if ( @$time )
        {
            return $range if ( $time{hour} = $time->[0] ) >= 24;
            return $range if ( $time{minute} = $time->[2] ) >= 60;
            return $range if @$time > 4 && ( $time{second} = $time->[4] ) >= 60;
        }

        push @time, \%time;
    }

    map { $time[1]{$_} = $time[0]{$_} } keys %{ $time[0] }
        if $time[-1] == $time[0];

    unless ( defined $time[-1]{second} )
    {
        $time[0]{second} = 0;
        $time[1]{second} = 59;
    }

    unless ( defined $time[-1]{hour} )
    {
        $time[0]{hour} = $time[0]{minute} = 0;
        $time[1]{hour} = 23;
        $time[1]{minute} = 59;

        map { $time[1]{$_} = $time[0]{$_} } qw( year month day )
            unless defined $time[1]{day};
    }

    return $range if $time[0]{day} * $time[1]{day} < 0;

    if ( $time[0]{day} > 0 )
    {
        @time = eval { map { DateTime
            ->new( %$_, time_zone => $_ENV{timezone} )->epoch() } @time };

        $range->[0]->insert( @time ) unless $@;
    }
    else
    {
        @time = map { $_->{hour} * 3600 + $_->{minute} * 60 + $_->{second} }
            @time;

        $range->[1]->insert( @time );
    }

    return $range;
}

1;

__END__

=head1 NOTE

See DynGig::Range::Time

=cut
