package Interchange6::Test::Role::MySQL;

=head1 NAME

Interchange6::Test::Role::MySQL

=cut

use File::Temp qw/tempdir/;
use Test::Roo::Role;
with 'Interchange6::Test::Role::Database';

=head1 METHODS

See also L<Interchange6::Test::Role::Database> which is consumed by this role.

=head2 BUILD

Check that all required modules load or else plan skip_all

=cut

sub BUILD {
    my $self = shift;

    eval 'use DateTime::Format::MySQL; 1'
      or plan skip_all => "DateTime::Format::MySQL required to run these tests";

    eval 'use DBD::mysql; 1'
      or plan skip_all => "DBD::mysql required to run these tests";

    eval 'use Test::mysqld; 1'
      or plan skip_all => "Test::mysqld required to run these tests";

    eval { $self->database }
      or plan skip_all => "Init database failed: $@";
}

my $tmpdir = tempdir(
    CLEANUP  => 1,
    TEMPLATE => 'ic6s_test_XXXXX',
    TMPDIR   => 1,
);

sub _build_database {
    my $self = shift;
    no warnings 'once';    # prevent: "Test::mysqld::errstr" used only once
    my $mysqld = Test::mysqld->new(
        base_dir => $tmpdir,
        my_cnf => {
            'character-set-server' => 'utf8',
            'collation-server'     => 'utf8_unicode_ci',
            'skip-networking'      => '',
        }
    ) or die $Test::mysqld::errstr;
    return $mysqld;
}

sub _build_dbd_version {
    my $self = shift;
    return
        "DBD::mysql $DBD::mysql::VERSION Test::mysqld "
      . "$Test::mysqld::VERSION mysql_clientversion "
      . $self->ic6s_schema->storage->dbh->{mysql_clientversion};
}

=head2 connect_info

Returns appropriate DBI connect info for this role.

=cut

sub connect_info {
    my $self = shift;
    return (
        $self->database->dsn( dbname => 'test' ),
        undef, undef,
        {
            mysql_enable_utf8 => 1,
            on_connect_call => 'set_strict_mode',
            quote_names => 1,
        }
    );
}

sub _build_database_info {
    my $self = shift;
    $self->ic6s_schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $variables = $dbh->selectall_arrayref(q(SHOW VARIABLES));
            my @info = map { $_->[0] =~ s/_server//; "$_->[0]=$_->[1]" } grep {
                $_->[0] =~ /^(version|character_set_server|collation_server)/
                  && $_->[0] !~ /compile/
            } @$variables;
            use DBI::Const::GetInfoType;
            push @info, $dbh->get_info( $GetInfoType{SQL_DBMS_VER} );
            return join( " ", @info );
        }
    );
}

1;
