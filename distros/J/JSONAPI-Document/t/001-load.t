#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;

my $t = Test::JSONAPI->new();

ok( $t->schema, 'schema is available' );

subtest 'schema is populated' => sub {
    my $post = $t->schema->resultset('Post')->find(1);
    ok( $post, 'post with id 1' );
    ok( my $author = $post->author, 'post has an author' );
    is( $author->name, 'John Doe', 'author has right data' );
    ok( my $comments = $post->comments, 'post has comments' );
    is( $comments->first()->likes, 2, 'first comment is correct' );

    ok( $author->posts, 'author has posts' );
    is( $author->posts->first->title, 'Intro to JSON API', 'authors first post is correct' );

    ok( $comments->first->post,   'comment has one post' );
    ok( $comments->first->author, 'comment has one author' );
};

done_testing;
