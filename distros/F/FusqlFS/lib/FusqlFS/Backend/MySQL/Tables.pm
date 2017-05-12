use strict;
use 5.010;

package FusqlFS::Backend::MySQL::Tables;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::MySQL::Tables - FusqlFS MySQL database tables interface

=head1 SYNOPSIS

    use FusqlFS::Backend::MySQL::Tables;

    my $tables = FusqlFS::Backend::MySQL::Tables->new();
    my $list = $table->list();
    $tables->create('sometable');
    my $table = $tables->get('sometable');
    $tables->drop('sometable');

=head1 DESCRIPTION

This is FusqlFS interface to MySQL database tables. This class is not
to be used by itself.

See L<FusqlFS::Backend::PgSQL::Tables> for details.

=cut

sub init
{
    my $self = shift;
    $self->{rename_expr} = 'ALTER TABLE `%s` RENAME TO `%s`';   
    $self->{drop_expr} = 'DROP TABLE `%s`';
    $self->{create_expr} = 'CREATE TABLE `%s` (id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id))';

    $self->{list_expr} = 'SHOW TABLES';
    $self->{get_expr} = 'SHOW TABLES LIKE "%s"';

    $self->autopackages(
        'struct',
        'data',
        'indices',
        'triggers');
}

=begin testing get

is $_tobj->get('fusqlfs_table'), undef, 'Test table doesn\'t exist';

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name) = @_;
    my $result = $self->all_col($self->{get_expr}, [$name]);
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
is_deeply $_tobj->list(), ['fusqlfs_table'], 'New table is listed';

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
is $_tobj->get('fusqlfs_table'), undef, 'Table is unaccessible under old name';
is_deeply $_tobj->get('new_fusqlfs_table'), $_tobj->{subpackages}, 'Table renamed correctly';
is_deeply $_tobj->list(), ['new_fusqlfs_table'], 'Table is listed under new name';

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    $self->do($self->{rename_expr}, [$name, $newname]);
}

=begin testing list

is_deeply $_tobj->list(), [], 'Tables list is sane';

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

#!class FusqlFS::Backend::MySQL::Test

=end testing
