use strict;
use 5.010;

package FusqlFS::Backend::SQLite::Tables;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::SQLite::Tables - FusqlFS SQLite database tables interface

=head1 SYNOPSIS

    use FusqlFS::Backend::SQLite::Tables;

    my $tables = FusqlFS::Backend::SQLite::Tables->new();
    my $list = $tables->list();

=head1 DESCRIPTION

This is FusqlFS an interface to SQLite database tables. This class is not
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

Table's indices, see L<FusqlFS::Backend::SQLite::Table::Indices> for details.

=item F<./struct>

Table's structure, see L<FusqlFS::Backend::SQLite::Table::Struct> for details.

=item F<./constraints>

Table's foreign keys, see L<FusqlFS::Backend::SQLite::Table::Constraints> for details.

=item F<./triggers>

Table's triggers, see L<FusqlFS::Backend::SQLite::Table::Triggers> for details.

=item F<./data>

Table's data, see L<FusqlFS::Backend::SQLite::Table::Data> for details.

=back

=cut

sub init
{
    my $self = shift;
    $self->{list_expr} = $self->expr('SELECT name FROM sqlite_master WHERE type = "table"');
    $self->{get_expr} = $self->expr('SELECT 1 FROM sqlite_master WHERE type = "table" AND name = ?');

    $self->{rename_expr} = 'ALTER TABLE %s RENAME TO %s';
    $self->{drop_expr} = 'DROP TABLE %s';
    $self->{create_expr} = 'CREATE TABLE %s (id INT)';

    $self->autopackages('indices', 'data', 'struct'); # 'constraints', 'triggers'
}

=begin testing list

cmp_set $_tobj->list(), [], 'Tables list is sane';

=end testing
=cut
sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr});
}

=begin testing get

is $_tobj->get('fusqlfs_table'), undef, 'Test table doesn\'t exist';

=end testing
=cut
sub get
{
    my $self = shift;
    return $self->one_row($self->{get_expr}, $_[0]) && $self->{subpackages};
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
    my ($table, $newtable) = @_;
    $self->do($self->{rename_expr}, [$table, $newtable]);
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
    my ($table) = @_;
    $self->do($self->{drop_expr}, [$table]);
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
    my ($table) = @_;
    $self->do($self->{create_expr}, [$table]);
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::SQLite::Test

=end testing

