=head1 NAME

IPC::DirQueue::IndexServer - an IPC::DirQueue index server

=head1 DESCRIPTION

See dq-indexd.

=cut

package IPC::DirQueue::IndexServer;
use strict;
use bytes;

use POE;
use POE::Filter::Line;
use POE::Component::Server::TCP;

###########################################################################

my @enqueued = ();

###########################################################################

sub new {
  my $class = shift;
  my $opts = shift;
  $class = ref($class) || $class;

  my $self = $opts;

  bless ($self, $class);
  $self;
}

sub run {
  my ($self) = @_;

  die "no port" unless $self->{port};

  POE::Component::Server::TCP->new (
        Port => $self->{port},
        ClientInput => \&client_input,
      );

  POE::Kernel->run();
}

sub client_input {
  my ($heap, $input) = @_[ HEAP, ARG0 ];
 
  if ($input !~ /^(\S+) *(.*?)$/) {
    req_err($heap, $input, "500 no command");
    return;
  }

  my $cmd = $1;
  my $args = $2;
  if ($cmd eq 'ENQ') {
    do_ENQ($heap, $args);
  }
  elsif ($cmd eq 'DEQ') {
    do_DEQ($heap, $args);
  }
  elsif ($cmd eq 'LS') {
    do_LS($heap, $args);
  }
  else {
    req_err($heap, $input, "500 syntax error");
    return;
  }
}

sub req_err {
  my ($heap, $input, $errcode) = @_;
  warn "failed to parse '$input': $errcode\n";
  $heap->{client}->put($errcode);
}

sub do_ENQ {
  my ($heap, $args) = @_;
  push (@enqueued, $args);
  $heap->{client}->put("200 enqueued $args");
}

sub do_DEQ {
  my ($heap, $args) = @_;
  chomp $args;
  @enqueued = grep { $_ ne $args } @enqueued;
  $heap->{client}->put("200 dequeued $args");
}

sub do_LS {
  my ($heap, $args) = @_;
  my $len = length($args);

  # compose a string buffer of our own; calling the
  # POE ->put() method is a write() syscall every time.
  my $buf = "201-starting ls\r\n";
  foreach my $item (@enqueued) {
    next if (substr($item, 0, $len) ne $args);
    $buf .= "202-$item\r\n";
  }
  $heap->{client}->put($buf."200 end of ls");
}

1;
