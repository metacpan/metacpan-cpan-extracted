package GRID::Machine::Group;
use warnings;
use strict;
use List::Util qw(first);
use Scalar::Util qw(reftype);
use IO::Select;
use base qw{Exporter};

our @EXPORT_OK = qw{void};

sub new {
  my $class = shift;
  my %args = @_;

  my @machines = @{$args{cluster}};
  @machines = map { ref($_)? $_ : GRID::Machine->new(host => $_, survive => 1) } @machines;

  
  my $s = IO::Select->new();
  my %rpipe2gm = map { (0+$_->readpipe,  $_) } @machines;
  my %wpipe2gm = map { (0+$_->writepipe, $_) } @machines;
  for (@machines) {
    $s->add($_->readpipe);
    $s->add($_->writepipe);
  }

  my $self = {
     machines => [ @machines ],
     select   => $s,
 
     rpipe    => \%rpipe2gm,
     wpipe    => \%wpipe2gm, # keys: write pipe addresses. Values: GRID machines
  };
 
  my $clusterclass = "$class"."::".(0+$self);

  bless $self, $clusterclass;

  my $misa;
  {
    no strict 'refs';
    $misa = \@{"${clusterclass}::ISA"};
  }

      unshift @{$misa}, 'GRID::Machine::Group'
  unless first { $_ eq 'GRID::Machine::Group' } @{$misa};

  $self;
}

sub call {
  calloreval('GRID::Machine::CALL', @_);
}

sub eval {
  calloreval('GRID::Machine::EVAL', @_);
}

sub calloreval {
  my $protocol = shift;
  my $self = shift;
  my $name = shift;
  my %ARG  = @_;

  my $arg = $ARG{args};

  my ($next, $thereareargs, $reset);

  unless (@{$self->{machines}}) {
    warn "Warning! Attempt to execute '$name' in an empty cluster!";
    return;
  }

  # replicate is ignored if 'arg' is defined
  unless (defined($arg)) {
    my $rep = $ARG{replicate};
    my $rt = reftype($rep);
    die "GRID::Machine::Group::call error. Unexpected arguments" unless $rt;
    if ($rt eq 'ARRAY') {
      push @$arg, $rep for @{$self->{machines}};
    }
    elsif ($rt eq 'CODE') {
      for ( @{$self->{machines}}) {
        my $r = $rep->($_);
        $r = [ $r ] unless reftype($r) and (reftype($r) eq 'ARRAY');
        push @$arg, $r;
      }
    }
    else {
      die "GRID::Machine::Group::call error. Unexpected arguments";
    }
  }

  my $rt = reftype($arg);
  if ($rt) {
    if ($rt eq 'ARRAY') {
      my @args = @$arg;
      $next = sub { shift @args }; 
      $thereareargs = sub { @args ? 1 : 0 };
      $reset = sub {};
    }
    elsif ($rt eq 'HASH') {
      $next         = $arg->{next};
      $thereareargs = $arg->{thereareargs};
      $reset    = $arg->{reset};
    }
    else { 
      die "GRID::Machine::Group::call error. Unexpected arguments";
    }
  }
  else { # not a ref
    die "GRID::Machine::Group::call error. Unexpected arguments";
  }

  my %t;
  my $task = 0;
  $reset->();
  for (@{$self->{machines}}) {
    my ($args)  = $next->(); # shift @_;
    $args = [ $args] unless (ref($args) and (reftype($args) eq 'ARRAY'));

    $_->send_operation( $protocol, $name, $args );
    $t{0+$_} = $task++;

    last unless $thereareargs->(); # @_; # Number of jobs is less than the number of machines
  }

  my $readset = $self->{select};

  my @ready;
  my @result;
  my $finished = 0;
  do {
    push @ready, $readset->can_read unless @ready;
    my $handle = shift @ready;

    my $me = $self->{rpipe}{0+$handle};

    my $index = $t{0+$me};
    $result[$index] = $me->_get_result(); 
    $finished++;

    if ($thereareargs->()) { 
      my ($args)  = $next->(\@result, $index);
      $args = [ $args] unless (ref($args) and (reftype($args) eq 'ARRAY'));

      $t{0+$me} = $task++;
      $me->send_operation( $protocol, $name, $args );
    }
    #print "Tasks left = '@_' Task = $task, finished = $finished\n";
    
  } while ($thereareargs->() or ($finished < $task));
  $reset->();

  return bless \@result, 'GRID::Machine::Group::Result';
}

sub sub {
  my $self = shift;

  warn "Warning!: Attempt to install sub '$_[0]' in an empty cluster" unless @{$self->{machines}};
  my @r;
  push @r, $_->sub(@_) for @{$self->{machines}};

  #install the par method proxy
  my $name = shift;
  my $sub = sub { my $self = shift; $self->call( $name, @_ ) };
   
  my $class = ref($self);
  no strict 'refs'; 
  *{$class."::".$name} = $sub;

  return @r;
}

sub makemethod {
  my $self = shift;

  warn "Warning!: Attempt to install makemethod '$_[0]' in an empty cluster" unless @{$self->{machines}};
  my @r;
  push @r, $_->makemethod(@_) for @{$self->{machines}};

  #install the par method proxy
  my $name = shift;
  my $sub = sub { my $self = shift; $self->call( $name, @_ ) };
   
  my $class = ref($self);
  no strict 'refs'; 
  *{$class."::".$name} = $sub;

  return @r;
}

sub void { return (replicate => []) }

package GRID::Machine::Group::Result;

sub Results {
  my $self = shift;

  return map { $_->result } @$self;
}

1;
