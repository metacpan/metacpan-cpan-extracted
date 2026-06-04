package FalkorDB::QueryResult;

use strict;
use warnings;
use FalkorDB::Node;
use FalkorDB::Edge;
use Scalar::Util qw(looks_like_number);
use FalkorDB::Path;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless \%args, $class;
    $self->_parse_stats();
    return $self;
}

sub header     { shift->{header} }
sub result_set { shift->{result_set} }
sub stats      { shift->{stats} }

sub labels_added            { shift->{labels_added}            || 0 }
sub nodes_created           { shift->{nodes_created}           || 0 }
sub nodes_deleted           { shift->{nodes_deleted}           || 0 }
sub properties_set          { shift->{properties_set}          || 0 }
sub relationships_created   { shift->{relationships_created}   || 0 }
sub relationships_deleted   { shift->{relationships_deleted}   || 0 }
sub cached_execution        { shift->{cached_execution}        || 0 }
sub internal_execution_time { shift->{internal_execution_time} || 0 }

sub row_count {
    my ($self) = @_;
    return scalar @{ $self->{result_set} || [] };
}

sub get_row {
    my ( $self, $idx ) = @_;
    return $self->{result_set}->[$idx];
}

sub next_row {
    my ($self) = @_;
    $self->{_iterator_idx} //= 0;
    if ( $self->{_iterator_idx} < $self->row_count ) {
        return $self->{result_set}->[ $self->{_iterator_idx}++ ];
    }
    return;
}

sub reset_iterator {
    my ($self) = @_;
    $self->{_iterator_idx} = 0;
}

sub hashes {
    my ($self)     = @_;
    my $header     = $self->header;
    my $result_set = $self->result_set;
    my @hashes;
    for my $row (@$result_set) {
        my %hash;
        for my $i ( 0 .. $#$header ) {
            $hash{ $header->[$i] } = $row->[$i];
        }
        push @hashes, \%hash;
    }
    return \@hashes;
}

sub next_hash {
    my ($self) = @_;
    my $row = $self->next_row();
    return unless $row;
    my $header = $self->header;
    my %hash;
    for my $i ( 0 .. $#$header ) {
        $hash{ $header->[$i] } = $row->[$i];
    }
    return \%hash;
}

# --- Parsing logic ---

sub new_from_raw {
    my ( $class, $raw_res ) = @_;

    my ( $header, $rows, $stats );
    if ( ref $raw_res eq 'ARRAY' ) {
        if ( @$raw_res == 1 ) {
            $stats  = $raw_res->[0];
            $header = [];
            $rows   = [];
        }
        elsif ( @$raw_res == 3 ) {
            $header = $raw_res->[0];
            $rows   = $raw_res->[1];
            $stats  = $raw_res->[2];
        }
        else {
            $stats  = [];
            $header = [];
            $rows   = [];
        }
    }

    my @processed_rows;
    if ( ref $rows eq 'ARRAY' ) {
        for my $row (@$rows) {
            my @processed_row;
            if ( ref $row eq 'ARRAY' ) {
                for my $cell (@$row) {
                    push @processed_row, _parse_cell($cell);
                }
            }
            else {
                push @processed_row, _parse_cell($row);
            }
            push @processed_rows, \@processed_row;
        }
    }

    return $class->new(
        header     => $header || [],
        result_set => \@processed_rows,
        stats      => $stats || [],
    );
}

sub _parse_cell {
    my ($val) = @_;

    if ( _is_node($val) ) {
        return FalkorDB::Node->new_from_resp($val);
    }
    elsif ( _is_edge($val) ) {
        return FalkorDB::Edge->new_from_resp($val);
    }
    elsif ( _is_path($val) ) {
        return FalkorDB::Path->new_from_string($val);
    }
    elsif ( defined $val && !ref $val && $val =~ /^\[.*\]$/ ) {
        return _parse_array_string($val);
    }
    elsif ( ref $val eq 'ARRAY' ) {
        return [ map { _parse_cell($_) } @$val ];
    }
    else {
        return $val;
    }
}

sub _is_node {
    my ($val) = @_;
    return unless ref $val eq 'ARRAY' && @$val == 3;
    my %keys = map { ref $_ eq 'ARRAY' ? ( $_->[0] => 1 ) : () } @$val;
    return $keys{id} && $keys{labels} && $keys{properties};
}

sub _is_edge {
    my ($val) = @_;
    return unless ref $val eq 'ARRAY' && @$val == 5;
    my %keys = map { ref $_ eq 'ARRAY' ? ( $_->[0] => 1 ) : () } @$val;
    return
         $keys{id}
      && $keys{type}
      && $keys{src_node}
      && $keys{dest_node}
      && $keys{properties};
}

sub _is_path {
    my ($val) = @_;
    return unless defined $val && !ref $val;
    return $val =~ /^\[\s*(\(\d+\)|\[\d+\])(?:\s*,\s*(\(\d+\)|\[\d+\]))*\s*\]$/;
}

sub _parse_array_string {
    my ($str) = @_;
    if ( $str =~ /^\[(.*)\]$/ ) {
        my $content = $1;
        return [] if $content =~ /^\s*$/;
        my @elements = split /,\s*/, $content;
        for my $el (@elements) {
            $el =~ s/^['"]//;
            $el =~ s/['"]$//;
            if ( looks_like_number($el) ) {
                $el = 0 + $el;
            }
        }
        return \@elements;
    }
    return;
}

sub _parse_properties {
    my ($props_array) = @_;
    my %props;
    if ( ref $props_array eq 'ARRAY' ) {
        for my $pair (@$props_array) {
            if ( ref $pair eq 'ARRAY' && @$pair == 2 ) {
                my ( $k, $v ) = @$pair;
                if ( defined $v && !ref $v && $v =~ /^\[.*\]$/ ) {
                    $v = _parse_array_string($v);
                }
                $props{$k} = $v;
            }
        }
    }
    return \%props;
}

# --- Statistics Parsing ---

sub _parse_stats {
    my ($self) = @_;
    my $stats = $self->{stats};
    return unless ref $stats eq 'ARRAY';

    for my $stat (@$stats) {
        if ( $stat =~ /^Labels added:\s*(\d+)/i ) {
            $self->{labels_added} = 0 + $1;
        }
        elsif ( $stat =~ /^Nodes created:\s*(\d+)/i ) {
            $self->{nodes_created} = 0 + $1;
        }
        elsif ( $stat =~ /^Nodes deleted:\s*(\d+)/i ) {
            $self->{nodes_deleted} = 0 + $1;
        }
        elsif ( $stat =~ /^Properties set:\s*(\d+)/i ) {
            $self->{properties_set} = 0 + $1;
        }
        elsif ( $stat =~ /^Relationships created:\s*(\d+)/i ) {
            $self->{relationships_created} = 0 + $1;
        }
        elsif ( $stat =~ /^Relationships deleted:\s*(\d+)/i ) {
            $self->{relationships_deleted} = 0 + $1;
        }
        elsif ( $stat =~ /^Cached execution:\s*(\d+)/i ) {
            $self->{cached_execution} = 0 + $1;
        }
        elsif ( $stat =~ /^Query internal execution time:\s*([\d\.]+)/i ) {
            $self->{internal_execution_time} = 0 + $1;
        }
    }
}

1;
__END__

=head1 NAME

FalkorDB::QueryResult - Representation of FalkorDB Cypher query results

=head1 DESCRIPTION

This class processes and exposes the results returned by executing a Cypher query.

=head1 METHODS

=head2 header()

Returns an array reference of the column names returned by the query.

=head2 result_set()

Returns an array reference of arrays (representing rows) containing parsed objects or scalars.

=head2 stats()

Returns the raw array reference of execution statistics.

=head2 row_count()

Returns the total number of rows in the result set.

=head2 get_row($idx)

Returns the row at the given 0-indexed position.

=head2 next_row()

Returns the next row as an array reference (or undef when exhausted).

=head2 reset_iterator()

Resets the iterator back to the beginning of the result set.

=head2 hashes()

Returns an array reference of hashes representing the result set, where keys are column names.

=head2 next_hash()

Returns the next row as a hash reference (or undef when exhausted).

=head2 labels_added()

=head2 nodes_created()

=head2 nodes_deleted()

=head2 properties_set()

=head2 relationships_created()

=head2 relationships_deleted()

=head2 cached_execution()

=head2 internal_execution_time()

Returns the execution metrics parsed from the query statistics.

=cut
