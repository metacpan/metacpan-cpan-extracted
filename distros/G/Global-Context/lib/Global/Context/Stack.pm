package Global::Context::Stack;
{
  $Global::Context::Stack::VERSION = '0.003';
}
use Moose::Role;
# ABSTRACT: the stack of a Global::Context::Env object


with 'MooseX::Clone';

use Moose::Util::TypeConstraints;

use namespace::autoclean;

role_type('Global::Context::StackFrame');

has frames => (
  isa    => 'ArrayRef[ Global::Context::StackFrame ]',
  reader => '_frames',
  traits => [ 'Array' ],
  default => sub { [] },
  handles => {
    frames        => 'elements',
    current_frame => [ get => -1 ],
  },
);

sub with_pushed_frame {
  my ($self, $frame) = @_;

  my @frames = $self->frames;
  pop @frames if @frames and $frames[0]->is_ephemeral;

  $self->clone(frames => [ @frames, $frame ]);
}

1;

__END__

=pod

=head1 NAME

Global::Context::Stack - the stack of a Global::Context::Env object

=head1 VERSION

version 0.003

=head1 OVERVIEW

Global::Context::Stack is a role.

Stack objects provide information about the execution path that has led to the
current execution point in a program.  It has only one important attribute,
C<frames>, which is an arrayref of L<Global::Context::StackFrame> objects.

It provides one critical method, L<with_pushed_frame>, which returns a clone of
the stack with one addition frame added.  (If the top frame of the stack was
"ephemeral," it is replaced instead of pushed down.)

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
