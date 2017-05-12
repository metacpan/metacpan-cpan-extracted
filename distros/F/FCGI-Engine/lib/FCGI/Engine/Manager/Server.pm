package FCGI::Engine::Manager::Server;
use Moose;

use MooseX::Daemonize::Pid::File;
use FCGI::Engine::Types;
use Config;

our $VERSION   = '0.22'; 
our $AUTHORITY = 'cpan:STEVAN';

has 'name' => (
    is      => 'ro', 
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        ((shift)->scriptname . '.server')
    }
);

has 'socket' => (
    is       => 'ro',
    isa      => 'FCGI::Engine::Listener',
    coerce   => 1,
    required => 1,
);

has $_ => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
) for qw[
    scriptname
    pidfile
];

has 'nproc' => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { 1 }
);

has 'additional_args' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    auto_deref => 1,
    predicate  => 'has_additional_args'
);

## ... internal attributes

has 'pid_obj' => (
    is        => 'ro',
    isa       => 'MooseX::Daemonize::Pid::File',
    lazy      => 1,
    default   => sub {
        MooseX::Daemonize::Pid::File->new(file => (shift)->pidfile)
    },
    clearer   => 'remove_pid_obj',
);

## methods ...

sub construct_command_line {
    my $self = shift;
    my $perl = $Config{perlpath};
    $perl .= $Config{_exe} if $^O ne 'VMS' and $perl !~ /$Config{_exe}$/i;
    return ($perl,
         ($self->has_additional_args
             ? $self->additional_args
             : ()),
         $self->scriptname, 
         "--nproc",
         $self->nproc,
         "--pidfile",
         $self->pidfile, 
         "--listen",
         $self->socket, 
         "--daemon");
}

# NOTE: 
# perhaps the server status information 
# should also go in here, so that we can 
# keep it all in one place.
# - SL

1;

__END__

=pod

=head1 NAME

FCGI::Engine::Manager::Server - An abstraction to represent a single FCGI::Engine server

=head1 DESCRIPTION

Nothing here to see really, this just models the individual server 
information in the config file for FCGI::Engine::Manager. It also 
handles creating the command line as well. 

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




