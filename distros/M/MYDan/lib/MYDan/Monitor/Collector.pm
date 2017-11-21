package MYDan::Monitor::Collector;

=head1 NAME

MYDan::Monitor::Collector

=head1 SYNOPSIS

 use MYDan::Monitor::Collector;
 my $collector = MYDan::Monitor::Collector->new( [ 'node1', 'node2' ] );
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

our %RUN = ( user => 'root', max => 128, timeout => 300 );

my ( %agent, %monitor ); 
BEGIN{ 
    %agent = MYDan::Util::OptConf->load()->dump('agent');
    %monitor = MYDan::Util::OptConf->load()->dump('monitor');
};

sub new
{
    my $class = shift;
    bless +{ node => \@_ }, ref $class || $class;
}

sub _query
{
    my ( $this, $node ) = @_;

    my %query = ( code => 'collector', user => 'monitor', argv => [ +{ conf => YAML::XS::LoadFile "$monitor{make}/$node" }] );
    my $query = MYDan::Agent::Query->dump(\%query);
    return $query;
}

sub run
{
    my ( $this, %run, %result ) = ( shift, %RUN, @_ );

    return unless my @node = @{$this->{node}};

    my $cv = AE::cv;

    my $work;$work = sub{
        return unless my $node = shift @node;
        $result{$node} = '';
        
        $cv->begin;
        tcp_connect $node, $agent{port}, sub {
             my ( $fh ) = @_;
             unless( $fh ){
                 $cv->end;
                 $result{$node} = "tcp_connect: $!";
                 $work->();
                 return;
             }
             my $hdl; $hdl = new AnyEvent::Handle(
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
                      $cv->end;
                      $work->();
                  }
             );
             $hdl->push_write($this->_query( $node ));
             $hdl->push_shutdown;
          };
    };

    my $max = scalar @node > $run{max} ? $run{max} : scalar @node;
    $work->() for 1 .. $max ;

    $cv->recv;
    map{ $_ =~ s/^\**#\*MYDan_\d+\*#//;}values %result;
    return %result;
}

1;
