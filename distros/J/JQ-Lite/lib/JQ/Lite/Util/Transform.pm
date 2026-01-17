package JQ::Lite::Util;

use strict;
use warnings;

use JSON::PP ();
use List::Util qw(sum min max);
use Scalar::Util qw(looks_like_number);
use MIME::Base64 qw(encode_base64 decode_base64);
use Encode qw(encode is_utf8);
use B ();

our ($JSON_DECODER, $FROMJSON_DECODER, $TOJSON_ENCODER);

sub _apply_tostring {
    my ($value) = @_;

    if (!defined $value) {
        return 'null';
    }

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 'true' : 'false';
    }

    if (!ref $value) {
        return "$value";
    }

    if (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        return $TOJSON_ENCODER->encode($value);
    }

    return $TOJSON_ENCODER->encode($value);
}

sub _apply_tojson {
    my ($value) = @_;

    return $TOJSON_ENCODER->encode($value);
}

sub _apply_fromjson {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_fromjson($_) } @$value ];
    }

    return $value if ref $value;

    my $text = "$value";
    my $decoded = eval { $FROMJSON_DECODER->decode($text) };

    return $@ ? $value : $decoded;
}

sub _apply_numeric_function {
    my ($value, $callback) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        my $numeric = $value ? 1 : 0;
        return $callback->($numeric);
    }

    if (!ref $value) {
        return looks_like_number($value) ? $callback->($value) : $value;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_numeric_function($_, $callback) } @$value ];
    }

    return $value;
}

sub _apply_clamp {
    my ($value, $min, $max) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        my $numeric = $value ? 1 : 0;
        return _clamp_scalar($numeric, $min, $max);
    }

    if (!ref $value) {
        return _clamp_scalar($value, $min, $max);
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_clamp($_, $min, $max) } @$value ];
    }

    return $value;
}

sub _normalize_numeric_bound {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    return looks_like_number($value) ? 0 + $value : undef;
}

sub _clamp_scalar {
    my ($value, $min, $max) = @_;

    return $value unless looks_like_number($value);

    my $numeric = 0 + $value;
    $numeric = $min if defined $min && $numeric < $min;
    $numeric = $max if defined $max && $numeric > $max;

    return $numeric;
}

sub _apply_to_number {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (!ref $value) {
        return looks_like_number($value) ? 0 + $value : $value;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_to_number($_) } @$value ];
    }

    return $value;
}

sub _normalize_percentile {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 1 : 0;
    }

    return undef if ref $value;
    return undef unless looks_like_number($value);

    my $fraction = 0 + $value;

    return undef if $fraction != $fraction;             # NaN
    return undef if ($fraction * 0) != ($fraction * 0); # infinity

    if ($fraction > 1) {
        $fraction /= 100 if $fraction <= 100;
    }

    $fraction = 0 if $fraction < 0;
    $fraction = 1 if $fraction > 1;

    return $fraction;
}

sub _percentile_value {
    my ($numbers, $fraction) = @_;

    return undef unless ref $numbers eq 'ARRAY';
    return undef unless @$numbers;

    $fraction = 0 if $fraction < 0;
    $fraction = 1 if $fraction > 1;

    return $numbers->[0] if @$numbers == 1;

    my $rank        = $fraction * (@$numbers - 1);
    my $lower_index = int($rank);
    my $upper_index = $lower_index == @$numbers - 1 ? $lower_index : $lower_index + 1;
    my $weight      = $rank - $lower_index;

    return $numbers->[$lower_index] if $upper_index == $lower_index;

    my $lower = $numbers->[$lower_index];
    my $upper = $numbers->[$upper_index];

    return $lower + ($upper - $lower) * $weight;
}

sub _apply_merge_objects {
    my ($value) = @_;

    if (ref $value eq 'ARRAY') {
        my %merged;
        my $saw_object = 0;

        for my $element (@$value) {
            next unless ref $element eq 'HASH';
            %merged = (%merged, %$element);
            $saw_object = 1;
        }

        return $saw_object ? \%merged : {};
    }

    if (ref $value eq 'HASH') {
        return { %$value };
    }

    return $value;
}

sub _to_entries {
    my ($value) = @_;

    if (ref $value eq 'HASH') {
        return [ map { { key => $_, value => $value->{$_} } } sort keys %$value ];
    }

    if (ref $value eq 'ARRAY') {
        return [ map { { key => $_, value => $value->[$_] } } 0 .. $#$value ];
    }

    return $value;
}

sub _is_string_scalar {
    my ($value) = @_;

    return 0 if !defined $value;
    return 0 if ref $value;

    my $sv    = B::svref_2object(\$value);
    my $flags = $sv->FLAGS;

    return $flags & B::SVp_POK() ? 1 : 0;
}

sub _from_entries {
    my ($value) = @_;

    die 'from_entries(): argument must be an array' unless ref $value eq 'ARRAY';

    my %result;
    my @numeric_keys;
    my $saw_non_numeric_key = 0;
    for my $entry (@$value) {
        my ($key, $val);

        if (ref $entry eq 'HASH') {
            die 'from_entries(): entry is missing key'    if !exists $entry->{key};
            die 'from_entries(): entry is missing value'  if !exists $entry->{value};
            ($key, $val) = ($entry->{key}, $entry->{value});
        }
        elsif (ref $entry eq 'ARRAY') {
            die 'from_entries(): entry must have a key and value' if @$entry < 2;
            ($key, $val) = @{$entry}[0, 1];
        }
        else {
            die 'from_entries(): entry must be an object or [key, value] tuple';
        }

        if (!defined $key || ref $key) {
            die 'from_entries(): key must be a string';
        }

        $key = "$key";

        die 'from_entries(): key must be a string' if !_is_string_scalar($key);

        $result{$key} = $val;

        if ($key =~ /^\d+$/) {
            push @numeric_keys, 0 + $key;
        }
        else {
            $saw_non_numeric_key = 1;
        }
    }

    if (@numeric_keys && !$saw_non_numeric_key) {
        my %seen;
        my $max_index = -1;
        for my $index (@numeric_keys) {
            next if $seen{$index}++;
            $max_index = $index if $index > $max_index;
        }

        if ($max_index + 1 == scalar(keys %result) && $max_index + 1 == scalar(@numeric_keys)) {
            my @array = map { $result{$_} } 0 .. $max_index;
            return \@array;
        }
    }

    return \%result;
}

sub _apply_with_entries {
    my ($self, $value, $filter) = @_;

    return $value unless ref $value eq 'HASH' || ref $value eq 'ARRAY';

    my $entries = _to_entries($value);
    return $value unless ref $entries eq 'ARRAY';

    my @transformed;
    for my $entry (@$entries) {
        my @results = $self->run_query(_encode_json($entry), $filter);
        for my $result (@results) {
            my $normalized = _normalize_entry($result);
            push @transformed, $normalized if $normalized;
        }
    }

    return _from_entries(\@transformed);
}

sub _apply_map_values {
    my ($self, $value, $filter) = @_;

    return $value if !defined $value;

    if (ref $value eq 'HASH') {
        my %result;
        for my $key (keys %$value) {
            my $original = $value->{$key};
            my @outputs  = $self->run_query(_encode_json($original), $filter);
            next unless @outputs;
            $result{$key} = $outputs[0];
        }
        return \%result;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_map_values($self, $_, $filter) } @$value ];
    }

    return $value;
}

sub _apply_walk {
    my ($self, $value, $filter) = @_;

    if (ref $value eq 'HASH') {
        my %copy;
        for my $key (keys %$value) {
            $copy{$key} = _apply_walk($self, $value->{$key}, $filter);
        }
        $value = \%copy;
    }
    elsif (ref $value eq 'ARRAY') {
        my @copy = map { _apply_walk($self, $_, $filter) } @$value;
        $value   = \@copy;
    }

    my @results = $self->run_query(_encode_json($value), $filter);
    return @results ? $results[0] : undef;
}

sub _apply_recurse {
    my ($self, $value, $filter) = @_;

    my @stack   = ($value);
    my @outputs;

    while (@stack) {
        my $current = pop @stack;
        push @outputs, $current;

        next unless defined $current;

        my @children;
        if (defined $filter) {
            my $json = _encode_json($current);
            @children = $self->run_query($json, $filter);
        }
        elsif (ref $current eq 'ARRAY') {
            @children = @$current;
        }
        elsif (ref $current eq 'HASH') {
            @children = map { $current->{$_} } sort keys %$current;
        }

        next unless @children;

        for my $child (reverse @children) {
            push @stack, $child;
        }
    }

    return @outputs;
}

sub _apply_delpaths {
    my ($self, $value, $filter) = @_;

    return $value if !defined $value;
    return $value if !ref $value || ref($value) eq 'JSON::PP::Boolean';

    $filter //= '';
    $filter =~ s/^\s+|\s+$//g;
    return $value if $filter eq '';

    my @paths;
    my $decoded_paths = eval { _decode_json($filter) };
    if (!$@ && defined $decoded_paths) {
        if (ref $decoded_paths eq 'ARRAY') {
            if (grep { ref($_) ne 'ARRAY' } @$decoded_paths) {
                die 'delpaths(): paths must be an array of path arrays';
            }

            push @paths, map { _validate_path_array($_, 'delpaths') } @$decoded_paths;
        }
        else {
            die 'delpaths(): paths must be an array of path arrays';
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(_encode_json($value), $filter);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (grep { ref($_) ne 'ARRAY' } @$output) {
                    die 'delpaths(): paths must be an array of path arrays';
                }

                push @paths, map { _validate_path_array($_, 'delpaths') } @$output;
            }
            else {
                die 'delpaths(): paths must be an array of path arrays';
            }
        }
    }

    return $value unless @paths;

    if (grep { ref $_ eq 'ARRAY' && !@$_ } @paths) {
        return undef;
    }

    my $clone = _deep_clone($value);
    my @ordered = _sort_paths_for_deletion(@paths);

    for my $path (@ordered) {
        next unless ref $path eq 'ARRAY';
        next unless @$path;
        _delete_path_inplace($clone, [@$path]);
    }

    return $clone;
}

sub _sort_paths_for_deletion {
    my (@paths) = @_;

    return sort {
        my $depth_cmp = @$b <=> @$a;
        return $depth_cmp if $depth_cmp;

        my $prefix_cmp = _path_prefix_key($a) cmp _path_prefix_key($b);
        return $prefix_cmp if $prefix_cmp;

        return _compare_path_segments($b->[-1], $a->[-1]);
    } @paths;
}

sub _path_prefix_key {
    my ($path) = @_;

    return '' if !$path || @$path < 2;

    my @segments = @$path[0 .. $#$path - 1];
    return join "\x1f", map { _path_segment_key($_) } @segments;
}

sub _path_segment_key {
    my ($segment) = @_;

    return 'undef' if !defined $segment;

    if (ref($segment) eq 'JSON::PP::Boolean') {
        return $segment ? 'bool:true' : 'bool:false';
    }

    return ref $segment ? 'ref:' . ref($segment) : "scalar:$segment";
}

sub _compare_path_segments {
    my ($left, $right) = @_;

    if (_is_numeric_segment($left) && _is_numeric_segment($right)) {
        return _numeric_segment_value($left) <=> _numeric_segment_value($right);
    }

    return _path_segment_key($left) cmp _path_segment_key($right);
}

sub _numeric_segment_value {
    my ($segment) = @_;

    if (ref($segment) eq 'JSON::PP::Boolean') {
        return $segment ? 1 : 0;
    }

    return int($segment);
}

sub _deep_clone {
    my ($value) = @_;

    return $value if !defined $value;
    return $value if !ref $value || ref($value) eq 'JSON::PP::Boolean';

    my $json = _encode_json($value);
    return _decode_json($json);
}

sub _delete_path_inplace {
    my ($value, $path) = @_;

    return unless ref $value eq 'HASH' || ref $value eq 'ARRAY';
    return unless ref $path eq 'ARRAY';
    return unless @$path;

    my @segments = @$path;
    my $last     = pop @segments;

    my $cursor = $value;
    for my $segment (@segments) {
        if (ref $cursor eq 'HASH') {
            my $key = _coerce_hash_key($segment);
            return unless defined $key;
            return unless exists $cursor->{$key};
            $cursor = $cursor->{$key};
            next;
        }

        if (ref $cursor eq 'ARRAY') {
            my $index = _normalize_array_index($segment, scalar @$cursor);
            return if !defined $index;
            $cursor = $cursor->[$index];
            next;
        }

        return;
    }

    if (ref $cursor eq 'HASH') {
        my $key = _coerce_hash_key($last);
        return unless defined $key;
        delete $cursor->{$key};
        return;
    }

    if (ref $cursor eq 'ARRAY') {
        my $index = _normalize_array_index($last, scalar @$cursor);
        return if !defined $index;
        splice @$cursor, $index, 1;
    }
}

sub _normalize_array_index {
    my ($value, $length) = @_;

    return if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 1 : 0;
    }

    return if ref $value;

    return if $value !~ /^-?\d+$/;

    my $index = int($value);
    $index += $length if $index < 0;

    return if $index < 0 || $index >= $length;

    return $index;
}

sub _normalize_entry {
    my ($entry) = @_;

    if (ref $entry eq 'HASH') {
        return unless exists $entry->{key};
        return { key => $entry->{key}, value => $entry->{value} };
    }

    if (ref $entry eq 'ARRAY') {
        return unless @$entry >= 2;
        return { key => $entry->[0], value => $entry->[1] };
    }

    return;
}

sub _apply_coalesce {
    my ($self, $value, $lhs_expr, $rhs_expr) = @_;

    my @lhs_values = _evaluate_coalesce_operand($self, $value, $lhs_expr);
    for my $candidate (@lhs_values) {
        return $candidate if defined $candidate;
    }

    my @rhs_values = _evaluate_coalesce_operand($self, $value, $rhs_expr);
    for my $candidate (@rhs_values) {
        return $candidate if defined $candidate;
    }

    return undef;
}

sub _evaluate_coalesce_operand {
    my ($self, $context, $expr) = @_;

    return () unless defined $expr;

    my $copy = $expr;
    $copy =~ s/^\s+|\s+$//g;
    return () if $copy eq '';

    while ($copy =~ /^\((.*)\)$/) {
        $copy = $1;
        $copy =~ s/^\s+|\s+$//g;
    }

    if ($copy =~ /^(.*?)\s*\/\/\s*(.+)$/) {
        my ($lhs, $rhs) = ($1, $2);
        my $result = _apply_coalesce($self, $context, $lhs, $rhs);
        return ($result);
    }

    if ($copy eq '.') {
        return ($context);
    }

    my $decoded = eval { _decode_json($copy) };
    if (!$@) {
        return ($decoded);
    }

    if ($copy =~ /^'(.*)'$/) {
        my $text = $1;
        $text =~ s/\\'/'/g;
        return ($text);
    }

    return () unless defined $context;

    my $path = $copy;
    $path =~ s/^\.//;

    return _traverse($context, $path);
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

            # direct index access: [index]
            if ($step =~ /^\[(\d+)\]$/) {
                my $index = $1;
                if (ref $item eq 'ARRAY' && defined $item->[$index]) {
                    push @next_stack, $item->[$index];
                }
            }
            # array expansion without key: []
            elsif ($step eq '[]') {
                if (ref $item eq 'ARRAY') {
                    push @next_stack, @$item;
                }
                elsif (ref $item eq 'HASH') {
                    push @next_stack, values %$item;
                }
            }
            # index access: key[index]
            elsif ($step =~ /^(.*?)\[(\d+)\]$/) {
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
                    elsif (ref $val eq 'HASH') {
                        push @next_stack, values %$val;
                    }
                }
                elsif (ref $item eq 'ARRAY') {
                    for my $sub (@$item) {
                        if (ref $sub eq 'HASH' && exists $sub->{$key}) {
                            my $val = $sub->{$key};
                            if (ref $val eq 'ARRAY') {
                                push @next_stack, @$val;
                            }
                            elsif (ref $val eq 'HASH') {
                                push @next_stack, values %$val;
                            }
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
        my ($re, $error) = _build_regex($pattern, $ignore_case);
        if ($error) {
            $error =~ s/[\r\n]+$//;
            die "match(): invalid regular expression - $error";
        }

        my @vals = _traverse($item, $path);
        for my $val (@vals) {
            next if ref $val;
            return 1 if $val =~ $re;
        }
        return 0;
    }

    # support for the =~ operator: select(. =~ "pattern")
    if ($cond =~ /^\s*\.(.+?)\s*=~\s*"(.*?)"(i?)\s*$/) {
        my ($path, $pattern, $ignore_case) = ($1, $2, $3);
        my ($re, $error) = _build_regex($pattern, $ignore_case);
        if ($error) {
            $error =~ s/[\r\n]+$//;
            die "=~: invalid regular expression - $error";
        }

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
        return 0 unless @values;

        for my $field_val (@values) {
            next unless defined $field_val;

            my $is_number = (!ref($field_val) && $field_val =~ /^-?\d+(?:\.\d+)?$/)
                         && (!ref($value)     && $value     =~ /^-?\d+(?:\.\d+)?$/);

            if ($op eq '==') {
                return 1 if $is_number ? ($field_val == $value) : ($field_val eq $value);
            } elsif ($op eq '!=') {
                return 1 if $is_number ? ($field_val != $value) : ($field_val ne $value);
            } elsif ($is_number) {
                # perform numeric comparisons only when applicable
                if ($op eq '>') {
                    return 1 if $field_val > $value;
                } elsif ($op eq '>=') {
                    return 1 if $field_val >= $value;
                } elsif ($op eq '<') {
                    return 1 if $field_val < $value;
                } elsif ($op eq '<=') {
                    return 1 if $field_val <= $value;
                }
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

sub _extreme_by {
    my ($array_ref, $key_path, $use_entire_item, $mode) = @_;

    return undef unless ref $array_ref eq 'ARRAY';
    return undef unless @$array_ref;

    my $cmp = _smart_cmp();
    my ($best_item, $best_key);

    for my $element (@$array_ref) {
        my $candidate = _extract_extreme_key($element, $key_path, $use_entire_item);
        next unless defined $candidate;

        if (!defined $best_item) {
            ($best_item, $best_key) = ($element, $candidate);
            next;
        }

        my $comparison = $cmp->($candidate, $best_key);
        if (($mode eq 'max' && $comparison > 0)
            || ($mode eq 'min' && $comparison < 0)) {
            ($best_item, $best_key) = ($element, $candidate);
        }
    }

    return defined $best_item ? $best_item : undef;
}

sub _extract_extreme_key {
    my ($element, $key_path, $use_entire_item) = @_;

    my @values = $use_entire_item ? ($element) : _traverse($element, $key_path);
    return undef unless @values;

    my $value = $values[0];
    return _value_to_comparable($value);
}

sub _value_to_comparable {
    my ($value) = @_;

    return undef unless defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (!ref $value) {
        return $value;
    }

    if (ref($value) eq 'HASH' || ref($value) eq 'ARRAY') {
        return _encode_json($value);
    }

    return undef;
}

sub _normalize_path_argument {
    my ($raw_path) = @_;

    $raw_path = '' unless defined $raw_path;
    $raw_path =~ s/^\s+|\s+$//g;
    $raw_path =~ s/^['"](.*)['"]$/$1/;

    my $use_entire_item = ($raw_path eq '' || $raw_path eq '.');
    my $key_path        = $raw_path;
    $key_path =~ s/^\.// unless $use_entire_item;

    return ($key_path, $use_entire_item);
}

sub _project_numeric_values {
    my ($element, $key_path, $use_entire_item) = @_;

    my @values = $use_entire_item
        ? ($element)
        : _traverse($element, $key_path);

    my @numbers;
    for my $value (@values) {
        next unless defined $value;

        if (ref($value) eq 'JSON::PP::Boolean') {
            push @numbers, $value ? 1 : 0;
            next;
        }

        next if ref $value;
        next unless looks_like_number($value);

        push @numbers, 0 + $value;
    }

    return @numbers;
}

sub _uniq {
    my %seen;
    return grep { !$seen{_key($_)}++ } @_;
}

# generate a unique key for hash, array, or scalar values
sub _key {
    my ($val) = @_;
    if (ref $val eq 'HASH') {
        return join(",", sort map { "$_=" . _key($val->{$_}) } keys %$val);
    } elsif (ref $val eq 'ARRAY') {
        return join(",", map { _key($_) } @$val);
    } else {
        return "$val";
    }
}

sub _group_by {
    my ($array_ref, $path) = @_;
    die 'group_by(): input must be an array' unless ref $array_ref eq 'ARRAY';

    my ($key_path, $use_entire_item) = _normalize_path_argument($path);

    my @entries;
    my $index = 0;
    for my $item (@$array_ref) {
        my $key_value;
        if ($use_entire_item) {
            $key_value = $item;
        } else {
            my @values = _traverse($item, $key_path);
            $key_value = @values ? $values[0] : undef;
        }

        my $signature = defined $key_value ? _key($key_value) : "\0__JQ_LITE_UNDEF__";
        push @entries, {
            item      => $item,
            signature => $signature,
            index     => $index++,
        };
    }

    my $cmp = _smart_cmp();
    my @sorted = sort {
        my $order = $cmp->($a->{signature}, $b->{signature});
        $order = $a->{index} <=> $b->{index} if $order == 0;
        $order;
    } @entries;

    my @groups;
    my $current_signature;
    for my $entry (@sorted) {
        if (!defined $current_signature || $entry->{signature} ne $current_signature) {
            push @groups, [];
            $current_signature = $entry->{signature};
        }
        push @{ $groups[-1] }, $entry->{item};
    }

    return \@groups;
}

sub _flatten_all {
    my ($value) = @_;

    return $value unless ref $value eq 'ARRAY';

    my @flattened;
    for my $item (@$value) {
        if (ref $item eq 'ARRAY') {
            my $flattened = _flatten_all($item);
            if (ref $flattened eq 'ARRAY') {
                push @flattened, @$flattened;
            } else {
                push @flattened, $flattened;
            }
        } else {
            push @flattened, $item;
        }
    }

    return \@flattened;
}

sub _flatten_depth {
    my ($value, $depth) = @_;

    return $value unless ref $value eq 'ARRAY';
    return $value if $depth <= 0;

    my @flattened;
    for my $item (@$value) {
        if (ref $item eq 'ARRAY') {
            my $flattened = _flatten_depth($item, $depth - 1);
            if (ref $flattened eq 'ARRAY') {
                push @flattened, @$flattened;
            } else {
                push @flattened, $flattened;
            }
        } else {
            push @flattened, $item;
        }
    }

    return \@flattened;
}

sub _apply_string_predicate {
    my ($value, $needle, $mode) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_string_predicate($_, $needle, $mode) } @$value ];
    }

    return _string_predicate_result($value, $needle, $mode);
}

sub _string_predicate_result {
    my ($value, $needle, $mode) = @_;

    return JSON::PP::false if !defined $value;
    return JSON::PP::false if ref $value;

    $needle //= '';
    my $len = length $needle;

    if ($mode eq 'start') {
        return JSON::PP::true if $len == 0 || index($value, $needle) == 0;
        return JSON::PP::false;
    }

    if ($mode eq 'end') {
        return JSON::PP::true if $len == 0;
        return JSON::PP::false if length($value) < $len;
        return JSON::PP::true if substr($value, -$len) eq $needle;
        return JSON::PP::false;
    }

    return JSON::PP::false;
}

sub _apply_test {
    my ($value, $pattern, $flags) = @_;

    my ($regex, $error) = _build_regex($pattern, $flags);
    if ($error) {
        $error =~ s/[\r\n]+$//;
        die "test(): invalid regular expression - $error";
    }

    return _test_against_regex($value, $regex);
}

sub _apply_match {
    my ($value, $pattern, $flags) = @_;

    my ($regex, $error) = _build_regex($pattern, $flags);
    if ($error) {
        $error =~ s/[\r\n]+$//;
        die "match(): invalid regular expression - $error";
    }

    return _match_against_regex($value, $regex);
}

sub _test_against_regex {
    my ($value, $regex) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _test_against_regex($_, $regex) } @$value ];
    }

    return JSON::PP::false if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 'true' : 'false';
    }

    return JSON::PP::false if ref $value;

    return $value =~ $regex ? JSON::PP::true : JSON::PP::false;
}

sub _match_against_regex {
    my ($value, $regex) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _match_against_regex($_, $regex) } @$value ];
    }

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 'true' : 'false';
    }

    return undef if ref $value;

    my $text = "$value";
    return undef unless $text =~ $regex;

    my $offset = $-[0];
    my $length = $+[0] - $-[0];
    my $string = substr($text, $offset, $length);

    my @captures;
    my $capture_count = $#-;
    for my $index (1 .. $capture_count) {
        if (defined $-[$index] && $-[$index] >= 0) {
            my $capture_offset = $-[$index];
            my $capture_length = $+[$index] - $-[$index];
            my $capture_string = substr($text, $capture_offset, $capture_length);
            push @captures, {
                offset => $capture_offset,
                length => $capture_length,
                string => $capture_string,
            };
        } else {
            push @captures, {
                offset => undef,
                length => undef,
                string => undef,
            };
        }
    }

    return {
        offset   => $offset,
        length   => $length,
        string   => $string,
        captures => \@captures,
    };
}

sub _build_regex {
    my ($pattern, $flags) = @_;

    $pattern = '' unless defined $pattern;
    $flags   = '' unless defined $flags;

    my %allowed = map { $_ => 1 } qw(i m s x);
    my $modifiers = '';
    for my $flag (split //, $flags) {
        return (undef, "unknown regex flag '$flag'") unless $allowed{$flag};
        next if index($modifiers, $flag) >= 0;
        $modifiers .= $flag;
    }

    my $escaped = $pattern;
    $escaped =~ s/'/\\'/g;

    my $regex = eval "qr'$escaped'$modifiers";
    if ($@) {
        return (undef, $@);
    }

    return ($regex, undef);
}

sub _parse_string_argument {
    my ($raw) = @_;

    return '' if !defined $raw;

    my $parsed = eval { _decode_json($raw) };
    if (!$@) {
        $parsed = '' if !defined $parsed;
        return $parsed;
    }

    $raw =~ s/^\s+|\s+$//g;
    $raw =~ s/^['"]//;
    $raw =~ s/['"]$//;
    return $raw;
}

sub _parse_literal_argument {
    my ($raw) = @_;

    return undef if !defined $raw;

    my $parsed = eval { _decode_json($raw) };
    return $parsed if !$@;

    $raw =~ s/^\s+|\s+$//g;
    $raw =~ s/^['"]//;
    $raw =~ s/['"]$//;
    return $raw;
}

sub _apply_csv {
    my ($value) = @_;

    if (ref $value eq 'ARRAY') {
        my @fields = map { _format_csv_field($_) } @$value;
        return join(',', @fields);
    }

    return _format_csv_field($value);
}

sub _apply_tsv {
    my ($value) = @_;

    if (ref $value eq 'ARRAY') {
        my @fields = map { _format_tsv_field($_) } @$value;
        return join("\t", @fields);
    }

    return _format_tsv_field($value);
}

sub _apply_base64 {
    my ($value) = @_;

    my $text;

    if (!defined $value) {
        $text = 'null';
    }
    elsif (ref($value) eq 'JSON::PP::Boolean') {
        $text = $value ? 'true' : 'false';
    }
    elsif (!ref $value) {
        $text = "$value";
    }
    elsif (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        $text = _encode_json($value);
    }
    else {
        $text = "$value";
    }

    return encode_base64($text, '');
}

sub _apply_base64d {
    my ($value) = @_;

    my $text;

    if (!defined $value) {
        $text = '';
    }
    elsif (ref($value) eq 'JSON::PP::Boolean') {
        $text = $value ? 'true' : 'false';
    }
    elsif (!ref $value) {
        $text = "$value";
    }
    elsif (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        $text = _encode_json($value);
    }
    else {
        $text = "$value";
    }

    $text =~ s/\s+//g;

    die '@base64d(): input must be base64 text'
        if length($text) % 4 != 0;

    die '@base64d(): input must be base64 text'
        if $text !~ /^[A-Za-z0-9+\/]*={0,2}$/;

    die '@base64d(): input must be base64 text'
        if $text =~ /=/ && $text !~ /=+$/;

    my $decoded = decode_base64($text);
    my $reencoded = encode_base64($decoded, '');

    die '@base64d(): input must be base64 text'
        if $reencoded ne $text;

    return $decoded;
}

sub _apply_uri {
    my ($value) = @_;

    my $text;

    if (!defined $value) {
        $text = 'null';
    }
    elsif (ref($value) eq 'JSON::PP::Boolean') {
        $text = $value ? 'true' : 'false';
    }
    elsif (!ref $value) {
        $text = "$value";
    }
    elsif (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        $text = _encode_json($value);
    }
    else {
        $text = "$value";
    }

    my $encoded = encode('UTF-8', $text);
    $encoded =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $encoded;
}

sub _format_csv_field {
    my ($value) = @_;

    return '' if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 'true' : 'false';
    }

    if (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        my $encoded = _encode_json($value);
        return _quote_csv_text($encoded);
    }

    if (ref $value) {
        my $stringified = "$value";
        return _quote_csv_text($stringified);
    }

    if (_is_unquoted_csv_number($value)) {
        return "$value";
    }

    my $text = "$value";
    return _quote_csv_text($text);
}

sub _format_tsv_field {
    my ($value) = @_;

    return '' if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 'true' : 'false';
    }

    if (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        my $encoded = _encode_json($value);
        return _escape_tsv_text($encoded);
    }

    if (ref $value) {
        my $stringified = "$value";
        return _escape_tsv_text($stringified);
    }

    my $text = "$value";
    return _escape_tsv_text($text);
}

sub _quote_csv_text {
    my ($text) = @_;

    $text = '' unless defined $text;
    $text =~ s/"/""/g;
    return '"' . $text . '"';
}

sub _escape_tsv_text {
    my ($text) = @_;

    $text = '' unless defined $text;
    $text =~ s/\\/\\\\/g;
    $text =~ s/\t/\\t/g;
    $text =~ s/\r/\\r/g;
    $text =~ s/\n/\\n/g;
    return $text;
}

sub _is_unquoted_csv_number {
    my ($value) = @_;

    return 0 if !defined $value;
    return 0 if ref $value;

    my $sv = B::svref_2object(\$value);
    my $flags = $sv->FLAGS;

    return ($flags & (B::SVp_IOK() | B::SVp_NOK())) ? 1 : 0;
}

sub _apply_split {
    my ($value, $separator) = @_;

    if (ref $value eq 'ARRAY') {
        my @parts;

        for my $element (@$value) {
            if (ref($element) eq 'JSON::PP::Boolean') {
                my $stringified = $element ? 'true' : 'false';
                my $result = _apply_split($stringified, $separator);
                push @parts, ref($result) eq 'ARRAY' ? @$result : $result;
                next;
            }

            my $result = _apply_split($element, $separator);
            push @parts, ref($result) eq 'ARRAY' ? @$result : $result;
        }

        return \@parts;
    }

    return undef if !defined $value;
    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 'true' : 'false';
    }
    elsif (ref $value) {
        return $value;
    }

    $separator = '' unless defined $separator;

    if ($separator eq '') {
        return [ split(//, $value) ];
    }

    my $pattern = quotemeta $separator;
    my @parts = split /$pattern/, $value, -1;
    return [ @parts ];
}

sub _apply_explode {
    my ($value) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_explode($_) } @$value ];
    }

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 'true' : 'false';
    }

    return $value if ref $value;

    my @chars = split(//u, "$value");
    return [ map { ord($_) } @chars ];
}

sub _apply_implode {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref $value eq 'ARRAY') {
        my $has_nested = grep { ref $_ } @$value;

        if ($has_nested) {
            return [ map { _apply_implode($_) } @$value ];
        }

        my $string = '';
        for my $code (@$value) {
            next unless defined $code;
            next unless looks_like_number($code);
            $string .= chr(int($code));
        }
        return $string;
    }

    return $value;
}

sub _apply_substr {
    my ($value, @args) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_substr($_, @args) } @$value ];
    }

    return undef if !defined $value;
    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 'true' : 'false';
    }
    elsif (ref $value) {
        return $value;
    }

    my ($start, $length) = @args;
    if (defined $start && !looks_like_number($start)) {
        die 'substr(): start index must be numeric';
    }
    $start = 0 unless defined $start;
    $start = int($start);

    if (defined $length) {
        if (!looks_like_number($length)) {
            die 'substr(): length must be numeric';
        }
        $length = int($length);
        return substr($value, $start, $length);
    }

    return substr($value, $start);
}

sub _apply_slice {
    my ($value, @args) = @_;

    return undef if !defined $value;

    if (ref $value eq 'ARRAY') {
        my $array = $value;
        my $size  = @$array;

        return [] if $size == 0;

        my $raw_start = @args ? $args[0] : 0;
        my $start     = 0;

        if (defined $raw_start && !looks_like_number($raw_start)) {
            die 'slice(): start must be numeric';
        }

        if (defined $raw_start && looks_like_number($raw_start)) {
            $start = int($raw_start);
        }

        $start += $size if $start < 0;
        $start = 0       if $start < 0;
        return []        if $start >= $size;

        my $length;
        if (@args > 1 && defined $args[1] && !looks_like_number($args[1])) {
            die 'slice(): length must be numeric';
        }

        if (@args > 1 && defined $args[1] && looks_like_number($args[1])) {
            $length = int($args[1]);
        }

        my $end;
        if (defined $length) {
            return [] if $length <= 0;
            $end = $start + $length;
        }
        else {
            $end = $size;
        }

        $end = $size if $end > $size;

        return [] if $end <= $start;

        return [ @$array[$start .. $end - 1] ];
    }

    return $value;
}

sub _apply_replace {
    my ($value, $search, $replacement) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_replace($_, $search, $replacement) } @$value ];
    }

    return $value if !defined $value;
    return $value if ref $value;

    return $value if looks_like_number($value);

    $search      = defined $search      ? "$search"      : '';
    $replacement = defined $replacement ? "$replacement" : '';

    return $value if $search eq '';

    my $pattern = quotemeta $search;
    (my $copy = "$value") =~ s/$pattern/$replacement/g;
    return $copy;
}

sub _apply_pick {
    my ($value, $keys) = @_;

    return $value unless @$keys;

    if (ref $value eq 'HASH') {
        my %subset;
        for my $key (@$keys) {
            next unless defined $key;
            next unless exists $value->{$key};
            $subset{$key} = $value->{$key};
        }
        return \%subset;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_pick($_, $keys) } @$value ];
    }

    return $value;
}

sub _parse_arguments {
    my ($raw) = @_;

    return () unless defined $raw;

    my $parsed = eval { _decode_json("[$raw]") };
    if (!$@ && ref $parsed eq 'ARRAY') {
        return @$parsed;
    }

    my @parts = split /,/, $raw;
    return map {
        my $part = $_;
        $part =~ s/^\s+|\s+$//g;
        $part;
    } @parts;
}

sub _split_semicolon_arguments {
    my ($raw, $expected) = @_;

    $raw //= '';

    my @segments;
    my $current   = '';
    my $depth     = 0;
    my $in_single = 0;
    my $in_double = 0;
    my $escape    = 0;

    for my $char (split //, $raw) {
        if ($escape) {
            $current .= $char;
            $escape = 0;
            next;
        }

        if ($char eq '\\' && $in_double) {
            $current .= $char;
            $escape = 1;
            next;
        }

        if ($char eq '"' && !$in_single) {
            $in_double = !$in_double;
            $current  .= $char;
            next;
        }

        if ($char eq "'" && !$in_double) {
            $in_single = !$in_single;
            $current  .= $char;
            next;
        }

        if (!$in_single && !$in_double) {
            if ($char =~ /[\[\{\(]/) {
                $depth++;
            }
            elsif ($char =~ /[\]\}\)]/ && $depth > 0) {
                $depth--;
            }
            elsif ($char eq ';' && $depth == 0) {
                my $segment = $current;
                $segment =~ s/^\s+|\s+$//g;
                push @segments, length $segment ? $segment : undef;
                $current = '';
                next;
            }
        }

        $current .= $char;
    }

    my $final = $current;
    $final =~ s/^\s+|\s+$//g;
    push @segments, length $final ? $final : undef;

    if (defined $expected) {
        $expected = int($expected);
        if ($expected > @segments) {
            push @segments, (undef) x ($expected - @segments);
        }
    }

    return @segments;
}

sub _parse_range_arguments {
    my ($raw) = @_;

    return () unless defined $raw;

    $raw =~ s/^\s+|\s+$//g;
    return () if $raw eq '';

    my @segments;
    my $current    = '';
    my $in_single  = 0;
    my $in_double  = 0;
    my $escape     = 0;

    for my $char (split //, $raw) {
        if ($escape) {
            $current .= $char;
            $escape = 0;
            next;
        }

        if ($char eq '\\' && $in_double) {
            $current .= $char;
            $escape = 1;
            next;
        }

        if ($char eq '"' && !$in_single) {
            $in_double = !$in_double;
            $current  .= $char;
            next;
        }

        if ($char eq "'" && !$in_double) {
            $in_single = !$in_single;
            $current  .= $char;
            next;
        }

        if ($char eq ';' && !$in_single && !$in_double) {
            push @segments, $current;
            $current = '';
            next;
        }

        $current .= $char;
    }

    push @segments, $current;

    my @args;
    for my $segment (@segments) {
        next unless defined $segment;
        my $clean = $segment;
        $clean =~ s/^\s+|\s+$//g;
        next if $clean eq '';

        my @values = _parse_arguments($clean);
        my $value  = @values ? $values[0] : undef;
        push @args, $value;
    }

    return @args;
}

sub _apply_range {
    my ($value, $args_ref) = @_;

    my $sequence = _build_range_sequence($args_ref);
    return @$sequence;
}

sub _build_range_sequence {
    my ($args_ref) = @_;

    my @args = @$args_ref;
    die 'range(): bounds must be numeric' unless @args;

    @args = @args[0 .. 2] if @args > 3;

    my ($start, $end, $step);

    if (@args == 1) {
        $start = 0;
        $end   = _coerce_range_number($args[0]);
        $step  = 1;
    }
    elsif (@args == 2) {
        $start = _coerce_range_number($args[0]);
        $end   = _coerce_range_number($args[1]);
        $step  = 1;
    }
    else {
        $start = _coerce_range_number($args[0]);
        $end   = _coerce_range_number($args[1]);
        $step  = _coerce_range_number($args[2]);
    }

    die 'range(): bounds must be numeric' unless defined $start && defined $end;
    die 'range(): step must be numeric'    if !defined $step;
    return []    if $step == 0;

    if ($step > 0) {
        return [] if $start >= $end;
        my @sequence;
        for (my $current = $start; $current < $end; $current += $step) {
            push @sequence, 0 + $current;
        }
        return \@sequence;
    }

    # negative step
    return [] if $start <= $end;

    my @sequence;
    for (my $current = $start; $current > $end; $current += $step) {
        push @sequence, 0 + $current;
    }

    return \@sequence;
}

sub _coerce_range_number {
    my ($value) = @_;

    return undef if !defined $value;
    return undef if ref $value;
    return undef if _is_string_scalar($value);

    return looks_like_number($value) ? 0 + $value : undef;
}

sub _apply_contains {
    my ($value, $needle) = @_;

    return _deep_contains($value, $needle, 'legacy') ? JSON::PP::true : JSON::PP::false;
}

sub _apply_contains_subset {
    my ($value, $needle) = @_;

    return _deep_contains($value, $needle, 'subset') ? JSON::PP::true : JSON::PP::false;
}

sub _apply_inside {
    my ($value, $container) = @_;

    return _apply_contains($container, $value);
}

sub _apply_indices {
    my ($value, $needle) = @_;

    if (ref $value eq 'ARRAY') {
        my @matches;
        for my $i (0 .. $#$value) {
            push @matches, $i if _values_equal($value->[$i], $needle);
        }
        return \@matches;
    }

    return [] if !defined $value;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        return [] unless defined $needle;

        my $haystack = "$value";
        my $fragment = "$needle";

        my @positions;
        if ($fragment eq '') {
            @positions = (0 .. length($haystack));
        }
        else {
            my $pos = -1;
            while (1) {
                $pos = index($haystack, $fragment, $pos + 1);
                last if $pos == -1;
                push @positions, $pos;
            }
        }

        return \@positions;
    }

    return [];
}

sub _apply_has {
    my ($value, $needle) = @_;

    return JSON::PP::false if !defined $needle;

    if (ref $value eq 'HASH') {
        return exists $value->{$needle} ? JSON::PP::true : JSON::PP::false;
    }

    if (ref $value eq 'ARRAY') {
        return JSON::PP::false if ref $needle;

        my $sv = B::svref_2object(\$needle);
        my $flags = $sv->FLAGS;
        return JSON::PP::false unless ($flags & (B::SVp_IOK() | B::SVp_NOK()));

        my $index = int($needle);
        return ($index >= 0 && $index < @$value)
            ? JSON::PP::true
            : JSON::PP::false;
    }

    return JSON::PP::false;
}

sub _values_equal {
    my ($left, $right) = @_;

    return 1 if !defined $left && !defined $right;
    return 0 if !defined $left || !defined $right;

    if (ref($left) eq 'JSON::PP::Boolean' && ref($right) eq 'JSON::PP::Boolean') {
        return (!!$left) == (!!$right);
    }

    if (!ref $left && !ref $right) {
        if (looks_like_number($left) && looks_like_number($right)) {
            return $left == $right;
        }
        return "$left" eq "$right";
    }

    if (ref $left eq 'ARRAY' && ref $right eq 'ARRAY') {
        return 0 if @$left != @$right;
        for (my $i = 0; $i < @$left; $i++) {
            return 0 unless _values_equal($left->[$i], $right->[$i]);
        }
        return 1;
    }

    if (ref $left eq 'HASH' && ref $right eq 'HASH') {
        return 0 if keys(%$left) != keys(%$right);
        for my $key (keys %$left) {
            return 0 unless exists $right->{$key} && _values_equal($left->{$key}, $right->{$key});
        }
        return 1;
    }

    return 0;
}

sub _deep_contains {
    my ($value, $needle, $mode) = @_;

    $mode ||= 'legacy';

    return 1 if !defined $value && !defined $needle;
    return 0 if !defined $value;

    if (ref $value eq 'ARRAY') {
        return _array_contains($value, $needle, $mode);
    }

    if (ref $value eq 'HASH') {
        return _hash_contains($value, $needle, $mode);
    }

    return _scalar_contains($value, $needle);
}

sub _array_contains {
    my ($haystack, $needle, $mode) = @_;

    if ($mode eq 'subset' && ref $needle eq 'ARRAY') {
        my @used;
        NEEDLE: for my $expected (@$needle) {
            for my $i (0 .. $#$haystack) {
                next if $used[$i];
                if (_deep_contains($haystack->[$i], $expected, $mode)) {
                    $used[$i] = 1;
                    next NEEDLE;
                }
            }
            return 0;
        }
        return 1;
    }

    for my $item (@$haystack) {
        return 1 if _values_equal($item, $needle);
    }

    return 0;
}

sub _hash_contains {
    my ($value, $needle, $mode) = @_;

    if (ref $needle eq 'HASH') {
        for my $key (keys %$needle) {
            return 0 unless exists $value->{$key};

            if ($mode eq 'legacy') {
                return 0 unless _values_equal($value->{$key}, $needle->{$key});
            }
            else {
                return 0 unless _deep_contains($value->{$key}, $needle->{$key}, $mode);
            }
        }
        return 1;
    }

    return exists $value->{$needle} ? 1 : 0;
}

sub _scalar_contains {
    my ($value, $needle) = @_;

    return 0 if !defined $value;
    return 0 if !defined $needle;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        my $haystack = "$value";
        my $fragment = "$needle";
        return index($haystack, $fragment) >= 0 ? 1 : 0;
    }

    return 0;
}

sub _ceil {
    my ($number) = @_;

    return $number if int($number) == $number;
    return $number > 0 ? int($number) + 1 : int($number);
}

sub _floor {
    my ($number) = @_;

    return $number if int($number) == $number;
    return $number > 0 ? int($number) : int($number) - 1;
}

sub _round {
    my ($number) = @_;

    return $number if int($number) == $number;
    return $number >= 0 ? int($number + 0.5) : int($number - 0.5);
}

sub _group_count {
    my ($array_ref, $path) = @_;
    return {} unless ref $array_ref eq 'ARRAY';

    my ($key_path, $use_entire_item) = _normalize_path_argument($path);

    my %counts;
    for my $item (@$array_ref) {
        my $key_value;
        if ($use_entire_item) {
            $key_value = $item;
        }
        else {
            my @values = _traverse($item, $key_path);
            $key_value = @values ? $values[0] : undef;
        }

        my $key = defined $key_value ? _key($key_value) : 'null';
        $counts{$key}++;
    }

    return \%counts;
}

1;
