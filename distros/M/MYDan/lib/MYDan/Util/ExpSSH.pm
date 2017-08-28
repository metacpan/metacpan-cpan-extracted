package MYDan::Util::ExpSSH;

use strict;
use warnings;

use Expect;
use MYDan::Node;
use MYDan::Util::OptConf;
use MYDan::Util::Pass;

our $TIMEOUT = 20;
our $SSH = 'ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -t';

=head1 SYNOPSIS

 use MYDan::Util::ExpSSH;

 my $ssh = MYDan::Util::ExpSSH->new( );

 $ssh->conn( host => 'foo', user => 'joe', 
             pass => '/conf/file', 
             sudo => 'user1' 
           );

=cut

sub new
{
    my $class = shift;
    bless +{}, ref $class || $class;
}

sub conn
{
    my ( $self, %conn ) = splice @_;
    my $i = 0;

    return unless my @host = $self->host( $conn{host} );


    if ( @host > 1 )
    {
        my @host = map { sprintf "[ %d ] %s", $_ + 1, $host[$_] } 0 .. $#host; 
        print STDERR join "\n", @host, "please select: [ 1 ] ";
        $i = $1 - 1 if <STDIN> =~ /(\d+)/ && $1 && $1 <= @host;
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

    $pass .= "\n" if defined $pass;

    my $ssh = sprintf "$SSH %s $host[$i]", $conn{user} ? "-l $conn{user}" : '';
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
        [ qr/[Pp]assword: *$/ => sub { $exp->send( $pass ); exp_continue; } ],
        [ qr/[#\$%] $/ => sub { $exp->interact; } ],
        [ qr/$prompt$/ => sub { $exp->send( $pass ); $exp->interact; } ],
    );
}

sub host
{
    my ( $self, $host ) = splice @_;

    return $host unless system "host $host > /dev/null";

    my $range = MYDan::Node->new( MYDan::Util::OptConf->load()->dump( 'range') );
    my $db = $range->db;

    my %node = map{ $_ => 1 }grep{ /$host/ && /^[\w.-]+$/ }
                   map{ @$_ }$db->select( 'node' );

    return %node ? sort keys %node : $host;
}

1;
