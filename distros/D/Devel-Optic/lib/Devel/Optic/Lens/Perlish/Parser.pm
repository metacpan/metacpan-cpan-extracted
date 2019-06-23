package Devel::Optic::Lens::Perlish::Parser;
$Devel::Optic::Lens::Perlish::Parser::VERSION = '0.012';
# ABSTRACT: Lexer/parser for Perlish lens

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse lex);

use Carp qw(croak);
our @CARP_NOT = qw(Devel::Optic::Lens::Perlish Devel::Optic);

use Devel::Optic::Lens::Perlish::Constants qw(:all);

use constant {
    'ACCESS_OPERATOR'   => '->',
    'HASHKEY_OPEN'      => '{',
    'HASHKEY_CLOSE'     => '}',
    'ARRAYINDEX_OPEN'   => '[',
    'ARRAYINDEX_CLOSE'  => ']',
};

my %symbols = map { $_ => 1 } qw({ } [ ]);

sub parse {
    my ($route) = @_;
    my @tokens = lex($route);
    return _parse_tokens(@tokens);
}

# %foo->{'bar'}->[-2]->{$baz->{'asdf'}}->{'blorg}'}
sub lex {
    my ($str) = @_;

    if (!defined $str) {
        croak "invalid syntax: undefined query";
    }

    # ignore whitespace
    my @chars = grep { $_ !~ /\s/ } split //, $str;
    my ( $elem, @items );

    if (scalar @chars == 0) {
        croak "invalid syntax: empty query";
    }

    if ($chars[0] ne '$' && $chars[0] ne '@' && $chars[0] ne '%') {
        croak 'invalid syntax: query must start with a Perl symbol (prefixed by a $, @, or % sigil)';
    }

    my $in_string;
    for ( my $idx = 0; $idx <= $#chars; $idx++ ) {
        my $char     = $chars[$idx];
        my $has_next = $#chars >= $idx + 1;
        my $next     = $chars[ $idx + 1 ];

        # Special case: escaped characters
        if ( $char eq '\\' && $has_next ) {
            $elem .= $next;
            $idx++;
            next;
        }

        # Special case: string handling
        if ( $char eq "'") {
            $in_string = !$in_string;
            $elem .= $char;
            next;
        }

        # Special case: arrow
        if ( !$in_string && $char eq '-' && $has_next ) {
            if ( $next eq '>' ) {
                if (defined $elem) {
                    push @items, $elem;
                    undef $elem;
                }
                $idx++;
                push @items, '->';
                next;
            }
        }

        if ( !$in_string && exists $symbols{$char} ) {
            if (defined $elem) {
                push @items, $elem;
                undef $elem;
            }
            push @items, $char;
            next;
        }

        # Special case: last item
        if ( !$has_next ) {
            $elem .= $char;
            push @items, $elem;
            last; # unnecessary, but more readable, I think
        }

        # Normal case
        $elem .= $char;
    }

    if ($in_string) {
        croak "invalid syntax: unclosed string";
    }

    return @items;
}

sub _parse_hash {
    my @tokens = @_;
    my $brace_count = 0;
    my $close_index;
    for (my $i = 0; $i <= $#tokens; $i++) {
        if ($tokens[$i] eq HASHKEY_OPEN) {
            $brace_count++;
        }
        if ($tokens[$i] eq HASHKEY_CLOSE) {
            $brace_count--;
            if ($brace_count == 0) {
                $close_index = $i;
                last;
            }
        }
    }

    croak sprintf("invalid syntax: unclosed hash key (missing '%s')", HASHKEY_CLOSE) if !defined $close_index;
    croak "invalid syntax: empty hash key" if $close_index == 1;

    return $close_index, [OP_HASHKEY, _parse_tokens(@tokens[1 .. $close_index-1])];
}

sub _parse_array {
    my @tokens = @_;
    my $bracket_count = 0;
    my $close_index;
    for (my $i = 0; $i <= $#tokens; $i++) {
        if ($tokens[$i] eq ARRAYINDEX_OPEN) {
            $bracket_count++;
        }

        if ($tokens[$i] eq ARRAYINDEX_CLOSE) {
            $bracket_count--;
            if ($bracket_count == 0) {
                $close_index = $i;
                last;
            }
        }
    }

    croak sprintf("invalid syntax: unclosed array index (missing '%s')", ARRAYINDEX_CLOSE) if !defined $close_index;
    croak "invalid syntax: empty array index" if $close_index == 1;

    return $close_index, [OP_ARRAYINDEX, _parse_tokens(@tokens[1 .. $close_index-1])];
}

sub _parse_tokens {
    my (@tokens) = @_;
    my $left_node;
    for (my $i = 0; $i <= $#tokens; $i++) {
        my $token = $tokens[$i];

        if ($token =~ /^[\$\%\@]/) {
            if ($token !~ /^[\$\%\@]\w+$/) {
                croak sprintf 'invalid symbol: "%s". symbols must start with a Perl sigil ($, %%, or @) and contain only word characters', $token;
            }

            $left_node = [SYMBOL, $token];
            next;
        }

        if ($token =~ /^-?\d+$/) {
            $left_node = [NUMBER, 0+$token];
            next;
        }

        if ($token eq HASHKEY_OPEN) {
            croak sprintf "found '%s' outside of a %s operator. use %s regardless of sigil",
                HASHKEY_OPEN, ACCESS_OPERATOR, ACCESS_OPERATOR;
        }

        if ($token eq HASHKEY_CLOSE) {
            croak sprintf "found '%s' outside of a %s operator", HASHKEY_CLOSE, ACCESS_OPERATOR;
        }

        if ($token eq ARRAYINDEX_OPEN) {
            croak sprintf "found '%s' outside of a %s operator. use %s regardess of sigil",
                ARRAYINDEX_OPEN, ACCESS_OPERATOR, ACCESS_OPERATOR;
        }

        if ($token eq ARRAYINDEX_CLOSE) {
            croak sprintf "found '%s' outside of a %s operator", ARRAYINDEX_CLOSE, ACCESS_OPERATOR;
        }

        if ($token eq ACCESS_OPERATOR) {
            my $next = $tokens[++$i];
            if (!defined $next) {
                croak sprintf "invalid syntax: '%s' needs something on the right hand side", ACCESS_OPERATOR;
            }

            my $right_node;
            if ($next eq HASHKEY_OPEN) {
                my ($close_index, $hash_node) = _parse_hash(@tokens[$i .. $#tokens]);
                $right_node = $hash_node;
                $i += $close_index;
            } elsif ($next eq ARRAYINDEX_OPEN) {
                my ($close_index, $array_node) = _parse_array(@tokens[$i .. $#tokens]);
                $right_node = $array_node;
                $i += $close_index;
            } else {
                croak sprintf(
                    q|invalid syntax: %s expects either hash key "%s'foo'%s" or array index "%s0%s" on the right hand side. found '%s' instead|,
                    ACCESS_OPERATOR,
                    HASHKEY_OPEN, HASHKEY_CLOSE,
                    ARRAYINDEX_OPEN, ARRAYINDEX_CLOSE,
                    $next,
                );
            }

            if (!defined $left_node) {
                croak sprintf("%s requires something on the left side", ACCESS_OPERATOR);
            }

            $left_node = [OP_ACCESS, [
                $left_node,
                $right_node,
            ]];

            next;
        }

        if ($token =~ /^'(.+)'$/) {
            $left_node = [STRING, $1];
            next;
        }

        croak "unrecognized token '$token'. hash key strings must be quoted with single quotes"
    }

    return $left_node;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Optic::Lens::Perlish::Parser - Lexer/parser for Perlish lens

=head1 VERSION

version 0.012

=head1 AUTHOR

Ben Tyler <btyler@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ben Tyler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
