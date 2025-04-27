package JQ::Lite;

use strict;
use warnings;
use JSON::PP;
use List::Util qw(sum min max);

our $VERSION = '0.39';

sub new {
    my ($class, %opts) = @_;
    my $self = {
        raw => $opts{raw} || 0,
    };
    return bless $self, $class;
}

sub run_query {
    my ($self, $json_text, $query) = @_;
    my $data = decode_json($json_text);
    
    if (!defined $query || $query =~ /^\s*\.\s*$/) {
        return ($data);
    }
    
    # instead of: my @parts = split /\|/, $query;
    my @parts = map { s/^\s+|\s+$//gr } split /\|/, $query;
    
    # detect .[] and convert to pseudo-command
    @parts = map {
        if ($_ eq '.[]') {
            'flatten'
        } elsif ($_ =~ /^\.(.+)$/) {
            $1
        } else {
            $_
        }
    } @parts;

    my @results = ($data);
    for my $part (@parts) {
        my @next_results;

        # support for flatten (alias for .[])
        if ($part eq 'flatten') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? @$_ : ()
            } @results;
            @results = @next_results;
            next;
        }

        # support for select(...)
        if ($part =~ /^select\((.+)\)$/) {
            my $cond = $1;
            @next_results = grep { _evaluate_condition($_, $cond) } @results;
            @results = @next_results;
            next;
        }

        # support for length
        if ($part eq 'length') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? scalar(@$_) :
                ref $_ eq 'HASH'  ? scalar(keys %$_) :
                0
            } @results;
            @results = @next_results;
            next;
        }

        # support for keys
        if ($part eq 'keys') {
            @next_results = map {
                ref $_ eq 'HASH' ? [ sort keys %$_ ] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # support for sort
        if ($part eq 'sort') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ sort { _smart_cmp()->($a, $b) } @$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for unique
        if ($part eq 'unique') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ _uniq(@$_) ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for first
        if ($part eq 'first') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[0] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # support for last
        if ($part eq 'last') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[-1] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # support for reverse
        if ($part eq 'reverse') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ reverse @$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for limit(n)
        if ($part =~ /^limit\((\d+)\)$/) {
            my $limit = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    my $end = $limit - 1;
                    $end = $#$arr if $end > $#$arr;
                    [ @$arr[0 .. $end] ]
                } else {
                    $_
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for map(...)
        if ($part =~ /^map\((.+)\)$/) {
            my $filter = $1;
            @next_results = map {
                ref $_ eq 'ARRAY'
                    ? [ grep { defined($_) } map { $self->run_query(encode_json($_), $filter) } @$_ ]
                    : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for add
        if ($part eq 'add') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? sum(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for min
        if ($part eq 'min') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? min(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for max
        if ($part eq 'max') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? max(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for avg
        if ($part eq 'avg') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? sum(map { 0 + $_ } @$_) / scalar(@$_) : 0
            } @results;
            @results = @next_results;
            next;
        }

        # support for group_by(key)
        if ($part =~ /^group_by\((.+)\)$/) {
            my $key_path = $1;
            @next_results = map {
                _group_by($_, $key_path)
            } @results;
            @results = @next_results;
            next;
        }

        # support for count
        if ($part eq 'count') {
            my $n = 0;
            for my $item (@results) {
                if (ref $item eq 'ARRAY') {
                    $n += scalar(@$item);
                } else {
                    $n += 1;  # count as 1 item
                }
            }
            @results = ($n);
            next;
        }

        # support for join(", ")
        if ($part =~ /^join\((.*?)\)$/) {
            my $sep = $1;
            $sep =~ s/^['"](.*?)['"]$/$1/;  # remove quotes around separator

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    join($sep, map { defined $_ ? $_ : '' } @$_)
                } else {
                    ''
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for sort_by(key)
        if ($part =~ /^sort_by\((.+?)\)$/) {
            my $key_path = $1;
            $key_path =~ s/^\.//;  # Remove leading dot
        
            my $cmp = _smart_cmp();
            @next_results = ();
        
            for my $item (@results) {
                if (ref $item eq 'ARRAY') {
                    my @sorted = sort {
                        my $a_val = (_traverse($a, $key_path))[0] // '';
                        my $b_val = (_traverse($b, $key_path))[0] // '';
        
                        warn "[DEBUG] a=$a_val, b=$b_val => cmp=" . $cmp->($a_val, $b_val) . "\n";
        
                        $cmp->($a_val, $b_val);
                    } @$item;
        
                    push @next_results, \@sorted;
                } else {
                    push @next_results, $item;
                }
            }
        
            @results = @next_results;
            next;
        }

        # support for empty
        if ($part eq 'empty') {
            @results = ();  # discard all results
            next;
        }

        # support for values
        if ($part eq 'values') {
            @next_results = map {
                ref $_ eq 'HASH' ? [ values %$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for flatten()
        if ($part eq 'flatten()' || $part eq 'flatten') {
            @next_results = map {
                (ref $_ eq 'ARRAY') ? @$_ : ()
            } @results;
            @results = @next_results;
            next;
        }

        # support for type()
        if ($part eq 'type()' || $part eq 'type') {
            @next_results = map {
                if (!defined $_) {
                    'null';
                }
                elsif (ref($_) eq 'ARRAY') {
                    'array';
                }
                elsif (ref($_) eq 'HASH') {
                    'object';
                }
                elsif (ref($_) eq '') {
                    if (/^-?\d+(?:\.\d+)?$/) {
                        'number';
                    } else {
                        'string';
                    }
                }
                elsif (ref($_) eq 'JSON::PP::Boolean') {
                    'boolean';
                }
                else {
                    'unknown';
                }
            } (@results ? @results : (undef)); 
            @results = @next_results;
            next;
        }

        # support for nth(n)
        if ($part =~ /^nth\((\d+)\)$/) {
            my $index = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    $_->[$index]
                } else {
                    undef
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for del(key)
        if ($part =~ /^del\((.+?)\)$/) {
            my $key = $1;
            $key =~ s/^['"](.*?)['"]$/$1/;  # remove quotes

            @next_results = map {
                if (ref $_ eq 'HASH') {
                    my %copy = %$_;  # shallow copy
                    delete $copy{$key};
                    \%copy
                } else {
                    $_
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for compact()
        if ($part eq 'compact()' || $part eq 'compact') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    [ grep { defined $_ } @$_ ]
                } else {
                    $_
                }
            } @results;
            @results = @next_results;
            next;
        }

        # standard traversal
        for my $item (@results) {
            push @next_results, _traverse($item, $part);
        }
        @results = @next_results;
    }

    return @results;
}

sub _map {
    my ($self, $data, $filter) = @_;

    if (ref $data ne 'ARRAY') {
        warn "_map expects array reference";
        return ();
    }

    my @mapped;
    for my $item (@$data) {
        push @mapped, $self->run_query(encode_json($item), $filter);
    }

    return @mapped;
}

sub _traverse {
    my ($data, $query) = @_;
    my @steps = split /\./, $query;
    my @stack = ($data);

    for my $step (@steps) {
        my $optional = ($step =~ s/\?$//);
        my @next_stack;

        for my $item (@stack) {
            next if !defined $item;

            # index access: key[index]
            if ($step =~ /^(.*?)\[(\d+)\]$/) {
                my ($key, $index) = ($1, $2);
                if (ref $item eq 'HASH' && exists $item->{$key}) {
                    my $val = $item->{$key};
                    push @next_stack, $val->[$index]
                        if ref $val eq 'ARRAY' && defined $val->[$index];
                }
            }
            # array expansion: key[]
            elsif ($step =~ /^(.*?)\[\]$/) {
                my $key = $1;
                if (ref $item eq 'HASH' && exists $item->{$key}) {
                    my $val = $item->{$key};
                    if (ref $val eq 'ARRAY') {
                        push @next_stack, @$val;
                    }
                }
                elsif (ref $item eq 'ARRAY') {
                    for my $sub (@$item) {
                        if (ref $sub eq 'HASH' && exists $sub->{$key}) {
                            my $val = $sub->{$key};
                            push @next_stack, @$val if ref $val eq 'ARRAY';
                        }
                    }
                }
            }
            # standard access: key
            else {
                if (ref $item eq 'HASH' && exists $item->{$step}) {
                    push @next_stack, $item->{$step};
                }
                elsif (ref $item eq 'ARRAY') {
                    for my $sub (@$item) {
                        if (ref $sub eq 'HASH' && exists $sub->{$step}) {
                            push @next_stack, $sub->{$step};
                        }
                    }
                }
            }
        }

        # allow empty results if optional
        @stack = @next_stack;
        last if !@stack && !$optional;
    }

    return @stack;
}

sub _evaluate_condition {
    my ($item, $cond) = @_;

    # support for numeric expressions like: select(.a + 5 > 10)
    if ($cond =~ /^\s*(\.\w+)\s*([\+\-\*\/%])\s*(-?\d+(?:\.\d+)?)\s*(==|!=|>=|<=|>|<)\s*(-?\d+(?:\.\d+)?)\s*$/) {
        my ($path, $op1, $rhs1, $cmp, $rhs2) = ($1, $2, $3, $4, $5);
        my @values = _traverse($item, substr($path, 1));
        my $lhs = $values[0];
    
        return 0 unless defined $lhs && $lhs =~ /^-?\d+(?:\.\d+)?$/;
    
        my $expr = eval "$lhs $op1 $rhs1";
        return eval "$expr $cmp $rhs2";
    }

    # support for multiple conditions: split and evaluate recursively
    if ($cond =~ /\s+and\s+/i) {
        my @conds = split /\s+and\s+/i, $cond;
        for my $c (@conds) {
            return 0 unless _evaluate_condition($item, $c);
        }
        return 1;
    }
    if ($cond =~ /\s+or\s+/i) {
        my @conds = split /\s+or\s+/i, $cond;
        for my $c (@conds) {
            return 1 if _evaluate_condition($item, $c);
        }
        return 0;
    }

    # support for the contains operator: select(.tags contains "perl")
    if ($cond =~ /^\s*\.(.+?)\s+contains\s+"(.*?)"\s*$/) {
        my ($path, $want) = ($1, $2);
        my @vals = _traverse($item, $path);

        for my $val (@vals) {
            if (ref $val eq 'ARRAY') {
                return 1 if grep { $_ eq $want } @$val;
            }
            elsif (!ref $val && index($val, $want) >= 0) {
                return 1;
            }
        }
        return 0;
    }

    # support for the has operator: select(.meta has "key")
    if ($cond =~ /^\s*\.(.+?)\s+has\s+"(.*?)"\s*$/) {
        my ($path, $key) = ($1, $2);
        my @vals = _traverse($item, $path);

        for my $val (@vals) {
            if (ref $val eq 'HASH' && exists $val->{$key}) {
                return 1;
            }
        }
        return 0;
    }

    # support for the match operator (with optional 'i' flag)
    if ($cond =~ /^\s*\.(.+?)\s+match\s+"(.*?)"(i?)\s*$/) {
        my ($path, $pattern, $ignore_case) = ($1, $2, $3);
        my $re = eval {
            $ignore_case eq 'i' ? qr/$pattern/i : qr/$pattern/
        };
        return 0 unless $re;

        my @vals = _traverse($item, $path);
        for my $val (@vals) {
            next if ref $val;
            return 1 if $val =~ $re;
        }
        return 0;
    }
 
    # pattern for a single condition
    if ($cond =~ /^\s*\.(.+?)\s*(==|!=|>=|<=|>|<)\s*(.+?)\s*$/) {
        my ($path, $op, $value_raw) = ($1, $2, $3);

        my $value;
        if ($value_raw =~ /^"(.*)"$/) {
            $value = $1;
        } elsif ($value_raw eq 'true') {
            $value = JSON::PP::true;
        } elsif ($value_raw eq 'false') {
            $value = JSON::PP::false;
        } elsif ($value_raw =~ /^-?\d+(?:\.\d+)?$/) {
            $value = 0 + $value_raw;
        } else {
            $value = $value_raw;
        }

        my @values = _traverse($item, $path);
        my $field_val = $values[0];

        return 0 unless defined $field_val;

        my $is_number = (!ref($field_val) && $field_val =~ /^-?\d+(?:\.\d+)?$/)
                     && (!ref($value)     && $value     =~ /^-?\d+(?:\.\d+)?$/);

        if ($op eq '==') {
            return $is_number ? ($field_val == $value) : ($field_val eq $value);
        } elsif ($op eq '!=') {
            return $is_number ? ($field_val != $value) : ($field_val ne $value);
        } elsif ($is_number) {
            # perform numeric comparisons only when applicable
            if ($op eq '>') {
                return $field_val > $value;
            } elsif ($op eq '>=') {
                return $field_val >= $value;
            } elsif ($op eq '<') {
                return $field_val < $value;
            } elsif ($op eq '<=') {
                return $field_val <= $value;
            }
        }
    }

    return 0;
}

sub _smart_cmp {
    return sub {
        my ($a, $b) = @_;

        my $num_a = ($a =~ /^-?\d+(?:\.\d+)?$/);
        my $num_b = ($b =~ /^-?\d+(?:\.\d+)?$/);

        if ($num_a && $num_b) {
            return $a <=> $b;
        } else {
            return "$a" cmp "$b";  # explicitly perform string comparison
        }
    };
}

sub _uniq {
    my %seen;
    return grep { !$seen{_key($_)}++ } @_;
}

# generate a unique key for hash, array, or scalar values
sub _key {
    my ($val) = @_;
    if (ref $val eq 'HASH') {
        return join(",", sort map { "$_=$val->{$_}" } keys %$val);
    } elsif (ref $val eq 'ARRAY') {
        return join(",", map { _key($_) } @$val);
    } else {
        return "$val";
    }
}

sub _group_by {
    my ($array_ref, $path) = @_;
    return {} unless ref $array_ref eq 'ARRAY';

    my %groups;
    for my $item (@$array_ref) {
        my @keys = _traverse($item, $path);
        my $key = defined $keys[0] ? "$keys[0]" : 'null';
        push @{ $groups{$key} }, $item;
    }
    return \%groups;
}

1;
__END__

=encoding utf-8

=head1 NAME

JQ::Lite - A lightweight jq-like JSON query engine in Perl

=head1 VERSION

Version 0.39

=head1 SYNOPSIS

  use JQ::Lite;
  
  my $jq = JQ::Lite->new;
  my @results = $jq->run_query($json_text, '.users[].name');
  
  for my $r (@results) {
      print encode_json($r), "\n";
  }

=head1 DESCRIPTION

JQ::Lite is a lightweight, pure-Perl JSON query engine inspired by the
L<jq|https://stedolan.github.io/jq/> command-line tool.

It allows you to extract, traverse, and filter JSON data using a simplified
jq-like syntax — entirely within Perl, with no external binaries or XS modules.

=head1 FEATURES

=over 4

=item * Pure Perl (no XS, no external binaries required)

=item * Dot notation traversal (e.g. .users[].name)

=item * Optional key access using '?' (e.g. .nickname?)

=item * Array indexing and flattening (.users[0], .users[])

=item * Boolean filters via select(...) with ==, !=, <, >, and, or

=item * Pipe-style query chaining using | operator

=item * Built-in functions: length, keys, values, first, last, reverse, sort, sort_by, unique, has, group_by, join, count, empty, type, nth, del, compact

=item * Supports map(...) and limit(n) style transformations

=item * Interactive mode for exploring queries line-by-line

=item * Command-line interface: C<jq-lite> (compatible with stdin or file)

=item * Decoder selection via C<--use> (JSON::PP, JSON::XS, etc.)

=item * Debug output via C<--debug>

=item * List all functions with C<--help-functions>

=back

=head1 CONSTRUCTOR

=head2 new

  my $jq = JQ::Lite->new;

Creates a new instance. Options may be added in future versions.

=head1 METHODS

=head2 run_query

  my @results = $jq->run_query($json_text, $query);

Runs a jq-like query against the given JSON string.
Returns a list of matched results. Each result is a Perl scalar
(string, number, arrayref, hashref, etc.) depending on the query.

=head1 SUPPORTED SYNTAX

=over 4

=item * .key.subkey

=item * .array[0] (index access)

=item * .array[] (flattening arrays)

=item * .key? (optional key access)

=item * select(.key > 1 and .key2 == "foo") (boolean filters)

=item * group_by(.field) (group array items by key)

=item * sort_by(.key) (sort array of objects by key)

=item * .key | count (count items or fields)

=item * .[] | select(...) | count (combine flattening + filter + count)

=item * .array | map(.field) | join(", ")

Concatenates array elements with a custom separator string.
Example:

  .users | map(.name) | join(", ")

Results in:

  "Alice, Bob, Carol"

=item * values()

Returns all values of a hash as an array.
Example:

  .profile | values

=item * empty()

Discards all output. Compatible with jq.
Useful when only side effects or filtering is needed without output.

Example:

  .users[] | select(.age > 25) | empty

=item * .[] as alias for flattening top-level arrays

=item * type()

Returns the type of the value as a string:
"string", "number", "boolean", "array", "object", or "null".

Example:

  .name | type     # => "string"
  .tags | type     # => "array"
  .profile | type  # => "object"

=item * nth(n)

Returns the nth element (zero-based) from an array.

Example:

  .users | nth(0)   # first user
  .users | nth(2)   # third user

=item * del(key)

Deletes a specified key from a hash object and returns a new hash without that key.

Example:

  .profile | del("password")

If the key does not exist, returns the original hash unchanged.

If applied to a non-hash object, returns the object unchanged.

=item * compact()

Removes undef and null values from an array.

Example:

  .data | compact()

Before: [1, null, 2, null, 3]

After:  [1, 2, 3]

=back

=head1 COMMAND LINE USAGE

C<jq-lite> is a CLI wrapper for this module.

  cat data.json | jq-lite '.users[].name'
  jq-lite '.users[] | select(.age > 25)' data.json
  jq-lite -r '.users[].name' data.json
  jq-lite '.[] | select(.active == true) | .name' data.json
  jq-lite '.users[] | select(.age > 25) | count' data.json
  jq-lite '.users | map(.name) | join(", ")'
  jq-lite '.users[] | select(.age > 25) | empty'
  jq-lite '.profile | values'

=head2 Interactive Mode

Omit the query to enter interactive mode:

  jq-lite data.json

You can then type queries line-by-line against the same JSON input.

=head2 Decoder Selection and Debug

  jq-lite --use JSON::PP --debug '.users[0].name' data.json

=head2 Show Supported Functions

  jq-lite --help-functions

Displays all built-in functions and their descriptions.

=head1 REQUIREMENTS

Uses only core modules:

=over 4

=item * JSON::PP

=back

Optional: JSON::XS, Cpanel::JSON::XS, JSON::MaybeXS

=head1 SEE ALSO

L<JSON::PP>, L<jq|https://stedolan.github.io/jq/>

=head1 AUTHOR

Kawamura Shingo E<lt>pannakoota1@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut

