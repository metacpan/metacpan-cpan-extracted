package JQ::Lite::Filters;

use strict;
use warnings;

use List::Util qw(sum min max);
use Scalar::Util qw(looks_like_number);
use B qw(SVp_IOK SVp_NOK);
use JQ::Lite::Util ();

sub apply {
    my ($self, $part, $results_ref, $out_ref) = @_;

    my @results = @$results_ref;
    my @next_results;

    my $normalized = JQ::Lite::Util::_strip_wrapping_parens($part);

        my @sequence_parts = JQ::Lite::Util::_split_top_level_commas($normalized);
        if (@sequence_parts > 1) {
            @next_results = ();

            for my $item (@results) {
                my $json = JQ::Lite::Util::_encode_json($item);

                for my $segment (@sequence_parts) {
                    next unless defined $segment;
                    my $filter = $segment;
                    $filter =~ s/^\s+|\s+$//g;
                    $filter = JQ::Lite::Util::_strip_wrapping_parens($filter);
                    next if $filter eq '';

                    if ($filter !~ /^\s*[\[{(]/) {
                        my ($values, $ok) = JQ::Lite::Util::_evaluate_value_expression($self, $item, $filter);
                        if ($ok) {
                            if (@$values) {
                                push @next_results, @$values;
                                next;
                            }
                            # fall through to the full evaluator when the shortcut produced no
                            # values so we don't accidentally drop a legitimate branch
                        }
                    }

                    my @outputs = $self->run_query($json, $filter);
                    push @next_results, @outputs;
                }
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for variable references like $var or $var.path
        if ($normalized =~ /^\$(\w+)(.*)$/s) {
            my ($var_name, $suffix) = ($1, $2 // '');
            for my $item (@results) {
                my @values = JQ::Lite::Util::_evaluate_variable_reference($self, $var_name, $suffix);
                if (@values) {
                    push @next_results, @values;
                } else {
                    push @next_results, undef;
                }
            }
            @$out_ref = @next_results;
            return 1;
        }

        # support for binding the current value to a variable: . as $x | ...
        if ($normalized =~ /^as\s+\$(\w+)$/) {
            my $var_name = $1;
            @next_results = ();

            for my $item (@results) {
                $self->{_vars}{$var_name} = $item;
                push @next_results, $item;
            }

            @$out_ref = @next_results;
            return 1;
        }

        if ($normalized =~ /^try\b/) {
            my $body = $normalized;
            $body =~ s/^try\s*//;

            my ($try_expr, $catch_expr) = ($body, '');

            my %pairs = (
                '(' => ')',
                '[' => ']',
                '{' => '}',
            );
            my %closing = reverse %pairs;

            my @stack;
            my $string;
            my $escape = 0;
            my $catch_index = undef;
            for (my $i = 0; $i < length $body; $i++) {
                my $ch = substr($body, $i, 1);

                if (defined $string) {
                    if ($escape) {
                        $escape = 0;
                        next;
                    }

                    if ($ch eq '\\') {
                        $escape = 1;
                        next;
                    }

                    if ($ch eq $string) {
                        undef $string;
                    }

                    next;
                }

                if ($ch eq "'" || $ch eq '"') {
                    $string = $ch;
                    next;
                }

                if (exists $pairs{$ch}) {
                    push @stack, $ch;
                    next;
                }

                if (exists $closing{$ch}) {
                    last unless @stack;
                    my $open = pop @stack;
                    last unless $pairs{$open} eq $ch;
                    next;
                }

                next if @stack;
                if (substr($body, $i) =~ /^catch\s+/) {
                    if ($i > 0) {
                        my $prev = substr($body, $i - 1, 1);
                        next unless $prev =~ /[\s\)\]\}\|,]/;
                    }
                    $catch_index = $i;
                    last;
                }
            }

            if (defined $catch_index) {
                $try_expr   = substr($body, 0, $catch_index);
                $catch_expr = substr($body, $catch_index + 5);
            }

            $try_expr   = JQ::Lite::Util::_strip_wrapping_parens($try_expr // '');
            $catch_expr = JQ::Lite::Util::_strip_wrapping_parens($catch_expr // '');
            $catch_expr =~ s/^\s+// if defined $catch_expr;

            @next_results = ();

            VALUE: for my $value (@results) {
                my $json   = JQ::Lite::Util::_encode_json($value);
                my @outputs;
                my $error;

                {
                    local $@;
                    eval { @outputs = $self->run_query($json, $try_expr); 1 } or $error = $@;
                }

                if (!$error) {
                    push @next_results, @outputs;
                    next VALUE;
                }

                my $message = $error;
                $message =~ s/\s+$// if defined $message;

                if (defined $catch_expr && length $catch_expr) {
                    my %existing = %{ $self->{_vars} || {} };
                    local $self->{_vars} = { %existing, error => $message };

                    my ($catch_values, $catch_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $value, $catch_expr);
                    if ($catch_ok) {
                        push @next_results, @$catch_values ? @$catch_values : (undef);
                    }
                    else {
                        my @catch_outputs;
                        my $catch_error;

                        {
                            local $@;
                            eval { @catch_outputs = $self->run_query($json, $catch_expr); 1 } or $catch_error = $@;
                        }

                        if ($catch_error) {
                            push @next_results, undef;
                        }
                        else {
                            push @next_results, @catch_outputs;
                        }
                    }

                    next VALUE;
                }

                push @next_results, undef;
            }

            @$out_ref = @next_results;
            return 1;
        }

        if (JQ::Lite::Util::_looks_like_expression($normalized)) {
            my @evaluated;
            my $all_ok = 1;

            for my $item (@results) {
                my ($values, $ok) = JQ::Lite::Util::_evaluate_value_expression($self, $item, $normalized);
                if ($ok) {
                    if (@$values) {
                        push @evaluated, $values->[0];
                    }
                    else {
                        push @evaluated, undef;
                    }
                }
                else {
                    $all_ok = 0;
                    last;
                }
            }

            if ($all_ok) {
                @$out_ref = @evaluated;
                return 1;
            }
        }

        # support for addition (. + expr)
        if ($normalized =~ /^\.\s*\+\s*(.+)$/s) {
            my $rhs_expr = $1;
            @next_results = map {
                my $lhs = $_;
                my ($rhs_values, $rhs_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $lhs, $rhs_expr);
                my $rhs = ($rhs_ok && @$rhs_values) ? $rhs_values->[0] : undef;
                JQ::Lite::Util::_apply_addition($lhs, $rhs);
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        my ($add_lhs, $add_rhs) = JQ::Lite::Util::_split_top_level_operator($normalized, '+');
        if (defined $add_lhs && defined $add_rhs) {
            @next_results = map {
                my ($values, $ok) = JQ::Lite::Util::_evaluate_value_expression($self, $_, $normalized);
                ($ok && @$values) ? $values->[0] : undef;
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for array constructors [expr, expr, ...]
        if ($normalized =~ /^\[(.*)\]$/s) {
            my $inner = $1;
            my @elements = ();
            if ($inner =~ /\S/) {
                @elements = JQ::Lite::Util::_split_top_level_commas($inner);
            }

            for my $item (@results) {
                my @built;

                for my $element (@elements) {
                    next if !defined $element;
                    $element =~ s/^\s+|\s+$//g;
                    next if $element eq '';

                    my ($values, $ok) = JQ::Lite::Util::_evaluate_value_expression($self, $item, $element);
                    if ($ok) {
                        if (@$values) {
                            push @built, @$values;
                        } else {
                            push @built, undef;
                        }
                        next;
                    }

                    my $json = JQ::Lite::Util::_encode_json($item);
                    my @outputs = $self->run_query($json, $element);
                    if (@outputs) {
                        push @built, @outputs;
                    } else {
                        push @built, undef;
                    }
                }

                push @next_results, \@built;
            }

            # handle empty [] constructor
            if (!@elements) {
                @next_results = map { [] } @results;
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for object constructors {key: expr, ...}
        if ($normalized =~ /^\{(.*)\}$/s) {
            my $inner = $1;
            my @pairs = ();
            if ($inner =~ /\S/) {
                @pairs = JQ::Lite::Util::_split_top_level_commas($inner);
            }

            for my $item (@results) {
                my %built;

                for my $pair (@pairs) {
                    next if !defined $pair;

                    my ($raw_key, $raw_expr) = JQ::Lite::Util::_split_top_level_colon($pair);
                    next if !defined $raw_key;

                    my $key = JQ::Lite::Util::_interpret_object_key($raw_key);
                    next if !defined $key;

                    my $value_expr = defined $raw_expr ? $raw_expr : '';
                    $value_expr =~ s/^\s+|\s+$//g;
                    next if $value_expr eq '';

                    my $value;

                    my ($values, $ok) = JQ::Lite::Util::_evaluate_value_expression($self, $item, $value_expr);
                    if ($ok) {
                        $value = @$values ? $values->[0] : undef;
                    }
                    else {
                        my $json = JQ::Lite::Util::_encode_json($item);
                        my @outputs = $self->run_query($json, $value_expr);
                        $value = @outputs ? $outputs[0] : undef;
                    }

                    $built{$key} = $value;
                }

                push @next_results, \%built;
            }

            if (!@pairs) {
                @next_results = map { {} } @results;
            }

            @$out_ref = @next_results;
            return 1;
        }

        if (my $foreach = JQ::Lite::Util::_parse_foreach_expression($normalized)) {
            @next_results = ();

            for my $value (@results) {
                my $json = JQ::Lite::Util::_encode_json($value);
                my @items = $self->run_query($json, $foreach->{generator});

                my ($init_values, $init_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $value, $foreach->{init_expr});
                my $acc;
                if ($init_ok) {
                    $acc = @$init_values ? $init_values->[0] : undef;
                }
                else {
                    my @init_outputs = $self->run_query(JQ::Lite::Util::_encode_json($value), $foreach->{init_expr});
                    $acc = @init_outputs ? $init_outputs[0] : undef;
                }

                for my $element (@items) {
                    my %existing = %{ $self->{_vars} || {} };
                    local $self->{_vars} = { %existing, $foreach->{var_name} => $element };

                    my ($updated_values, $updated_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $acc, $foreach->{update_expr});
                    my $next;
                    if ($updated_ok) {
                        $next = @$updated_values ? $updated_values->[0] : undef;
                    }
                    else {
                        my @outputs = $self->run_query(JQ::Lite::Util::_encode_json($acc), $foreach->{update_expr});
                        $next = @outputs ? $outputs[0] : undef;
                    }

                    $acc = $next;

                    if (defined $foreach->{extract_expr} && length $foreach->{extract_expr}) {
                        my ($extract_values, $extract_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $acc, $foreach->{extract_expr});
                        my $output;
                        if ($extract_ok) {
                            $output = @$extract_values ? $extract_values->[0] : undef;
                        }
                        else {
                            my @extracted = $self->run_query(JQ::Lite::Util::_encode_json($acc), $foreach->{extract_expr});
                            $output = @extracted ? $extracted[0] : undef;
                        }

                        push @next_results, $output;
                    }
                    else {
                        push @next_results, $acc;
                    }
                }
            }

            @$out_ref = @next_results;
            return 1;
        }

        if (my $if_expr = JQ::Lite::Util::_parse_if_expression($normalized)) {
            @next_results = ();

            for my $value (@results) {
                my $json     = JQ::Lite::Util::_encode_json($value);
                my $matched  = 0;

                BRANCH: for my $branch (@{ $if_expr->{branches} }) {
                    my @cond_results = $self->run_query($json, $branch->{condition});
                    my $truthy       = 0;

                    for my $cond_value (@cond_results) {
                        if (JQ::Lite::Util::_is_truthy($cond_value)) {
                            $truthy = 1;
                            last;
                        }
                    }

                    if (!$truthy && !@cond_results) {
                        $truthy = JQ::Lite::Util::_evaluate_condition($value, $branch->{condition}) ? 1 : 0;
                    }

                    next BRANCH unless $truthy;

                    my ($branch_values, $branch_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $value, $branch->{then});

                    if ($branch_ok) {
                        push @next_results, @$branch_values;
                    }
                    else {
                        my @outputs = $self->run_query($json, $branch->{then});
                        push @next_results, @outputs;
                    }

                    $matched = 1;
                    last BRANCH;
                }

                next if $matched;

                if (defined $if_expr->{else}) {
                    my ($else_values, $else_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $value, $if_expr->{else});

                    if ($else_ok) {
                        push @next_results, @$else_values;
                    }
                    else {
                        my @else_outputs = $self->run_query($json, $if_expr->{else});
                        push @next_results, @else_outputs;
                    }
                }
            }

            @$out_ref = @next_results;
            return 1;
        }

        if (my $reduce = JQ::Lite::Util::_parse_reduce_expression($normalized)) {
            @next_results = ();

            for my $value (@results) {
                my $json = JQ::Lite::Util::_encode_json($value);
                my @items = $self->run_query($json, $reduce->{generator});

                my ($init_values, $init_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $value, $reduce->{init_expr});
                my $acc;
                if ($init_ok) {
                    $acc = @$init_values ? $init_values->[0] : undef;
                }
                else {
                    my @init_outputs = $self->run_query(JQ::Lite::Util::_encode_json($value), $reduce->{init_expr});
                    $acc = @init_outputs ? $init_outputs[0] : undef;
                }

                for my $element (@items) {
                    my %existing = %{ $self->{_vars} || {} };
                    local $self->{_vars} = { %existing, $reduce->{var_name} => $element };

                    my ($updated_values, $updated_ok) = JQ::Lite::Util::_evaluate_value_expression($self, $acc, $reduce->{update_expr});
                    my $next;
                    if ($updated_ok) {
                        $next = @$updated_values ? $updated_values->[0] : undef;
                    }
                    else {
                        my @outputs = $self->run_query(JQ::Lite::Util::_encode_json($acc), $reduce->{update_expr});
                        $next = @outputs ? $outputs[0] : undef;
                    }

                    $acc = $next;
                }

                push @next_results, $acc;
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for .[] iteration
        if ($part eq '.[]') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? @$_
              : ref $_ eq 'HASH'  ? values %$_
              : JQ::Lite::Util::_is_string_scalar($_) ? split(//, "$_")
              : ()
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for select(...)
        if ($part =~ /^select\((.+)\)$/) {
            my $cond = $1;
            @next_results = ();

            my $has_wildcard_array = index($cond, '[]') != -1;
            my $has_comparison = ($cond =~ /(==|!=|>=|<=|>|<|\band\b|\bor\b|\bcontains\b|\bhas\b|\bmatch\b)/i);
            my $use_streaming_eval = $has_wildcard_array || !$has_comparison;

            # allow built-in filters like match() and test() to run so their errors surface
            $use_streaming_eval ||= ($cond =~ /^\s*(match|test)\s*\(/);

            VALUE: for my $value (@results) {
                my $simple = JQ::Lite::Util::_evaluate_condition($value, $cond) ? 1 : 0;

                if ($use_streaming_eval) {
                    my $json = JQ::Lite::Util::_encode_json($value);
                    my $error;
                    my @cond_results;

                    {
                        local $@;
                        @cond_results = eval { $self->run_query($json, $cond) };
                        $error = $@;
                    }

                    die $error if $error;

                    if (@cond_results) {
                        my $truthy = 0;

                        for my $cond_value (@cond_results) {
                            if (JQ::Lite::Util::_is_truthy($cond_value)) {
                                $truthy++;
                            }
                        }

                        if ($truthy) {
                            push @next_results, (($value) x $truthy);
                        }

                        next VALUE;
                    }
                }

                if ($simple) {
                    push @next_results, $value;
                }
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for length
        if ($part eq 'length') {
            @next_results = map {
                if (!defined $_) {
                    0;
                }
                elsif (ref $_ eq 'ARRAY') {
                    scalar(@$_);
                }
                elsif (ref $_ eq 'HASH') {
                    scalar(keys %$_);
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    length("$_");
                }
                else {
                    0;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for keys
        if ($part eq 'keys') {
            @next_results = map {
                if (ref $_ eq 'HASH') {
                    [ sort keys %$_ ];
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ 0 .. $#{$_} ];
                }
                else {
                    die 'keys(): argument must be an object or array';
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for keys_unsorted
        if ($part eq 'keys_unsorted' || $part eq 'keys_unsorted()') {
            @next_results = map {
                if (ref $_ eq 'HASH') {
                    [ keys %$_ ];
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ 0 .. $#{$_} ];
                }
                else {
                    undef;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for assignment (e.g., .spec.replicas = 3)
        if (JQ::Lite::Util::_looks_like_assignment($part)) {
            my ($path, $value_spec, $operator) = JQ::Lite::Util::_parse_assignment_expression($part);

            @next_results = map {
                JQ::Lite::Util::_apply_assignment($self, $_, $path, $value_spec, $operator)
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for sort
        if ($part eq 'sort') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ sort { JQ::Lite::Util::_smart_cmp()->($a, $b) } @$_ ] : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for sort_desc
        if ($part eq 'sort_desc') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $cmp = JQ::Lite::Util::_smart_cmp();
                    [ sort { $cmp->($b, $a) } @$_ ];
                }
                else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for unique
        if ($part eq 'unique') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ JQ::Lite::Util::_uniq(@$_) ] : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for unique_by(path)
        if ($part =~ /^unique_by\((.+?)\)$/) {
            my $raw_path = $1;
            $raw_path =~ s/^\s+|\s+$//g;

            my $key_path = $raw_path;
            $key_path =~ s/^['"](.*)['"]$/$1/;

            my $use_entire_item = ($key_path eq '' || $key_path eq '.');
            $key_path =~ s/^\.// unless $use_entire_item;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my %seen;
                    my @deduped;

                    for my $element (@$_) {
                        my $key_value;

                        if ($use_entire_item) {
                            $key_value = $element;
                        } else {
                            my @values = JQ::Lite::Util::_traverse($element, $key_path);
                            $key_value = @values ? $values[0] : undef;
                        }

                        my $signature;
                        if (defined $key_value) {
                            $signature = JQ::Lite::Util::_key($key_value);
                        } else {
                            $signature = "\0__JQ_LITE_UNDEF__";
                        }

                        next if $seen{$signature}++;
                        push @deduped, $element;
                    }

                    \@deduped;
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for first
        if ($part eq 'first') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[0] : undef
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for last
        if ($part eq 'last') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[-1] : undef
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for rest
        if ($part eq 'rest') {
            @next_results = map {
                ref $_ eq 'ARRAY'
                ? (@$_ ? [ @$_[ 1 .. $#{$_} ] ] : [])
                : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for reverse
        if ($part eq 'reverse') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ reverse @$_ ]
                : JQ::Lite::Util::_is_string_scalar($_) ? scalar reverse $_
                : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for limit(n)
        if ($part =~ /^limit\((.+)\)$/) {
            my $limit_str = $1;
            $limit_str =~ s/^\s+|\s+$//g;

            if ($limit_str !~ /^\d+$/) {
                die "limit(): count must be a non-negative integer";
            }

            my $limit = $limit_str + 0;

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
            @$out_ref = @next_results;
            return 1;
        }

        # support for drop(n)
        if ($part =~ /^drop\((.+)\)$/) {
            my $count_str = $1;
            $count_str =~ s/^\s+|\s+$//g;

            if ($count_str !~ /^\d+$/) {
                die "drop(): count must be a non-negative integer";
            }

            my $count = $count_str + 0;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    if ($count >= @$arr) {
                        [];
                    } else {
                        [ @$arr[$count .. $#$arr] ];
                    }
                } else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for tail(n)
        if ($part =~ /^tail\((.+)\)$/) {
            my $count_str = $1;
            $count_str =~ s/^\s+|\s+$//g;

            if ($count_str !~ /^\d+$/) {
                die "tail(): count must be a non-negative integer";
            }

            my $count = $count_str + 0;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;

                    if ($count == 0 || !@$arr) {
                        [];
                    } else {
                        my $start = @$arr - $count;
                        $start = 0 if $start < 0;

                        [ @$arr[$start .. $#$arr] ];
                    }
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for chunks(n)
        if ($part =~ /^chunks\((.+)\)$/) {
            my $size_str = $1;
            $size_str =~ s/^\s+|\s+$//g;

            if ($size_str !~ /^\d+$/) {
                die "chunks(): size must be a non-negative integer";
            }

            my $size = $size_str + 0;
            $size = 1 if $size < 1;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    if (!@$arr) {
                        [];
                    } else {
                        my @chunks;
                        for (my $i = 0; $i < @$arr; $i += $size) {
                            my $end = $i + $size - 1;
                            $end = $#$arr if $end > $#$arr;
                            push @chunks, [ @$arr[$i .. $end] ];
                        }
                        \@chunks;
                    }
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for range(...)
        if ($part =~ /^range\((.*)\)$/) {
            my $args_raw = $1;
            my @args     = JQ::Lite::Util::_parse_range_arguments($args_raw);

            @next_results = ();
            for my $value (@results) {
                push @next_results, JQ::Lite::Util::_apply_range($value, \@args);
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for map(...)
        if ($part =~ /^map\((.+)\)$/) {
            my $filter = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @mapped;

                    for my $element (@$_) {
                        my @outputs = $self->run_query(JQ::Lite::Util::_encode_json($element), $filter);
                        push @mapped, @outputs if @outputs;
                    }

                    \@mapped;
                } else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for map_values(filter)
        if ($part =~ /^map_values\((.+)\)$/) {
            my $filter = $1;
            @next_results = map { JQ::Lite::Util::_apply_map_values($self, $_, $filter) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for walk(filter)
        if ($part =~ /^walk\((.+)\)$/) {
            my $filter = $1;
            @next_results = map { JQ::Lite::Util::_apply_walk($self, $_, $filter) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for recurse([filter])
        if ($part =~ /^recurse(?:\((.*)\))?$/) {
            my $filter = defined $1 ? $1 : '';
            $filter =~ s/^\s+|\s+$//g;
            $filter = undef if $filter eq '';

            @next_results = map { JQ::Lite::Util::_apply_recurse($self, $_, $filter) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for enumerate()
        if ($part =~ /^enumerate(?:\(\))?$/) {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    my @pairs;
                    for my $idx (0 .. $#$arr) {
                        push @pairs, { index => $idx, value => $arr->[$idx] };
                    }
                    \@pairs;
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for to_entries
        if ($part eq 'to_entries') {
            @next_results = map { JQ::Lite::Util::_to_entries($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for from_entries
        if ($part eq 'from_entries') {
            @next_results = map { JQ::Lite::Util::_from_entries($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for with_entries(filter)
        if ($part =~ /^with_entries\((.+)\)$/) {
            my $filter = $1;
            @next_results = map { JQ::Lite::Util::_apply_with_entries($self, $_, $filter) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for transpose()
        if ($part eq 'transpose()' || $part eq 'transpose') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $outer = $_;

                    if (!@$outer) {
                        [];
                    }
                    elsif (grep { ref $_ ne 'ARRAY' } @$outer) {
                        $_;
                    }
                    else {
                        my @lengths = map { scalar(@$_) } @$outer;
                        my $limit   = @lengths ? min(@lengths) : 0;

                        if ($limit <= 0) {
                            [];
                        } else {
                            my @transposed;
                            for my $idx (0 .. $limit - 1) {
                                push @transposed, [ map { $_->[$idx] } @$outer ];
                            }
                            \@transposed;
                        }
                    }
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for slice(start[, length])
        if ($part =~ /^slice(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args     = JQ::Lite::Util::_parse_arguments($args_raw);

            @next_results = map { JQ::Lite::Util::_apply_slice($_, @args) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for pluck(key)
        if ($part =~ /^pluck\((.+)\)$/) {
            my $key_path = $1;
            $key_path =~ s/^['"](.*)['"]$/$1/;
            $key_path =~ s/^\.//;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @collected = map {
                        my $item = $_;
                        my @values = JQ::Lite::Util::_traverse($item, $key_path);
                        @values ? $values[0] : undef;
                    } @$_;
                    \@collected;
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for pick(key1, key2, ...)
        if ($part =~ /^pick\((.*)\)$/) {
            my @keys = map { defined $_ ? "$_" : undef } JQ::Lite::Util::_parse_arguments($1);
            @keys = grep { defined $_ } @keys;

            @next_results = map { JQ::Lite::Util::_apply_pick($_, \@keys) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for merge_objects()
        if ($part eq 'merge_objects()' || $part eq 'merge_objects') {
            @next_results = map { JQ::Lite::Util::_apply_merge_objects($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for add
        if ($part eq 'add') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? sum(map { 0 + $_ } @$_) : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for sum (alias for add)
        if ($part eq 'sum') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? sum(map { 0 + $_ } @$_) : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for sum_by(path)
        if ($part =~ /^sum_by\((.+)\)$/) {
            my $raw_path = $1;
            $raw_path =~ s/^\s+|\s+$//g;
            $raw_path =~ s/^['"](.*)['"]$/$1/;

            my $use_entire_item = ($raw_path eq '' || $raw_path eq '.');
            my $key_path        = $raw_path;
            $key_path =~ s/^\.// unless $use_entire_item;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $sum        = 0;
                    my $has_number = 0;

                    for my $element (@$_) {
                        my @values = $use_entire_item
                            ? ($element)
                            : JQ::Lite::Util::_traverse($element, $key_path);

                        for my $value (@values) {
                            next unless defined $value;

                            my $num = $value;
                            if (ref($num) eq 'JSON::PP::Boolean') {
                                $num = $num ? 1 : 0;
                            }

                            next if ref $num;
                            next unless looks_like_number($num);
                            $sum += $num;
                            $has_number = 1;
                        }
                    }

                    $has_number ? $sum : 0;
                }
                else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for median_by(path)
        if ($part =~ /^median_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = JQ::Lite::Util::_normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @numbers;
                    for my $element (@$_) {
                        push @numbers, JQ::Lite::Util::_project_numeric_values($element, $key_path, $use_entire_item);
                    }

                    if (@numbers) {
                        @numbers = sort { $a <=> $b } @numbers;
                        my $count  = @numbers;
                        my $middle = int($count / 2);
                        if ($count % 2) {
                            $numbers[$middle];
                        } else {
                            ($numbers[$middle - 1] + $numbers[$middle]) / 2;
                        }
                    } else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for avg_by(path)
        if ($part =~ /^avg_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = JQ::Lite::Util::_normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $sum   = 0;
                    my $count = 0;

                    for my $element (@$_) {
                        my @values = $use_entire_item
                            ? ($element)
                            : JQ::Lite::Util::_traverse($element, $key_path);

                        for my $value (@values) {
                            next unless defined $value;

                            my $num = $value;
                            if (ref($num) eq 'JSON::PP::Boolean') {
                                $num = $num ? 1 : 0;
                            }

                            next if ref $num;
                            next unless looks_like_number($num);
                            $sum   += $num;
                            $count += 1;
                        }
                    }

                    $count ? $sum / $count : 0;
                }
                else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for max_by(path)
        if ($part =~ /^max_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = JQ::Lite::Util::_normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    JQ::Lite::Util::_extreme_by($_, $key_path, $use_entire_item, 'max');
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for min_by(path)
        if ($part =~ /^min_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = JQ::Lite::Util::_normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    JQ::Lite::Util::_extreme_by($_, $key_path, $use_entire_item, 'min');
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for product
        if ($part eq 'product') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $product    = 1;
                    my $has_values = 0;
                    for my $val (@$_) {
                        next unless defined $val;
                        $product *= (0 + $val);
                        $has_values = 1;
                    }
                    $has_values ? $product : 1;
                } else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for min
        if ($part eq 'min') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? min(map { 0 + $_ } @$_) : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for max
        if ($part eq 'max') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? max(map { 0 + $_ } @$_) : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for avg
        if ($part eq 'avg') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? sum(map { 0 + $_ } @$_) / scalar(@$_) : 0
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for abs
        if ($part eq 'abs') {
            @next_results = map {
                if (!defined $_) {
                    undef;
                }
                elsif (!ref $_) {
                    looks_like_number($_) ? abs($_) : $_;
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ map { looks_like_number($_) ? abs($_) : $_ } @$_ ];
                }
                else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for ceil()
        if ($part eq 'ceil()' || $part eq 'ceil') {
            @next_results = map { JQ::Lite::Util::_apply_numeric_function($_, \&JQ::Lite::Util::_ceil) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for floor()
        if ($part eq 'floor()' || $part eq 'floor') {
            @next_results = map { JQ::Lite::Util::_apply_numeric_function($_, \&JQ::Lite::Util::_floor) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for round()
        if ($part eq 'round()' || $part eq 'round') {
            @next_results = map { JQ::Lite::Util::_apply_numeric_function($_, \&JQ::Lite::Util::_round) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for clamp(min, max)
        if ($part =~ /^clamp\((.*)\)$/) {
            my @args = JQ::Lite::Util::_parse_arguments($1);
            my $min  = @args ? JQ::Lite::Util::_normalize_numeric_bound($args[0]) : undef;
            my $max  = @args > 1 ? JQ::Lite::Util::_normalize_numeric_bound($args[1]) : undef;

            if (defined $min && defined $max && $min > $max) {
                ($min, $max) = ($max, $min);
            }

            @next_results = map { JQ::Lite::Util::_apply_clamp($_, $min, $max) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for tostring()
        if ($part eq 'tostring()' || $part eq 'tostring') {
            @next_results = map { JQ::Lite::Util::_apply_tostring($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for tojson()
        if ($part eq 'tojson()' || $part eq 'tojson') {
            @next_results = map { JQ::Lite::Util::_apply_tojson($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for fromjson()
        if ($part eq 'fromjson()' || $part eq 'fromjson') {
            @next_results = map { JQ::Lite::Util::_apply_fromjson($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for to_number()
        if ($part eq 'to_number()' || $part eq 'to_number') {
            @next_results = map { JQ::Lite::Util::_apply_to_number($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        if ($part eq 'tonumber()' || $part eq 'tonumber') {
            @next_results = map { JQ::Lite::Util::_tonumber($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for median
        if ($part eq 'median') {
            @next_results = map {
                if (ref $_ eq 'ARRAY' && @$_) {
                    my @numbers = sort { $a <=> $b }
                        map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        my $count  = @numbers;
                        my $middle = int($count / 2);
                        if ($count % 2) {
                            $numbers[$middle];
                        } else {
                            ($numbers[$middle - 1] + $numbers[$middle]) / 2;
                        }
                    } else {
                        undef;
                    }
                } else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for percentile(p)
        if ($part =~ /^percentile(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args     = length $args_raw ? JQ::Lite::Util::_parse_arguments($args_raw) : ();
            my $fraction = @args ? JQ::Lite::Util::_normalize_percentile($args[0]) : 0.5;

            @next_results = map {
                if (ref $_ eq 'ARRAY' && @$_) {
                    my @numbers = sort { $a <=> $b }
                        map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        defined $fraction ? JQ::Lite::Util::_percentile_value(\@numbers, $fraction) : undef;
                    }
                    else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for mode
        if ($part eq 'mode') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    if (!@$_) {
                        undef;
                    } else {
                        my %counts;
                        my %values;
                        my %first_index;
                        my $max_count  = 0;
                        my $best_index = undef;
                        my $mode_key;

                        for (my $i = 0; $i < @{$_}; $i++) {
                            my $item = $_->[$i];
                            next unless defined $item;

                            my $key = JQ::Lite::Util::_key($item);
                            next unless defined $key;

                            $counts{$key}++;
                            $values{$key}      //= $item;
                            $first_index{$key} //= $i;

                            my $count = $counts{$key};
                            my $index = $first_index{$key};

                            if (!defined $mode_key
                                || $count > $max_count
                                || ($count == $max_count
                                    && (!defined $best_index || $index < $best_index))) {
                                $mode_key   = $key;
                                $max_count  = $count;
                                $best_index = $index;
                            }
                        }

                        defined $mode_key ? $values{$mode_key} : undef;
                    }
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for variance
        if ($part eq 'variance') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @numbers = map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        my $mean = sum(@numbers) / @numbers;
                        sum(map { ($_ - $mean) ** 2 } @numbers) / @numbers;
                    }
                    else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for stddev
        if ($part eq 'stddev') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @numbers = map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        my $mean = sum(@numbers) / @numbers;
                        my $variance = sum(map { ($_ - $mean) ** 2 } @numbers) / @numbers;
                        sqrt($variance);
                    }
                    else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for group_count(key)
        if ($part =~ /^group_count\((.+)\)$/) {
            my $key_path = $1;
            @next_results = map {
                JQ::Lite::Util::_group_count($_, $key_path)
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for group_by(key)
        if ($part =~ /^group_by\((.+)\)$/) {
            my $key_path = $1;
            @next_results = map {
                JQ::Lite::Util::_group_by($_, $key_path)
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for count
        if ($part eq 'count') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    scalar(@$_);
                }
                elsif (!defined $_) {
                    0;
                }
                else {
                    1;    # count as 1 item for scalars and objects
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for all() / all(expr)
        if ($part =~ /^all(?:\((.*)\))?$/) {
            my $expr = defined $1 ? $1 : undef;
            $expr = undef if defined($expr) && $expr eq '';

            @next_results = map { JQ::Lite::Util::_apply_all($self, $_, $expr) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for any() / any(expr)
        if ($part =~ /^any(?:\((.*)\))?$/) {
            my $expr = defined $1 ? $1 : undef;
            $expr = undef if defined($expr) && $expr eq '';

            @next_results = map { JQ::Lite::Util::_apply_any($self, $_, $expr) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for join(", ")
        if ($part =~ /^join\((.*?)\)$/) {
            my $sep = JQ::Lite::Util::_parse_string_argument($1);

            @next_results = map {
                die 'join(): input must be an array' if ref($_) ne 'ARRAY';
                my @parts;
                for my $item (@$_) {
                    if (!defined $item) {
                        push @parts, '';
                        next;
                    }

                    if (ref($item) eq 'JSON::PP::Boolean') {
                        push @parts, $item ? 'true' : 'false';
                        next;
                    }

                    if (ref $item) {
                        die 'join(): array elements must be scalars';
                    }

                    push @parts, "$item";
                }

                join($sep, @parts)
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for sort_by(key)
        if ($part =~ /^sort_by\((.+?)\)$/) {
            my $key_path = $1;
            $key_path =~ s/^\.//;  # Remove leading dot
        
            my $cmp = JQ::Lite::Util::_smart_cmp();
            @next_results = ();
        
            for my $item (@results) {
                if (ref $item eq 'ARRAY') {
                    my @sorted = sort {
                        my $a_val = (JQ::Lite::Util::_traverse($a, $key_path))[0] // '';
                        my $b_val = (JQ::Lite::Util::_traverse($b, $key_path))[0] // '';

                        $cmp->($a_val, $b_val);
                    } @$item;
        
                    push @next_results, \@sorted;
                } else {
                    push @next_results, $item;
                }
            }
        
            @$out_ref = @next_results;
            return 1;
        }

        # support for empty
        if ($part eq 'empty') {
            @results = ();  # discard all results
            return 1;
        }

        # support for values
        if ($part eq 'values') {
            @next_results = map {
                ref $_ eq 'HASH' ? [ values %$_ ] : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for arrays
        if ($part eq 'arrays()' || $part eq 'arrays') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? $_ : ()
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for scalars
        if ($part eq 'scalars()' || $part eq 'scalars') {
            @next_results = map {
                if (!defined $_) {
                    undef;
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    $_;
                }
                else {
                    ();
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for objects
        if ($part eq 'objects()' || $part eq 'objects') {
            @next_results = map {
                ref $_ eq 'HASH' ? $_ : ()
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for flatten()
        if ($part eq 'flatten()' || $part eq 'flatten') {
            @next_results = map {
                ref $_ eq 'ARRAY'
                    ? JQ::Lite::Util::_flatten_depth($_, 1)
                    : $_
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for flatten_all()
        if ($part eq 'flatten_all()' || $part eq 'flatten_all') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    JQ::Lite::Util::_flatten_all($_);
                } else {
                    $_;
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for flatten_depth(n)
        if ($part =~ /^flatten_depth(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args     = length $args_raw ? JQ::Lite::Util::_parse_arguments($args_raw) : ();
            my $depth    = @args ? $args[0] : 1;

            if (!defined $depth || !looks_like_number($depth)) {
                $depth = 1;
            }

            $depth = int($depth);
            $depth = 0 if $depth < 0;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    JQ::Lite::Util::_flatten_depth($_, $depth);
                } else {
                    $_;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
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
                    my $sv    = B::svref_2object(\$_);
                    my $flags = $sv->FLAGS;

                    ($flags & (SVp_IOK | SVp_NOK)) ? 'number' : 'string';
                }
                elsif (ref($_) eq 'JSON::PP::Boolean') {
                    'boolean';
                }
                else {
                    'unknown';
                }
            } (@results ? @results : (undef)); 
            @$out_ref = @next_results;
            return 1;
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
            @$out_ref = @next_results;
            return 1;
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
            @$out_ref = @next_results;
            return 1;
        }

        # support for delpaths(paths_expr)
        if ($part =~ /^delpaths\((.*)\)$/) {
            my $filter = $1;
            $filter =~ s/^\s+|\s+$//g;

            @next_results = map { JQ::Lite::Util::_apply_delpaths($self, $_, $filter) } @results;
            @$out_ref = @next_results;
            return 1;
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
            @$out_ref = @next_results;
            return 1;
        }

        # support for titlecase()
        if ($part eq 'titlecase()' || $part eq 'titlecase') {
            @next_results = map { JQ::Lite::Util::_apply_case_transform($_, 'titlecase') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for upper()
        if ($part eq 'upper()' || $part eq 'upper') {
            @next_results = map { JQ::Lite::Util::_apply_case_transform($_, 'upper') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for ascii_upcase
        if ($part eq 'ascii_upcase()' || $part eq 'ascii_upcase') {
            @next_results = map { JQ::Lite::Util::_apply_ascii_case_transform($_, 'upper') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for ascii_downcase
        if ($part eq 'ascii_downcase()' || $part eq 'ascii_downcase') {
            @next_results = map { JQ::Lite::Util::_apply_ascii_case_transform($_, 'lower') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for lower()
        if ($part eq 'lower()' || $part eq 'lower') {
            @next_results = map { JQ::Lite::Util::_apply_case_transform($_, 'lower') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for trim()
        if ($part eq 'trim()' || $part eq 'trim') {
            @next_results = map { JQ::Lite::Util::_apply_trim($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for ltrimstr("prefix")
        if ($part =~ /^ltrimstr\((.+)\)$/) {
            my $needle = JQ::Lite::Util::_parse_string_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_trimstr($_, $needle, 'left') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for rtrimstr("suffix")
        if ($part =~ /^rtrimstr\((.+)\)$/) {
            my $needle = JQ::Lite::Util::_parse_string_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_trimstr($_, $needle, 'right') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for has(key)
        if ($part =~ /^has\((.+)\)$/) {
            my @args   = JQ::Lite::Util::_parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map { JQ::Lite::Util::_apply_has($_, $needle) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for contains(value)
        if ($part =~ /^contains\((.+)\)$/) {
            my $needle = JQ::Lite::Util::_parse_literal_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_contains($_, $needle) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for contains_subset(value)
        if ($part =~ /^contains_subset\((.+)\)$/) {
            my $needle = JQ::Lite::Util::_parse_literal_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_contains_subset($_, $needle) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for inside(container)
        if ($part =~ /^inside\((.+)\)$/) {
            my $container = JQ::Lite::Util::_parse_literal_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_inside($_, $container) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for test("pattern"[, "flags"])
        if ($part =~ /^test\((.+)\)$/) {
            my ($pattern_expr, $flags_expr) = JQ::Lite::Util::_split_semicolon_arguments($1, 2);
            my $pattern = defined $pattern_expr ? JQ::Lite::Util::_parse_string_argument($pattern_expr) : '';
            my $flags   = defined $flags_expr   ? JQ::Lite::Util::_parse_string_argument($flags_expr)   : '';

            @next_results = map { JQ::Lite::Util::_apply_test($_, $pattern, $flags) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for match("pattern"[, "flags"])
        if ($part =~ /^match\((.+)\)$/) {
            my ($pattern_expr, $flags_expr) = JQ::Lite::Util::_split_semicolon_arguments($1, 2);
            my $pattern = defined $pattern_expr ? JQ::Lite::Util::_parse_string_argument($pattern_expr) : '';
            my $flags   = defined $flags_expr   ? JQ::Lite::Util::_parse_string_argument($flags_expr)   : '';

            @next_results = map { JQ::Lite::Util::_apply_match($_, $pattern, $flags) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for startswith("prefix")
        if ($part =~ /^startswith\((.+)\)$/) {
            my $needle = JQ::Lite::Util::_parse_string_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_string_predicate($_, $needle, 'start') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for endswith("suffix")
        if ($part =~ /^endswith\((.+)\)$/) {
            my $needle = JQ::Lite::Util::_parse_string_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_string_predicate($_, $needle, 'end') } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for explode()
        if ($part eq 'explode()' || $part eq 'explode') {
            @next_results = map { JQ::Lite::Util::_apply_explode($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for implode()
        if ($part eq 'implode()' || $part eq 'implode') {
            @next_results = map { JQ::Lite::Util::_apply_implode($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for replace(old, new)
        if ($part =~ /^replace\((.+)\)$/) {
            my ($search, $replacement) = JQ::Lite::Util::_parse_arguments($1);
            $search      = defined $search      ? $search      : '';
            $replacement = defined $replacement ? $replacement : '';

            @next_results = map { JQ::Lite::Util::_apply_replace($_, $search, $replacement) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for @json (format value as JSON string)
        if ($part eq '@json' || $part eq '@json()') {
            @next_results = map { JQ::Lite::Util::_apply_tojson($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for @csv (format array/scalar as CSV row)
        if ($part eq '@csv' || $part eq '@csv()') {
            @next_results = map { JQ::Lite::Util::_apply_csv($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for @tsv (format array/scalar as TSV row)
        if ($part eq '@tsv' || $part eq '@tsv()') {
            @next_results = map { JQ::Lite::Util::_apply_tsv($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for @base64 (format value as base64 string)
        if ($part eq '@base64' || $part eq '@base64()') {
            @next_results = map { JQ::Lite::Util::_apply_base64($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for @base64d (decode base64-encoded string)
        if ($part eq '@base64d' || $part eq '@base64d()') {
            @next_results = map { JQ::Lite::Util::_apply_base64d($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for @uri (percent-encode value)
        if ($part eq '@uri' || $part eq '@uri()') {
            @next_results = map { JQ::Lite::Util::_apply_uri($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for split("separator")
        if ($part =~ /^split\((.+)\)$/) {
            my $separator = JQ::Lite::Util::_parse_string_argument($1);
            @next_results = map { JQ::Lite::Util::_apply_split($_, $separator) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for substr(start[, length])
        if ($part =~ /^substr(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args = JQ::Lite::Util::_parse_arguments($args_raw);
            @next_results = map { JQ::Lite::Util::_apply_substr($_, @args) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for indices(value)
        if ($part =~ /^indices\((.*)\)$/) {
            my @args   = JQ::Lite::Util::_parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map { JQ::Lite::Util::_apply_indices($_, $needle) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for index(value)
        if ($part =~ /^index\((.*)\)$/) {
            my @args   = JQ::Lite::Util::_parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $array = $_;
                    my $found;
                    for my $i (0 .. $#$array) {
                        if (JQ::Lite::Util::_values_equal($array->[$i], $needle)) {
                            $found = $i;
                            last;
                        }
                    }
                    defined $found ? $found : undef;
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    if (!defined $_ || !defined $needle) {
                        undef;
                    }
                    else {
                        my $haystack = "$_";
                        my $fragment = "$needle";
                        my $pos      = index($haystack, $fragment);
                        $pos >= 0 ? $pos : undef;
                    }
                }
                else {
                    undef;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for rindex(value)
        if ($part =~ /^rindex\((.*)\)$/) {
            my @args   = JQ::Lite::Util::_parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $array = $_;
                    my $found;
                    for (my $i = $#$array; $i >= 0; $i--) {
                        if (JQ::Lite::Util::_values_equal($array->[$i], $needle)) {
                            $found = $i;
                            last;
                        }
                    }
                    defined $found ? $found : undef;
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    if (!defined $_ || !defined $needle) {
                        undef;
                    }
                    else {
                        my $haystack = "$_";
                        my $fragment = "$needle";
                        my $pos      = rindex($haystack, $fragment);
                        $pos >= 0 ? $pos : undef;
                    }
                }
                else {
                    undef;
                }
            } @results;

            @$out_ref = @next_results;
            return 1;
        }

        # support for paths()
        if ($part eq 'paths()' || $part eq 'paths') {
            @next_results = ();

            for my $value (@results) {
                my $paths = JQ::Lite::Util::_apply_paths($value);
                push @next_results, @$paths;
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for paths(scalars)
        if ($part =~ /^paths\(\s*scalars\s*\)$/) {
            @next_results = ();

            for my $value (@results) {
                my $paths = JQ::Lite::Util::_apply_scalar_paths($value);
                push @next_results, @$paths;
            }

            @$out_ref = @next_results;
            return 1;
        }

        # support for leaf_paths()
        if ($part eq 'leaf_paths()' || $part eq 'leaf_paths') {
            @next_results = map { JQ::Lite::Util::_apply_leaf_paths($_) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for getpath(path_expr)
        if ($part =~ /^getpath\((.*)\)$/) {
            my $path_expr = defined $1 ? $1 : '';

            @next_results = map { JQ::Lite::Util::_apply_getpath($self, $_, $path_expr) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for setpath(path_expr; value_expr)
        if ($part =~ /^setpath\((.*)\)$/) {
            my $args_raw = defined $1 ? $1 : '';
            my ($paths_expr, $value_expr) = JQ::Lite::Util::_split_semicolon_arguments($args_raw, 2);

            @next_results = map { JQ::Lite::Util::_apply_setpath($self, $_, $paths_expr, $value_expr) } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for path()
        if ($part eq 'path') {
            @next_results = map {
                if (ref $_ eq 'HASH') {
                    [ sort keys %$_ ]
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ 0..$#$_ ]
                }
                else {
                    ''
                }
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for is_empty
        if ($part eq 'is_empty') {
            @next_results = map {
                (ref $_ eq 'ARRAY' && !@$_) || (ref $_ eq 'HASH' && !%$_)
                    ? JSON::PP::true
                    : JSON::PP::false
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for not (logical negation)
        if ($part eq 'not' || $part eq 'not()') {
            @next_results = map {
                JQ::Lite::Util::_is_truthy($_) ? JSON::PP::false : JSON::PP::true
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # support for jq's alternative operator: lhs // rhs
        my $coalesce_expr = $part;
        if (defined $coalesce_expr) {
            my $stripped = $coalesce_expr;
            while ($stripped =~ /^\((.*)\)$/) {
                $stripped = $1;
                $stripped =~ s/^\s+|\s+$//g;
            }

            if ($stripped =~ /^(.*?)\s*\/\/\s*(.+)$/) {
                my ($lhs_raw, $rhs_raw) = ($1, $2);
                my $lhs_expr = $lhs_raw;
                my $rhs_expr = $rhs_raw;
                $lhs_expr =~ s/^\s+|\s+$//g;
                $rhs_expr =~ s/^\s+|\s+$//g;

                @next_results = map { JQ::Lite::Util::_apply_coalesce($self, $_, $lhs_expr, $rhs_expr) } @results;
                @$out_ref = @next_results;
                return 1;
            }
        }

        # support for default(value)
        if ($part =~ /^default\((.+)\)$/) {
            my $default_value = $1;
            $default_value =~ s/^['"](.*?)['"]$/$1/;

            @results = @results ? @results : (undef);

            @next_results = map {
                defined($_) ? $_ : $default_value
            } @results;
            @$out_ref = @next_results;
            return 1;
        }

        # Fallback: value expressions (including literals like null/0/"text")
        {
            my $all_ok = 1;
            @next_results = ();

            for my $item (@results) {
                my ($values, $ok) = JQ::Lite::Util::_evaluate_value_expression($self, $item, $part);
                if ($ok) {
                    if (@$values) {
                        push @next_results, @$values;
                    }
                    else {
                        push @next_results, undef;
                    }
                }
                else {
                    $all_ok = 0;
                    last;
                }
            }

            if ($all_ok) {
                @$out_ref = @next_results;
                return 1;
            }
        }

    return 0;
}

1;
