package Plack::Handler::FCGI::Engine;
use Moose;
use MooseX::NonMoose;

use Plack::Handler::FCGI::Engine::ProcManager;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Plack::Handler::FCGI';

has 'manager' => (
    is      => 'ro',
    isa     => 'Str | ClassName',
    default => sub { 'Plack::Handler::FCGI::Engine::ProcManager' },
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::Handler::FCGI::Engine - A Plack::Handler backend for FCGI::Engine

=head1 SYNOPSIS

  use Plack::Handler::FCGI::Engine;

  my $handler = Plack::Handler::FCGI::Engine->new(
      nproc  => $num_proc,
      listen => $listen,
      detach => 1,
  );

  $handler->run($app);

=head1 DESCRIPTION

This is a subclass of L<Plack::Handler::FCGI> which will use the
L<Plack::Handler::FCGI::Engine::ProcManager> process manager by default,
instead of L<FCGI::ProcManager>.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
