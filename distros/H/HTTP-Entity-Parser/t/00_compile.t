use strict;
use Test::More;

use_ok $_ for qw(
    HTTP::Entity::Parser
    HTTP::Entity::Parser::JSON
    HTTP::Entity::Parser::MultiPart
    HTTP::Entity::Parser::OctetStream
    HTTP::Entity::Parser::UrlEncoded
);

my $parser = HTTP::Entity::Parser->new(buffer_length => 100);
ok($parser);
is($parser->[1],100);

{
    my $env = {
        CONTENT_TYPE => 'multipart/form-data',
    };
    my $parser = HTTP::Entity::Parser->new(buffer_length => 100);
    my ( $params, $uploads) = $parser->parse($env);
    is_deeply($params,[]);
    is_deeply($uploads,[]);
}

{
    my $env = {
        CONTENT_TYPE => 'multipart/form-data',
        'psgi.input' => undef,
    };
    my $parser = HTTP::Entity::Parser->new(buffer_length => 100);
    my ( $params, $uploads) = $parser->parse($env);
    is_deeply($params,[]);
    is_deeply($uploads,[]);
}


done_testing;
