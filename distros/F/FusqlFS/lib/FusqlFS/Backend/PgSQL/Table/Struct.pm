use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Table::Struct;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

sub init
{
    my $self = shift;

    $self->{list_expr} = $self->expr("SELECT attname FROM pg_catalog.pg_attribute as a
                WHERE attrelid = (SELECT oid FROM pg_catalog.pg_class as c WHERE c.relname = ? AND relkind = 'r') AND attnum > 0
            ORDER BY attnum");
    $self->{get_expr} = $self->expr("SELECT pg_catalog.format_type(atttypid, atttypmod) AS type,
                NOT attnotnull as nullable,
                CASE WHEN atthasdef THEN
                    (SELECT pg_catalog.pg_get_expr(adbin, adrelid) FROM pg_attrdef as d
                        WHERE adrelid = attrelid AND adnum = attnum)
                ELSE NULL END AS default,
                attndims AS dimensions,
                attnum as order
            FROM pg_catalog.pg_attribute as a
            WHERE attrelid = (SELECT oid FROM pg_catalog.pg_class as c WHERE c.relname = ? AND relkind = 'r')
                AND attname = ?");

    $self->{drop_expr} = 'ALTER TABLE "%s" DROP COLUMN "%s"';
    $self->{create_expr} = 'ALTER TABLE "%s" ADD COLUMN "%s" INTEGER NOT NULL DEFAULT \'0\'';
    $self->{rename_expr} = 'ALTER TABLE "%s" RENAME COLUMN "%s" TO "%s"';

    $self->{store_default_expr} = 'ALTER TABLE "%s" ALTER COLUMN "%s" SET DEFAULT %s';
    $self->{drop_default_expr} = 'ALTER TABLE "%s" ALTER COLUMN "%s" DROP DEFAULT';
    $self->{set_nullable_expr} = 'ALTER TABLE "%s" ALTER COLUMN "%s" DROP NOT NULL';
    $self->{drop_nullable_expr} = 'ALTER TABLE "%s" ALTER COLUMN "%s" SET NOT NULL';
    $self->{store_type_expr} = 'ALTER TABLE "%s" ALTER COLUMN "%s" TYPE %s';
}

=begin testing list

is $_tobj->list('unknown'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'id' ];

=end testing
=cut
sub list
{
    my $self = shift;
    my ($table) = @_;
    my $list = $self->all_col($self->{list_expr}, $table);
    return unless @$list;
    return $list;
}

=begin testing get

is $_tobj->get('fusqlfs_table', 'unknown'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'id'), {
    default => "nextval('fusqlfs_table_id_seq'::regclass)",
    dimensions => 0,
    nullable => 0,
    order => 1,
    type => 'integer',
};

=end testing
=cut
sub get
{
    my $self = shift;
    my ($table, $name) = @_;
    my $result = $self->one_row($self->{get_expr}, $table, $name);
    return $self->dump($result);
}

=begin testing drop after rename

isnt $_tobj->drop('fusqlfs_table', 'new_field'), undef;
is $_tobj->get('fusqlfs_table', 'new_field'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'id', '........pg.dropped.2........' ];

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->do($self->{drop_expr}, [$table, $name]);
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_table', 'field'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'id', 'field' ];
is_deeply $_tobj->get('fusqlfs_table', 'field'), {
    default => 0,
    dimensions => 0,
    nullable => 0,
    order => 2,
    type => 'integer',
};

=end testing
=cut
sub create
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->do($self->{create_expr}, [$table, $name]);
}

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_table', 'field', 'new_field'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'id', 'new_field' ];
is $_tobj->get('fusqlfs_table', 'field'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'new_field'), $new_field;

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    $self->do($self->{rename_expr}, [$table, $name, $newname]);
}

=begin testing store after create

isnt $_tobj->store('fusqlfs_table', 'field', $new_field), undef;
is_deeply $_tobj->get('fusqlfs_table', 'field'), $new_field;

=end testing
=cut
sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    $data = $self->validate($data, {
		type       => '',
		dimensions => qr/^\d+$/,
		default    => '',
		nullable   => '',
	}) or return;

    my $newtype = $data->{'type'};
    $newtype =~ s/(\[\])+$//;
    $newtype .= '[]' x $data->{'dimensions'};

    my $using = $data->{'using'} || undef;
    $newtype .= " USING $using" if $using;

    $self->do($self->{store_type_expr}, [$table, $name, $newtype]);

    if (defined $data->{'default'}) {
        $self->do($self->{store_default_expr}, [$table, $name, $data->{'default'}]);
    } else {
        $self->do($self->{drop_default_expr}, [$table, $name]);
    }
    $self->do($self->{$data->{'nullable'}? 'set_nullable_expr': 'drop_nullable_expr'}, [$table, $name]);
    return 1;
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_field = {
    default => "''::character varying",
    dimensions => 0,
    nullable => 1,
    order => 2,
    type => 'character varying(255)',
};

=end testing
=cut
