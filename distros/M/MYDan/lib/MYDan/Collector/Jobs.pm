package MYDan::Collector::Jobs;
use strict;
use warnings;

use Carp;
use YAML::XS;

use Digest::MD5;
use Sys::Hostname;

use threads;
use Thread::Queue;

use MYDan::Collector::Push;
use MYDan::Collector::Sock::Data;
use MYDan::Collector::Sock::Ring;
use MYDan::Collector::Stat::Backup;
use MYDan::Collector::Util;

use POSIX qw( :sys_wait_h );
#use Time::HiRes qw( time sleep alarm stat );

use Data::Dumper;

sub new
{
    my ( $class, %this ) = @_;

    $this{jobs} = '' unless $this{jobs} && $this{jobs} =~ /^[\w_]+$/;
    map{ $this{$_} = "$this{$_}_$this{jobs}" if $this{jobs} }qw( data logs );
    map{ 
        confess "no $_\n" unless $this{$_};
        system "mkdir -p '$this{$_}'" unless -d $this{$_} 
    }
    qw( conf code logs data );
   
    $this{conf} = sprintf "$this{conf}/config%s", $this{jobs} ? "_$this{jobs}" : '';

    MYDan::Collector::Sock::Data->new( path => "$this{data}/output.sock" )->run();
    MYDan::Collector::Sock::Ring->new( path => "$this{data}/ring.sock" )->run();

    $MYDan::Collector::Stat::Backup::path = "$this{data}/backup";

    $this{config} = eval{ YAML::XS::LoadFile $this{conf} };
    confess "load config fail:$@\n" if $@;

    $this{md5} = Digest::MD5->new->add( YAML::XS::Dump $this{config} )->hexdigest;

    return bless \%this, ref $class || $class;
}

sub run
{
    my ( $this, $index ) = shift;

    my $queue = Thread::Queue->new;
#    $SIG{ALRM} = sub{ die "code timeout."; };

    my $config = $this->{config};
    my $conf   = $config->{conf};
    my $push   = MYDan::Collector::Push->new( %{$config->{'push'}} ) if $config->{'push'};

    threads::async
    { 
        while( sleep 10 )
        {
            my $conf = eval{  YAML::XS::LoadFile $this->{conf} };
            if( $@ ){ warn "load config fail. exit(1).\n"; exit 1 };

            my $curr =  Digest::MD5->new->add( YAML::XS::Dump $conf )->hexdigest;
            if ( $curr ne $this->{md5} )
            {  warn "conf file has changed. exit(1).\n"; exit 1; }
        }
    }->detach;

    threads::async
    { 
        my $index = MYDan::Collector::Util::qx( "ls -tr $this->{logs}/output.* |tail -n 1" ) 
                        =~ /\/output\.(\d+)\n$/ ? $1 : 0;

        while( 1 )
        {
            if (( stat "$this->{data}/output" )[9] > time - 90 )
            {
                $index = 1 if ++$index > 1024;
                MYDan::Collector::Util::system "cp '$this->{data}/output' '$this->{logs}/output.$index'";
                sleep 600;
            }
            else { sleep 30; }
        }
    }->detach;


    sub task
        {
            my ( $t, $conf, $this, $config, $queue ) = @_;
            $SIG{'KILL'} = sub { print "$t exit\n";threads->exit(); };
            $SIG{'CHLD'} = sub {                   
                my $kid;
                do {
                    $kid = waitpid(-1, WNOHANG);
                } while $kid > 0;
            };
            print "init $t\n";
            #my $conf = $conf->{$t};
            my ( $interval, $timeout, $code, $param, $i ) 
                = @$conf{qw( interval timeout code param )};

            $interval ||= 60; $timeout ||= $interval;

            $code = do "$this->{code}/$config->{conf}{$t}{code}";
            unless( $code && ref $code eq 'CODE' )
            {
                warn "load code fail: $t\n";
                exit 1;
            }

            while(1)
            {
                printf "do $t (%d)...\n", ++ $i;
                my $time = time;
                eval
                {
                    my $data = &$code( %$param );
                    $queue->enqueue( 'data', $t, YAML::XS::Dump $data );
                };
                $queue->enqueue( 'code', $t, 
                    YAML::XS::Dump [ time - $time, $time, $@ ||'' ] 
                );

                my $due = $time + $interval - time;
                sleep $due if $due > 0;
        }
    };

    my ( %thr, %tid );
    map{ 
        $thr{$_} = threads->create( 'task', ( $_, $conf->{$_}, $this, $config, $queue ) );
        $tid{$thr{$_}->tid()} = $_;
    }keys %$conf;


    my %timeout  = map{ $_ => $conf->{$_}{timeout} || 60 }keys %$conf;
    my %interval = map{ $_ => $conf->{$_}{interval} || 60}keys %$conf;
    my ( $time, %data, %time ) = time;

    my $prev = 0;
    while( 1 )
    {
        printf "do(%d)...\n", ++ $index;
        
        while( $queue->pending )
        {
            my ( $type, $name, $data ) = $queue->dequeue( 3 );
            $data{$type}{$name} = YAML::XS::Load $data;
            MYDan::Collector::Sock::Ring::push( $data{$type}{$name} ) if $type eq 'data';
        }

        my $uptime = $data{'collector'}{uptime} = time - $time;
        my $curr = int( $uptime / 60 );
        if ( $curr > $prev )
        {
            $prev = $curr;

            $data{'collector'}{cfgtime} = time - ( stat $this->{conf} )[9];
            my ( @t, @collector ) = qw( uptime cfgtime);
            push my @coll, [ 'TASK', @t ];
            push @coll, [ 'value', map{ $data{'collector'}{$_} }@t ];
            push my @code, [ qw( TASK usetime last err ) ];
            map
            {
                unless( $data{'code'}{$_} )
                {
                    push @code, [ $_, '','','no info'];
                }
                else
                {
                    my ( $usetime, $last, $err ) = @{$data{'code'}{$_}};
                    $err = "run timeout" if ! $err && $usetime > $interval{$_};
                    $err = "timeout" if ! $err && $last + $usetime + $timeout{$_} < time;
                    push @code, [ $_, $usetime, $last, $err ];
                }
            }sort keys %timeout;

            for( 1 .. @code -1 )
            {
                my ( $name, $error ) = ( $code[$_][0], $code[$_][3] );
                next unless $error;
                print "code stat error $name, restart!!!\n";
                eval{ $thr{$name}->kill('KILL'); } ;##if $curr % 2;
                print "kill thread err:$@\n" if $@;
            }

            for my $t ( threads->list( threads::joinable ) )
            {

                my $tid = $t->tid();
                next unless my $name = delete $tid{$tid};
                $t->join();
                $thr{$name} = threads->create(
                    'task', ( $name, $conf->{$name}, $this, $config, $queue )
                );

                $tid{$thr{$name}->tid()} = $name;
            }

            push @collector, \@coll, \@code;
            MYDan::Collector::Sock::Ring::push( $data{data}{collector} = \@collector );
            eval{ 
                YAML::XS::DumpFile "$this->{data}/.output", $data{data};
                $push->push( $data{data} ) if $push;
                $MYDan::Collector::Sock::Data::DATA = YAML::XS::Dump $data{data};
            };
            
            MYDan::Collector::Util::system "mv '$this->{data}/.output' '$this->{data}/output'";
        }
        sleep 3;
    }
}

1;
