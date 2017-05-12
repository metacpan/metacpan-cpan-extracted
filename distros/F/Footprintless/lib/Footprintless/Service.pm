use strict;
use warnings;

package Footprintless::Service;
$Footprintless::Service::VERSION = '1.24';
# ABSTRACT: Performs an action on a service.
# PODNAME: Footprintless::Service

use parent qw(Footprintless::MixableBase);

use Carp;
use Footprintless::Command qw(
    batch_command
    command
);
use Footprintless::CommandOptionsFactory;
use Footprintless::InvalidEntityException;
use Footprintless::Localhost;
use Footprintless::Mixins qw(
    _command_options
    _entity
    _run_or_die
);
use Footprintless::Util qw(
    invalid_entity
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub kill {
    my ( $self, %options ) = @_;
    $self->execute( 'kill', %options );
}

sub _command {
    my ( $self, $action ) = @_;
    my $command      = $self->{spec}{command};
    my $actions_spec = $self->{spec}{actions}{$action};
    if ($actions_spec) {
        if ( $actions_spec->{command} ) {
            return $actions_spec->{command};
        }
        elsif ( $actions_spec->{command_args} ) {
            $action = $actions_spec->{command_args};
        }
        elsif ( $actions_spec->{use_pid} ) {
            invalid_entity( $self->{coordinate},
                "pid_file or pid_command required for [$action]" )
                unless ( $self->{spec}{pid_file} || $self->{spec}{pid_command} );

            my $pid_file = $self->{spec}{pid_file};
            my $pid_command =
                $pid_file
                ? command(
                "cat $pid_file",
                $self->{command_options}->clone(
                    hostname     => undef,
                    ssh          => undef,
                    ssh_username => undef,
                )
                )
                : $self->{spec}{pid_command};
            if ( $action eq 'kill' ) {
                return "kill -KILL \$($pid_command)";
            }
            elsif ( $action eq 'status' ) {
                my $command_name = $actions_spec->{command_name} || $command || 'command';
                return command( "kill -0 \$($pid_command) 2> /dev/null "
                        . "&& echo '$command_name is running' "
                        . "|| echo '$command_name is stopped'" );
            }
            else {
                invalid_entity( $self->{coordinate}, "use_pid not supported for [$action]" );
            }
        }
    }

    invalid_entity( $self->{coordinate}, "no command specified for [$action]" )
        unless ($command);
    return "$command $action";
}

sub execute {
    my ( $self, $action, %options ) = @_;

    my $runner_options =
          %options && $options{runner_options}
        ? $options{runner_options}
        : { out_handle => \*STDOUT };

    $self->_run_or_die( command( $self->_command($action), $self->{command_options} ),
        $runner_options );
}

sub _init {
    my ( $self, %options ) = @_;

    $self->{entity}          = $self->{factory}->entities();
    $self->{spec}            = $self->_entity( $self->{coordinate}, 1 );
    $self->{command_options} = $self->_command_options();

    return $self;
}

sub start {
    my ( $self, %options ) = @_;
    $self->execute( 'start', %options );
}

sub status {
    my ( $self, %options ) = @_;
    $self->execute( 'status', %options );
}

sub stop {
    my ( $self, %options ) = @_;
    $self->execute( 'stop', %options );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Service - Performs an action on a service.

=head1 VERSION

version 1.24

=head1 SYNOPSIS

    # Standard way of getting a service
    use Footprintless;
    my $service = Footprintless->new()->service();

    $service->stop();

    $service->start();

    $service->status();

    $service->kill();

=head1 DESCRIPTION

Manages services.  Allows you to start, stop, check the status of, and
kill services.  Additional actions can be configured as well.

=head1 ENTITIES

A simple service (the most common case) can be defined:

    service => {
        command => '/opt/foo/bar.sh',
        pid_file => '/var/run/bar/bar.pid'
    }

A more complex service might be defined:

    service => {
        actions => {
            debug => {command_args => "jpda start"},
            kill => {command_args => "stop -kill"},
            status => {use_pid => 1, command_name => 'tomcat'},
        },
        command => '/opt/tomcat/catalina.sh',
        hostname => 'tomcat.pastdev.com',
        pid_command => 'ps -aef|grep "/opt/tomcat/"|grep -v grep|awk \'{print \$2}\'',
        sudo_username => 'tomcat',
    }

In this case, an additional action, debug, was added, kill was redefined
as a special case of stop, and status was redefined to use the pid 
(ex: kill -0 $pid).  Also, the pid is found via command rather than a file.

=head1 CONSTRUCTORS

=head2 new($entity, $coordinate, %options)

Constructs a new service configured by C<$entities> at C<$coordinate>.  
The supported options are:

=over 4

=item command_options_factory

The command options factory to use.  Defaults to an instance of
L<Footprintless::CommandOptionsFactory> using the C<localhost> instance
of this object.

=item command_runner

The command runner to use.  Defaults to an instance of 
L<Footprintless::CommandRunner::IPCRun>.

=item localhost

The localhost alias resolver to use.  Defaults to an instance of
L<Footprintless::Localhost> configured with C<load_all()>.

=back

=head1 METHODS

=head2 execute($action)

Executes C<$action> on the service.

=head2 kill()

Kills the service.

=head2 start()

Starts the service.

=head2 status()

Prints out the status of the service.

=head2 stop()

Stops the service.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Config::Entities|Config::Entities>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::CommandOptionsFactory|Footprintless::CommandOptionsFactory>

=item *

L<Footprintless::CommandRunner|Footprintless::CommandRunner>

=item *

L<Footprintless::Localhost|Footprintless::Localhost>

=back

=cut
