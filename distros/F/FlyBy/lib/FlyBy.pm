package FlyBy;

use strict;
use warnings;
use 5.010;
our $VERSION = '0.095';

use Moo;

use Carp qw(croak);
use Parse::Lex;
use Scalar::Util qw(reftype);
use Set::Scalar;
use Try::Tiny;

has index_sets => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {}; },
);

has records => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { []; },
);

has _full_set => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { Set::Scalar->new; },
);

has query_lexer => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_query_lexer',
);

my $negation = '!';

sub _build_query_lexer {
    my $self = shift;

    my @tokens = (
        "NOTEQUAL"      => "(is not|IS NOT)",
        "EQUAL"         => "is|IS",
        "AND"           => "and|AND",
        "OR"            => "or|OR",
        "REDUCE"        => "->",
        "COMMA"         => ",",
        "QUOTED_STRING" => qq~(?:\'(?:[^\\\']*(?:\\.[^\\\']*)*)\'|\"(?:[^\\\"]*(?:\\.[^\\\"]*)*)\")~,    # From Text::Balanced
        "ERROR"         => ".*",
        sub { die qq!cannot analyze: "$_[1]"!; });

    return Parse::Lex->new(@tokens);
}

sub add_records {
    my ($self, @new_records) = @_;

    my $index_sets = $self->index_sets;
    my $records    = $self->records;

    foreach my $record (@new_records) {
        my $whatsit = reftype($record) // 'no reference';
        croak 'Records must be hash references, got: ' . $whatsit unless ($whatsit eq 'HASH');

        my $rec_index = $#$records + 1;    # Even if we accidentally made this sparse, we can insert here.
        my $add_it    = 0;                 # Do not add until we know there is at least one defined value;
        while (my ($k, $v) = each %$record) {
            if (defined $v) {
                $self->_from_index($k, $v, 1)->insert($rec_index);
                $add_it ||= 1;
            } else {
                delete $record->{$k};      # A missing key denotes an undefined value.
            }
        }
        if ($add_it) {
            $records->[$rec_index] = $record;
            $self->_full_set->insert($rec_index);
        }
    }

    return 1;
}

sub _from_index {
    my ($self, $key, $value, $add_missing_key) = @_;
    my $index_sets = $self->index_sets;

    my ($result, $negated);

    if (substr($value, 0, 1) eq $negation) {
        $negated = 1;
        $value = substr($value, 1);
    }

    return $negated ? $self->_full_set : $self->_full_set->empty_clone
        unless $add_missing_key or exists $index_sets->{$key};                      # Avoiding auto-viv on request

    if ($add_missing_key) {
        $result = $index_sets->{$key}{$value} //= $self->_full_set->empty_clone;    # Sets which do not (yet) exist in the index are null.
    } else {
        $result = $index_sets->{$key}{$value} //  $self->_full_set->empty_clone;    # Sets which do not (yet) exist in the index are null.
    }

    $result = $self->_full_set->difference($result) if ($negated);

    return $result;
}

sub query {
    my ($self, $query_clauses, $reduce_list) = @_;

    if (not reftype($query_clauses)) {
        my $err;                                                                    # To let us notice parsing errors;
        croak 'String queries should have a single parameter' if (defined $reduce_list);
        ($query_clauses, $reduce_list, $err) = $self->parse_query($query_clauses);
        croak $err if $err;
    } else {
        # Trust the parser above, so we only verify on 'hand-made' queries.
        croak 'Query clauses should be a non-empty hash reference.'
            unless ($query_clauses and (reftype($query_clauses) // '') eq 'HASH' and keys %$query_clauses);
        croak 'Reduce list should be a non-empty array reference.'
            unless (not $reduce_list or ((reftype($reduce_list) // '') eq 'ARRAY' and scalar @$reduce_list));

        # Now convert the supplied hashref to an array reference we can use.
        my %qhash = %$query_clauses;
        $query_clauses = [map { [$_ => $qhash{$_}] } grep { defined $qhash{$_} } keys %qhash];
    }

    my $match_set = $self->_full_set;
    my @qc        = @$query_clauses;

    while (my $addl_clause = shift @qc) {
        my ($key, $value) = @$addl_clause;
        my $whatsit = reftype($value);
        my $change_set;
        if ($whatsit && $whatsit eq 'ARRAY') {
            # OR syntax.
            my @ors = @$value;
            $value = shift @ors;
            # Allow for negation, even though it seems unlikely.
            $change_set = $self->_from_index($key, $value, 0);
            foreach my $or (@ors) {
                $change_set = $change_set->union($self->_from_index($key, $or, 0));
            }
        } else {
            $change_set = $self->_from_index($key, $value, 0);
        }

        $match_set = $match_set->intersection($change_set);
    }

    my $records = $self->records;
    # Sort may only be important for testing.  Reconsider if large slow sets appear.
    my @indices = sort { $a <=> $b } ($match_set->elements);
    my @results;

    if ($reduce_list) {
        my @keys      = @$reduce_list;
        my $key_count = scalar @keys;
        my %seen;
        foreach my $idx (@indices) {
            my @reduced_element = map { ($records->[$idx]->{$_} // '') } @keys;
            my $seen_key = join('->', @reduced_element);
            if (not $seen{$seen_key}) {
                push @results, ($key_count > 1) ? \@reduced_element : @reduced_element;
                $seen{$seen_key}++;
            }
        }
    } else {
        @results = map {
            { %{$records->[$_]} }
        } @indices;
    }

    return @results;
}

sub parse_query {
    my ($self, $query) = @_;

    my (%values, $err);
    my $lexer = $self->query_lexer;
    my $parse_err = sub { return 'Improper query at: ' . shift; };

    try {
        croak 'Empty query' unless $query;
        my @clause = ();
        my @tokens = $lexer->analyze($query);
        my ($in_reduce, $negated, $in_or) = (0, 0);
        $values{query} = [];
        TOKEN:
        while (my $name = shift @tokens) {
            my $text = shift @tokens;
            if ($name eq 'EOI') {
                # We must be done.
                if (@clause and $in_reduce) {
                    $values{reduce} = [@clause];
                } elsif (@clause) {
                    push @{$values{query}}, [@clause];
                }

                last TOKEN;
            }
            next TOKEN if ($name eq 'COMMA');    # They can put commas anywhere, we don't care.
            my $expected_length = 2;
            if ($name eq 'QUOTED_STRING') {
                my $value = ($negated) ? $negation . substr($text, 1, -1) : substr($text, 1, -1);
                if ($in_or) {
                    $clause[-1] = [$clause[-1]] unless (reftype($clause[-1]));
                    push @{$clause[-1]}, $value;
                } else {
                    push @clause, $value;
                }
                ($in_or, $negated) = 0;
            } elsif ($name eq 'AND') {
                croak $parse_err->($text) if ($in_reduce or scalar @clause != $expected_length);
                push @{$values{query}}, [@clause];
                @clause = ();    # Starting a new clause.
            } elsif ($name eq 'OR') {
                croak $parse_err->($text) if ($in_reduce or scalar @clause != $expected_length);
                $in_or = 1;
            } elsif ($name eq 'EQUAL') {
                croak $parse_err->($text) if ($in_reduce or scalar @clause != $expected_length - 1);
            } elsif ($name eq 'NOTEQUAL') {
                croak $parse_err->($text) if ($in_reduce or scalar @clause != $expected_length - 1);
                $negated = 1;
            } elsif ($name eq 'REDUCE') {
                croak $parse_err->($text) if ($in_reduce);
                $in_reduce = 1;
                push @{$values{query}}, [@clause] if (@clause);
                @clause = ();
            }
        }
    }
    catch {
        $err = $_;
    };

    return $values{query}, $values{reduce}, $err;
}

sub _check_clause {
    my ($self, $thing) = @_;

    my $whatsit = reftype $thing;
    return ($whatsit and $whatsit eq 'ARRAY' and scalar @$thing == 2);
}

sub all_keys {
    my $self = shift;
    return (sort { $a cmp $b } keys %{$self->index_sets});
}

sub values_for_key {
    my ($self, $key) = @_;

    return (sort { $a cmp $b } keys %{$self->index_sets->{$key}});
}

1;
__END__

=encoding utf-8

=head1 NAME

FlyBy - Ad hoc denormalized querying

=head1 SYNOPSIS

  use FlyBy;

  my $fb = FlyBy->new;
  $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});
  my @array_of_hash_refs = $fb->query({'key' => ['value', 'other value']});

  # Or with a 'reduction list':
  my @array = $fb->query({'key' => 'value'}, ['some key']);
  my @array_of_array_refs = $fb->query({'key' =>'value', 'other key' => 'other value'},
    ['some key', 'some other key']);

=head1 DESCRIPTION

FlyBy is a system to allow for ad hoc querying of data which may not
exist in a traditional datastore at runtime

=head1 USAGE

=over

=item add_records

  $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});

Supply one or more hash references to be added to the store.

Keys with undefined values will be silently stripped from each record.  If the
record is then empty it will be discarded.

`croak` on error; returns `1` on success

=item query

=over

=item string

  $fb->query("'type' IS 'shark' AND 'food' IS 'seal' -> 'called', 'lives_in'");

The query parameters are joined with `IS` for equality testing, or
`IS NOT` for its inverse.

Multiple values for a given key can be combined with `OR`.

Multiple keys are joined with AND.

The optional reductions are prefaced with `->`.

If no reduction is provided a list of the full record hash
references is returned.
If a reduction list of length 1 is provided, a list of the distinct
values for the matching key is returned.
If a longer reduction list is provided, a list of distinct value
array references (in the provided key order) is returned.

=item raw

  $fb->query({'type' => 'shark', 'food' => 'seal'}, ['called', 'lives_in']");

The query clause is supplied as hash reference of keys and values to
be `AND`-ed together for the final result.

An array reference value is treated as a sucession of 'or'-ed values
for the provided key.

All values prepended with an `!` are deemed to be a negation of the
rest of the string as a value.

A second optional reduction list of strings may be provided which
reduces the result as above.

=back

Will `croak` on improperly supplied query formats.

=item all_keys

Returns an array with all known keys against which one might query.

=item values_for_key

Returns an array of all known values for a given key.

=back

=head1 CAVEATS

Note that supplied keys may not begin with an `!`.  Thought has been
given to making this configurable at creation, but it was deemed to
be unnecessary complexity.

This software is in an early state. The internal representation and
external API are subject to deep breaking change.

This software is not tuned for efficiency.  If it is not being used
to resolve many queries on each instance or if the data is available
from a single canonical source, there are likely better solutions
available in CPAN.

=head1 AUTHOR

Binary.com

=head1 COPYRIGHT

Copyright 2015- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
