package MYDan::Util::Supervisor;
use strict;
use warnings;
use Carp;
use YAML::XS;

use POSIX qw( :sys_wait_h );
use AnyEvent::Loop;
use AnyEvent;

use LWP::UserAgent;

use IPC::Open3;
use Symbol 'gensym';
use Time::TAI64 qw/unixtai64n/;

my %RUN = ( size => 10000000, keep => 5 );
our %time;

our %proc;
sub new
{
    my ( $class, %this ) = @_;
    map{ confess "$_ undef" unless $this{$_}; }qw( cmd log );

    unless( -d $this{log} )
    {
        die "mkdir $this{log} fail: $!" if system "mkdir -p '$this{log}'";
    }
    bless \%this, ref $class || $class;
}

sub run
{
    my $this = shift  @_;
    %RUN = ( %RUN, @_ );

    our ( $cmd, $log, $http, $check ) = @$this{qw( cmd log http check )};

    my ( $i, $cv ) = ( 0, AnyEvent->condvar );

    our ( $logf, $logH ) = ( "$log/current" );
    
    confess "open log: $!" unless open $logH, ">>$logf"; 
    $logH->autoflush;


    $SIG{'CHLD'} = sub {
        while((my $pid = waitpid(-1, WNOHANG)) >0)
        {
            %proc = () if $proc{pid} && $proc{pid} == $pid;
        }
    };

    my $t = AnyEvent->timer(
        after => 2,
        interval => 3,
        cb => sub {
                return if %proc;

                my ( $err, $wtr, $rdr ) = gensym;
                my $pid = IPC::Open3::open3( undef, $rdr, $err, "$cmd" );
           
                print $logH unixtai64n(time), " [START]\n";

                $proc{pid} = $pid;
                $proc{rdr} = AnyEvent->io (
                    fh => $rdr, poll => "r",
                    cb => sub {
                        my $input = <$rdr>; 
                        delete $proc{rdr} and return unless $input;
                        chomp $input;
                        print $logH unixtai64n(time), " [STDOUT] $input\n";
                    }
                );
                $proc{err} = AnyEvent->io (
                    fh => $err, poll => "r", 
                    cb => sub {
                        my $input = <$err>;
                        delete $proc{err} and return unless $input;

                        chomp $input;
                        print $logH unixtai64n(time), " [STDERR] $input\n"; 
                    }
                );

        }
    );

    my $tt = AnyEvent->timer(
        after => 30,
        interval => 60,
        cb => sub {
            my $size = ( stat "$log/current" )[7];
            return unless $size > $RUN{size};
            my $num = $this->_num();
            system "mv '$log/current' '$log/log.$num'";
            
	        confess "open log: $!" unless open $logH, ">>$logf"; 
	        $logH->autoflush;
        }
    );

    my $ht = AnyEvent->timer(
        after => 6,
        interval => 3,
        cb => sub {

            my $ua = LWP::UserAgent->new();
            $ua->agent('Mozilla/9 [en] (Centos; Linux)');
            $ua->timeout( 5 );

            my $res = $ua->get( $http );

            my $status = $check ? ( $res->is_success && $res->content =~ /$check/ ) ? 'ok' : 'fail'
                                : ( $res->code() == 200 ) ? 'ok' : 'fail';


            print $logH unixtai64n(time), " [CHECK] $status\n";
            kill 'KILL', $proc{pid} if $status eq 'fail' && $proc{pid};
             
        }
    ) if $http;


    $cv->recv;
    return $this;
}

sub _num
{
    my ( $log, %time ) = shift->{log};
    for my $num ( 1 .. $RUN{keep} )
    {
       return $num unless $time{$num} = ( stat "$log/log.$num" )[10];
    }
    return ( sort{ $time{$a} <=> $time{$b} } keys %time )[0];
}

1;
