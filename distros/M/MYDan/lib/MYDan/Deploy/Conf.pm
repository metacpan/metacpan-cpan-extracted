package MYDan::Deploy::Conf;

=head1 NAME

MYDan::Deploy::Conf - Load/Inspect maintenance configs

=head1 SYNOPSIS

 use MYDan::Deploy::Conf;

 my $conf = MYDan::Deploy::Conf->new( $name )->dump( \%macro );

=cut
use strict;
use warnings;

use Data::Dumper;

use Carp;
use YAML::XS;
use Tie::File;

=head1 CONFIGURATION

YAML file that defines sets of maintenance parameters index by names.
Each set defines the following parameters:

 target : targets of maintenance, to be devided into batches.
 maint : name of maintainance code.
 batch : name of batch code.
 param : ( optional ) parameters of batch code.

=cut
#our @PARAM = qw( target maint batch );

sub new
{
    my ( $class, $name, $path ) = splice @_;
   
    map{ confess "no path $path->{$_}" unless -d $path->{$_} }qw( mould conf );

    my $conf =  eval { YAML::XS::LoadFile( "$path->{conf}/$name" ) };
    confess "load conf error: $@" if $@;

    confess "tie conf fail: $!" unless tie my @conf, 'Tie::File', "$path->{conf}/$name";
    my $s_conf = join "\n", @conf;

    return bless +{ path => $path, conf => $conf, s_conf => $s_conf }, ref $class || $class;
}

sub dump
{
    my ( $this, $macro ) = @_;
    my ( $path, $conf, $s_conf ) = @$this{qw( path conf s_conf )};

    if( my $dm = delete $conf->{macro} )
    {
        confess "default macro no HASH in conf" if ref $dm ne 'HASH';
        map{ $macro->{$_} = $dm->{$_} unless defined $macro->{$_} }keys %$dm;
    }
    
    $conf = $s_conf;

    map{ $conf =~ s/\$env\{$_\}/$macro->{$_}/g; }keys %$macro if $macro;

    my @env = $conf =~ /(\$env\{.*\})/g;

    exit 0 if @env && printf "env no replace on conf: %s\n", join ' ', @env;

    $conf = eval{ YAML::XS::Load $conf };
    confess "load conf error: $@" if $@;

    map{ confess "$_ undef in conf" unless $conf->{$_} }qw( batch maint );
    confess "batch's code undef in conf" unless $conf->{batch}{code};
    confess "maint's mould undef in conf" unless $conf->{maint}{mould};
    

    my $mouldfile =  "$path->{mould}/$conf->{maint}{mould}";
    confess "no the mould file\n" unless -f $mouldfile;
    confess "tie mould fail: $!" unless tie my @maint, 'Tie::File', $mouldfile;

    my $maint = join "\n", @maint;

    my $m = $conf->{maint}{macro};
    map{ $maint =~ s/\$env\{$_\}/$m->{$_}/g; }keys %$m if $m;
    my @e = $maint =~ /(\$env\{.*\})/g;

    confess sprintf "env no replace on maint: %s\n", join ' ', @e if @e;

    $maint = eval{ YAML::XS::Load $maint };
    confess "load conf error: $@" if $@;

    confess "maint no ARRAY" if ref $maint ne 'ARRAY';

    my %title;
    my %code = ( $conf->{batch}{code} => 1 );
    map
    {
        $title{ $maint->[$_-1]->{title} ||= "job.$_" } ++;
        $code{$maint->[$_-1]->{code}} = 1;
    }1.. @$maint;
    
    my @redef = grep{ $title{$_} > 1 }keys %title;
    confess sprintf "maint title ref: %s", join ' ' , @redef if @redef;

    return $conf, $maint, \%code;
}

#
#sub check
#{


#    my ( $self, $conf ) = splice @_;
#    map { die "$_ not defined" if ! $conf->{$_} } @PARAM;
#}
#
#=head1 METHODS
#
#=head3 dump( @name )
#
#Returns configurations indexed by @name.
#
#=cut
#sub dump
#{
#    my $self = shift;
#    my @conf = return @$self{@_};
#    return wantarray ? @conf : shift @conf;
#}
#
#=head3 names
#
#Returns names of all maintenance.
#
#=cut
#sub names
#{
#    my $self = shift;
#    return keys %$self;
#}
#
1;
