use 5.024;
use strict;
use warnings;

use JSON::PP ();
use Test::More;

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

{
  package Local::DefaultResolver::Inner;
  sub new {
    bless {
      prefix => $_[1],
      req => sub { die "hash key must not replace a same-named method\n" },
    }, $_[0];
  }
  sub req {
    my ($self, $args, $context, $info) = @_;
    return join ':', $self->{prefix}, $args->{suffix}, $context->{request},
      $info->{field_name};
  }

  package Local::DefaultResolver::Root;
  sub new {
    bless {
      hello => sub { die "hash key must not replace a same-named method\n" },
      inner => sub { die "hash key must not replace a same-named method\n" },
    }, $_[0];
  }
  sub hello {
    my ($self, $args, $context, $info) = @_;
    return join ':', $args->{suffix}, $context->{request}, $info->{field_name};
  }
  sub inner {
    return Local::DefaultResolver::Inner->new('method');
  }
  sub explicit { die "default method must not replace an explicit resolver\n" }

  package Local::DefaultResolver::Callable;
  use overload '&{}' => sub {
    my ($self) = @_;
    return sub {
      my ($args, $context, $info) = @_;
      return join ':', $self->{prefix}, $args->{suffix}, $context->{request},
        $info->{field_name};
    };
  }, fallback => 1;
  sub new { bless { prefix => $_[1] }, $_[0] }
}

my $Inner = GraphQL::Houtou::Type::Object->new(
  name => 'DefaultResolverInner',
  fields => {
    req => {
      type => $String,
      args => { suffix => { type => $String } },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'DefaultResolverQuery',
    fields => {
      hello => {
        type => $String,
        args => { suffix => { type => $String } },
      },
      inner => { type => $Inner },
      explicit => { type => $String, resolve => sub { 'explicit' } },
      failure => { type => $String },
      promised => { type => $String },
    },
  ),
  types => [$Inner],
);

my $query = <<'GRAPHQL';
query DefaultResolver($suffix: String) {
  hello(suffix: $suffix)
  inner { req(suffix: $suffix) }
  explicit
}
GRAPHQL

subtest 'hash coderefs receive graphql-perl default resolver arguments' => sub {
  my $root = {
    hello => sub {
      my ($args, $context, $info) = @_;
      return join ':', $args->{suffix}, $context->{request}, $info->{field_name};
    },
    inner => sub {
      return {
        req => sub {
          my ($args, $context, $info) = @_;
          return join ':', 'coderef', $args->{suffix}, $context->{request},
            $info->{field_name};
        },
      };
    },
    explicit => sub { die "default property must not replace an explicit resolver\n" },
  };
  my $runtime = build_native_runtime($schema);
  my $static_query = '{ hello(suffix: "x") inner { req(suffix: "x") } explicit }';
  my $bundle = $runtime->compile_bundle_for_document($static_query);
  my $want = {
    data => {
      hello => 'x:req:hello',
      inner => { req => 'coderef:x:req:req' },
      explicit => 'explicit',
    },
  };
  my %lanes = (
    'async program' => build_native_runtime($schema, async => 1)->execute_document(
      $query, variables => { suffix => 'x' }, root_value => $root,
      context => { request => 'req' },
    ),
    'fast SV program' => $runtime->execute_document(
      $query, variables => { suffix => 'x' }, root_value => $root,
      context => { request => 'req' },
    ),
    'fast JSON program' => JSON::PP::decode_json($runtime->execute_document_to_json(
      $query, variables => { suffix => 'x' }, root_value => $root,
      context => { request => 'req' },
    )),
    'bundle envelope' => $runtime->execute_bundle(
      $bundle, root_value => $root, context => { request => 'req' },
    ),
    'bundle JSON' => JSON::PP::decode_json($runtime->execute_bundle_to_json(
      $bundle, root_value => $root, context => { request => 'req' },
    )),
  );
  for my $lane (sort keys %lanes) {
    is_deeply $lanes{$lane}, $want, "$lane; methods win over hash keys";
  }
};

subtest 'blessed sources use method fallback' => sub {
  my $runtime = build_native_runtime($schema);
  my $root = Local::DefaultResolver::Root->new;
  my $static_query = '{ hello(suffix: "x") inner { req(suffix: "x") } explicit }';
  my $bundle = $runtime->compile_bundle_for_document($static_query);
  my $want = {
    data => {
      hello => 'x:req:hello',
      inner => { req => 'method:x:req:req' },
      explicit => 'explicit',
    },
  };
  my %lanes = (
    'async program' => build_native_runtime($schema, async => 1)->execute_document(
      $query, variables => { suffix => 'x' }, root_value => $root,
      context => { request => 'req' },
    ),
    'fast SV program' => $runtime->execute_document(
      $query, variables => { suffix => 'x' }, root_value => $root,
      context => { request => 'req' },
    ),
    'fast JSON program' => JSON::PP::decode_json($runtime->execute_document_to_json(
      $query, variables => { suffix => 'x' }, root_value => $root,
      context => { request => 'req' },
    )),
    'bundle envelope' => $runtime->execute_bundle(
      $bundle, root_value => $root, context => { request => 'req' },
    ),
    'bundle JSON' => JSON::PP::decode_json($runtime->execute_bundle_to_json(
      $bundle, root_value => $root, context => { request => 'req' },
    )),
  );
  for my $lane (sort keys %lanes) {
    is_deeply $lanes{$lane}, $want, $lane;
  }
};

subtest 'blessed hashes without a method retain hash fallback' => sub {
  my $root = bless { hello => 'hash-fallback' },
    'Local::DefaultResolver::HashOnly';
  my $result = build_native_runtime($schema)->execute_document(
    '{ hello }', root_value => $root,
  );
  is_deeply $result, { data => { hello => 'hash-fallback' } },
    'a missing method falls through to the blessed hash key';
};

subtest 'callable overloads follow graphql-perl default resolver behavior' => sub {
  my $result = build_native_runtime($schema)->execute_document(
    '{ hello(suffix: "x") }',
    root_value => {
      hello => Local::DefaultResolver::Callable->new('overload'),
    },
    context => { request => 'req' },
  );
  is_deeply $result, { data => { hello => 'overload:x:req:hello' } },
    'an overloaded coderef receives args, context, and info';
};

subtest 'blessed coderefs stay on the native coderef path' => sub {
  my $callback = bless sub {
    my ($args, $context, $info) = @_;
    return join ':', 'blessed', $args->{suffix}, $context->{request},
      $info->{field_name};
  }, 'Local::DefaultResolver::BlessedCoderef';
  my $result = build_native_runtime($schema)->execute_document(
    '{ hello(suffix: "x") }',
    root_value => { hello => $callback },
    context => { request => 'req' },
  );
  is_deeply $result, { data => { hello => 'blessed:x:req:hello' } },
    'a blessed real CV is invoked directly';
};

subtest 'default resolver failures become field errors' => sub {
  my $result = build_native_runtime($schema)->execute_document(
    '{ failure }', root_value => { failure => sub { die "default failed\n" } },
  );
  is $result->{data}{failure}, undef, 'failed field is null';
  like $result->{errors}[0]{message}, qr/default failed/, 'exception is recorded';
  is_deeply $result->{errors}[0]{path}, ['failure'], 'field path is retained';
};

subtest 'default resolver coderefs support Promise::XS' => sub {
  plan skip_all => 'Promise::XS is not available'
    if !eval { require Promise::XS; 1 };
  my $result = build_native_runtime($schema, async => 1)->execute_document(
    '{ promised }',
    root_value => { promised => sub { Promise::XS::resolved('settled') } },
  );
  is_deeply $result, { data => { promised => 'settled' } },
    'promise result follows the async completion lane';
};

done_testing;
