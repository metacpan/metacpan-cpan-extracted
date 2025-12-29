package IO::Async::Pg::Results;

use strict;
use warnings;

# Constructor from DBI statement handle (eager fetch)
sub new {
    my ($class, $sth) = @_;

    # Fetch all rows eagerly as hashrefs
    my $rows = $sth->fetchall_arrayref({}) // [];
    my $columns = $sth->{NAME} ? [ @{$sth->{NAME}} ] : [];
    my $rows_affected = $sth->rows;
    $sth->finish;

    return bless {
        rows          => $rows,
        columns       => $columns,
        count         => scalar @$rows,
        rows_affected => $rows_affected,
    }, $class;
}

# Constructor from data (for testing without DBI)
sub new_from_data {
    my ($class, %args) = @_;

    my $rows = $args{rows} // [];
    my $columns = $args{columns} // [];

    return bless {
        rows          => $rows,
        columns       => $columns,
        count         => scalar @$rows,
        rows_affected => $args{rows_affected} // 0,
    }, $class;
}

# All rows as arrayref of hashrefs
sub rows { shift->{rows} }

# Column names
sub columns { shift->{columns} }

# Number of rows
sub count { shift->{count} }

# Rows affected by INSERT/UPDATE/DELETE
sub rows_affected { shift->{rows_affected} }

# First row or undef
sub first {
    my $self = shift;
    return $self->{rows}[0];
}

# First column of first row (useful for COUNT(*) etc)
sub scalar {
    my $self = shift;
    my $first = $self->first;
    return undef unless $first;

    # Get first column name and return its value
    my $col = $self->{columns}[0];
    return $first->{$col} if defined $col;

    # Fallback: return first value in hash
    my @values = values %$first;
    return $values[0];
}

# True if no rows
sub is_empty {
    my $self = shift;
    return $self->{count} == 0;
}

1;

__END__

=head1 NAME

IO::Async::Pg::Results - Query result wrapper

=head1 SYNOPSIS

    my $result = await $conn->query('SELECT * FROM users');

    # Access rows
    for my $row (@{$result->rows}) {
        say $row->{name};
    }

    # First row
    my $user = $result->first;

    # Count
    my $count_result = await $conn->query('SELECT COUNT(*) FROM users');
    my $count = $count_result->scalar;

=head1 METHODS

=head2 rows

Returns arrayref of all rows as hashrefs.

=head2 first

Returns first row as hashref, or undef if empty.

=head2 count

Returns number of rows.

=head2 columns

Returns arrayref of column names.

=head2 scalar

Returns first column of first row. Useful for C<COUNT(*)> queries.

=head2 is_empty

Returns true if result has no rows.

=head2 rows_affected

Returns number of rows affected by INSERT/UPDATE/DELETE.

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056@yahoo.comE<gt>

=cut
