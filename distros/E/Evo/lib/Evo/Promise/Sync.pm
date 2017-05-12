package Evo::Promise::Sync;
use Evo '-Class *';

has 'promise', ro;
has $_, optional for qw(called v blocking should_resolve);

sub reject ($self, $r) {
  return if $self->called;
  $self->called(1);
  $self->blocking ? $self->promise->d_reject($r) : $self->promise->d_reject_continue($r);
  $self;
}

sub resolve ($self, $v) {
  return if $self->called;
  $self->called(1);
  $self->blocking ? $self->should_resolve(1)->v($v) : $self->promise->d_resolve_continue($v);
  $self;
}

sub try_thenable ($self, $thenable) {
  $self->blocking(1);

  # reject drain second time, so don't bother checking "called"
  my ($res, $rej) = (sub { $self->resolve(@_) }, sub { $self->reject(@_) });
  eval { $thenable->then($res, $rej); 1; } or $self->reject($@);
  $self->blocking(0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Promise::Sync

=head1 VERSION

version 0.0403

=head2 SYNOPSIS
This class exists for internal purposes only to make C<d_resolve> a little bit
simpler. Probably, you're looking for C<::Deferred>

False value of C<blocking> means we're in the async level should call *_continue
to start traverse. True value means we're already in the current C<d_resolve> loop

=head2 try_thenable

You should check C<should_resolve> after invocation and ONLY if it's true,
continue the loop in C<d_resolve>, or break it otherwise.

Because true value means blocking C<resolve> was called with C<v> and we need extra loop,
because C<blocking> resolve dosn't call C<d_resolve> (but blocking C<reject> calls C<d_reject>)

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
