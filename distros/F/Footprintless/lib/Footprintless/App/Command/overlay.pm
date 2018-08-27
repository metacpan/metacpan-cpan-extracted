use strict;
use warnings;

package Footprintless::App::Command::overlay;
$Footprintless::App::Command::overlay::VERSION = '1.29';
# ABSTRACT: Performs an action on an overlay.
# PODNAME: Footprintless::App::Command::overlay

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'clean'      => 'Footprintless::App::Command::overlay::clean',
        'initialize' => 'Footprintless::App::Command::overlay::initialize',
        'update'     => 'Footprintless::App::Command::overlay::update'
    );
}

sub _default_action {
    return 'update';
}

sub usage_desc {
    return "fpl overlay OVERLAY_COORD ACTION %o";
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::Command::overlay - Performs an action on an overlay.

=head1 VERSION

version 1.29

=head1 SYNOPSIS

  fpl overlay OVERLAY_COORD clean
  fpl overlay OVERLAY_COORD initialize
  fpl overlay OVERLAY_COORD update
  fpl overlay OVERLAY_COORD # same as update

=head1 DESCRIPTION

Performs actions on an overlay. 

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

L<Footprintless::Overlay|Footprintless::Overlay>

=item *

L<Footprintless::App::Command::overlay::clean|Footprintless::App::Command::overlay::clean>

=item *

L<Footprintless::App::Command::overlay::initialize|Footprintless::App::Command::overlay::initialize>

=item *

L<Footprintless::App::Command::overlay::update|Footprintless::App::Command::overlay::update>

=back

=cut
