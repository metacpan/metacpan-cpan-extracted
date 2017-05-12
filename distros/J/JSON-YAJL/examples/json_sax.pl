#!perl
use strict;
use warnings;
use JSON::YAJL;
use XML::LibXML::SAX::Builder;

my $builder = XML::LibXML::SAX::Builder->new();
$builder->start_document;
$builder->start_element( { Name => 'json' } );

my $filename = shift || die 'Please pass a JSON filename to reformat';

my $text;
my $parser = JSON::YAJL::Parser->new(
    0, 0,
    [   sub {
            $builder->start_element( { Name => 'null' } );
            $builder->end_element( { Name => 'null' } );
        },
        sub {
            $builder->start_element( { Name => 'bool' } );
            $builder->characters( { Data => shift } );
            $builder->end_element( { Name => 'bool' } );
        },
        undef,
        undef,
        sub {
            $builder->start_element( { Name => 'number' } );
            $builder->characters( { Data => shift } );
            $builder->end_element( { Name => 'number' } );
        },
        sub {
            $builder->start_element( { Name => 'string' } );
            $builder->characters( { Data => shift } );
            $builder->end_element( { Name => 'string' } );
        },
        sub {
            $builder->start_element( { Name => 'map_open' } );
        },
        sub {
            $builder->start_element( { Name => 'key' } );
            $builder->characters( { Data => shift } );
            $builder->end_element( { Name => 'key' } );
        },
        sub {
            $builder->end_element( { Name => 'map_close' } );
        },
        sub {
            $builder->start_element( { Name => 'array_open' } );
        },
        sub {
            $builder->end_element( { Name => 'array_close' } );
        },
    ]
);
my $json
    = '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}';
$parser->parse($json);
$parser->parse_complete();

$builder->end_element( { Name => 'json' } );
$builder->end_document;
print $builder->result->toString . "\n";

=head1 NAME

json_sax.pl - Reformat JSON as XML via SAX

=head1 DESCRIPTION

This example program uses the parsing parts of L<JSON::YAJL> and the XML
generation parts of L<XML::LibXML::SAX::Builder> to reformat JSON as XML.
This is an example of how similar the APIs are and this is not recommended
for serious use.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<JSON::YAJL>
