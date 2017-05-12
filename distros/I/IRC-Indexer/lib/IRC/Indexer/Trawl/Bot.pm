package IRC::Indexer::Trawl::Bot;

use 5.10.1;
use strict;
use warnings;
use Carp;

use IRC::Indexer;

use IRC::Indexer::Report::Server;

use POE;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::CTCP;

use IRC::Utils qw/
  decode_irc
  strip_color strip_formatting
/;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;

  $self->{State} = {};
  
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  $self->verbose($args{verbose} || 0);

  $self->{timeout}   = $args{timeout}  || 90;
  $self->{interval}  = $args{interval} || 5;

  $self->{ircserver} = $args{server} 
    || croak "No Server specified in new" ;

  $self->{ircport} = $args{port}     || 6667 ;
  $self->{ircnick} = $args{nickname} || 'iindx'.(int rand 666);  
  
  $self->{bindaddr} = $args{bindaddr} if $args{bindaddr};
  $self->{useipv6}  = $args{ipv6} || 0;

  $self->{POST} = delete $args{postback}
    if $args{postback} and ref $args{postback};

  $self->{Serv} = IRC::Indexer::Report::Server->new;

  return $self
}

sub trawler_for { return $_[0]->{ircserver} }

sub spawn {
  my ($pkg, %opts) = @_;
  croak "cannot use spawn() interface without a postback"
    unless $opts{postback};
  my $self = $pkg->new(%opts);
  $self->run();
  return $self->{sessid}
}

sub run {
  my ($self) = @_;

  $self->{Serv}->connectedto( $self->{ircserver} );
  
  my $sess = POE::Session->create(
    object_states => [
      $self => [
      
      ## Internals / PoCo::IRC:
      qw/
         _start
         _stop
         shutdown
         
         b_check_timeout
         b_retrieve_info
         b_issue_cmd
         
         irc_connected
         irc_001
         
         irc_disconnected
         irc_error
         irc_socketerr       
      /,
      
      ## Numerics:
        ## MOTD
         'irc_372',
         'irc_375',
         'irc_376',
        ## LINKS
         'irc_364',
         'irc_365',
        ## LUSERS
         'irc_251',
         'irc_252',
        ## LIST
         'irc_322',
         'irc_323',
    ] ],
  );
  
  $self->{sessid} = $sess->ID;

  $self->{Serv}->startedat( time() );
  
  return $self
}

sub verbose {
  my ($self, $verbose) = @_;
  return $self->{verbose} = $verbose if defined $verbose;
  return $verbose
}

sub irc {
  my ($self, $irc) = @_;
  return $self->{ircobj} = $irc if $irc;
  return $self->{ircobj}
}

sub info { report(@_) }
sub report {
  my ($self) = @_;
  return $self->{Serv}
}

## Status accessors

sub failed {
  my ($self, $reason) = @_;
  return unless ref $self->report;
  
  if ($reason) {
    carp "Trawl run failed: $reason" if $self->verbose;
    $self->report->status('FAIL');
    $self->report->failed($reason);
    $self->report->finishedat(time);
  } else {
    return unless defined $self->report->status 
           and $self->report->status eq 'FAIL';
  }
  return $self->report->failed
}

sub done {
  my ($self, $finished) = @_;
  
  if ($finished) {
    carp "Trawler completed: ".$self->report->connectedto
      if $self->verbose;
    $self->report->status('DONE');
    $self->report->finishedat(time());
  }

  return unless ref $self->report;  
  return unless $self->report->status eq 'DONE'
         or     $self->report->status eq 'FAIL';
  return $self->report->status
}

sub dump {
  my ($self) = @_;
  ## return() if we're not done:
  return unless ref $self->report;
  return unless defined $self->report->status 
         and $self->report->status eq 'DONE'
         or  $self->report->status eq 'FAIL';
  ## else return hashref of net info (or failure status)
  ## that way masters can iterate through a pool of bots and check 'em
  ## frontends can serialize / store
  return $self->report->netinfo
}

sub ID {
  ## Get our POE SessionID if running.
  my ($self) = @_;
  return $self->{sessid}
}

sub _stop {}
sub shutdown {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  
  $kernel->alarm('b_check_timeout');
  $kernel->alarm('b_issue_cmd');

  warn "-> Trawler shutdown called\n" if $self->verbose;

  $self->done(1) unless $self->done;
  $self->irc->yield('shutdown', "Leaving", 2)   if ref $self->irc;
  $self->irc(1);
  
  if (my $postback = delete $self->{POST}) {
    $postback->($self);
  }
}

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  
  my %ircopts = (
    nick     => $self->{ircnick},
    username => 'ircindexer',
    ircname  => __PACKAGE__,
    server   => $self->{ircserver},
    port     => $self->{ircport},
    useipv6  => $self->{useipv6},
  );
  $ircopts{localaddr} = $self->{bindaddr} if $self->{bindaddr};
  
  my $irc = POE::Component::IRC->spawn( %ircopts );
  $self->irc( $irc );

  warn "-> Trawler spawned IRC\n" if $self->verbose;
  
  $irc->plugin_add('CTCP' =>
    POE::Component::IRC::Plugin::CTCP->new(
      version => __PACKAGE__.' '.$IRC::Indexer::VERSION,
    ),
  );
  
  $irc->yield(register => qw/
    connected
    disconnected
    socketerr
    error
    
    001
    
    375 372 376

    364 365
    
    251 252
    
    322 323
  / );

  $irc->yield(connect => {});
  
  $kernel->alarm( 'b_check_timeout', time + 5 );
}

sub b_retrieve_info {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  ## called via alarm() (in irc_001)

  warn "-> Retrieving server information\n" if $self->verbose;

  $self->report->server( $self->irc->server_name )
    unless $self->report->server;

  my $irc = $self->irc;  
  
  my $report = $self->report;
  
  my $network = $irc->isupport('NETWORK') || $irc->server_name;
  $report->netname($network);

  $report->ircd( $irc->server_version // 'Not Available' );  
  ## yield off commands to grab anything else needed:
  ##  - LUSERS (maybe, unless we have counts already)
  ##  - LINKS
  ##  - LIST
  ## stagger them out at reasonable intervals to avoid flood prot:
  my $alrm = 2;
  for my $cmd (qw/list links lusers/) {
    $kernel->alarm_add('b_issue_cmd', time + $alrm, $cmd);
    $alrm += $self->{interval};
  }
}

sub b_issue_cmd {
  my ($self, $cmd) = @_[OBJECT, ARG0];
  
  $self->report->server( $self->irc->server_name )
    unless $self->report->server;

  ## most servers will announce lusers at connect-time:
  return if $cmd eq 'lusers' and $self->{State}->{Lusers};
  
  warn "-> Issuing: $cmd\n" if $self->verbose;
  $self->irc->yield($cmd);
}

sub b_check_timeout {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my $irc = $self->irc;
  my $report = $self->report;
  
  my $shutdown = 0;
  
  my @states = qw/Links Lusers MOTD List/;
  my $stc = 0;
  for my $state (@states) {
    next unless $self->{State}->{$state};
    $stc++;
    warn "-> have state: $state\n" if $self->verbose;
  }
  
  $shutdown = 1 if $stc == scalar @states;

  my $startedat = $report->startedat || 0;
  if (time - $startedat > $self->{timeout}) {
    $self->failed("Timed out");
    ++$shutdown;
  }

  if ($shutdown) {
    warn "-> Posting shutdown to own session\n" if $self->verbose;
    $kernel->post( $_[SESSION], 'shutdown' )
      if $_[SESSION] eq $_[SENDER];
  }
  
  $kernel->alarm( 'b_check_timeout', time + 1 );
}

## PoCo::IRC handlers

sub irc_connected {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  ## report connected status; irc_001 handles the rest
  my $report = $self->report;
  $report->status('INIT');
  $report->connectedat(time());
}

sub irc_disconnected {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  ## we're done, clean up and report such 
  $self->failed("irc_disconnected") unless $self->done;
  $self->report->server($_[ARG0]) unless $self->report->server;
  $self->done(1);
}

sub irc_socketerr {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my $err = $_[ARG0];
  $self->failed("irc_socketerr: $err");
  $kernel->call( $_[SESSION], 'shutdown' );
}

sub irc_error {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my $err = $_[ARG0];
  ## errored out. clean up and report failure status
  $self->failed("irc_error: $err") unless $self->done;
  $kernel->call( $_[SESSION], 'shutdown' );
}

sub irc_001 {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->report->status('CONNECTED');
  my $this_server = $self->irc->server_name;
  $self->report->server($this_server) if $this_server;
  ## let things settle out, then b_retrieve_info:
  $kernel->alarm('b_retrieve_info', time + 3);
}

sub irc_375 {
  ## Start of MOTD
  my ($self, $server) = @_[OBJECT, ARG0];
  my $report = $self->report;
  $report->blank_motd;
  $report->motd( "MOTD for $server:" );
}

sub irc_372 {
  ## MOTD line
  my ($self) = $_[OBJECT];
  my $report = $self->report;
  $report->motd( $_[ARG1] );
}

sub irc_376 {
  ## End of MOTD
  my ($self) = $_[OBJECT];
  my $report = $self->report;
  $report->motd( "End of MOTD." );  
  $self->{State}->{MOTD} = 1;
}

sub irc_364 {
  ## LINKS, if we can get it
  ## FIXME -- also grab ARG2 and try to create useful hash?
  my ($self) = $_[OBJECT];
  my $rawline;
  return unless $rawline = $_[ARG1];
  push(@{ $self->{ListLinks} }, $_[ARG1]);
}

sub irc_365 {
  ## end of LINKS
  my $self = $_[OBJECT];
  $self->report->links( $self->{ListLinks} );
  $self->{State}->{Links} = 1;
}

sub irc_251 {
  my ($self) = $_[OBJECT];
  my $report = $self->report;
  $self->{State}->{Lusers} = 1;
    
  my $rawline;
  ## LUSERS
  ## may require some fuckery ...
  ## may vary by IRCD, but in theory it should be something like:
  ## 'There are X users and Y invisible on Z servers'
  return unless $rawline = $_[ARG2]->[0];
  my @chunks = split ' ', $rawline;
  my($users, $i);
  while (my $chunk = shift @chunks) {
    if ($chunk =~ /^[0-9]+$/) {
      $users += $chunk;
      last if ++$i == 2;
    }
  }
  $report->users($users||0)
}

sub irc_252 {
  ## LUSERS oper count
  my ($self) = $_[OBJECT];
  my $report = $self->report;
  my $rawline = $_[ARG1];
  my ($count) = $rawline =~ /^([0-9]+)/;
  $report->opers($count||0);
}

sub irc_322 {
  ## LIST
  my ($self) = $_[OBJECT];
  my $report = $self->report;
  my $split = $_[ARG2] // return;
  my ($chan, $users, $topic) = @$split;
  
  $chan  = decode_irc($chan);
  $topic = decode_irc( strip_color(strip_formatting($topic)) );
  
  $users //= 0;
  $topic //= ''; 
  
  ## Add a hash element
  $report->add_channel($chan, $users, $topic);
}

sub irc_323 {
  ## LIST ended
  my ($self) = $_[OBJECT];  
  $self->{State}->{List} = 1;
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Trawl::Bot - Indexing trawler instance

=head1 SYNOPSIS

  ## Inside a POE session
  ## 'spawn' returns session ID:  
  my $trawl_sess_id = IRC::Indexer::Trawl::Bot->spawn(
    ## Server address and port:
    Server  => 'irc.cobaltirc.org',
    Port    => 6667,
    
    ## Nickname, defaults to irctrawl$rand:
    Nickname => 'mytrawler',
    
    ## Local address to bind, if needed:
    BindAddr => '1.2.3.4',
    
    ## IPv6 trawler:
    UseIPV6 => 1,
    
    ## Overall timeout for this server
    ## (The IRC component may time out sooner if the socket is bust)
    Timeout => 90,
    
    ## Interval between commands (LIST/LINKS/LUSERS):
    Interval => 5,
    
    ## Verbosity/debugging level:
    Verbose => 0,
    
    ## Optionally use postback interface:
    Postback => $_[SESSION]->postback('trawler_done', $some_tag);    
  );

  ## Using postback:
  sub trawler_done {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $tag     = $_[ARG0]->[0];
    my $trawler = $_[ARG1]->[0];
    my $report = $trawler->report;
    . . .
  }

  ## Or without postbacks:
  
  ## Spawn a bunch of trawlers in a loop
  ## new() and run() both return a trawler object
  my $trawlers;
  for my $server (@servers) {
    $trawlers->{$server} = IRC::Indexer::Trawl::Bot->new(
      server => $server,
    )->run();
  }
  
  ## Check on them later:
  SERVER: for my $server (keys %$trawlers) {
    my $trawl = $trawlers->{$server};
    
    next SERVER unless $trawl->done;
    
    next SERVER if $trawl->failed;
    
    my $report  = $trawl->report;
    my $netname = $report->network;
    my $hash    = $report->netinfo;
    . . . 
  }

=head1 DESCRIPTION

A single instance of an IRC::Indexer trawler; this is the bot that forms 
the backbone of the rest of the IRC::Indexer modules and utilities.

Connects to a specified server, gathers some network information, and 
disconnects when either all requests appear to be fulfilled or the 
specified timeout (defaults to 90 seconds) is reached. Uses 
L<POE::Component::IRC> for an IRC transport.

There are two ways to interact with a running trawler: the object 
interface or a POE session postback.

When the trawler is finished, $trawl->done() will be boolean true; if 
there was some error, $trawl->failed() will be true and will contain a 
scalar string describing the error. See L</new> and L</run> if you'd 
like to use the object interface.

If a postback was specified at construction time, the event will be 
posted when a trawler has finished. $_[ARG1]->[0] will contain the 
trawler object; $_[ARG0] will be an array reference containing any 
arguments specified in your 'Postback =>' option after the event name.
See L</spawn> if you'd like to use the POE interface.

The B<report()> method returns the L<IRC::Indexer::Report::Server> 
object.

The B<dump()> method returns a hash reference containing network 
information (or undef if not done); see L<IRC::Indexer::Report::Server> 
for details. This is the hash returned by 
L<IRC::Indexer::Report::Server/netinfo>

The trawler attempts to be polite, spacing out requests for LINKS, 
LUSERS, and LIST; you can fine-tune the interval between commands by 
specifying a different B<interval> at construction. 

See L<IRC::Indexer::Trawl::Forking> for an interface-compatible forked
trawler instance.

=head1 METHODS

=head2 new

Construct, but do not L</run>, a trawler instance.

Use new() when you'd like to create pending trawler instances that will 
sit around until instructed to L</run>.

new() can be used to construct trawlers before any POE sessions are 
initialized (but you lose the ability to use postbacks).

See L</SYNOPSIS> for constructor options.

=head2 spawn

Construct and immediately run a trawler from within a running 
L<POE::Session>.

Returns a POE session ID that can be used to post L</shutdown> events 
if needed.

See L</SYNOPSIS> for constructor options.

=head2 run

Start the trawler session. Returns the trawler object, so you can chain 
methods thusly:

  my $trawler = IRC::Indexer::Trawl::Bot->new(%opts)->run();

You should only call run() if you're not using the spawn() interface.

spawn() will call run() for you.

=head2 trawler_for

Returns the server this trawler was constructed for.

=head2 ID

Returns the POE::Session ID of the trawler, if it is running.

Can be used to post a L</shutdown>, if needed:

  $poe_kernel->post( $trawler->ID, 'shutdown' );

Returns undef if the trawler was constructed via B<new()> but was never 
B<run()>.

=head2 failed

If a trawler has encountered an error, B<failed> will return true and 
contain a string describing the problem.

It's safest to skip failed runs when processing output; if a report 
object does exist, the reported data is probably incomplete or broken.

=head2 done

Returns boolean true if the trawler instance has finished; it may still 
be L</failed> and have an incomplete or nonexistant report.

=head2 report

Returns the L<IRC::Indexer::Report::Server> object, from which server 
information can be retrieved.

Nonexistant until the trawler has been ->run().

=head2 dump

Returns the L</report> hash if the trawler instance has finished, or 
undef if not. See L<IRC::Indexer::Report::Server>

=head1 Shutting down

The trawler instance will run its own cleanup when the run has 
completed, but sometimes you may need to shut it down early.

The safest way to shut down your trawler is to post a B<shutdown> event:

  my $sess_id = $trawler->ID();
  if ($sess_id) {
    ## Or call(), if you really must ...
    $poe_kernel->post( $sess_id, 'shutdown' );
  }

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
