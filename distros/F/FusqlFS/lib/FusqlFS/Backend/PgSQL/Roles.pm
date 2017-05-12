use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Roles;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Test

my $new_role = {
    struct => {
        can_login => 1,
        cat_update => 1,
        config => undef,
        conn_limit => 1,
        create_db => 1,
        create_role => 1,
        inherit => 0,
        superuser => 1,
        valid_until => '2010-01-01 00:00:00+02',
    },
    postgres => \"roles/postgres",
    owned => $_tobj->{owned},
};

=end testing
=cut

use DBI qw(:sql_types);
use FusqlFS::Backend::PgSQL::Role::Owned;

sub init
{
    my $self = shift;

    $self->{list_expr} = $self->expr("SELECT rolname FROM pg_catalog.pg_roles");
    $self->{get_expr} = $self->expr("SELECT r.rolcanlogin AS can_login, r.rolcatupdate AS cat_update, r.rolconfig AS config,
            r.rolconnlimit AS conn_limit, r.rolcreatedb AS create_db, r.rolcreaterole AS create_role, r.rolinherit AS inherit,
            r.rolsuper AS superuser, r.rolvaliduntil AS valid_until,
            ARRAY(SELECT b.rolname FROM pg_catalog.pg_roles AS b
                    JOIN pg_catalog.pg_auth_members AS m ON (m.member = b.oid)
                WHERE m.roleid = r.oid) AS contains
        FROM pg_catalog.pg_roles AS r WHERE rolname = ?");

    $self->{create_expr} = 'CREATE ROLE "%s"';
    $self->{rename_expr} = 'ALTER ROLE "%s" RENAME TO "%s"';
    $self->{drop_expr} = 'DROP ROLE "%s"';

    $self->{revoke_expr} = 'REVOKE "%s" FROM "%s"';
    $self->{grant_expr} = 'GRANT "%s" TO "%s"';

    $self->{owned} = FusqlFS::Backend::PgSQL::Role::Owned->new();
}

=begin testing get

is $_tobj->get('unknown'), undef, 'Unknown role not exists';
is_deeply $_tobj->get('postgres'), { struct => {
    can_login => 1,
    cat_update => 1,
    config => undef,
    conn_limit => '-1',
    create_db => 1,
    create_role => 1,
    inherit => 1,
    superuser => 1,
    valid_until => undef,
},
owned => $_tobj->{owned},
}, 'Known role is sane';

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name) = @_;

    my $data = $self->one_row($self->{get_expr}, $name);
    return unless $data;

    my $result = { map { $_ => \"roles/$_" } @{delete($data->{contains})} };

    $result->{struct} = $self->dump($data);
    $result->{owned}  = $self->{owned};
    return $result;
}

=begin testing list

cmp_deeply $_tobj->list(), supersetof('postgres'), 'Roles list is sane';

=end testing
=cut
sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr})||[];
}

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_test', 'new_fusqlfs_test'), undef, 'Role renamed';
is_deeply $_tobj->get('new_fusqlfs_test'), $new_role, 'Role renamed correctly';
is $_tobj->get('fusqlfs_test'), undef, 'Role is unaccessable under old name';
my $list = $_tobj->list();
ok grep { $_ eq 'new_fusqlfs_test' } @$list;
ok !grep { $_ eq 'fusqlfs_test' } @$list;

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    $self->do($self->{rename_expr}, [$name, $newname]);
}

=begin testing drop after rename

isnt $_tobj->drop('new_fusqlfs_test'), undef, 'Role deleted';
is $_tobj->get('new_fusqlfs_test'), undef, 'Deleted role is absent';
my $list = $_tobj->list();
ok !grep { $_ eq 'new_fusqlfs_test' } @$list;

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{drop_expr}, [$name]);
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_test'), undef, 'Role created';
is_deeply $_tobj->get('fusqlfs_test')->{struct}, {
    can_login => 0,
    cat_update => 0,
    config => undef,
    conn_limit => '-1',
    create_db => 0,
    create_role => 0,
    inherit => 1,
    superuser => 0,
    valid_until => undef,
}, 'New role is sane';

my $list = $_tobj->list();
ok grep { $_ eq 'fusqlfs_test' } @$list;

=end testing
=cut
sub create
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{create_expr}, [$name]);
}

=begin testing store after create

isnt $_tobj->store('fusqlfs_test', $new_role), undef, 'Role saved';
is_deeply $_tobj->get('fusqlfs_test'), $new_role, 'Role saved correctly';

=end testing
=cut
sub store
{
    my $self = shift;
    my ($name, $data) = @_;
    my $struct = $self->validate($data, {
        struct => {
            -superuser   => '',
            -create_db   => '',
            -create_role => '',
            -inherit     => '',
            -can_login   => '',
            -conn_limit  => qr/^\d+$/,
            -valid_until => '',
            -password    => '',
        },
    }, sub{
        $_->{contains} = [ grep ref $data->{$_} eq 'SCALAR', keys %{$_[0]} ];
        return 1;
    }) or return;

    my $olddata = $self->one_row($self->{get_expr}, $name);
    my ($grant, $revoke) = $self->adiff($olddata->{contains}, $struct->{contains});

    $self->do($self->{revoke_expr}, [$name, $_]) foreach @$revoke;
    $self->do($self->{grant_expr},  [$name, $_]) foreach @$grant;

    $data = $self->load($data->{struct})||{};

    my $sth = $self->build("ALTER ROLE \"$name\" ", sub{
            my ($a, $b) = @_;
            if (ref $b)
            {
                return unless $data->{$a};
                return "$b->[0] ? ", $data->{$a}, $b->[1];
            }
            else
            {
                return unless exists $data->{$a};
                return ($data->{$a}? '': 'NO') . "$b ";
            }
    }, superuser   => 'SUPERUSER' ,
       create_db   => 'CREATEDB'  ,
       create_role => 'CREATEROLE',
       inherit     => 'INHERIT'   ,
       can_login   => 'LOGIN'     ,
       conn_limit  => ['CONNECTION LIMIT', SQL_INTEGER],
       valid_until => ['VALID UNTIL', SQL_TIMESTAMP]   ,
       password    => ['PASSWORD', SQL_VARCHAR]        );

    $sth->execute();
}

1;

