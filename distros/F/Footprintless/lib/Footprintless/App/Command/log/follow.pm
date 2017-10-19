use strict;
use warnings;

package Footprintless::App::Command::log::follow;
$Footprintless::App::Command::log::follow::VERSION = '1.26';
# ABSTRACT: output the last part of a file and append as the file grows
# PODNAME: Footprintless::App::Command::log::follow

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->{log}->follow(
        runner_options => { out_handle => \*STDOUT },
        ( $opts->{until} ? ( until => $opts->{until} ) : () )
    );

    $logger->info('Done...');
}

sub opt_spec {
    return ( [ 'until=s', 'a regex used to determine when to stop following the log' ] );
}

sub usage_desc {
    return "fpl log LOG_COORD follow %o";
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{log} = $self->{footprintless}->log( $self->{coordinate} ); };
    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::Command::log::follow - output the last part of a file and append as the file grows

=head1 VERSION

version 1.26

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

=back

=for Pod::Coverage execute opt_spec usage_desc validate_args

=cut
