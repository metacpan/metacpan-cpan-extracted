package MYDan::Util::Go;
use strict;
use warnings;

use Expect;
use YAML::XS;
use Authen::OATH;
use Convert::Base32 qw( decode_base32 );

our $TIMEOUT = 20;

=head1 SYNOPSIS

 use MYDan::Util::Go;
 MYDan::Util::Go->new( '/path/go')->go( 'grep' );

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

sub go
{

    my ( $this, $grep ) = @_;

    my @host = sort keys %$this;

    GOTO:

    @host = grep{ $_ =~ /$grep/ }@host if defined $grep;

    return unless @host;

    my $i = 0;
    if( @host > 1 )
    {
        my @host = map { sprintf "[ %d ] %s", $_ + 1, $host[$_] } 0 .. $#host; 
        print STDERR join "\n", @host, "please select: [ 1 ] ";

        my $x = <STDIN>;
        if( $x && $x =~ s/^\/// ) { $grep = $x; chomp $grep; goto GOTO; }
        $i = $1 - 1 if $x =~ /(\d+)/ && $1 && $1 <= @host;
    }

    my $conf = $this->{$host[$i]};

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
