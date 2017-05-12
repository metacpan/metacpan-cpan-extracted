use strict;
use 5.010;

package FusqlFS::Backend::SQLite::Table::Indices;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

sub init
{
    my $self = shift;
    $self->{list_expr} = $self->expr('SELECT name FROM sqlite_master WHERE type = "index" AND tbl_name = ?');
    $self->{get_expr} = $self->expr('SELECT sql, rootpage FROM sqlite_master WHERE type = "index" AND tbl_name = ? AND name = ?');
}

sub list
{
    my $self = shift;
    my $table = shift;
    return $self->all_col($self->{list_expr}, $table);
}

sub get
{
    my $self = shift;
    my ($table, $name) = @_;
    my $data = $self->one_row($self->{get_expr}, $table, $name);
    return unless $data;

    $data->{sql} ||= '';
    return $data;
}

1;
