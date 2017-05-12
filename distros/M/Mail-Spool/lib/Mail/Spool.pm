# -*- perl -*-
#
#  Mail::Spool - adpO - Extensible Perl Mail Spooler
#
#  $Id: Spool.pm,v 1.7 2001/12/07 23:55:26 rhandom Exp $
#
#  Copyright (C) 2001, Paul T Seamons
#                      paul@seamons.com
#                      http://seamons.com/
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
#  All rights reserved.
#
#  Please read the perldoc Mail::Spool
#
################################################################

package Mail::Spool;

use strict;
use vars qw(@EXPORT_OK
            @ISA
            $AUTOLOAD
            $REV
            $VERSION
            $DEQUEUE_DIR
            $DEQUEUE_PERIODS
            $DEQUEUE_PRIORITY
            $DEQUEUE_TIMEOUT
            $MAX_DEQUEUE_PROCESSES
            $MAX_CONNECTION_TIME
            $USAGE_LOG);
use Exporter ();
use File::NFSLock 1.10 ();
use Net::DNS ();
use Net::SMTP ();
use IO::File ();
use Mail::Internet ();
use Mail::Address ();
use Digest::MD5 qw(md5_hex);

use Mail::Spool::Handle ();
use Mail::Spool::Node ();

@ISA = qw(Exporter);
@EXPORT_OK = qw(dequeue send_mail daemon);

$REV  = (q$Revision: 1.7 $ =~ /([\d\.]+)/) ? $1 : ""; # what revision is this
$VERSION = '0.50';

###----------------------------------------------------------------###

### directory that will hold mail spool (hate to hard code)
$DEQUEUE_DIR = "/var/spool/mail";

### seconds to be in a queue before trying
### see the list_spool_handles sub for further discussion
$DEQUEUE_PERIODS  = [0, .5*3600, 4*3600, 8*3600, 16*3600, 24*3600, 48*3600];

### directory priority (lower is higher priority)
### see the list_spool_handles sub for further discussion
$DEQUEUE_PRIORITY = [1, 3,       9,      25,     50,      100,     200];

### seconds to wait before checking the queues
### see the list_spool_handles sub for further discussion
$DEQUEUE_TIMEOUT = 20;

### max number of processes to start at one time
$MAX_DEQUEUE_PROCESSES = 20;

###----------------------------------------------------------------###

### directory to store usage information
$USAGE_LOG = "$DEQUEUE_DIR/usage";

### maximum amount of time to try and send a message
$MAX_CONNECTION_TIME = 6 * 60 * 60;

### RFC line ending
my $crlf = "\015\012";

###----------------------------------------------------------------###

sub new {
  my $type  = shift;
  my $class = ref($type) || $type || __PACKAGE__;
  my $self  = @_ && ref($_[0]) ? shift() : {@_};
  return bless $self, $class;
}

###----------------------------------------------------------------###
### daemon which can act as the mail dequeuer
### invoke via "perl -e 'use Mail::Spool; Mail::Spool->new->daemon;'"
sub daemon {
  my $self = shift;

  $self->create_dequeue_dirs();
  
  my $package = "Net::Server::Fork";
  require $package;
  unshift @ISA, $package;

  $self->run(
             log_file        => 'Sys::Syslog', # send any debugging to the syslog
             setsid          => 1,             # make sure this truly daemonizes
             
             max_servers     => 1,             # don't fire up any servers
             
             check_for_dequeue => $self->dequeue_timeout, # wait before looking at the queue
             max_dequeue       => $self->max_dequeue_processes, # max number to start
             
             @_, # any other arguments
             );
  exit;
}
sub pre_bind {}
sub bind {}

###----------------------------------------------------------------###
sub create_dequeue_dirs {
  my $self = shift || Mail::Spool->new();
  
  ### make sure the dequeue dir is there
  if( ! -d $self->dequeue_dir ){
    mkdir $self->dequeue_dir, 0755;
    die "Couldn't create dequeue_dir ($!)" if ! -d $self->dequeue_dir;
  }
  
  ### create the queue directories
  my $periods = $self->dequeue_periods;
  for ( 0 .. $#$periods ){
    my $dir = $self->dequeue_dir . "/$_";
    if( ! -d $dir ){
      mkdir $dir, 0755;
      die "Couldn't create dequeue_dir ($dir) ($!)" if ! -d $dir;
    }
  }

  return 1;
}

### list all of the spools that we may look in
sub list_spool_handles {
  my $self = shift;

  # RFC notes
  # failed delivery should wait 30 minutes (done)
  # give up time should be 4-5 days (done)
  # two attempts during first hour of queue (done)

  ### This system will work on a network with several mail spool dequeuers running on
  ### multiple boxes.  The system uses probability to make reading of the directory happen
  ### rather than file locking (individual files are still locked).
  ###
  ### A dequeue_priority of 1   will happen 100%  of the time (1/x).
  ### A dequeue_priority of 3   will happen 33.3% of the time.
  ### A dequeue_priority of 9   will happen 11.1% of the time.
  ### A dequeue_priority of 25  will happen 4%    of the time.
  ### A dequeue_priority of 50  will happen 2%    of the time.
  ### A dequeue_priority of 100 will happen 1%    of the time.
  ### A dequeue_priority of 200 will happen .5%   of the time.
  ###
  ### With a dequeue_timeout of 20 and one server, the following will happen on average:
  ### A dequeue_priority of 1   will check every 20   seconds.
  ### A dequeue_priority of 3   will check every 60   seconds.
  ### A dequeue_priority of 9   will check every 3    minutes.
  ### A dequeue_priority of 25  will check every 8.3  minutes.
  ### A dequeue_priority of 50  will check every 16.6 minutes.
  ### A dequeue_priority of 100 will check every 33.3 minutes.
  ### A dequeue_priority of 200 will check every 66.6 minutes.
  ### (if the timeout is decreased to 10, priority 1 would check every 10 seconds)
  ### (if the number of servers doubles, priority 1 would check every 10 seconds)
  ### (if servers double and timeout is 10, priority 1 would check every 5 seconds)
  ###
  ### Following the default dequeue_periods and dequeue_priorities, 
  ### Spool 0 will check every 20 seconds for messages to be sent out immediately.
  ### Spool 1 will check every 60 seconds for messages that have been there for 30 min.
  ### Spool 2 will check every 3  minutes for messages that have been there for 4  hours.
  ### Spool 3 will check every 8  minutes for messages that have been there for 8  hours.
  ### Spool 4 will check every 16 minutes for messages that have been there for 16 hours.
  ### Spool 5 will check every 33 minutes for messages that have been there for 24 hours.
  ### Spool 6 will check every 66 minutes for messages that have been there for 48 hours.
  ###
  ### For messages that fail the first, or subsequent times,
  ### the total retry time is 30m+4h+8h+16h+24h+48h = 100.5h or 4.2 days.

  my @spools = ();

  my $periods = $self->dequeue_periods;
  my $last = $#$periods;

  foreach my $i ( 0 .. $last ){

    ### essentially do this 1/x percent of the time
    my $int = int(rand() * $self->dequeue_priority->[$i]);
    next if $int;
    
    my $fallback_spool_dir = ($i == $last) ? undef : $self->dequeue_dir.'/'.($i+1);

    ### load a spool handle object
    my $msh = $self->mail_spool_handle(spool_dir    => $self->dequeue_dir.'/'.$i,
                                       fallback_dir => $fallback_spool_dir,
                                       wait         => $periods->[$i],
                                       spool        => $self,
                                       );

    ### allow for getting only the first spool handle
    if( ! wantarray ){
      return $msh;
    }

    ### add to the list
    push @spools, $msh;
  }

  return @spools;
}

sub mail_spool_handle {
  my $self = shift;
  return Mail::Spool::Handle->new(@_);
}

sub mail_spool_node {
  my $self = shift;
  return Mail::Spool::Node->new(@_);
}

###----------------------------------------------------------------###

sub dequeue {
  ### allow for invocation as function or method
  ### even though all are object oriented
  my $self = shift || __PACKAGE__->new(@_);

  ### iterate on all of the mail spool handles
  foreach my $msh ( $self->list_spool_handles ){

    ### open up that spool (if necessary)
    $msh->open_spool;

    while( defined(my $node = $msh->next_node) ){

      ### get exclusive lock
      my $lock = $node->lock_node;
      next unless $lock;
      
      ### get a IO::Handle style filehandle
      my $fh = $node->filehandle;
      if( ! $fh ){
        # what would be good here?
        next;
      }

      ### try to send it
      my $ok = eval{ $self->send_mail(to         => $node->to,
                                      from       => $node->from,
                                      filehandle => $fh,
                                      delivery   => 'Interactive',
                                      timeout    => $self->max_connection_time,
                                      id         => $node->id,
                                      ) } || '';
      my $error = $@ || '';
      
      ### the message was sent off OK
      if( $ok && ! $error ){
        $node->delete_node;
        next;
      }
      
      ### PAST THIS POINT - THE MESSAGE IS NOT OK, save for later (maybe)
      
      ### maximum number of retries reached.
      ### (is this the node's job of the mailspoolhandle's)
      if( ! defined $node->fallback_filename ){
        $error = "Undeliverable: maximum number of retries reached contacting \"".$node->to."\"";
      }
      
      warn "D$$: Got \"$ok\" back: $error\n" if $@ !~ /and thus/;
      
      ### If the message was couldn't be sent, but is not
      ### undeliverable, fallback and try again later.
      ### there was permanent error or we have tried enough
      if( $error !~ /^Undeliverable/i ){
        
        $node->fallback; # again, is this the node's job or msh's
        next;

      }

      ### If this was not already an error response, then
      ### we should have an address and can't forward it
      if( $node->from || length($node->from) ){
          
        my $ok = eval{ $self->send_mail(to       => $node->from, # send back to the to
                                        from     => '<>',        # don't allow a return msg
                                        message  => $error,      # the message is the error
                                        delivery => 'Interactive',
                                        timeout  => 5 * 60,      # queue after 5 min
                                        id       => $node->id,
                                        ) };
          ### maybe check status, maybe we don't care
          ### maybe we should append original message
      }
        
      ### get rid of the file now
      $node->delete_node;

    }
  }
}

###----------------------------------------------------------------###

sub parse_for_address {
  my $self = shift;
  my $line = shift;
  my @objs = eval{ Mail::Address->parse($line) };
  if( $@ ){
    # do something
    return ();
  }
  return @objs;
}

sub new_message_id {
  my $self = shift;
  my $m    = shift;
  return uc(substr(md5_hex( time() . $$ . $m ), 2, 16));
}

###----------------------------------------------------------------###

### this sub can be used to replace Mail::SENDMAIL
# to         - will be used in the "rcpt to"   header (will be parsed out of message if not given)
# from       - will be used in the "mail from" header (will be parsed out of message if not given)
# message    - Mail::Internet obj, MIME::Entity obj, array ref, scalar ref, or scalar
# filehandle - if message is empty, should be a readable IO::Handle style object containing the message
# filename   - if message and filehandle are empty, should be path to file containing the message
# delivery   - type of delivery, can be one of the following:
#              - Deferred (or Standard) - put it in a spool for latter
#              - Interative - block until sent (or timed out), die on failure
#              - Background - block until sent (or timed out), put in spool on failure
# timeout    - on Interactive or Background, seconds to try and connect to a host
# id         - message id to be used in the queue filename

sub send_mail {

  ### allow for call as a function or a method
  my $self;
  if( @_ && $_[0] && ref($_[0]) && $_[0]->isa(__PACKAGE__) ){
    $self = shift;
  }else{
    $self = __PACKAGE__->new();
  }

  ### read the argument list
  my $args = (@_ && ref($_[0])) ? shift() : { @_ };


  ### objectify what is passed
  my $m = $self->parse_message($args);
  die "Couldn't parse message [$@]" unless $m;
  $args->{message} = $m;


  ### make sure we have a "to" line
  my $to = $args->{to} ? ref($args->{to}) eq 'ARRAY' ? $args->{to} : [$args->{to}] : [];
  if( ! ref($to) || ! @$to ){
    my %to = ();
    foreach my $line ($m->head->get('To'),
                      $m->head->get('Cc'),
                      $m->head->get('Bcc'),
                      ){
      foreach my $obj ( $self->parse_for_address($line) ){
        my $addr = $obj->address();
        $to{$addr} = 1;
      }
    }
    $to = [keys %to];
  }
  die "You didn't supply a \"to\" field and the message didn't have one" unless @$to;


  ### make sure we have a "from" line (an empty from is fine, just not returnable)
  my $from = $args->{from};
  if( ! defined $from ){
    my @from = $m->head->get('From') || (undef);
    my @objs = $self->parse_for_address($from[0]);
    $from = @objs ? $objs[0]->address() : undef;
  }
  die "You didn't supply a \"from\" field and the message didn't have one"
    unless defined $from;
  $args->{from} = $from;


  ### don't show bcc's
  $m->head->delete('Bcc');


  ### read the type of delivery
  $args->{delivery} ||= 'Deferred'; # can be Standard, Deferred, Background, or Interactive
  $args->{delivery}   = 'Deferred'
    if $args->{delivery} !~ /^(Deferred|Background|Interactive)$/;


  ### DELIVERY DEFERRED: queue the message
  if( $args->{delivery} eq 'Deferred' ){
    
    ### what is the message id ?
    my $id = $args->{id} || undef;
    if( ! $id ){
      my @received = $m->head->get('Received') || ();
      foreach my $tag ( @received ){
        if( $tag =~ /\s+id\s+\(([^\)]+)\)/ ){
          $id = $1;
          last;
        }
      }
    }
    if( ! $id ){
      $id = $self->new_message_id($m);
    }

    ### get a few more arguments
    $args->{id}  = $id;
    $args->{msh} = $self->list_spool_handles;

    ### write it to the queue
    ### iterate on all addresses
    foreach my $TO ( @$to ){
      my $old = $args->{to};
      $args->{to} = $TO;

      ### send it off
      $self->_send_mail_deferred($args);

      $args->{to} = $old;
    }

  ### DELIVERY NONDEFERED: try to send it now
  }else{
    
    ### deliver it to the remote boxes
    foreach my $TO ( @$to ){
      my $old = $args->{to};
      $args->{to} = $TO;

      ### send it off
      $self->_send_mail_now($args);

      $args->{to} = $old;
    }
  }

  return 1;
}

### make sure that what ever they passed us is turned
### into an object that supporst 'head' and 'print'
sub parse_message {
  my $self = shift;
  my $args = (@_ && ref($_[0])) ? shift() : { @_ };

  my $m   = $args->{message} || undef;
  my $ref = $m ? ref($m) : '';

  ### need to create a suitable object
  if( ! $ref || $ref eq 'SCALAR' ){

    ### no message -- read one
    if( ! $m ){
      my $fh = $args->{filehandle} || undef;

      ### no filehandle -- create one
      if( ! $fh ){
        die "No clue what to do (I need a message or a filename)!" unless $args->{filename};
        die "File \"$args->{filename}\" doesn't exist and thus cannot be sent" unless -e $args->{filename};
        $fh = IO::File->new( $args->{filename}, 'r' );
        die "Can't open \"$args->{filename}\" [$!]" unless $fh;
      }

      ### create an object from the filehandle
      $m = eval{ Mail::Internet->new( $fh ) };

    ### turn passed scalar message into an object
    }else{
      my $txt = $ref ? $m : \$m;
      $m = eval{ Mail::Internet->new([ ($$txt =~ m/^(.*\n?)/mg) ]) };
    }

  ### turn array refs into the object
  }elsif( $ref eq 'ARRAY' ){
    $m = eval{ Mail::Internet->new( $m ) };

  ### make sure anything else can at least do the right methods
  }elsif( ! $m->can('head') ){
    die "Passed object must have a 'head' method";
  }elsif( ! $m->can('print') ){
    die "Passed object must have a 'print' method";
  }
  ### actually they need a ->head, ->print, ->body, ->header,
  ### ->head->get, ->head->add, ->head->delete
  ### we will just check the basic ones for them.


  return $m;
}

###----------------------------------------------------------------###

sub _send_mail_deferred {
  my $self = shift;
  my $args = (@_ && ref($_[0])) ? shift() : {@_};
  my $TO   = $args->{to};
  my $m    = $args->{message};
  my $from = $args->{from};

  ### encode values for the filename
  foreach ( $TO, $from ){
    s/([^\ -~])/sprintf("%%%02X",ord($1))/eg;
    s/([\%\/\-])/sprintf("%%%02X",ord($1))/eg;
  }

  ### create a new node
  my $node = eval{ $self->mail_spool_node(msh  => $args->{msh},
                                          name => join("-",time(),$args->{id},$TO,$from),
                                          ) };
  die "Couldn't create new node [$@]" unless defined $node;
  
  ### lock it
  my $lock = $node->lock_node;
  die "Couldn't get lock on node [".$node->lock_error."]" unless defined $lock;
  
  ### write it out
  my $fh = $node->filehandle('w') || die "Couldn't open node [$!]";
  $m->print($fh);
  $fh->close();
  
  ### record the size
  my $bytes = $node->size;
  $self->log_usage($bytes,'Spool');
}


sub _send_mail_now {
  my $self = shift;
  my $args = (@_ && ref($_[0])) ? shift() : {@_};
  my $TO   = $args->{to};
  my $m    = $args->{message};
  my $from = $args->{from};

  my @to = $self->parse_for_address( $TO );
  die "Not a valid \"to\"" unless @to && ref($to[0]);
  my $host = $to[0]->host();
  my $sock;
  my $mx_host;

  ### protect the lookup with a timeout
  local $SIG{ALRM} = sub{ die "Timed out\n" };
  eval{
    my $old_alarm = $args->{timeout} ? alarm($args->{timeout}) : undef;
    
    ### get the dns for this host
    my  @mx = $self->lookup_mx($host); 
    die "MX lookup error" unless @mx;
    
    ### attempt to connect to one of the mail servers
    foreach my $_mx_host ( @mx ){
      $mx_host = $self->lookup_host($_mx_host);
      
      warn "S$$: Trying $mx_host\n";
      $sock = $self->open_smtp_connection($mx_host);
      last if defined $sock;
      
    }

    alarm($old_alarm ? $old_alarm : 0);
  };

  ### see if we have sock. if not, die unless delivery is to be backgrounded
  if( ! defined $sock ){
    if( $args->{delivery} eq 'Background' ){
      $args->{delivery} = 'Deferred';
      eval{ $self->send_mail( %$args ) };
      if( $@ ){
        die $@;
      }else{
        return 1;
      }
    }else{
      die "Couldn't open a connection to mx of $host [$!]";
    }
  }
  
  ### retrieve the greeting
  my $status;
  my $_msg = $sock->message();
  $_msg =~ s/\n(\w)/\n  $1/g; # indent for the log
  warn "S$$: Connected to host ($mx_host): ".$sock->code()." ".$_msg;
  
  ### send the mail from
  $sock->mail($from);
  $self->check_sock_status($sock,$mx_host,$from,$TO);
  warn "S$$: Mail from is done ($from) ".$sock->code()." ".$sock->message();
  
  ### send the rcpt to
  $sock->to($TO);
  $self->check_sock_status($sock,$mx_host,$from,$TO);
  warn "S$$: Rcpt to is done ($TO) ".$sock->code()." ".$sock->message();
  
  ### request to send data
  ### we are not using the data method of Net::SMTP because we don't
      ### want to duplicate this message in memory
  $sock->command("DATA");
  $sock->response();
  $self->check_sock_status($sock,$mx_host,$from,$TO);
  warn "S$$: Data request is sent ".$sock->code()." ".$sock->message();
  
  ### make sure the headers are folded
  $m->head->fold();
  
  ### Possible duplication of memory. I hope people
  ### who write objects are smart with their memory
  ### and just give us a reference to the lines
  ### (Mail::Internet is not smart, sadly)
  my $body = $m->body();
  
  ### send the message header, double newline, and body
  ### do so on our own because Net::SMTP (Net::Cmd) duplicates memory
  my $bytes = 0;
  foreach ( @{ $m->header() }, $crlf, @$body ){
    s/(^|[^\015])\012/$1$crlf/g; # a cr before lf if none
    s/^\./../g;                  # byte stuff as per RFC
    print $sock $_;
    $bytes += length($_);
  }

  ### if the last line doesn't have a newline, add one
  if( $body->[$#$body] !~ /$crlf/ ){
    print $sock $crlf;
    $bytes += length($crlf);
  }

  $self->log_usage($bytes,'Sent');
  
  ### do the termination byte
  $sock->command('.');
  $sock->response();
  $self->check_sock_status($sock,$mx_host,$from,$TO);
  warn "S$$: Data end sent ".$sock->code()." ".$sock->message();
  
  ### all done
  $sock->quit() || die "Couldn't send the quit [$!]";
  $self->check_sock_status($sock,$mx_host,$from,$TO);
  
}

###----------------------------------------------------------------###

### see if the previous command was successful
sub check_sock_status {
  my $self = shift;
  my $sock = shift;
  if( !$sock->status() ){
    die "Couldn't get status, try again later\n";
  }elsif( $sock->status() == 5 ){
    die "Undeliverable: <$_[0]> <$_[1]> <$_[2]>"
      .$sock->code()." ".$sock->message()."\n";
  }elsif( $sock->status() == 4 ){
    die "Temporary trouble, try again later [".$sock->code()." ".$sock->message()."]\n";
  }
}

### look up the mx records
### we could possibly cache them
sub lookup_mx {
  my $self = shift;
  my $host = shift;

  my @mx = Net::DNS::mx($host);

  @mx = sort {$a->preference() <=> $b->preference()} @mx;
  
  @mx = map {$_->exchange()} @mx;

  return @mx;
}

### we could translate the host into 
### an ip right here and cache it
sub lookup_host {
  my $self = shift;
  my $host = shift;
  return $host;
}

### return an open socket ready for printing to
### possible caching of connection with RSET
### in between could be done here
sub open_smtp_connection {
  my $self = shift;
  my $host = shift;
  my $timeout = shift || 0;
  my $sock = Net::SMTP->new($host,
                            Port    => 25,
                            Timeout => $timeout,
                            );
  return $sock;
}

###----------------------------------------------------------------###

### dump routine to log a number and purpose
### usually like "23434 spooled" (number of bytes spooled)
sub log_usage {
  my $self  = shift;
  my $bytes = shift;
  my $purpose = shift;
  return unless -d $self->usage_log;
  if( ! open(_FH,">>".$self->usage_log."/raw") ){
    warn "Couldn't open \"".$self->usage_log."/raw\" ($!)";
    return;
  }

  print _FH time()." $bytes $purpose\n";
  close _FH;
}

###----------------------------------------------------------------###

sub AUTOLOAD {
  my $self = shift;

  my ($method) = ($AUTOLOAD =~ /([^:]+)$/) ? $1 : '';

  ### install some some routines if asked
  if( $method =~ /^(dequeue_dir|
                    dequeue_periods|
                    dequeue_priority|
                    dequeue_timeout|
                    max_dequeue_processes|
                    usage_log|
                    max_connection_time
                    )$/x ){
    no strict 'refs';
    * { __PACKAGE__ ."::". $method } = sub {
      my $self = shift;
      $self->{$method} = $ { __PACKAGE__."::".uc($method) }
        if ! defined $self->{$method};
      my $val = $self->{$method};
      $self->{$method} = shift if @_;
      return $val;
    };
    use strict 'refs';
    
    ### now that it is installed, call it again
    return $self->$method( @_ );
  }

}

1;

__END__


=head1 NAME

Mail::Spool - Extensible Perl Mail Spooler

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  package MyPackage;

  use Mail::Spool;
  @ISA = qw(Mail::Spool);

  my $spool = Mail::Spool->new();

  $spool->dequeue_dir = '/var/spool/mail';

  $spool->daemon;
  exit;

  # OR

  use Mail::Spool qw(send_mail);
  my $args = {to   => 'anybody@in.the.world',
              from => 'me@right.here.local',
              delivery => 'Interactive', # or Deferred
              timeout  => 2 * 60, # two minutes
              filename =>
              #or# message  => $scalar,
              #or# message  => \$scalar,
              #or# message  => $a_mail_internet_object,
              #or# filehandle => $open_io_handle,
              };
  my $spool = Mail::Spool->new();
  eval{ $spool->send_mail($args) };

  # OR

  eval{ send_mail($args) };
  if( $@ ){
    die "Something went wrong [$@]";
  }

=head1 OBTAINING

Visit http://seamons.com/ for the latest version.

=head1 DESCRIPTION

Mail::Spool is a "pure perl" implementation of
mail spooling, unspooling and sending.  It is
intended to be used with daemons such as
Net::Server::SMTP (to be released soon), but it
also contains its own daemon (based off of
Net::Server::Fork) that can be used if necessary.

It is also intended to be used as a quick spooling
mechanism for perl scripts.  As it can write
straight to the queue without opening another process.

The send_mail method allows for either Deferred or
Interactive sending of mail.

As of this writing, a version Mail::Spool has been in use in
production for three months spooling and sending
about 200MB a day in several thousand messages.

The default setup allows for setup on multiple
servers, all sharing a common spool directory.
NFS capable locking will take place in necessary areas.

=head1 PROPERTIES

Properties of Mail::Spool are accessed methods of
the same name.  They may be set by calling the
method and passing the new value as an argument.
For example:

  my $dequeue_dir = $self->dequeue_dir;
  $self->dequeue_dir($new_dequeue_dir);

The following properties are
available:

=over 4

=item dequeue_dir

Base location for the mail spool.  Defaults to
$Mail::Spool::DEQUEUE_DIR which at load time
contains "/var/spool/mail".

=item dequeue_periods

An array ref containing the amount of time a
message must wait in the spool and fallback
spools.  Defaults to $Mail::Spool::DEQUEUE_PERIODS
which at load time contains an array ref with 0,
.5*3600, 4*3600, 8*3600, 16*3600, 24*3600, and
48*3600 as its values.  A directory for each of
these times will be created (0 will be in
dequeue_dir/0, .5*3600 will be dequeue_dir/1,
etc).  For a further discussion of dequeue times
and methods, please read the extended comment in
the source code under the subroutine list_spool_handles.

=item dequeue_priority

An array ref containing an equal number of
elements as dequeue_periods.  Elements should be
integers.  Defaults to
$Mail::Spool::DEQUEUE_PRIORITY which at load time
contains an array ref with 1, 3, 9, 25, 50, 100,
and 200 as its values.  A lower number means
higher priority.  With a 20 second
dequeue_timeout, a priority of 1 checks the queue
every 20 seconds, 3 checks every 60 seconds, and
200 checks every 66 minutes.   For a further 
discussion of dequeue times and methods, please
read the extended comment in the source code under
the subroutine list_spool_handles.

=item dequeue_timeout

Seconds to wait before before looking through the
queues.  Defaults to $Mail::Spool::DEQUEUE_TIMEOUT
which at load time is 20 (seconds).

=item max_dequeue_processes

Maximum number of dequeue processes to start under
a daemon.  Defaults to
$Mail::Spool::MAX_DEQUEUE_PROCESSES which at load
time is 20.

=item max_connection_time

Maximum amount of time to stay connected to a
remote host.  Defaults to
$Mail::Spool::MAX_CONNECTION_TIME which at load
time is 6*60*60 (6 hours).  Messages not delivered
under this time period are queued for later delivery.

=item usage_log

Location to store raw spool usage information.
Defaults to $Mail::Spool::USAGE_LOG which at
load time is "$Mail::Spool::DEQUEUE_DIR/usage".

=back

=head1 METHODS

=over 4

=item new  

Returns an object blessed into the passed class.
A hash, or hashref passed to the the method will
be set as hash keys of the object.

=item daemon 

Starts a mail spool daemon using Net::Server::Fork
as the back end.  Will run continuously until the
main process is killed.  Log information defaults
to 'Sys::Syslog'.

=item create_dequeue_dirs

May be called as a method or function.
Hook to create the necessary directories used by
the spool daemon.

=item list_spool_handles

Returns a list of objects blessed into the 
Mail::Spool::Handle class (by default).  These
handle objects represent the queue (spools) that
need to be processed at the moment.  For an
important discussion of architecture and waiting
times, please read the comments in the source code
located within this subroutine.

=item mail_spool_handle

Returns an object blessed into the
Mail::Spool::Handle class.  See L<Mail::Spool::Handle>.

=item mail_spool_node

Returns an object blessed into the
Mail::Spool::Node class.  See L<Mail::Spool::Node>.

=item dequeue

May be called as a method or function.
Run through a dequeue process.  This consists of
listing spool handles, opening the spools, reading
nodes from the spools, and having the nodes fallback
upon failed delivery.  Dequeue is called
periodically based upon dequeue_timeout one the
daemon process has been started.

=item parse_for_address

Short wrapper around Mail::Address-E<gt>parse.  Should
take an email address line and return a list of
objects that can support -E<gt>address, -E<gt>domain,
and -E<gt>format methods.  See L<Mail::Address>.

=item new_message_id

During the send_mail process if a message is
deferred, the spooler will attempt to parse a
message id from the email.  If none can be found,
this method is called to generate a new id which
will be used in the spooling process.

=item send_mail

May be called as a method or function.
Send mail takes a message and either sends it off
or places it in the queue.  Arguments are a hash
or a hashref.  The possible
arguments to send_mail are as follows:

=over 4

=item to

Will be used in the "rcpt to" SMTP header (this
will be parsed out of message if not given).

=item from

Will be used in the "mail from" header (this will
be parsed out of message if not given).

=item message

My be either a scalar, a scalar ref, an array ref,
or an object which supports the following head,
print, body, header, head-E<gt>get, head-E<gt>add,
and head-E<gt>delete.  Mail::Internet and
MIME::Entity objects work.  If message is not
given, filehandle or filename may be given.

=item filehandle

Used if message is not given.  Must contain an
open IO::Handle style object (such as IO::File or
IO::Scalar). 

=item filename

Used if neither message or filehandle are given.
Must contain the path to a readable filename.

=item delivery

Type of delivery to be used.  Must be one of the
following: Deferred - put in the spool for later
(default), Standard - same as Deferred, Interative
- block until sent (or timed out) and die on
failure, Background - block until sent (or timed
out) and put in spool on failure.

=item timeout

Used with delivery Interactive or delivery
Background.   Seconds to wait while trying to
connect to a host.

=item id 

Message id to be used in the queue filename.  Used
under deferred delivery.  If none is given, will
be parsed out of the message.  If none is found,
will be generated using new_message_id.

=back


=item parse_message

Based upon the arguments given, returns an object
that possesses the correct methods for use in the
send_mail routine.  Arguments may be given either
as a hash or a hashref.  The main arguments are
"message," "filehandle," or "filename.".  Message
may be either a scalar or scalar ref containing
the message, an array ref containing the lines of
the message, or an object which supports head,
body, and print methods (such as Mail::Internet,
or MIME::Entity) (actually the object needs to
support head, print, body, header, head-E<gt>get,
head-E<gt>add, and head-E<gt>delete).  If there is
no message argument, and there is a "filehandle"
argument, parse_message will create an object from
the filehandle (the filehandle should be an
IO::Handle style object).  If no filehandle is
given, parse_message will look for a "filename"
argument.  This should be a readable filename
accessible by the spooler.  In all cases, the
passed message should contain the email headers
necessary.  If it does not, the headers will be
added as necessary.  This method returns a
Mail::Internet compatible object.

=item _send_mail_deferred

Called by send_mail.  Arguments should a hash or hash
ref.  Places the message contained in the
"message" argument into the mail spool and returns
immediately.  Required arguments are "message,"
"to," "from," "id," and "msh" (a
Mail::Spool::Handle object).

=item _send_mail_now

Called by send_mail.  Arguments shoud be a hash or hash
ref.  Required arguments are "message,"
"to," "from," "id," "timeout," and "delivery."  Looks up the
mx records of the domain found in "to" using the
lookup_mx method, and iterates through each of these
records and tries to open a connection using
open_smtp_connection (times out after "timeout"
seconds).  Once a connection has been
established, sends the message, testing responses
using check_sock_status.  If delivery is
"Background," and a connection could not be
established, the message will be queued for later
delivery.  Any errors die.

=item check_sock_status

Checks the status of the last smtp command.
Arguments are the open socket, the mx host, the to
address, and the from address.  Any errors die.

=item lookup_mx

Takes a hostname as an argument.  Should return a
list of the mx records for that hostname, ordered
by their priorities.  This method could also be
sub classed to allow for caching of the response.

=item lookup_host

Takes a hostname as an argument.  Should return a
hostname or an ip address.  Intended as a means of
caching records.  Default is to simply return the
passed host.

=item open_smtp_connection

Takes a hostname as an argument.  Returns a
IO::Socket style object containing an open
connection to that host (or undef on failure).
This could be overridden to allow for holding the
connection open across several emails to the same
domain.

=item log_usage

Takes a number and word as arguments.  Writes this
information out to a very simple log.  Intended
for gathering basic spool information, such as
total bytes spooled and total bytes sent, as well
as total messages spooled and sent.

=item AUTOLOAD

Used to dynamically some of the property methods.

=back

=head1 TO DO

=over 4

=item Use It

The best way to further the status of this project is to use
it.  A less extensible version of this module has been in
use for around three months as of this writing.  

=item Extensions

Explore other extenstions such as optimized read of spool
directories to order by domain.  Possibly add
interface to allow placing mail in postfix and
sendmail compatible queues.

=item DNS

Add modules to handle DNS caching.

=item Interfaces

Add modules containing interfaces to databases, or other
"file systems".

=back

=head1 BUGS

The current setup of Mail::Spool does represent a
possible denial of service if 20 or thirty
messages are sent to a host that simply holds a
connection open and does nothing else during mail
delivery.  What should probably be done instead is
to only do one dequeue process at a time (ever)
and fork off a separate process for each mail.
This will probably be coming under later releases.

=head1 SEE ALSO

Please see also
L<Mail::Spool::Handle>,
L<Mail::Spool::Node>.

=head1 COPYRIGHT

  Copyright (C) 2001, Paul T Seamons
                      paul@seamons.com
                      http://seamons.com/

  This package may be distributed under the terms of either the
  GNU General Public License
    or the
  Perl Artistic License

  All rights reserved.

=cut
