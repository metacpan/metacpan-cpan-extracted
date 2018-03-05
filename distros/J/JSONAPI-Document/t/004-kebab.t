#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;

my $t = Test::JSONAPI->new( { kebab_case_attrs => 1 } );

my $post = $t->schema->resultset('Post')->find(1);

my $document =
  $t->resource_document( $post, { with_relationships => 1, with_attributes => 1, includes => ['author'] } );
is_deeply(
    $document,
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
                    }
                }
            }
        }
    },
    'document case is kebab\'d'
);

done_testing;
