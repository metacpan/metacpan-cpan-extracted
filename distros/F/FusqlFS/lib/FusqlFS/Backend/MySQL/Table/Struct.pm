use strict;
use 5.010;

package FusqlFS::Backend::MySQL::Table::Struct;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use base 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::MySQL::Table::Struct

=head1 SYNOPSIS

    Synopsis

=head1 DESCRIPTION

Description

=cut

sub init
{
    my $self = shift;

    $self->{list_expr} = 'SHOW COLUMNS FROM `%s`';
    $self->{get_expr} = 'SHOW FULL COLUMNS FROM `%s` LIKE "%s"';
    $self->{get_create_expr} = 'SHOW CREATE TABLE `%s`';

    $self->{create_expr} = 'ALTER TABLE `%s` ADD COLUMN `%s` INT NOT NULL DEFAULT 0';
    $self->{rename_expr} = 'ALTER TABLE `%s` CHANGE COLUMN `%s` `%s` %s';
    $self->{store_expr} = 'ALTER TABLE `%s` MODIFY COLUMN `%s` %s';
    $self->{drop_expr} = 'ALTER TABLE `%s` DROP COLUMN `%s`';
    $self->{default_expr} = 'ALTER TABLE `%s` ALTER COLUMN `%s` %s DEFAULT %s';
}

sub build_column_def
{
    my $data = shift;
    return sprintf('%s %s %s NULL %s %s',
            $data->{type},
            $data->{collation}? 'COLLATE '.$data->{collation}: '',
            $data->{null}? '': 'NOT',
            #defined $data->{default}? $data->{default}: 'NULL',
            $data->{extra},
            $data->{comment}? "COMMENT '$data->{comment}'": '');
}

=begin testing list

is $_tobj->list('unknown'), undef, 'Unknown table';
cmp_set $_tobj->list('fusqlfs_table'), ['id', 'create.sql'], 'Test table listable';

=end testing
=cut
sub list
{
    my $self = shift;
    my ($table) = @_;
    my $list = $self->all_col($self->{list_expr}, [$table]);
    return unless $list && @$list;

    push @$list, 'create.sql';
    return $list
}

=begin testing get

is $_tobj->get('fusqlfs_table', 'unknown'), undef, 'Unknown field';
is_deeply $_tobj->get('fusqlfs_table', 'id'), {
    collation => undef,
    comment => '',
    default => undef,
    extra => 'auto_increment',
    key => 'PRI',
    null => 0,
    privileges => [
        'select',
        'insert',
        'update',
        'references',
    ],
    type => 'int(11)',
}, 'Known field';

=end testing
=cut
sub get
{
    my $self = shift;
    my ($table, $name) = @_;

    if ($name eq 'create.sql')
    {
        return $self->one_row($self->{get_create_expr}, [$table])->{'Create Table'};
    }

    my $result = $self->one_row($self->{get_expr}, [$table, $name]);
    if ($result)
    {
        $result = { map { lc($_) => $result->{$_} } grep { $_ ne 'Field' } keys %$result };
        $result->{privileges} = [ split /,/, $result->{privileges} ];
        $result->{null} = $result->{null} eq 'YES'? 1: 0;
        return $self->dump($result);
    }
    return;
}

=begin testing drop after rename

isnt $_tobj->drop('fusqlfs_table', 'new_field'), undef, 'Field is dropped';
is $_tobj->get('fusqlfs_table', 'new_field'), undef, 'Field is not gettable';
is_deeply $_tobj->list('fusqlfs_table'), ['id', 'create.sql'], 'Field is not listable';

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->do($self->{drop_expr}, [$table, $name]);
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_table', 'field'), undef, 'Create field';
is_deeply $_tobj->get('fusqlfs_table', 'field'), $new_field, 'New field exists';
is_deeply $_tobj->list('fusqlfs_table'), ['id', 'field', 'create.sql'], 'New field is listable';

=end testing
=cut
sub create
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->do($self->{create_expr}, [$table, $name]);
}

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_table', 'field', 'new_field'), undef, 'Field renamed';
is $_tobj->get('fusqlfs_table', 'field'), undef, 'New field is unaccessible by old name';
is_deeply $_tobj->get('fusqlfs_table', 'new_field'), $new_field, 'New field exists';
is_deeply $_tobj->list('fusqlfs_table'), ['id', 'new_field', 'create.sql'], 'New field is listable';

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    my $field = $self->one_row($self->{get_expr}, [$table, $name]);
    return unless $field;

    my $fielddef = build_column_def({ map { lc($_) => $field->{$_} } keys %$field });
    $self->do($self->{rename_expr}, [$table, $name, $newname, $fielddef]);
    $self->do($self->{default_expr}, [$table, $newname,
        defined $field->{Default}? 'SET': 'DROP', $field->{Default}]);
}

=begin testing store after create

$new_field->{type} = 'varchar(255)';
$new_field->{default} = undef;
$new_field->{collation} = 'utf8_general_ci';
$new_field->{null} = 1;
isnt $_tobj->store('fusqlfs_table', 'field', $new_field), undef, 'Field changed';
is_deeply $_tobj->get('fusqlfs_table', 'field'), $new_field, 'Field changed correctly';

=end testing
=cut
sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    $data = $self->validate($data, {
		type      => '',
		null      => qr/^\d$/,
		extra     => '',
		collation => '',
		default   => '',
                comment   => '',
	}) or return;
    my $fielddef = build_column_def($data);
    $self->do($self->{store_expr}, [$table, $name, $fielddef]);
    $self->do($self->{default_expr}, [$table, $name,
        defined $data->{default}? 'SET': 'DROP', $data->{default}]);
}
1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::MySQL::Table::Test

my $new_field = {
    collation => undef,
    comment => '',
    default => 0,
    extra => '',
    key => '',
    null => 0,
    privileges => [
        'select',
        'insert',
        'update',
        'references',
    ],
    type => 'int(11)',
};

=end testing
=cut
