use strict;
use warnings;

package Footprintless::App::Command::deployment;
$Footprintless::App::Command::deployment::VERSION = '1.28';
# ABSTRACT: Performs an action on a deployment.
# PODNAME: Footprintless::App::Command::deployment

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'clean'  => 'Footprintless::App::Command::deployment::clean',
        'deploy' => 'Footprintless::App::Command::deployment::deploy'
    );
}

sub _default_action {
    return 'deploy';
}

sub usage_desc {
    return "fpl deployment DEPLOYMENT_COORD ACTION %o";
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::Command::deployment - Performs an action on a deployment.

=head1 VERSION

version 1.28

=head1 SYNOPSIS

    fpl deployment DEPLOYMENT_COORD clean
    fpl deployment DEPLOYMENT_COORD deploy
    fpl deployment DEPLOYMENT_COORD deploy --clean

=head1 DESCRIPTION

Performs actions on a deployment.

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

L<Footprintless::Deployment|Footprintless::Deployment>

=item *

L<Footprintless::App::Command::deployment::clean|Footprintless::App::Command::deployment::clean>

=item *

L<Footprintless::App::Command::deployment::deploy|Footprintless::App::Command::deployment::deploy>

=back

=cut
