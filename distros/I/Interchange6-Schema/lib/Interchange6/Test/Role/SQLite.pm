package Interchange6::Test::Role::SQLite;

=head1 NAME

Interchange6::Test::Role::SQLite

=cut

use File::Temp;
use Test::Roo::Role;
with 'Interchange6::Test::Role::Database';

=head1 METHODS

See also L<Interchange6::Test::Role::Database> which is consumed by this role.

=head2 BUILD

Check that all required modules load or else plan skip_all

=cut

sub BUILD {
    eval('use DBD::SQLite; 1')
      or plan skip_all => "DBD::SQLite required to run these tests";
}

my $fh = File::Temp->new(
    TEMPLATE => 'ic6s_test_XXXXX',
    EXLOCK   => 0,
    TMPDIR   => 1,
);
my $dbfile = $fh->filename;

after teardown => sub {
    shift->clear_database;
};

=head2 clear_database

Attempt to unlink temporary database file

=cut

sub clear_database {
    close($fh);
    unlink($dbfile) or diag "Could not unlink $dbfile: $!";
}

sub _build_database {

    # does nothing atm for SQLite
    return;
}

sub _build_dbd_version {
    return "DBD::SQLite $DBD::SQLite::VERSION";
}

=head2 connect_info

Returns appropriate DBI connect info for this role.

=cut

sub connect_info {
    my $self = shift;

    return ( "dbi:SQLite:dbname=$dbfile", undef, undef,
        {
            sqlite_unicode  => 1,
            on_connect_call => 'use_foreign_keys',
            on_connect_do   => 'PRAGMA synchronous = OFF',
            quote_names     => 1,
        }
    );
}

sub _build_database_info {
    my $self = shift;
    return "SQLite library version: "
      . $self->ic6s_schema->storage->dbh->{sqlite_version};
}

1;
