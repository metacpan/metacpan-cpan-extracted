package JSON::Path::Tokenizer;
$JSON::Path::Tokenizer::VERSION = '0.310';
use strict;
use warnings;
use 5.008;

use Carp;
use Readonly;
use JSON::Path::Constants qw(:symbols);
use Exporter::Easy ( OK => [ 'tokenize' ] );

Readonly my $ESCAPE_CHAR => qq{\\};
Readonly my %RESERVED_SYMBOLS => (
    $DOLLAR_SIGN          => 1,
    $COMMERCIAL_AT        => 1,
    $FULL_STOP            => 1,
    $LEFT_SQUARE_BRACKET  => 1,
    $RIGHT_SQUARE_BRACKET => 1,
    $ASTERISK             => 1,
    $COLON                => 1,
    $LEFT_PARENTHESIS     => 1,
    $RIGHT_PARENTHESIS    => 1,
    $COMMA                => 1,
    $EQUAL_SIGN           => 1,
    $EXCLAMATION_MARK     => 1,
    $GREATER_THAN_SIGN    => 1,
    $LESS_THAN_SIGN       => 1,
);

# ABSTRACT: Helper class for JSON::Path::Evaluator. Do not call directly.

# Take an expression and break it up into tokens
sub tokenize {
    my $expression = shift;

    # $expression = normalize($expression);
    my @tokens;
    my @chars = split //, $expression;
    my $char;
    while ( defined( my $char = shift @chars ) ) {
        my $token = $char;

        if ($char eq $ESCAPE_CHAR) { 
            my $next_char = shift @chars;
            $token .= $next_char;
        }
        elsif ( $RESERVED_SYMBOLS{$char}) {
            if ( $char eq $FULL_STOP ) {    # distinguish between the '.' and '..' tokens
                my $next_char = shift @chars;
                if ( $next_char eq $FULL_STOP ) {
                    $token .= $next_char;
                }
                else {
                    unshift @chars, $next_char;
                }
            }
            elsif ( $char eq $LEFT_SQUARE_BRACKET ) {
                my $next_char = shift @chars;

                # $.addresses[?(@.addresstype.id == D84002)]

                if ( $next_char eq $LEFT_PARENTHESIS ) {
                    $token .= $next_char;
                }
                elsif ( $next_char eq $QUESTION_MARK ) {
                    $token .= $next_char;
                    my $next_char = shift @chars;
                    if ( $next_char eq $LEFT_PARENTHESIS ) {
                        $token .= $next_char;
                    }
                    else {
                        die qq{filter operator "$token" must be followed by '('\n};
                    }
                }
                else {
                    unshift @chars, $next_char;
                }
            }
            elsif ( $char eq $RIGHT_PARENTHESIS ) {
                my $next_char = shift @chars;
                no warnings qw/uninitialized/;
                die qq{Unterminated expression: '[(' or '[?(' without corresponding ')]'\n}
                    unless $next_char eq $RIGHT_SQUARE_BRACKET;
                use warnings qw/uninitialized/;
                $token .= $next_char;
            }
            elsif ( $char eq $EQUAL_SIGN ) {    # Build '=', '==', or '===' token as appropriate
                my $next_char = shift @chars;
                if ( !defined $next_char ) {
                    die qq{Unterminated comparison: '=', '==', or '===' without predicate\n};
                }
                if ( $next_char eq $EQUAL_SIGN ) {
                    $token .= $next_char;
                    $next_char = shift @chars;
                    if ( !defined $next_char ) {
                        die qq{Unterminated comparison: '==' or '===' without predicate\n};
                    }
                    if ( $next_char eq $EQUAL_SIGN ) {
                        $token .= $next_char;
                    }
                    else {
                        unshift @chars, $next_char;
                    }
                }
                else {
                    unshift @chars, $next_char;
                }
            }
            elsif ( $char eq $LESS_THAN_SIGN || $char eq $GREATER_THAN_SIGN ) {
                my $next_char = shift @chars;
                if ( !defined $next_char ) {
                    die qq{Unterminated comparison: '=', '==', or '===' without predicate\n};
                }
                if ( $next_char eq $EQUAL_SIGN ) {
                    $token .= $next_char;
                }
                else {
                    unshift @chars, $next_char;
                }
            }
        }
        else {
            # Read from the character stream until we have a valid token
            while ( defined( $char = shift @chars ) ) {
                if ( $char eq $ESCAPE_CHAR ) { 
                    $char = shift @chars;
                }
                elsif ( $RESERVED_SYMBOLS{$char} ) {
                    unshift @chars, $char;
                    last;
                }
                $token .= $char;
            }
        }
        push @tokens, $token;
    }

    return @tokens;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Path::Tokenizer - Helper class for JSON::Path::Evaluator. Do not call directly.

=head1 VERSION

version 0.310

=head1 AUTHOR

Kit Peters <kit.peters@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kit Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
