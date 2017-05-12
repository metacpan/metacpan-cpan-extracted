=head1 NAME

DynGig::RCE::Access - RCE server. Extends DynGig::Util::TCPServer.

=cut
package DynGig::RCE::Server;

use base DynGig::Util::TCPServer;

use warnings;
use strict;
use Carp;

use Socket;
use YAML::XS;

use DynGig::RCE::Code;
use DynGig::RCE::Query;
use DynGig::RCE::Access;
use DynGig::Util::Sysrw;

use constant MAX_BUF => 2 ** 12;
use constant DEF_USR => 'nobody';

=head1 SYNOPSIS

 use DynGig::RCE::Server;

 my $server = DynGig::RCE::Server->new
 (
     thread => $number,
     port => $port,
 );
 
 $server->run
 (
     max_buf => $bytes,
     code_dir => $dir_path,
     access_file => $file_path
 );

=cut
sub run
{
    my ( $this, %param ) = @_;
    my $code_dir = $param{code_dir};
    my $access_file = $param{access_file};
    my $max_buf = $param{max_buf} || MAX_BUF;
    my $error = 'invalid definition for';

    croak "$error max_buf" if $max_buf && $max_buf !~ /^\d+$/;
    croak "$error 'code_dir'" unless $code_dir && -d $code_dir;

    my $code = DynGig::RCE::Code->new( $code_dir );

    warn YAML::XS::Dump $error if $error = $code->error();

    my $access = DynGig::RCE::Access->new( $access_file ) if $access_file;
    my @cruft = grep { ! $code->code( $_ ) } $access->names();
    my %id;

    warn "\ncruft in access file\n" . YAML::XS::Dump \@cruft if @cruft;

    if ( my $user = $param{default_user} )
    {
        my @user = split ':', $user, 2;

        croak "invalid default user '$user[0]'"
            unless defined ( $id{$user}[0] = getpwnam $user[0] );

        croak "invalid default group '$user[1]'"
            unless @user == 1 || defined ( $id{$user}[1] = getgrnam $user[1] );
    }
    else
    {
        my $user = DEF_USR;
        my @id = ( scalar getpwnam( $user ), scalar getgrnam( $user ) );

        $id{"$user:$user"} = \@id;
        $id{$user}[0] = $id[0];
    }

    $this->{_context} = +
    {
        code => $code,
        access => $access,
        max_buf => $max_buf,
        default => \%id,
    };

    DynGig::Util::TCPServer::run( $this );
}

sub _worker
{
    my ( $this, $queue ) = @_;
    print "\n" . $queue->dequeue();
}

sub _server
{
    my ( $this, $socket, $queue ) = @_;
    my $context = $this->{_context};
    my $buffer;
    my $query = DynGig::RCE::Query::unzip( $buffer )
        if DynGig::Util::Sysrw->read( $socket, $buffer, $context->{max_buf} );

    unless ( $query )
    {
        my $client = inet_ntoa( ( sockaddr_in( getpeername $socket ) )[-1] );
        $queue->enqueue( YAML::XS::Dump +{ INVALID => $client } );
        return;
    }

    $queue->enqueue( $query->serial() );

    my $default = $context->{default};
    my $access = $context->{access};
    my $code = $context->{code};

    for my $query ( $query->query() )
    {
        my $name = $query->{code};

        last unless $code->code( $name );

        my $user = $query->{user} || DEF_USR;
        my $param = $query->{param};
        my $id = $default->{$user};

        last unless defined $id || ( $id = $access->getid( $name, $user ) );

        local $< = local $> = $id->[0];
        local $( = local $) = $id->[1] if @$id == 2;

        my $result = $code->run( $name, $param );

        last unless defined $result
            && DynGig::Util::Sysrw->write( $socket, YAML::XS::Dump $result );
    }
}

=head1 NOTE

See DynGig::RCE

=cut

1;

__END__
