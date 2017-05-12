use strict;
use warnings;

package Footprintless::Log;
$Footprintless::Log::VERSION = '1.24';
# ABSTRACT: A log manager
# PODNAME: Footprintless::Log

use parent qw(Footprintless::MixableBase);

use Carp;
use Footprintless::Command qw(
    command
    tail_command
);
use Footprintless::CommandOptionsFactory;
use Footprintless::Localhost;
use Footprintless::Mixins qw(
    _entity
);
use Footprintless::Util qw(
    dumper
    invalid_entity
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub _action_args {
    my ($args) = @_;
    return '' unless ($args);

    my $ref = ref($args);
    return "$args " unless ($ref);

    croak("unsupported ref type [$ref] for action options")
        unless ( $ref eq 'ARRAY' );

    return scalar(@$args)
        ? join( ' ', @$args, '' )
        : '';
}

sub cat {
    my ( $self, %options ) = @_;

    my $action_args = _action_args( $options{args} );

    return $self->{command_runner}
        ->run_or_die( command( "cat $action_args$self->{log_file}", $self->{command_options} ),
        $self->_runner_options( $options{runner_options} ) );
}

sub follow {
    my ( $self, %options ) = @_;

    eval {
        $self->{command_runner}->run_or_die(
            tail_command( $self->{log_file}, follow => 1, $self->{command_options} ),
            $self->_runner_options( $options{runner_options}, $options{until} )
        );
    };
    if ($@) {
        my $exception = $self->{command_runner}->get_exception();
        croak($@) unless ( $exception && $exception =~ /^until found .*$/ );
    }
}

sub grep {
    my ( $self, %options ) = @_;

    my $action_args = _action_args( $options{args} );

    return $self->{command_runner}
        ->run_or_die( command( "grep $action_args$self->{log_file}", $self->{command_options} ),
        $self->_runner_options( $options{runner_options} ) );
}

sub head {
    my ( $self, %options ) = @_;

    my $action_args = _action_args( $options{args} );

    return $self->{command_runner}
        ->run_or_die( command( "head $action_args$self->{log_file}", $self->{command_options} ),
        $self->_runner_options( $options{runner_options} ) );
}

sub _init {
    my ( $self, %options ) = @_;

    $self->{spec} = $self->_entity( $self->{coordinate}, 1 );

    # Allow string, hashref with file key, or object
    my $ref = ref( $self->{spec} );
    if ($ref) {
        if ( $ref eq 'HASH' ) {
            if ( $self->{spec}{file} ) {
                $self->{log_file} = $self->{spec}{file};
            }
            else {
                invalid_entity( $self->{coordinate}, "must be file, or hashref with 'file' key" );
            }
        }
        elsif ( $ref eq 'SCALAR' ) {
            $self->{log_file} = $self->{spec};
        }
        else {
            invalid_entity( $self->{coordinate}, "must be file, or hashref with 'file' key" );
        }
    }
    else {
        $self->{log_file} = $self->{spec};
    }

    $self->{command_runner}  = $self->{factory}->command_runner();
    $self->{command_options} = $self->{factory}->command_options(
        %{  $self->{factory}->entities()->fill(
                $self->{coordinate},
                {   hostname      => undef,
                    ssh           => undef,
                    ssh_username  => undef,
                    sudo_command  => undef,
                    sudo_username => undef
                },
                ancestry => 1
            )
        }
    );

    return $self;
}

sub _runner_options {
    my ( $self, $runner_options, $until ) = @_;

    $runner_options = {} unless ($runner_options);

    my $options = {};
    if ($until) {
        if ( $runner_options->{out_buffer} ) {
            $options->{out_callback} = sub {
                my ($line) = @_;
                ${ $runner_options->{out_buffer} } .= "$line\n";
                die('until found') if ( $line =~ $until );
            };
        }
        elsif ( $runner_options->{out_callback} ) {
            $options->{out_callback} = sub {
                my ($line) = @_;
                &{ $runner_options->{out_callback} }($line);
                die('until found') if ( $line =~ $until );
            };
        }
        else {
            my $handle = $runner_options->{out_handle};
            $options->{out_callback} = sub {
                my ($line) = @_;
                print( $handle "$line\n" ) if ($handle);
                die('until found') if ( $line =~ $until );
            };
        }
    }
    else {
        if ( exists( $runner_options->{out_buffer} ) ) {
            $options->{out_buffer} = $runner_options->{out_buffer};
        }
        elsif ( exists( $runner_options->{out_callback} ) ) {
            $options->{out_callback} = $runner_options->{out_callback};
        }
        elsif ( exists( $runner_options->{out_handle} ) ) {
            $options->{out_handle} = $runner_options->{out_handle};
        }
    }

    if ( exists( $runner_options->{err_buffer} ) ) {
        $options->{err_buffer} = $runner_options->{err_buffer};
    }
    elsif ( exists( $runner_options->{err_callback} ) ) {
        $options->{err_callback} = $runner_options->{err_callback};
    }
    elsif ( exists( $runner_options->{err_handle} ) ) {
        $options->{err_handle} = $runner_options->{err_handle};
    }

    return $options;
}

sub tail {
    my ( $self, %options ) = @_;

    my $action_args = _action_args( $options{args} );

    return $self->{command_runner}
        ->run_or_die( command( "tail $action_args$self->{log_file}", $self->{command_options} ),
        $self->_runner_options( $options{runner_options} ) );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Log - A log manager

=head1 VERSION

version 1.24

=head1 SYNOPSIS

    # Standard way of getting a log
    use Footprintless;
    my $log = Footprintless->new()->log();

    # Wait for a started message before proceeding
    $log->follow(until => qr/Started in \d+/); 

    # Check for errors during startup
    my $error_messages = $log->grep(options => {'ERROR'});

=head1 DESCRIPTION

Provides access to read from log files.

=head1 ENTITIES

A log entity can be a simple entity:

    catalina => '/opt/tomcat/logs/catalina.out'

Or it can be a hashref entity containing, at minimum, a C<file> entity:

    catalina => {
        file => '/var/log/external/web/catalina.out',
        hostname => 'loghost.pastdev.com'
    }

All unspecified command options will be inherited (C<hostname>, C<ssh>, 
C<sudo_username>, C<username>) from their ancestry.  Logs are commonly 
grouped together:

    web => {
        hostname => 'web.pastdev.com',
        logs => {
            error => '/var/log/httpd/error_log',
            access => '/var/log/httpd/access_log'
            catalina => {
                file => '/opt/tomcat/logs/catalina.out',
                hostname => 'app.pastdev.com',
                sudo_username => 'tomcat'
            }
        }
        sudo_username => 'apache'
    }

=head1 CONSTRUCTORS

=head2 new($entity, $coordinate, %options)

Constructs a new log manager configured by the C<$entities> at C<$coordinate>.  
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

=head2 cat(%options)

Executes the C<cat> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<cat> command

=back

=head2 follow(%options)

Executes the C<tail> command with the C<-f> (follow) option and sets
the command runner options to pass the C<STDOUT> from tail to this
C<STDOUT>.

=over 4

=item runner_options

Runner options to be passed on to the command runner.

=item until

The command will stop once the regex supplied is matched to the output.

=back

=head2 grep(%options)

Executes the C<grep> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<grep> command

=back

=head2 head(%options)

Executes the C<head> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<head> command

=back

=head2 tail(%options)

Executes the C<tail> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<tail> command

=back

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
