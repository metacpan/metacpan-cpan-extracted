=head1 NAME

DynGig::Schedule::Override - Parse override policy

=cut
package DynGig::Schedule::Override;

use strict;
use warnings;

use Carp;
use YAML::XS;

use DynGig::Range::String;
use DynGig::Range::Time::Date;

use constant OVERRIDE => qw( replace insert );

=head1 SYNOPSIS

 use DynGig::Schedule::Override;

 my $policy = DynGig::Schedule::Override->new
 (
     config => '/config/file',
     policy => $policy_object,
 );

=cut
sub new
{
    my ( $class, %param ) = @_;

    map { croak "'$_' not defined" unless $param{$_} } qw( policy config );

    my $policy = $param{policy};
    my $config = YAML::XS::LoadFile( $param{override} || $param{config} );

    goto DONE if ref $config ne 'HASH';

    my %config;
    my %queue = map { $_ => 1 } map { @{ $_->{queue} } }
        values %{ $policy->{policy} };

    for my $name ( keys %$config )
    {
        if ( $name =~ /(.+?):(\d+)$/ )
        {
            next unless $policy->{policy}{$1} && $2 && $2 <= $policy->{level};
        }
        else
        {
            next unless $queue{$name};
        }

        my @override;
        my $override = $config->{$name};

        for my $override ( ref $override eq 'ARRAY'
            ? reverse @$override : $override )
        {
            next unless $override && ref $override eq 'HASH';

            $override->{timezone} ||= $policy->{timezone};

            $override->{period} &&= DynGig::Range::Time::Date
                ->setenv( timezone => $override->{timezone} )
                ->new( $override->{period} );

            if ( $override->{period} )
            {
                map { $override->{period}->subtract( $_->{period} ) } @override;
                last if $override->{period}->empty();
            }

            for my $action ( OVERRIDE )
            {
                $override->{$action} =
                    DynGig::Range::String->new( $override->{$action} );
    
                delete $override->{$action} if $override->{$action}->empty();
            }
    
            push @override, $override if grep { $override->{$_} } OVERRIDE;
            last unless $override->{period};
        }

        $config{$name} = \@override if @override;
    }

    DONE: bless \%config;
}

=head1 METHODS

=head2 period( start, end )

Determine the policy in specified period. Returns HASH reference.

=cut
sub period
{
    my ( $this, @period ) = @_;
    my %period;
    my $epoch = DateTime->from_epoch( epoch => $period[0] );

    while ( my ( $name, $override ) = each %$this )
    {
        my @override;

        for my $o ( @$override )
        {
            my $period = DynGig::Range::Integer->new()->insert( @period );
            my $dt = $epoch->clone()->set_time_zone( $o->{timezone} )
                ->set( hour => 0, minute => 0, second => 0 );

            goto NEXT unless $o->{period};

            $period = $o->{period}->abs()->clone();

            while ( $dt->epoch() < $period[1] )
            {
                for my $p ( $o->{period}->rel()->list( skip => 1 ) )
                {
                    my @p = map { $dt->set( DynGig::Range::Time::Date
                        ->sec2hms( $_ ) )->epoch() } @$p;

                    last if $p[0] >= $period[1];
                    next if $p[1] <= $period[0];

                    $period->insert( $p[0], $p[1] ++ );
                }

                $dt->set( hour => 0, minute => 0, second => 0 )
                    ->set_time_zone( 'UTC' )->add( days => 1 )
                    ->set_time_zone( $o->{timezone} );
            }

            NEXT: map { $period->subtract( $_->{period} ) } @override;

            next if $period->empty();

            unshift @override, +{ period => $period };
            map { $override[0]{$_} = $o->{$_}->clone() if $o->{$_} } OVERRIDE;
        }

        $period{$name} = \@override;
    }

    return \%period;
}

=head1 NOTE

See DynGig::Schedule

=cut

1;

__END__
