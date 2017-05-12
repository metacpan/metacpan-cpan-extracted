use strict;
use warnings;

package Footprintless::CommandRunner::IPCRun;
$Footprintless::CommandRunner::IPCRun::VERSION = '1.24';
# ABSTRACT: An implementation of Footprintless::CommandRunner using IPC::Run
# PODNAME: Footprintless::CommandRunner::IPCRun

use parent qw(Footprintless::CommandRunner);

use Carp;
use IPC::Run;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _run_options {
    my ( $self, $runner_options ) = @_;
    my @timeout;
    if ( $runner_options->{timeout} ) {
        @timeout = ( IPC::Run::timeout( $runner_options->{timeout} ) );
    }

    my $in = $runner_options->{in_handle} || \undef;
    my $out =
           $runner_options->{out_handle}
        || $runner_options->{out_callback}
        || \$self->{last_call}{stdout};
    my $err =
           $runner_options->{err_handle}
        || $runner_options->{err_callback}
        || \$self->{last_call}{stderr};

    return ( '<', $in, '>', $out, '2>', $err, @timeout );
}

sub _run {
    my ( $self, $command, $runner_options ) = @_;
    if ( $runner_options->{out_callback} || $runner_options->{err_callback} ) {
        my $out_callback = $runner_options->{out_callback};
        my $err_callback = $runner_options->{err_callback};

        my ( $out, $err );
        local $runner_options->{out_callback} = \$out if ($out_callback);
        local $runner_options->{err_callback} = \$err if ($err_callback);
        my $harness =
            IPC::Run::start( [ 'sh', '-c', $command ], $self->_run_options($runner_options) );

        my ( $last_part_out, $last_part_err ) = ( '', '' );
        eval {
            while ( $harness->pump() ) {
                if ($out_callback) {
                    my @lines = split( /\r?\n/, $last_part_out . $out, -1 );
                    $last_part_out = pop(@lines) || '';
                    &$out_callback($_) foreach (@lines);
                    $out = '';
                }

                if ($err_callback) {
                    my @lines = split( /\r?\n/, $last_part_err . $err, -1 );
                    $last_part_err = pop(@lines) || '';
                    &$err_callback($_) foreach (@lines);
                    $err = '';
                }
            }

            &$out_callback($last_part_out)
                if ( $out_callback && length($last_part_out) > 0 );
            &$err_callback($last_part_err)
                if ( $err_callback && length($last_part_err) > 0 );
        };
        my $error = $@;
        if ($error) {
            $logger->debugf( "callback exited early: %s", $error );
            $harness->kill_kill();
            die($error);
        }
    }
    else {
        IPC::Run::run( [ 'sh', '-c', $command ], $self->_run_options($runner_options) );
    }
    return $? >> 8;
}

1;

__END__

=pod

=head1 NAME

Footprintless::CommandRunner::IPCRun - An implementation of Footprintless::CommandRunner using IPC::Run

=head1 VERSION

version 1.24

=head1 DESCRIPTION

An implementation of L<Footprintless::CommandRunner> using C<IPC::Run>.

=head1 CONSTRUCTORS

=head2 new()

Constructs a new instance.

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

L<Footprintless|Footprintless>

=item *

L<Footprintless::CommandRunner|Footprintless::CommandRunner>

=back

=cut
