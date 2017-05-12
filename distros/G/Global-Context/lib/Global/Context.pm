use strict;
use warnings;
package Global::Context;
{
  $Global::Context::VERSION = '0.003';
}
# ABSTRACT: track the global execution context of your code

use Carp ();
use Global::Context::Env::Basic;
use Global::Context::StackFrame::Basic;
use Sub::Exporter::GlobExporter ();


use Sub::Exporter -setup => {
  exports    => [
    ctx_init => \'_build_ctx_init',
    ctx_push => \'_build_ctx_push',
  ],
  collectors => {
    '$Context' => Sub::Exporter::GlobExporter::glob_exporter(
      Context => \'common_globref',
    )
  },
};


sub common_globref { \*Object }


sub default_context_class { 'Global::Context::Env::Basic' }
sub default_frame_class   { 'Global::Context::StackFrame::Basic' }

sub _build_ctx_init {
  my ($class, $name, $arg, $col) = @_;

  Carp::croak("can't import $name without importing \$Context")
    unless $col->{'$Context'};

  return sub {
    my ($arg) = @_;

    my $ref = *{ $col->{'$Context'} }{SCALAR};
    Carp::confess("context has already been initialized") if $$ref;

    $$ref = $class->default_context_class->new($arg)->with_pushed_frame(
      $class->default_frame_class->new({
        description => Carp::shortmess("context initialized"),
        ephemeral   => 1,
      }),
    );

    return $$ref;
  };
}

sub _build_ctx_push {
  my ($class, $name, $arg, $col) = @_;

  Carp::croak("can't import $name without importing \$Context")
    unless $col->{'$Context'};

  return sub {
    my ($frame) = @_;

    Carp::croak("Can't push frame onto uninitialized context")
        unless defined ${ *{ $col->{'$Context'} }{SCALAR} };

    $frame = { description => $frame } unless ref $frame;

    $frame = $class->default_frame_class->new($frame)
      unless Scalar::Util::blessed($frame);

    return ${ *{ $col->{'$Context'} }{SCALAR} }->with_pushed_frame($frame);
  }
}

1;

__END__

=pod

=head1 NAME

Global::Context - track the global execution context of your code

=head1 VERSION

version 0.003

=head1 OVERVIEW

B<WARNING!>  This code is B<very> young and experimental.  Its interface may
change drastically as it is proven.

Global::Context is a system for tracking the context under which a program is
currently running.  It establishes a globally-accessible object that tracks the 
current user, authentication information, request originator, and execution
stack.

This object can be replaced locally (within dynamic scopes) to affect pushes
and pops against is stack, but is otherwise meant to be immutable once created.

  use Global::Context -all, '$Context';

  ctx_init({
    terminal => Global::Context::Terminal::Basic->new({ uri => 'ip://1.2.3.4' }),
    auth_token => Global::Context::AuthToken::Basic->new({
      uri   => 'websession://1234',
      agent => 'customer://abcdef',
    }),
  });

  sub eat_pie {
    my ($self) = @_;

    local $Context = ctx_push("eating pie");
    
    ...;
  }

  eat_pie;

=head2 Exports

If C<$Context> is requested as an import, a package variable is added, aliasing
a shared global.  It can be localized as needed, affecting the global value.
This feature is provided by L<Sub::Exporter::GlobExporter>.

The shared globref is provided by the C<common_globref> method, which can
return a different globref in other subclasses to allow multiple global
contexts to exist in one interpreter.

The C<ctx_init> and C<ctx_push> routines are exported by request or as part of
the C<-all> group.

C<ctx_init> takes the same arguments as the constructor for the default context
class (by default L<Global::Context::Env::Basic>) and sets up the initial
environment.  If C<ctx_init> is called after the environment has already been
configured, it is fatal.

C<ctx_push> takes either a stack frame (something that does
L<Global::Context::StackFrame>), the arguments to a construct a new
Global::Context::StackFrame::Basic, or a stack frame description.  It returns a
new global context object, just like the current but with an extra stack frame.
It's meant to be called like this:

  {
    local $Context = ctx_push("preferences subsystem");

    ...
  }

=head1 METHODS

=head2 common_globref

This returns the globref in which the context object is stored.  This method
can be replaced in subclasses to allow multiple global contexts to operate in
one program.

=head2 default_context_class

=head2 default_frame_class

These methods name the default classes for new context objects and stack
frames.  They default to Global::Context::Env::Basic and
Global::Context::StackFrame::Basic, by default.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
