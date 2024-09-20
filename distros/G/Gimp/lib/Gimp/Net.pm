package Gimp::Net;

# This package is loaded by Gimp, and is !private!, so don't
# use it standalone, it won't work.

# the protocol is quite easy ;)
# at connect() time the server returns
# PERL-SERVER protocolversion [AUTH]
#
# length_of_packet cmd
#
# cmd				response	description
# AUTH password			ok [message]	authorize yourself
# QUIT						quit server
# EXEC verbose func args	$@ return-vals	run simple command
# TEST procname			bool		check for procedure existence
# DTRY in-args					destroy all argument objects
#
# args is "number of arguments" arguments preceded by length
# type is first character
# Sscalar-value
# Aelem1\0elem2...
# Rclass\0scalar-value

BEGIN { warn "$$-Loading ".__PACKAGE__ if $Gimp::verbose >= 2; }

use strict;
use warnings;
our $VERSION;
use subs qw(gimp_call_procedure);
use base qw(DynaLoader);
use IO::Socket;
use Carp 'croak';
use Fcntl qw(F_SETFD);

$VERSION = "2.38";
bootstrap Gimp::Net $VERSION;

my $PROTOCOL_VERSION = 5; # protocol version
my ($server_fh, $gimp_pid, $auth);

my $DEFAULT_TCP_PORT  = 10009;
my $DEFAULT_UNIX_DIR  = "/tmp/gimp-perl-serv-uid-$>/";
my $DEFAULT_UNIX_SOCK = "gimp-perl-serv";

my $initialized = 0;

# manual import - can't call Gimp::import as it calls us!
sub __ ($) { goto &Gimp::__ }

sub initialized { $initialized }

sub response {
   read($server_fh,my $len,4) == 4 or die "protocol error (1): $!";
   $len=unpack("N",$len);
   read($server_fh,my $req,$len) == $len or die "protocol error (2): $!";
   net2args(0,$req);
}

sub senddata { $_[0]->print(pack("N",length $_[1]), $_[1]) or die "$_[0]: $!"; }

sub command {
   my $req=shift;
   senddata $server_fh, $req . args2net(0,@_);
   response;
}

sub import {
   my $pkg = shift;
   warn "$$-$pkg->import(@_)" if $Gimp::verbose >= 2;
   return if @_;
   # overwrite some destroy functions
   *Gimp::Tile::DESTROY=
   *Gimp::PixelRgn::DESTROY=
   *Gimp::GimpDrawable::DESTROY=sub {
      # is synchronous which avoids deadlock from using non sys*-type functions
      command "DTRY", @_ if $server_fh;
   };
}

sub gimp_call_procedure {
   warn "$$-Net::gimp_call_procedure(@_)" if $Gimp::verbose >= 2;
   my @response = command("EXEC", $Gimp::verbose, @_);
   my $die_text = shift @response;
   Gimp::recroak(Gimp::exception_strip(__FILE__, $die_text)) if $die_text;
   wantarray ? @response : $response[0];
}

sub gimp_procedural_db_proc_exists { command 'TEST', @_; }
sub server_quit { command 'QUIT'; undef $server_fh; $initialized = 0; }

sub server_wait {
   croak __"server_wait called but gimp_pid undefined"
      unless defined $gimp_pid;
   waitpid $gimp_pid, 0;
}

my $PROC_SF = 'extension-perl-server';

sub start_server {
   my $opt = shift;
   $opt = $Gimp::spawn_opts unless $opt;
   warn __"$$-start_server($opt)" if $Gimp::verbose >= 2;
   croak __"unable to create socketpair for gimp communications: $!"
      unless ($server_fh, my $gimp_fh) =
	 IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);
   # do it here so it is done only once
   require Alien::Gimp;
   $gimp_pid = fork;
   croak __"unable to fork: $!" if $gimp_pid < 0;
   if ($gimp_pid > 0) {
      return $server_fh;
   }
   undef $gimp_pid;
   close $server_fh;
   fcntl $gimp_fh, F_SETFD, 0;
   delete $ENV{GIMP_HOST};
   open STDIN,"</dev/null";
   my $args = join ' ',
     &Gimp::RUN_NONINTERACTIVE,
     fileno($gimp_fh),
     int($Gimp::verbose);
   my @exec_args = (Alien::Gimp->gimp, qw(--no-splash --console-messages));
   push @exec_args, "--no-data" if $opt=~s/(^|:)no-?data//;
   push @exec_args, "-i" unless $opt=~s/(^|:)gui//;
   push @exec_args, "--verbose" if $Gimp::verbose >= 2;
   push @exec_args, qw(--pdb-compat-mode off);
   push @exec_args, qw(--batch-interpreter plug-in-script-fu-eval -b);
   push @exec_args, "(if (defined? '$PROC_SF) ($PROC_SF $args)) (gimp-quit 0)";
   warn __"$$-exec @exec_args\n" if $Gimp::verbose >= 2;
   { exec @exec_args; } # block to suppress warning
   croak __"unable to exec: $!";
}

sub try_connect {
   local $_=$_[0];
   warn "$$-".__PACKAGE__."::try_connect(@_)" if $Gimp::verbose >= 2;
   my $fh;
   $auth = s/^(.*)\@// ? $1 : "";	# get authorization
   if ($_ eq "") {
      return $fh if $fh = try_connect ("$auth\@unix$DEFAULT_UNIX_DIR$DEFAULT_UNIX_SOCK");
      return $fh if $fh = try_connect ("$auth\@tcp/127.1:$DEFAULT_TCP_PORT");
      return $fh if $fh = try_connect ("$auth\@spawn/");
      undef $auth;
      return;
   }
   if (s{^spawn/}{}) {
      return start_server($_);
   } elsif (s{^unix/}{/}) {
      return IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $_);
   } else {
      s{^tcp/}{};
      my($host, $port) = split /:/;
      $port = $DEFAULT_TCP_PORT unless $port;
      return IO::Socket::INET->new(
	 Type => SOCK_STREAM, PeerHost => $host, PeerPort => $port,
      );
   }
   undef $auth;
}

sub gimp_init {
   warn "$$-gimp_init(@_)" if $Gimp::verbose >= 2;
   if (@_) {
      $server_fh = try_connect ($_[0]);
   } elsif (defined($Gimp::host)) {
      $server_fh = try_connect ($Gimp::host);
   } elsif (defined($ENV{GIMP_HOST})) {
      $server_fh = try_connect ($ENV{GIMP_HOST});
   } else {
      $server_fh = try_connect ("");
   }
   defined $server_fh or croak __"could not connect to the gimp server (make sure Perl-Server is running)";
   { my $fh = select $server_fh; $|=1; select $fh }
   my @r = response;
   die __"expected perl-server at other end of socket, got @r\n"
      unless $r[0] eq "PERL-SERVER";
   shift @r;
   die __"expected protocol version $PROTOCOL_VERSION, but server uses $r[0]\n"
      unless $r[0] eq $PROTOCOL_VERSION;
   shift @r;
   for(@r) {
      if($_ eq "AUTH") {
         die __"server requests authorization, but no authorization available\n"
            unless $auth;
         my @r = command "AUTH", $auth;
         die __"authorization failed: $r[1]\n" unless $r[0];
         print __"authorization ok, but: $r[1]\n" if $Gimp::verbose >= 2 and $r[1];
      }
   }
   $initialized = 1;
   warn "$$-Finished gimp_init(@_)" if $Gimp::verbose >= 2;
}

sub gimp_end {
   warn "$$-gimp_end - gimp_pid=$gimp_pid" if $Gimp::verbose >= 2;
   $initialized = 0;
   if ($gimp_pid and $server_fh) {
      server_quit;
      server_wait;
   }
   undef $server_fh;
   undef $gimp_pid;
}

sub gimp_main {
   eval { Gimp::callback("-net") };
   if ($@) {
      chomp(my $exception = $@);
      warn "$0 exception: $exception\n";
      gimp_end;
      -1;
   } else {
      gimp_end;
      0;
   }
}

sub get_connection() {
   [$server_fh,$gimp_pid];
}

sub set_connection($) {
   ($server_fh,$gimp_pid)=@{+shift};
}

END {
   gimp_end;
}

# start of server-used block
our ($use_unix, $use_tcp, @authorized, %stats);
# you can enable unix sockets, tcp sockets, or both (or neither...)
# enabling tcp sockets can be a security risk. If you don't understand why,
# you shouldn't enable it!
$use_unix	= 1;
$use_tcp	= 1;	# tcp is enabled only when authorization is available
my $unix_path;

my $max_pkt = 1024*1024*8;

sub slog {
  return if $Gimp::Fu::run_mode == &Gimp::RUN_NONINTERACTIVE;
  print localtime.": $$-slog(",@_,")\n";
}

sub reply { my $fh = shift; senddata $fh, args2net(0, @_); }

sub handle_request($) {
   my($fh)=@_;
   my ($req, $data);
   eval {
      my $length;
      read($fh,$length,4) == 4 or die "2\n";
      $length=unpack("N",$length);
      $length>0 && $length<$max_pkt or die "3\n";
      read($fh,$req,4) == 4 or die "4\n";
      read($fh,$data,$length-4) == $length-4 or die "5\n";
   };
   warn "$$-handle_request got '$@'" if $@ and $Gimp::verbose >= 2;
   return 0 if $@;
   my @args = net2args(($req eq "EXEC"), $data);
   if(!$auth or $authorized[fileno($fh)]) {
      if ($req eq "EXEC") {
         no strict 'refs';
	 my $old_v = $Gimp::verbose;
	 $Gimp::verbose = shift @args;
	 my $function = shift @args;
	 warn "$$-Net:Gimp->$function(@args)" if $Gimp::verbose >= 2;
         my @retvals = eval { Gimp->$function(@args) };
	 $Gimp::verbose = $old_v;
	 unshift @retvals, Gimp::exception_strip(__FILE__, $@);
	 senddata $fh, args2net(1, @retvals);
      } elsif ($req eq "TEST") {
         no strict 'refs';
         reply $fh,
	    defined(*{"Gimp::Lib::$args[0]"}{CODE}) ||
	       Gimp::gimp_procedural_db_proc_exists($args[0]);
      } elsif ($req eq "DTRY") {
         destroy_objects(@args);
         reply $fh; # fix to work around using non-sysread/write functions
      } elsif ($req eq "QUIT") {
         slog __"received QUIT request";
         reply $fh;
	 Gtk2->main_quit;
      } elsif($req eq "AUTH") {
         reply $fh, 1, __"authorization unnecessary";
      } else {
         reply $fh;
         slog __"illegal command received, aborting connection";
         return 0;
      }
   } else {
      if($req eq "AUTH") {
         my($ok,$msg);
         if($args[0] eq $auth) {
            $ok=1;
            $authorized[fileno($fh)]=1;
         } else {
            $ok=0;
            slog __"wrong authorization, aborting connection";
            sleep 5; # safety measure
         }
         reply $fh, $ok, $msg;
         return $ok;
      } else {
         reply $fh;
         slog __"unauthorized command received, aborting connection";
         return 0;
      }
   }
   return 1;
}

sub on_accept {
  warn "$$-on_accept(@_)" if $Gimp::verbose >= 2;
  my $h = shift;
  slog sprintf __"new connection(%d)%s",
    $h->fileno,
    $h->isa('IO::Socket::INET') ? ' from '.$h->peerport.':'.$h->peerhost : '';
  reply $h, "PERL-SERVER", $PROTOCOL_VERSION, ($auth ? "AUTH" : ());
  $stats{fileno($h)}=[0,time];
}

sub on_input {
  warn "$$-on_input(@_)" if $Gimp::verbose >= 2;
  my ($fd, $condition, $fh) = @_;
  if (handle_request($fh)) {
    return ++$stats{$fd}[0]; # non-false!
  } else {
    slog sprintf __"closing connection %d (%d requests in %g seconds)", $fd, $stats{$fd}[0], time-$stats{$fd}[1];
    return;
  }
}

sub setup_listen_unix {
  warn "$$-setup_listen_unix(@_)" if $Gimp::verbose >= 2;
  use autodie;
  use File::Basename;
  my $host = shift;
  my $dir = dirname($host);
  mkdir $dir, 0700 unless -d $dir;
  unlink $host if -e $host;
  Gimp::Extension::add_listener(IO::Socket::UNIX->new(
    Type => SOCK_STREAM, Local => $host, Listen => 5
  ), \&on_input, \&on_accept);
  slog __"accepting connections in $host";
}

sub setup_listen_tcp {
  warn "$$-setup_listen_tcp(@_)" if $Gimp::verbose >= 2;
  use autodie;
  my $host = shift;
  ($host, my $port)=split /:/,$host;
  $port = $DEFAULT_TCP_PORT unless $port;
  Gimp::Extension::add_listener(IO::Socket::INET->new(
    Type => SOCK_STREAM, LocalPort => $port, Listen => 5, ReuseAddr => 1,
    ($host ? (LocalAddr => $host) : ()),
  ), \&on_input, \&on_accept);
  slog __"accepting connections on port $port";
}

sub perl_server_run {
  (my $filehandle, $Gimp::verbose) = @_;
  warn "$$-".__PACKAGE__."::perl_server_run(@_)\n" if $Gimp::verbose >= 2;
  if ($Gimp::Fu::run_mode == &Gimp::RUN_NONINTERACTIVE) {
      die __"unable to open Gimp::Net communications socket: $!\n"
	 unless open my $fh,"+<&$filehandle";
      $fh->autoflush;
      on_accept($fh);
      Glib::IO->add_watch(fileno($fh), 'in', \&on_input, $fh);
      Gtk2->main;
      Gimp->quit(0);
      exit(0);
  }
  my $host = $ENV{'GIMP_HOST'};
  $auth = $host=~s/^(.*)\@// ? $1 : undef;	# get authorization
  slog __"server version $Gimp::VERSION started".($auth ? __", authorization required" : "");
  $SIG{PIPE}='IGNORE'; # may not work, since libgimp (eech) overwrites it.
  if ($host ne "") {
     if ($host=~s{^spawn/}{}) {
        die __"invalid GIMP_HOST: 'spawn' is not a valid connection method for the server";
     } elsif ($host=~s{^unix/}{/}) {
        setup_listen_unix($unix_path = $host);
     } else {
        $host=~s{^tcp/}{};
	die __"authorization required for tcp connections" unless $auth;
        setup_listen_tcp($host);
     }
  } else {
     setup_listen_unix($unix_path = $DEFAULT_UNIX_DIR.$DEFAULT_UNIX_SOCK)
        if $use_unix;
     setup_listen_tcp(":$DEFAULT_TCP_PORT") if $use_tcp && $auth;
  }
  Gtk2->main;
  ();
}

sub perl_server_quit {
  return unless $unix_path;
  unlink $unix_path or die "failed to unlink '$unix_path': $!\n";
  rmdir $DEFAULT_UNIX_DIR if $unix_path eq $DEFAULT_UNIX_DIR.$DEFAULT_UNIX_SOCK;
  slog "server quitting";
}

1;
__END__

=head1 NAME

Gimp::Net - Communication module for the gimp-perl server.

=head1 SYNOPSIS

  use Gimp;

=head1 DESCRIPTION

For Gimp::Net (and thus commandline and remote scripts) to work, you
first have to install the "Perl-Server" plugin somewhere where Gimp
can find it (e.g in your .gimp/plug-ins/ directory). Usually this is
done automatically while installing the Gimp extension. If you have a
menu entry C<Filters/Perl/Server> then it is probably installed.

The Perl-Server can either be started from the C<Filters> menu in Gimp,
or automatically when a perl script can't find a running Perl-Server,
in which case it will start up its own copy of GIMP.

When started from within GIMP, the Perl-Server will create a unix
domain socket to which local clients can connect. If an authorization
password is given to the Perl-Server (by defining the environment variable
C<GIMP_HOST> before starting GIMP), it will also listen on a tcp port
(default 10009). Since the password is transmitted in cleartext, using the
Perl-Server over tcp effectively B<lowers the security of your network to
the level of telnet>. Even worse: the current Gimp::Net-protocol can be
used for denial of service attacks, i.e. crashing the Perl-Server. There
also *might* be buffer-overflows (although I do care a lot for these).

=head1 ENVIRONMENT

The environment variable C<GIMP_HOST> specifies the default server to
contact and/or the password to use. The syntax is
[auth@][tcp/]hostname[:port] for tcp, [auth@]unix/local/socket/path for unix
and spawn/ for a private GIMP instance. Examples are:

 www.yahoo.com               # just kidding ;)
 yahoo.com:11100             # non-standard port
 tcp/yahoo.com               # make sure it uses tcp
 authorize@tcp/yahoo.com:123 # full-fledged specification

 unix/tmp/unx                # use unix domain socket
 password@unix/tmp/test      # additionally use a password

 authorize@                  # specify authorization only

 spawn/                      # use a private gimp instance
 spawn/nodata                # pass --no-data switch
 spawn/gui                   # don't pass -n switch

=head1 CALLBACKS

=over 4

=item Gimp::on_net($callback)

C<$callback> is called after we have succesfully connected to the
server. Do your dirty work in this function, or see L<Gimp::Fu> for a
better solution.

=back

=head1 FUNCTIONS

=over 4

=item server_wait()

waits for a spawned GIMP process to exit. Calls C<croak> if none defined.

=item server_quit()

sends the perl server a quit command.

=item get_connection()

return a connection id which uniquely identifies the current connection.

=item set_connection(conn_id)

set the connection to use on subsequent commands. C<conn_id> is the
connection id as returned by get_connection().

=back

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>

=head1 SEE ALSO

perl(1), L<Gimp>.
