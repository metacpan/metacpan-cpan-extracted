use strict;
package Event::process;
use Carp;
use Event qw(time);
use base 'Event::Watcher';
use vars qw($DefaultPriority);
$DefaultPriority = Event::PRIO_HIGH();

'Event::Watcher'->register();

sub new {
    #lock %Event::;

    shift if @_ & 1;
    my %arg = @_;
    my $o = 'Event::process'->allocate();
    $o->init([qw(pid timeout)], \%arg);
    $o->{any} = 1 if !exists $o->{pid};
    $o->start();
    $o;
}

my %cb;		# pid => [events]

Event->signal(signal => 'CHLD',  #CLD? XXX
	      callback => sub {
		  my ($o) = @_;
		  for (my $x=0; $x < $o->{count}; $x++) {
		      my $pid = wait;
		      last if $pid == -1;
		      my $status = $?;
		      
		      my $cbq = delete $cb{$pid} if exists $cb{$pid};
		      $cbq ||= $cb{any} if exists $cb{any};
		      
		      next if !$cbq;
		      for my $e (@$cbq) {
			  $e->{pid} = $pid;
			  $e->{status} = $status;
			  Event::queue($e);
		      }
		  }
	      },
	      desc => "Event::process SIGCHLD handler");

sub _start {
    my ($o, $repeat) = @_;
    my $key = exists $o->{any}? 'any' : $o->{pid};
    push @{$cb{ $key } ||= []}, $o;
    if (exists $o->{timeout}) {
	croak "Timeout for all child processes?" if $o->{any};
	$o->{at} = time + $o->{timeout};
    }
}

sub _stop {
    my $o = shift;
    my $key = exists $o->{any}? 'any' : $o->{pid};
    $cb{ $key } = [grep { $_->{id} != $o->{id} } @{$cb{ $key }} ];
    delete $cb{ $key } if
	@{ $cb{ $key }} == 0;
}

sub _alarm {
    my $o = shift;
    delete $o->{status};
    Event::queue($o);
}

sub _postCB {
    my $o = shift;
    if (exists $o->{timeout}) {
	delete $o->{timeout};
	$o->again;
    }
}

1;
