use strict;
use warnings;

use Test::More;

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS not available';
}

use GraphQL::Houtou qw(execute build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $Int $ID);
use GraphQL::Houtou::DataLoader;

# ---------------------------------------------------------------------------
# A small "database": posts belong to users, users have teams.
# ---------------------------------------------------------------------------
my %USERS = map { $_->{id} => $_ } (
  { id => '1', name => 'alice', team_id => 't1' },
  { id => '2', name => 'bob',   team_id => 't1' },
  { id => '3', name => 'carol', team_id => 't2' },
);
my %TEAMS = (
  t1 => { id => 't1', name => 'core' },
  t2 => { id => 't2', name => 'infra' },
);
my @POSTS = (
  { id => 'p1', title => 'one',   author_id => '1' },
  { id => 'p2', title => 'two',   author_id => '2' },
  { id => 'p3', title => 'three', author_id => '1' },
  { id => 'p4', title => 'four',  author_id => '3' },
);

my @user_batches;
my @team_batches;

sub make_loaders {
  @user_batches = ();
  @team_batches = ();
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    push @user_batches, [ @$ids ];
    return [ map { $USERS{$_} } @$ids ];
  });
  my $teams = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    push @team_batches, [ @$ids ];
    return [ map { $TEAMS{$_} } @$ids ];
  });
  return ($users, $teams);
}

my $Team = GraphQL::Houtou::Type::Object->new(
  name => 'Team',
  fields => {
    id => { type => $ID },
    name => { type => $String },
  },
);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  fields => {
    id => { type => $ID },
    name => { type => $String },
    team => {
      type => $Team,
      resolve => sub {
        my ($user, undef, $context) = @_;
        return $context->{teams}->load($user->{team_id});
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
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      posts => {
        type => $Post->non_null->list,
        resolve => sub { [ @POSTS ] },
      },
      post => {
        type => $Post,
        args => { id => { type => $ID } },
        resolve => sub {
          my (undef, $args) = @_;
          my ($post) = grep { $_->{id} eq $args->{id} } @POSTS;
          return $post;
        },
      },
      missing_load => {
        type => $String,
        resolve => sub { Promise::XS::deferred()->promise },
      },
    },
  ),
  types => [ $Post, $User, $Team ],
);

subtest 'N+1 collapses to one batch per level' => sub {
  my ($users, $teams) = make_loaders();
  my $result = execute($schema, '{ posts { title author { name team { name } } } }', undef,
    context => { users => $users, teams => $teams },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $teams),
  );
  ok !exists $result->{errors}, 'no errors';
  is scalar @{ $result->{data}{posts} }, 4, 'all posts';
  is $result->{data}{posts}[0]{author}{name}, 'alice', 'author resolved';
  is $result->{data}{posts}[0]{author}{team}{name}, 'core', 'nested team resolved';

  is scalar @user_batches, 1, 'users fetched in exactly one batch';
  is_deeply [ sort @{ $user_batches[0] } ], [ '1', '2', '3' ],
    'user batch contains each distinct author once';
  is scalar @team_batches, 1, 'teams fetched in exactly one batch';
  is_deeply [ sort @{ $team_batches[0] } ], [ 't1', 't2' ],
    'team batch deduplicated';
};

subtest 'result is returned synchronously with variables' => sub {
  my ($users, $teams) = make_loaders();
  my $result = execute($schema, 'query Q($id: ID) { post(id: $id) { author { name } } }',
    { id => 'p4' },
    context => { users => $users, teams => $teams },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $teams),
  );
  is ref($result), 'HASH', 'plain envelope, not a promise';
  is $result->{data}{post}{author}{name}, 'carol', 'variables + loader work together';
};

subtest 'per-request cache dedupes and prime seeds it' => sub {
  my ($users, $teams) = make_loaders();
  $users->prime('1', { id => '1', name => 'cached-alice', team_id => 't1' });
  my $result = execute($schema, '{ a: post(id: "p1") { author { name } } b: post(id: "p3") { author { name } } }',
    undef,
    context => { users => $users, teams => $teams },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $teams),
  );
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{a}{author}{name}, 'cached-alice', 'primed value used';
  is $result->{data}{b}{author}{name}, 'cached-alice', 'cache dedupes same key';
  is scalar @user_batches, 0, 'no batch needed when everything was primed';
};

subtest 'per-key errors fail only that field' => sub {
  my $flaky = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    return [ map {
      $_ eq 'bad'
        ? GraphQL::Houtou::DataLoader::Error->new("no such user: $_\n")
        : $USERS{1}
    } @$ids ];
  });
  my $s = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'FlakyQuery',
      fields => {
        good => { type => $User, resolve => sub { $_[2]->{flaky}->load('1') } },
        bad => { type => $User, resolve => sub { $_[2]->{flaky}->load('bad') } },
      },
    ),
    types => [ $User, $Team ],
  );
  my $result = execute($s, '{ good { name } bad { name } }', undef,
    context => { flaky => $flaky },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($flaky),
  );
  is $result->{data}{good}{name}, 'alice', 'good key resolved';
  is $result->{data}{bad}, undef, 'bad key nulled';
  like $result->{errors}[0]{message}, qr/no such user: bad/, 'per-key error surfaced';
};

subtest 'batch function die fails the whole batch' => sub {
  my $boom = GraphQL::Houtou::DataLoader->new(batch => sub { die "db down\n" });
  my $s = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'BoomQuery',
      fields => {
        u => { type => $User, resolve => sub { $_[2]->{boom}->load('1') } },
      },
    ),
    types => [ $User, $Team ],
  );
  my $result = execute($s, '{ u { name } }', undef,
    context => { boom => $boom },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($boom),
  );
  like $result->{errors}[0]{message}, qr/db down/, 'batch failure becomes a field error';
};

subtest 'deadlock is detected instead of hanging' => sub {
  my ($users, $teams) = make_loaders();
  eval {
    execute($schema, '{ missing_load }', undef,
      context => { users => $users, teams => $teams },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $teams),
    );
  };
  like $@, qr/stalled.*no progress/s, 'unresolvable promise reports a deadlock';
};

subtest 'max_batch_size chunks large batches' => sub {
  my @sizes;
  my $chunked = GraphQL::Houtou::DataLoader->new(
    max_batch_size => 2,
    batch => sub { my ($ids) = @_; push @sizes, scalar @$ids; return [ map { $USERS{1} } @$ids ] },
  );
  my $promise = $chunked->load_many([qw(a b c d e)]);
  is $chunked->dispatch, 5, 'dispatch reports all keys';
  is_deeply \@sizes, [2, 2, 1], 'batches chunked at max size';
};

subtest 'load_many follows dataloader-js loadMany semantics' => sub {
  my ($users) = make_loaders();
  my $got;
  $users->load_many([qw(1 3)])->then(sub { $got = $_[0] });
  $users->dispatch;
  is ref $got, 'ARRAY', 'resolves with a single arrayref';
  is_deeply [ map { $_->{name} } @$got ], [qw(alice carol)], 'values in key order';
  is_deeply \@user_batches, [ [qw(1 3)] ], 'both keys queued in one batch';

  my $empty;
  $users->load_many([])->then(sub { $empty = $_[0] });
  is_deeply $empty, [], 'empty arrayref resolves immediately';
};

subtest 'load_many per-key failures land in the result array' => sub {
  require Scalar::Util;
  my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    return [ map {
      $_ eq 'bad' ? GraphQL::Houtou::DataLoader::Error->new("no such key: $_") : uc $_
    } @$ids ];
  });
  my $got;
  $loader->load_many([qw(a bad b)])->then(sub { $got = $_[0] });
  $loader->dispatch;
  is $got->[0], 'A', 'value before the failure';
  ok Scalar::Util::blessed($got->[1])
    && $got->[1]->isa('GraphQL::Houtou::DataLoader::Error'),
    'failed slot holds an Error object';
  like $got->[1]->message, qr/no such key: bad/, 'error carries the reason';
  is $got->[2], 'B', 'value after the failure';
};

subtest 'load_many list form is deprecated but keeps working' => sub {
  my ($users) = make_loaders();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my @promises = $users->load_many(qw(1 2));
  is scalar @promises, 2, 'list call still returns one promise per key';
  like $warnings[0], qr/deprecated/, 'list call warns in the deprecated category';
  my @names;
  $_->then(sub { push @names, $_[0]{name} }) for @promises;
  $users->dispatch;
  is_deeply \@names, [qw(alice bob)], 'promises still settle per key';
};

subtest 'resolver returning a load_many promise completes the list' => sub {
  my ($users, $teams) = make_loaders();
  my $s = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'ManyQuery',
      fields => {
        authors => {
          type => $User->list,
          resolve => sub { $_[2]->{users}->load_many([qw(1 3)]) },
        },
      },
    ),
    types => [ $User, $Team ],
  );
  my $result = execute($s, '{ authors { name } }', undef,
    context => { users => $users, teams => $teams },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $teams),
  );
  is_deeply $result->{data}{authors},
    [ { name => 'alice' }, { name => 'carol' } ],
    'promise-of-array from load_many completes the list field';
  is scalar @user_batches, 1, 'single batch for the whole list';
};

subtest 'one loader shared across types, several loaders per type' => sub {
  # The realistic wiring: Blog.author and Entry.author share the users
  # loader (cross-type dedup through the per-request cache), while Blog
  # also uses a second loader for latestEntry. Loaders feed each other
  # within one stall: settling entries queues Entry.author loads.
  my %users_db = (
    u1 => { id => 'u1', name => 'alice' },
    u2 => { id => 'u2', name => 'bob' },
    u3 => { id => 'u3', name => 'carol' },
  );
  my %entries_db = (
    e1 => { id => 'e1', title => 'entry-one', author_id => 'u3' },
    e2 => { id => 'e2', title => 'entry-two', author_id => 'u1' },
  );
  my @blogs = (
    { id => 'b1', title => 'blog-one', author_id => 'u1', latest_entry_id => 'e1' },
    { id => 'b2', title => 'blog-two', author_id => 'u2', latest_entry_id => 'e2' },
  );

  my (@users_batched, @entries_batched);
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @users_batched, [ @{ $_[0] } ];
    return [ map { $users_db{$_} } @{ $_[0] } ];
  });
  my $entries = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @entries_batched, [ @{ $_[0] } ];
    return [ map { $entries_db{$_} } @{ $_[0] } ];
  });

  my $BUser = GraphQL::Houtou::Type::Object->new(
    name => 'BUser', fields => { id => { type => $ID }, name => { type => $String } });
  my $Entry = GraphQL::Houtou::Type::Object->new(
    name => 'Entry',
    fields => {
      title => { type => $String },
      author => { type => $BUser, resolve => sub { $_[2]->{users}->load($_[0]{author_id}) } },
    });
  my $Blog = GraphQL::Houtou::Type::Object->new(
    name => 'Blog',
    fields => {
      title => { type => $String },
      author => { type => $BUser, resolve => sub { $_[2]->{users}->load($_[0]{author_id}) } },
      latestEntry => { type => $Entry, resolve => sub { $_[2]->{entries}->load($_[0]{latest_entry_id}) } },
    });
  my $blog_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'BlogQuery',
      fields => { blogs => { type => $Blog->non_null->list, resolve => sub { [ @blogs ] } } },
    ),
    types => [ $BUser, $Entry, $Blog ],
  );

  my $result = execute($blog_schema,
    '{ blogs { title author { name } latestEntry { title author { name } } } }',
    undef,
    context => { users => $users, entries => $entries },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $entries),
  );

  ok !exists $result->{errors}, 'no errors';
  is_deeply $result->{data}{blogs}, [
    { title => 'blog-one', author => { name => 'alice' },
      latestEntry => { title => 'entry-one', author => { name => 'carol' } } },
    { title => 'blog-two', author => { name => 'bob' },
      latestEntry => { title => 'entry-two', author => { name => 'alice' } } },
  ], 'both loaders resolve across both types';

  is_deeply \@entries_batched, [ [qw(e1 e2)] ], 'entries batched once';
  is scalar @users_batched, 2, 'users batched once per dependency level';
  is_deeply $users_batched[0], [qw(u1 u2)], 'blog authors collapse into one batch';
  is_deeply $users_batched[1], [qw(u3)],
    'entry authors batch within the same stall; u1 deduped across types by the cache';
};

subtest 'late-resolving list whose items queue more loads (grouping loader)' => sub {
  # Post.comments loads an arrayref of rows per post id (grouping loader);
  # the list promise resolves at the flush, and each comment's child block
  # then queues Comment.author on the shared users loader. The completed
  # list arrives as a list-pending handle on the scheduler's resolved-value
  # path - treating it as a promise used to break the whole response.
  my %users_db = (
    1 => { id => 1, name => 'alice' }, 2 => { id => 2, name => 'bob' },
    3 => { id => 3, name => 'carol' },
  );
  my %comments_db = (
    1 => [ { post_id => 1, author_id => 2, body => 'nice' },
           { post_id => 1, author_id => 3, body => '+1' } ],
    2 => [ { post_id => 2, author_id => 1, body => 'thanks' } ],
  );
  my @posts = (
    { id => 1, title => 'first', author_id => 1 },
    { id => 2, title => 'second', author_id => 2 },
  );

  my (@users_batched, @comments_batched);
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @users_batched, [ @{ $_[0] } ];
    return [ map { $users_db{$_} } @{ $_[0] } ];
  });
  my $comments = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @comments_batched, [ @{ $_[0] } ];
    return [ map { $comments_db{$_} || [] } @{ $_[0] } ];
  });

  my $CUser = GraphQL::Houtou::Type::Object->new(
    name => 'CUser', fields => { name => { type => $String } });
  my $Comment = GraphQL::Houtou::Type::Object->new(
    name => 'Comment',
    fields => {
      body => { type => $String },
      author => { type => $CUser, resolve => sub { $_[2]->{users}->load($_[0]{author_id}) } },
    });
  require GraphQL::Houtou::Type::List;
  my $CPost = GraphQL::Houtou::Type::Object->new(
    name => 'CPost',
    fields => {
      title => { type => $String },
      author => { type => $CUser, resolve => sub { $_[2]->{users}->load($_[0]{author_id}) } },
      comments => {
        type => GraphQL::Houtou::Type::List->new(of => $Comment),
        resolve => sub { $_[2]->{comments_by_post}->load($_[0]{id}) },
      },
    });
  my $s = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'CommentsQuery',
      fields => { posts => { type => $CPost->non_null->list, resolve => sub { [ @posts ] } } },
    ),
    types => [ $CUser, $Comment, $CPost ],
  );

  my $result = execute($s,
    '{ posts { title author { name } comments { body author { name } } } }',
    undef,
    context => { users => $users, comments_by_post => $comments },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $comments),
  );

  ok !exists $result->{errors}, 'no errors';
  is_deeply $result->{data}{posts}, [
    { title => 'first', author => { name => 'alice' },
      comments => [
        { body => 'nice', author => { name => 'bob' } },
        { body => '+1', author => { name => 'carol' } },
      ] },
    { title => 'second', author => { name => 'bob' },
      comments => [ { body => 'thanks', author => { name => 'alice' } } ] },
  ], 'nested loads under a late-resolving list complete';
  is_deeply \@comments_batched, [ [ 1, 2 ] ], 'comments grouped into one batch';
  is_deeply \@users_batched, [ [ 1, 2 ], [ 3 ] ],
    'comment authors batch in the next level, deduped against post authors';
};

subtest 'runtime execute_document accepts on_stall directly' => sub {
  my ($users, $teams) = make_loaders();
  my $runtime = build_native_runtime($schema);
  my $result = $runtime->execute_document('{ posts { author { name } } }',
    context => { users => $users, teams => $teams },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $teams),
  );
  ok !exists $result->{errors}, 'no errors';
  is scalar @user_batches, 1, 'single batch through the runtime API';
};

subtest 'list field resolving to an array of promises (issue #33)' => sub {
  require GraphQL::Houtou::Type::List;
  my @rows = map { { name => "row-$_", qty => $_ } } 1..3;
  my $Item = GraphQL::Houtou::Type::Object->new(
    name => 'Row', fields => {
      name => { type => $String },
      qty => { type => $Int },
    });
  my @batches;
  my $list_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        rows => {
          type => GraphQL::Houtou::Type::List->new(of => $Item),
          resolve => sub {
            my (undef, undef, $c) = @_;
            return [ map { $c->{rows}->load($_) } 1..3 ];
          },
        },
        tags => {
          type => GraphQL::Houtou::Type::List->new(of => $String),
          resolve => sub {
            my (undef, undef, $c) = @_;
            return [ map { $c->{tags}->load($_) } qw(x y) ];
          },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($list_schema);

  my $rows_loader = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @batches, [ @{ $_[0] } ];
    return [ map { $rows[$_-1] } @{ $_[0] } ];
  });
  my $tags_loader = GraphQL::Houtou::DataLoader->new(batch => sub {
    return [ map { "tag-$_" } @{ $_[0] } ];
  });
  my $result = $runtime->execute_document('{ rows { name qty } tags }',
    context => { rows => $rows_loader, tags => $tags_loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($rows_loader, $tags_loader),
  );
  is_deeply $result, {
    data => {
      rows => [
        { name => 'row-1', qty => 1 },
        { name => 'row-2', qty => 2 },
        { name => 'row-3', qty => 3 },
      ],
      tags => [ 'tag-x', 'tag-y' ],
    },
  }, 'object and scalar promise items complete after settling';
  is scalar @batches, 1, 'all item keys collapse into one batch';

  # per-key errors inside a list surface in the errors array with the
  # item path, and the failed item becomes null
  my $flaky = GraphQL::Houtou::DataLoader->new(batch => sub {
    return [ map {
      $_ == 2 ? GraphQL::Houtou::DataLoader::Error->new('row 2 missing') : $rows[$_-1]
    } @{ $_[0] } ];
  });
  my $tags2 = GraphQL::Houtou::DataLoader->new(batch => sub {
    [ map { "tag-$_" } @{ $_[0] } ] });
  my $with_error = $runtime->execute_document('{ rows { name qty } }',
    context => { rows => $flaky, tags => $tags2 },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($flaky),
  );
  is $with_error->{data}{rows}[0]{name}, 'row-1', 'items before the failure survive';
  ok !defined $with_error->{data}{rows}[1] || !defined $with_error->{data}{rows}[1]{name},
    'failed item is null';
  is $with_error->{data}{rows}[2]{name}, 'row-3', 'items after the failure survive';
  like $with_error->{errors}[0]{message}, qr/row 2 missing/, 'rejection surfaces in errors';
};

subtest 'preresolved promise next to a loader promise in one object' => sub {
  # Regression: the preresolved field settles synchronously while the
  # frame is being armed, so the scheduler processes the frame once
  # before the loader promise settles. The re-pushed armed entry moves
  # to a new index; its callbacks used to keep the old one, dropping the
  # loader's value and deadlocking the request. The parent resolving via
  # a loader puts the child's finalize inside the drain, which is what
  # defers the early process until the armed entry already exists.
  my $Parent = GraphQL::Houtou::Type::Object->new(
    name => 'Parent',
    fields => {
      fast => {
        type => $String,
        resolve => sub { Promise::XS::resolved('fast-value') },
      },
      slow => {
        type => $String,
        resolve => sub { $_[2]->{users}->load('1')->then(sub { $_[0]->{name} }) },
      },
    },
  );
  my $mixed_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        parent => {
          type => $Parent,
          resolve => sub { $_[2]->{parents}->load('x') },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($mixed_schema);

  for my $selection ('{ parent { fast slow } }', '{ parent { slow fast } }') {
    my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { $USERS{$_} } @{ $_[0] } ];
    });
    my $parents = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { { id => $_ } } @{ $_[0] } ];
    });
    my $result = $runtime->execute_document($selection,
      context => { users => $users, parents => $parents },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $parents),
    );
    is_deeply $result, {
      data => { parent => { fast => 'fast-value', slow => 'alice' } },
    }, "both fields resolve for $selection";
  }
};

done_testing;
