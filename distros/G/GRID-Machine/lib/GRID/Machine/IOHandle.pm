package GRID::Machine::IOHandle;
use strict;

## Class methods

use overload '<>' => \&diamond;

# diamond works only in scalar context
sub diamond {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->diamond($self->{index}, @_);
  die $r unless $r->ok;
  return $r->result;
};

sub print {
  my $self = shift;
  my $m = $self->{server};

  $m->print($self->{index}, @_);

}

sub printf {
  my $self = shift;
  my $m = $self->{server};

  $m->printf($self->{index}, @_);

}

sub flush {
  my $self = shift;
  my $m = $self->{server};

  $m->flush($self->{index}, @_)->result;
}

sub autoflush {
  my $self = shift;
  my $m = $self->{server};

  $m->autoflush($self->{index}, @_)->result;
}

sub blocking {
  my $self = shift;
  my $m = $self->{server};

  $m->blocking($self->{index}, @_)->result;
}

sub close {
  my $self = shift;
  my $m = $self->{server};

  $m->close($self->{index}, @_)->result;
}

sub getc {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->getc($self->{index}, @_);
  die $r unless $r->ok;
  return $r->result;
}

sub getline {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->getline($self->{index}, @_);
  die $r unless $r->ok;
  return $r->result;
}

sub getlines {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->getlines($self->{index}, @_);
  die $r unless $r->ok;
  return $r->Results;
}

sub read {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->read($self->{index}, @_);
  die $r unless $r->ok;
  return $r->result;
}

sub sysread {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->sysread($self->{index}, @_);
  die $r unless $r->ok;
  return $r->result;
}

sub stat {
  my $self = shift;
  my $m = $self->{server};

  my $r = $m->stat($self->{index}, @_);
  die $r unless $r->ok;
  return $r->Results;
}

1;

__END__

