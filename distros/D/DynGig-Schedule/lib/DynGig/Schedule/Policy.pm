=head1 NAME

DynGig::Schedule::Policy - Parse schedule

=cut
package DynGig::Schedule::Policy;

use strict;
use warnings;

use Carp;
use DateTime;
use YAML::XS;

use DynGig::Range::Time::Day;
use DynGig::Range::Time::Date;

=head1 SYNOPSIS

 use DynGig::Schedule::Policy;

 my $policy = DynGig::Schedule::Policy->new
 (
     config => '/config/file',
     level => 3,
     cycle => 7,
     timezone => 'UTC',
 );

=cut
sub new
{
    my ( $class, %param ) = @_;

    map { croak "'$_' not defined" unless $param{$_} }
        qw( level cycle config timezone );

    my $level = $param{level};
    my $config = YAML::XS::LoadFile $param{config};

    croak 'policy is not HASH' if ref $config ne 'HASH';
    croak '"default" not defined' unless $config->{default};

    map { delete $config->{default}{$_} } qw( period redirect );

    for my $label ( keys %$config )
    {
        my $policy = $config->{$label};

        map { croak "$label: $_ not defined" unless $policy->{$_} }
            qw( queue epoch );

        my $queue = $policy->{queue};
        my $redirect = $policy->{redirect} || {};

        croak "$label: invalid redirect" if ref $redirect ne 'HASH';
        croak "$label: invalid queue" if ref $queue ne 'ARRAY';
        croak "$label: invalid queue" unless my @queue =
            map { grep { $_ !~ /:/ } split ',', $_ }
                ref $queue ? @$queue : $queue;

        map { $policy->{$_} ||= $param{$_} } qw( cycle timezone );

        $policy->{queue} = \@queue;

        $policy->{period} &&= DynGig::Range::Time::Day
            ->setenv( cycle => $policy->{cycle} )->new( $policy->{period} );

        $policy->{epoch} = DynGig::Range::Time::Date
            ->setenv( timezone => $policy->{timezone} )
            ->new( $policy->{epoch} )->abs()->min();

        for my $i ( keys %$redirect )
        {
            if ( $i =~ /^\d+$/ && $i > 1 && $i <= $level
                && $redirect->{$i} =~ /^([^:]+):(\d+)$/ && $config->{$1}
                && $1 ne $label && $2 && $2 <= $param{level} 
                && ! $config->{$1}{redirect}{$2 - 1} )
            {
                my $j = $i + 0;

                delete $redirect->{$i} if $i ne $j;
                $redirect->{$j} = [ $1, $2 - 1 ];
            }
            else
            {
                delete $redirect->{$i};
                carp "$label: invalid redirect '$i' ignored";
            }
        }
    }

    map { delete $config->{default}{$_} } qw( period redirect );

    bless { policy => $config, level => $level, timezone => $param{timezone} };
}

=head1 METHODS

=head2 period( start, end )

Determine the policy in specified period. Returns HASH reference.

=cut
sub period
{
    my ( $this, @period ) = @_;
    my ( %policy, %period );

    while ( my ( $name, $policy ) = each %{ $this->{policy} } )
    {
        my $period = DynGig::Range::Integer->new();
        my @queue = @{ $policy->{queue} };
        my $cycle = @queue * $policy->{cycle};
        my $dt = DateTime->from_epoch( epoch => $policy->{epoch} );

        $dt->add( days => $cycle ) while $dt->epoch() < $period[0];
        $dt->subtract( days => $cycle ) while $dt->epoch() > $period[0];

        my @epoch = $dt->epoch();

        for ( my $i = 1, my $dt = $dt->clone(); $i < $this->{level}; $i ++ )
        {
            $dt->add( days => $policy->{cycle} );
            $dt->subtract( days => $cycle ) if $dt->epoch() > $period[0];
            $epoch[$i] = $dt->epoch();
        }

        unless ( $policy->{period} )
        {
            $period->insert( @period );
            goto NEXT;
        }

        my @i = 1 .. $policy->{period}->size();

        $dt->set_time_zone( $policy->{timezone} );

        while ( $dt->epoch() < $period[1] )
        {
            for my $i ( @i )
            {
                for my $p ( $policy->{period}[$i]->list( skip => 1 ) )
                {
                    my @p = map { $dt->set( DynGig::Range::Time::Date
                        ->sec2hms( $_ ) )->epoch() } @$p;

                    last if $p[0] >= $period[1];
                    next if $p[1] <= $period[0];

                    $period->insert( $p[0], $p[1] ++ );
                }

                last if $dt->set( hour => 0, minute => 0, second => 0 )
                    ->add( days => 1 )->epoch() >= $period[1];
            }
        }

        NEXT: $policy{$name} = +
        {
            epoch => \@epoch,
            queue => \@queue,
            period => $period,
            cycle => $policy->{cycle},
        };
    }

    while ( my ( $name, $policy ) = each %policy )
    {
        for my $i ( 0 .. $this->{level} - 1 )
        {
            my $j = $i;

            if ( my $redirect = $this->{policy}{$name}{redirect}{$i + 1} )
            {
                $policy = $policy{ $redirect->[0] };
                $j = $redirect->[1];
            }

            $period{$name}[$i] = [ $policy, $policy->{epoch}[$j] ];
        }
    }

    return \%period;
}

=head1 NOTE

See DynGig::Schedule

=cut

1;

__END__
