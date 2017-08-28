package MYDan::Subscribe::Conf;
use strict;
use warnings;
use Carp;
use YAML::XS;

use Data::Dumper;
use POSIX;

use MYDan::Util::OptConf;
use File::Basename;
use MYDan::Subscribe::DBI::DB;
use MYDan::Notify;

sub new
{
    my ( $class, %this ) = @_;

    die "path undef" unless $this{path};
    $this{db} =  MYDan::Subscribe::DBI::DB->new(
        $this{path},
        $MYDan::Subscribe::DBI::DB::TABLE
    );

    bless \%this, ref $class || $class;
}

sub insert
{
    my ( $this, %param ) = @_;
    $this->{db}->insert( @param{qw( name attr user level)} );
}

sub select
{
    my ( $this, %param, %query ) = @_;

    map{ $query{$_} = [ 1, $param{$_} ] if $param{$_} }qw( name attr user level);
    $this->{db}->select( '*', %query );
}

sub delete
{
    my ( $this, %param, %query ) = @_;

    map{ $query{$_} = [ 1, $param{$_} ] if $param{$_} }qw( name attr user level);
    $this->{db}->delete( %query );
}

sub get
{
    my ( $this, %param, @r, %r ) = @_;
    my ( $name, $attr ) = map{ $param{$_} ||= 'null' }qw( name attr );
    for my $x ( $this->select() )
    {
        next unless _match( $name, $x->[0] ) && _match( $attr, $x->[1] );
        my $len = length "$x->[0]$x->[1]";
        $r{$x->[2]} = +{ len => $len, res => $x } 
            if ! $r{$x->[2]}{len} || ( $r{$x->[2]}{len} &&  $r{$x->[2]}{len} <= $len );
    }
    return map{ $_->{res} } values %r;
}

sub _match
{
    my ( $s, $m ) = @_;
    return ( ( $s eq $m || '*' eq $m ) || ( $m =~ s/\*/\\w\+/g && $s =~ /$m/ ) ) ? 1 : 0;
}

1;
