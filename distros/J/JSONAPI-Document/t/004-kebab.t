#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api', kebab_case_attrs => 1 });

my $post = $t->schema->resultset('Post')->find(1);
is_deeply(
    $t->resource_document($post, { with_relationships => 1, with_attributes => 1, includes => ['author'] }),
    {
        id         => 1,
        type       => 'posts',
        attributes => {
            'author-id'   => 1,
            'description' => 'This is a Perl transformer for the JSON API specification',
            'title'       => 'Intro to JSON API',
        },
        relationships => {
            author => {
                data => {
                    id         => 1,
                    type       => 'authors',
                    attributes => {
                        name => 'John Doe',
                        age  => 28
                    } } } }
    },
    'document case is kebab\'d'
);

my $author = $t->schema->resultset('Author')->find(1);
is_deeply(
    $t->resource_document($author, { with_relationships => 1, includes => ['email_templates'] }),
    {
        id         => 1,
        type       => 'authors',
        attributes => {
            age  => 28,
            name => 'John Doe',
        },
        relationships => {
            'email-templates' => {
                links => {
                    self    => 'http://example.com/api/authors/1/relationships/email-templates',
                    related => 'http://example.com/api/authors/1/email-templates',
                },
                data => [{
                        id   => 1,
                        type => 'email-templates',
                    }] } }
    },
    'author document case is kebab\'d along with its relationships'
);

done_testing;
