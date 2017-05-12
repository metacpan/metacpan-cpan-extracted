=head1 NAME

DynGig::Range::Time::Day -
Extends DynGig::Range::Time::Parse and DynGig::Range::Time::Object.

=cut
package DynGig::Range::Time::Day;

use base DynGig::Range::Time::Parse;
use base DynGig::Range::Time::Object;

use warnings;
use strict;

use overload '*=' => \&filter;

my %_ENV = ( cycle => 7 );

=head1 METHODS

See base class for additional methods.

=head2 setenv( cycle => $int )

Sets private environment variable I<cycle>. Returns object/class.

=cut
sub setenv
{
    my ( $this, %param ) = @_;

    map { $_ENV{$_} = $param{$_} if defined $param{$_} } keys %_ENV;
    return $this;
}

=head2 size()

Return the number of days in the object.

=cut
sub size
{
    my ( $this ) = @_;
    return @$this - 1;
}

=head2 filter( object )

Overloads B<*=>. Returns the object after I<semantic> intersection
with another object. To be implemented by derived class.

=cut
sub filter
{
    my ( $this, $that ) = @_;
    $this->intersect( $that );
}

=head1 INTERNALS

See base class for additional details.

=head2 OBJECT

ARRAY of I<cycle> DynGig::Range::Integer objects, each represents a corresponding day.

=cut
sub _object
{
    my ( $this ) = @_;
    $this->_init( $_ENV{cycle} );
}

=head2 LITERAL

A rudimentary range form. e.g.

 '10:25'     ## 1 minute
 '14:35:00'  ## 1 second
 '6'         ## 1 day
 '2 ~ 7'     ## 5 days

 '10:25 ~ 14:35'
 '10:25:38 ~ 14:35:00'
 '2 @ 10:25 ~ 7 @ 14:35'

=cut
sub _parse_
{
    my ( $this, @range ) = @_;
    my ( $range, @time ) = $this->_object();

    return $range unless @range && @{ $range[0] } == @{ $range[-1] };

    for my $time ( @range )
    {
        return $range if ! grep { @$time == $_ } 1, 3, 5, 7;
        return $range if $time->[0] !~ /^\d/;

        my %time = ( day => -1 );

        if ( @$time == 1 || $time->[1] ne ':' )
        {
            return $range if ( $time{day} = $time->[0] ) > $_ENV{cycle};
            splice @$time, 0, 2;
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
        $time[1]{day} = $time[0]{day} unless defined $time[1]{day};
    }   

    if ( @time == 1 )
    {
        map { $time[1]{$_} = $time[0]{$_} } keys %{ $time[0] };
    }
    else
    {
        return $range if $time[0]{day} * $time[1]{day} < 0;
    }

    my @day = map { $_->{day} } @time;
    @time = map { $_->{hour} * 3600 + $_->{minute} * 60 + $_->{second} } @time;

    if ( $day[0] < 0 )
    {
        map { $range->[$_]->insert( @time ) } 1 .. $#$range;
    }
    else
    {
        $range->[ $day[0] ]->insert( $time[0], 86399 );
        $range->[ $day[1] ]->insert( 0, $time[1] );
        
        map { $range->[$_]->insert( 0, 86399 ) } $day[0] + 1 .. $day[1] - 1; 
    }

    return $range;
}

1;

__END__

=head1 NOTE

See DynGig::Range::Time

=cut
