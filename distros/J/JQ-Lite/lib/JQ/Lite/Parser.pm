package JQ::Lite::Parser;

use strict;
use warnings;

use JQ::Lite::Util ();
use JQ::Lite::Error ();
use JQ::Lite::AST ();
use JQ::Lite::Tokenizer ();
use JSON::PP ();

sub _parse_error {
    my ($message) = @_;
    die JQ::Lite::Error::Parse->new(message => $message);
}

sub _validate_query_syntax {
    my ($query) = @_;

    return if !defined $query || $query eq '';

    my @stack;
    my $string;
    my $escape = 0;
    my %pairs = (')' => '(', ']' => '[', '}' => '{');

    for my $char (split //, $query) {
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

        if ($char eq '(' || $char eq '[' || $char eq '{') {
            push @stack, $char;
            next;
        }

        if (exists $pairs{$char}) {
            my $open = pop @stack;
            _parse_error('Invalid query syntax: unmatched brackets')
                if !defined $open || $open ne $pairs{$char};
        }
    }

    _parse_error('Invalid query syntax: unmatched brackets')
        if defined $string || @stack;

    my @pipeline_parts = JQ::Lite::Util::_split_top_level_pipes($query);
    _parse_error('Invalid query syntax: empty filter segment')
        if grep { !defined $_ || $_ !~ /\S/ } @pipeline_parts;

    for my $segment (@pipeline_parts) {
        my @comma_parts = JQ::Lite::Util::_split_top_level_commas($segment);
        _parse_error('Invalid query syntax: empty filter segment')
            if grep { !defined $_ || $_ !~ /\S/ } @comma_parts;
    }
}

sub parse_ast {
    my ($query) = @_;

    my @parts = parse_query($query);
    my @filters = map { JQ::Lite::AST->filter($_) } @parts;
    return JQ::Lite::AST->pipeline(@filters);
}

sub parse_query {
    my ($query) = @_;

    return () unless defined $query;
    return () if $query =~ /^\s*\.\s*$/;

    _validate_query_syntax($query);

    my $tokens = JQ::Lite::Tokenizer::tokenize($query);
    my @parts = map { $_->{value} } grep { $_->{type} eq 'FILTER' } @{$tokens};
    @parts = map {
        my $part = $_;
        $part =~ s/^\s+|\s+$//g;
        $part;
    } @parts;

    # Expand jq's iterator suffix before path normalization. This preserves
    # existing dotted path traversal such as .values[] while allowing any
    # non-path filter that produces an array or object (for example keys,
    # split(","), or an array constructor) to reuse the existing .[] logic.
    my @iterator_expanded;
    for my $part (@parts) {
        my @sequence_parts = JQ::Lite::Util::_split_top_level_commas($part);
        if (@sequence_parts > 1) {
            for my $sequence_part (@sequence_parts) {
                $sequence_part =~ s/^\s+|\s+$//g;
                next if $sequence_part =~ /^\./s;
                if ($sequence_part =~ /^(.*?)\s*\[\s*\]\s*$/s) {
                    my $filter = $1;
                    $filter =~ s/\s+$//;
                    $sequence_part = "($filter | .[])" if $filter =~ /\S/;
                }
            }
            push @iterator_expanded, join(', ', @sequence_parts);
            next;
        }

        if ($part !~ /^\s*\./s && $part =~ /^(.*?)\s*\[\s*\]\s*$/s) {
            my $filter = $1;
            $filter =~ s/\s+$//;
            if ($filter =~ /\S/) {
                push @iterator_expanded, $filter, '.[]';
            }
            else {
                push @iterator_expanded, $part;
            }
        }
        else {
            push @iterator_expanded, $part;
        }
    }
    @parts = @iterator_expanded;

    @parts = map {
        if ($_ eq '.[]') {
            '.[]';
        }
        elsif ($_ =~ /^\.(.+)$/) {
            my $rest = $1;
            if ($rest eq 'count') {
                $_;
            }
            elsif ($rest =~ /,/) {
                $_;
            }
            elsif ($rest =~ /^\s*\[/) {
                $_;
            }
            elsif ($rest =~ /^\s*[+\-*\/%]/
                || $rest =~ /[+\-*\/%]/
                || $rest =~ /(?:==|!=|>=|<=|>|<|\band\b|\bor\b)/i
                || $rest =~ /\b(?:floor|ceil|round|tonumber)\b/)
            {
                $_;
            }
            else {
                my $trimmed = $rest;
                $trimmed =~ s/^\s+|\s+$//g;
                if ($trimmed =~ /^"(?:[^"\\]|\\.)*"$/s) {
                    my $decoded = eval { JQ::Lite::Util::_decode_json($trimmed) };
                    return $decoded if defined $decoded && !$@;
                }
                $rest;
            }
        }
        else {
            $_;
        }
    } @parts;

    @parts = map { _lower_object_shorthand($_) } @parts;

    my @expanded;
    for my $part (@parts) {
        next unless defined $part;

        my $trimmed = $part;
        $trimmed =~ s/^\s+|\s+$//g;

        if ($trimmed =~ /^\(.*\)$/s) {
            my $inner = JQ::Lite::Util::_strip_wrapping_parens($trimmed);
            if (defined $inner && length $inner && $inner ne $trimmed) {
                my @inner_parts = parse_query($inner);
                if (@inner_parts) {
                    push @expanded, @inner_parts;
                    next;
                }
            }
        }

        push @expanded, $trimmed;
    }

    return @expanded;
}

sub _lower_object_shorthand {
    my ($text) = @_;

    return $text unless defined $text;
    return $text if index($text, '{') == -1;

    my $result = '';
    my $len    = length $text;
    my $i      = 0;
    my $string;
    my $escape = 0;

    while ($i < $len) {
        my $char = substr($text, $i, 1);

        if (defined $string) {
            $result .= $char;
            if ($escape) {
                $escape = 0;
            }
            elsif ($char eq '\\') {
                $escape = 1;
            }
            elsif ($char eq $string) {
                undef $string;
            }
            $i++;
            next;
        }

        if ($char eq "'" || $char eq '"') {
            $string = $char;
            $result .= $char;
            $i++;
            next;
        }

        if ($char eq '{') {
            my ($body, $consumed) = _extract_object_body($text, $i);
            if (defined $body) {
                my $lowered = _lower_object_constructor($body);
                $result .= '{' . $lowered . '}';
                $i += $consumed;
                next;
            }
        }

        $result .= $char;
        $i++;
    }

    return $result;
}

sub _extract_object_body {
    my ($text, $start) = @_;

    my $len     = length $text;
    my $depth   = 0;
    my $string;
    my $escape  = 0;

    for (my $i = $start; $i < $len; $i++) {
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

        if ($char eq '{') {
            $depth++;
            next;
        }

        if ($char eq '}') {
            $depth--;
            if ($depth == 0) {
                my $body = substr($text, $start + 1, $i - $start - 1);
                return ($body, $i - $start + 1);
            }
            next;
        }
    }

    return (undef, 1);
}

sub _lower_object_constructor {
    my ($inner) = @_;

    return $inner unless defined $inner;

    my @parts = JQ::Lite::Util::_split_top_level_commas($inner);
    return $inner unless @parts;

    my @transformed;
    for my $part (@parts) {
        next unless defined $part;

        my $trimmed = $part;
        $trimmed =~ s/^\s+|\s+$//g;
        next if $trimmed eq '';

        my ($lhs, $rhs) = JQ::Lite::Util::_split_top_level_colon($part);

        if (defined $lhs && defined $rhs) {
            my $key = $lhs;
            $key =~ s/^\s+|\s+$//g;

            my $value = _lower_object_shorthand($rhs);
            $value =~ s/^\s+|\s+$//g;

            push @transformed, "$key: $value";
            next;
        }

        if (!defined $lhs && $trimmed =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
            push @transformed, "$trimmed: .$trimmed";
            next;
        }

        if (defined $lhs && !defined $rhs) {
            my $key = $lhs;
            $key =~ s/^\s+|\s+$//g;
            next if $key eq '';
            push @transformed, "$key: .$key";
            next;
        }

        my $lowered = _lower_object_shorthand($trimmed);
        $lowered =~ s/^\s+|\s+$//g;
        push @transformed, $lowered if length $lowered;
    }

    return join(', ', @transformed);
}

1;
