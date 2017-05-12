package FCGI::Engine::Manager::Server::Plackup;
use Moose;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

extends 'FCGI::Engine::Manager::Server';

has 'server_type' => (
    is       => 'ro',
    isa      => 'Str',
    default  => sub { 'FCGI::Engine' }
);

has 'workers' => (
    is       => 'ro',
    isa      => 'Int'
);

sub construct_command_line {
    my $self = shift;
    return ("plackup",
         $self->scriptname,
         "--server",
         $self->server_type,
         ( $self->workers ? ( "--workers", $self->workers ) : ( "--nproc", $self->nproc ) ),
         "--pid",
         $self->pidfile,
         "--listen",
         $self->socket,
         "--daemonize",
         ($self->has_additional_args
             ? $self->additional_args
             : ()));
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

FCGI::Engine::Manager::Server::Plackup - A subclass of FCGI::Engine::Manager::Server for Plack apps

=head1 DESCRIPTION

This uses the C<plackup> utility that comes with L<Plack> to manage a L<Plack> FCGI application.
See L<FCGI::Engine::Manager> for details on how to configure things.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
