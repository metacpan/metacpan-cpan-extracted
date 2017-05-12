# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use strict;
use warnings;

package HTTP::Server::Multiplex;
use vars '$VERSION';
$VERSION = '0.11';


use HTTP::Server::VirtualHost;
use HTTP::Server::VirtualHost::LocalHost;
use HTTP::Server::Connection;

use IO::Multiplex    ();
use IO::Socket::INET ();
use Sys::Hostname    qw(hostname);
use POSIX            qw(setsid);
use English          qw(-no_match_vars);
use POSIX            qw(setuid setgid sigprocmask
                        SIGINT SIG_BLOCK SIG_UNBLOCK);
use Fcntl;
use File::Spec       ();
use Socket           qw(inet_aton AF_INET);

use Log::Report 'httpd-multiplex', syntax => 'SHORT';

###


my $singleton;
sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift @_ : {@_};

    error __x"you can only create one {pkg} object per program"
        if $singleton++;   # only one IO::Multiplexer

    (bless {}, $class)->init($args);
}

sub _to_list($) { ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0] }
sub init($)
{   my ($self, $args) = @_;

    my $mux = $self->{HSM_mux} = IO::Multiplex->new;
    $mux->set_callback_object($self);

    foreach my $conn (_to_list delete $args->{connection})
    {   trace "setting up connection";
        $self->_configNetwork($mux, $conn);
    }

    $self->{HSM_vhosts} = {};
    foreach my $vhost (_to_list delete $args->{vhosts})
    {   trace "setting up virtual host";
        $self->addVirtualHost($vhost);
    }

    trace "setting up daemon";
    $self->_configDaemon(delete $args->{daemon});

    error __x"Unknown option for ::Multiplex::new(): {names}"
      , names => [keys %$args]
         if keys %$args;
    $self;
}


sub _configNetwork($$)
{   my ($self, $mux, $config) = @_;
    my $socket;

    if(UNIVERSAL::isa($config, 'IO::Socket'))
    {   $socket = $config;
    }
    elsif(not UNIVERSAL::isa($config, 'HASH'))
    {   error __x"connection configuration not a socket not HASH";
    }
    else
    {   my $host = $config->{host} || '0.0.0.0';
        my $port = $config->{port} || 80;
        $socket = IO::Socket::INET->new
          ( LocalAddr => $host
          , Listen    => 5
          , LocalPort => $port
          , Reuse     => 1  # to be able to restart without loss of service
                            # not yet implemented
          );

        defined $socket
           or fault __x"unable to create socket for {host} port {port}"
                , host => $host, port => $port;

        trace 'created server socket '.$socket->sockhost.':'.$port;
    }

    $mux->listen($socket);
}


sub _configDaemon($)
{   my ($self, $config) = @_;
    my @daemon_headers;

    my $id;
    if(exists $config->{server_id})
    {   $id = $config->{server_id};
    }
    else
    {   no strict; no warnings;
        $id = hostname . " ".__PACKAGE__." $VERSION, "
            . "IO::Multiplex $IO::Multiplex::VERSION";
    }
    push @daemon_headers, Server => $id if defined $id;
    HTTP::Server::Connection->setDefaultHeaders(@daemon_headers);

    $EUID!=0 || defined $config->{user}
        or error __"running daemon as root is dangerous: specify other user";

    my $user   = $config->{user} || $ENV{USER} || $EUID;
    my $uid    = $user =~ m/\D/ ? getpwnam($user) : $user;
    defined $uid
        or error __x"user {name} does not exist", name => $user;
    $self->{HSM_uid} = $uid;

    my @groups = split ' ', ($config->{group} || $EGID);
    my @gid;
    foreach my $group (@groups)
    {   my $gid = $group =~ m/\D/ ? getgrnam($group) : $group;
        defined $gid
            or error __x"group {name} does not exist", name => $group;
        push @gid, $gid;
    }
    $self->{HSM_gid} = join ' ', @gid;

    $self->{HSM_pidfn} = $config->{pid_file};
    $self;
}

sub _daemonize()
{   my $self = shift;

    my ($uid, $gid) = @$self{'HSM_uid', 'HSM_gid'};
    if($uid ne $EUID)
    {   setuid $uid
            or fault __x"cannot switch to user-id {uid}", uid => $uid;
        trace "switch to user $uid";
    }
    if($gid ne $EGID)
    {   setgid $gid
            or fault __x"cannot switch to group-id {gid}", gid => $gid;
        trace "switch to group $gid";
    }

    $self->{HSM_detach}
        or return $self;

    my $pidfile = $self->{HSM_pidfn};
    if(defined $pidfile)
    {   sysopen PID, $pidfile, O_EXCL|O_CREAT|O_WRONLY|O_TRUNC
            or fault __x"cannot write to pid_file {fn}", fn => $pidfile;
    }

    trace "close standard error dispatcher";
    dispatcher close => 'PERL';    # no die/warn output

    trace "closing standard file-handles";
    open STDIN,  '<', File::Spec->devnull;
    open STDOUT, '>', File::Spec->devnull;
    open STDERR, '>', File::Spec->devnull;

    trace "process into the background";
    my $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask SIG_BLOCK, $sigset
        or fault "cannot block SIGINT for fork";

    my $pid    = fork;
    defined $pid
        or fault "cannot fork into background";

    sigprocmask SIG_UNBLOCK, $sigset
        or fault "cannot unblock SIGINT after fork";

    if($pid > 0)
    {   # Parent process
        if($pidfile)
        {   print PID "$pid\n";
            close PID or fault "cannot write pid-file {fn}", fn => $pidfile;
        }

        return $self;
    }

    # Child process
    close PID if $pidfile;

    setsid;

    $self;
}

#-------------

sub mux() {shift->{HSM_mux}}

#-------------

sub run()
{   my $self = shift;

    unless(keys %{$self->{HSM_vhosts}})
    {   trace "creating default vhost 'localhost' because no explicit vhost";
        $self->addVirtualHost(HTTP::Server::VirtualHost::LocalHost->new);
    }

    $self->_daemonize;

    info __x"http daemon start, user {uid} group {gid}"
      , uid => $EUID, gid => $EGID;

    $self->mux->loop;
}

#-------------

sub addVirtualHost(@)
{   my $self   = shift;
    my $config = @_==1 ? shift : {@_};
    my $vhost;
    if(UNIVERSAL::isa($config, 'HTTP::Server::VirtualHost'))
    {   $vhost = $config;
    }
    elsif(!ref $config && $config =~ m/\:\:/)
    {   eval "require $config";
        die $@ if $@;
        $vhost = $config->new;
    }
    elsif(not UNIVERSAL::isa($config, 'HASH'))
    {   error __x"virtual configuration not a valid object not HASH";
    }
    else
    {   $vhost = HTTP::Server::VirtualHost->new($config);
    }

    $self->{HSM_vhosts}{$_} = $vhost
        for $vhost->name, $vhost->aliases;
    $vhost;
}


sub removeVirtualHost($)
{   my ($self, $id) = @_;
    my $vhost = UNIVERSAL::isa($id, 'HTTP::Server::VirtualHost') ? $id
              : $self->virtualHost($id);
    defined $vhost or return;

    delete $self->{HSM_vhosts}{$_}
        for $vhost->name, $vhost->aliases;
    $vhost;
}


sub virtualHost($) { $_[0]->{HSM_vhosts}{$_[1]} }

#-------------------
#section Multiplexer

sub mux_connection($$)
{   my ($self, $mux, $fh) = @_;
    my $client = HTTP::Server::Connection->new($mux, $fh, $self);
    $mux->set_callback_object($client, $fh);
}

sub dnslookup($$$)
{   my ($self, $conn, $ip, $where) = @_;
    my $host = $self->{HSM_cache}{$ip} ||=
        # must be changed into async lookup!
        gethostbyaddr inet_aton($ip), AF_INET;
    $$where  = $host;
    info $conn->id." $ip is $host";
}

#-------------------


1;
