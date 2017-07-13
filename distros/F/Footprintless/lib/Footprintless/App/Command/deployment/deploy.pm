use strict;
use warnings;

package Footprintless::App::Command::deployment::deploy;
$Footprintless::App::Command::deployment::deploy::VERSION = '1.25';
# ABSTRACT: deploys all files managed by the deployment
# PODNAME: Footprintless::App::Command::deployment::deploy

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    if ( $opts->{clean} ) {
        $logger->info('Performing clean...');
        $self->{deployment}->clean();
    }
    $logger->info('Performing deploy...');
    $self->{deployment}->deploy();

    $logger->info('Done...');
}

sub opt_spec {
    return ( [ "clean", "will cause clean to be run before deploy" ] );
}

sub usage_desc {
    return "fpl deployment DEPLOYMENT_COORD deploy %o";
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

Footprintless::App::Command::deployment::deploy - deploys all files managed by the deployment

=head1 VERSION

version 1.25

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
