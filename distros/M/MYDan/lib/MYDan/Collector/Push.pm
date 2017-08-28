package MYDan::Collector::Push;
use strict;
use warnings;

use Carp;
use YAML::XS;

use Sys::Hostname;
use LWP::UserAgent;

sub new
{
    my ( $class, %this ) = @_;

    map{ confess "$_ undef\n" unless $this{$_} }qw( addr form );
    my $form = $this{form};
    confess "form no HASH" unless ref $form eq 'HASH';
   
    map{
        my $t = $_;
        map{ $this{'index'}{$_} = $t if $form->{$t} eq "\$$_" }qw( node data );
    }keys %$form;

    map{ confess "$_ undef\n" unless $this{'index'}{$_} }qw( node data );

    $this{form}{$this{'index'}{node}} = $ENV{nshostname} ||  hostname;

    $this{ua} = my $ua = LWP::UserAgent->new();
    $ua->proxy( @{$this{proxy}} ) if $this{proxy};
    $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    $ua->timeout( 10 );
    $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );

    map{ $this{load}{$_} = 1 } @{$this{'keys'}} if $this{'keys'};

    return bless \%this, ref $class || $class;
}

sub push
{
    my ( $this, $data, @data ) = splice @_, 0, 2;

    my ( $ua, $addr, $form, $load, $index ) = @$this{ qw( ua addr form load index ) };

    for my $type ( keys %$data )
    {
        map{ push @data, $_ if !$load || $load->{$_->[0][0]}  }@{$data->{$type}};
    }

    my $res = $ua->post(
                  $addr, 
                  +{ %{$form}, $index->{data} => YAML::XS::Dump \@data } 
             );
    printf "push %s\n", $res->is_success ? 'OK' : 'FAIL';
}

1;
