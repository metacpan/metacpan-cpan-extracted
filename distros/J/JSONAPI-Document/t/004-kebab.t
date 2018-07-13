#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;
use JSONAPI::Document::Builder;

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api', kebab_case_attrs => 1 });

my $post = $t->schema->resultset('Post')->find(1);
is_deeply(
    $t->resource_document($post, { with_attributes => 1, includes => ['author'] }),
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
    $t->resource_document($author, { includes => ['email_templates'] }),
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
                    related => 'http://example.com/api/authors/1/relationships/email-templates',
                    self    => 'http://example.com/api/authors/1/email-templates',
                },
                data => [{
                        id   => 1,
                        type => 'email-templates',
                    }] } }
    },
    'author document case is kebab\'d along with its relationships'
);

my $builder = JSONAPI::Document::Builder->new(
    chi              => $t->chi,
    kebab_case_attrs => 1,
    row              => $t->schema->resultset('Post')->find(1),
    segmenter        => $t->segmenter,
);

is_deeply(
    { $builder->kebab_case(__foo__ => 123, bar => 'baz') },
    { __foo__ => 123, bar => 'baz' },
    'kebab case keeps properties starting with an underscore'
);

done_testing;
