package MYDan::Util::Gateway;
use strict;
use warnings;

use Expect;
use YAML::XS;
use Authen::OATH;
use Convert::Base32 qw( decode_base32 );
use MYDan::Node;
use MYDan::Util::Hosts;

our $TIMEOUT = 20;

=head1 SYNOPSIS

 use MYDan::Util::Gateway;
 MYDan::Util::Gateway->new( '/path/conf');

=cut

sub new
{
    my ( $class, $path ) = @_;

    my $conf = $path && -e $path ? eval{ YAML::XS::LoadFile $path } : +{};
    die "load $path fail:$@" if $@;

    $conf = YAML::XS::Dump $conf;
    map{ $conf =~ s/\$ENV\{$_\}/$ENV{$_}/g; }keys %ENV;
    $conf = eval{ YAML::XS::Load $conf };
    die "load conf fail:$@" if $@;

    my $range = MYDan::Node->new( MYDan::Util::OptConf->load()->dump( 'range') );
    my $hosts = MYDan::Util::Hosts->new();
    for my $k ( keys %$conf  )
    {
        my $v = $conf->{$k};
        next unless my $node = delete  $v->{range};
        delete $conf->{$k};
        map{
            my %v = %$v;
            my %h = $hosts->match( $_ );
            my $n = $h{$_} || $_;
            $v{go} =~ s/{}/$n/g;
            $conf->{"$k:$_"} = \%v;
        }$range->load( $node )->list;
    }

    bless $conf, ref $class || $class;
}

sub _status
{
    my ( $this, $name ) = @_;
    return ( 'undef', 'undef' )unless my $v = $this->{$name};
    my ( $go, $stat, $port ) = $v->{go};
    $stat = 'config nomatch -D 127.0.0.1:\d+' unless $go =~ /-D\s+127.0.0.1:(\d+)\s+/;
    $stat = `lsof -i:$1` ? 'on' : 'off' if $1;
    return ( $stat, $1 );
}

sub status
{
    my $this = shift @_;
    map{
	printf "%s : stat => %s ; port => %s\n", $_, $this->_status($_); 
    }keys %$this;
}

sub on
{
    my ( $this, @name ) = @_;
    @name = keys %$this  unless @name;
    for my $name ( @name )
    {
        my ( $stat, $port ) = $this->_status($name); 
	unless( $stat eq 'off' )
	{
	    printf "%s : stat => %s ; port => %s\n", $name, $stat, $port;
            next;
	}
	$this->go( $name );
	printf "%s : stat => %s ; port => %s\n", $name, $this->_status($name);
    }
}


sub off
{
    my ( $this, @name ) = @_;
    @name = keys %$this  unless @name;
    for my $name ( @name )
    {
        my ( $stat, $port ) = $this->_status($name); 
	unless( $stat eq 'on' )
	{
	    printf "%s : stat => %s ; port => %s\n", $name, $stat, $port;
            next;
	}
	map{ kill 'KILL', $1 if $_ =~ /^ssh\s+(\d+)\s+/  }`lsof -i:$port` if $port =~ /^\d+$/;
	printf "%s : stat => %s ; port => %s\n", $name, $this->_status($name);
    }
}

sub go
{
    my ( $this, $name ) = @_;

    my $conf = $this->{$name};

    my $exp = Expect->new();
    $SIG{WINCH} = sub
    {
        $exp->slave->clone_winsize_from( \*STDIN );
        kill WINCH => $exp->pid if $exp->pid;
        local $SIG{WINCH} = $SIG{WINCH};
    };

    $conf->{expect} = +{} unless $conf->{expect} && ref $conf->{expect} eq 'HASH';

    for ( keys  %{$conf->{expect}} )
    {
        next unless $conf->{expect}{$_} =~ /googlecode\s*:\s*(\w+)/;
	$conf->{expect}{$_} = Authen::OATH->new->totp(  decode_base32( $1 ));
    }

    $exp->slave->clone_winsize_from( \*STDIN );
    print "debug:$conf->{go}\n" if $ENV{MYDan_DEBUG};
    $exp->spawn( $conf->{go} );
    $exp->expect
    ( 
        $TIMEOUT, 
        [ qr/[#\$%] $/ => sub { $exp->interact; } ],
        [ qr/yes\/no/ => sub { $exp->send( "yes\n" ); exp_continue; } ],
	map{ my $v = $conf->{expect}{$_};[ qr/$_/ => sub { $exp->send( "$v\n" ); exp_continue; } ] }keys %{ $conf->{expect} }
    );
}

1;
