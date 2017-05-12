package FCGI::Engine::Core;
use Moose;

use Class::Load ();
use FCGI;
use MooseX::Daemonize::Pid::File;
use FCGI::Engine::Types;
use FCGI::Engine::ProcManager;

use constant DEBUG => 0;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

with 'MooseX::Getopt',
     'MooseX::Daemonize::Core';

has 'listen' => (
    metaclass   => 'Getopt',
    is          => 'ro',
    isa         => 'FCGI::Engine::Listener',
    coerce      => 1,
    cmd_aliases => 'l',
    predicate   => 'is_listening',
);

has 'nproc' => (
    metaclass   => 'Getopt',
    is          => 'ro',
    isa         => 'Int',
    default     => sub { 1 },
    cmd_aliases => 'n',
);

has 'pidfile' => (
    metaclass   => 'Getopt',
    is          => 'ro',
    isa         => 'MooseX::Daemonize::Pid::File',
    coerce      => 1,
    cmd_aliases => 'p',
    predicate   => 'has_pidfile',
);

has 'detach' => (
    metaclass   => 'Getopt',
    is          => 'ro',
    isa         => 'Bool',
    cmd_flag    => 'daemon',
    cmd_aliases => 'd',
    predicate   => 'should_detach',
);

has 'manager' => (
    metaclass   => 'Getopt',
    is          => 'ro',
    isa         => 'Str',
    default     => sub { 'FCGI::Engine::ProcManager' },
    cmd_aliases => 'M',
);

has 'use_manager' => (
    metaclass => 'Getopt',
    is        => 'ro',
    isa       => 'Bool',
    default   => 0,
);

# options to specify in your script

has 'pre_fork_init' => (
    metaclass => 'NoGetopt',
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_pre_fork_init',
);

## methods ...

sub BUILD {
    my $self = shift;
    ($self->has_pidfile)
        || confess "You must specify a pidfile if you are listening"
            if $self->is_listening;
}

sub initialize {
    my ( $self, %addtional_options ) = @_;

    $self->pre_fork_init->(%addtional_options)
        if $self->has_pre_fork_init;

    inner();
}

sub create_socket {
    my $self   = shift;
    my $socket = 0;
    if ($self->is_listening) {
        my $old_umask = umask;
        umask(0);
        $socket = FCGI::OpenSocket($self->listen, 100);
        umask($old_umask);
    }
    $socket;
}

sub create_environment { +{} }

sub create_request {
    my ( $self, $socket, $env ) = @_;
    return FCGI::Request(
        \*STDIN,
        \*STDOUT,
        \*STDERR,
        $env,
        $socket,
        &FCGI::FAIL_ACCEPT_ON_INTR
    );
}

sub create_proc_manager {
    my ( $self, %addtional_options ) = @_;

    # make sure any subclasses are loaded ...
    Class::Load::load_class( $self->manager );

    return $self->manager->new({
        n_processes => $self->nproc,
        pidfile     => $self->pidfile,
        %addtional_options
    });
}

sub prepare_environment {
    my ($self, $_env) = @_;

    my $env = inner();

    # Cargo-culted from Catalyst::Engine::FastCGI
    # and Plack::Server::FCGI, thanks guys :)
    if ( $env->{SERVER_SOFTWARE} ) {
        if ( $env->{SERVER_SOFTWARE} =~ /lighttpd/ ) {
            $env->{PATH_INFO}   ||= delete $env->{SCRIPT_NAME};
            $env->{SCRIPT_NAME} ||= '';
            $env->{SERVER_NAME} =~ s/:\d+$//; # cut off port number
        }
        elsif ( $env->{SERVER_SOFTWARE} =~ /^nginx/ ) {
            my $script_name = $env->{SCRIPT_NAME};
            $env->{PATH_INFO} =~ s/^$script_name//g;
        }
    }

    $env;
}

sub handle_request { confess __PACKAGE__ . " is abstract, override handle_request" }

sub run {
    my ($self, %addtional_options) = @_;

    $self->initialize( %addtional_options );

    my $socket  = $self->create_socket;
    my $env     = $self->create_environment;
    my $request = $self->create_request( $socket, $env );

    my $proc_manager;

    if ($self->is_listening) {

        $self->daemon_fork && return if $self->detach;

        $proc_manager = $self->create_proc_manager( %addtional_options );

        $self->daemon_detach(
            # Not sure we need this ...
            no_double_fork       => 1,
            # we definetely need this ...
            dont_close_all_files => 1,
        ) if $self->detach;

        $proc_manager->manage;
    }

    # We do not listen but we do want more than one processes being forked and
    # want to take the benefit of running the process manager as well. This
    # makes sense if the FastCGI script is started directly via Apache.
    elsif ( $self->use_manager ) {
        $proc_manager = $self->create_proc_manager( %addtional_options );
        $proc_manager->manage;
    }

    while ($request->Accept() >= 0) {

        $proc_manager && $proc_manager->pre_dispatch;

        $self->handle_request(
            $self->prepare_environment( $env ),
            $request
        );

        $proc_manager && $proc_manager->post_dispatch;
    }
}

1;

__END__

=pod

=head1 NAME

FCGI::Engine::Core - A base class for various FCGI::Engine flavors

=head1 DESCRIPTION

This is a base class for various FCGI::Engine flavors, it should be
possible to subclass this to add different approaches to FCGI::Engine.

The basic L<FCGI::Engine> shows a Catalyst/CGI::Application style
approach with a simple handler class, while the L<FCGI::Engine::PSGI>
shows how this can be used to run things like PSGI applications.

This class is mostly of interest to other FCGI::Engine flavor
developers, who should pretty much just read the source. The relevant
docs are to be found in L<FCGI::Engine> and L<FCGI::Engine::PSGI>.

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


