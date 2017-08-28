package MYDan::Monitor::Make;
use strict;
use warnings;
use Carp;
use YAML::XS;

use File::Basename;
use POSIX qw( :sys_wait_h );
use Data::Dumper;
use MYDan::Node;
use MYDan::Subscribe;

our %c = ( code => 'stat', timeout => 60, interval => 60 );

sub new
{
    my ( $class, %this ) = @_;
    map{ 
        die "$_ undef." unless $this{$_};
        system( "mkdir -p '$this{$_}'" ) unless -e $this{$_};
    }qw( make conf );

    $this{subscribe} = MYDan::Subscribe->new();

    bless \%this, ref $class || $class;
}

sub make
{
    my ( $this, @node, %skip, %node, %collect ) = @_;
    my ( $make, $conf, $subscribe, $option ) = @$this{qw( make conf subscribe option )};

    
    my %n = map{ $_ => 1 }@node;
    for my $file ( glob "$conf/collect/*" )
    {
       my $name = basename $file;

       $collect{$name} = eval{ YAML::XS::LoadFile $file };

       if( $@ )
       {
           my $project = ( $name =~ /:(.+)$/ ) ? $1 : $name;
           $skip{$project} = 1;
           $subscribe->input( $project, 'error', "laod $name error" );
       }
    }


     for ( MYDan::Node->new( $option->dump( 'range' ) )->db()->select( 'name,attr,node,info' ) )
     {
         my ( $name, $attr, $node, $info ) = @$_;
         $node{$node}{$name}{$attr} = 1
     }

    for my $node ( keys %node )
    {
        next unless $n{$node};
        my @name = sort keys %{$node{$node}};
        next if grep{ $skip{$_} }@name;

        my %config;
        for my $name ( @name )
        {
            %config = ( %config, %{$collect{$name}} ) if $collect{$name};
            map{  %config = ( %config, %{$collect{"$name:$_"}} )  if $collect{"$name:$_"}  }
                sort keys %{$node{$node}{$name}}
        }
        eval{ YAML::XS::DumpFile "$make/$node", 
            +{ 
                conf => +{ 
                    stat => +{ 
                        code => 'stat', 
                        timeout => 60, 
                        interval=> 60, 
                        param =>+{ test => \%config }
                    } 
                }, 
                target => $node 
            } 
        };
        if( $@ )
        {
            map{ $subscribe->input( $_, 'error', "dump $node error" ); }@name;
        }
    }

}

1;
