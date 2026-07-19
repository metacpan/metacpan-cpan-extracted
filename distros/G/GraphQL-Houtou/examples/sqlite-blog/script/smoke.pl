#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use HTTP::Request::Common qw(GET POST);
use JSON::MaybeXS;
use Plack::Test;
use Test::More;

my $root = "$FindBin::Bin/..";
my $json = JSON::MaybeXS->new->utf8->canonical;
my $app = do "$root/app.psgi" or die $@ || $!;
my $test = Plack::Test->create($app);

sub operation {
  my ($id, $variables) = @_;
  my $res = $test->request(POST '/graphql',
    'Content-Type' => 'application/json',
    Content => $json->encode({ id => $id, variables => $variables || {} }));
  is $res->code, 200, "$id returns HTTP 200" or diag $res->content;
  my $payload = $json->decode($res->content);
  ok !$payload->{errors}, "$id returns no GraphQL errors" or diag $res->content;
  return $payload->{data};
}

is $test->request(GET '/')->code, 200, 'frontend is served';
my $graphiql = $test->request(GET '/graphiql', Accept => 'text/html');
is $graphiql->code, 200, 'GraphiQL is served';
like $graphiql->content, qr/createGraphiQLFetcher/, 'GraphiQL points at its dynamic endpoint';
my $dynamic = $test->request(POST '/graphiql/graphql',
  'Content-Type' => 'application/json',
  Content => $json->encode({ query => '{ __schema { queryType { name } } health }' }));
is $dynamic->code, 200, 'GraphiQL dynamic endpoint accepts GraphQL source';
is $json->decode($dynamic->content)->{data}{__schema}{queryType}{name}, 'Query',
  'GraphiQL endpoint enables introspection';
my $feed = operation('Feed', { limit => 3 });
ok @{ $feed->{feed} } >= 2, 'English and Japanese seed posts are returned';
ok $feed->{feed}[0]{author}{name}, 'author DataLoader resolved';
ok ref($feed->{feed}[0]{tags}) eq 'ARRAY', 'tag DataLoader resolved';
ok ref($feed->{feed}[0]{comments}) eq 'ARRAY', 'comment DataLoader resolved';
my $stats = operation('Stats');
is $stats->{health}, 'ok', 'direct scalar resolver works';
ok $stats->{stats}{posts} >= 3, 'hash-backed stats resolver works';

my $title = '動作確認 ' . $$;
my $created = operation('CreatePost', { input => {
  authorId => '2', title => $title,
  body => 'English and 日本語 are both preserved.', language => 'JA',
  tags => [ 'graphql', 'smoke' ],
} });
is $created->{createPost}{title}, $title, 'UTF-8 mutation result is preserved';

my $post = operation('PostById', { ref => { id => $created->{createPost}{id} } });
is $post->{post}{title}, $title, '@oneOf id lookup finds the created post';
my $node = operation('NodeById', { ref => { title => $title } });
is $node->{node}{__typename}, 'Post', 'interface dispatch returns Post';
my $comment = operation('AddComment', { input => {
  postId => $created->{createPost}{id}, authorId => '3', body => '確認しました',
} });
is $comment->{addComment}{author}{name}, 'Carol / キャロル',
  'second mutation resolves its relation through DataLoader';
my $search = operation('Search', { text => $title });
is $search->{search}[0]{__typename}, 'Post', 'union dispatch returns Post';

my $unknown = $test->request(POST '/graphql',
  'Content-Type' => 'application/json',
  Content => $json->encode({ id => 'RawQueryIsNotAllowed', variables => {} }));
is $unknown->code, 404, 'unknown persisted operation is rejected';

done_testing;
