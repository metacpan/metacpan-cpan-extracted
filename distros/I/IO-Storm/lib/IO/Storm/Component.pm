# ABSTRACT: The base class for Bolts and Spouts.

package IO::Storm::Component;
$IO::Storm::Component::VERSION = '0.17';
# Imports
use strict;
use warnings;
use v5.10;
use IO::Handle qw(autoflush);
use IO::File;
use Log::Log4perl qw(:easy);
use JSON::XS;
use Data::Dumper;
use IO::Storm::Tuple;

# Setup Moo for object-oriented niceties
use Moo;
use namespace::clean;

# Setup STDIN/STDOUT/STDERR to use UTF8
binmode STDERR, ':utf8';
binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':utf8';

has '_pending_commands' => (
    is      => 'rw',
    default => sub { [] },
);

has '_pending_taskids' => (
    is      => 'rw',
    default => sub { [] },
);

has '_stdin' => (
    is      => 'rw',
    default => sub {
        my $io = IO::Handle->new;
        $io->fdopen( fileno(STDIN), 'r' );
    }
);

has 'max_lines' => (
    is      => 'rw',
    default => 100
);

has 'max_blank_msgs' => (
    is      => 'rw',
    default => 500
);

has '_json' => (
    is      => 'rw',
    default => sub { JSON::XS->new->allow_blessed->convert_blessed }
);

has '_topology_name' => (
    is        => 'rw',
    init_args => undef
);

has '_task_id' => (
    is        => 'rw',
    init_args => undef
);

has '_component_name' => (
    is        => 'rw',
    init_args => undef
);

has '_debug' => (
    is        => 'rw',
    init_args => undef
);

has '_storm_conf' => (
    is        => 'rw',
    init_args => undef
);

has '_context' => (
    is        => 'rw',
    init_args => undef
);

my $logger = Log::Log4perl->get_logger('storm');


sub _setup_component {
    my ( $self, $storm_conf, $context ) = @_;
    my $conf_is_hash = ref($storm_conf) eq ref {};
    $self->_topology_name(
        ( $conf_is_hash && exists( $storm_conf->{'topology.name'} ) )
        ? $storm_conf->{'topology.name'}
        : ''
    );
    $self->_task_id( exists( $context->{taskid} ) ? $context->{taskid} : '' );
    $self->_component_name('');
    if ( exists( $context->{'task->component'} ) ) {
        my $task_component = $context->{'task->component'};
        if ( exists( $task_component->{ $self->_task_id } ) ) {
            $self->_component_name( $task_component->{ $self->_task_id } );
        }
    }
    $self->_debug(
        ( $conf_is_hash && exists( $storm_conf->{'topology.debug'} ) )
        ? $storm_conf->{'topology.debug'}
        : 0
    );
    $self->_storm_conf($storm_conf);
    $self->_context($context);
}


sub read_message {
    $logger->debug('start read_message');
    my $self         = shift;
    my $blank_lines  = 0;
    my $message_size = 0;
    my $line         = '';

    my @messages = ();
    while (1) {
        $line = $self->_stdin->getline;
        if ( defined($line) ) {
            $logger->debug("read_message: line=$line");
        }
        else {
            $logger->error( "Received EOF while trying to read stdin from "
                    . "Storm, pipe appears to be broken, exiting." );
            exit(1);
        }
        if ( $line eq "end\n" ) {
            last;
        }
        elsif ( $line eq '' ) {
            $logger->error( "Received EOF while trying to read stdin from "
                    . "Storm, pipe appears to be broken, exiting." );
            exit(1);
        }
        elsif ( $line eq "\n" ) {
            $blank_lines++;
            if ( $blank_lines % 1000 == 0 ) {
                $logger->warn( "While trying to read a command or pending "
                        . "task ID, Storm has instead sent $blank_lines "
                        . "'\\n' messages." );
                next;
            }
        }
        chomp($line);
        push( @messages, $line );
    }

    return $self->_json->decode( join( "\n", @messages ) );
}

sub read_task_ids {
    my $self = shift;

    if ( scalar( @{ $self->_pending_taskids } ) ) {
        return shift( @{ $self->_pending_taskids } );
    }
    else {
        my $msg = $self->read_message();
        while ( ref($msg) ne 'ARRAY' ) {
            push( @{ $self->_pending_commands }, $msg );
            $msg = $self->read_message();
        }

        return $msg;
    }
}

sub read_command {
    my $self = shift;

    if ( @{ $self->_pending_commands } ) {
        return shift( @{ $self->_pending_commands } );
    }
    else {
        my $msg = $self->read_message();
        while ( ref($msg) eq 'ARRAY' ) {
            push( @{ $self->_pending_taskids }, $msg );
            $msg = $self->read_message();
        }
        return $msg;
    }
}


sub read_tuple {
    my $self = shift;
    $logger->debug('read_tuple');

    my $tupmap = $self->read_command();

    return IO::Storm::Tuple->new(
        id        => $tupmap->{id},
        component => $tupmap->{comp},
        stream    => $tupmap->{stream},
        task      => $tupmap->{task},
        values    => $tupmap->{tuple}
    );
}


sub read_handshake {
    my $self = shift;

    # TODO: Figure out how to redirect stdout to ensure that print
    # statements/functions won't crash the Storm Java worker

    autoflush STDOUT 1;
    autoflush STDERR 1;

    my $msg = $self->read_message();
    $logger->debug(
        sub { 'Received initial handshake from Storm: ' . Dumper($msg) } );

    # Write a blank PID file out to the pidDir
    my $pid      = $$;
    my $pid_dir  = $msg->{pidDir};
    my $filename = $pid_dir . '/' . $pid;
    open my $fh, '>', $filename
        or die "Cant't write to '$filename': $!\n";
    $fh->close;
    $logger->debug("Sending process ID $pid to Storm");
    $self->send_message( { pid => int($pid) } );

    return [ $msg->{conf}, $msg->{context} ];
}


sub send_message {
    my ( $self, $msg ) = @_;
    say $self->_json->encode($msg);
    say "end";
}


sub sync {
    my $self = shift;
    $self->send_message( { command => 'sync' } );
}


sub log {
    my ( $self, $message ) = @_;
    $self->send_message( { command => 'log', msg => $message } );
}

1;

__END__

=pod

=head1 NAME

IO::Storm::Component - The base class for Bolts and Spouts.

=head1 VERSION

version 0.17

=head1 METHODS

=head2 _setup_component

Add helpful instance variables to component after initial handshake with Storm.

=head2 read_message

Read a message from the ShellBolt.  Reads until it finds a "end" line.

=head2 read_tuple

Turn the incoming Tuple structure into an <IO::Storm::Tuple>.

=head2 read_handshake

Read and process an initial handshake message from Storm

=head2 send_message

Send a message to Storm, encoding it as JSON.

=head2 sync

Send a sync command to Storm.

=head2 log

Send a log command to Storm

=head1 AUTHORS

=over 4

=item *

Dan Blanchard <dblanchard@ets.org>

=item *

Cory G Watson <gphat@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Educational Testing Service.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
