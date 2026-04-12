use Test2::V1 -Pip;

use JSON::Schema::AsType;

subtest basic => sub {
    my $schema = JSON::Schema::AsType->new;

    my $uri = 'http://something.com/foo';
    my $s   = { type => 'boolean' };

    $schema->register_schema( $uri, $s );

    like [ $schema->all_schema_uris ], bag {
        item $uri;
    };

    isa_ok $schema->registered_schema($uri) => 'JSON::Schema::AsType';
};

subtest 'ids' => sub {
    my $schema = JSON::Schema::AsType->new;

    my $uri = 'http://something.com/foo';
    my $s   = {
        type        => 'boolean',
        definitions => {
            bar => {
                '$id' => 'http://somethingelse.com/baz',
                type  => 'string',
            }
        }
    };

    $schema->register_schema( $uri, $s );

    like [ $schema->all_schema_uris ], bag {
        item $uri;
        item 'http://somethingelse.com/baz';
    };
};

done_testing;

