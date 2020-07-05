package MYDan::MonitorV2::Collector;

=head1 NAME

MYDan::MonitorV2::Collector

=head1 SYNOPSIS

 use MYDan::MonitorV2::Collector;
 my $collector = MYDan::MonitorV2::Collector->new( %o, name => shift );
 $collector->run(); 

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;
use Time::HiRes qw(time);
use FindBin qw( $RealBin );
use MYDan::Node;
use MYDan::Subscribe;
use MYDan::Util::OptConf;

sub new
{
    my ( $class, %self ) = @_;

    map{ die "$_ undef" unless $self{$_} }qw( conf code name run );
    $0 = "MYDan.monitorv2.collector.$self{name}";

    $self{tmp} = "$self{run}/$self{name}";
    $self{config} = eval{ YAML::XS::LoadFile "$self{conf}/$self{name}" };
    die "load fail:$@" if $@;

    map{ die "$_ undef" unless $self{config}{$_} }qw( code interval target param );
    $self{code} = do "$self{code}/$self{config}{code}";
    die "load code fail" unless $self{code} && ref $self{code} eq 'CODE';

    bless \%self, ref $class || $class;
}

sub run
{
    my ( $this, %ERR ) = shift;
    print "start..\n";


    while( 1 )
    {
        my $time = time;
        my ( $config, $code, $conf, $name, $tmp ) = @$this{qw( config code conf name tmp )};

        print "check config: begin.\n";
        my $newconfig = eval{ YAML::XS::LoadFile "$conf/$name" };
        die "load config $conf/$name: $@\n" if $@;
        die "config has been updated. exit.\n" 
            unless ( YAML::XS::Dump $newconfig ) eq ( YAML::XS::Dump $config );
        print "check config: done.\n";

        my $option = MYDan::Util::OptConf->load();
        my $range = MYDan::Node->new( $option->dump( 'range' ) );
        my $cache = MYDan::Node::DBI::Cache->new( $option->{range}{cache} );

        print "batch: begin.\n";
	    my @node = $range->load( $config->{target} )->list;
        print "batch: done.\n";


        print "collector: begin.\n";
        my %err = @node
                   ? &$code( %{$config->{param}}, node => \@node )
                   : ( 'mydan.monitorv2###sys###err' => 'NoNode' );
        print "collector: done.\n";

        print "analysis: begin.\n";
        my %allkey = ( %err, %ERR );

        for my $key ( keys %allkey )
		{
			$ERR{$key} = [] unless defined $ERR{$key};
			unshift @{$ERR{$key}}, $err{$key} ? 1 : 0;
		}

		for my $key ( keys %ERR )
		{
			pop( @{$ERR{$key}} ) if scalar( @{$ERR{$key}} ) >= 11;
			delete $ERR{$key} unless grep{ $_ }@{$ERR{$key}};
		}
        
        my ( %hostc, %count );
        map{
            $hostc{$_->[2]}{$_->[0]}{$_->[1]} = 1;
            $count{$_->[0]}{$_->[1]}{$_->[2]} = 1;
        }$cache->select( '*' );
        
		my ( %currerror, %temp );
		for my $key ( keys %ERR )
		{
			my ( $node, $group, $test ) = split '###', $key, 3;

			if( $key =~ / (\d+)\/(\d+)$/ )
			{
				my ( $a, $b ) = ( $1, $2 );
				$b = 10 if $b >= 10;
				my $count = scalar grep{ $ERR{$key}[$_] } 0.. $b - 1;
				$currerror{$key}++ if $count >= $a;
			}
			else
			{
				$currerror{$key}++;
			}
		}

		for my $key ( keys %currerror )
		{
			my ( $node, $group, $test ) = split '###', $key, 3;
			unless( $hostc{$node} )
			{
				$temp{$group}{$test}{'null'}{'null'}{$node} ++;
				next;
			}
			for my $name ( keys %{$hostc{$node}} )
			{
				map{
					$temp{$group}{$test}{$name}{$_}{$node} ++;
				}keys %{$hostc{$node}{$name}}
			}
		}
        
        my $subscribe = MYDan::Subscribe->new();
        for my $group ( keys %temp )
        {
            for my $err ( keys %{$temp{$group}} )
            {
                for my $name ( keys %{$temp{$group}{$err}} )
                {
                    for my $attr ( keys %{$temp{$group}{$err}{$name}} )
                    {
                        my @errhost = keys %{$temp{$group}{$err}{$name}{$attr}};
                        my @attrhost = ( $name eq 'null' && $attr eq 'null' )
                                     ? ( @errhost ) : ( keys %{$count{$name}{$attr}} );
                        my $scale = sprintf "%d/%d", scalar( @errhost ), scalar( @attrhost );
        
                        $subscribe->input( "name:$name attr:$attr scale:($scale) strategy: $err node:" 
                            .join( ',', sort @errhost ), $name, $attr );
                    }
                }
            }
        }

        print "dump: begin.\n";
        eval{ YAML::XS::DumpFile $tmp, \%err };
        print "Dump Fail: $@\n" if $@;
        print YAML::XS::Dump \%err;
        print "dump: done.\n";

  	    my $due = $time + $config->{interval} - time;
		sleep $due if $due > 0;
    }
}

1;
