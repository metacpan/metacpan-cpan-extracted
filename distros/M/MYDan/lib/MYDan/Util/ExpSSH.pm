package MYDan::Util::ExpSSH;

use strict;
use warnings;

use Expect;
use MYDan;
use MYDan::Node;
use MYDan::Util::OptConf;
use MYDan::Util::Pass;
use MYDan::Util::Hosts;
use MYDan::Util::Alias;
use MYDan::Util::Proxy;

use Authen::OATH;
use Convert::Base32 qw( decode_base32 ); 

our $TIMEOUT = 20;
our $SSH;
our $RSYNC;

BEGIN{
    my $alias = MYDan::Util::Alias->new();
    $RSYNC = $alias->alias( 'rsync' ) || 'rsync';
    $SSH =  $alias->alias( 'ssh' ) || 'ssh' . ' -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1';
};

=head1 SYNOPSIS

 use MYDan::Util::ExpSSH;

 my $ssh = MYDan::Util::ExpSSH->new( );

 $ssh->conn( host => 'foo', user => 'joe', 
             pass => '/conf/file', 
             sudo => 'user1',
             rsync => '-aP /tmp/foo user@host:/tmp/bar', #if rsync
           );

=cut

sub new
{
    my $class = shift;
    bless +{}, ref $class || $class;
}

sub conn
{
    my ( $self, %conn, $grep ) = splice @_;

    my $hosts = MYDan::Util::Hosts->new();
    my @host = $conn{rsync} ? ( $conn{host} ) : $self->host( $hosts, $conn{host} );

    GOTO:

    @host = grep{ $_ =~ /$grep/ }@host if defined $grep;
    return unless @host;

    my $i = 0;
    if ( @host > 1 )
    {
        my @host = map { sprintf "[ %d ] %s", $_ + 1, $host[$_] } 0 .. $#host; 
        print STDERR join "\n", @host, "please select: [ 1 ] ";

        my $x = <STDIN>;
        if( $x && $x =~ s/^\/// ) { $grep = $x; chomp $grep; goto GOTO; }
        $i = $1 - 1 if $x =~ /(\d+)/ && $1 && $1 <= @host;
    }

    my ( undef, $pass ) = MYDan::Util::Pass->new( conf => $conn{pass} )
        ->pass( [ $host[$i] ] => $conn{user} );

    if( $pass && ref $pass )
    {
        my $default = delete $pass->{default};
        my ( $j, @user ) = ( 0, keys %$pass );

        if( @user == 1 )
        {
            $conn{user} = $user[0];$pass = $pass->{$user[0]};
        }
        elsif ( @user  > 1 )
        {
            my @u = map { sprintf "[ %d ] %s", $_ + 1, $user[$_] } 0 .. $#user;
            print STDERR join "\n", @u, "please select: [ 1 ] ";
            $j = $1 - 1 if <STDIN> =~ /(\d+)/ && $1 && $1 <= @user;
            $conn{user} = $user[$j];
            $pass = $pass->{$user[$j]};
        }elsif( $pass = $default )
        {
            $conn{user} = `logname`;chop $conn{user};
        }
    }

    my %expect;
    if ( $pass && ref $pass )
    {
        %expect = %$pass;
	for( keys %expect ) 
	{
            next unless $expect{$_} =~ /googlecode\s*:\s*(\w+)/;  
	    $expect{$_} = Authen::OATH->new->totp(  decode_base32( $1 ));
	}
    }
    elsif( defined $pass )
    {
        $expect{assword} = $pass;
    }

    my $ssh;
    my $node = $host[$i];
    my %node = $hosts->match( $node );
    
    my $p = MYDan::Util::Proxy->new( "$MYDan::PATH/etc/util/conf/proxy" );
    my %x = $p->search( $node{$node} );
    
    $ssh = $SSH. sprintf " %s %s", $conn{user} ? "-l $conn{user}" : '', 
       $x{$node{$node}} ? " -o ProxyCommand='nc -X 5 -x $x{$node{$node}} %h %p'":'';
    
    if ($conn{rsync} )
    {
	$conn{rsync} =~ s/$node:/$node{$node}:/g;
        $ssh = "$RSYNC -e \"$ssh\" $conn{rsync}"
    }
    else
    {
        $ssh = "$ssh -t $node{$node}";
    }
    warn "debug:$ssh\n" if $ENV{MYDan_DEBUG};

    my $prompt = '::sudo::';
    if ( my $sudo = $conn{sudo} ) { $ssh .= " sudo -p '$prompt' su - $sudo" }

    exec $ssh unless $pass;

    my $exp = Expect->new();

    $SIG{WINCH} = sub
    {
        $exp->slave->clone_winsize_from( \*STDIN );
        kill WINCH => $exp->pid if $exp->pid;
        local $SIG{WINCH} = $SIG{WINCH};
    };

    $exp->slave->clone_winsize_from( \*STDIN );
    $exp->spawn( $ssh );
    $exp->expect
    ( 
        $TIMEOUT, 
	[ qr/yes\/no/ => sub { $exp->send( "yes\n" ); exp_continue; } ],
        [ qr/[#\$%] $/ => sub { $exp->interact; } ],
        [ qr/$prompt$/ => sub { $exp->send( $pass ); $exp->interact; } ],
	map{ my $v = $expect{$_};[ qr/$_/ => sub { $exp->send( "$v\n" ); exp_continue; } ] }keys %expect        
    );
}

sub host
{
    my ( $self, $hosts, $host ) = splice @_;

    return $host if $host =~ /^\d+\.\d+\.\d+\.\d+$/;

    my $range = MYDan::Node->new( MYDan::Util::OptConf->load()->dump( 'range') );
    my $db = $range->db;

    my %node = map{ $_ => 1 }grep{ /$host/ && /^[\w.-]+$/ }
                   map{ @$_ }$db->select( 'node' );

    map{ $node{$_} = 1 }grep{ /$host/ && /^[\w.-]+$/ }$hosts->hosts();
    return %node ? sort keys %node : $host;
}

1;
