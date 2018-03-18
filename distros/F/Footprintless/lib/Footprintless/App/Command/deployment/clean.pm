use strict;
use warnings;

package Footprintless::App::Command::deployment::clean;
$Footprintless::App::Command::deployment::clean::VERSION = '1.28';
# ABSTRACT: removes all files managed by the deployment
# PODNAME: Footprintless::App::Command::deployment::clean

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $logger->info('Performing clean...');
    $self->{deployment}->clean();

    $logger->info('Done...');
}

sub usage_desc {
    return "fpl deployment DEPLOYMENT_COORD clean %o";
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{deployment} = $self->{footprintless}->deployment( $self->{coordinate} ); };

    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::Command::deployment::clean - removes all files managed by the deployment

=head1 VERSION

version 1.28

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

=for Pod::Coverage execute usage_desc validate_args

=cut
