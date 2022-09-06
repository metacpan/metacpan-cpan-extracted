package JSON::Path::Tokenizer;
$JSON::Path::Tokenizer::VERSION = '1.0.2';
use strict;
use warnings;

use Carp;
use Readonly;
use JSON::Path::Constants qw(:symbols :operators);
use Exporter::Shiny 'tokenize';

Readonly my $ESCAPE_CHAR => qq{\\};
Readonly my %OPERATORS => (
    $TOKEN_ROOT                => 1,    # $
    $TOKEN_RECURSIVE           => 1,    # ..
    $TOKEN_CHILD               => 1,    # .
    $TOKEN_FILTER_OPEN         => 1,    # [?(
    $TOKEN_FILTER_SCRIPT_CLOSE => 1,    # )]
    $TOKEN_SCRIPT_OPEN         => 1,    # [(
    $TOKEN_SUBSCRIPT_OPEN      => 1,    # [
    $TOKEN_SUBSCRIPT_CLOSE     => 1,    # ]
    $TOKEN_QUOTE               => 1,    # "
);

# my $invocation = 0;

# ABSTRACT: Helper class for JSON::Path::Evaluator. Do not call directly.

# Take an expression and break it up into tokens
sub tokenize {
    my $expression = shift;
    #print "Tokenize \"$expression\"\n";
    my $chars = [ split //, $expression ];

    my @tokens;
    while ( defined( my $token = _read_to_next_token($chars) ) ) {

        #        print "$invocation: Got token: $token\n";
        push @tokens, $token;
        if ( $token eq $TOKEN_SCRIPT_OPEN || $token eq $TOKEN_FILTER_OPEN ) {

            #            print "$invocation: script/filter open: $token\n";
            push @tokens, _read_to_filter_script_close($chars);
        }
    }
    return @tokens;
}

sub _read_to_filter_script_close {
    my $chars = shift;

    #print "$invocation: read to filter script close: " . join( '', @{$chars} ) . "\n";
    my $filter;
    my $in_quote;
    while ( defined( my $char = shift @{$chars} ) ) {
        $filter .= $char;
        if ( $char eq $APOSTROPHE || $char eq $QUOTATION_MARK ) {
            if ( $in_quote && $in_quote eq $char ) {
                $in_quote = '';
            }
            else {
                $in_quote = $char;
            }
        }

        last unless @{$chars};
        last if $chars->[0] eq $RIGHT_PARENTHESIS && !$in_quote;
    }
    return $filter;
}

sub _read_to_next_token {
    #$invocation++;
    my $chars = shift;

    #print "$invocation: Get next token: " . join( '', @{$chars} ) . "\n";
    my $in_quote = '';
    my $token;
    while ( defined( my $char = shift @{$chars} ) ) {

        if ( $char eq $APOSTROPHE || $char eq $QUOTATION_MARK ) {
            #print "$invocation: Char is $APOSTROPHE or $QUOTATION_MARK. Char: $char, in_quote: $in_quote\n";
            if ( $in_quote && $in_quote eq $char ) {
                $in_quote = '';
                last;
            }
            $in_quote = $char;

            #print "$invocation: Set \$in_quote to $in_quote\n";
            next;
        }

        if ( $char eq $ESCAPE_CHAR && !$in_quote ) {

            #print "$invocation: Got escape char: $char\n";
            $token .= shift @{$chars};
            next;
        }

        #print "Append '$char' to token '$token'\n";
        $token .= $char;
        next if $in_quote;

 # Break out of the loop if the current character is the last one in the stream.
        last unless @{$chars};

        if ( $char eq $LEFT_SQUARE_BRACKET )
        {    # distinguish between '[', '[(', and '[?('
            if ( $chars->[0] eq $LEFT_PARENTHESIS ) {
                next;
            }
            if ( $chars->[0] eq $QUESTION_MARK ) {

# The below appends the '?'. The '(' will be appended in the next iteration of the loop
                $token .= shift @{$chars};
                next;
            }
        }
        elsif ( $char eq $RIGHT_PARENTHESIS ) {

            #print "$invocation: Found right parenthesis\n";

# A right parenthesis should be followed by a right square bracket, which itself is a token.
# Append the next character and proceed.
            $token .= shift @{$chars};

            #print "$invocation: Token is now: $token\n";
        }
        elsif ( $char eq $FULL_STOP ) {

# A full stop (i.e. a period, '.') may be the child operator '.' or the recursive operator '..'
            $token .= shift @{$chars} if $chars->[0] eq $FULL_STOP;
        }

        # If we've assembled an operator, we're done.
        last if $OPERATORS{$token};

        # Similarly, if the next character is an operator, we're done
        last if $OPERATORS{ $chars->[0] };
    }
    no warnings qw/uninitialized/;

    #print "$invocation: Token: $token\n";
    use warnings qw/uninitialized/;
    return $token;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Path::Tokenizer - Helper class for JSON::Path::Evaluator. Do not call directly.

=head1 VERSION

version 1.0.2

=head1 AUTHOR

Kit Peters <popefelix@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Kit Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
