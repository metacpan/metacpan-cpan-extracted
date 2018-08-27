use strict;
use warnings;

package Footprintless::App::Command::log::grep;
$Footprintless::App::Command::log::grep::VERSION = '1.29';
# ABSTRACT: output lines matching a pattern
# PODNAME: Footprintless::App::Command::log::grep

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->{log}->grep(
        runner_options => { out_handle => \*STDOUT },
        ( $opts->{arg} ? ( args => $opts->{arg} ) : () )
    );

    $logger->info('Done...');
}

sub opt_spec {
    return ( [ 'arg=s@', 'an argument passed to the command' ] );
}

sub usage_desc {
    return "fpl log LOG_COORD grep %o";
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

Footprintless::App::Command::log::grep - output lines matching a pattern

=head1 VERSION

version 1.29

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
