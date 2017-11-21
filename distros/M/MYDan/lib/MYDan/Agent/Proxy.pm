package MYDan::Agent::Proxy;

=head1 NAME

MYDan::Agent::Proxy

=head1 SYNOPSIS

 use MYDan::Agent::Proxy;
 my $proxy = MYDan::Agent::Proxy->new( '/conf/file' );
 my %r = $proxy->search( 'node1', 'node2', '10.10.0.1', '10.10.0.2' );
 
 %r = (
      node1 => undef, node2 => undef,
      '10.10.0.1' => 'proxyip',
      '10.10.0.2' => 'proxyip',
 );

=cut

use strict;
use warnings;

use Carp;
use YAML::XS;
use Net::IP::Match::Regexp qw( match_ip create_iprange_regexp_depthfirst );
use Data::Validate::IP qw( is_ipv4 );
use Socket;

sub new
{
    my ( $class, $conf ) = @_;
    confess "no conf" unless $conf && -e $conf;

    eval { $conf = YAML::XS::LoadFile( $conf ) };

    confess "error: $@" if $@;
    confess "error: not HASH" if ref $conf ne 'HASH';

    bless $conf, ref $class || $class;
}

sub search
{
    my ( $this, @node, %innet ) = @_;

    for ( keys %$this )
    {
        next unless $_ =~ /^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})\s*$/;
	$innet{$_} = $this->{$_} if is_ipv4( $1 ) && $2 >=0 && $2 <= 32;
    }

    return map{ $_ => undef }@node unless %innet;

    my $regexp = create_iprange_regexp_depthfirst( \%innet );

    my %hosts = MYDan::Util::Hosts->new()->match( @node );
    map{
        $hosts{$_} = inet_ntoa( gethostbyname $_ ) 
	    unless is_ipv4( $hosts{$_} )
    }keys %hosts;

    return map{ $_ => match_ip( $hosts{$_}, $regexp )}@node;
}

1;
