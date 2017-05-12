use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Tables;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::PgSQL::Tables - FusqlFS PostgreSQL database tables interface

=head1 SYNOPSIS

    use FusqlFS::Backend::PgSQL::Tables;

    my $tables = FusqlFS::Backend::PgSQL::Tables->new();
    my $list = $tables->list();
    $tables->create('sometable');
    my $table = $tables->get('sometable');
    $tables->drop('sometable');

=head1 DESCRIPTION

This is FusqlFS an interface to PostgreSQL database tables. This class is not
to be used by itself.

This class provides a view of a set of different table's artifacts like
indices, struct (fields description), data rows/records, constraints, triggers
etc.

See L<FusqlFS::Artifact> for description of interface methods,
L<FusqlFS::Backend> to learn more on backend initialization and
L<FusqlFS::Backend::Base> for more info on database backends writing.

=head1 EXPOSED STRUCTURE

=over

=item F<./indices>

Table's indices, see L<FusqlFS::Backend::PgSQL::Table::Indices> for details.

=item F<./struct>

Table's structure, see L<FusqlFS::Backend::PgSQL::Table::Struct> for details.

=item F<./constraints>

Table's constraints, see L<FusqlFS::Backend::PgSQL::Table::Constraints> for details.

=item F<./triggers>

Table's triggers, see L<FusqlFS::Backend::PgSQL::Table::Triggers> for details.

=item F<./owner>

Symlink to table's owner role in F<../../roles>.

=item F<./acl>

Table's ACL with permissions given to different roles. See
L<FusqlFS::Backend::PgSQL::Role::Acl> for details.

=back

=cut

use FusqlFS::Backend::PgSQL::Role::Owner;
use FusqlFS::Backend::PgSQL::Role::Acl;

sub init
{
    my $self = shift;
    $self->{rename_expr} = 'ALTER TABLE "%s" RENAME TO "%s"';
    $self->{drop_expr} = 'DROP TABLE "%s"';
    $self->{create_expr} = 'CREATE TABLE "%s" (id serial, PRIMARY KEY (id))';

    $self->{list_expr} = $self->expr("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'");
    $self->{get_expr} = $self->expr("SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND tablename = ?");

    $self->extend(
        $self->autopackages(
            'indices',
            'struct',
            'data',
            'constraints',
            'triggers'
        ), {
            owner => FusqlFS::Backend::PgSQL::Role::Owner->new('r'),
            acl   => FusqlFS::Backend::PgSQL::Role::Acl->new('r'),
        }
    );
}

=begin testing get

is $_tobj->get('fusqlfs_table'), undef, 'Test table doesn\'t exist';

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name) = @_;
    my $result = $self->all_col($self->{get_expr}, $name);
    return unless @$result;
    return $self->{subpackages};
}

=begin testing drop after rename

isnt $_tobj->drop('new_fusqlfs_table'), undef, 'Table dropped';
is $_tobj->get('new_fusqlfs_table'), undef, 'Table dropped correctly';
is_deeply $_tobj->list(), [], 'Tables list is empty';

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{drop_expr}, [$name]);
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_table'), undef, 'Table created';
is_deeply $_tobj->get('fusqlfs_table'), $_tobj->{subpackages}, 'New table is sane';
is_deeply $_tobj->list(), [ 'fusqlfs_table' ], 'New table is listed';

=end testing
=cut
sub create
{
    my $self = shift;
    my ($name) = @_;
    $self->do($self->{create_expr}, [$name]);
}

=begin testing rename after create

isnt $_tobj->rename('fusqlfs_table', 'new_fusqlfs_table'), undef, 'Table renamed';
is $_tobj->get('fusqlfs_table'), undef, 'Table is unaccessable under old name';
is_deeply $_tobj->get('new_fusqlfs_table'), $_tobj->{subpackages}, 'Table renamed correctly';
is_deeply $_tobj->list(), [ 'new_fusqlfs_table' ], 'Table is listed under new name';

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    $self->do($self->{rename_expr}, [$name, $newname]);
}

=begin testing list

cmp_set $_tobj->list(), [], 'Tables list is sane';

=end testing
=cut
sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr}) || [];
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Test

=end testing
