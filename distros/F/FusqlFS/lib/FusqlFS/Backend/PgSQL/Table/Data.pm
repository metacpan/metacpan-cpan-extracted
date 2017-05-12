use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Table::Data;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Data';

use FusqlFS::Backend::PgSQL::Table::Struct;

sub init
{
    my $self = shift;
    $self->SUPER::init();

    $self->{get_primary_expr} = $self->expr("SELECT indkey FROM pg_catalog.pg_index
            WHERE indisprimary AND indrelid = (SELECT oid FROM pg_catalog.pg_class as c WHERE c.relname = ? AND relkind = 'r')");
}

=begin testing list

cmp_set $_tobj->list('fusqlfs_table'), [];

=end testing
=cut

=begin testing get

is $_tobj->get('fusqlfs_table', '1'), undef;

=end testing
=cut

=begin testing drop after rename

isnt $_tobj->drop('fusqlfs_table', '2'), undef;
is $_tobj->get('fusqlfs_table', '2'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [];

=end testing
=cut

=begin testing create after get list

ok $_tobj->create('fusqlfs_table', '1');
is_deeply $_tobj->get('fusqlfs_table', '1'), { id => 1 };
is_deeply $_tobj->list('fusqlfs_table'), [ 1 ];

=end testing
=cut

=begin testing rename after create

isnt $_tobj->rename('fusqlfs_table', '1', '2'), undef;
is $_tobj->get('fusqlfs_table', '1'), undef;
is_deeply $_tobj->get('fusqlfs_table', '2'), { id => 2 };
is_deeply $_tobj->list('fusqlfs_table'), [ 2 ];

=end testing
=cut

sub get_primary_key
{
    my $self = shift;
    my ($table) = @_;
    my @result = ();
    my $data = $self->all_col($self->{get_primary_expr}, $table);
    if ($data)
    {
        my $fields = FusqlFS::Backend::PgSQL::Table::Struct->new()->list($table);
        @result = map { $fields->[$_-1] } split / /, $data->[0];
    }
    return @result;
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Table::Test

=end testing
