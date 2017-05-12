package Global::Context::StackFrame;
{
  $Global::Context::StackFrame::VERSION = '0.003';
}
use Moose::Role;
# ABSTRACT: one frame in a stack


use namespace::autoclean;

requires 'as_string';

has ephemeral => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
  reader  => 'is_ephemeral',
);

1;

__END__

=pod

=head1 NAME

Global::Context::StackFrame - one frame in a stack

=head1 VERSION

version 0.003

=head1 OVERVIEW

Global::Context::StackFrame is a role.

Stack frames are only required to provide an C<as_string> method.  The
StackFrame role also provides a boolean C<ephemeral> attribute indicating
whether a frame is ephemeral.

Most frames are I<not> ephemeral, but those that are will be replaced when a
new frame is pushed, rather than being shifted down.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
