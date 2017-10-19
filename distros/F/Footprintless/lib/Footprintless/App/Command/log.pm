use strict;
use warnings;

package Footprintless::App::Command::log;
$Footprintless::App::Command::log::VERSION = '1.26';
# ABSTRACT: Provides access to log files.
# PODNAME: Footprintless::App::Command::log

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'cat'    => 'Footprintless::App::Command::log::cat',
        'follow' => 'Footprintless::App::Command::log::follow',
        'grep'   => 'Footprintless::App::Command::log::grep',
        'head'   => 'Footprintless::App::Command::log::head',
        'tail'   => 'Footprintless::App::Command::log::tail'
    );
}

sub _default_action {
    return 'follow';
}

sub usage_desc {
    return "fpl log LOG_COORD ACTION %o";
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::Command::log - Provides access to log files.

=head1 VERSION

version 1.26

=head1 SYNOPSIS

  fpl log foo.dev.tomcat.logs.catalina follow
  fpl log foo.prod.web.logs.access grep --arg "--color" --arg "'GET /foo/bar'"

=head1 DESCRIPTION

Provides various forms of read access to log files.

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

L<Footprintless::Log|Footprintless::Log>

=item *

L<Footprintless::App::Command::log::cat|Footprintless::App::Command::log::cat>

=item *

L<Footprintless::App::Command::log::follow|Footprintless::App::Command::log::follow>

=item *

L<Footprintless::App::Command::log::grep|Footprintless::App::Command::log::grep>

=item *

L<Footprintless::App::Command::log::head|Footprintless::App::Command::log::head>

=item *

L<Footprintless::App::Command::log::tail|Footprintless::App::Command::log::tail>

=back

=cut
