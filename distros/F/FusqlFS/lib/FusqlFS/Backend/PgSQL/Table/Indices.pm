use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Table::Indices;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Lazy';

use FusqlFS::Backend::PgSQL::Table::Struct;

sub init
{
    my $self = shift;

    $self->{rename_expr} = 'ALTER INDEX "%s" RENAME TO "%s"';
    $self->{drop_expr} = 'DROP INDEX "%s"';
    $self->{create_expr} = 'CREATE %s INDEX "%s" ON "%s" (%s)';

    $self->{list_expr} = $self->expr("SELECT (SELECT c1.relname FROM pg_catalog.pg_class as c1 WHERE c1.oid = indexrelid) as Index_name
        FROM pg_catalog.pg_index
            WHERE indrelid = (SELECT oid FROM pg_catalog.pg_class as c WHERE c.relname = ? AND relkind = 'r')");
    $self->{get_expr} = $self->expr("SELECT pg_get_indexdef(indexrelid, 0, true) AS \"create.sql\",
            indisunique as \".unique\", indisprimary as \".primary\", indkey as \".order\"
        FROM pg_catalog.pg_index
            WHERE indexrelid = (SELECT oid FROM pg_catalog.pg_class as c WHERE c.relname = ? AND relkind = 'i')");

    $self->{template} = { '.order' => [] };
}

=begin testing get

is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_table_pkey'), {
    '.primary' => 1,
    '.unique'  => 1,
    '.order'   => [ 'id' ],
    'id'       => \'tables/fusqlfs_table/struct/id',
    'create.sql' => 'CREATE UNIQUE INDEX fusqlfs_table_pkey ON fusqlfs_table USING btree (id)',
};
is $_tobj->get('fusqlfs_table', 'fusqlfs_index'), undef;

=end testing
=cut
sub get
{
    my $self = shift;
    my ($table, $name) = @_;

    unless ($self->SUPER::get($table, $name))
    {
        my $result = $self->one_row($self->{get_expr}, $name);
        return unless $result;
        if ($result->{'.order'})
        {
            my @fields = @{FusqlFS::Backend::PgSQL::Table::Struct->new()->list($table)};
            $result->{'.order'} = [ map { $fields[$_-1] } split / /, $result->{'.order'} ];
            $result->{$_} = \"tables/$table/struct/$_" foreach @{$result->{'.order'}};
        }
        delete $result->{'.unique'} unless $result->{'.unique'};
        delete $result->{'.primary'} unless $result->{'.primary'};
        return $result;
    }
}

=begin testing list

cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];

=end testing
=cut
sub list
{
    my $self = shift;
    my ($table) = @_;
    my @list = @{$self->SUPER::list($table)};
    return [ (@{$self->all_col($self->{list_expr}, $table)}, @list) ];
}

=begin testing drop after rename

isnt $_tobj->drop('fusqlfs_table', 'new_fusqlfs_index'), undef;
is $_tobj->get('fusqlfs_table', 'new_fusqlfs_index'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->SUPER::drop($table, $name) or $self->do($self->{drop_expr}, [$name]);
}

=begin testing store after create

ok $_tobj->store('fusqlfs_table', 'fusqlfs_index', $new_index);
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_index'), $new_index;
is_deeply [ sort(@{$_tobj->list('fusqlfs_table')}) ], [ sort('fusqlfs_table_pkey', 'fusqlfs_index') ];

=end testing
=cut
sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;

    $self->drop($table, $name);
    my $fields = $self->parse_fields($data);
    my $unique = defined $data->{'.unique'}? 'UNIQUE': '';
    $self->do($self->{create_expr}, [$unique, $name, $table, $fields]);
}

sub parse_fields
{
    my $self = shift;
    my ($data) = @_;
    my @order = grep { exists $data->{$_} } @{$data->{'.order'}};
    my @fields = grep { !/^\./ && $_ ne 'create.sql' } keys %$data;

    my %order = map { $_ => 1 } @order;
    foreach (@fields)
    {
        push @order, $_ unless exists $order{$_};
    }
    my $fields = '"'.join('", "', @order).'"';

    return $fields;
}

=begin testing create after get list

ok $_tobj->create('fusqlfs_table', 'fusqlfs_index');
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_index'), {
    '.order' => [],
};
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey', 'fusqlfs_index' ];

=end testing
=cut

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_table', 'fusqlfs_index', 'new_fusqlfs_index'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey', 'new_fusqlfs_index' ];
is $_tobj->get('fusqlfs_table', 'fusqlfs_index'), undef;

$new_index->{'create.sql'} =~ s/INDEX fusqlfs_index ON/INDEX new_fusqlfs_index ON/;
is_deeply $_tobj->get('fusqlfs_table', 'new_fusqlfs_index'), $new_index;

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    $self->SUPER::rename($table, $name, $newname) or $self->do($self->{rename_expr}, [$name, $newname]);
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_index = { 'id' => \'tables/fusqlfs_table/struct/id', '.order' => [ 'id' ], '.unique' => 1,
    'create.sql' => 'CREATE UNIQUE INDEX fusqlfs_index ON fusqlfs_table USING btree (id)' };

=end testing
