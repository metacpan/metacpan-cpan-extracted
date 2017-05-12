package MColPro::Claim;

use strict;
use warnings;

use Carp;
use YAML::XS;
use Data::Dumper;

sub new
{
    my ( $this, $conf, $sqlbase ) = @_;

    my %class;
    $class{mysql} = $sqlbase;
    $class{claim} = $conf->{claim};

    my $i = 0;
    map { $class{column}{$_} = $i++ }
        qw( host type claim time );

    bless \%class, ref $this || $this;
}

sub get_batch
{
    my ( $this, $type, $hosts ) = @_;

    my %result;
    my $sql = "select host,claim from %s where type='%s' and host in ( %s )";
    return \%result unless @$hosts;

    $sql = sprintf( $sql, $this->{claim}, $type,
        join ( ',', map { "\"$_\"" } @$hosts) );

    $this->{mysql}->dbquery( $sql );
    my $record_set = $this->{mysql}->create_record_iterator;
    return \%result unless $record_set;
    while ( my $record = $record_set->each )
    {
        my $c = eval { YAML::XS::Load( $record->[1] ) };
        $result{$record->[0]} = $c if $c;
    }

    return \%result;
}

sub set_batch
{
    my ( $this, $type, $config ) = @_;
    return 1 unless $type;
    my $sql = "INSERT INTO %s(host,type,claim) values(\"%s\", \"%s\",\"%s\") ON DUPLICATE KEY UPDATE claimback=`claim`,claim=\"%s\"";

    while( my ( $n, $v ) = each %$config )
    {
        my $y = YAML::XS::Dump( $v );
        my $s = sprintf( $sql, $this->{claim},
            $n, $type, $y, $y );
        $this->{mysql}->dbquery( $s );
    }
    
    return 1;
}

# 在给定一组机器配置中找到相同的配置
# 解决新加机器没有监控配置的问题
sub find_same
{
    my ( $this, $param ) = @_;
    my %tmph;
    my %tmpa;
    my $count = scalar keys %$param;
    ## 超过半数机器都有的配置就加入新机器配置中
    $count = $count < 3 ? 0 : $count / 2;
    my $config;
    
    while( my ( $node, $conf ) = each %$param )
    {
        if( ref $conf eq 'HASH' )
        {
            map
            {
                $tmph{$_}{$conf->{$_}}++;
            } keys %$conf;
        }
        elsif( ref $conf eq 'ARRAY' )
        {
            map
            {
                $tmpa{$_}++;
            } @$conf;
        }
    }

    if( keys %tmph )
    {
        $config = {};
        for my $x ( keys %tmph )
        {
            for my $y ( keys %{ $tmph{$x} } )
            {
                $config->{$x} = $y if $tmph{$x}{$y} > $count;
            }
        }

        return $config;
    }

    if( keys %tmpa )
    {
        $config = [];

        for my $x ( keys %tmpa )
        {
            push @$config, $x if $tmpa{$x} > $count;
        }

        return $config;
    }

    return undef;
}

1;
