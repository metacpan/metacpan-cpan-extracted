##-*- Mode: CPerl; coding: utf-8; -*-
##
## File: DiaColloDB/WWW/Server.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, www wrappers: standalone tiny www server
##  + adapted from DTA::CAB::Server::HTTP

package DiaColloDB::WWW::Server;
use DiaColloDB;
use DiaColloDB::Logger;
use DiaColloDB::WWW::CGI;
use DiaColloDB::WWW::Handler;
use DiaColloDB::WWW::Handler::cgi;
use DiaColloDB::WWW::Handler::static;
use File::ShareDir qw(dist_dir);
use HTTP::Daemon;
use HTTP::Status;
use MIME::Types;         ##-- for guessing mime types
use POSIX ':sys_wait_h'; ##-- for WNOHANG
use Socket qw(SOMAXCONN);
use Carp;

use strict;

##======================================================================
## globals

our $VERSION = "0.02.005";
our @ISA  = qw(DiaColloDB::Logger);

##======================================================================
## constructors etc.

## $srv = $that->new(%args)
##  + %args, %$srv:
##    (
##     ##-- underlying HTTP::Daemon server
##     daemonMode => $daemonMode,    ##-- one of 'serial' or 'fork' [default='serial']
##     daemonArgs => \%daemonArgs,   ##-- args to HTTP::Daemon->new(); default={LocalAddr=>'0.0.0.0',LocalPort=>6066}
##     daemon     => $daemon,        ##-- underlying HTTP::Daemon object
##     cgiArgs    => \%cgiArgs,      ##-- args to DiaColloDB::WWW::CGI->new(); default=none
##     mimetypes  => $mt,            ##-- a MIME::Types object for guessing mime types
##     ##
##     ##-- user data
##     wwwdir     => $wwwdir,        ##-- root directory for www wrapper data (default=File::ShareDir::dist_dir("DiaColloDB-WWW")."/htdocs"
##     dburl      => $dburl,         ##-- DiaColloDB client URL (e.g. local indexed directory; alias='dbdir')
##     ##
##     ##-- logging
##     logAttempt => $level,        ##-- log connection attempts at $level (default='trace')
##     logConnect => $level,        ##-- log successful connections (client IP and requested path) at $level (default='debug')
##     logRquestData => $level,     ##-- log full client request data at $level (default='trace')
##     logResponse => $level,       ##-- log full client response at $level (default='trace')
##     logClientError => $level,    ##-- log errors to client at $level (default='debug')
##     logClose => $level,          ##-- log close client connections (default='trace')
##    )
sub new {
  my $that = shift;
  my $srv = bless({
		   ##-- underlying server
		   daemon => undef,
		   daemonArgs => {
				  LocalAddr=>'0.0.0.0', ##-- all
				  LocalPort=>6066,
				  ReuseAddr=>1,
				  #ReusePort=>1, ##-- don't set this; it causes errors "Your vendor has not defined Socket macro SO_REUSEPORT"
				 },
		   cgiArgs => {},
		   mimetypes => undef, ##-- see prepareLocal()

		   ##-- user data
		   dburl => undef,
		   wwwdir => undef, ##-- see prepareLocal()

		   ##-- logging
		   logAttempt => 'trace',
		   logConnect => 'debug',
		   logRequestData => 'trace',
		   logResponse => 'trace',
		   logCache => 'debug',
		   logClose => 'trace',
		   logClientError => 'debug',

		   ##-- user args
		   @_,
		  }, ref($that)||$that);
  $srv->{dburl} = $srv->{dbdir} if ($srv->{dbdir} && !defined($srv->{dburl}));

  return $srv;
}

##==============================================================================
## Methods: Generic Server API
##==============================================================================

## $rc = $srv->prepare()
##  + default implementation initializes logger & pre-loads all analyzers
sub prepare {
  my $srv = shift;
  my $rc  = 1;

  ##-- prepare: logger
  DiaColloDB::Logger->ensureLog();

  ##-- prepare: PID file
  if (defined($srv->{pidfile})) {
    my $pidfh = IO::File->new(">$srv->{pidfile}")
      or $srv->logconfess("prepare(): could not write PID file '$srv->{pidfile}': $!");
    $pidfh->print(($srv->{pid} || $$), "\n");
    $pidfh->close()
  }

  ##-- prepare: signal handlers
  $rc &&= $srv->prepareSignalHandlers();

  ##-- prepare: subclass-local
  $rc &&= $srv->prepareLocal(@_);

  ##-- prepare: timestamp
  $srv->{t_started} //= time();

  ##-- return
  $srv->info("initialization complete");

  return $rc;
}

## $rc = $srv->prepareSignalHandlers()
##  + initialize signal handlers
sub prepareSignalHandlers {
  my $srv = shift;
  $SIG{'__DIE__'} = sub {
    die @_ if ($^S);  ##-- normal operation if executing inside an eval{} block
    $srv->finish();
    $srv->logconfess("__DIE__ handler called - exiting: ", @_);
    exit(255);
  };
  my $sig_catcher = sub {
    my $signame = shift;
    $srv->finish();
    $srv->logwarn("caught signal SIG$signame - exiting");
    exit(255);
  };
  my ($sig);
  foreach $sig (qw(TERM KILL QUIT INT HUP ABRT SEGV)) {
    $SIG{$sig} = $sig_catcher;
  }
  #$SIG{$sig} = $sig_catcher foreach $sig (qw(IO URG SYS USR1 USR2)); ##-- DEBUG
  return $sig_catcher;
}

## $rc = $srv->prepareLocal(@args_to_prepare)
##  + subclass-local initialization
##  + called by prepare() after default prepare() guts have run
sub prepareLocal {
  my $srv = shift;

  ##-- setup wwwdir
  $srv->{wwwdir} //= dist_dir("DiaColloDB-WWW")."/htdocs";

  ##-- setup mimetypes object
  if (!($srv->{mimetypes} //= MIME::Types->new())) {
    $srv->logconfess("could not create MIME::Types object: $!");
  }

  ##-- setup HTTP::Daemon object
  if (!($srv->{daemon}=HTTP::Daemon->new(%{$srv->{daemonArgs}}))) {
    $srv->logconfess("could not create HTTP::Daemon object: $!");
  }
  my $daemon = $srv->{daemon};

  ##-- setup mode-specific options
  $srv->{daemonMode} //= 'serial';
  if ($srv->{daemonMode} eq 'fork') {
    $srv->{children} //= {};
    $srv->{pid}      //= $$;
    $SIG{CHLD} = $srv->reaper();
  }

  return 1;
}


## $rc = $srv->run()
##  + run the server (just a dummy method)
sub run {
  my $srv = shift;
  $srv->prepare() if (!$srv->{daemon}); ##-- sanity check
  $srv->logconfess("run(): no underlying HTTP::Daemon object!") if (!$srv->{daemon});

  my $daemon = $srv->{daemon};
  my $mode   = $srv->{daemonMode} || 'serial';
  $srv->info("server starting in $mode mode on host ", $daemon->sockhost, ", port ", $daemon->sockport, "\n");

  ##-- setup SIGPIPE handler (avoid heinous death)
  ##  + following suggestion on http://www.perlmonks.org/?node_id=580411
  $SIG{PIPE} = sub { $srv->vlog('warn',"got SIGPIPE (ignoring)"); };

  my ($csock,$chost,$hreq,$urikey,$handler,$pid,$rsp);
  while (1) {
    ##-- call accept() within the loop to avoid breaking out in fork mode
    if (!defined($csock=$daemon->accept())) {
      #sleep(1);
      next;
    }

    ##-- got client $csock (HTTP::Daemon::ClientConn object; see HTTP::Daemon(3pm))
    $chost = $csock->peerhost();

    ##-- serve client: parse HTTP request
    ${*$csock}{'httpd_client_proto'} = HTTP::Daemon::ClientConn::_http_version("HTTP/1.0"); ##-- HACK: force status line on send_error() from $csock->get_request()
    $hreq = $csock->get_request();
    if (!$hreq) {
      $srv->clientError($csock, RC_BAD_REQUEST, "could not parse HTTP request: ", ($csock->reason || 'get_request() failed'));
      next;
    }

    ##-- log basic request, and possibly request data
    $urikey = $hreq->uri->as_string;
    $srv->vlog($srv->{logConnect}, "client $chost: ", $hreq->method, ' ', $urikey);
    $srv->vlog($srv->{logRequestData}, "client $chost: HTTP::Request={\n", $hreq->as_string, "}");

    ##-- map request to handler
    $handler = $srv->getPathHandler($hreq->uri);
    if (!defined($handler)) {
      $srv->clientError($csock, RC_NOT_FOUND, "cannot resolve URI ", $hreq->uri);
      next;
    }

    ##-- child|serial code: pass request to handler
    eval {
      $rsp = $handler->run($srv,$csock,$hreq);
    };
    if ($@) {
      $srv->clientError($csock,RC_INTERNAL_SERVER_ERROR,"handler ", (ref($handler)||$handler), " died:<br/><pre>$@</pre>");
      $srv->reapClient($csock,$handler,$chost);
    }
    elsif (!defined($rsp)) {
      $srv->clientError($csock,RC_INTERNAL_SERVER_ERROR,"handler ", (ref($handler)||$handler), " failed for ", $hreq->uri->path);
      $srv->reapClient($csock,$handler,$chost);
    }

    ##-- ... and dump response to client
    if (!$csock->opened) {
      $srv->logwarn("client socket closed unexpectedly");
      next;
    } elsif ($csock->error) {
      $srv->logwarn("client socket has errors");
      next;
    }
    $srv->vlog($srv->{logResponse}, "returning response: ", $rsp->as_string) if ($srv->{logResponse});
    $csock->send_response($rsp);
  }
  continue {
    ##-- cleanup after client
    $srv->reapClient($csock,undef,$chost) if (!$pid);
    $hreq=$handler=$pid=$rsp=undef;
  }


  $srv->info("server exiting\n");
  return $srv->finish();
}

## $rc = $srv->finish()
##  + cleanup method; should be called when server dies or after run() has completed
sub finish {
  my $srv = shift;
  delete @SIG{qw(HUP TERM KILL __DIE__)}; ##-- unset signal handlers
  unlink($srv->{pidfile}) if ($srv->{pidfile});
  return 1;
}

##==============================================================================
## Methods: Local: spawn and reap

## \&reaper = $srv->reaper()
##  + zombie-harvesting code; installed to local %SIG
sub reaper {
  my $srv = shift;
  return sub {
    my ($child);
    while (($child = waitpid(-1,WNOHANG)) > 0) {
      $srv->vlog($srv->{logReap},"reaped subprocess pid=$child, status=$?");
      delete $srv->{children}{$child};
    }
    #$SIG{CHLD}=$srv->reaper() if ($srv->{installReaper}); ##-- re-install reaper for SysV
  };
}

## undef = $srv->reapClient($csock, $handler_or_undef, $chost_or_undef)
sub reapClient {
  my ($srv,$csock,$handler,$chost) = @_;
  return if (!$csock);
  $srv->vlog($srv->{logClose}, "closing connection to client ", ($chost // ($csock->opened ? $csock->peerhost : '-undef-')));
  if ($csock->opened) {
    $csock->force_last_request();
    $csock->shutdown(2);
  }
  $handler->finish($srv,$csock) if (UNIVERSAL::can($handler,'finish'));
  exit 0 if ($srv->{pid} && $srv->{pid} != $$);
  return;
}

##==============================================================================
## Methods: Local: path handlers

## $handler = $srv->getPathHandler($hreq_uri)
##  + returns a callback for handling $hreq_uri, called as $handler->($clientSocket,$httpRequest)
sub getPathHandler {
  my ($srv,$uri) = @_;
  (my $path   = $uri->path) =~ s{/+$}{};
  $path     ||= 'index.perl';
  $path       =~ s{/+}{/}g;
  $path       =~ s{^/}{};
  my $wwwdir  = $srv->{wwwdir};

  if ($path =~ /Makefile|README|\.svn|(?:\.(?:ttk|rc|pod|txt|pm)$)|~$/) {
    ##-- ignore special paths
    return undef;
  }
  elsif ($path =~ /\.perl$/) {
    ##-- handle "*.perl" requests via cgi (e.g. http://HOST:PORT/profile.perl?q=foo)
    (my $base = $path) =~ s/\.perl$//;
    return DiaColloDB::WWW::Handler::cgi->new(template=>"$wwwdir/$base.ttk")
      if (-e "$wwwdir/$base.perl" && -r "$wwwdir/$base.ttk");
    return undef; ##-- don't serve up raw perl files
  }
  elsif (-e "$wwwdir/$path.ttk") {
    ##-- handle template requests via cgi (e.g. http://HOST:PORT/profile?q=foo)
    return DiaColloDB::WWW::Handler::cgi->new(template=>"$wwwdir/$path.ttk");
  }
  elsif (-r "$wwwdir/$path") {
    ##-- handle static files
    return DiaColloDB::WWW::Handler::static->new(file=>"$wwwdir/$path");
  }

  return undef;
}

## $type_or_undef = $srv->mimetype($filename)
##  + gets stringified MIME-type of $filename via MIME::Types::mimeTypeOf()
sub mimetype {
  my ($srv,$file) = @_;
  $srv->logconfess("mimetype() called but no {mimetypes} key defined!") if (!defined($srv->{mimetypes}));
  my $type = $srv->{mimetypes}->mimeTypeOf($file);
  return defined($type) ? $type->type : undef;
}

##======================================================================
## Methods: Local: error handling

## undef = $srv->clientError($clientSock,$status,@message)
##  + send an error message to the client
##  + $status defaults to RC_INTERNAL_SERVER_ERROR
##  + shuts down the client socket
sub clientError {
  my ($srv,$csock,$status,@msg) = @_;
  if ($csock->opened) {
    my $chost = $csock->peerhost();
    my $msg   = join('',@msg);
    $status   = RC_INTERNAL_SERVER_ERROR if (!defined($status));
    $srv->vlog($srv->{logClientError}, "clientError($chost): $msg");
    if ($msg !~ /: client closed$/i) {
      ##-- don't try to write to sockets reporting 'client closed': this crashes the running server inexplicably!
      my $_warn=$^W;
      $^W=0;
      $csock->send_error($status, $msg);
      $^W=$_warn;
    }
    $csock->force_last_request();
    $csock->shutdown(2);
  }
  $csock->close() if (UNIVERSAL::can($csock,'close'));
  $@ = undef;     ##-- unset eval error
  return undef;
}


1; ##-- be happy

__END__
