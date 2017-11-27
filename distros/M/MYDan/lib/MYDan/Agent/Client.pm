package MYDan::Agent::Client;

=head1 NAME

MYDan::Agent::Client

=head1 SYNOPSIS

 use MYDan::Agent::Client;
 my $client = MYDan::Agent::Client->new( [ 'node1', 'node2' ] );
 my %result = $client->run( timeout => 300, input => '' ); 

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;
use File::Spec;
use File::Basename;
use FindBin qw( $RealBin );
use YAML::XS;

use MYDan::Agent::Query;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Time::HiRes qw(time);

use MYDan::API::Agent;
use MYDan::Util::Percent;
use MYDan::Agent::Proxy;
use MYDan::Util::Hosts;

our %RUN = ( user => 'root', max => 128, timeout => 300 );

sub new
{
    my $class = shift;
    bless +{ node => \@_ }, ref $class || $class;
}

sub run
{
    my ( $this, %run, %result ) = ( shift, %RUN, @_ );

    return unless my @node = @{$this->{node}};

    my $percent =  MYDan::Util::Percent->new( scalar @node, 'run ..' );

    my %proxy;
    if( $run{proxy} )
    {
        my $proxy =  MYDan::Agent::Proxy->new( $run{proxy} );
        %proxy = $proxy->search( @node );
    }
    else { %proxy  = map{ $_ => undef }@node; }

    my $isc = $run{role} && $run{role} eq 'client' ? 1 : 0;

    my $query;
    unless( $query = $run{queryx} )
    {
        $run{query}{node} = \@node if $isc;

        $query = MYDan::Agent::Query->dump($run{query});

        eval{ $query = MYDan::API::Agent->new()->encryption( $query ) if $isc };
        if( $@ )
        {
            warn "ERROR:$@\n";
            return map{ $_ => "norun --- 1\n" }@node;
        }
    }

    @node = (); my %node;

    while( my( $n, $p ) = each %proxy )
    {
        if( $p ) { push @{$node{$p}}, $n; }
        else { push @node, $n; }
    }

    my $cv = AE::cv;
    my ( @work, $stop );

    $SIG{TERM} = $SIG{INT} = my $tocb = sub
    {
        $stop = 1;
        for my $w ( @work )
        {
            next unless $$w && $$w->fh;
            $$w->destroy;
            $cv->end;
        }

        map{ $cv->end; } 1 .. $cv->{_ae_counter}||0;
    };

    my %hosts = MYDan::Util::Hosts->new()->match( @node );
    my $work;$work = sub{
        return unless my $node = shift @node;
        $result{$node} = '';
        
        $cv->begin;
        tcp_connect $hosts{$node}, $run{port}, sub {
             my ( $fh ) = @_;
             unless( $fh ){
		 $percent->add()->print() if $run{verbose};
                 $result{$node} = "tcp_connect: $!";
                 $work->();
                 $cv->end;
                 return;
             }
             if( $stop )
             {
                 close $fh;
                 return;
             }

             my $hdl;
             push @work, \$hdl;
             $hdl = new AnyEvent::Handle(
                 fh => $fh,
                 on_read => sub {
                     my $self = shift;
                     $self->unshift_read (
                         chunk => length $self->{rbuf},
                         sub { $result{$node} .= $_[1];}
                     );
                  },
                  on_eof => sub{
                      undef $hdl;
		      $percent->add()->print() if $run{verbose};
                      $work->();
                      $cv->end;
                  }
             );
             $hdl->push_write($query);
             $hdl->push_shutdown;
          };
    };

    my $max = scalar @node > $run{max} ? $run{max} : scalar @node;
    $work->() for 1 .. $max ;

    my %rresult;
    my $rwork = sub{
        my $node = shift;
        $cv->begin;

        my @node = @{$node{$node}};
        map{ $result{$_} = '' }@node;

        my %rquery = ( 
            code => 'proxy', 
            argv => [ \@node, +{ query => $query, map{ $_ => $run{$_} }grep{ $run{$_} }qw( timeout max port ) } ],
	    map{ $_ => $run{query}{$_} }qw( user sudo env ) 
        );

        $rquery{node} = [ $node ] if $isc;

        my $rquery = MYDan::Agent::Query->dump(\%rquery);
    
        eval{ $rquery = MYDan::API::Agent->new()->encryption( $rquery ) if $isc };
        if( $@ )
        {
            warn "ERROR:$@\n";
            map{ $result{$_} = "norun --- 1\n" }@node;
            return;
        }

        tcp_connect $node, $run{port}, sub {
             my ( $fh ) = @_;
             unless( $fh ){
                 $cv->end;
		 $percent->add( scalar @node )->print() if $run{verbose};
                 map{ $result{$_} = "proxy $node fail tcp_connect: $!" }@node;
                 return;
             }
             if( $stop )
             {
                 close $fh;
                 return;
             }

             my $hdl;
             push @work, \$hdl;
             $hdl = new AnyEvent::Handle(
                 fh => $fh,
                 on_read => sub {
                     my $self = shift;
                     $self->unshift_read (
                         chunk => length $self->{rbuf},
                         sub { $rresult{$node} .= $_[1];}
                     );
                  },
                  on_eof => sub{
                      undef $hdl;
		      $percent->add(scalar @node)->print() if $run{verbose};
                      $cv->end;

                      unless( $rresult{$node} )
                      {
                          map{ $result{$_} = "proxy $node result null" }@node;
                          return;
                      }

                      $rresult{$node}  =~ s/^\**#\*MYDan_\d+\*#//;
                      my @c = eval{ YAML::XS::Load $rresult{$node} };

                      my $error = $@ ? "\$@ = $@" :
                             @c != 2 ? "\@c count != 2": 
                          $c[1] != 0 ? "exit != 0" :
   (  $c[0] && ref $c[0] eq 'HASH' ) ? undef : "no hash";

                      if( $error )
                      {
                          warn "call proxy result no good: $error\n";
                          map{ $result{$_} = "proxy $node result format error" }@node;
                          return;
                      }

                      map
                      {
			  $result{$_} = exists $c[0]{$_} ? $c[0]{$_} : "no any result by proxy $node";
                      }
                      @node;
                      
                      return;
                  },

                  on_error => sub {
                      close $fh;
                      map { $result{$_} = "no_error by proxy $node"; } @node;
                  }
             );
             $hdl->push_write($rquery);
             $hdl->push_shutdown;
          };
    };

    #Don't change it to map
    foreach( keys %node ) { $rwork->( $_ ); }

    my $w = AnyEvent->timer ( after => $run{timeout},  cb => $tocb );

    $cv->recv;
    undef $w;

    if( $run{version} )
    {
        map{ $_ =~ s/^\**#\*MYDan_(\d+)\*#/runtime version:$1\n/;}values %result;
    }
    else { map{ $_ =~ s/^\**#\*MYDan_\d+\*#//;}values %result; }

    return %result;
}

1;
