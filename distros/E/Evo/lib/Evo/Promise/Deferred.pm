package Evo::Promise::Deferred;
use Evo '-Class *';

has 'promise', ro;
has 'called',  optional;

sub reject ($self, $r = undef) {
  return if $self->called;
  $self->called(1)->promise->d_reject_continue($r);
}

sub resolve ($self, $v = undef) {
  return if $self->called;
  $self->called(1)->promise->d_resolve_continue($v);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Promise::Deferred

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
