#!perl
use strict;
use warnings;
use JSON::YAJL;

my $filename = shift || die 'Please pass a JSON filename to reformat';

my $generator = JSON::YAJL::Generator->new(1, '    ');

my $text;
my $parser = JSON::YAJL::Parser->new(
    0, 0,
    [   sub { $generator->null },
        sub { $generator->bool(shift) },
        undef,
        undef,
        sub { $generator->number(shift) },
        sub { $generator->string(shift) },
        sub { $generator->map_open },
        sub { $generator->string(shift) },
        sub { $generator->map_close },
        sub { $generator->array_open },
        sub { $generator->array_close },
    ]
);
my $json
    = '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}';
$parser->parse($json);
$parser->parse_complete();
print $generator->get_buf . "\n";

=head1 NAME

json_reformat.pl - Reformat and reindent JSON

=head1 DESCRIPTION

This example program uses both the parsing and generating parts of
L<JSON::YAJL> to reformat and reindent JSON.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<JSON::YAJL>
