package MYDan::Collector::Show;
use strict;
use warnings;

use Carp;
use YAML::XS;

use Digest::MD5;
use Sys::Hostname;

use threads;
use Thread::Queue;

use Data::Dumper;
use POSIX;

use Socket;
use IO::Handle;

sub new
{
    my ( $class, %this ) = @_;

    $this{name} = '' unless $this{name} && $this{name} =~ /^[\w_]+$/;

    map{
        $this{$_} = "$this{$_}_$this{name}" if $this{name}; 
        confess "no $_\n" unless $this{$_} && -d $this{$_};
    }qw( logs data );

    return bless \%this, ref $class || $class;
}

sub show
{
    my ( $this, @show ) = @_;
    @show ? $this->hist( @show ): $this->curr();
    return $this;
}

sub curr
{
    my ( $this, $data, $time ) = shift;

    if( $this->{sock} || $this->{ring} )
    {
        $data = sprintf "$this->{data}/%s.sock",  $this->{sock} ? 'output' : 'ring';
        unless( -S $data )
        {
            warn "no sock\n"; return $this;
        }

        socket(my $sock, PF_UNIX, SOCK_STREAM, 0);
        connect($sock, sockaddr_un($data)) or die "Connect: $!\n";
        $sock->autoflush(1);
        $data = join '', my @buf = <$sock>;
        close $sock;
        $data = eval{ YAML::XS::Load $data };
        if( $@ ) { warn "syntax err:$@\n"; return $this; }
        $time = POSIX::strftime( "%Y-%m-%d_%H:%M:%S", localtime );
    }
    else
    {
        $data = "$this->{data}/output";
        
        unless( -f $data )
        {
            warn "no data\n"; return $this;
        }

        $time = POSIX::strftime( "%Y-%m-%d_%H:%M:%S", localtime( (stat $data)[9] ) );

        $data = eval{ YAML::XS::LoadFile $data };
        if( $@ ) { warn "syntax err:$@\n"; return $this; }
    }

#    unless ( $data = $data->{data} )
#    {
#        warn "no data in yaml\n";return $this;
#    }

    if( ref $data eq 'HASH' )
    {
        for( keys %$data )
        {
            my $stat = $data->{$_};
            if( ref $stat ne 'ARRAY' )
            {
                warn "syntax err:$_\n";next;
            }
            map{ map{ printf "$time\t%s\n", join "\t", map{defined $_ ? $_:''}@$_ }@$_;print "\n"; }@$stat;
            printf "\n%s\n\n", join ',', map{ $_->[0][0] }@$stat;
        }
    }
    else
    {
        for my $s ( @$data )
        {
            next unless ref $s eq 'ARRAY';
            my ( $d, $t ) = @$s;
            next unless ref $d eq 'ARRAY';
            map{map{ print "$t\t";map{  print defined $_ ? $_:'',"\t"}@$_; print "\n";}@$_}@$d;
        }
    }
    return $this;
}

sub hist
{
    my $this = shift;
    my $logs = $this->{logs};
    my %show = map{ $_ => 1 }@_;

    my %hist = map{ $_ => ( stat $_ )[9] }grep{ /\/output\.\d+$/ }glob "$logs/output.*";

    map{
        my $time =  POSIX::strftime( "%Y-%m-%d_%H:%M:%S", localtime(  $hist{$_} ) );

        eval{

            my $data = YAML::XS::LoadFile $_;
#            $data = $data->{data};
            for my $stat( values %$data )
            {
                next unless ref $stat eq 'ARRAY';
                map{ my $t = $stat->[$_]; map{ printf "$time\t%s\n", join "\t", @$_;}@$t; }
                grep{ $show{$stat->[$_][0][0]} } 0 .. @$stat -1;
                
            }
        };
        

    }sort{ $hist{$b} <=> $hist{$a} }keys %hist;
    
    return $this;
}

1;
