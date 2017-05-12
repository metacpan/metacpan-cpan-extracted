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

done_testing;

