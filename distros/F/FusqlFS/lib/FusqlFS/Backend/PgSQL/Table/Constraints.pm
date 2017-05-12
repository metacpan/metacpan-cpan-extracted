use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Table::Constraints;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Lazy';

sub init
{
    my $self = shift;

    $self->{get_expr} = $self->expr('SELECT pg_catalog.pg_get_constraintdef(co.oid, true) AS "content.sql", co.contype AS ".type" FROM pg_catalog.pg_constraint co
            JOIN pg_catalog.pg_class AS cl ON (cl.oid = co.conrelid) WHERE cl.relname = ? AND co.conname = ?');
    $self->{list_expr} = $self->expr('SELECT co.conname FROM pg_catalog.pg_constraint AS co
            JOIN pg_catalog.pg_class AS cl ON (cl.oid = co.conrelid) WHERE cl.relname = ?');

    $self->{drop_expr} = 'ALTER TABLE "%s" DROP CONSTRAINT "%s"';
    $self->{store_expr} = 'ALTER TABLE "%s" ADD CONSTRAINT "%s" %s';

    $self->{template} = { 'content.sql' => "" };
}

=begin testing store after create

isnt $_tobj->store('fusqlfs_table', 'fusqlfs_constraint', $new_constraint), undef;
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), $new_constraint;

=end testing
=cut
sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    $self->drop($table, $name);
    $self->do($self->{store_expr}, [$table, $name, $data->{'content.sql'}]);
}

=begin testing rename after store

isnt $_tobj->rename('fusqlfs_table', 'fusqlfs_constraint', 'new_fusqlfs_constraint'), undef;
is $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'new_fusqlfs_constraint'), $new_constraint;
is_deeply [ sort(@{$_tobj->list('fusqlfs_table')}) ], [ sort('fusqlfs_table_pkey', 'new_fusqlfs_constraint') ];

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    unless ($self->SUPER::rename($table, $name, $newname))
    {
        my $data = $self->get($table, $name);
        $self->drop($table, $name);
        $self->store($table, $newname, $data);
    }
}

=begin testing create after get list

isnt $_tobj->create('fusqlfs_table', 'fusqlfs_constraint'), undef;
isnt $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), $_tobj->{template};
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), $_tobj->{template};
is_deeply [ sort(@{$_tobj->list('fusqlfs_table')}) ], [ sort('fusqlfs_table_pkey', 'fusqlfs_constraint') ];

=end testing
=cut

=begin testing drop after rename

isnt $_tobj->drop('fusqlfs_table', 'new_fusqlfs_constraint'), undef;
is $_tobj->get('fusqlfs_table', 'new_fusqlfs_constraint'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->SUPER::drop($table, $name) or $self->do($self->{drop_expr}, [$table, $name]);
}

=begin testing get

is $_tobj->get('fusqlfs_table', 'unknown'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_table_pkey'), { 'content.sql' => 'PRIMARY KEY (id)', '.type' => 'p' };

=end testing
=cut
sub get
{
    my $self = shift;
    my ($table, $name) = @_;
    unless ($self->SUPER::get($table, $name))
    {
        my $data = $self->one_row($self->{get_expr}, $table, $name);
        return unless $data;
        if ($data->{".type"} eq 'f')
        {
            my ($myfields, $table, $herfields) = ($data->{'content.sql'} =~ /KEY \((.+?)\) REFERENCES (.+?)\((.+?)\)/);
            my @myfields = split /,/, $myfields;
            my @herfields = split /,/, $herfields;
            foreach (0..$#myfields)
            {
                $data->{$myfields[$_]} = \"tables/$table/struct/$herfields[$_]";
            }
        }
        return $data;
    }
}

=begin testing list

#is $_tobj->list('unknown'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];

=end testing
=cut
sub list
{
    my $self = shift;
    my ($table) = @_;
    my @list = @{$self->SUPER::list($table)};
    return [ @{$self->all_col($self->{list_expr}, $table)}, @list ];
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_constraint = {
    'content.sql' => 'CHECK (id > 5)',
    '.type' => 'c',
};

=end testing
=cut
