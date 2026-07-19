use strict;
use warnings;
use utf8;

use DBI;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use JSON::MaybeXS;
use Plack::Request;
use Promise::XS;

use GraphQL::Houtou qw(build_native_runtime build_schema);
use GraphQL::Houtou::DataLoader;
use GraphQL::Houtou::PSGI;

{
  package SQLiteBlog::Post;

  sub new { my ($class, $row) = @_; bless { %$row }, $class }
  sub id { $_[0]{id} }
  sub title { $_[0]{title} }
  sub body { $_[0]{body} }
  sub language { $_[0]{language} }
  sub publishedAt { $_[0]{published_at} }
  sub legacyTitle { $_[0]{title} }
  sub author_id { $_[0]{author_id} }
}

my $ROOT = dirname(abs_path(__FILE__));
my $DB_FILE = $ENV{BLOG_DB} || "$ROOT/var/blog.sqlite3";
my $JSON = JSON::MaybeXS->new->utf8->canonical;
my $MAX_BODY = 1024 * 1024;
my $ENABLE_GRAPHIQL = !exists($ENV{BLOG_GRAPHIQL}) || $ENV{BLOG_GRAPHIQL};

sub slurp {
  my ($path) = @_;
  open my $fh, '<:raw', $path or die "Cannot read $path: $!";
  local $/;
  return <$fh>;
}

sub connect_db {
  my ($path) = @_;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
    sqlite_unicode => 1,
  });
  $dbh->do('PRAGMA foreign_keys = ON');
  $dbh->do('PRAGMA journal_mode = WAL');
  $dbh->do('PRAGMA busy_timeout = 5000');
  return $dbh;
}

sub initialize_db {
  my ($dbh) = @_;
  $dbh->do(q{CREATE TABLE IF NOT EXISTS authors (
    id INTEGER PRIMARY KEY, name TEXT NOT NULL
  )});
  $dbh->do(q{CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY, author_id INTEGER NOT NULL REFERENCES authors(id),
    title TEXT NOT NULL, body TEXT NOT NULL,
    language TEXT NOT NULL CHECK(language IN ('EN','JA')),
    published_at TEXT NOT NULL
  )});
  $dbh->do(q{CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY, post_id INTEGER NOT NULL REFERENCES posts(id),
    author_id INTEGER NOT NULL REFERENCES authors(id), body TEXT NOT NULL
  )});
  $dbh->do(q{CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE
  )});
  $dbh->do(q{CREATE TABLE IF NOT EXISTS post_tags (
    post_id INTEGER NOT NULL REFERENCES posts(id),
    tag_id INTEGER NOT NULL REFERENCES tags(id), PRIMARY KEY(post_id, tag_id)
  )});
  $dbh->do('CREATE INDEX IF NOT EXISTS comments_post ON comments(post_id)');
  $dbh->do('CREATE INDEX IF NOT EXISTS posts_author ON posts(author_id)');

  my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM authors');
  return if $authors;
  $dbh->do(q{INSERT INTO authors(id,name) VALUES
    (1,'Alice'),(2,'ボブ'),(3,'Carol / キャロル')});
  my $now = '2026-07-19T00:00:00Z';
  $dbh->do(q{INSERT INTO posts(id,author_id,title,body,language,published_at)
    VALUES (1,1,'Hello, Houtou','A small English post.','EN',?),
           (2,2,'日本語の投稿','SQLite と DataLoader を使った投稿です。','JA',?),
           (3,1,'Avoiding N+1','Relations are loaded in batches.','EN',?)},
    undef, $now, $now, $now);
  $dbh->do(q{INSERT INTO comments(id,post_id,author_id,body) VALUES
    (1,1,2,'Nice post!'),(2,1,3,'読みました。'),(3,2,1,'Thanks / ありがとう')});
  $dbh->do(q{INSERT INTO tags(id,name) VALUES (1,'graphql'),(2,'perl'),(3,'日本語')});
  $dbh->do(q{INSERT INTO post_tags(post_id,tag_id) VALUES
    (1,1),(1,2),(2,1),(2,3),(3,1),(3,2)});
}

my $bootstrap_db = connect_db($DB_FILE);
initialize_db($bootstrap_db);
$bootstrap_db->disconnect;

my ($worker_pid, $worker_dbh);
sub worker_db {
  if (!$worker_dbh || !$worker_dbh->ping || !defined($worker_pid) || $worker_pid != $$) {
    eval { $worker_dbh->disconnect if $worker_dbh };
    $worker_dbh = connect_db($DB_FILE);
    $worker_pid = $$;
  }
  return $worker_dbh;
}

sub placeholders { join ',', ('?') x @{ $_[0] } }
sub posts_from_rows { [ map { SQLiteBlog::Post->new($_) } @{ $_[0] } ] }

my $schema = build_schema(slurp("$ROOT/schema.graphql"), resolvers => {
  Query => {
    feed => sub {
      my (undef, $args, $ctx) = @_;
      my $limit = $args->{limit} || 20;
      $limit = 100 if $limit > 100;
      return posts_from_rows($ctx->{db}->selectall_arrayref(q{
        SELECT id,author_id,title,body,language,published_at
        FROM posts ORDER BY id DESC LIMIT ?}, { Slice => {} }, $limit));
    },
    post => sub {
      my (undef, $args, $ctx) = @_;
      my $ref = $args->{ref};
      my ($where, $value) = exists $ref->{id}
        ? ('id = ?', $ref->{id}) : ('title = ?', $ref->{title});
      my $row = $ctx->{db}->selectrow_hashref(qq{
        SELECT id,author_id,title,body,language,published_at
        FROM posts WHERE $where ORDER BY id DESC LIMIT 1}, undef, $value);
      return $row ? SQLiteBlog::Post->new($row) : undef;
    },
    node => sub {
      my (undef, $args, $ctx) = @_;
      my $ref = $args->{ref};
      my ($where, $value) = exists $ref->{id}
        ? ('id = ?', $ref->{id}) : ('title = ?', $ref->{title});
      my $row = $ctx->{db}->selectrow_hashref(qq{
        SELECT id,author_id,title,body,language,published_at
        FROM posts WHERE $where ORDER BY id DESC LIMIT 1}, undef, $value);
      return $row ? SQLiteBlog::Post->new($row) : undef;
    },
    search => sub {
      my (undef, $args, $ctx) = @_;
      my $like = '%' . $args->{text} . '%';
      my $posts = posts_from_rows($ctx->{db}->selectall_arrayref(q{
        SELECT id,author_id,title,body,language,published_at
        FROM posts WHERE title LIKE ? OR body LIKE ? ORDER BY id DESC LIMIT 20
      }, { Slice => {} }, $like, $like));
      my $authors = $ctx->{db}->selectall_arrayref(q{
        SELECT id,name,'Author' AS _type FROM authors WHERE name LIKE ? LIMIT 20
      }, { Slice => {} }, $like);
      return [ @$posts, @$authors ];
    },
    stats => sub {
      my (undef, undef, $ctx) = @_;
      return {
        posts => 0 + ($ctx->{db}->selectrow_array('SELECT COUNT(*) FROM posts'))[0],
        authors => 0 + ($ctx->{db}->selectrow_array('SELECT COUNT(*) FROM authors'))[0],
        comments => 0 + ($ctx->{db}->selectrow_array('SELECT COUNT(*) FROM comments'))[0],
      };
    },
    health => sub { 'ok' },
  },
  Mutation => {
    createPost => sub {
      my (undef, $args, $ctx) = @_;
      my $in = $args->{input};
      my $dbh = $ctx->{db};
      my $post;
      $dbh->begin_work;
      eval {
        $dbh->do(q{INSERT INTO posts(author_id,title,body,language,published_at)
          VALUES (?,?,?,?,datetime('now'))}, undef,
          @$in{qw(authorId title body language)});
        my $id = $dbh->sqlite_last_insert_rowid;
        for my $tag (@{ $in->{tags} }) {
          $dbh->do('INSERT OR IGNORE INTO tags(name) VALUES (?)', undef, $tag);
          my ($tag_id) = $dbh->selectrow_array('SELECT id FROM tags WHERE name=?', undef, $tag);
          $dbh->do('INSERT INTO post_tags(post_id,tag_id) VALUES (?,?)', undef, $id, $tag_id);
        }
        my $row = $dbh->selectrow_hashref(q{
          SELECT id,author_id,title,body,language,published_at FROM posts WHERE id=?
        }, undef, $id);
        $post = SQLiteBlog::Post->new($row);
        $dbh->commit;
        1;
      } or do { my $error = $@; eval { $dbh->rollback }; die $error };
      return $post;
    },
    addComment => sub {
      my (undef, $args, $ctx) = @_;
      my $in = $args->{input};
      $ctx->{db}->do('INSERT INTO comments(post_id,author_id,body) VALUES (?,?,?)',
        undef, @$in{qw(postId authorId body)});
      my $id = $ctx->{db}->sqlite_last_insert_rowid;
      return { id => $id, body => $in->{body}, author_id => $in->{authorId} };
    },
  },
  Post => {
    author => sub { $_[2]{loaders}{authors}->load($_[0]->author_id) },
    tags => sub { $_[2]{loaders}{tags_by_post}->load($_[0]->id) },
    comments => sub { $_[2]{loaders}{comments_by_post}->load($_[0]->id) },
  },
  Author => {
    posts => sub { $_[2]{loaders}{posts_by_author}->load($_[0]{id}) },
  },
  Comment => {
    author => sub { $_[2]{loaders}{authors}->load($_[0]{author_id}) },
  },
  Node => {
    resolve_type => sub { ref($_[0]) eq 'SQLiteBlog::Post' ? 'Post' : ($_[0]{_type} || 'Author') },
  },
  SearchResult => {
    resolve_type => sub { ref($_[0]) eq 'SQLiteBlog::Post' ? 'Post' : 'Author' },
  },
});

my $runtime = build_native_runtime($schema,
  async => 1, program_cache_max => 100, max_depth => 15,
  max_nodes => 2_000, max_cost => 20_000, default_list_size => 20,
  allow_introspection => 0,
);
my $operation_source = slurp("$ROOT/operations.graphql");
my @operation_ids = qw(Feed PostById NodeById Search Stats CreatePost AddComment);
my %program = map {
  $_ => $runtime->compile_program($operation_source, operation_name => $_)
} @operation_ids;

sub request_context {
  my $dbh = worker_db();
  my %batch_count;
  my %loaders;
  $loaders{authors} = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_; $batch_count{authors}++;
    my %row = map { $_->{id} => $_ } @{ $dbh->selectall_arrayref(
      'SELECT id,name FROM authors WHERE id IN (' . placeholders($ids) . ')',
      { Slice => {} }, @$ids) };
    return [ map { $row{$_} } @$ids ];
  });
  $loaders{tags_by_post} = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_; $batch_count{tags}++;
    my %rows;
    push @{ $rows{$_->{post_id}} }, { id => $_->{id}, name => $_->{name}, _type => 'Tag' }
      for @{ $dbh->selectall_arrayref(
        'SELECT pt.post_id,t.id,t.name FROM post_tags pt JOIN tags t ON t.id=pt.tag_id '
        . 'WHERE pt.post_id IN (' . placeholders($ids) . ') ORDER BY t.id',
        { Slice => {} }, @$ids) };
    return [ map { $rows{$_} || [] } @$ids ];
  });
  $loaders{comments_by_post} = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_; $batch_count{comments}++;
    my %rows;
    push @{ $rows{$_->{post_id}} }, $_ for @{ $dbh->selectall_arrayref(
      'SELECT id,post_id,author_id,body FROM comments WHERE post_id IN ('
      . placeholders($ids) . ') ORDER BY id', { Slice => {} }, @$ids) };
    return [ map { $rows{$_} || [] } @$ids ];
  });
  $loaders{posts_by_author} = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_; $batch_count{posts}++;
    my %rows;
    push @{ $rows{$_->{author_id}} }, SQLiteBlog::Post->new($_)
      for @{ $dbh->selectall_arrayref(
        'SELECT id,author_id,title,body,language,published_at FROM posts '
        . 'WHERE author_id IN (' . placeholders($ids) . ') ORDER BY id DESC',
        { Slice => {} }, @$ids) };
    return [ map { $rows{$_} || [] } @$ids ];
  });
  my $context = { db => $dbh, loaders => \%loaders };
  my $on_stall = GraphQL::Houtou::DataLoader->on_stall_for(values %loaders);
  return ($context, $on_stall, \%batch_count);
}

my $graphiql_app = GraphQL::Houtou::PSGI->new(
  runtime => $runtime,
  graphiql => 1,
  graphiql_path => '/graphiql/graphql',
  allow_introspection => 1,
  max_body_size => $MAX_BODY,
  context => sub {
    my ($context, $on_stall) = request_context();
    return ($context, $on_stall);
  },
)->to_app;

my $index_html = slurp("$ROOT/public/index.html");

sub json_response {
  my ($status, $payload, @headers) = @_;
  return [ $status, [ 'Content-Type' => 'application/json; charset=utf-8', @headers ],
    [ ref($payload) ? $JSON->encode($payload) : $payload ] ];
}

sub read_request_body {
  my ($env) = @_;
  my $declared = $env->{CONTENT_LENGTH};
  return if defined($declared) && $declared =~ /\A\d+\z/ && $declared > $MAX_BODY;
  my $input = $env->{'psgi.input'};
  my $body = '';
  while (length($body) <= $MAX_BODY) {
    my $read = $input->read(my $chunk, 64 * 1024);
    die "Cannot read request body: $!" if !defined $read;
    last if !$read;
    $body .= $chunk;
  }
  return if length($body) > $MAX_BODY;
  return $body;
}

my $app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  if ($ENABLE_GRAPHIQL && $req->path_info eq '/graphiql') {
    return $graphiql_app->({ %$env, PATH_INFO => '/', HTTP_ACCEPT => 'text/html' });
  }
  if ($ENABLE_GRAPHIQL && $req->path_info eq '/graphiql/graphql') {
    return $graphiql_app->({ %$env, PATH_INFO => '/' });
  }
  if ($req->method eq 'GET' && $req->path_info eq '/') {
    return [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ $index_html ] ];
  }
  if ($req->method eq 'GET' && $req->path_info eq '/operations') {
    return json_response(200, { operations => \@operation_ids });
  }
  return json_response(404, { error => 'Not found' })
    if $req->path_info ne '/graphql';
  return json_response(405, { error => 'POST required' }, Allow => 'POST')
    if $req->method ne 'POST';
  my $body = eval { read_request_body($env) };
  return json_response(500, { error => 'Cannot read request body' }) if $@;
  return json_response(413, { error => 'Request body too large' }) if !defined $body;

  my $input = eval { $JSON->decode($body) };
  return json_response(400, { error => 'Invalid JSON' }) if !$input || ref($input) ne 'HASH';
  my $id = $input->{id} || '';
  return json_response(404, { error => 'Unknown persisted operation' }) if !$program{$id};
  return json_response(400, { error => 'variables must be an object' })
    if exists($input->{variables}) && ref($input->{variables}) ne 'HASH';

  my ($context, $on_stall, $batches) = request_context();
  my $json = eval {
    $runtime->execute_program_to_json($program{$id},
      variables => ($input->{variables} || {}), context => $context,
      on_stall => $on_stall);
  };
  if (my $error = $@) {
    warn "persisted operation $id failed: $error";
    return json_response(500, { errors => [ { message => 'Internal server error' } ] });
  }
  my $timing = join ', ', map { "loader-$_;desc=\"batches\";dur=$batches->{$_}" }
    sort keys %$batches;
  return json_response(200, $json, ($timing ? ('Server-Timing' => $timing) : ()));
};

no warnings 'void';
$app;
