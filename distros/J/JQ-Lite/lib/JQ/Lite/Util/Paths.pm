package JQ::Lite::Util;

use strict;
use warnings;

use JSON::PP ();
use Scalar::Util qw(looks_like_number);

sub _apply_assignment {
    my ($self, $item, $path, $value_spec, $operator) = @_;

    return $item unless defined $item;
    return $item unless defined $path && length $path;

    $operator //= '=';

    my $value = _resolve_assignment_value($self, $item, $value_spec);

    if ($operator ne '=') {
        my $current = _clone_for_assignment(_get_path_value($item, $path));
        my $current_num = _coerce_number($current);
        my $value_num   = _coerce_number($value);

        return $item unless defined $current_num && defined $value_num;

        my $result;
        if ($operator eq '+=') {
            $result = $current_num + $value_num;
        }
        elsif ($operator eq '-=') {
            $result = $current_num - $value_num;
        }
        elsif ($operator eq '*=') {
            $result = $current_num * $value_num;
        }
        elsif ($operator eq '/=') {
            return $item if $value_num == 0;
            $result = $current_num / $value_num;
        }
        else {
            return $item;
        }

        $value = $result;
    }

    _set_path_value($item, $path, $value);

    return $item;
}

sub _get_path_value {
    my ($target, $path) = @_;

    return undef unless defined $target;
    return undef unless defined $path && length $path;

    my @segments = _parse_path_segments($path);
    return undef unless @segments;

    my $cursor = $target;
    for my $index (0 .. $#segments) {
        my $segment = $segments[$index];
        my $is_last = ($index == $#segments);

        if ($segment->{type} eq 'key') {
            return undef unless ref $cursor eq 'HASH';
            my $key = $segment->{value};

            return $cursor->{$key} if $is_last;

            return undef unless exists $cursor->{$key};
            $cursor = $cursor->{$key};
            next;
        }

        if ($segment->{type} eq 'index') {
            return undef unless ref $cursor eq 'ARRAY';

            my $idx = $segment->{value};
            my $numeric = int($idx);
            if ($idx =~ /^-?\d+$/) {
                $numeric += @$cursor if $numeric < 0;
            }

            return undef if $numeric < 0 || $numeric > $#$cursor;

            return $cursor->[$numeric] if $is_last;

            $cursor = $cursor->[$numeric];
            next;
        }
    }

    return undef;
}

sub _coerce_number {
    my ($value) = @_;

    return 0 if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    return 0 + $value if looks_like_number($value);

    return undef;
}

sub _resolve_assignment_value {
    my ($self, $item, $value_spec) = @_;

    return undef unless defined $value_spec;

    if ($value_spec->{type} && $value_spec->{type} eq 'path') {
        my $path = $value_spec->{value} // '';
        $path =~ s/^\.//;

        my @values = _traverse($item, $path);
        return _clone_for_assignment($values[0]);
    }

    if ($value_spec->{type} && $value_spec->{type} eq 'expression') {
        my $expr = $value_spec->{value} // '';

        my ($values, $ok) = _evaluate_value_expression($self, $item, $expr);
        if ($ok) {
            return _clone_for_assignment(@$values ? $values->[0] : undef);
        }

        if (defined $self && $self->can('run_query')) {
            my @outputs = $self->run_query(_encode_json($item), $expr);
            return _clone_for_assignment($outputs[0]) if @outputs;
        }

        return _clone_for_assignment($expr);
    }

    return _clone_for_assignment($value_spec->{value});
}

sub _set_path_value {
    my ($target, $path, $value) = @_;

    return unless defined $target;

    my @segments = _parse_path_segments($path);
    return unless @segments;

    my $cursor = $target;
    for my $index (0 .. $#segments) {
        my $segment = $segments[$index];
        my $is_last = ($index == $#segments);

        if ($segment->{type} eq 'key') {
            return unless ref $cursor eq 'HASH';
            my $key = $segment->{value};

            if ($is_last) {
                $cursor->{$key} = $value;
                last;
            }

            if (!exists $cursor->{$key} || !defined $cursor->{$key}) {
                my $next = $segments[$index + 1];
                $cursor->{$key} = ($next->{type} eq 'index') ? [] : {};
            }

            $cursor = $cursor->{$key};
            next;
        }

        if ($segment->{type} eq 'index') {
            return unless ref $cursor eq 'ARRAY';

            my $idx = $segment->{value};
            my $numeric = int($idx);
            if ($idx =~ /^-?\d+$/) {
                $numeric += @$cursor if $numeric < 0;
            }

            return if $numeric < 0;

            if ($is_last) {
                $cursor->[$numeric] = $value;
                last;
            }

            if (!defined $cursor->[$numeric]) {
                my $next = $segments[$index + 1];
                $cursor->[$numeric] = ($next->{type} eq 'index') ? [] : {};
            }

            $cursor = $cursor->[$numeric];
            next;
        }
    }

    return;
}

sub _parse_path_segments {
    my ($path) = @_;

    $path //= '';
    $path =~ s/^\s+|\s+$//g;

    my @segments;
    for my $chunk (split /\./, $path) {
        next if $chunk eq '';

        while (length $chunk) {
            if ($chunk =~ s/^\[(\-?\d+)\]//) {
                push @segments, { type => 'index', value => $1 };
                next;
            }

            if ($chunk =~ s/^([^\[]+)//) {
                push @segments, { type => 'key', value => $1 };
                next;
            }

            last;
        }
    }

    return @segments;
}

sub _clone_for_assignment {
    my ($value) = @_;

    return undef unless defined $value;
    return $value unless ref $value;

    my $json = _encode_json($value);
    return _decode_json($json);
}

sub _map {
    my ($self, $data, $filter) = @_;

    if (ref $data ne 'ARRAY') {
        warn "_map expects array reference";
        return ();
    }

    my @mapped;
    for my $item (@$data) {
        push @mapped, $self->run_query(_encode_json($item), $filter);
    }

    return @mapped;
}

sub _apply_all {
    my ($self, $value, $expr) = @_;

    if (ref $value eq 'ARRAY') {
        return JSON::PP::true unless @$value;

        for my $item (@$value) {
            if (defined $expr) {
                my @evaluated = $self->run_query(_encode_json($item), $expr);
                return JSON::PP::false unless @evaluated;
                return JSON::PP::false if grep { !_is_truthy($_) } @evaluated;
            }
            else {
                return JSON::PP::false unless _is_truthy($item);
            }
        }

        return JSON::PP::true;
    }

    if (defined $expr) {
        my @evaluated = $self->run_query(_encode_json($value), $expr);
        return JSON::PP::false unless @evaluated;
        return grep { !_is_truthy($_) } @evaluated ? JSON::PP::false : JSON::PP::true;
    }

    return _is_truthy($value) ? JSON::PP::true : JSON::PP::false;
}

sub _apply_any {
    my ($self, $value, $expr) = @_;

    if (ref $value eq 'ARRAY') {
        return JSON::PP::false unless @$value;

        for my $item (@$value) {
            if (defined $expr) {
                my @evaluated = $self->run_query(_encode_json($item), $expr);
                return JSON::PP::true if grep { _is_truthy($_) } @evaluated;
            }
            else {
                return JSON::PP::true if _is_truthy($item);
            }
        }

        return JSON::PP::false;
    }

    if (defined $expr) {
        my @evaluated = $self->run_query(_encode_json($value), $expr);
        return grep { _is_truthy($_) } @evaluated ? JSON::PP::true : JSON::PP::false;
    }

    return _is_truthy($value) ? JSON::PP::true : JSON::PP::false;
}

sub _is_truthy {
    my ($value) = @_;

    return 0 unless defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (ref $value eq 'ARRAY') {
        return @$value ? 1 : 0;
    }

    if (ref $value eq 'HASH') {
        return scalar(keys %$value) ? 1 : 0;
    }

    if (!ref $value) {
        return 0 if $value eq '';
        if (looks_like_number($value)) {
            return $value != 0 ? 1 : 0;
        }
        return 1;
    }

    return 1;
}

sub _apply_case_transform {
    my ($value, $mode) = @_;

    if (!defined $value) {
        return undef;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_case_transform($_, $mode) } @$value ];
    }

    if (!ref $value) {
        return uc $value      if $mode eq 'upper';
        return lc $value      if $mode eq 'lower';
        return _to_titlecase($value);
    }

    return $value;
}

sub _apply_ascii_case_transform {
    my ($value, $mode) = @_;

    if (!defined $value) {
        return undef;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_ascii_case_transform($_, $mode) } @$value ];
    }

    if (!ref $value) {
        my $copy = $value;
        if ($mode eq 'upper') {
            $copy =~ tr/a-z/A-Z/;
        }
        elsif ($mode eq 'lower') {
            $copy =~ tr/A-Z/a-z/;
        }
        return $copy;
    }

    return $value;
}

sub _to_titlecase {
    my ($value) = @_;

    my $result = lc $value;
    $result =~ s/(^|[^\p{L}\p{N}])(\p{L})/$1 . uc($2)/ge;
    return $result;
}

sub _apply_trim {
    my ($value) = @_;

    if (!defined $value) {
        return undef;
    }

    if (!ref $value) {
        my $copy = $value;
        $copy =~ s/^\s+//;
        $copy =~ s/\s+$//;
        return $copy;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_trim($_) } @$value ];
    }

    return $value;
}

sub _apply_trimstr {
    my ($value, $needle, $mode) = @_;

    if (!defined $value) {
        return undef;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_trimstr($_, $needle, $mode) } @$value ];
    }

    if (ref $value) {
        return $value;
    }

    return $value if !_is_string_scalar($value);

    $needle = '' unless defined $needle;
    my $target = "$value";
    my $pattern = "$needle";
    my $len = length $pattern;

    return $target if $len == 0;

    if ($mode eq 'left') {
        return $target if index($target, $pattern) != 0;
        return substr($target, $len);
    }

    if ($mode eq 'right') {
        return $target if $len > length($target);
        return $target unless substr($target, -$len) eq $pattern;
        return substr($target, 0, length($target) - $len);
    }

    return $target;
}

sub _apply_paths {
    my ($value) = @_;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        return [];
    }

    my @paths;
    _collect_paths($value, [], \@paths);
    return \@paths;
}

sub _apply_scalar_paths {
    my ($value) = @_;

    return [] if _is_scalar_value($value);

    my @paths;
    _collect_scalar_paths($value, [], \@paths);
    return \@paths;
}

sub _apply_leaf_paths {
    my ($value) = @_;

    if (_is_leaf_value($value)) {
        return [ [] ];
    }

    my @paths;
    _collect_leaf_paths($value, [], \@paths);
    return \@paths;
}

sub _validate_path_array {
    my ($path, $caller) = @_;

    $caller //= 'getpath';

    die "$caller(): path must be an array" if ref($path) ne 'ARRAY';

    for my $segment (@$path) {
        my $is_boolean = ref($segment) && ref($segment) eq 'JSON::PP::Boolean';

        die "$caller(): path elements must be defined" if !defined $segment;
        die "$caller(): path elements must be scalars" if ref($segment) && !$is_boolean;
    }

    return [ @$path ];
}

sub _apply_getpath {
    my ($self, $value, $expr) = @_;

    return undef unless defined $value;

    $expr //= '';
    $expr =~ s/^\s+|\s+$//g;
    return undef if $expr eq '';

    my @paths;

    my $decoded = eval { _decode_json($expr) };
    if (!$@ && defined $decoded) {
        if (ref $decoded eq 'ARRAY') {
            if (@$decoded && ref $decoded->[0] eq 'ARRAY') {
                    for my $path (@$decoded) {
                        push @paths, _validate_path_array($path, 'getpath');
                    }
            }
            else {
                push @paths, _validate_path_array($decoded, 'getpath');
            }
        }
        else {
            die 'getpath(): path must be an array';
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(_encode_json($value), $expr);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    for my $path (@$output) {
                        push @paths, _validate_path_array($path, 'getpath');
                    }
                }
                else {
                    push @paths, _validate_path_array($output, 'getpath');
                }
            }
            else {
                die 'getpath(): path must be an array';
            }
        }
    }

    return undef unless @paths;

    my @values = map { _traverse_path_array($value, $_) } @paths;
    return @values == 1 ? $values[0] : \@values;
}

sub _apply_setpath {
    my ($self, $value, $paths_expr, $value_expr) = @_;

    return $value unless defined $value;

    $paths_expr //= '';
    $paths_expr =~ s/^\s+|\s+$//g;
    return $value if $paths_expr eq '';

    my @paths = _resolve_paths_from_expr($self, $value, $paths_expr);
    return $value unless @paths;

    my $replacement = _evaluate_setpath_value($self, $value, $value_expr);
    my $result      = $value;

    for my $path (@paths) {
        $result = _set_value_at_path($result, [@$path], $replacement);
    }

    return $result;
}

sub _resolve_paths_from_expr {
    my ($self, $value, $expr) = @_;

    return () unless defined $expr;

    my $clean = $expr;
    $clean =~ s/^\s+|\s+$//g;
    return () if $clean eq '';

    my @paths;

    my $decoded = eval { _decode_json($clean) };
    if (!$@ && defined $decoded) {
        if (ref $decoded eq 'ARRAY') {
            if (@$decoded && ref $decoded->[0] eq 'ARRAY') {
                push @paths, map { _validate_path_array($_, 'setpath') } @$decoded;
            }
            else {
                push @paths, _validate_path_array($decoded, 'setpath');
            }
        }
        else {
            die 'setpath(): path must be an array';
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(_encode_json($value), $clean);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    push @paths, map { _validate_path_array($_, 'setpath') } @$output;
                }
                elsif (!@$output || !ref $output->[0]) {
                    push @paths, _validate_path_array($output, 'setpath');
                }
            }
            elsif (!ref $output || ref($output) eq 'JSON::PP::Boolean') {
                die 'setpath(): path must be an array';
            }
        }
    }

    return @paths;
}

sub _evaluate_setpath_value {
    my ($self, $context, $expr) = @_;

    return undef unless defined $expr;

    my $clean = $expr;
    $clean =~ s/^\s+|\s+$//g;
    return undef if $clean eq '';

    my $decoded = eval { _decode_json($clean) };
    if (!$@) {
        return $decoded;
    }

    if ($clean =~ /^'(.*)'$/) {
        my $text = $1;
        $text =~ s/\\'/'/g;
        return $text;
    }

    if ($clean =~ /^\.(.+)$/) {
        my $path = $1;
        my @values = _traverse($context, $path);
        return @values ? $values[0] : undef;
    }

    my @outputs = $self->run_query(_encode_json($context), $clean);
    return @outputs ? $outputs[0] : undef;
}

sub _set_value_at_path {
    my ($current, $path, $replacement) = @_;

    return _deep_clone($replacement) unless @$path;

    my ($segment, @rest) = @$path;

    if (ref $current eq 'HASH') {
        my $key = _coerce_hash_key($segment);
        return $current unless defined $key;

        my %copy = %$current;
        if (@rest) {
            my $next_value = exists $copy{$key} ? $copy{$key} : _guess_container_for_segment($rest[0]);
            $copy{$key} = _set_value_at_path($next_value, \@rest, $replacement);
        }
        else {
            $copy{$key} = _deep_clone($replacement);
        }

        return \%copy;
    }

    if (ref $current eq 'ARRAY') {
        my $index = _normalize_array_index_for_set($segment, scalar @$current);
        return $current unless defined $index;

        my @copy = @$current;
        _ensure_array_length(\@copy, $index);

        if (@rest) {
            my $next_value = defined $copy[$index] ? $copy[$index] : _guess_container_for_segment($rest[0]);
            $copy[$index] = _set_value_at_path($next_value, \@rest, $replacement);
        }
        else {
            $copy[$index] = _deep_clone($replacement);
        }

        return \@copy;
    }

    my $container = _guess_container_for_segment($segment);
    return _set_value_at_path($container, $path, $replacement);
}

sub _coerce_hash_key {
    my ($segment) = @_;

    return undef if !defined $segment;

    if (ref($segment) eq 'JSON::PP::Boolean') {
        return $segment ? 'true' : 'false';
    }

    return undef if ref $segment;

    return "$segment";
}

sub _guess_container_for_segment {
    my ($segment) = @_;

    return [] if _is_numeric_segment($segment);
    return {};
}

sub _is_numeric_segment {
    my ($segment) = @_;

    return 0 if !defined $segment;

    if (ref($segment) eq 'JSON::PP::Boolean') {
        return 1;
    }

    return 0 if ref $segment;

    return ($segment =~ /^-?\d+$/) ? 1 : 0;
}

sub _normalize_array_index_for_set {
    my ($segment, $length) = @_;

    return undef if !defined $segment;

    if (ref($segment) eq 'JSON::PP::Boolean') {
        $segment = $segment ? 1 : 0;
    }

    return undef if ref $segment;
    return undef if $segment !~ /^-?\d+$/;

    my $index = int($segment);
    $index += $length if $index < 0;

    return undef if $index < 0;

    return $index;
}

sub _normalize_array_index_for_get {
    my ($segment, $length) = @_;

    return undef if !defined $segment;

    if (ref($segment) eq 'JSON::PP::Boolean') {
        $segment = $segment ? 1 : 0;
    }

    return undef if ref $segment;
    return undef if $segment !~ /^-?\d+$/;

    my $index = int($segment);
    $index += $length if $index < 0;

    return undef if $index < 0;

    return $index;
}

sub _ensure_array_length {
    my ($array_ref, $index) = @_;

    return unless ref $array_ref eq 'ARRAY';

    while (@$array_ref <= $index) {
        push @$array_ref, undef;
    }
}

sub _collect_paths {
    my ($value, $current_path, $paths) = @_;

    if (ref $value eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child = $value->{$key};
            my @next  = (@$current_path, $key);
            push @$paths, [@next];

            if (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
                _collect_paths($child, \@next, $paths);
            }
        }
        return;
    }

    if (ref $value eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $child = $value->[$index];
            my @next  = (@$current_path, $index);
            push @$paths, [@next];

            if (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
                _collect_paths($child, \@next, $paths);
            }
        }
        return;
    }

    push @$paths, [@$current_path];
}

sub _collect_scalar_paths {
    my ($value, $current_path, $paths) = @_;

    if (ref $value eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child = $value->{$key};
            my @next  = (@$current_path, $key);

            if (_is_scalar_value($child)) {
                push @$paths, [@next];
            }
            elsif (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
                _collect_scalar_paths($child, \@next, $paths);
            }
        }
        return;
    }

    if (ref $value eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $child = $value->[$index];
            my @next  = (@$current_path, $index);

            if (_is_scalar_value($child)) {
                push @$paths, [@next];
            }
            elsif (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
                _collect_scalar_paths($child, \@next, $paths);
            }
        }
        return;
    }
}

sub _traverse_path_array {
    my ($value, $path) = @_;

    return undef unless defined $value;
    return $value unless defined $path;
    return $value if ref($path) ne 'ARRAY';

    my $cursor = $value;
    for my $segment (@$path) {
        return undef unless defined $cursor;

        if (ref $cursor eq 'HASH') {
            my $key = _coerce_hash_key($segment);
            return undef unless defined $key;
            return undef unless exists $cursor->{$key};
            $cursor = $cursor->{$key};
            next;
        }

        if (ref $cursor eq 'ARRAY') {
            my $index = _normalize_array_index_for_get($segment, scalar @$cursor);
            return undef unless defined $index;

            return undef if $index > $#$cursor;

            $cursor = $cursor->[$index];
            next;
        }

        return undef;
    }

    return $cursor;
}

sub _collect_leaf_paths {
    my ($value, $current_path, $paths) = @_;

    if (ref $value eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child = $value->{$key};
            my @next  = (@$current_path, $key);

            if (_is_leaf_value($child)) {
                push @$paths, [@next];
            }
            else {
                _collect_leaf_paths($child, \@next, $paths);
            }
        }
        return;
    }

    if (ref $value eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $child = $value->[$index];
            my @next  = (@$current_path, $index);

            if (_is_leaf_value($child)) {
                push @$paths, [@next];
            }
            else {
                _collect_leaf_paths($child, \@next, $paths);
            }
        }
        return;
    }

    push @$paths, [@$current_path];
}

sub _is_leaf_value {
    my ($value) = @_;

    return 1 unless ref $value;
    return 1 if ref($value) eq 'JSON::PP::Boolean';
    return 0 if ref($value) eq 'ARRAY';
    return 0 if ref($value) eq 'HASH';
    return 1;
}

sub _is_scalar_value {
    return _is_leaf_value(@_);
}

1;
