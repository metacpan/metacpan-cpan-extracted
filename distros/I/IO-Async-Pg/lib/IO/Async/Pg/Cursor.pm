package IO::Async::Pg::Cursor;

use strict;
use warnings;

use Future::AsyncAwait;
use IO::Async::Pg::Results;

my $cursor_counter = 0;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        name              => $args{name} // _generate_name(),
        batch_size        => $args{batch_size} // 1000,
        conn              => $args{conn},
        _owns_transaction => $args{_owns_transaction} // 0,
        exhausted         => 0,
        closed            => 0,
        buffer            => [],
    }, $class;

    return $self;
}

sub _generate_name {
    return "cursor_" . ++$cursor_counter;
}

# Accessors
sub name        { shift->{name} }
sub batch_size  { shift->{batch_size} }
sub is_exhausted { shift->{exhausted} }
sub is_closed   { shift->{closed} }

# Fetch next batch of rows
async sub next {
    my ($self) = @_;

    return undef if $self->{exhausted} || $self->{closed};

    my $conn = $self->{conn};
    my $name = $self->{name};
    my $batch_size = $self->{batch_size};

    my $result = await $conn->query("FETCH $batch_size FROM $name");
    my $rows = $result->rows;

    if (@$rows < $batch_size) {
        $self->{exhausted} = 1;
    }

    return @$rows ? $rows : undef;
}

# Iterate over all rows, calling callback for each
async sub each {
    my ($self, $callback) = @_;

    my $count = 0;
    while (my $batch = await $self->next) {
        for my $row (@$batch) {
            $callback->($row);
            $count++;
        }
    }

    return $count;
}

# Collect all remaining rows into an array
async sub all {
    my ($self) = @_;

    my @all_rows;
    while (my $batch = await $self->next) {
        push @all_rows, @$batch;
    }

    return \@all_rows;
}

# Close the cursor
async sub close {
    my ($self) = @_;

    return if $self->{closed};
    $self->{closed} = 1;

    if (my $conn = $self->{conn}) {
        eval { await $conn->query("CLOSE " . $self->{name}) };

        # If we started a transaction for this cursor, commit it
        if ($self->{_owns_transaction}) {
            eval { await $conn->query('COMMIT') };
            $conn->{in_transaction} = 0;
        }
    }
}

sub DESTROY {
    my ($self) = @_;

    # During global destruction, don't try to close
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    # Note: Can't await in DESTROY, so cursor cleanup may be deferred
    # Best practice is to explicitly call close()
}

1;

__END__

=head1 NAME

IO::Async::Pg::Cursor - Streaming cursor for large result sets

=head1 SYNOPSIS

    my $cursor = await $conn->cursor(
        'SELECT * FROM large_table WHERE status = $1',
        'active',
        { batch_size => 100 }
    );

    # Iterate over batches
    while (my $batch = await $cursor->next) {
        for my $row (@$batch) {
            process($row);
        }
    }

    # Or use each() for row-by-row processing
    await $cursor->each(sub {
        my ($row) = @_;
        process($row);
    });

    # Clean up
    await $cursor->close;

=head1 METHODS

=head2 next

Fetch the next batch of rows. Returns arrayref of rows, or undef when exhausted.

=head2 each($callback)

Iterate over all remaining rows, calling callback for each row.

=head2 all

Collect all remaining rows into an array. Use with caution on large result sets.

=head2 close

Close the cursor and release server resources.

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056@yahoo.comE<gt>

=cut
