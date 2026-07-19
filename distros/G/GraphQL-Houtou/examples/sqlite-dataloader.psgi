#!/usr/bin/env plackup
# A GraphQL over HTTP endpoint backed by SQLite, batching the classic N+1
# (posts -> author, posts -> comments -> author) into one SQL query per
# loader per level with the bundled DataLoader. Dependencies (DBI,
# DBD::SQLite, Plack) install from the cpanfile in this directory:
#
#   cd examples && carton install
#   carton exec -- plackup sqlite-dataloader.psgi
#   # (from a repo checkout, add the built lib: carton exec -- \
#   #    plackup -I../blib/lib -I../blib/arch sqlite-dataloader.psgi)
#   curl localhost:5000 -H 'Content-Type: application/json' \
#     -d '{"query":"{ posts { title author { name } comments { body author { name } } } }"}'
#
# Open http://localhost:5000/ in a browser for GraphiQL.
#
# The wiring shows the two shapes every real schema ends up with:
#   - one loader shared across types: Post.author and Comment.author both
#     resolve through $users, so a user fetched for a post is never
#     re-fetched for a comment (the per-request cache dedupes globally)
#   - several loaders on one type: Post uses $users for author and
#     $comments_by_post for comments
use strict;
use warnings;
use DBI;

use GraphQL::Houtou::PSGI;
use GraphQL::Houtou::DataLoader;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::List;
use GraphQL::Houtou::Type::Scalar qw($String $ID);

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
$dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT, author_id INTEGER)');
$dbh->do('CREATE TABLE comments (id INTEGER PRIMARY KEY, post_id INTEGER, author_id INTEGER, body TEXT)');
$dbh->do(q{INSERT INTO users VALUES (1, 'alice'), (2, 'bob'), (3, 'carol')});
$dbh->do(q{INSERT INTO posts VALUES (1, 'first', 1), (2, 'second', 2), (3, 'third', 1)});
$dbh->do(q{INSERT INTO comments VALUES
  (1, 1, 2, 'nice'), (2, 1, 3, '+1'), (3, 2, 1, 'thanks'), (4, 3, 3, 'agreed')});

# One SELECT ... WHERE id IN (...) per request level, regardless of how many
# author fields the query touches - across posts and comments alike.
sub batch_users_by_id {
  my ($ids) = @_;
  my $in = join ',', ('?') x @$ids;
  my %row = map { ($_->{id} => $_) } @{ $dbh->selectall_arrayref(
    "SELECT id, name FROM users WHERE id IN ($in)", { Slice => {} }, @$ids,
  ) };
  return [ map { $row{$_} } @$ids ];
}

# A grouping loader: keys are post ids, values are arrayrefs of comment
# rows. One SELECT covers every post in the request.
sub batch_comments_by_post_id {
  my ($post_ids) = @_;
  my $in = join ',', ('?') x @$post_ids;
  my %rows;
  push @{ $rows{ $_->{post_id} } }, $_ for @{ $dbh->selectall_arrayref(
    "SELECT id, post_id, author_id, body FROM comments WHERE post_id IN ($in) ORDER BY id",
    { Slice => {} }, @$post_ids,
  ) };
  return [ map { $rows{$_} || [] } @$post_ids ];
}

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  fields => {
    id => { type => $ID },
    name => { type => $String },
  },
);

my $Comment = GraphQL::Houtou::Type::Object->new(
  name => 'Comment',
  fields => {
    id => { type => $ID },
    body => { type => $String },
    author => {
      type => $User,
      resolve => sub {
        my ($comment, undef, $context) = @_;
        return $context->{users}->load($comment->{author_id});
      },
    },
  },
);

my $Post = GraphQL::Houtou::Type::Object->new(
  name => 'Post',
  fields => {
    id => { type => $ID },
    title => { type => $String },
    author => {
      type => $User,
      resolve => sub {
        my ($post, undef, $context) = @_;
        return $context->{users}->load($post->{author_id});
      },
    },
    comments => {
      type => GraphQL::Houtou::Type::List->new(of => $Comment),
      resolve => sub {
        my ($post, undef, $context) = @_;
        return $context->{comments_by_post}->load($post->{id});
      },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      posts => {
        type => GraphQL::Houtou::Type::List->new(of => $Post),
        resolve => sub {
          $dbh->selectall_arrayref(
            'SELECT id, title, author_id FROM posts ORDER BY id', { Slice => {} });
        },
      },
    },
  ),
  types => [ $User, $Comment, $Post ],
);

GraphQL::Houtou::PSGI->new(
  schema => $schema,
  graphiql => 1,
  context => sub {
    # Loaders are per-request: the cache lives exactly as long as the request.
    my $users = GraphQL::Houtou::DataLoader->new(batch => \&batch_users_by_id);
    my $comments_by_post =
      GraphQL::Houtou::DataLoader->new(batch => \&batch_comments_by_post_id);
    return (
      { users => $users, comments_by_post => $comments_by_post },
      GraphQL::Houtou::DataLoader->on_stall_for($users, $comments_by_post),
    );
  },
)->to_app;
