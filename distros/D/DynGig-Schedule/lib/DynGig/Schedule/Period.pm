=head1 NAME

DynGig::Schedule::Period - Calculate schedule according to a config file

=cut
package DynGig::Schedule::Period;

use strict;
use warnings;

use Carp;
use DateTime;
use YAML::XS;

use DynGig::Range::String;
use DynGig::Schedule::Policy;
use DynGig::Schedule::Override;

use constant { DEFAULT => 'default', DAY => 86400 };

=head1 SYNOPSIS

 use DynGig::Schedule::Period

 my $period = DynGig::Schedule::Period->new
 (
     config => 'config.yaml',
     period => [ $start_time, $end_time ],
 );

=cut
sub new
{   
    my ( $class, %param ) = @_;
    my $period = $param{period};
    my $config = YAML::XS::LoadFile $param{config};

    croak "Undefined/Invalid 'period'"
        unless $period && ref $period eq 'ARRAY' && @$period == 2;

    my @period = map { ref $_ eq 'DateTime' ? $_->epoch() : $_ } @$period;

    @period = reverse @period if $period[0] > $period[1];

    bless
    {
        period => \@period,
        map { $_ => $config->{$_}->period( @period ) } keys %$config
    };
}

=head1 METHODS

=head2 schedule()

Determine the schedule.
Returns ARRAY in list context. Returns ARRAY reference in scalar context.

=cut
sub schedule
{
    my ( $this, $pattern ) = @_;
    my ( @serial, @match, @schedule ) = '';
    my %schedule = map { $_ => 1 } @{ $this->{period} };
    
    map { map { $schedule{ $_->[0] } = $schedule{ $_->[1] + 1 } = 1 }
        $_->[0][0]{period}->list( skip => 1 ) } values %{ $this->{policy} };

    map { map { map { $schedule{ $_->[0] } = $schedule{ $_->[1] + 1 } = 1 }
        $_->{period}->list( skip => 1 ) } @$_ } values %{ $this->{override} }
            if $this->{override};

    for my $time ( sort { $a <=> $b } keys %schedule )
    {
        next unless my @search = $this->search( $time );

        $serial[1] = join ' ', map { $_->[0]->string() } @search;

        next if $serial[0] eq $serial[1];

        if ( defined $pattern )
        {
            $match[1] = $serial[1] =~ /$pattern/;
            push @schedule, [ $time, @search ] if $match[0] || $match[1];
            $match[0] = $match[1];
        }
        else
        {
            push @schedule, [ $time, @search ];
        }

        $serial[0] = $serial[1];
    }

    return wantarray ? @schedule : \@schedule;
}

=head2 search( time )

Determine the escalation at the time.
Returns ARRAY in list context. Returns ARRAY reference in scalar context.

=cut
sub search
{
    my ( $this, $time ) = @_;
    my @policy = $this->_policy( $time );

    for ( my $i = 0; $i < @policy; )
    {
        my $policy = $policy[$i];
        my $role = $policy->[1] . ':' . ++ $i;
        my $name = $policy->[0] = DynGig::Range::String->new( $policy->[0] );
        my %override = $this->_override( $time, $name, $role );

        $policy->[0] = $override{replace}->clone() if $override{replace};
        $policy->[0]->add( $override{insert} ) if $override{insert};
    }

    return wantarray ? @policy : \@policy;
}

sub _policy
{
    my ( $this, $time ) = @_;
    my $period = $this->{period};
    my $policy = $this->{policy};
    my @policy;

    goto DONE if $time < $period->[0] || $time > $period->[1];

    my $default = $policy->{default};
    my @name = reverse sort grep { $_ ne DEFAULT } keys %$policy;

    for my $i ( 0 .. $#$default )
    {
        for my $name ( DEFAULT, @name )
        {
            my $level = $policy->{$name}[$i];

            if ( $policy[$i] )
            {
                next if $level == $default->[$i];
                last if $policy[$i][1] ne DEFAULT;
            }

            my ( $policy, $epoch ) = @$level;

            if ( defined $policy->{period}->index( $time ) )
            {
                my $j = int( ( $time - $epoch ) / DAY / $policy->{cycle} );

                $j %= @{ $policy->{queue} };
                $policy[$i] = [ $policy->{queue}[$j], $name ];
            }
        }
    }

    DONE: return wantarray ? @policy : \@policy;
}

sub _override
{
    my ( $this, $time, $name, $role ) = @_;
    my %override;

    for my $name ( $name, $role )
    {
        next unless my $override = $this->{override}{$name};

        for my $override ( @$override )
        {
            if ( defined $override->{period}->index( $time ) )
            {
                map { $override{$_} = $override->{$_} if $_ ne 'period' }
                    keys %$override;
                last;
            }
        }

        last if %override;
    }

    return wantarray ? %override : \%override;
}

=head1 NOTE

See DynGig::Schedule

=cut

1;

__END__
