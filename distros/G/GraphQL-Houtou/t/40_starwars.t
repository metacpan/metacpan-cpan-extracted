use strict;
use warnings;
use Test::More;

# The Star Wars schema from the graphql-js reference implementation: the
# de-facto conformance example ported by every executor (JS, graphql-core,
# graphql-java, gqlgen, juniper). Exercises the combinations real schemas
# hit at once: an interface with cyclic references (Character.friends is
# [Character]), an enum used both as an argument and a list output, named
# and inline fragments, @include/@skip with variables, aliases on the same
# field, a resolver error inside a nested selection, and the identical
# queries again on the async lane with friends loaded through DataLoader.

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS not available';
}

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Enum;
use GraphQL::Houtou::Type::List;
use GraphQL::Houtou::Type::Scalar qw($String $ID);
use GraphQL::Houtou::DataLoader;

# --------------------------------------------------------------------------
# The classic dataset.
# --------------------------------------------------------------------------
my %CHARACTERS = (
  '1000' => { kind => 'human', id => '1000', name => 'Luke Skywalker',
              friends => ['1002', '1003', '2000', '2001'],
              appears_in => [ 'NEWHOPE', 'EMPIRE', 'JEDI' ],
              home_planet => 'Tatooine' },
  '1001' => { kind => 'human', id => '1001', name => 'Darth Vader',
              friends => ['1004'],
              appears_in => [ 'NEWHOPE', 'EMPIRE', 'JEDI' ],
              home_planet => 'Tatooine' },
  '1002' => { kind => 'human', id => '1002', name => 'Han Solo',
              friends => ['1000', '1003', '2001'],
              appears_in => [ 'NEWHOPE', 'EMPIRE', 'JEDI' ] },
  '1003' => { kind => 'human', id => '1003', name => 'Leia Organa',
              friends => ['1000', '1002', '2000', '2001'],
              appears_in => [ 'NEWHOPE', 'EMPIRE', 'JEDI' ],
              home_planet => 'Alderaan' },
  '1004' => { kind => 'human', id => '1004', name => 'Wilhuff Tarkin',
              friends => ['1001'],
              appears_in => [ 'NEWHOPE' ] },
  '2000' => { kind => 'droid', id => '2000', name => 'C-3PO',
              friends => ['1000', '1002', '1003', '2001'],
              appears_in => [ 'NEWHOPE', 'EMPIRE', 'JEDI' ],
              primary_function => 'Protocol' },
  '2001' => { kind => 'droid', id => '2001', name => 'R2-D2',
              friends => ['1000', '1002', '1003'],
              appears_in => [ 'NEWHOPE', 'EMPIRE', 'JEDI' ],
              primary_function => 'Astromech' },
);

sub hero_for {
  my ($episode) = @_;
  return $CHARACTERS{ ($episode // '') eq 'EMPIRE' ? '1000' : '2001' };
}

# --------------------------------------------------------------------------
# Schema builder: $friend_resolver lets the same schema run with plain
# synchronous lookups or through a per-request DataLoader.
# --------------------------------------------------------------------------
sub build_schema {
  my (%args) = @_;
  my $friend_resolver = $args{friend_resolver}
    || sub { [ map { $CHARACTERS{$_} } @{ $_[0]{friends} || [] } ] };

  my $Episode = GraphQL::Houtou::Type::Enum->new(
    name => 'Episode',
    values => {
      NEWHOPE => {},
      EMPIRE => {},
      JEDI => {},
    },
  );

  my %character_fields;
  my $Character;
  $Character = GraphQL::Houtou::Type::Interface->new(
    name => 'Character',
    fields => sub {
      return {
        id => { type => $ID->non_null },
        name => { type => $String },
        friends => {
          type => GraphQL::Houtou::Type::List->new(of => $Character),
          resolve => $friend_resolver,
        },
        appearsIn => {
          type => GraphQL::Houtou::Type::List->new(of => $Episode),
          resolve => sub { $_[0]{appears_in} },
        },
        secretBackstory => {
          type => $String,
          resolve => sub { die "secretBackstory is secret.\n" },
        },
      };
    },
    tag_resolver => sub { $_[0]{kind} },
  );

  my $Human = GraphQL::Houtou::Type::Object->new(
    name => 'Human',
    interfaces => [ $Character ],
    runtime_tag => 'human',
    fields => sub {
      return {
        id => { type => $ID->non_null },
        name => { type => $String },
        friends => {
          type => GraphQL::Houtou::Type::List->new(of => $Character),
          resolve => $friend_resolver,
        },
        appearsIn => {
          type => GraphQL::Houtou::Type::List->new(of => $Episode),
          resolve => sub { $_[0]{appears_in} },
        },
        secretBackstory => {
          type => $String,
          resolve => sub { die "secretBackstory is secret.\n" },
        },
        homePlanet => {
          type => $String,
          resolve => sub { $_[0]{home_planet} },
        },
      };
    },
  );

  my $Droid = GraphQL::Houtou::Type::Object->new(
    name => 'Droid',
    interfaces => [ $Character ],
    runtime_tag => 'droid',
    fields => sub {
      return {
        id => { type => $ID->non_null },
        name => { type => $String },
        friends => {
          type => GraphQL::Houtou::Type::List->new(of => $Character),
          resolve => $friend_resolver,
        },
        appearsIn => {
          type => GraphQL::Houtou::Type::List->new(of => $Episode),
          resolve => sub { $_[0]{appears_in} },
        },
        secretBackstory => {
          type => $String,
          resolve => sub { die "secretBackstory is secret.\n" },
        },
        primaryFunction => {
          type => $String,
          resolve => sub { $_[0]{primary_function} },
        },
      };
    },
  );

  my $Query = GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hero => {
        type => $Character,
        args => { episode => { type => $Episode } },
        resolve => sub {
          my (undef, $args) = @_;
          return hero_for($args->{episode});
        },
      },
      human => {
        type => $Human,
        args => { id => { type => $ID->non_null } },
        resolve => sub {
          my (undef, $args) = @_;
          my $row = $CHARACTERS{ $args->{id} };
          return ($row && $row->{kind} eq 'human') ? $row : undef;
        },
      },
      droid => {
        type => $Droid,
        args => { id => { type => $ID->non_null } },
        resolve => sub {
          my (undef, $args) = @_;
          my $row = $CHARACTERS{ $args->{id} };
          return ($row && $row->{kind} eq 'droid') ? $row : undef;
        },
      },
    },
  );

  return GraphQL::Houtou::Schema->new(
    query => $Query,
    types => [ $Character, $Human, $Droid, $Episode ],
    %{ $args{schema_opts} || {} },
  );
}

my $schema = build_schema();
my $runtime = build_native_runtime($schema);

sub run_query {
  my ($query, %opts) = @_;
  return $runtime->execute_document($query, %opts);
}

# --------------------------------------------------------------------------
# The canonical query set from the reference test suite.
# --------------------------------------------------------------------------

subtest 'hero of the saga' => sub {
  is_deeply run_query('{ hero { name } }'), {
    data => { hero => { name => 'R2-D2' } },
  }, 'R2-D2 is the hero';
};

subtest 'hero with enum argument' => sub {
  is_deeply run_query('{ hero(episode: EMPIRE) { name } }'), {
    data => { hero => { name => 'Luke Skywalker' } },
  }, 'Luke is the hero of EMPIRE';

  is_deeply run_query(
    'query HeroFor($ep: Episode) { hero(episode: $ep) { name } }',
    variables => { ep => 'EMPIRE' },
  ), {
    data => { hero => { name => 'Luke Skywalker' } },
  }, 'enum argument through variables';
};

subtest 'nested friends (two levels) with __typename and enum list output' => sub {
  my $result = run_query(q~
    { hero { __typename id name appearsIn friends { name friends { name } } } }
  ~);
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{hero}{__typename}, 'Droid', 'abstract type resolves to Droid';
  is_deeply $result->{data}{hero}{appearsIn}, [qw(NEWHOPE EMPIRE JEDI)],
    'enum list serializes to names';
  is_deeply [ map { $_->{name} } @{ $result->{data}{hero}{friends} } ],
    [ 'Luke Skywalker', 'Han Solo', 'Leia Organa' ],
    'first level of friends';
  is_deeply [ map { $_->{name} } @{ $result->{data}{hero}{friends}[0]{friends} } ],
    [ 'Han Solo', 'Leia Organa', 'C-3PO', 'R2-D2' ],
    'friends of friends (cyclic interface reference)';
};

subtest 'aliases fetch the same field twice' => sub {
  is_deeply run_query(q~
    { empireHero: hero(episode: EMPIRE) { name } jediHero: hero(episode: JEDI) { name } }
  ~), {
    data => {
      empireHero => { name => 'Luke Skywalker' },
      jediHero => { name => 'R2-D2' },
    },
  }, 'aliased heroes';
};

subtest 'named fragment shared by two selections' => sub {
  is_deeply run_query(q~
    query UseFragment {
      leia: human(id: "1003") { ...HumanFragment }
      han: human(id: "1002") { ...HumanFragment }
    }
    fragment HumanFragment on Human { name homePlanet }
  ~), {
    data => {
      leia => { name => 'Leia Organa', homePlanet => 'Alderaan' },
      han => { name => 'Han Solo', homePlanet => undef },
    },
  }, 'fragment reuse and a nullable field left null';
};

subtest 'inline fragments discriminate interface members' => sub {
  is_deeply run_query(q~
    {
      hero {
        name
        ... on Droid { primaryFunction }
        ... on Human { homePlanet }
      }
      luke: human(id: "1000") {
        name
        ... on Human { homePlanet }
      }
    }
  ~), {
    data => {
      hero => { name => 'R2-D2', primaryFunction => 'Astromech' },
      luke => { name => 'Luke Skywalker', homePlanet => 'Tatooine' },
    },
  }, 'per-type fragments apply only to matching members';
};

subtest '@include and @skip with variables' => sub {
  my $query = q~
    query Hero($withFriends: Boolean!, $skipName: Boolean!) {
      hero {
        name @skip(if: $skipName)
        friends @include(if: $withFriends) { name }
      }
    }
  ~;
  is_deeply run_query($query, variables => { withFriends => 0, skipName => 0 }), {
    data => { hero => { name => 'R2-D2' } },
  }, 'friends excluded';
  my $with = run_query($query, variables => { withFriends => 1, skipName => 1 });
  ok !exists $with->{errors}, 'no errors';
  ok !exists $with->{data}{hero}{name}, 'name skipped';
  is scalar @{ $with->{data}{hero}{friends} }, 3, 'friends included';
};

subtest 'resolver error surfaces with path and nulls only that field' => sub {
  my $result = run_query('{ hero { name secretBackstory } }');
  is $result->{data}{hero}{name}, 'R2-D2', 'sibling field still resolves';
  ok !defined $result->{data}{hero}{secretBackstory}, 'failed field is null';
  like $result->{errors}[0]{message}, qr/secretBackstory is secret/, 'error message';
  is_deeply $result->{errors}[0]{path}, [ 'hero', 'secretBackstory' ], 'error path';
};

subtest 'error inside a list item carries the index in its path' => sub {
  my $result = run_query('{ hero { friends { name secretBackstory } } }');
  is_deeply $result->{data}{hero}{friends}[1]{name} , 'Han Solo', 'items resolve';
  my ($err) = grep { $_->{path} && $_->{path}[2] == 1 } @{ $result->{errors} };
  ok $err, 'per-item error present';
  is_deeply $err->{path}, [ 'hero', 'friends', 1, 'secretBackstory' ],
    'path includes the list index';
};

subtest 'unknown id returns null without an error' => sub {
  is_deeply run_query('{ human(id: "9999") { name } }'), {
    data => { human => undef },
  }, 'missing human is null';

  is_deeply run_query('{ droid(id: "1000") { name } }'), {
    data => { droid => undef },
  }, 'a human asked for as droid is null';
};

subtest 'introspection sees the interface' => sub {
  my $result = run_query(q~
    { __type(name: "Droid") { name kind interfaces { name } } }
  ~);
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{__type}{name}, 'Droid', 'type name';
  is $result->{data}{__type}{kind}, 'OBJECT', 'kind';
  is_deeply $result->{data}{__type}{interfaces}, [ { name => 'Character' } ],
    'implements Character';
};

# --------------------------------------------------------------------------
# The same canonical queries on the async lane: friends resolve through a
# per-request DataLoader, and every envelope must match the sync lane.
# --------------------------------------------------------------------------
subtest 'async lane with DataLoader friends matches the sync lane' => sub {
  my @batches;
  my $loader;
  my $async_schema = build_schema(
    friend_resolver => sub {
      my ($source) = @_;
      return $loader->load_many([ @{ $source->{friends} || [] } ]);
    },
  );
  my $async_runtime = build_native_runtime($async_schema, async => 1);

  for my $query (
    '{ hero { name friends { name friends { name } } } }',
    '{ hero { name secretBackstory friends { name secretBackstory } } }',
    q~{ hero { name ... on Droid { primaryFunction } friends { name appearsIn } } }~,
  ) {
    @batches = ();
    $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      push @batches, [ @{ $_[0] } ];
      return [ map { $CHARACTERS{$_} } @{ $_[0] } ];
    });
    my $async_result = $async_runtime->execute_document($query,
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    my $sync_result = run_query($query);
    is_deeply $async_result, $sync_result, "async matches sync for $query";
  }

  # the two-level friends query collapses into one batch per level
  @batches = ();
  $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @batches, [ @{ $_[0] } ];
    return [ map { $CHARACTERS{$_} } @{ $_[0] } ];
  });
  $async_runtime->execute_document(
    '{ hero { name friends { name friends { name } } } }',
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  is scalar @batches, 2, 'two friend levels load in two batches';
  is_deeply $batches[0], [ '1000', '1002', '1003' ], 'level one keys';
};

done_testing;
