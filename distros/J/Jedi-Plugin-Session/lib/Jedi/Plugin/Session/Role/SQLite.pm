#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Role::SQLite;

# ABSTRACT: SQLite Backend

use strict;
use warnings;
our $VERSION = '0.05';    # VERSION

use File::ShareDir;
use Path::Class;
use Carp;
use Jedi::Plugin::Session::Backend::SQLite;
use Moo::Role;

sub _build__jedi_session {
    my ($self)     = @_;
    my $class      = ref $self;
    my $expires_in = $self->jedi_config->{$class}{session}{expiration}
        // '3 hours';
    my $sqlite_path = $self->jedi_config->{$class}{session}{sqlite}{path};
    if ( !defined $sqlite_path ) {
        $sqlite_path = dir( File::ShareDir::dist_dir('Jedi-Plugin-Session') );
    }
    croak
        "SQLite path is missing and cannot be guest. Please setup the configuration file."
        if !defined $sqlite_path;
    my $app_dir = dir( $sqlite_path, split( /::/x, $class ) );
    my $sqlite_db_file = file( $app_dir . '.db' );
    return Jedi::Plugin::Session::Backend::SQLite->new(
        database   => $sqlite_db_file,
        expires_in => $expires_in,
    );
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Role::SQLite - SQLite Backend

=head1 VERSION

version 0.05

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-session/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
