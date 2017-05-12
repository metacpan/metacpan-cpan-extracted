#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Backend::SQLite;

# ABSTRACT: Backend storage for SQLite

use strict;
use warnings;
our $VERSION = '0.05';    # VERSION
use Time::Duration::Parse;
use Sereal qw/encode_sereal decode_sereal/;
use Path::Class;
use Carp;
use Jedi::Plugin::Session::Backend::SQLite::DB;
use DBIx::Class::Migration;
use Moo;

has 'database' => (
    is     => 'ro',
    coerce => sub {
        my ($db) = @_;
        my $dbfile = file($db);
        $dbfile->dir->mkpath;
        return _prepare_database($dbfile);
    }
);

has 'expires_in' => (
    is      => 'ro',
    default => sub { 3 * 3600 },
    coerce  => sub { parse_duration( $_[0] ) }
);

## no critic (NamingConventions::ProhibitAmbiguousNames)

sub get {
    my ( $self, $uuid ) = @_;
    return if !defined $uuid;
    my $resultset = $self->database->resultset('Session');
    my $now       = time;
    my $data      = $resultset->find($uuid);
    my $session;
    if ( defined $data ) {
        if ( $data->expire_at > $now ) {
            return if !eval { $session = decode_sereal( $data->session ); 1 };
        }
        else {
            $resultset->search( { expire_at => { '<=' => $now } } )
                ->delete_all;
        }
    }
    return $session;
}

sub set {
    my ( $self, $uuid, $value ) = @_;
    return if !defined $uuid;
    my $session = encode_sereal($value);
    $self->database->resultset('Session')->update_or_create(
        {   id        => $uuid,
            expire_at => time + $self->expires_in,
            session   => $session
        }
    );
    return 1;
}

# PRIVATE

sub _prepare_database {
    my ($dbfile) = @_;
    my @connect_info = ( "dbi:SQLite:dbname=" . $dbfile->stringify );
    my $schema
        = Jedi::Plugin::Session::Backend::SQLite::DB->connect(@connect_info);

    my $migration = DBIx::Class::Migration->new( schema => $schema, );

    $migration->install_if_needed;
    $migration->upgrade;

    return $schema;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Backend::SQLite - Backend storage for SQLite

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
