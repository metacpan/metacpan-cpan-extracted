package MYDan::Collector::Stat::Cache;

use strict;
use warnings;
use Carp;
use POSIX;

use MYDan::Bone::Redis;
use Data::Dumper;

use YAML::XS;

sub co
{
    my ( $this, %cache, @stat ) = shift;

    map{ $cache{$1} = 1 if $_ =~ /^\{CACHE:([\w:_]+)\}\{/ }@_;
    my $redis = MYDan::Bone::Redis->new("read");
    my @keys = keys %cache;
    my @mesg = $redis->mget( @keys );

    for( 0 .. @keys -1 )
    {
        next unless $mesg[$_];
        my $data = eval{ YAML::XS::Load $mesg[$_] };
        next unless ref $data eq 'ARRAY' && ref $data->[0] eq 'ARRAY';
        $data->[0][0] = "CACHE:$keys[$_]";
        push @stat, $data;
    }

    return @stat;
}

1;
