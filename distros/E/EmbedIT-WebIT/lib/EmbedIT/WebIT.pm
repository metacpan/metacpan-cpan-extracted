package EmbedIT::WebIT;

use strict;
use POSIX;
use HTTP::Date qw(time2str time2iso);
use IO::Socket;
use IO::Select;
use LWP::MediaTypes qw(guess_media_type read_media_types);
use IPC::Open3;
use Taint::Runtime qw(disable);
no strict "refs";

our $VERSION = '1.6.3';
our $CRLF = "\015\012";

use vars qw(@childs $data);

# --------------------------------------------------------------------------------------
# Public functions
# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------
# Create a new web server object
#

sub new {
  my ($class, %conf) = @_;

  if (not defined %conf) {
    %conf = ();
  }

  EmbedIT::WebIT::__fix_conf(\%conf);
  EmbedIT::WebIT::__clean_env(\%conf);
  EmbedIT::WebIT::__report(\%conf);

  my $start_time = time();
  my $has_cgi_pm = undef;

  my $logging = $conf{"LOG_METHOD"};

  read_media_types($conf{"MIME_TYPES"});
  Taint::Runtime::taint_stop;

  #open STDIN, '</dev/null';
  #open STDOUT, '>>/dev/null';
  #open STDERR, '>>/dev/null';
 
  my @childs = ();
  $SIG{CHLD} = 'IGNORE';
  $SIG{SIGPIPE} = 'IGNORE';
  $SIG{TERM} = \&__stop_server;
  my $Server = undef;

  if (defined $conf{"USE_SSL"}) {
    $Server = EmbedIT::WebIT::__start_server_ssl(\%conf);
  } else {
    $Server = EmbedIT::WebIT::__start_server_socket(\%conf);
  }

  if (not defined $Server) {
    &$logging("Unable to open socket");
    return;
  }

  if (defined $conf{"RUN_AS_USER"}) {
    my $UID = EmbedIT::WebIT::__get_uid($conf{"RUN_AS_USER"});
    $> = $UID;
  }
  if (defined $conf{"RUN_AS_GROUP"}) {
    my $GID = EmbedIT::WebIT::__get_gid($conf{"RUN_AS_GROUP"});
    $) = "$GID $GID";
    $( = $GID;
  }

  my $self = {
               SERVER     => $Server,
               START_TIME => $start_time,
               HAS_CGI_PM => $has_cgi_pm,
               CONF       => \%conf,
             };

  bless $self;
  return $self;
}

# --------------------------------------------------------------------------------------
# Execute the server
#

sub execute {
  my ($self) = @_;

  my $logging = $self->{CONF}->{"LOG_METHOD"};

  if (defined $self->{SERVER}) {
    $0 = $self->{CONF}->{"PROC_PREFIX"} . " starting ";
    $self->__fork_workers();
    if ($self->{CONF}->{"SERVERS"} == 0) {
      $0 = $self->{CONF}->{"PROC_PREFIX"} . " server   (" . $self->{CONF}->{"SERVER_IP"} . ":" . $self->{CONF}->{"SERVER_PORT"} . ")";
      $self->__single_server(0, 1);
    } else {
      $self->__fork_servers();
      $0 = $self->{CONF}->{"PROC_PREFIX"} . " master   (" . $self->{CONF}->{"SERVER_IP"} . ":" . $self->{CONF}->{"SERVER_PORT"} . ")";
      waitpid(-1,0);
    }
    &$logging("Shuting down");
  } else {
    &$logging("Failed to start");
  }
}

# --------------------------------------------------------------------------------------
# Get the process specific data
#

sub data {
  my ($self) = @_;
  return $data;
}

# --------------------------------------------------------------------------------------
# Get the process startup time
#

sub start_time {
  my ($self) = @_;
  return $self->{START_TIME};
}

# --------------------------------------------------------------------------------------
# Private functions
# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------
# Stop the running web server
#

sub __stop_server {
  my ($self) = @_;
  $self->{SERVER}->close();
  kill "TERM", @childs;
}

# --------------------------------------------------------------------------------------
# Fork off the servers
#

sub __fork_servers {
  my ($self) = @_;
  my $conf = $self->{CONF};
  for (my $i = 0; $i < $conf->{"SERVERS"}; $i++) {
    my $pid = fork();
    if ($pid == 0) {
      $self->__single_server($i);
    } else {
      push @childs, $pid;
    }
  }
}

# --------------------------------------------------------------------------------------
# Fork off the page workers
#

sub __fork_workers {
  my ($self) = @_;
  my $conf = $self->{CONF};
  if ($conf->{"FORK_CONN"}) { return; }
  for (my $i = 0;  $i < $conf->{"WORKERS"}; $i++) {
    my $pid = fork();
    if ($pid == 0) {
      $self->__single_worker($i);
    } else {
      push @childs, $pid;
    }
  }
}

# --------------------------------------------------------------------------------------
# Start single server
#

sub __single_server {
  my ($self, $i, $avoid) = @_;
  my $conf = $self->{CONF};
  if ($conf->{"FORK_CONN"} == 0) {
    $self->__pre_fork("S$i");
  }
  if (not defined $avoid) {
    $0 = $conf->{"PROC_PREFIX"} . " listener ($i)";
    @childs = ();
  }
  if ($conf->{"FORK_CONN"} == 1) {
    $SIG{TERM} = \&__stop_server;
    $self->__fork_connections("S$i");
  } else {
    $self->__multiplex_connections("S$i");
  }
  if ($conf->{"FORK_CONN"} == 0) {
    $self->__post_fork("S$i");
  }
  exit 0;
}

# --------------------------------------------------------------------------------------
# Start single worker
#

sub __single_worker {
  my ($self, $i) = @_;
  my $conf = $self->{CONF};
  $self->__pre_fork("W$i");
  $0 = $conf->{"PROC_PREFIX"} . " worker   ($i)";
  @childs = ();
  $SIG{TERM} = 'DEFAULT'; 
  select(undef,undef,undef,undef);
  $self->__post_fork("W$i");
  exit 0;
}

# --------------------------------------------------------------------------------------
# Report configuration
#

sub __report {
  my ($conf) = @_;
  my $logging = $conf->{"LOG_METHOD"};

  &$logging("Staring " . $conf->{"SOFTWARE"} . " web server on " . 
       $conf->{"SERVER_IP"} . ":" . $conf->{"SERVER_PORT"} . 
       " with " . $conf->{"QUEUE_SIZE"} . " connection queue limit");

  if ($conf->{"USE_SSL"}) {
    &$logging("SSL will be used on all connections");
  }

  if ($conf->{"SERVERS"} > 0) {
    &$logging("PREFORKING " . $conf->{"SERVERS"} . " servers");
  } else {
    &$logging("SINGLE process server");
  }

  if ($conf->{"FORK_CONN"}) {
    &$logging("REQUESTS are forked");
  } else {
    &$logging("REQUESTS are multiplexed");
    if ($conf->{"WORKERS"} > 0) {
      &$logging("PREFORKING " . $conf->{"WORKERS"} . " page workers");
    } else {
      &$logging("WORKERS are embeded into SERVERS");
    }
  }

  if ($conf->{"WAIT_RESPONSE"}) {
    &$logging("RESPONSE will be sent normaly");
    if ($conf->{"IMMED_CLOSE"}) {
      &$logging("CONNECTION will close immediatelly regardless of client request");
    } else {
      &$logging("CONNECTION will remain open per client request");
    }
  } else {
    if (defined $conf->{"NO_WAIT_REPLY"}) {
      &$logging("RESPONSE " . $conf->{"NO_WAIT_REPLY"} . " will be sent before page load");
    } else {
      &$logging("RESPONSE 204 will be sent before page load");
    }
    &$logging("CONNECTION will close immediatelly regardless of client request");
  }

  if ($conf->{'LOG_PACKETS'}) {
    &$logging("PACKET contents will be logged");
  } elsif ($conf->{'LOG_HEADERS'}) {
    &$logging("HEADERS will be logged");
  }

  if (defined $conf->{"DOCUMENTS"}) {
    if (defined $conf->{"DOCUMENT_ROOT"}) {
      &$logging("EMBEDED pages with EXTERNAL pages on (" . $conf->{"DOCUMENT_ROOT"} . ")");
    } else {
      &$logging("EMBEDED pages");
    }
  } else {
    &$logging("EXTERNAL pages on (" . $conf->{"DOCUMENT_ROOT"} . ")");
  }

  if (defined $conf->{"CGI_PATH"}) {
    if ($conf->{"EMBED_PERL"}) {
      &$logging("CGI pages on (" . $conf->{"CGI_PATH_PRINT"} . ") with PERL embeded");
    } else {
      &$logging("CGI pages on (" . $conf->{"CGI_PATH_PRINT"} . ")");
    }
  }

  if (defined $conf->{"AUTH_PATH"}) {
    if (not defined $conf->{"AUTH_METHOD"}) {
      &$logging("AUTHENTICATION will always fail");
    } else {
      &$logging("AUTHENTICATION on (" . $conf->{"AUTH_PATH_PRINT"} . ")");
    }
  } else {
    &$logging("AUTHENTICATION is not defined for any path");
  }

  if (defined $conf->{"STARTUP"}) {
    &$logging("STARTUP script can be found in (" . $conf->{"STARTUP"}. ")");
  }

}

# --------------------------------------------------------------------------------------
# Start a single web server
#

sub __start_server_socket {
  my ($conf) = @_;
  return new IO::Socket::INET( LocalAddr => $conf->{"SERVER_IP"},
                               LocalPort => $conf->{"SERVER_PORT"},
                               Proto     => 'tcp',
                               Reuse     => 1,
                               Listen    => $conf->{"QUEUE_SIZE"}) || return undef;
}

# --------------------------------------------------------------------------------------
# Start a single SSL web server
#

sub __start_server_ssl {
  my ($conf) = @_;
  return new IO::Socket::INET( LocalAddr => $conf->{"SERVER_IP"},
                               LocalPort => $conf->{"SERVER_PORT"},
                               Proto     => 'tcp',
                               Reuse     => 1,
                               Listen    => $conf->{"QUEUE_SIZE"}) || return undef;
}

# --------------------------------------------------------------------------------------
# Start accepting connecitons
#

sub __multiplex_connections {
  my ($self, $id) = @_;
  my $conf = $self->{CONF};
  my $d = $self->{SERVER};

  $d->blocking(0);

  my %buffers = ();
  my $logging = $conf->{"DEBLOG_METHOD"};
  my $read_handles = new IO::Select();
  my $write_handles = new IO::Select();
  $read_handles->add($d);

  while (1) {
    my @ret = IO::Select->select($read_handles, $write_handles, undef, undef);
    if ((not defined @ret) || (@ret == 0)) { &$logging("[$id] has failed on select"); return; }
    my ($rset, $wset, $eset) = @ret;

    my $r = scalar(@$rset);
    my $w = scalar(@$wset);
    my $e = scalar(@$eset);
 
    foreach my $fh (@$rset) {
      my $no = $fh->fileno;
      if ($fh == $d) {
        my $ns = $d->accept();
        if (defined $ns) {
          $ns->blocking(0);
          $ns->autoflush(0);
          $read_handles->add($ns);
          $no = $ns->fileno;
          $buffers{$no}{InBuffer} = '';
          $buffers{$no}{OutBuffer} = '';
          $buffers{$no}{AutoClose} = 0;
          $buffers{$no}{CloseAfter} = 0;
          $buffers{$no}{CLen} = -1;
          $buffers{$no}{CPos} = 0;
          $buffers{$no}{Socket} = $ns;
          &$logging("[$id] NEW connection [$no] from " . $ns->peerhost . ":" . $ns->peerport);
        } 
      } else {
        if (!$self->__fill_buffer($id, $fh, \%{$buffers{$no}})) {
          $read_handles->remove($fh);
          $write_handles->remove($fh);
          close($fh);
          delete $buffers{$no};
          &$logging("[$id] END connection (1) [$no]");
        }

        if ($buffers{$no}{AutoClose}) {
          $read_handles->remove($fh);
          $write_handles->remove($fh);
          delete $buffers{$no};
          close($fh);
          &$logging("[$id] END connection (2) [$no]");
        } else {
          if ($buffers{$no}{OutBuffer} ne '') {
            $write_handles->add($fh);
            $read_handles->remove($fh);
          }
        }
      }
    }

    foreach my $fh (@$wset) {

      my $no = $fh->fileno;
      my $size = length($buffers{$no}{OutBuffer});

      if ($size == 0) { 
        $write_handles->remove($fh);
        if ($buffers{$no}{CloseAfter}) {
          $read_handles->remove($fh);
          delete $buffers{$no};
          close($fh);
          &$logging("[$id] END connection (3) [$no]");
        } else {
          $read_handles->add($fh);
        }
      } else {
        if (!$self->__socket_write($id, $fh, $size, \%{$buffers{$no}})) {
          $read_handles->remove($fh);
          $write_handles->remove($fh);
          delete $buffers{$no};
          close($fh);
          &$logging("[$id] END connection (4) [$no]");
        }
      }

    }

  }

}

# --------------------------------------------------------------------------------------
# Start a single forking web server
#

sub __fork_connections {
  my ($self, $id) = @_;
  my $conf = $self->{CONF};
  my $d = $self->{SERVER};
  my $logging = $conf->{"DEBLOG_METHOD"};
  my $handles = new IO::Select();

  $d->blocking(0);
  $handles->add($d);

  while (1) {
    my @ret = IO::Select->select($handles, undef, undef, undef);
    if (not defined @ret) { return; }
    if (@ret == 0) { &$logging("[$id] has failed on select"); return; }
    my ($rset, $wset, $eset) = @ret;

    my $c = $d->accept();
    if (defined $c) {
      $c->blocking(0);
      $c->autoflush(0);
      my $pid = fork();
      if ($pid == 0) {                  
        $self->__pre_fork("S$id");
        $0 = $conf->{"PROC_PREFIX"} . " serving  (" . $c->peerhost . ":" . $c->peerport . ")";
        &$logging("NEW connection from " . $c->peerhost . ":" . $c->peerport);
        $self->__forked_loop($id, $c);
        $self->__post_fork("S$id");
        exit 0;
      } else {
        push @childs, $pid;
        my $ended = waitpid(-1,WNOHANG);
        if ($ended > 0) {
          for (my $i = 0; $i < @childs; $i++) {
             if ($childs[$i] == $ended) {
               splice(@childs,$i,1);
               last;
             }
          }
        }
      }
    }

  } 
}

# --------------------------------------------------------------------------------------
# Main loop of a forked child
#

sub __forked_loop {
  my ($self, $id, $c) = @_;
  my $conf = $self->{CONF};
  my $logging = $conf->{"DEBLOG_METHOD"};

  my %buffer = ();
  $buffer{InBuffer} = '';
  $buffer{OutBuffer} = '';
  $buffer{AutoClose} = 0;
  $buffer{CloseAfter} = 0;
  $buffer{CLen} = -1;
  $buffer{CPos} = 0;
  $buffer{Socket} = $c;

  my $read_handles = new IO::Select();
  my $write_handles = new IO::Select();
  $read_handles->add($c);

  my $exit_loop = 0;

  while (1) {
    if ($exit_loop) { last; }
    my @ret = IO::Select->select($read_handles, $write_handles, undef, undef);
    if ((not defined @ret) || (@ret == 0)) { &$logging("[$id] has failed on select"); return; }
    my ($rset, $wset, $eset) = @ret;

    foreach my $fh (@$rset) {

      my $no = $fh->fileno;

      if (!$self->__fill_buffer($id, $fh, \%buffer)) {
        $read_handles->remove($fh);
        $write_handles->remove($fh);
        close($fh);
        &$logging("[$id] END connection [$no]");
        $exit_loop = 1;
      }

      if ($buffer{AutoClose}) {
        $read_handles->remove($fh);
        $write_handles->remove($fh);
        close($fh);
        &$logging("[$id] END connection [$no]");
        $exit_loop = 1;
      } else {
        if ($buffer{OutBuffer} ne '') {
          $write_handles->add($fh);
          $read_handles->remove($fh);
        }
      }
    }

    foreach my $fh (@$wset) {

      my $no = $fh->fileno;

      my $size = length($buffer{OutBuffer});

      if ($size == 0) { 
        $read_handles->add($fh);
        $write_handles->remove($fh);
        if ($buffer{CloseAfter}) {
          $read_handles->remove($fh);
          close($fh);
          &$logging("[$id] END connection [$no]");
          $exit_loop = 1;
        }
      } else {
        if (!$self->__socket_write($id, $fh, $size, \%buffer)) {
          $read_handles->remove($fh);
          $write_handles->remove($fh);
          close($fh);
          &$logging("[$id] END connection [$no]");
          $exit_loop = 1;
        }
      }

    }

  }

}

# --------------------------------------------------------------------------------------
# Try to fill out the buffer of the connection
#

sub __fill_buffer {
  my ($self, $id, $c, $buf) = @_;
  my $conf = $self->{CONF};
  my $res;
  
  $res = $self->__socket_read($id, $c, $buf);
  if ($res < 0) {
    $buf->{InBuffer} = '';
    $buf->{CLen} = -1;
    $buf->{CPos} = 0;
    return 0;
  } elsif ($res == 1) {
    my $r = $self->__parse_http_request($buf->{InBuffer});
    $buf->{InBuffer} = '';
    $buf->{CLen} = -1;
    $buf->{CPos} = 0;
    return $self->__handle_request($id, $c, $r, $buf);
  } else {
    return 1;
  }
}

# --------------------------------------------------------------------------------------
# Try to send out the buffer to the connection
#

sub __socket_write {
  my ($self, $id, $c, $size, $buf) = @_;
  my $conf = $self->{CONF};
  
  my $res;
  eval {
    #$res = $c->send($buf->{OutBuffer});
    $res = syswrite($c, $buf->{OutBuffer}, length($buf->{OutBuffer}));
  };
  if ($@) {
    my $logging = $conf->{'DEBLOG_METHOD'};
    &$logging("[$id] " . $@);
    return 0;
  }

  if ($res) {
    if ($res == 0) { return 0; }
    $buf->{OutBuffer} = substr($buf->{OutBuffer}, $res);
    return 1;
  } else {
    return 0;
  }
}

# --------------------------------------------------------------------------------------
# Read from socket and fill out the given buffer
#

sub __socket_read {
  my ($self, $id, $c, $buf) = @_;
  my $conf = $self->{CONF};
  
  my $tbuf = '';
  my $read = 0;

  #$read = $c->read($tbuf, 8192);
  $read = sysread($c, $tbuf, 8192);
  if (not defined $read) { 
    my $errstr = $!;
    my $errno  = $! + 0;
    if ($errno != 0) {
      my $logging = $conf->{'DEBLOG_METHOD'};
      &$logging("[$id] Socket read error was [$errno] ($errstr)");
    }
    return -1;                # socket read got an error
  }

  if ($read == 0) {
    return -1;                # socket closed
  }

  $buf->{InBuffer} .= $tbuf;

  if ($buf->{CLen} < 0) { 
    my $pos;
    if (($pos = index($buf->{InBuffer}, "$CRLF$CRLF")) > 0) {     # we have full headers
      if ($buf->{InBuffer} =~ /Content-Length:\s*(\d+)/io) {
        $buf->{CLen} = $1;
      } else {
        $buf->{CLen} = 0;
      }
      $buf->{CPos} = $pos;
    } else {
      return 0;               # not a complete packet yet
    }
  } 

  if ($buf->{CLen} >= 0) {
    my $expected = $buf->{CPos} + $buf->{CLen} + 4;     # we have up to a point. Read the remaining
    if (length($buf->{InBuffer}) < $expected) {
      return 0;
    }
  } else {
    return 0;
  }

  return 1;               # we have a complete packet
}

# --------------------------------------------------------------------------------------
# Parse a request packet
#

sub __parse_http_request {
  my ($self, $packet) = @_;
  my $conf = $self->{CONF};

  my $spacket = $packet;
  my %request = ();

  my $head = '';

  $packet =~ s/^(.*)\n?//o;
  my $line = $1;
  $line =~ s/\r//gco;
  $line =~ s/^\s*//go;
  my ($meth, $uri, $ver) = split(/\s+/o, $line);

  $head .= $line . $CRLF;

  if ($uri =~ /(.*?)\?(.*)/o) {
    $request{URI} = $1;
    $request{QUERY_STRING} = $2;
  } else {
    $request{URI} = $uri;
    $request{QUERY_STRING} = '';
  }
  $request{METHOD} = $meth;
  $request{VERSION} = $ver;

  while (1) {
    $packet =~ s/^(.*)\n?//o;
    $line = $1;
    $line =~ s/\r//gco;
    $line =~ s/^\s*//go;
    my ($k, $v) = ($line =~ /^\s*(.*?)\s*?\:\s*?(.*)/o);
    if ($k ne '') {
      $head .= $line . $CRLF;
      $v =~ s/^\s*//go;
      $v =~ s/\s*$//go;
      $request{HEADERS}{uc($k)} = $v;
    } else {
      $head .= $CRLF;
      last;
    }
  }

  my $logging = $conf->{"DEBLOG_METHOD"};

  if ($conf->{'LOG_PACKETS'}) {
    &$logging($spacket);
  } else {
    if ($conf->{'LOG_HEADERS'}) {
      &$logging($head);
    }
  }

  $request{CONTENT} = $packet;

  return \%request;
}

# --------------------------------------------------------------------------------------
# Handle a request
#

sub __handle_request {
  my ($self, $id, $c, $r, $buf) = @_;
  my $conf = $self->{CONF};

  if (not defined $r->{METHOD}) {
    return 0;
  } else {
    if ($conf->{"WAIT_RESPONSE"} == 0) {
      my $page = $self->__make_response($conf->{"NO_WAIT_REPLY"}, undef, undef, 0);
      $c->blocking(1);
      print $c, $page;
      $buf->{AutoClose} = 1;
      close($c);
      $self->__get_page($id, $c->peerhost, $c->peerport, $r, 0);
    } else {
      my $page = $self->__get_page($id, $c->peerhost, $c->peerport, $r, 1);
      $buf->{OutBuffer} .= $page;
      if (($conf->{"IMMED_CLOSE"}) || ($r->{HEADERS}{'CONNECTION'} eq 'Close')) {
        $buf->{CloseAfter} = 1;
      }
    }
  }
  return 1;
}

# --------------------------------------------------------------------------------------
# Get the requested page
#

sub __get_page {
  my ($self, $id, $rhost, $rport, $r, $err) = @_;
  my $conf = $self->{CONF};

  my $page = undef;

  my $logging = $conf->{"LOG_METHOD"};
  my $logging2 = $conf->{"DEBLOG_METHOD"};
  my $path = $r->{URI};
  my $embed = undef;
  my $script = undef;
  my $inauth_space = 0;

  $path =~ s/\/\//\//gco;

  if ($path =~ /\/$/o) {
    $path .= "index.html";
  }

  if (exists $conf->{"DOCUMENTS"}{$path}) {
    $embed = 1;
  } else {
    if (defined $conf->{"DOCUMENT_ROOT"}) {
      my $fname = $conf->{"DOCUMENT_ROOT"} . $path;
      $fname =~ s/\/\//\//gco;
      if (! -e $fname) {
        if (exists $conf->{"DOCUMENTS"}{'*'}) {
          $embed = 1;
        } else {
          if ($path =~ /$conf->{"CGI_PATH"}/) {
            if ($conf->{"SETUP_ENV"}) {
              $script = 1;
              $ENV{"SCRIPT_NAME"} = $path;
              $ENV{"SCRIPT_FILENAME"} = $fname;
              $ENV{"QUERY_STRING"} = "";
            }
          }
        }
      } else {
        if ($path =~ /$conf->{"CGI_PATH"}/) {
          if ($conf->{"SETUP_ENV"}) {
            $script = 1;
            $ENV{"SCRIPT_NAME"} = $path;
            $ENV{"SCRIPT_FILENAME"} = $fname;
            $ENV{"QUERY_STRING"} = "";
          }
        }
      }
    } else {
      if (exists $conf->{"DOCUMENTS"}{'*'}) {
        $embed = 1;
      }
    }
  }

  # &$logging("[$id] Request was \n" . $r->as_string());

  $ENV{"REQUEST_URI"} = $path;

  my $pmeth = sprintf("%-4s", $r->{METHOD});

  my ($auth_ok, $page) = $self->__is_auth_ok($id, $rhost, $rport, $r, $path, $inauth_space, $err);
  if ($auth_ok) {

    if ($conf->{"SETUP_ENV"}) { 
      $self->__fix_env($r); 
    }
    $ENV{"REMOTE_PORT"} = $rport;
    $ENV{"REMOTE_ADDR"} = $rhost;

    my $retval = undef;
    my $reterr = undef;

    my $type = '';

    if ($r->{METHOD} =~ /GET|HEAD|POST/o) {
      if ($script) {
        if (($conf->{"EMBED_PERL"} == 1) && ($path =~ /\.pl$/o)) {
          $type = 'PERL ';
          ($retval, $reterr, $page) = $self->__do_perl($id, $path, $r, $inauth_space);
          if (!$retval) {
            &$logging2("[$id] Script error ($reterr) on (" . $r->{URI} . ")");
            if ($err) {
              $page = $self->__make_error($reterr, $inauth_space, $id, $rhost, $rport, $r);
            }
          }
        } else {
          $type = 'CGI  ';
          ($retval, $reterr, $page) = $self->__do_cgi($id, $path, $r, $inauth_space);
          if (!$retval) {
            &$logging2("[$id] Script error ($reterr) on (" . $r->{URI} . ")");
            if ($err) {
              $page = $self->__make_error($reterr, $inauth_space, $id, $rhost, $rport, $r);
            }
          }
        }
      } elsif ($embed) {
        $type = 'EMBED';
        ($retval, $reterr, $page) = $self->__do_embeded($id, $path, $r, $inauth_space);
        if (!$retval) {
          &$logging2("[$id] Embeded function error ($reterr) on ($path)");
          if ($err) {
            $page = $self->__make_error($reterr, $inauth_space, $id, $rhost, $rport, $r);
          }
        }
      } else {
        $type = 'FILE ';
        ($retval, $reterr, $page) = $self->__do_file($path, $r, $inauth_space);
        if (!$retval) {
          &$logging2("[$id] FILE (" . $r->{URI} . ") not found");
          if ($err) {
            $page = $self->__make_error($reterr, $inauth_space, $id, $rhost, $rport, $r);
          }
        }
      }
    } else {
      $type = 'FAIL ';
      &$logging2("[$id] Method $pmeth for (" . $r->{URI} . ") is not implemented");
      if ($err) {
        $reterr = 405;
        $page = $self->__make_error($reterr, $inauth_space, $id, $rhost, $rport, $r);
      }
    }

    &$logging("[$id] $pmeth [$type] from $rhost:$rport ($path) got ($reterr " . $conf->{'HTML_CODES'}{$reterr}. ")");

  } else {
    &$logging("[$id] $pmeth from $rhost:$rport ($path) failed authentication");
  }

  return $page;
}

# --------------------------------------------------------------------------------------
# Get the authorization from the packet -- packet
#

sub __get_authorization {
  my ($self, $r, $log) = @_;

  my $h = $r->{HEADERS}->{'AUTHORIZATION'};

  if (defined $h) { 
    $h =~ s/^\s*Basic\s+//gco;
    require MIME::Base64;
    my $val = MIME::Base64::decode_base64($h);
    return $val unless wantarray;
    return split(/:/, $val, 2);
  }
  return;
}

# --------------------------------------------------------------------------------------
# Check if we are in a path with authentication and authentication data exists
#

sub __is_auth_ok {
  my ($self, $id, $rhost, $rport, $r, $path, $inauth_space, $err) = @_;
  my $conf = $self->{CONF};

  if (not defined $conf->{"AUTH_PATH"}) { return (1, undef); }

  my $auth_f = $conf->{"AUTH_METHOD"};
  my $logging = $conf->{"DEBLOG_METHOD"};
  my $logging2 = $conf->{"LOG_METHOD"};
  my $page = undef;

  if ($path =~ /$conf->{"AUTH_PATH"}/) {
    my $five = 5;
    $_[$five] = 1;
    my ($user, $pass) = $self->__get_authorization($r, $logging);
    if (not defined $user) {
      $page = $self->__make_response("401", undef, undef, 1);
      &$logging("[$id] AUTH to $rhost:$rport ($path)");
      return (0, $page);
    } else {
      if (not defined $auth_f) {
        if ($conf->{"SETUP_ENV"}) {
          $ENV{"REMOTE_USER"} = $user;
          $ENV{"AUTH_TYPE"} = "Basic";
        }
        return (1, $page);
      } elsif (&$auth_f($user, $pass)) {
        if ($conf->{"SETUP_ENV"}) {
          $ENV{"REMOTE_USER"} = $user;
          $ENV{"AUTH_TYPE"} = "Basic";
        }
        return (1, $page);
      } else {
        if ($err) {
          $page = $self->__make_error("403", 1, $id, $rhost, $rport, $r);
        }
        &$logging2("[$id] REJECT to $rhost:$rport for ($user) on ($path)");
        return (0, $page);
      }
    }
  }
  return (1, $page);
}

# --------------------------------------------------------------------------------------
# get the expiration time for a given media type 
#

sub __get_type_expiration {
  my ($self, $type) = @_;
  my $conf = $self->{CONF};

  my $exp = undef;                 # default is not defined

  if (exists $conf->{'EXPIRATIONS'}) {
    if (exists $conf->{'EXPIRATIONS'}->{$type}) {
      $exp = $conf->{'EXPIRATIONS'}->{$type};
    } else {
      if (exists $conf->{'EXPIRATIONS'}->{'ALL'}) {
        $exp = $conf->{'EXPIRATIONS'}->{'ALL'};
      }
    }
  } 

  return $exp;
}

# --------------------------------------------------------------------------------------
# send file
#

sub __do_file {
  my ($self, $p, $r, $auth) = @_;
  my $conf = $self->{CONF};

  my $res = "";
  my $page = undef;

  if ($conf->{"WAIT_RESPONSE"} == 0) { 
    return (1, 200, $self->__make_response("200", undef, undef, undef)); 
  }

  if (not defined $conf->{"DOCUMENT_ROOT"}) { 
    return (0, 404, $self->__make_response("404", undef, undef, undef)); 
  }

  $p = $conf->{"DOCUMENT_ROOT"} . $p;

  if (-e $p) {
    my %headers = ();

    if ($r->{METHOD} eq "HEAD") {
      return (1, 200, $self->__make_response("200", undef, undef, $auth));
    } else {
      my @s = stat($p);
      my $nine = 9;
      my $seven = 7;
      my $mdate = time2str($s[$nine]);
      my $size = $s[$seven];

      my ($type, $enc) = guess_media_type($p);
      my $expiration = $self->__get_type_expiration($type);

      if ($r->{HEADERS}{"IF-MODIFIED-SINCE"} eq $mdate) {
        $headers{'Date'} = time2str(time);
        $headers{'Last-Modified'} = $mdate;
        if ((defined $expiration) && ($expiration =~ /\d+/)) {
          $headers{'Cache-Control'} = "max-age=$expiration, must-revalidate";
          $headers{'Expires'} = time2str(time + $expiration);
        }

        return (1, 304, $self->__make_response("304", \%headers, undef, $auth));
      } 

#      if ($r->{HEADERS}{"IF-UNMODIFIED-SINCE"} ne $mdate) {
#        return (1, 412, __make_response("412", undef, undef, $auth, $conf));
#      }

      $res = $self->__load_file($p);
      if (not defined $res) { 
        return (0, 404, $self->__make_response("404", undef, undef, $auth));
      }

      if (length($res) > 0) {
        if ($enc ne '') {
          $headers{'Content-Encoding'} = $enc;
        }

        $headers{'Content-Type'} = $type;
        $headers{'Date'} = time2str(time);
        $headers{'Last-Modified'} = $mdate;
        if ((defined $expiration) && ($expiration =~ /\d+/)) {
          $headers{'Cache-Control'} = "max-age=$expiration, must-revalidate";
          $headers{'Expires'} = time2str(time + $expiration);
        }

        $res = $CRLF . $CRLF . $res;

        return (1, 200, $self->__make_response("200", \%headers, $res, $auth));
      }
    }
  }

  return (0, 404, $self->__make_response("404", undef, undef, $auth));
}

# --------------------------------------------------------------------------------------
# Run an embeded function
#

sub __do_embeded {
  my ($self, $id, $s, $r, $auth) = @_;
  my $conf = $self->{CONF};

  my $logging = $conf->{"DEBLOG_METHOD"};
  my $p = $r->{CONTENT};
  my $page = undef;
  my $post = 0;
  my $sub = $conf->{"DOCUMENTS"}{$s};

  if (not defined $sub) {
    $sub = $conf->{"DOCUMENTS"}{'*'};
  }
  
  if ((defined $sub) && (exists &$sub)) {
    $ENV{'REQUEST_METHOD'} = $r->{METHOD};
    if ($r->{METHOD} =~ /GET|HEAD/o) {
      $ENV{"QUERY_STRING"} = $r->{'QUERY_STRING'};
    } else {
      $post = 1;
    }
    if ($r->{METHOD} =~ /GET/o) {
      if ($r->{HEADERS}{"IF-MODIFIED-SINCE"} eq time2str($self->{START_TIME})) {
        my %headers = ();
        $headers{'Date'} = time2str($self->{START_TIME});
        $headers{'Last-Modified'} = time2str($self->{START_TIME});

        my $expiration = undef;
        if (exists $conf->{'EXPIRATIONS'}->{'ALL'}) {
          $expiration = $conf->{'EXPIRATIONS'}->{'ALL'};
        }
        if ((defined $expiration) && ($expiration =~ /\d+/)) {
          $headers{'Cache-Control'} = "max-age=$expiration, must-revalidate";
          $headers{'Expires'} = time2str($self->{START_TIME} + $expiration);
        }

        return (1, 304, $self->__make_response("304", \%headers, undef, $auth));
      }
    }
    if ($conf->{"SETUP_ENV"}) {
      if (exists $r->{HEADERS}{"CONTENT-TYPE"}) { $ENV{"CONTENT_TYPE"} = $r->{HEADERS}{"CONTENT-TYPE"}; }
      if (exists $r->{HEADERS}{"CONTENT-ENCODING"}) { $ENV{"CONTENT_ENCODING"} = $r->{HEADERS}{"CONTENT-ENCODING"}; }
      if (exists $r->{HEADERS}{"CONTENT-LENGTH"}) { $ENV{"CONTENT_LENGTH"} = $r->{HEADERS}{"CONTENT-LENGTH"}; }
      if (exists $r->{HEADERS}{"CONTENT-LANGUAGE"}) { $ENV{"CONTENT_LANGUAGE"} = $r->{HEADERS}{"CONTENT-LANGUAGE"}; }
    }

    my $res = '';
    my $errs = '';
    my $evalerrs = '';

    # save all STD files
    open OLDERR, ">&STDERR";
    open OLDOUT, ">&STDOUT";
    open OLDIN, "<&STDIN";

    # reopen STDIN to $p string if we have POST
    close STDIN;
    open STDIN, "<", \$p;
    binmode STDIN;

    # reopen STDOUT to $res string
    close STDOUT;
    open STDOUT, ">", \$res;
    binmode STDOUT;

    # reopen STDERR to $errs string
    close STDERR;
    open STDERR, ">", \$errs;

    if ($self->{HAS_CGI_PM}) {
      eval('CGI::initialize_globals();');
    } else {
      for my $k (keys %INC) {
        if ($k eq 'CGI.pm') {
    $self->{HAS_CGI_PM} = 1;
          eval('CGI::initialize_globals();');
    last;
        }
      }
    }

    eval {
      &$sub($data);
    };
 
    $evalerrs = $@;

    # restore STD files
    close STDOUT;
    open STDOUT, ">&OLDOUT";
    close OLDOUT;
    close STDERR;
    open STDERR, ">&OLDERR";
    close OLDERR;
    close STDIN;
    open STDIN, "<&OLDIN";
    close OLDIN;

    if ($conf->{"SETUP_ENV"}) {
      delete $ENV{"QUERY_STRING"};
      delete $ENV{"CONTENT_TYPE"};
      delete $ENV{"CONTENT_ENCODING"};
      delete $ENV{"CONTENT_LENGTH"};
      delete $ENV{"CONTENT_LANGUAGE"};
    }

    $errs .= $evalerrs;
  
    if (length($errs) > 0) {
      &$logging("[$id] ($s) \n$errs");
    }

    if ($conf->{"WAIT_RESPONSE"} == 0) { return (1, 200, $page); }

    if ($evalerrs ne '') {
      return (0, 500, $self->__make_response("500", undef, undef, $auth));
    } else {
      if ($r->{METHOD} eq "HEAD") {
        return (1, 200, $self->__make_response("200", undef, undef, $auth));
      } else {
        return (1, 200, $self->__make_response("200", undef, $res, $auth));
      }
    }
  } else {
    return (0, 404, $page);
  }
}

# --------------------------------------------------------------------------------------
# Run a perl script
#

sub __do_perl {
  my ($self, $id, $s, $r, $auth) = @_;
  my $conf = $self->{CONF};

  my $logging = $conf->{"DEBLOG_METHOD"};
  my $p = $r->{'CONTENT'};
  my $page = undef;
  my $post = 0;

  $s = $conf->{"DOCUMENT_ROOT"} . $s;

  if (-e $s) {
    $ENV{'REQUEST_METHOD'} = $r->{METHOD};
    if ($r->{METHOD} =~ /GET|HEAD/o) {
      $ENV{"QUERY_STRING"} = $r->{'QUERY_STRING'};
    } else {
      $post = 1;
    }
    if ($conf->{"SETUP_ENV"}) {
      if (exists $r->{HEADERS}{"CONTENT-TYPE"}) { $ENV{"CONTENT_TYPE"} = $r->{HEADERS}{"CONTENT-TYPE"}; }
      if (exists $r->{HEADERS}{"CONTENT-ENCODING"}) { $ENV{"CONTENT_ENCODING"} = $r->{HEADERS}{"CONTENT-ENCODING"}; }
      if (exists $r->{HEADERS}{"CONTENT-LENGTH"}) { $ENV{"CONTENT_LENGTH"} = $r->{HEADERS}{"CONTENT-LENGTH"}; }
      if (exists $r->{HEADERS}{"CONTENT-LANGUAGE"}) { $ENV{"CONTENT_LANGUAGE"} = $r->{HEADERS}{"CONTENT-LANGUAGE"}; }
    }

    my $script = $self->__load_file($s);
    if (not defined $script) { return (0, 400, $page); }

    my $res = '';
    my $errs = '';
    my $evalerrs = '';

    # save all STD files
    open OLDERR, ">&STDERR";
    open OLDOUT, ">&STDOUT";
    open OLDIN, "<&STDIN";

    # reopen STDIN to $p string if we have POST
    close STDIN;
    open STDIN, "<", \$p;
    binmode STDIN;

    # reopen STDOUT to $res string
    close STDOUT;
    open STDOUT, ">", \$res;
    binmode STDOUT;

    # reopen STDERR to $errs string
    close STDERR;
    open STDERR, ">", \$errs;

    if ($self->{HAS_CGI_PM}) {
      eval('CGI::initialize_globals();');
    } else {
      for my $k (keys %INC) {
        if ($k eq 'CGI.pm') {
    $self->{HAS_CGI_PM} = 1;
          eval('CGI::initialize_globals();');
        }
      }
    }

    eval {
      eval($script);
      $evalerrs = $@;
    };

    # restore STD files
    close STDOUT;
    open STDOUT, ">&OLDOUT";
    close OLDOUT;
    close STDERR;
    open STDERR, ">&OLDERR";
    close OLDERR;
    close STDIN;
    open STDIN, "<&OLDIN";
    close OLDIN;

    if ($conf->{"SETUP_ENV"}) {
      delete $ENV{"QUERY_STRING"};
      delete $ENV{"CONTENT_TYPE"};
      delete $ENV{"CONTENT_ENCODING"};
      delete $ENV{"CONTENT_LENGTH"};
      delete $ENV{"CONTENT_LANGUAGE"};
    }
  
    $errs .= $evalerrs;

    if (length($errs) > 0) {
      &$logging("[$id] ($s) \n$errs");
    }

    if ($conf->{"WAIT_RESPONSE"} == 0) { return (1, 200, $page); }

    if ($evalerrs ne '') {
      return (0, 500, $page);
    } else {
      if ($r->{METHOD} eq "HEAD") {
        return (1, 200, $self->__make_response("200", undef, undef, $auth));
      } else {
        return (1, 200, $self->__make_response("200", undef, $res, $auth));
      }
    }
  } else {
    return (0, 404, $page);
  }
}

# --------------------------------------------------------------------------------------
# Run a CGI script
#

sub __do_cgi {
  my ($self, $id, $s, $r, $auth) = @_;
  my $conf = $self->{CONF};

  my $logging = $conf->{"DEBLOG_METHOD"};
  my $p = $r->{'CONTENT'};
  my $page = undef;
  my $post = 0;

  $s = $conf->{"DOCUMENT_ROOT"} . $s;

  if (-e $s) {
    $ENV{'REQUEST_METHOD'} = $r->{METHOD};
    if ($r->{METHOD} =~ /GET|HEAD/o) {
      $ENV{"QUERY_STRING"} = $r->{'QUERY_STRING'};
    } else {
      $post = 1;
    }
    if ($conf->{"SETUP_ENV"}) {
      if (exists $r->{HEADERS}{"CONTENT-TYPE"}) { $ENV{"CONTENT_TYPE"} = $r->{HEADERS}{"CONTENT-TYPE"}; }
      if (exists $r->{HEADERS}{"CONTENT-ENCODING"}) { $ENV{"CONTENT_ENCODING"} = $r->{HEADERS}{"CONTENT-ENCODING"}; }
      if (exists $r->{HEADERS}{"CONTENT-LENGTH"}) { $ENV{"CONTENT_LENGTH"} = $r->{HEADERS}{"CONTENT-LENGTH"}; }
      if (exists $r->{HEADERS}{"CONTENT-LANGUAGE"}) { $ENV{"CONTENT_LANGUAGE"} = $r->{HEADERS}{"CONTENT-LANGUAGE"}; }
    }
  
    my $pid;
    my $res;
    my $errs;

    my ($IN, $OUT, $ERR);

    use Symbol;
    $ERR = Symbol::gensym;

    if ($r->{METHOD} =~ /GET|HEAD/o) {
      $pid = IPC::Open3::open3($IN,$OUT,$ERR,$s,$p) or return (0, 503, $page);
    } else {
      $pid = IPC::Open3::open3($IN,$OUT,$ERR,$s) or return (0, 503, $page);
      
      binmode $IN;
      print $IN $p;
      close $IN;
    } 

    my $sel = new IO::Select;

    $sel->add($OUT,$ERR);

    while(my @ready = $sel->can_read) {
      foreach my $fh (@ready) {
        my $line = <$fh>;
        if (not defined $line) {
          $sel->remove($fh);
          next;
        }
        if    ($fh == $OUT) { $res  .= $line; }
        elsif ($fh == $ERR) { $errs .= $line; }
      }
    }

    if ($conf->{"SETUP_ENV"}) {
      delete $ENV{"QUERY_STRING"};
      delete $ENV{"CONTENT_TYPE"};
      delete $ENV{"CONTENT_ENCODING"};
      delete $ENV{"CONTENT_LENGTH"};
      delete $ENV{"CONTENT_LANGUAGE"};
    }
  
    if (length($errs) > 0) {
      &$logging("[$id] ($s) \n$errs");
    }
  
    if ($conf->{"WAIT_RESPONSE"} == 0) { return (1, 200, $page); }

    if ($r->{METHOD} eq "HEAD") {
      return (1, 200, $self->__make_response("200", undef, undef, $auth));
    } else {
      return (1, 200, $self->__make_response("200", undef, $res, $auth));
    }
  } else {
    return (0, 404, $page);
  }
}

# --------------------------------------------------------------------------------------
# Make response to client given variable contents
#

sub __make_response {
  my ($self, $code, $headers, $cont, $auth) = @_;
  my $conf = $self->{CONF};

  my $logging = $conf->{"DEBLOG_METHOD"};
  my $msg = $conf->{"HTML_CODES"}{$code};
  my $len = 0;
  my $page = undef;
  my $base_headers = '';
  if ($auth) {
    $base_headers = "WWW-Authenticate: Basic realm=\"" . $conf->{"AUTH_REALM"} . "\"$CRLF";
  }
  my $http = "HTTP/1.1 $code ($msg) $CRLF";
  my $len = "Content-Length: 0$CRLF";

  $base_headers .= "Server: WebIT $VERSION$CRLF";

  my $extra_headers = '';

  if (defined $headers) {
    if (ref($headers) eq 'HASH') {
      for my $k (keys %$headers) {
        $extra_headers .= $k . ': ' . $headers->{$k} . $CRLF;
      }
    } elsif (ref($headers) eq '') {
      $extra_headers = $headers;
    } 
  }

  my $hr = $cont;
  if (defined $cont) {
    my $split;
    ($hr, $split, $cont) = split(/($CRLF$CRLF|\n\n)/, $cont, 2);
    if (($cont eq '') && ($split eq '')) {
      $cont = $hr;
      $hr = '';
    }  
    $hr =~ s/($CRLF|\n)$//gc;
    if ($hr ne '') {
      $http .= $hr . $CRLF;
    }
    $len = "Content-Length: " . length($cont) . $CRLF;
  } 

  my $total_headers = $http . $base_headers . $extra_headers . $len . $CRLF;

  $page = $total_headers . $cont;

  if ($conf->{'LOG_PACKETS'}) {
    &$logging($page);
  } else {
    if ($conf->{'LOG_HEADERS'}) {
      &$logging($total_headers);
    }
  }

  return $page;
}

# --------------------------------------------------------------------------------------
# Make response given error and check if there is an error page to send as well
#

sub __make_error {
  my ($self, $code, $auth, $id, $rhost, $rport, $r) = @_;
  my $conf = $self->{CONF};

  my $msg = $conf->{"HTML_CODES"}{$code};
  my $logging = $conf->{"LOG_METHOD"};

  my $page = undef;

  if ($conf->{'SETUP_ENV'}) {
    $ENV{'ERROR_CODE'}   = $code;
    $ENV{'ERROR_TEXT'}   = $msg;
    $ENV{'ERROR_URI'}    = $r->{URI};
    $ENV{'ERROR_METHOD'} = $r->{METHOD};
  }

  if (exists $conf->{'ERROR_PAGES'}) {
    if ((exists $conf->{'ERROR_PAGES'}{$code}) && 
        ((-e $conf->{'DOCUMENT_ROOT'}.$conf->{'ERROR_PAGES'}{$code}) ||
         (exists $conf->{'DOCUMENTS'}{$conf->{'ERROR_PAGES'}{$code}})
        )
       ) {
      $r->{METHOD} = 'GET';
      $r->{URI} = $conf->{'ERROR_PAGES'}{$code};
      my $page = $self->__get_page($id, $rhost, $rport, $r, 0);
      if (defined $page) {
        $page =~ s/^(.+)\s+\d+\s+\(.*\)(\s*$CRLF)/$1 $code ($msg)$2/;
      }
      return $page;

    } elsif ((exists $conf->{'ERROR_PAGES'}{'ALL'}) &&
             ((-e $conf->{'DOCUMENT_ROOT'}.$conf->{'ERROR_PAGES'}{'ALL'}) ||
              (exists $conf->{'DOCUMENTS'}{$conf->{'ERROR_PAGES'}{'ALL'}})
             )
            ) {
      $r->{METHOD} = 'GET';
      $r->{URI} = $conf->{'ERROR_PAGES'}{'ALL'};
      my $page = $self->__get_page($id, $rhost, $rport, $r, 0);
      if (defined $page) {
        $page =~ s/^(.+)\s+\d+\s+\(.*\)(\s*$CRLF)/$1 $code ($msg)$2/;
      }
      return $page;

    } 
  } 

  
  my $pmeth = sprintf("%-4s", $r->{METHOD});
  &$logging("[$id] $pmeth [ERROR] from $rhost:$rport got ($code " . $msg. ")");

  my $cont = "<html><head><title>$code $msg</title></head><body><h1>$code $msg</h1></body></html>";

  my %headers = ();
  $headers{'Content-type'} = 'text/html';

  return $self->__make_response($code, \%headers, $cont, $auth);
}

# --------------------------------------------------------------------------------------
# Perform fork start initialization
#

sub __pre_fork {
  my ($self, $id) = @_;
  my $rconf = $self->{CONF};

  # Pre fork is only for workers
  # if ($id =~ /^S\d+$/) { return; }

  if (defined $rconf->{"STARTUP"}) {
    $0 = $rconf->{"PROC_PREFIX"} . " loading startup ";
    if (!$self->__load_startup()) {
      return;
    }
  }

  my $f = $rconf->{"CHILD_START"};
  if (defined $f) {

    $0 = $rconf->{"PROC_PREFIX"} . " running pre-fork ";

    my $logging = $rconf->{"DEBLOG_METHOD"};
    my $logging2 = $rconf->{"LOG_METHOD"};
    my $errs = '';
    my $res = '';

    # save all STD files
    open OLDERR, ">&STDERR";
    open OLDOUT, ">&STDOUT";

    # reopen STDERR to $errs string
    close STDERR;
    open STDERR, ">", \$errs;

    # reopen STDOUT to $res string
    close STDOUT;
    open STDOUT, ">", \$res;
    binmode STDOUT;

    my $evalerr;
    eval {
      $data = &$f;
      $evalerr = $@;
    };

    close STDOUT;
    open STDOUT, ">&OLDOUT";
    close OLDOUT;
    close STDERR;
    open STDERR, ">&OLDERR";
    close OLDERR;

    $errs .= $evalerr;

    if (length($errs) > 0) {
      &$logging("[$id] (Child start) \n$errs");
    }

    &$logging2("[$id] Child ready\n");
  }

  return;
}

# --------------------------------------------------------------------------------------
# Perform fork stop de-initialization
#

sub __post_fork {
  my ($self, $id) = @_;
  my $rconf = $self->{CONF};

  # Post fork is only for workers
  # if ($id =~ /^S\d+$/) { return; }

  my $f = $rconf->{"CHILD_END"};
  if (defined $f) {

    my $logging = $rconf->{"DEBLOG_METHOD"};
    my $logging2 = $rconf->{"LOG_METHOD"};
    my $errs = '';
    my $res = '';
 
    # save all STD files
    open OLDERR, ">&STDERR";
    open OLDOUT, ">&STDOUT";

    # reopen STDERR to $errs string
    close STDERR;
    open STDERR, ">", \$errs;

    # reopen STDOUT to $res string
    close STDOUT;
    open STDOUT, ">", \$res;
    binmode STDOUT;

    my $evalerr;
    eval {
      &$f($data);
      $evalerr = $@;
    };

    close STDOUT;
    open STDOUT, ">&OLDOUT";
    close OLDOUT;
    close STDERR;
    open STDERR, ">&OLDERR";
    close OLDERR;

    $errs .= $evalerr;

    if (length($errs) > 0) {
      &$logging("[$id] (Child end) \n$errs");
    }

    &$logging2("[$id] Child finished\n");
  } 

  return;
}

# --------------------------------------------------------------------------------------
# Patch configuration for our needs
#

sub __fix_conf {
  my ($rconf) = @_;

  if (not defined $rconf->{"SERVER_NAME"}) {
    $rconf->{"SERVER_NAME"} = "localhost"
  }
  if (not defined $rconf->{"SERVER_IP"}) {
    $rconf->{"SERVER_IP"} = "127.0.0.1";
  }
  if (not defined $rconf->{"SERVER_PORT"}) {
    $rconf->{"SERVER_PORT"} = 80;
  }
  if (not defined $rconf->{"WAIT_RESPONSE"}) {
    $rconf->{"WAIT_RESPONSE"} = 1;
  }
  if (not defined $rconf->{"NO_WAIT_REPLY"}) {
    $rconf->{"NO_WAIT_REPLY"} = 204;
  }
  if (not defined $rconf->{"IMMED_CLOSE"}) {
    $rconf->{"IMMED_CLOSE"} = 0;
  }
  if (not defined $rconf->{"SOFTWARE"}) {
    $rconf->{"SOFTWARE"} = "WebIT/$VERSION";
  }
  if (not defined $rconf->{"SIGNATURE"}) {
    $rconf->{"SIGNATURE"} = "<br/>WebIT/$VERSION for Perl<br/>";
  }
  if (not defined $rconf->{"PROC_PREFIX"}) {
    $rconf->{"PROC_PREFIX"} = 'WebIT';
  }
  $rconf->{"PROC_PREFIX"} =~ s/\s\s/\s/go;
  if (not defined $rconf->{"EMBED_PERL"}) {
    $rconf->{"EMBED_PERL"} = 1;
  }
  if (not defined $rconf->{"QUEUE_SIZE"}) {
    $rconf->{"QUEUE_SIZE"} = 5;
  }
  if (defined $rconf->{"DOCUMENT_ROOT"}) {
    if ($rconf->{"DOCUMENT_ROOT"} !~ /\/$/) {
      $rconf->{"DOCUMENT_ROOT"} .= "/";
    }
  } else {
    $rconf->{"DOCUMENT_ROOT"} = undef;
  }

  if (not defined $rconf->{"SETUP_ENV"}) {
    $rconf->{"SETUP_ENV"} = 1;
  }

  if (length($rconf->{"STARTUP"}) > 0) {
    $rconf->{"STARTUP"} =~ s/\/\//\//gco;
  }

  if (not defined $rconf->{"ENV_KEEP"}) {
    push(@{$rconf->{"ENV_KEEP"}}, 'PATH');
  }

  if (not defined $rconf->{"ENV_ADD"}) {
    $rconf->{"ENV_ADD"} = ();
  }

  if (not defined $rconf->{"MIME_TYPES"}) {
    $rconf->{"MIME_TYPES"} = '/etc/mime.types';
  }

  if (not defined $rconf->{"SERVERS"}) {
    $rconf->{"SERVERS"} = 0;
  }

  if (not defined $rconf->{"WORKERS"}) {
    $rconf->{"WORKERS"} = 0;
  }

  if (not defined $rconf->{"FORK_CONN"}) {
    $rconf->{"FORK_CONN"} = 0;
  }

  if ($rconf->{"FORK_CONN"}) {
    $rconf->{"WORKERS"} = 0;
  }

  if (not defined $rconf->{"USE_SSL"}) {
    $rconf->{"USE_SSL"} = 0;
    $rconf->{"SSL_CERTIFICATE"} = undef;
    $rconf->{"SSL_KEY"} = undef;
  }

  if (not defined $rconf->{"LOG_METHOD"}) {
    if ($rconf->{"NO_LOGGING"}) {
      $rconf->{"LOG_METHOD"} = 'EmbedIT::WebIT::__no_logging';
    } else {
      $rconf->{"LOG_METHOD"} = 'EmbedIT::WebIT::__logging';
    }
  }
  if (not defined $rconf->{"DEBLOG_METHOD"}) {
    $rconf->{"DEBLOG_METHOD"} = $rconf->{"LOG_METHOD"};
  }

  if (not defined $rconf->{"LOG_HEADERS"}) {
    $rconf->{"LOG_HEADERS"} = 0;
  }

  if (not defined $rconf->{"LOG_PACKETS"}) {
    $rconf->{"LOG_PACKETS"} = 0;
  }

  if ($rconf->{'LOG_PACKETS'}) {
    $rconf->{"LOG_HEADERS"} = 1;
  }

  if (defined $rconf->{"CGI_PATH"}) {
    $rconf->{"CGI_PATH_PRINT"} = $rconf->{"CGI_PATH"};
    # transform CGI_PATH to a regular expression for single step matching
    $rconf->{"CGI_PATH"} =~ s/\s(:|;)\s/$1/g;
    $rconf->{"CGI_PATH"} =~ s/(:|;)/\/$1/g;
    $rconf->{"CGI_PATH"} =~ s/$/\//g;
    $rconf->{"CGI_PATH"} =~ s/\/\//\//g;
    $rconf->{"CGI_PATH"} =~ s/\//\\\//g;
    $rconf->{"CGI_PATH"} =~ s/^(.)/($1/g;
    $rconf->{"CGI_PATH"} =~ s/(.)$/$1)/g;
    $rconf->{"CGI_PATH"} =~ s/(:|;)/)|(/g;
    $rconf->{"CGI_PATH"} =~ s/\)/.*?\\\..*)/g;
  }
  if (defined $rconf->{"AUTH_PATH"}) {
    $rconf->{"AUTH_PATH_PRINT"} = $rconf->{"AUTH_PATH"};
    # transform AUTH_PATH to a regular expression for single step matching
    $rconf->{"AUTH_PATH"} =~ s/\s(:|;)\s/$1/g;
    $rconf->{"AUTH_PATH"} =~ s/(:|;)/\/$1/g;
    $rconf->{"AUTH_PATH"} =~ s/$/\//g;
    $rconf->{"AUTH_PATH"} =~ s/\/\//\//g;
    $rconf->{"AUTH_PATH"} =~ s/\//\\\//g;
    $rconf->{"AUTH_PATH"} =~ s/^(.)/($1/g;
    $rconf->{"AUTH_PATH"} =~ s/(.)$/$1)/g;
    $rconf->{"AUTH_PATH"} =~ s/(:|;)/)|(/g;
  }

  if (not exists $rconf->{"HTML_CODES"}) {
    $rconf->{"HTML_CODES"} = {
      100 => "Continue",
      101 => "Switching Protocols",
      200 => "OK",
      201 => "Created",
      202 => "Accepted",
      203 => "Non-Authoritative Information",
      204 => "No Content",
      205 => "Reset Content",
      206 => "Partial Content",
      300 => "Multiple Choices",
      301 => "Moved Permanently",
      302 => "Found",
      303 => "See Other",
      304 => "Not Modified",
      305 => "Use Proxy",
      306 => "No Longer Used",
      307 => "Temporary Redirect",
      400 => "Bad Request",
      401 => "Not Authorised",
      402 => "Payment Required",
      403 => "Forbidden",
      404 => "Not Found",
      405 => "Method Not Allowed",
      406 => "Not Acceptable",
      407 => "Proxy Authentication Required",
      408 => "Request Timeout",
      409 => "Conflict",
      410 => "Gone",
      411 => "Length Required",
      412 => "Precondition Failed",
      413 => "Request Entity Too Large",
      414 => "Request URI Too Long",
      415 => "Unsupported Media Type",
      416 => "Requested Range Not Satisfiable",
      417 => "Expectation Failed",
      500 => "Internal Server Error",
      501 => "Not Implemented",
      502 => "Bad Gateway",
      503 => "Service Unavailable",
      504 => "Gateway Timeout",
      505 => "HTTP Version Not Supported",
    };
  }
}

# --------------------------------------------------------------------------------------
# Clean up the process environment variables
#

sub __clean_env {
  my ($conf) = @_;

  foreach my $k (keys %ENV) {
    my $found = 0;
    foreach my $w (@{$conf->{"ENV_KEEP"}}) {
      if ($k eq $w) { $found = 1; }
    }
    if (!$found) { delete $ENV{$k} };
  }

  if ($conf->{"SETUP_ENV"}) {
    $ENV{"SERVER_NAME"} = $conf->{"SERVER_NAME"};
    $ENV{"SERVER_PORT"} = $conf->{"SERVER_PORT"};
    $ENV{"SERVER_ADMIN"} = $conf->{"SERVER_ADMIN"};
    $ENV{"DOCUMENT_ROOT"} = $conf->{"DOCUMENT_ROOT"};
    $ENV{"SERVER_PROTOCOL"} = "HTTP/1.1";
    $ENV{"SERVER_SOFTWARE"} = $conf->{"SOFTWARE"};
    $ENV{"SERVER_SIGNATURE"} = $conf->{"SIGNATURE"};
    $ENV{"GATEWAY_INTERFACE"} = "CGI/1.1 WebIT for Perl";
    if ($conf->{"EMBED_PERL"}) {
      $ENV{"WEBIT_DATA"} = "INTERNAL";
    }
  }
  foreach my $k (keys %{$conf->{"ENV_ADD"}}) {
    $ENV{$k} = $conf->{"ENV_ADD"}->{$k};
  }
}

# --------------------------------------------------------------------------------------
# Fix environment variables for current request
#

sub __fix_env {
  my ($self, $r) = @_;

  for my $k (keys %{ $r->{HEADERS} }) {
    if ($k !~ /CONTENT-LENGTH|COOKIE/) {
      my $l = $k;
      $l =~ s/[^A-Za-z0-9_]/_/gco;
      $l = 'HTTP_' . $l;
      $ENV{$l} = $r->{HEADERS}{$k};
    }
  }
  if (exists $r->{HEADERS}{'COOKIE'}) { 
    $ENV{'COOKIE'} = $r->{HEADERS}{'COOKIE'}; 
  } else {
    delete $ENV{'COOKIE'};
  }
}

# --------------------------------------------------------------------------------------
# Load a file a return its contents or undef on error
#

sub __load_file {
  my ($self, $f) = @_;

  open FILE, $f || return undef;
  binmode FILE;
  my @l = <FILE>;
  close FILE;

  return join('',@l);
}

# --------------------------------------------------------------------------------------
# Load startup file to fix server environment
#

sub __load_startup {
  my ($self) = @_;
  my $conf = $self->{CONF};

  my $logging = $conf->{"DEBLOG_METHOD"};

  my $scr = $self->__load_file($conf->{"STARTUP"});
  if (not defined $scr) { 
    &$logging("Startup file cannot be loaded"); 
    return 0; 
  }

  my $errs = '';
  my $res = '';
 
  # save all STD files
  open OLDERR, ">&STDERR";
  open OLDOUT, ">&STDOUT";

  # reopen STDERR to $errs string
  close STDERR;
  open STDERR, ">", \$errs;

  # reopen STDOUT to $res string
  close STDOUT;
  open STDOUT, ">", \$res;
  binmode STDOUT;

  my $evalerr;
  eval {
    eval($scr);
    $evalerr = $@;
  };

  close STDOUT;
  open STDOUT, ">&OLDOUT";
  close OLDOUT;
  close STDERR;
  open STDERR, ">&OLDERR";
  close OLDERR;

  $errs .= $evalerr;

  if (length($errs) > 0) {
    &$logging("(" . $conf->{"STARTUP"} . ") \n$errs");
  }

  if ($evalerr ne '') { return 0; }

  return 1;
}

# --------------------------------------------------------------------------------------
# get user id from given id or name
#

sub __get_uid {
  my ($i_id) = @_;

  my ($n, $p, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwnam($i_id);
  if (not defined $uid) {
    ($n, $p, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwuid($i_id);
    if (not defined $uid) {
      return 0;
    }
  }

  return $uid;
}

# --------------------------------------------------------------------------------------
# get group id from given id or name
#

sub __get_gid {
  my ($i_id) = @_;

  my ($n, $p, $gid, $members) = getgrnam($i_id);
  if (not defined $gid) {
    ($n, $p, $gid, $members) = getgrgid($i_id);
    if (not defined $gid) {
      return 0;
    }
  }
  return $gid;
}

# --------------------------------------------------------------------------------------
# Empty logger
#

sub __no_logging {
}

# --------------------------------------------------------------------------------------
# Elementary log
#

sub __logging {
  my ($self, $str) = @_;
  if (ref($self) eq '') {
    print STDERR time2iso(time) . " - $self\n";
  } else {
    print STDERR time2iso(time) . " - $str\n";
  }
}

# --------------------------------------------------------------------------------------

1;

=head1 NAME

EmbedIT::WebIT - A small yet very effective embeded web server for any perl application

=head1 Synopsis

  use EmbedIT::WebIT;

  $server = new EmbedIT::WebIT( SERVER_NAME   => 'www.my.org',
                                SERVER_IP     => '127.0.0.1',
                                SERVER_PORT   => 8080,
                                SOFTWARE      => 'MyApp web server',
                                QUEUE_SIZE    => 100,
                                RUN_AS_USER   => nobody,
                                RUN_AS_GROUP  => nogroup,
                                WAIT_RESPONSE => 1,
                                IMMED_CLOSE   => 1,
                                EMBED_PERL    => 1,
                                FORK_CONN     => 0,
                                SETUP_ENV     => 1,
                                SERVER_ADMIN  => 'info@my.org',
                                SERVERS       => 3,
                                WORKERS       => 1,
                                DOCUMENT_ROOT => '/opt/my/web',
                                DOCUMENTS     => {
                                                   '/index.html'    => 'WPages::index',
                                                   '/error.html'    => 'WPages::error',
                                                   '/style.css'     => 'WPages::style',
                                                   '/print.css'     => 'WPages::print',
                                                   '/404.html'      => 'WPages::error404',
                                                   '*'              => 'WPages::pageHandle',
                                                 },
                                ERROR_PAGES   => { 
                                                   '404' => '/404.html',    # embeded subroutine error
                                                   'ALL' => '/error.html',  # simple html file error
                                                 },
                                EXPIRATIONS   => { 
                                                   'image/jpg' => 86400,
                                                   'ALL' => 3600, 
                                                 },
                                PROC_PREFIX   => 'my:',
                                CHILD_START   => 'WControl::start_db',
                                CHILD_END     => 'WControl::stop_db',
                                LOG_METHOD    => 'WControl::logInfo',
                                DEBLOG_METHOD => 'WControl::logDebug',
                                LOG_HEADERS   => 0,
                                LOG_PACKETS   => 0,
                                CGI_PATH      => '/cgi',
                                ENV_KEEP      => [ 'PERL5LIB', 'LD_LIBRARY_PATH' ],
                                NO_LOGGING    => 0,
                              );

  $server->execute();

=head1 Description

The WebIT embeded web server was created a long time ago to make a pure perl application that will interact 
directly with I<Kannel>. The need was to relieve I<Kannel> from the need to wait for the web server to run 
its scripts before going back to serve another SMS message. In this respect WebIT is a hack and can be 
configured to behave in a manner which is not according to the RFC's for HTTP. Yet, creating Perl applications 
with WebIT using embeded html pages as perl functions outperforms Apache with mod_perl installations. 

For this reason I was asked by a few to release this code so that they can use it for their applications. 

So even though WebIT is not complete (Workers and SSL not implemented yet) WebIT is already used by 
14 perl applications that I know of excluding my personal work.

To work with WebIT all you need to do is to create a new server object by giving to it the parameters
that you want, and then at any point in time call the execute method to run the server. The execute method 
returns only when the server has finished execution, and that can only be done by sending a TERM signal to 
the process. 

Once the server has started it will fork the predefined number of servers and workers. Since workers are not 
implemented yet you are advised to ask for 0 workers on startup. From then on, WebIT will serve HTTP requests 
by using external files in a configured directory and/or internal pages served by perl subroutines. The code
of the cgi pages and subroutines is as you already know by Apache and mod_perl. You can use the CGI module to 
get the request parameters, print on the standard output to form the response to the caller, and print to 
standard error to log text to the logger of the server.

=head1 Things to avoid

=over

=item * 

Dont use perl threads ! Perl does not really have threads anyway, so dont use them. Threads that do not by 
default share their data are not threads, they are forks, and in perl threads are isolated. If you are really 
inclined to use threads move to another language like Java.

=item * 

Dont use IPC. The server already uses IPC, and some things you can do might break the server. 

=back

Just use the server for what it is, and that is an embeded web server for applications, not for hacks, thus you 
should not need any of the above to create you application. Now if for any reason you really have to use some of 
the above, then WebIT is not for you. 

=head1 Configuration

Now lets take a look at the configuration hash of the server.

=over 4

=item SERVER_NAME

The DNS name of the server (default is localhost)

=item SERVER_IP

The IP address to bind to (default is 127.0.0.1)

=item SERVER_PORT

The TCP port to use (default is 80)

=item QUEUE_SIZE

The number of connections to queue per child (default is 5)

=item USE_SSL

The server will work in SSL mode accepting https connections only. (default is undef) 
B<This feature is not implemented yet>

=item SSL_CERTIFICATE

The servers SSL certificate path and file. If not defined no certificate file will be 
used for the connection. You can pass the actual certificate here as is. The value is 
first tested to see if it matches an existing file, and if not it will be used as an 
actual certificate. (default is undef)
B<This feature is not implemented yet>

=item SSL_KEY

The servers SSL key path and file. If not defined no key will be used for the
connection. You can pass the actual key here as is. The value is first tested 
to see if it matches an existing file, and if not it will be used as an
actual key. (default is undef).
B<This feature is not implemented yet>

=item WAIT_RESPONSE

Directs the server to wait until a response is generated. If 0 server will 
close connection before running scripts or getting pages and returns 204  
(No Content) to client (default is 1 and the server will wait for responses)

=item NO_WAIT_REPLY

The code to send when WAIT_RESPONCE is 0. (default is undef and 204 is returned)

=item IMMED_CLOSE

Close connection immediately after serving request. Ignored if WAIT_RESPONSE is 0. (default is 0)
If it is set to 0 the server will respect the client's request about the handling of the connection (might be
immediate close or keep open) 

=item RUN_AS_USER

The user under which the server should run as

=item RUN_AS_GROUP

The group under which the server should run as

=item SETUP_ENV

Allow the server to setup the children environment. This requires some milliseconds for each request
served since the server will have to contruct the environment for each call. If you are not using the CGI 
module and you know what you are doing you can set this to 0-false and save some time for running requests
(default is 1) 

=item ENV_KEEP

List of environment variables to keep for scripts. For normal execution all environment variables are cleared 
and CGI and embeded pages run in a clean environment. If however you need to preserve some, like database variables
you can specify their names here in an array, and they will be preserved for your scripts.

=item ENV_ADD

Hash with environment variables and values to set for scripts. These environment variables and their values will be 
added to the environment of your CGI and embeded pages.

=item MIME_TYPES

Path and file where the server can find valid mimetypes. (default is /etc/mime.types)

=item EMBED_PERL

Run perl CGI scripts inside the server, not in a separate process. Faster than Apache and mod_perl. (default is 0)

=item SERVER_ADMIN

The email of the server administrator. This text will appear in the environment variables of the CGI / embeded pages (default is empty)

=item DOCUMENT_ROOT

The path where the site documents and scripts are stored. (default is undef)

=item DOCUMENTS

A hash of documents and their subroutines to execute within the server. This is 
used to create fully embeded web servers that respond to specific URL's using 
specific subroutines. A special page name '*' can be used to direct all unknown 
page requests to be directed to the subroutine of this special page.
Can be used in conjunction with and has precedence over DOCUMENT_ROOT (default is undef)

=item ERROR_PAGES

A hash with the site supplied error pages. It contains the error code as a key and
the page path within DOCUMENT_ROOT or DOCUMENTS of the page for the error. Alternatevly there can
be an entry with keyword ALL where all errors without a specific entry in the hash
will find their error pages. Error pages can be cgi's or plain html. (default is undef) 
For all error pages the server sets 4 extra environment variables. These are:

=over 4

=item ERROR_CODE

This contains the numeric value of the error, eg 404.

=item ERROR_TEXT

This contains the text value of the error, eg Page not found.

=item ERROR_URI

This contains the URI that generated the error.

=item ERROR_METHOD

This contains the method used to access the URI, eg POST

=back

Along with all other environment variables used you can track all errors to their fullest detail, and handle 
them not just for display but for administrator notifications as well.

=item EXPIRATIONS

A hash with expiration times. It contains the content type as a key and the expiration
time in seconds. A special entry called ALL specifies the expiration time of any type NOT 
already defined in the hash.

=item SERVERS

Number of servers to prefork. Default is 0 where only the master instance exists

=item WORKERS

Number of page workers to prefork. Default is 0 where only the master instance exists
B<Wrokers are not implemented yet>

=item FORK_CONN

Create a child everytime a new connection arrives. (default is 0) Usefull for hard headed 
perl modules like SOAP::WSDL that retain information between calls and confuse the server. Not to be
used with time sensitive HTTP applications like SMS applications with I<Kannel> because with perl, forking 
requires quite some time to be performed.

=item STARTUP

Run this script at startup to load the environment for the pages. Can only be an external perl script.
Embeded pages startup code can be done in many ways without the need of external scripts.

=item CHILD_START

Subroutine to call on every fork for initialization. Returned values of this 
subroutine are passed to internally called functions (default is undef) Persistant database connections 
and other paraphenalia that are required for your application should be initialized in the method 
defined here. All values that are needed by your application should be returned in a hash or an array 
by your method, so that they can be retrieved later on by your CGI's and embeded pages.

=item CHILD_END

Subrouting to call on termination of a forked child. It is passed the return values of the start subroutine 
(default is undef) All values initialized by the method defined in CHILD_START that require some form 
of proper termination should be treated by the method defined here. The parameter passed to that method 
is the pointer returned by the CHILD_START, so you should know how to deal with it.

=item PROC_PREFIX

Text line to be used as prefix for the process name of the childs. (default is WebIT) This is 
just for decorating the ps listing of those OS's that give us the ability to change the name of the process.

=item LOG_METHOD

Subroutine to call for logging. It is passed a single string to log. 
(default is internal logging to stderr)

=item DEBLOG_METHOD

Subroutine to call for debug logging. It is passed a single string to log. 
(default is the same with LOG_METHOD)

=item LOG_HEADERS

Log input and output packet headers as those come and go to and from the server (default is 0)

=item LOG_PACKETS

Log input and output packets as those come and go to anf from the server. By turning on packet logging you will
implicity get header logging. (default is 0)

=item NO_LOGGING

When set to 1-true the server will avoid all possible logging speeding up processing to the max. (default is 0)

=item CGI_PATH

A colon or semicolon separated list of paths under the DOCUMENT_ROOT where
CGI scripts exist. (default is undef)

=item AUTH_PATH

A colon or semicolon separated list of paths under the DOCUMENT_ROOT where 
authentication is needed. Works with embeded pages as well. (default is undef)

=item AUTH_REALM

A string specifying the realm of the authentication for the AUTH_PATH's. There is only one
realm (default is undef)

=item AUTH_METHOD

Subroutine to call for authenticating remote users. Parameters are the returned values of 
the child start subroutine preceeded by a username and a password. (default is undef)

=item SOFTWARE

Text with software name and version. This text will appear in the environment variables of the CGI / embeded pages
(default is WebIT/$VESRION)

=item SIGNATURE

Text with web server signature. This text will appear in the environment variables of the CGI / embeded pages. (default is <br\>WebIT/$VERSION for Perl<br\>)`

=back

=head1 Methods

The methods that are available to use are the following:

=over

=item new()

This is the constructor of the object. It takes as a parameter a hash with keys and values as described above.

=item execute()

This is the routing to enter the execution loop of the server. This method will never return, so if you need to do 
anyting more with your application you might want to call this method from a forked process.

=item data()

This method returns the server child data as those were returned by the CHILD_START method.

Lets assume that you have a CHILD_START method as follows:

  sub start_up {
    %res = ();
    $db = DBI->connect("DBI:Oracle:sid=pits;host=127.0.0.2;port=3127", "user", "pass");

    $res{DATABASE} = $db;

    return \%res;
  }

If you want to retrieve that connection from inside a CGI script or an embeded page what you need to do is the 
following:

  $res = EmbedIT::WebIT::data();
  $db = $res->{DATABASE};

or if you have access to you server object you can do the following:

  $res = $server->data();
  $db = $res->{DATABASE};

=item start_time()

This method returns the timestamp of the server startup time. Usefull for applications that need to know when 
the server started in order to perform some functions. 

=back

=head1 WebIT and SOAP::WSDL

One of the main reasons why I use now days WebIT, is to expose soap methods. SOAP::WSDL (and not SOAP::Lite) is the 
best possible soap package available for perl. If you want to use WebIT as a server for SOAP::WSDL this is what you
have to do:

First of all you need to specify FORK_CONN as true (1 for perl) to force the server to fork a new child for each 
new connection. Then you need to specify the embeded pages that will serve the methods exposed by the WSDL. For
example, assume you need to expose a method test that takes a string as input and returns another string as output.

Create you WSDL 

  <?xml version="1.0" encoding="utf-8"?>
  <wsdl:definitions xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
                    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
                    xmlns:tns="http://tempuri.org/"
                    xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/"
                    xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
                    targetNamespace="http://tempuri.org/"
                    xmlns:wc="http://tempuri.org/"
                    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
    <wsdl:types>
      <xs:schema elementFormDefault="unqualified" targetNamespace="http://tempuri.org/">
        <xs:element name="InputFlag">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="Flag" type="xs:string" minOccurs="1"  maxOccurs="1"/>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
  
        <xs:element name="OutputFlag">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="Flag" type="xs:string" minOccurs="1" maxOccures="1"/>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:schema>
    </wsdl:types>
  
    <wsdl:message name="MsgIn"> <wsdl:part element="tns:InputFlag" name="MessageIn"/> </wsdl:message>
    <wsdl:message name="MsgOut"> <wsdl:part element="tns:OutputFlag" name="MessageOut"/> </wsdl:message>
  
    <wsdl:portType name="TestPort">
      <wsdl:operation name="Test">
        <wsdl:input  message="tns:MsgIn" />
        <wsdl:output message="tns:MsgOut" />
      </wsdl:operation>
    </wsdl:portType>
  
    <wsdl:binding name="TestBind" type="tns:TestPort">
      <soap:binding transport="http://schemas.xmlsoap.org/soap/http" style="document" />
  
      <wsdl:operation name="Test">
        <soap:operation soapAction="urn:Test#Test" style="document" />
  
        <wsdl:input>  <soap:body use="literal"/> </wsdl:input>
        <wsdl:output> <soap:body use="literal"/> </wsdl:output>
      </wsdl:operation>
  
    </wsdl:binding>

    <wsdl:service name="Test">
      <wsdl:port name="Test" binding="tns:TestBind">
        <soap:address location="http://127.0.0.1:8089/WS/Test" />
      </wsdl:port>

    </wsdl:service>
  </wsdl:definitions>

and compile it with wsdl2perl

Then create your handling object (use SOAP::WSDL documentation to see what you need to do) as follows:

  package WebService

  our $VERSION = "1.0";

  sub new {
    my $self = {};
    bless $self;
    return $self;
  }

  sub Test {
    my ($self,$body,$header) = @_;
    my %idata = ();
  
    $idata{Flag} = $body->get_Flag() . "";
  
    return MyElements::OutputFlag->new(\%idata);
  }

and finally create your embeded page that will handle the HTTP request.

  sub WebService {
      eval {
        unshift @INC, $lib_path;      # add at run time the library path of the generated classes from wsdl2perl
        require MyServer::Test::Test; # use the server class generated by wsdl2perl
  
        my $t = WebService->new();    # create a WebService handling object
        my $server = MyServer::Test::Test->new({ dispatch_to     => 'WebService',
                                                 transport_class => 'SOAP::WSDL::Server::CGI' });
        $server->handle();
     };
     if ($@) { print "just do something ...the call has failed\n"; }
  }

On your WebIT configuration hash you need to remember to add the above subroutine as the handler 
for a page like so:

  $server = new EmbedIT::WebIT( SERVER_NAME => 'name.org',
                                ...
                                FORK_CONN   => 1,
                                ...
                                DOCUMENTS   => {
                                                 'WS/Test' => 'main::WebService',
                                               },
                                ...
                              );

and thats it. You have exposed web services working with WebIT as an embeded web server.

=head1 Requirements

You need to have installed the following packages for WebIT to work.

=over 4

=item HTTP::Date

=item IO::Socket

=item IO::Select

=item LWP::MediaTypes

=item IPC::Open3

=item Taint::Runtime

=item MIME::Base64

=back

=head1 Copyright

Copyright 2008 D. Evmorfopoulos <devmorfo@gmail.com>

Permission is granted to copy, distribute and/or modify this 
document under the terms of the GNU Free Documentation 
License, Version 1.2 or any later version published by the 
Free Software Foundation; with no Invariant Sections, with 
no Front-Cover Texts, and with no Back-Cover Texts.

=cut
