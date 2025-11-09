package JQ::Lite::Util;

use strict;
use warnings;

use JSON::PP ();
use List::Util qw(sum min max);
use Scalar::Util qw(looks_like_number);
use MIME::Base64 qw(encode_base64 decode_base64);
use Encode qw(encode is_utf8);
use B ();
use JQ::Lite::Expression ();

my $JSON_DECODER     = JSON::PP->new->utf8->allow_nonref;
my $FROMJSON_DECODER = JSON::PP->new->utf8->allow_nonref;
my $TOJSON_ENCODER   = JSON::PP->new->utf8->allow_nonref;

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

        if (exists $closing{$char}) {
            return unless @stack;
            my $open = pop @stack;
            return unless $pairs{$open} eq $char;
            next;
        }

        next unless $char eq '|';
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

    return 1 if $expr =~ /[\-*\/%]/;
    return 1 if $expr =~ /\b(?:floor|ceil|round|tonumber)\b/;

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

    return { type => 'literal', value => $raw };
}

sub _apply_assignment {
    my ($item, $path, $value_spec, $operator) = @_;

    return $item unless defined $item;
    return $item unless defined $path && length $path;

    $operator //= '=';

    my $value = _resolve_assignment_value($item, $value_spec);

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
    my ($item, $value_spec) = @_;

    return undef unless defined $value_spec;

    if ($value_spec->{type} && $value_spec->{type} eq 'path') {
        my $path = $value_spec->{value} // '';
        $path =~ s/^\.//;

        my @values = _traverse($item, $path);
        return _clone_for_assignment($values[0]);
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
        return [ [] ];
    }

    my @paths;
    _collect_paths($value, [], \@paths);
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
                push @paths, map { [ @$_ ] } @$decoded;
            }
            else {
                push @paths, [ @$decoded ];
            }
        }
        else {
            push @paths, [ $decoded ];
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(_encode_json($value), $expr);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    push @paths, grep { ref $_ eq 'ARRAY' } @$output;
                }
                elsif (!@$output || !ref $output->[0]) {
                    push @paths, [ @$output ];
                }
            }
            elsif (!ref $output || ref($output) eq 'JSON::PP::Boolean') {
                push @paths, [ $output ];
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
        next unless ref $path eq 'ARRAY';
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
                push @paths, map { [ @$_ ] } @$decoded;
            }
            else {
                push @paths, [ @$decoded ];
            }
        }
        else {
            push @paths, [ $decoded ];
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(_encode_json($value), $clean);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    push @paths, grep { ref $_ eq 'ARRAY' } @$output;
                }
                elsif (!@$output || !ref $output->[0]) {
                    push @paths, [ @$output ];
                }
            }
            elsif (!ref $output || ref($output) eq 'JSON::PP::Boolean') {
                push @paths, [ $output ];
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

sub _traverse_path_array {
    my ($value, $path) = @_;

    return undef unless defined $value;
    return $value unless defined $path;
    return $value if ref($path) ne 'ARRAY';

    my $cursor = $value;
    for my $segment (@$path) {
        return undef unless defined $cursor;

        if (ref $cursor eq 'HASH') {
            my $key = defined $segment ? "$segment" : return undef;
            return undef unless exists $cursor->{$key};
            $cursor = $cursor->{$key};
            next;
        }

        if (ref $cursor eq 'ARRAY') {
            return undef unless defined $segment;

            my $index = "$segment";
            if ($index =~ /^-?\d+$/) {
                my $numeric = int($index);
                $numeric += @$cursor if $numeric < 0;
                return undef if $numeric < 0 || $numeric > $#$cursor;
                $cursor = $cursor->[$numeric];
                next;
            }

            return undef;
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

sub _from_entries {
    my ($value) = @_;

    return $value unless ref $value eq 'ARRAY';

    my %result;
    for my $entry (@$value) {
        my $normalized = _normalize_entry($entry);
        next unless $normalized;

        my $key = $normalized->{key};
        $result{$key} = $normalized->{value};
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
            if (@$decoded_paths && ref $decoded_paths->[0] eq 'ARRAY') {
                push @paths, map { [ @$_ ] } @$decoded_paths;
            }
            elsif (!@$decoded_paths) {
                # no paths supplied
            }
            else {
                push @paths, [ @$decoded_paths ];
            }
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(_encode_json($value), $filter);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    push @paths, grep { ref $_ eq 'ARRAY' } @$output;
                } elsif (!@$output || !ref $output->[0]) {
                    push @paths, $output;
                }
            }
        }
    }

    return $value unless @paths;

    if (grep { ref $_ eq 'ARRAY' && !@$_ } @paths) {
        return undef;
    }

    my $clone = _deep_clone($value);

    for my $path (@paths) {
        next unless ref $path eq 'ARRAY';
        next unless @$path;
        _delete_path_inplace($clone, [@$path]);
    }

    return $clone;
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
            my $key = defined $segment ? "$segment" : return;
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
        my $key = defined $last ? "$last" : return;
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
    return JSON::PP::false if $error;

    return _test_against_regex($value, $regex);
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

sub _build_regex {
    my ($pattern, $flags) = @_;

    $pattern = '' unless defined $pattern;
    $flags   = '' unless defined $flags;

    my %allowed = map { $_ => 1 } qw(i m s x);
    my $modifiers = '';
    for my $flag (split //, $flags) {
        next unless $allowed{$flag};
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
        return [ map { _apply_split($_, $separator) } @$value ];
    }

    return [] if !defined $value;
    return $value if ref $value;

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
    return $value if ref $value;

    my ($start, $length) = @args;
    $start = 0 unless defined $start;
    $start = int($start);

    if (defined $length) {
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

        if (defined $raw_start && looks_like_number($raw_start)) {
            $start = int($raw_start);
        }

        $start += $size if $start < 0;
        $start = 0       if $start < 0;
        return []        if $start >= $size;

        my $length;
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
    return defined $sequence ? @$sequence : ($value);
}

sub _build_range_sequence {
    my ($args_ref) = @_;

    my @args = @$args_ref;
    return undef unless @args;

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

    return undef unless defined $start && defined $end;
    return undef if !defined $step;
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

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    return looks_like_number($value) ? 0 + $value : undef;
}

sub _apply_contains {
    my ($value, $needle) = @_;

    if (ref $value eq 'ARRAY') {
        for my $item (@$value) {
            return JSON::PP::true if _values_equal($item, $needle);
        }
        return JSON::PP::false;
    }

    if (ref $value eq 'HASH') {
        return exists $value->{$needle} ? JSON::PP::true : JSON::PP::false;
    }

    return JSON::PP::false if !defined $value;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        my $haystack = "$value";
        my $fragment = defined $needle ? "$needle" : '';
        return index($haystack, $fragment) >= 0 ? JSON::PP::true : JSON::PP::false;
    }

    return JSON::PP::false;
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
        return JSON::PP::false unless looks_like_number($needle);

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

    my %counts;
    for my $item (@$array_ref) {
        my @keys = _traverse($item, $path);
        my $key = defined $keys[0] ? "$keys[0]" : 'null';
        $counts{$key}++;
    }

    return \%counts;
}

1;
