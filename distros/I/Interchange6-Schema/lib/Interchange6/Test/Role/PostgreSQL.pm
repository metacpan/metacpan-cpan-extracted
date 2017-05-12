package Interchange6::Test::Role::PostgreSQL;

=head1 NAME

Interchange6::Test::Role::PostgreSQL

=cut

use Test::Roo::Role;
with 'Interchange6::Test::Role::Database';

=head1 METHODS

See also L<Interchange6::Test::Role::Database> which is consumed by this role.

=head2 BUILD

Check that all required modules load or else plan skip_all

=cut

sub BUILD {
    my $self = shift;

    eval('use DateTime::Format::Pg; 1')
      or plan skip_all => "DateTime::Format::Pg required to run these tests";

    eval('use DBD::Pg 3.0.0; 1')
      or plan skip_all => "DBD::Pg >= 3.0.0 required to run these tests";

    eval('use Test::Postgresql58; 1')
      or plan skip_all => "Test::Postgresql58 required to run these tests";

    eval { $self->database }
      or plan skip_all => "Init database failed: $@";
}

sub _build_database {
    my $self = shift;
    no warnings 'once'; # prevent: "Test::Postgresql58::errstr" used only once
    my $pgsql = Test::Postgresql58->new(
        initdb_args
          => $Test::Postgresql58::Defaults{initdb_args}
            . ' --encoding=utf8 --no-locale'
    ) or die $Test::Postgresql58::errstr;
    return $pgsql;
}

sub _build_dbd_version {
    return "DBD::Pg $DBD::Pg::VERSION Test::Postgresql58 $Test::Postgresql58::VERSION";
}

=head2 connect_info

Returns appropriate DBI connect info for this role.

=cut

sub connect_info {
    my $self = shift;
    return ( $self->database->dsn, undef, undef,
        {
            on_connect_do  => 'SET client_min_messages=WARNING;',
            quote_names    => 1,
        }
    );
}

sub _build_database_info {
    my $self = shift;
    $self->ic6s_schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            @{ $dbh->selectrow_arrayref(q| SELECT version() |) }[0];
        }
    );
}

after teardown => sub {
};

1;
