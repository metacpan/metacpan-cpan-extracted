package JQ::Lite::Parser;

use strict;
use warnings;

use JQ::Lite::Util ();

sub parse_query {
    my ($query) = @_;

    return () unless defined $query;
    return () if $query =~ /^\s*\.\s*$/;

    my @parts = JQ::Lite::Util::_split_top_level_pipes($query);
    @parts = map {
        my $part = $_;
        $part =~ s/^\s+|\s+$//g;
        $part;
    } @parts;

    @parts = map {
        if ($_ eq '.[]') {
            'flatten';
        }
        elsif ($_ =~ /^\.(.+)$/) {
            my $rest = $1;
            if ($rest =~ /^\s*[+\-*\/%]/ || $rest =~ /[+\-*\/%]/ || $rest =~ /\b(?:floor|ceil|round|tonumber)\b/) {
                $_;
            }
            else {
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
