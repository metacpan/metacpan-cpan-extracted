use strict;
use 5.010;

package FusqlFS::Artifact::Table::Data;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

sub init
{
    my $self = shift;

    $self->{query_cache} = {};
    $self->{field_quote} = '"';
}

sub list
{
    my $self = shift;
    my ($table) = @_;
    my @primary_key = $self->get_key_fields($table);
    return undef unless @primary_key;

    my $sth = $self->cexpr('SELECT %s FROM %s %s', $self->concat(@primary_key), $self->{field_quote}.$table.$self->{field_quote}, $self->limit);
    return $self->all_col($sth)||[];
}

sub where_clause
{
    my $self = shift;
    my ($table, $name) = @_;
    my @binds = $self->asplit($name);
    my @primary_key = $self->get_key_fields($table);
    return unless @primary_key && $#primary_key == $#binds;

    return $self->pairs(' AND ', @primary_key), @binds;
}

=item pairs

Composes fields into pairs, suitable for UPDATE query or the like.

Input: $glue, @fields.
Output: $sql_clause.

=cut
sub pairs
{
    my ($self, $glue, @fields) = @_;
    my $q = $self->{field_quote};
    return join($glue, map { "$q$_$q = ?" } @fields);
}

sub get
{
    my $self = shift;
    my ($table, $name) = @_;
    my ($where_clause, @binds) = $self->where_clause($table, $name);
    my $qtable = $self->{field_quote}.$table.$self->{field_quote};
    return unless $where_clause || @binds;

    $self->{query_cache}->{$table} ||= {};
    $self->{query_cache}->{$table}->{$where_clause} ||= $where_clause?
                $self->expr('SELECT * FROM %s WHERE %s LIMIT 1', $qtable, $where_clause):
                $self->expr('SELECT * FROM %s %s', $qtable, $self->limit);

    my $sth = $self->{query_cache}->{$table}->{$where_clause};
    my $result = $self->all_row($sth, @binds);
    return unless $result && @$result;

    $result = $result->[0] if scalar(@$result) == 1;
    return $self->dump($result);
}

sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    my ($where_clause, @binds) = $self->where_clause($table, $name);
    my $qtable = $self->{field_quote}.$table.$self->{field_quote};
    return unless $where_clause;

    $self->cdo('DELETE FROM %s WHERE %s', [$qtable, $where_clause], @binds);
}

sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    my ($where_clause, @binds) = $self->where_clause($table, $name);
    my $qtable = $self->{field_quote}.$table.$self->{field_quote};
    return unless $where_clause || @binds;

    $data = $self->load($data);
    return unless $data;

    my $template = $self->pairs(', ', keys %$data);
    $self->cdo('UPDATE %s SET %s WHERE %s', [$qtable, $template, $where_clause], values %$data, @binds);
}

sub create
{
    my $self = shift;
    my ($table, $name) = @_;
    my @primary_key = $self->get_key_fields($table);
    my $qtable = $self->{field_quote}.$table.$self->{field_quote};
    return unless @primary_key;

    my $pholders = '?,' x scalar(@primary_key);
    chop $pholders;
    $self->cdo('INSERT INTO %s (%s) VALUES (%s)', [$qtable, join(', ', @primary_key), $pholders], $self->asplit($name));
}

sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    my @primary_key = $self->get_key_fields($table);
    return unless @primary_key;

    my %data = map { shift(@primary_key) => $_ } $self->asplit($newname);
    $self->store($table, $name, \%data);
}

sub get_key_fields {
    my @fields = @{$FusqlFS::Artifact::instance->{namemap}->{$_[1]} || []};
    @fields = $_[0]->get_primary_key($_[1]) unless @fields;
    return @fields;
}

sub get_primary_key { }

1;

