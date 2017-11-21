package MYDan::Util::WhoIs;
use strict;
use warnings;

use MYDan::Node;
use MYDan::Util::Hosts;
use MYDan::Util::OptConf;

=head1 SYNOPSIS

 use MYDan::Util::WhoIs;
 my $w = MYDan::Util::WhoIs->new()

 $w->whois( 'hostname.abc' );
 $w->search( 'abc' );

=cut

sub new
{
    my ( $class, %self ) = shift;

    $self{hosts} = MYDan::Util::Hosts->new();
    $self{cache} = MYDan::Node::DBI::Cache->new( 
	    MYDan::Util::OptConf->load()->{range}{cache} );

    bless \%self, ref $class || $class;
}

sub whois
{
    my ( $this, $name ) = @_;
    return unless $name;

    my ( $cache, $hosts ) = @$this{qw( cache hosts )};

    my %d = $hosts->dump();

    my ( %i, %h ) = ( $name => 1 );

    while( 1 )
    {
        my $c = keys %i;
        for my $name ( grep{ $_ !~ /^\d+\.\d+\.\d+\.\d+$/ }keys %i )
        {
             $name =~ s/^[nw]{1}\d*-//;
             map{ $i{$_} = 1 if $_ eq $name || $_ =~ /^[nw]{1}\d*-$name$/ }$hosts->hosts();
        }

        while( my @d = each %d )
        {
	    if( grep{ $_ eq $d[0] || $_ eq $d[1] }keys %i )
	    {
	        map{$i{$_} = 1}@d;
		$h{$d[0]} = $d[1];
	    }
        }
        
        last if $c == keys %i;
    }
    
    return ( cluster => [ $cache->select( '*',  node => [ 1 => keys %i ] ) ], hosts => \%h );
}

sub search
{
    my ( $this, $name ) = @_;
    return unless $name;

    my ( $cache, $hosts ) = @$this{qw( cache hosts )};

    my ( %d, %h ) = $hosts->dump();
    while( my @d = each %d )
    {
        $h{$d[0]} = $d[1] if grep{ $_ =~ /$name/ }@d;
    }
 
    return ( cluster => [ grep{$_->[2] =~ /$name/ }$cache->select( '*' ) ], hosts => \%h );
}

1;
