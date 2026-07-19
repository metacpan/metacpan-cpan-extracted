use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;

BEGIN {
  my $root = File::Spec->catdir($Bin, '..');
  for my $path (
    File::Spec->catdir($root, 'lib'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5', 'darwin-2level'),
  ) {
    unshift @INC, $path if -d $path;
  }
}
use GraphQL::Houtou::Promise::PromiseXS qw(
  maybe_get_promise_xs
);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::Type::Union;

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'RuntimePromiseUser',
  runtime_tag => 'user',
  fields => {
    id => { type => $String->non_null },
    name => { type => $String->non_null },
  },
);

my $SearchResult = GraphQL::Houtou::Type::Union->new(
  name => 'RuntimePromiseSearchResult',
  types => [ $User ],
  tag_resolver => sub { $_[0]{kind} },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'RuntimePromiseQuery',
    fields => {
      later => {
        type => $String->non_null,
        resolve => sub { require Promise::XS; Promise::XS::resolved('world') },
      },
      later_user => {
        type => $User,
        resolve => sub {
          require Promise::XS;
          Promise::XS::resolved({ id => '41', name => 'async:41' });
        },
      },
      later_list => {
        type => $String->non_null->list->non_null,
        resolve => sub {
          require Promise::XS;
          [
            Promise::XS::resolved('alpha'),
            Promise::XS::resolved('beta'),
          ];
        },
      },
      later_search => {
        type => $SearchResult,
        resolve => sub {
          require Promise::XS;
          Promise::XS::resolved({
            kind => 'user',
            id => '42',
            name => 'async:42',
          });
        },
      },
    },
  ),
  types => [ $User, $SearchResult ],
);

subtest 'runtime rejects legacy promise_code' => sub {
  my $ok = eval {
    $schema->execute(
      '{ later }',
      promise_code => {
        resolve => sub { $_[0] },
        reject => sub { $_[0] },
        all => sub { $_[0] },
      },
    );
    1;
  };

  ok !$ok, 'legacy promise_code is rejected';
  like $@, qr/promise_code is no longer supported/i;
};

subtest 'runtime auto-detects Promise::XS values' => sub {
  my $result = $schema->execute(
    '{ later later_user { id name } later_list later_search { ... on RuntimePromiseUser { id name } } }',
  );

  my $resolved = maybe_get_promise_xs($result);

  ok(
    !ref($result) || eval { $result->isa('Promise::XS::Promise') } || ref($result) eq 'HASH',
    'runtime program resolves synchronously or returns Promise::XS promise object',
  );
  is_deeply $resolved, {
    data => {
      later => 'world',
      later_user => {
        id => '41',
        name => 'async:41',
      },
      later_list => [ 'alpha', 'beta' ],
      later_search => {
        id => '42',
        name => 'async:42',
      },
    },
  }, 'runtime program resolves Promise::XS-backed scalar/object/list/abstract fields';
};

done_testing;
