#!perl
use strict;
use warnings;
use Data::Dumper;
use JSON::YAJL;
use Marpa;

my $filename = shift || die 'Please pass a JSON filename to reformat';
my @tokens = tokenize($filename);

my $data = parse(@tokens);
print Dumper($data);

sub tokenize {
    my $filename = shift;
    my @tokens;

    my $text;
    my $parser = JSON::YAJL::Parser->new(
        0, 0,
        [   sub {
                push @tokens, ['null'];
            },
            sub {
                push @tokens, [ 'bool', shift ];
            },
            undef,
            undef,
            sub {
                push @tokens, [ 'number', shift ];
            },
            sub {
                push @tokens, [ 'string', shift ];
            },
            sub {
                push @tokens, ['map_open'];
            },
            sub {
                push @tokens, [ 'key', shift ];
            },
            sub {
                push @tokens, ['map_close'];
            },
            sub {
                push @tokens, ['array_open'];
            },
            sub {
                push @tokens, ['array_close'];
            },
        ]
    );
    my $json
        = '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}';
    $parser->parse($json);
    $parser->parse_complete();
    return @tokens;
}

sub parse {
    my @tokens  = @_;
    my $grammar = Marpa::Grammar->new(
        {   start          => 'Open',
            actions        => 'main',
            default_action => 'action_default',
            lhs_terminals  => 0,
            strip          => 0,
            rules          => [
                {   lhs    => 'Open',
                    rhs    => [qw/map_open Bits map_close/],
                    action => 'action_map',
                },
                {   lhs    => 'Open',
                    rhs    => [qw/array_open Bits array_close/],
                    action => 'action_array',
                },

                {   lhs    => 'Bits',
                    rhs    => [qw/Bit/],
                    min    => 0,
                    action => 'action_bits',
                },
                {   lhs => 'Bit',
                    rhs => [qw/Open/],
                },
                {   lhs => 'Bit',
                    rhs => [qw/key/],
                },
                {   lhs => 'Bit',
                    rhs => [qw/number/],
                },
                {   lhs => 'Bit',
                    rhs => [qw/string/],
                },
                {   lhs => 'Bit',
                    rhs => [qw/null/],
                },
                {   lhs => 'Bit',
                    rhs => [qw/bool/],
                },
            ],
        }
    );

    $grammar->precompute();

    my $recce = Marpa::Recognizer->new(
        {   grammar           => $grammar,
            trace_terminals   => 2,
            trace_actions     => 0,
            trace_values      => 0,
            trace_earley_sets => 0,
            mode              => 'stream',
        }
    );

    $recce->tokens( \@tokens );
    return $recce->value;
}

sub action_default {
    shift;
    return shift;
}

sub action_map {
    shift;
    shift;
    my $what = shift;
    return {@$what};
}

sub action_array {
    shift;
    my @args = @_;
    pop @args;
    shift @args;
    return [@args];
}

sub action_bits {
    shift;
    return [@_];
}

=head1 NAME

json_decode.pl - Decode JSON as a Perl data structure

=head1 DESCRIPTION

This example program uses the parsing parts of L<JSON::YAJL> and a parser
based on L<Marpa> to decode JSON as a Perl data structure. This is an example
of how a higher-level JSON parser could be build upon L<JSON::YAJL> and this
is not recommended for serious use.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<JSON::YAJL>
