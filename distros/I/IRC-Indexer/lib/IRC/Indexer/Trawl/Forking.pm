package IRC::Indexer::Trawl::Forking;

## Object and session to handle a single forked trawler.
## This is mostly intended for ircindexer-server-json.

## Provide compatible methods w/ Bot::Trawl
## Other layers can use this with the same interface.

use 5.10.1;
use strict;
use warnings;
use Carp;

use Config;

use POE qw/Wheel::Run Filter::Reference/;

use Time::HiRes;

use IRC::Indexer::Report::Server;

require IRC::Indexer::Process::Trawler;

## Trawl::Bot compat:

sub new {
  my $self = {};
  my $class = shift;
  bless $self, $class;
  
  $self->{sessid} = undef;
  
  $self->{wheels}->{by_pid} = {};
  $self->{wheels}->{by_wid} = {};
  
  ## Grab and save same opts as Bot::Trawl
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  $self->{POST} = delete $args{postback}
    if $args{postback} and ref $args{postback};
  
  $self->{TrawlerOpts} = \%args;
  
  croak "No Server specified in new()"
    unless $self->{TrawlerOpts}->{server};

  ## This should get replaced later:  
  $self->{ReportObj} = IRC::Indexer::Report::Server->new();
  
  return $self
}

sub spawn {
  ## POE-compat constructor
  my ($pkg, %opts) = @_;
  croak "cannot use spawn() interface without a postback"
    unless $opts{postback};
  my $self = $pkg->new(%opts);
  $self->run();
  return $self->{sessid}
}

sub run {
  my ($self) = @_;
  ## Create POE session to manage forked Bot::Trawl
  
  my $sess = POE::Session->create(
    object_states => [
      $self => [ qw/
        _start
        _stop
        shutdown
        
        sess_sig_int
        
        tr_sig_chld
        
        tr_input
        tr_error
        tr_stderr
      / ],
    ],
  );

  $self->{sessid} = $sess->ID;
  return $self 
}

sub trawler_for { return $_[0]->{TrawlerOpts}->{server} }

sub ID { return $_[0]->{sessid} }

sub done {
  my ($self, $finished) = @_;
  
  if ($finished) {
    $self->report->status('DONE');
    $self->report->finishedat(time);

    if (my $postback = delete $self->{POST}) {
      ## Send ourself in a postback.
      $postback->($self);
    }

  }
  
  return unless ref $self->report;
  return unless defined $self->report->status
    and $self->report->status ~~ [qw/DONE FAIL/];
  return $self->report->status
}

sub failed {
  my ($self, $reason) = @_;
  
  if ($reason) {
    unless (ref $self->report) {
      $self->report( IRC::Indexer::Report::Server->new() );
      $self->report->connectedto( $self->trawler_for );
    }
    $self->report->status('FAIL');
    $self->report->failed($reason);
    $self->report->finishedat(time);
    
    if (my $postback = delete $self->{POST}) {
      $postback->($self);
    }
    
  } else {
    return unless ref $self->report;
    return unless $self->report->status eq 'FAIL';
  }
  
  return $self->report->failed
}

sub dump {
  my ($self) = @_;

  return unless ref $self->report;
  return unless $self->report->status ~~  [ qw/DONE FAIL/ ];
  return $self->report->netinfo
}

sub report { info(@_) }
sub info {
  my ($self, $reportobj) = @_;
  $self->{ReportObj} = $reportobj if ref $reportobj;
  return $self->{ReportObj}
}


## POE:
sub _stop {
  $_[OBJECT]->kill_all; 
}

sub sess_sig_int {
  $_[OBJECT]->kill_all;
}

sub shutdown {
  $_[OBJECT]->kill_all;
}

sub kill_all {
  my ($self) = @_;
  for my $pidof (keys %{ $self->{wheels}->{by_pid} }) {
    my $wheel = delete $self->{wheels}->{by_pid}->{$pidof};
    if (ref $wheel) {
      $wheel->kill(9);
    }
  }
  delete $self->{wheels};

  $self->failed("Terminated early") unless $self->done;
}

sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  
  $kernel->sig('INT', 'sess_sig_int');
  $kernel->sig('TERM', 'sess_sig_int');
  
  $self->{sessid} = $_[SESSION]->ID();
  
  my $perlpath = $Config{perlpath};
  if ($^O ne 'VMS') {
    $perlpath .= $Config{_exe}
      unless $perlpath =~ m/$Config{_exe}$/i;
  }
  
  my $forkable;
  if ($^O eq 'MSWin32') {
    $forkable = \&IRC::Indexer::Process::Trawler::worker;
  } else {
    $forkable = [
      $perlpath,  (map { "-I$_" } @INC),
      '-MIRC::Indexer::Process::Trawler', '-e',
      'IRC::Indexer::Process::Trawler->worker()'
    ];
  }
  
  my $wheel = POE::Wheel::Run->new(
    Program => $forkable,
    ErrorEvent  => 'tr_error',
    StdoutEvent => 'tr_input',
    StderrEvent => 'tr_stderr',
    CloseEvent  => 'tr_closed',
    StdioFilter => POE::Filter::Reference->new(),
  );
  
  my $wheelid = $wheel->ID;
  my $pidof   = $wheel->PID;
  
  $kernel->sig_child($pidof, 'tr_sig_chld');

  $self->{wheels}->{by_pid}->{$pidof}   = $wheel;
  $self->{wheels}->{by_wid}->{$wheelid} = $wheel;

  ## Feed this worker the trawler conf.
  my $trawlercf = $self->{TrawlerOpts};
  my $item = [ $self->trawler_for, $trawlercf ];
  $wheel->put($item);
}

sub tr_input {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my $input = $_[ARG0];

  ## Received report->clone()'d hash

  my ($server, $info_h) = @$input;
  unless (ref $info_h eq 'HASH') {
    croak "tr_input received invalid input from worker";
  }

  ## Re-create Report::Server obj
  my $report = IRC::Indexer::Report::Server->new(
    FromHash => $info_h,
  );
  
  $self->{ReportObj} = $report;
  ## We're finished.
  $self->done(1);
  $self->failed( $info_h->{Failure} ) if $info_h->{Failure};
  delete $self->{wheels};
}

sub tr_error {
  ## these should sigchld and go away
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my ($op, $num, $str, $wid) = @_[ARG0 .. $#_];
  my $wheel = $self->{wheels}->{by_wid}->{$wid};
  my $pidof = $wheel->PID if ref $wheel;
  warn "worker err, probably harmless: $self->trawler_for $wid err: $op"
    ." $num $str\n";
}

sub tr_stderr {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my ($err, $id) = @_[ARG0, ARG1];
  ## Report failed() and clean up
  warn "Worker err: $err";
  $self->failed("Worker: SIGCHLD")
    unless $self->done or $self->failed;
}

sub tr_sig_chld {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  ## Worker's gone
  
  my $pidof = $_[ARG1];

  my $wheel = delete $self->{wheels}->{by_pid}->{$pidof};
  return unless ref $wheel;
  
  my $wheelid = $wheel->ID;
  delete $self->{wheels}->{by_wid}->{$wheelid};

  $self->failed("Worker: SIGCHLD")
    unless $self->done or $self->failed;
}

sub tr_closed {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my $wheelid = $_[ARG0];
  my $wheel = delete $self->{wheels}->{by_wid}->{$wheelid};
  if (ref $wheel) {
    $self->failed("Worker closed output")
      unless $self->done or $self->failed;
    my $pidof = $wheel->PID;
    delete $self->{wheels}->{by_pid}->{$pidof};
    $wheel->kill(9);
  }
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Trawl::Forking - Forking Trawl::Bot instances

=head1 SYNOPSIS

See L<IRC::Indexer::Trawl::Bot> for usage details.

This carries exactly the same interface, but a trawler is forked off.

=head1 DESCRIPTION

Uses L<POE::Wheel::Run> to manage forked trawlers running under their 
own Perl interpreter.

Carries exactly the same interface as L<IRC::Indexer::Trawl::Bot> and 
can be used interchangably.

This is useful when pulling very large trawl runs; it can take advantage 
of more CPU cores when composing Reports and tends to reduce the 
long-term memory footprint of a controller when trawling multiple large networks 
(at the cost of extra overhead when forking).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
