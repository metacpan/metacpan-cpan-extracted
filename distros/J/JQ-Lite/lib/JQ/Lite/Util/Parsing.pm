package JQ::Lite::Util;

use strict;
use warnings;

use JSON::PP ();
use Scalar::Util qw(looks_like_number);
use Encode qw(encode is_utf8);
use JQ::Lite::Expression ();

our $JSON_DECODER     = JSON::PP->new->utf8->allow_nonref;
our $FROMJSON_DECODER = JSON::PP->new->utf8->allow_nonref;
our $TOJSON_ENCODER   = JSON::PP->new->utf8->allow_nonref;

sub _encode_json {
    my ($value) = @_;
    return $TOJSON_ENCODER->encode($value);
}

sub _decode_json {
    my ($text) = @_;

    if (defined $text && is_utf8($text, 1)) {
        $text = encode('UTF-8', $text);
    }

    return $JSON_DECODER->decode($text);
}

sub _are_brackets_balanced {
    my ($text) = @_;

    return 1 unless defined $text && length $text;

    my %pairs = (
        '(' => ')',
        '[' => ']',
        '{' => '}',
    );
    my %closing = reverse %pairs;

    my @stack;
    my $string;
    my $escape = 0;

    for my $char (split //, $text) {
        if (defined $string) {
            if ($escape) {
                $escape = 0;
                next;
            }

            if ($char eq '\\') {
                $escape = 1;
                next;
            }

            if ($char eq $string) {
                undef $string;
            }

            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            next;
        }

        if (exists $pairs{$char}) {
            push @stack, $char;
            next;
        }

        if (exists $closing{$char}) {
            return 0 unless @stack;
            my $open = pop @stack;
            return 0 unless $pairs{$open} eq $char;
            next;
        }
    }

    return !@stack && !defined $string;
}

sub _strip_wrapping_parens {
    my ($text) = @_;

    return '' unless defined $text;

    my $copy = $text;
    $copy =~ s/^\s+|\s+$//g;

    while ($copy =~ /^\((.*)\)$/s) {
        my $inner = $1;
        last unless _are_brackets_balanced($inner);
        $inner =~ s/^\s+|\s+$//g;
        $copy = $inner;
    }

    return $copy;
}

sub _split_top_level_semicolons {
    my ($text) = @_;

    return unless defined $text;

    my %pairs = (
        '(' => ')',
        '[' => ']',
        '{' => '}',
    );
    my %closing = reverse %pairs;

    my @stack;
    my $string;
    my $escape = 0;
    my @parts;
    my $start = 0;

    for (my $i = 0; $i < length $text; $i++) {
        my $char = substr($text, $i, 1);

        if (defined $string) {
            if ($escape) {
                $escape = 0;
                next;
            }

            if ($char eq '\\') {
                $escape = 1;
                next;
            }

            if ($char eq $string) {
                undef $string;
            }

            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            next;
        }

        if (exists $pairs{$char}) {
            push @stack, $char;
            next;
        }

        if (exists $closing{$char}) {
            return unless @stack;
            my $open = pop @stack;
            return unless $pairs{$open} eq $char;
            next;
        }

        next unless $char eq ';';

        if (!@stack) {
            my $chunk = substr($text, $start, $i - $start);
            push @parts, $chunk;
            $start = $i + 1;
        }
    }

    push @parts, substr($text, $start) if $start <= length $text;

    return @parts;
}

sub _split_top_level_pipes {
    my ($text) = @_;

    return unless defined $text;

    my %pairs = (
        '(' => ')',
        '[' => ']',
        '{' => '}',
    );
    my %closing = reverse %pairs;

    my @stack;
    my $string;
    my $escape = 0;
    my @parts;
    my $start = 0;

    my $length = length $text;
    my $in_try = 0;
    for (my $i = 0; $i < $length; $i++) {
        my $char = substr($text, $i, 1);

        if (defined $string) {
            if ($escape) {
                $escape = 0;
                next;
            }

            if ($char eq '\\') {
                $escape = 1;
                next;
            }

            if ($char eq $string) {
                undef $string;
            }

            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            next;
        }

        if (exists $pairs{$char}) {
            push @stack, $char;
            next;
        }

        if (!$in_try && !@stack && !defined $string) {
            if (substr($text, $i) =~ /^try\b/) {
                $in_try = 1;
                next;
            }
        }

        if ($in_try && !@stack && !defined $string) {
            if (substr($text, $i) =~ /^catch\b/) {
                $in_try = 0;
                next;
            }
        }

        if (exists $closing{$char}) {
            return unless @stack;
            my $open = pop @stack;
            return unless $pairs{$open} eq $char;
            next;
        }

        next unless $char eq '|';
        next if $in_try;
        if (substr($text, $i, 2) eq '||') {
            $i++;
            next;
        }

        if (!@stack) {
            my $chunk = substr($text, $start, $i - $start);
            push @parts, $chunk;
            $start = $i + 1;
        }
    }

    push @parts, substr($text, $start) if $start <= $length;

    return @parts;
}

sub _split_top_level_commas {
    my ($text) = @_;

    return unless defined $text;

    my %pairs = (
        '(' => ')',
        '[' => ']',
        '{' => '}',
    );
    my %closing = reverse %pairs;

    my @stack;
    my $string;
    my $escape = 0;
    my @parts;
    my $start = 0;

    for (my $i = 0; $i < length $text; $i++) {
        my $char = substr($text, $i, 1);

        if (defined $string) {
            if ($escape) {
                $escape = 0;
                next;
            }

            if ($char eq '\\') {
                $escape = 1;
                next;
            }

            if ($char eq $string) {
                undef $string;
            }

            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            next;
        }

        if (exists $pairs{$char}) {
            push @stack, $char;
            next;
        }

        if (exists $closing{$char}) {
            return unless @stack;
            my $open = pop @stack;
            return unless $pairs{$open} eq $char;
            next;
        }

        next unless $char eq ',';

        if (!@stack) {
            my $chunk = substr($text, $start, $i - $start);
            push @parts, $chunk;
            $start = $i + 1;
        }
    }

    push @parts, substr($text, $start) if $start <= length $text;

    return @parts;
}

sub _split_top_level_operator {
    my ($text, $operator) = @_;

    return unless defined $text && defined $operator && length($operator) == 1;

    my %pairs = (
        '(' => ')',
        '[' => ']',
        '{' => '}',
    );
    my %closing = reverse %pairs;

    my @stack;
    my $string;
    my $escape = 0;

    for (my $i = 0; $i < length $text; $i++) {
        my $char = substr($text, $i, 1);

        if (defined $string) {
            if ($escape) {
                $escape = 0;
                next;
            }

            if ($char eq '\\') {
                $escape = 1;
                next;
            }

            if ($char eq $string) {
                undef $string;
            }

            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            next;
        }

        if (exists $pairs{$char}) {
            push @stack, $char;
            next;
        }

        if (exists $closing{$char}) {
            return if !@stack;
            my $open = pop @stack;
            return if $pairs{$open} ne $char;
            next;
        }

        next if $char ne $operator;

        if (!@stack) {
            if ($operator eq '+' || $operator eq '-') {
                my $prev = $i > 0 ? substr($text, $i - 1, 1) : '';
                my $next = $i + 1 < length $text ? substr($text, $i + 1, 1) : '';
                if ($prev =~ /[eE]/ && $next =~ /[0-9]/) {
                    next;
                }
                if ($next eq '=') {
                    next;
                }
            }

            my $lhs = substr($text, 0, $i);
            my $rhs = substr($text, $i + 1);
            return ($lhs, $rhs);
        }
    }

    return;
}

sub _split_top_level_colon {
    my ($text) = @_;

    return unless defined $text;

    my %pairs = (
        '(' => ')',
        '[' => ']',
        '{' => '}',
    );
    my %closing = reverse %pairs;

    my @stack;
    my $string;
    my $escape = 0;

    for (my $i = 0; $i < length $text; $i++) {
        my $char = substr($text, $i, 1);

        if (defined $string) {
            if ($escape) {
                $escape = 0;
                next;
            }

            if ($char eq '\\') {
                $escape = 1;
                next;
            }

            if ($char eq $string) {
                undef $string;
            }

            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            next;
        }

        if (exists $pairs{$char}) {
            push @stack, $char;
            next;
        }

        if (exists $closing{$char}) {
            return unless @stack;
            my $open = pop @stack;
            return unless $pairs{$open} eq $char;
            next;
        }

        next if $char ne ':';

        if (!@stack) {
            my $lhs = substr($text, 0, $i);
            my $rhs = substr($text, $i + 1);
            return ($lhs, $rhs);
        }
    }

    return;
}

sub _interpret_object_key {
    my ($raw) = @_;

    return unless defined $raw;

    my $text = $raw;
    $text =~ s/^\s+|\s+$//g;
    return if $text eq '';

    my $decoded = eval { $FROMJSON_DECODER->decode($text) };
    if (!$@ && !ref $decoded) {
        return $decoded;
    }

    if ($text =~ /^'(.*)'$/s) {
        my $inner = $1;
        $inner =~ s/\\'/'/g;
        return $inner;
    }

    return $text;
}

sub _split_top_level_semicolon {
    my ($text) = @_;

    my @parts = _split_top_level_semicolons($text);
    return unless @parts == 2;

    return @parts;
}

sub _matches_keyword {
    my ($text, $pos, $keyword) = @_;

    return 0 unless defined $text;
    return 0 if $pos < 0;

    my $kw_len = length $keyword;
    return 0 if $pos + $kw_len > length $text;
    return 0 if substr($text, $pos, $kw_len) ne $keyword;

    my $before = $pos == 0 ? '' : substr($text, $pos - 1, 1);
    my $after  = ($pos + $kw_len) < length $text ? substr($text, $pos + $kw_len, 1) : '';

    return 0 if $before =~ /[A-Za-z0-9_]/;
    return 0 if $after  =~ /[A-Za-z0-9_]/;

    return 1;
}

sub _parse_if_expression {
    my ($expr) = @_;

    return undef unless defined $expr;

    my $copy = _strip_wrapping_parens($expr);
    $copy =~ s/^\s+|\s+$//g;
    return undef unless $copy =~ /^if\b/;

    my $len = length $copy;
    my $pos = 0;

    return undef unless _matches_keyword($copy, $pos, 'if');
    $pos += 2;

    my $depth      = 1;
    my $state      = 'condition';
    my $current    = '';
    my $condition;
    my @branches;
    my $else_expr;

    my $in_single = 0;
    my $in_double = 0;
    my $escape    = 0;

    while ($pos < $len) {
        my $char = substr($copy, $pos, 1);

        if ($escape) {
            $current .= $char;
            $escape = 0;
            $pos++;
            next;
        }

        if ($in_single) {
            if ($char eq '\\') {
                $escape = 1;
            }
            elsif ($char eq "'") {
                $in_single = 0;
            }
            $current .= $char;
            $pos++;
            next;
        }

        if ($in_double) {
            if ($char eq '\\') {
                $escape = 1;
            }
            elsif ($char eq '"') {
                $in_double = 0;
            }
            $current .= $char;
            $pos++;
            next;
        }

        if ($char eq "'") {
            $in_single = 1;
            $current  .= $char;
            $pos++;
            next;
        }

        if ($char eq '"') {
            $in_double = 1;
            $current  .= $char;
            $pos++;
            next;
        }

        if (_matches_keyword($copy, $pos, 'if')) {
            $depth++;
            $current .= 'if';
            $pos += 2;
            next;
        }

        if (_matches_keyword($copy, $pos, 'then') && $depth == 1 && $state eq 'condition') {
            $condition = $current;
            $condition =~ s/^\s+|\s+$//g;
            return undef unless defined $condition && length $condition;

            $current = '';
            $state   = 'then';
            $pos    += 4;
            next;
        }

        if (_matches_keyword($copy, $pos, 'elif') && $depth == 1 && $state eq 'then') {
            my $then_expr = $current;
            $then_expr =~ s/^\s+|\s+$//g;
            $then_expr = '.' if !length $then_expr;

            return undef unless defined $condition;
            push @branches, { condition => $condition, then => $then_expr };

            $condition = undef;
            $current   = '';
            $state     = 'condition';
            $pos      += 4;
            next;
        }

        if (_matches_keyword($copy, $pos, 'else') && $depth == 1 && $state eq 'then') {
            my $then_expr = $current;
            $then_expr =~ s/^\s+|\s+$//g;
            $then_expr = '.' if !length $then_expr;

            return undef unless defined $condition;
            push @branches, { condition => $condition, then => $then_expr };

            $condition = undef;
            $current   = '';
            $state     = 'else';
            $pos      += 4;
            next;
        }

        if (_matches_keyword($copy, $pos, 'end')) {
            if ($depth == 1) {
                if ($state eq 'then') {
                    my $then_expr = $current;
                    $then_expr =~ s/^\s+|\s+$//g;
                    $then_expr = '.' if !length $then_expr;

                    return undef unless defined $condition;
                    push @branches, { condition => $condition, then => $then_expr };
                }
                elsif ($state eq 'else') {
                    my $else = $current;
                    $else =~ s/^\s+|\s+$//g;
                    $else_expr = length $else ? $else : undef;
                }
                elsif ($state eq 'condition') {
                    return undef;
                }

                $depth = 0;
                $pos  += 3;
                $current = '';
                $state   = 'done';
                last;
            }
            else {
                $depth--;
                $current .= 'end';
                $pos     += 3;
                next;
            }
        }

        if (_matches_keyword($copy, $pos, 'then') && $depth > 1) {
            $current .= 'then';
            $pos     += 4;
            next;
        }

        if (_matches_keyword($copy, $pos, 'elif') && $depth > 1) {
            $current .= 'elif';
            $pos     += 4;
            next;
        }

        if (_matches_keyword($copy, $pos, 'else') && $depth > 1) {
            $current .= 'else';
            $pos     += 4;
            next;
        }

        $current .= $char;
        $pos++;
    }

    return undef unless @branches;

    if ($pos < $len) {
        my $remaining = substr($copy, $pos);
        $remaining =~ s/^\s+//;
        return undef if $remaining =~ /\S/;
    }

    return {
        branches => \@branches,
        else     => $else_expr,
    };
}

sub _parse_reduce_expression {
    my ($expr) = @_;

    return undef unless defined $expr;

    my $copy = _strip_wrapping_parens($expr);
    return undef unless $copy =~ /^reduce\s+(.+?)\s+as\s+\$(\w+)\s*\((.*)\)$/s;

    my ($generator, $var_name, $body) = ($1, $2, $3);
    my @parts = _split_top_level_semicolons($body);
    return undef unless @parts == 2;
    my ($init_expr, $update_expr) = @parts;

    $generator   =~ s/^\s+|\s+$//g;
    $init_expr   =~ s/^\s+|\s+$//g;
    $update_expr =~ s/^\s+|\s+$//g;

    return {
        generator   => $generator,
        var_name    => $var_name,
        init_expr   => $init_expr,
        update_expr => $update_expr,
    };
}

sub _parse_foreach_expression {
    my ($expr) = @_;

    return undef unless defined $expr;

    my $copy = _strip_wrapping_parens($expr);
    return undef unless $copy =~ /^foreach\s+(.+?)\s+as\s+\$(\w+)\s*\((.*)\)$/s;

    my ($generator, $var_name, $body) = ($1, $2, $3);
    my @parts = _split_top_level_semicolons($body);
    return undef unless @parts >= 2 && @parts <= 3;

    my ($init_expr, $update_expr, $extract_expr) = @parts;

    for ($generator, $init_expr, $update_expr) {
        next unless defined $_;
        s/^\s+|\s+$//g;
    }

    if (defined $extract_expr) {
        $extract_expr =~ s/^\s+|\s+$//g;
    }

    return {
        generator    => $generator,
        var_name     => $var_name,
        init_expr    => $init_expr,
        update_expr  => $update_expr,
        extract_expr => $extract_expr,
    };
}

sub _resolve_variable_reference {
    my ($self, $name) = @_;

    return (undef, 0) unless defined $self && ref($self) eq 'JQ::Lite';
    return (undef, 0) unless defined $name && length $name;

    my $vars = $self->{_vars} || {};
    return (undef, 0) unless exists $vars->{$name};

    return ($vars->{$name}, 1);
}

sub _evaluate_variable_reference {
    my ($self, $name, $suffix) = @_;

    my ($value, $exists) = _resolve_variable_reference($self, $name);
    return () unless $exists;

    return ($value) if !defined $suffix || $suffix !~ /\S/;

    my $expr = $suffix;
    $expr =~ s/^\s+//;

    my ($values, $ok) = _evaluate_value_expression($self, $value, $expr);
    return $ok ? @$values : ();
}

sub _evaluate_value_expression {
    my ($self, $context, $expr) = @_;

    return ([], 0) unless defined $expr;

    my $copy = _strip_wrapping_parens($expr);
    $copy =~ s/^\s+|\s+$//g;
    return ([], 0) if $copy eq '';

    if (_looks_like_expression($copy)) {
        my %builtins = (
            floor => sub {
                my ($value) = @_;
                my $numeric = _coerce_number_strict($value, 'floor() argument');
                return _floor($numeric);
            },
            ceil => sub {
                my ($value) = @_;
                my $numeric = _coerce_number_strict($value, 'ceil() argument');
                return _ceil($numeric);
            },
            round => sub {
                my ($value) = @_;
                my $numeric = _coerce_number_strict($value, 'round() argument');
                return _round($numeric);
            },
            tonumber => sub {
                my ($value) = @_;
                return _tonumber($value);
            },
        );

        my ($ok, $value) = JQ::Lite::Expression::evaluate(
            expr          => $copy,
            context       => $context,
            resolve_path  => sub {
                my ($ctx, $path) = @_;
                return $ctx if !defined $path || $path eq '';
                my @values = _traverse($ctx, $path);
                return @values ? $values[0] : undef;
            },
            coerce_number => \&_coerce_number_strict,
            builtins      => \%builtins,
        );

        if ($ok) {
            return ([ $value ], 1);
        }
    }

    my @pipeline_parts = _split_top_level_pipes($copy);
    if (@pipeline_parts > 1) {
        if (defined $self && $self->can('run_query')) {
            my $json = _encode_json($context);
            my @outputs = $self->run_query($json, $copy);
            return ([ @outputs ], 1);
        }
    }

    if ($copy =~ /^\$(\w+)(.*)$/s) {
        my ($var, $suffix) = ($1, $2 // '');
        my @values = _evaluate_variable_reference($self, $var, $suffix);
        return (\@values, 1);
    }

    if ($copy =~ /^\[(.*)$/s) {
        $copy = ".$copy";
    }

    if ($copy eq '.') {
        return ([ $context ], 1);
    }

    if ($copy =~ /^\.(.*)$/s) {
        my $path = $1;
        $path =~ s/^\s+|\s+$//g;

        if ($path !~ /\s/ && $path !~ /[+\-*\/]/) {
            return ([], 1) unless defined $context;
            return ([], 1) if $path eq '';

            my @values = _traverse($context, $path);
            return (\@values, 1);
        }
    }

    my ($lhs_expr, $rhs_expr) = _split_top_level_operator($copy, '+');
    if (defined $lhs_expr && defined $rhs_expr) {
        $lhs_expr =~ s/^\s+|\s+$//g;
        $rhs_expr =~ s/^\s+|\s+$//g;

        if (length $lhs_expr && length $rhs_expr) {
            my ($lhs_values, $lhs_ok) = _evaluate_value_expression($self, $context, $lhs_expr);
            my $lhs;
            if ($lhs_ok) {
                $lhs = @$lhs_values ? $lhs_values->[0] : undef;
            }
            else {
                my @outputs = $self->run_query(_encode_json($context), $lhs_expr);
                $lhs = @outputs ? $outputs[0] : undef;
            }

            my ($rhs_values, $rhs_ok) = _evaluate_value_expression($self, $context, $rhs_expr);
            my $rhs;
            if ($rhs_ok) {
                $rhs = @$rhs_values ? $rhs_values->[0] : undef;
            }
            else {
                my @outputs = $self->run_query(_encode_json($context), $rhs_expr);
                $rhs = @outputs ? $outputs[0] : undef;
            }

            my $combined = _apply_addition($lhs, $rhs);
            return ([ $combined ], 1);
        }
    }

    if ($copy !~ /\bthen\b/i
        && $copy !~ /\belse\b/i
        && $copy !~ /\bend\b/i
        && $copy =~ /(?:==|!=|>=|<=|>|<|\band\b|\bor\b|\bcontains\b|\bhas\b|\bmatch\b)/)
    {
        my $bool = _evaluate_condition($context, $copy);
        my $json_bool = $bool ? JSON::PP::true : JSON::PP::false;
        return ([ $json_bool ], 1);
    }

    my $decoded = eval { _decode_json($copy) };
    if (!$@) {
        return ([ $decoded ], 1);
    }

    if ($copy =~ /^'(.*)'$/s) {
        my $text = $1;
        $text =~ s/\\'/'/g;
        return ([ $text ], 1);
    }

    return ([], 0);
}

sub _apply_addition {
    my ($left, $right) = @_;

    return $right if !defined $left;
    return $left  if !defined $right;

    if (ref($left) eq 'JSON::PP::Boolean') {
        $left = $left ? 1 : 0;
    }

    if (ref($right) eq 'JSON::PP::Boolean') {
        $right = $right ? 1 : 0;
    }

    if (!ref $left && !ref $right) {
        if (looks_like_number($left) && looks_like_number($right)) {
            return 0 + $left + $right;
        }

        my $left_is_num  = looks_like_number($left);
        my $right_is_num = looks_like_number($right);

        if ($left_is_num != $right_is_num) {
            die 'addition operands must both be numbers or both be non-numeric';
        }

        $left  = '' unless defined $left;
        $right = '' unless defined $right;
        return "$left$right";
    }

    if (ref $left eq 'ARRAY' && ref $right eq 'ARRAY') {
        return [ @$left, @$right ];
    }

    if (ref $left eq 'ARRAY') {
        return [ @$left, $right ];
    }

    if (ref $right eq 'ARRAY') {
        return [ $left, @$right ];
    }

    if (ref $left eq 'HASH' && ref $right eq 'HASH') {
        return { %$left, %$right };
    }

    return $right if !ref $left && ref $right eq 'HASH';
    return $left  if ref $left eq 'HASH' && !ref $right;

    return undef;
}

sub _coerce_number_strict {
    my ($value, $label) = @_;

    $label ||= 'value';

    die "$label must be a number" unless defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    die "$label must be a number" if ref $value;
    die "$label must be a number" unless looks_like_number($value);

    return 0 + $value;
}

sub _tonumber {
    my ($value) = @_;

    return undef unless defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (ref $value) {
        die 'tonumber(): argument must be a string or number';
    }

    my $text = "$value";
    $text =~ s/^\s+|\s+$//g;

    die 'tonumber(): not a numeric string' unless length $text && looks_like_number($text);

    return 0 + $text;
}

sub _looks_like_expression {
    my ($expr) = @_;

    return 0 unless defined $expr;

    return 1 if $expr =~ /\b(?:floor|ceil|round|tonumber)\b/;
    return 0 if $expr =~ /^\s*[\{\[]/;
    return 0 if $expr =~ /^[A-Za-z_]\w*\s*\(/;
    return 1 if $expr =~ /[\-*\/%]/;
    return 1 if $expr =~ /(?:==|!=|>=|<=|>|<|\band\b|\bor\b)/i;

    return 0;
}

sub _looks_like_assignment {
    my ($expr) = @_;

    return 0 unless defined $expr;
    return 0 if $expr =~ /[()]/;
    return 0 if $expr =~ /(?:==|!=|>=|<=|=>|=<)/;
    return ($expr =~ /=/);
}

sub _parse_assignment_expression {
    my ($expr) = @_;

    $expr //= '';

    my ($lhs, $op, $rhs) = ($expr =~ /^(.*?)\s*([+\-*\/]?=)\s*(.*)$/);

    $lhs //= '';
    $rhs //= '';
    $op  //= '=';

    $lhs =~ s/^\s+|\s+$//g;
    $rhs =~ s/^\s+|\s+$//g;

    $lhs =~ s/^\.//;

    my $value_spec = _parse_assignment_value($rhs);

    return ($lhs, $value_spec, $op);
}

sub _parse_assignment_value {
    my ($raw) = @_;

    $raw //= '';
    $raw =~ s/^\s+|\s+$//g;

    if ($raw =~ /^\.(.+)$/) {
        return { type => 'path', value => $1 };
    }

    my $decoded = eval { _decode_json($raw) };
    if (!$@) {
        return { type => 'literal', value => $decoded };
    }

    if ($raw =~ /^'(.*)'$/) {
        return { type => 'literal', value => $1 };
    }

    return { type => 'expression', value => $raw };
}

1;
