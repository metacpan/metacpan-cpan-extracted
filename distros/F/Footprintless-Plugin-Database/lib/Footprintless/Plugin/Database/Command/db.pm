use strict;
use warnings;

package Footprintless::Plugin::Database::Command::db;
$Footprintless::Plugin::Database::Command::db::VERSION = '1.04';
# ABSTRACT: Provides support for databases
# PODNAME: Footprintless::Plugin::Database::Command::db

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'backup'  => 'Footprintless::Plugin::Database::Command::db::backup',
        'client'  => 'Footprintless::Plugin::Database::Command::db::client',
        'copy-to' => 'Footprintless::Plugin::Database::Command::db::copy_to',
        'restore' => 'Footprintless::Plugin::Database::Command::db::restore',
    );
}

sub _default_action {
    return 'client';
}

sub usage_desc {
    return 'fpl db DB_COORD ACTION %o';
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::Command::db - Provides support for databases

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    fpl db pastdev.dev.app.db backup

=head1 DESCRIPTION

Performs actions on a database instance.

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

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=back

=cut
