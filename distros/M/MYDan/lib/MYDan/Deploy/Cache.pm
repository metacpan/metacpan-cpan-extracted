package MYDan::Deploy::Cache;
use strict;
use warnings;
use Carp;

use YAML::XS;

use Data::Dumper;

sub load
{
    my ( $class, $cache, $maint ) = splice @_;

    confess "no code" unless $cache;

    $cache  = eval{ YAML::XS::LoadFile $cache };
    confess "load cache error: $@" if $@;
    confess "cache not HASH" if ref $cache ne 'HASH';


    my ( $node, $step, $glob ) 
        = map{ $cache->{$_} || confess "no find $_"  }qw( node step glob );
     

    confess "maint & step & glob no match"
        unless @$maint == @$step && @$step == @$glob;    

    for my $i ( 0 .. @$step -1 )
    {
        my $error =  "mould is error no step#$i";
        my ( $g, $t ) = map{ $maint->[$i]{$_} || 0 }qw( global title );

        confess "$error: title no match $t ne $step->[$i]" if $t ne $step->[$i];

        confess "$error: global no match" if $g ne $glob->[$i];
    }

    return $cache;
}

1;
