use strict;
use warnings;

package Footprintless::CommandRunner::IPCRun3;
$Footprintless::CommandRunner::IPCRun3::VERSION = '1.28';
# ABSTRACT: An implementation of Footprintless::CommandRunner using IPC::Run3
# PODNAME: Footprintless::CommandRunner::IPCRun3

use parent qw(Footprintless::CommandRunner);

use Carp;
use IPC::Run3;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _run3_options {
    my ( $self, $runner_options ) = @_;

    my $in  = \undef;
    my $out = \$self->{last_call}{stdout};
    my $err = \$self->{last_call}{stderr};

    return ( $in, $out, $err );
}

sub _run {
    my ( $self, $command, $runner_options ) = @_;
    run3( $command, $self->_run3_options($runner_options) );
    return $? >> 8;
}

1;

__END__

=pod

=head1 NAME

Footprintless::CommandRunner::IPCRun3 - An implementation of Footprintless::CommandRunner using IPC::Run3

=head1 VERSION

version 1.28

=head1 DESCRIPTION

An implementation of L<Footprintless::CommandRunner> using C<IPC::Run3>.
This implementation is B<NOT> complete.  C<IPC::Run3> does not have a 
timeout feature so it can hang indefinitely.  Also, the callbacks and 
handles have not yet been implemented.  This I<should> work for simple
commands that you want command runner to track out and err for.  Use
L<Footprintless::CommandRunner::IPCRun> instead if you want a full
featured implementation.

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

=item *

L<Footprintless::CommandRunner::IPCRun|Footprintless::CommandRunner::IPCRun>

=back

=cut
