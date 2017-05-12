package Global::Context::Env;
{
  $Global::Context::Env::VERSION = '0.003';
}
use Moose::Role;
# ABSTRACT: the global execution environment


with 'MooseX::Clone';

use Global::Context::Stack::Basic;

use namespace::autoclean;


has auth_token => (
  is   => 'ro',
  does => 'Global::Context::AuthToken',
  predicate => 'has_auth_token',
);

sub agent {
  return undef unless $_[0]->has_auth_token;
  return $_[0]->auth_token->agent;
}


has terminal => (
  is   => 'ro',
  does => 'Global::Context::Terminal',
  required => 1,
);


has stack => (
  is   => 'ro',
  does => 'Global::Context::Stack',
  required => 1,

  # XXX: This seems wrong; probably there should be no default, and it's up to
  # ctx_init to get this right. -- rjbs, 2010-12-13
  default  => sub { Global::Context::Stack::Basic->new },
);


sub stack_trace {
  my ($self) = @_;
  map $_->as_string, $self->stack->frames;
}

sub with_pushed_frame {
  my ($self, $frame) = @_;

  return $self->clone(
    stack => $self->stack->with_pushed_frame($frame),
  );
}

1;

__END__

=pod

=head1 NAME

Global::Context::Env - the global execution environment

=head1 VERSION

version 0.003

=head1 OVERVIEW

Global::Context::Env is a role.

Global::Context::Env objects are the heart of the L<Global::Context> system.
They're the things that go in the shared C<$Context> variable, and they're the
things that point to the AuthToken, Terminal, and Stack.

=head1 ATTRIBUTES

=head2 auth_token

Every environment either has an auth token that does
L<Global::Context::AuthToken> or it has none.  This attribute cannot be changed
after initialization.

The C<agent> method will return undef if there is no auth token, and will
otherwise get the agent from the token.

=head2 terminal

Every environment has a terminal that does L<Global::Context::Terminal>.
This attribute cannot be changed after initialization.

=head2 stack

Every environment has a stack that does L<Global::Context::Stack>.
This attribute cannot be changed after initialization.

Instead, the C<with_pushed_frame> method is used to create a clone of the
entire environment, save for a new frame pushed onto the stack.

=head1 METHODS

=head2 stack_trace

C<< ->stack_trace >> is a convenience method that returns a list
containing the string representation of each frame in the stack.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
