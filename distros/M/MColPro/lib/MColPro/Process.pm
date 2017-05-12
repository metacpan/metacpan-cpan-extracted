package MColPro::Process;

=head1 NAME

 MColPro::Process - Data process and report

=cut

use strict;
use warnings;
use utf8;

use Carp;

use YAML::XS;
use threads;
use threads::shared;
use Time::HiRes qw( time sleep alarm stat );
use POSIX qw( strftime );

use DynGig::Range::String;

use MColPro::Util::Logger;
use MColPro::Util::Plugin;
use MColPro::Report;
use MColPro::SqlBase;
use MColPro::Record;
use MColPro::Exclude;
use MColPro::Process::Policy;
use MColPro::Process::Event;

sub new
{
    my ( $class, %conf ) = @_;
    my %self;

    confess "invaild conf" 
        unless $conf{event} && $conf{config};

    $self{event} = MColPro::Process::Event->new( $conf{event} );
    $self{log} = MColPro::Util::Logger->new( \*STDERR );

    ## db
    $self{config} = MColPro::SqlBase::conf_check( $conf{config} );

    ## report
    $self{config}{sms} = MColPro::Util::Plugin->new( $self{config}{sms} )
        if $self{config}{sms};
    $self{config}{email} = MColPro::Util::Plugin->new( $self{config}{email} )
        if $self{config}{email};

    bless \%self, ref $class || $class;
}

sub run
{
    my $self = shift;

    my $log = $self->{log};
    my @thread;

    $SIG{TERM} = $SIG{INT} = sub
    {
        $log->say( 'Process: killed.' );
        map
        {
            $_->kill( 'SIGKILL' )->detach();
        } @thread;
        exit 1;
    };

    for my $event ( @{ $self->{event} } )
    {
        push @thread, threads::async
        {
            my $tmp_ms = MColPro::SqlBase->new( $self->{config} );
            my $init_p = MColPro::Record->new( $self->{config}, $tmp_ms );
            my $position = $init_p->init_position( $event->{name}
                , $event->{interval} );
            $tmp_ms->close();

            local $SIG{KILL} = sub { threads->exit(); };

            while(1)
            {
                $log->say( "Process: thread loop start" );

                my $start = time;

                $log->say( "postion: $position" );

                eval
                {
                    my $ms = MColPro::SqlBase->new( $self->{config} );
                    my $recorder = MColPro::Record->new( $self->{config}, $ms );
                    $log->say( $event->{name} );

                    my ( $result, $new_p ) = $recorder->dump
                    (
                        $event->{name},
                        $event->{condition},
                        $position,
                    );
                    $position = $new_p;

                    ## reset policy count if cluster x not result
                    if ( $result )
                    {
                        while( my( $name, $policy ) 
                                = each %{ $event->{policy} } )
                        {
                            map
                            {
                                delete $policy->{$_}
                                    if $_ ne 'stair' && ! defined $result->{$_};
                            } keys %$policy;
                        }

                        if ( %$result )
                        {
                            my $message = &_process( $event, $result );

                            if( $message && %$message )
                            {
                                my $reporter = MColPro::Report->new( $self->{config}, $ms );
                                $reporter->report( $event->{name}, $message );
                            }
                        }
                    }

                    $ms->close();
                };

                $log->say( "Process: thread erorr $@" ) if $@;

                $log->say( "Process: thread loop end" );

                my $sleep = $start + $event->{interval} - time + 0.1; ## 0.1 revise
                sleep $sleep if $sleep > 0;
            }
        };

    }

    while(1)
    {
        map
        {
            die "some threads dead" 
                unless $_->is_running();
        } @thread;
        sleep 20;
    }
}

sub _process
{
    my ( $event, $result ) = @_;
    my %notice;

    ## hour::min and week day
    my $hm = strftime( "%H:%M", localtime(time) );
    my ( undef,undef,undef,undef,undef,undef,$wday) = localtime(time);

    while( my( $cluster, $cinfo ) = each %$result )
    {
        ## combined alarm
        while( my ( $node, $ninfo ) = each %$cinfo )
        {
            my $label = $ninfo->{label};
            if( $event->{label} && ! eval $event->{label} )
            {
                delete $cinfo->{$node};
                next;
            }
        }
        next unless %$cinfo;

        ## policy
        $cluster =~ /(.*?)\[(.*?)\]/o;
        my $cluster_prefix = $1 || $cluster;
        my $policy = $event->{policy}{$cluster_prefix} || $event->{policy}{default};
        my $cpolicy = $policy->{$cluster} ||= {};
        $cpolicy->{count}++;
        $cpolicy->{last_report} ||= 0;

        for ( @{ $policy->{stair} } )
        {
            ## Error次数在报警策略范围内
            if ( $cpolicy->{count} >= $_->{count}[0]
                && $cpolicy->{count} <= $_->{count}[1] )
            {
                ## 第一次出现Error 或者 Error次数增长量等于步长
                if ( $cpolicy->{count} == $_->{count}[0] 
                    || $cpolicy->{count} == $cpolicy->{last_report} + $_->{step} )
                {
                    ##更新本次报警对应的Error次数
                    $cpolicy->{last_report} = $cpolicy->{count};

                    ## 是否在报警时间范围内
                    if( $_->{time} )
                    {
                        next unless $_->{time}{wday}{$wday};
                        next unless $hm ge $_->{time}{hm}[0]
                            && $hm le $_->{time}{hm}[1];
                    }

                    ## 报警
                    push @{ $notice{$cluster}{contacts} }, @{ $_->{reciver} };
                }
            }
        } 
        next unless $notice{$cluster}; ## policy said nothing need report

        my %info;
        while( my ( $node, $ninfo ) = each %$cinfo )
        {
            my $label = delete $ninfo->{label};
            $label = DynGig::Range::String->serial( map { $_ =~ s/\/{1}/##/g; $_ } keys %$label );
            $label =~ s/##/\//g;
            push @{ $info{$label}{nodes} }, $node;
            my $id = delete $ninfo->{id};
            push @{ $info{$label}{id} }, $id;
        }

        ## notice
        $notice{$cluster}{email} = YAML::XS::Dump( $cinfo ); ## email content

        while( my ( $label, $attr ) = each %info )
        {
            my $range = DynGig::Range::String->serial( @{ $attr->{nodes} } );
            my $id = DynGig::Range::String->serial( @{ $attr->{id} } );

            push @{ $notice{$cluster}{info} }, [ $range, $label, $id, ];
        }

    }

    return \%notice;
}

1;
