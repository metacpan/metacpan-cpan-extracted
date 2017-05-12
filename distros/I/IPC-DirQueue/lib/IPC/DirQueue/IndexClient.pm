=head1 NAME

IPC::DirQueue::IndexClient - client for the indexd protocol

=head1 DESCRIPTION

indexd client.

=cut

package IPC::DirQueue::IndexClient;
use strict;
use bytes;

use IO::Socket::INET;

our @ISA = ();

our $DEBUG; # = 1;

###########################################################################

sub new {
  my $class = shift;
  my $opts = shift;
  $class = ref($class) || $class;

  my $self = $opts;
  $self ||= { };

  if ($self->{uri} =~ m,^dq://(\S+?)(\:\d+?)?$,) {
    $self->{host} = $1;

    my $p = $2 || '23458';
    $p =~ s/^://;
    $self->{port} = $p;
  }
  else {
    die "unparseable URI: $self->{uri}";
  }

  bless ($self, $class);
  $self;
}

sub dbg {
  $DEBUG and warn "debug: ".join('', @_);
}

###########################################################################

sub enqueue {
  my ($self, $qdir, $qfile) = @_;
  my $qid = $self->_get_dir_id($qdir);
  $qfile =~ s,^.*queue/,,;
  $self->sock_send("ENQ q=$qid|f=$qfile\r\n");
}

sub sock_send {
  my ($self, $str) = @_;

  if (!$self->_connect()) {
    die "connect to indexd failed";
  }

  $DEBUG and dbg "--> ".$str;
  if (!$self->{socket}->print($str)) {
    die "print to indexd failed";
  }

  my $rstr = $self->{socket}->getline();
  $DEBUG and dbg "<-- ".$rstr;

  if ($rstr =~ /(2\d\d) /) {
    return $1;
  }
  elsif ($rstr =~ /(2\d\d)-/) {
    return -($1);
  }
  else {
    warn "indexd replied with error: $rstr";
    return;
  }
}

sub dequeue {
  my ($self, $qdir, $qfile) = @_;
  my $qid = $self->_get_dir_id($qdir);
  $qfile =~ s,^.*queue/,,;
  $self->sock_send("DEQ q=$qid|f=$qfile\r\n");
}

sub ls {
  my ($self, $qdir) = @_;
  my $qid = $self->_get_dir_id($qdir);

  my $resp = $self->sock_send("LS q=$qid|\r\n");
  if ($resp != -201) {
    die "need 201- response for LS";
  }
  
  my @list = ();
  while (1) {
    my $str = $self->{socket}->getline();
    $DEBUG and dbg "<-- ".$str;
    if ($str =~ /^202-(\S+)/) {

      my $withqid = $1;
      $withqid =~ s,^q=\Q$qid\E\|f=,, or warn "$withqid sub failed";
      push (@list, $withqid);
    }
    elsif ($str =~ /^200 /) {
      last;
    }
    else {
      die "bad response from indexd on ls: $str";
    }
  }

  return @list;
}

###########################################################################

sub _get_dir_id {
  my ($self, $qdir) = @_;

  # chop off the "queue" part
  # t/log/qdir/queue -> t/log/qdir
  $qdir =~ s,([^/]+)/+queue/*$,$1,;

  # the ID string is: "dirname/inode"
  # where dirname is the final part of the path, inode is the inode
  # number of that dir.

  my @s = stat $qdir;
  if (!@s) {
    die "stat $qdir failed";
  }

  return "$1/$s[1]";
}

sub _connect {
  my ($self) = @_;

  return 1 if ($self->{socket});

  my $sock = IO::Socket::INET->new (
            PeerAddr => $self->{host},
            PeerPort => $self->{port},
            Proto => "tcp",
        );

  if (!$sock) {
    warn "connect failed to '$self->{host}':$self->{port}: $!";
    return;
  }

  $self->{socket} = $sock;
  return 1;
}

1;
