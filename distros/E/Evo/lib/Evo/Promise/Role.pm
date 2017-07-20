package Evo::Promise::Role;
use Evo -Class;
use Evo '-Promise::Sync; -Lib try; -Promise::Const *; -Promise::Deferred';
use Evo 'Carp croak; Scalar::Util blessed';

requires 'postpone';

# https://promisesaplus.com/

has $_, optional for qw(d_v d_locked d_fh d_rh d_settled);
has 'd_children' => ro, sub { [] };
has 'state' => PENDING;

#sub assert { shift or croak join '; ', caller() }

#sub value($self) {
#  croak "$self isn't fulfilled" unless $self->state eq FULFILLED;
#  $self->d_v;
#}
#
#sub reason($self) {
#  croak "$self isn't rejected" unless $self->state eq REJECTED;
#  $self->d_v;
#}

## CLASS METHODS
sub promise ($me, $fn) {
  my $d = Evo::Promise::Deferred->new(promise => my $p = $me->new());
  try {
    $fn->(sub { $d->resolve(@_) }, sub { $d->reject(@_) });
  }
  sub($e) {
    $d->reject(@_);
  };
  $p;
}

sub deferred($me) { Evo::Promise::Deferred->new(promise => $me->new()); }

sub resolve ($me, $v) {
  my $d = Evo::Promise::Deferred->new(promise => $me->new());
  $d->resolve($v);
  $d->promise;
}

sub reject ($me, $v) {
  my $d = Evo::Promise::Deferred->new(promise => $me->new());
  $d->reject($v);
  $d->promise;
}

sub race ($me, @prms) {
  my $d = Evo::Promise::Deferred->new(promise => $me->new());
  my $onF = sub { $d->resolve(@_) };
  my $onR = sub { $d->reject(@_) };
  foreach my $cur (@prms) {
    if (ref $cur eq 'Evo::Promise::Class') {
      $cur->then($onF, $onR);
    }
    else {
      # wrap with our promise
      my $wd = Evo::Promise::Deferred->new(promise => $me->new());
      $wd->promise->then($onF, $onR);
      $wd->resolve($cur);
    }
  }

  $d->promise;
}


sub all ($me, @prms) {
  my $d = Evo::Promise::Deferred->new(promise => $me->new());
  do { $d->resolve([]); return $d->promise; } unless @prms;

  my $pending = @prms;

  my @result;
  my $onR = sub { $d->reject($_[0]) };

  for (my $i = 0; $i < @prms; $i++) {
    my $cur_i = $i;
    my $cur_p = $prms[$cur_i];
    my $onF   = sub { $result[$cur_i] = $_[0]; $d->resolve(\@result) if --$pending == 0; };

    if (ref $cur_p eq 'Evo::Promise::Class') {
      $cur_p->then($onF, $onR);
    }
    else {
      # wrap with our promise
      my $wd = Evo::Promise::Deferred->new(promise => $me->new());
      $wd->promise->then($onF, $onR);
      $wd->resolve($cur_p);
    }
  }
  $d->promise;
}

### OBJECT METHODS

sub finally ($self, $fn) {
  my $d   = Evo::Promise::Deferred->new(promise => ref($self)->new);
  my $me  = ref($self);
  my $onF = sub($v) {
    $d->resolve($fn->());    # need pass result because it can be a promise
    $d->promise->then(sub {$v});
  };
  my $onR = sub($r) {
    $d->resolve($fn->());    # see above
    $d->promise->then(sub { $me->reject($r) });
  };
  $self->then($onF, $onR);
}

sub catch ($self, $cfn) {
  $self->then(undef, $cfn);
}

sub spread ($self, $fn) {
  $self->then(sub($ref) { $fn->($ref->@*) });
}


sub then {
  my ($self, $fh, $rh) = @_;
  my $p = ref($self)->new(ref($fh) ? (d_fh => $fh) : (), ref($rh) ? (d_rh => $rh) : ());
  push $self->d_children->@*, $p;
  $self->d_traverse if $self->d_settled;
  $p;
}

### DRIVER INTERNAL METHODS

sub d_lock_in ($self, $parent) {

  #assert(!$self->d_locked);
  #assert(!$self->d_settled);
  unshift $parent->d_children->@*, $self->d_locked(1);
}

sub d_fulfill ($self, $v) {

  #assert(!$self->d_settled);
  $self->d_settled(1)->state(FULFILLED)->d_v($v);
}

sub d_reject ($self, $r) {

  #assert(!$_[0]->d_settled);
  $self->d_settled(1)->state(REJECTED)->d_v($r);
}

# 2.3 The Promise Resolution Procedure
# 2.3.3.2, 2.3.3.4 doesn't make sense in perl (in real world)
# Changed term obj or func to blessed obj and can "then"
sub d_resolve ($self, $x) {

  #assert(!$self->d_settled);

  while (1) {

    # 2.3.4 but means not a blessed object
    return $self->d_fulfill($x) unless blessed($x);


    # 2.3.1
    return $self->d_reject('TypeError') if $x && $self eq $x;

    # 2.3.2 promise
    if (ref $x eq ref $self) {
      $x->d_settled
        ? $x->state eq FULFILLED
          ? $self->d_fulfill($x->d_v)
          : $self->d_reject($x->d_v)
        : $self->d_lock_in($x);
      return;
    }

    if ($x->can('then')) {
      my $sync = Evo::Promise::Sync->new(promise => $self)->try_thenable($x);
      return unless $sync->should_resolve;
      $x = $sync->v;    # and next, but it's already last in loop
      next;
    }

    # 2.3.3.4
    return $self->d_fulfill($x);
  }
}

# reject promise and call traverse with the stack of children
sub d_reject_continue ($self, $reason) {
  $self->d_reject($reason);
  $self->d_traverse;
}

sub d_resolve_continue ($self, $v) {
  $self->d_resolve($v);
  return unless $self->d_settled;
  $self->d_traverse;
}

# breadth-first
sub d_traverse($self) {

  my @stack = ($self);
  while (@stack) {

    my $parent = shift @stack;

    #assert($parent->d_settled);
    my @children = $parent->d_children->@* or next;
    $parent->{d_children} = [];

    # 2.2.2 - 2.2.7
    my ($pstate, $v) = ($parent->state, $parent->d_v);
    foreach my $cur (@children) {
      my $h = $pstate eq FULFILLED ? $cur->d_fh : $cur->d_rh;
      $cur->d_fh(undef)->d_rh(undef);

      if ($h) {
        my $sub = sub {
          my $x;
          eval { $x = $h->($v); 1 } ? $cur->d_resolve_continue($x) : $cur->d_reject_continue($@);
        };
        $self->postpone($sub);    # 2.2.4, call async
        next;
      }

      $pstate eq FULFILLED ? $cur->d_fulfill($v) : $cur->d_reject($v);
      push @stack, $cur;
    }

  }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Promise::Role

=head1 VERSION

version 0.0405

=head1 IMPLEMENTATION

This is a sexy and fast non-recursive implementation of Promises/A+

See L<Evo::Promise::Mojo> or L<Evo::Promise::AE> for end-user library

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
