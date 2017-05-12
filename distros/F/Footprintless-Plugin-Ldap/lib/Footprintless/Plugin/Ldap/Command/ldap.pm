use strict;
use warnings;

package Footprintless::Plugin::Ldap::Command::ldap;
$Footprintless::Plugin::Ldap::Command::ldap::VERSION = '1.00';
# ABSTRACT: Provides support for LDAP directories
# PODNAME: Footprintless::Plugin::Ldap::Command::ldap;

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'backup'       => 'Footprintless::Plugin::Ldap::Command::ldap::backup',
        'copy-to'      => 'Footprintless::Plugin::Ldap::Command::ldap::copy_to',
        'copy-user-to' => 'Footprintless::Plugin::Ldap::Command::ldap::copy_user_to',
        'restore'      => 'Footprintless::Plugin::Ldap::Command::ldap::restore',
        'search'       => 'Footprintless::Plugin::Ldap::Command::ldap::search'
    );
}

sub usage_desc {
    return 'fpl ldap LDAP_COORD ACTION';
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap::Command::ldap; - Provides support for LDAP directories

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    fpl ldap proj.env.ldap backup
    fpl ldap proj.env.ldap copy-to
    fpl ldap proj.env.ldap copy-user-to
    fpl ldap proj.env.ldap restore
    fpl ldap proj.env.ldap search

=head1 DESCRIPTION

Performs actions on an LDAP directory instance.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=back

=cut
