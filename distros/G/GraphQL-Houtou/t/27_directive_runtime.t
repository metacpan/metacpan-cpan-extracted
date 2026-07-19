use strict;
use warnings;

use Test::More 0.98;

use lib 'lib';
use GraphQL::Houtou ();
use GraphQL::Houtou::Directive;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Boolean $String);

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

my $UrlScalar = GraphQL::Houtou::Type::Scalar->new(
  name => 'UrlScalar',
  specified_by_url => 'https://example.com/spec/url-scalar',
  serialize => sub { defined $_[0] ? "$_[0]" : undef },
  parse_value => sub { $_[0] },
);

my $Mask = GraphQL::Houtou::Directive->new(
  name => 'mask',
  repeatable => 1,
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  args => {
    enabled => { type => $Boolean->non_null },
  },
  apply_field_result => sub {
    my ($value, $source, $field_args, $context, $info, $return_type, $directive_args) = @_;
    return $directive_args->{enabled} ? '***' : $value;
  },
);

my $Upper = GraphQL::Houtou::Directive->new(
  name => 'upper',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  resolve_field => sub {
    my ($next) = @_;
    my $value = $next->();
    return undef if !defined $value;
    return uc($value);
  },
);

my $Auth = GraphQL::Houtou::Directive->new(
  name => 'auth',
  locations => [ qw(FIELD_DEFINITION) ],
  args => {
    role => { type => $String->non_null },
  },
  resolve_field => sub {
    my ($next, $source, $field_args, $context, $info, $return_type, $directive_args) = @_;
    die "forbidden\n" if (($context || {})->{role} || '') ne ($directive_args->{role} || '');
    return $next->();
  },
);

my $Bracket = GraphQL::Houtou::Directive->new(
  name => 'bracket',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  apply_field_result => sub {
    my ($value) = @_;
    return undef if !defined $value;
    return '[' . $value . ']';
  },
);

my $Bang = GraphQL::Houtou::Directive->new(
  name => 'bang',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  apply_field_result => sub {
    my ($value) = @_;
    return undef if !defined $value;
    return $value . '!';
  },
);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'DirectiveUser',
  fields => {
    name => { type => $String },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'DirectiveQuery',
    fields => {
      hello => {
        type => $String,
        resolver_mode => 'native',
        resolve => sub { 'hello' },
      },
      viewer => {
        type => $User,
        resolver_mode => 'native',
        resolve => sub { +{ name => 'Ana' } },
      },
      homepage => {
        type => $UrlScalar,
        resolver_mode => 'native',
        resolve => sub { 'https://example.com/' },
      },
      secret => {
        type => $String,
        directives => [
          { name => 'auth', arguments => { role => 'admin' } },
        ],
      },
    },
  ),
  types => [ $User, $UrlScalar ],
  directives => [
    @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES,
    $Mask,
    $Upper,
    $Auth,
    $Bracket,
    $Bang,
  ],
);

subtest 'introspection exposes specifiedByURL and __Directive.isRepeatable' => sub {
  my $result = $schema->execute(q{
    {
      __type(name: "UrlScalar") {
        specifiedByURL
      }
      __schema {
        directives {
          name
          isRepeatable
        }
      }
    }
  });

  ok !exists $result->{errors}, 'introspection has no errors';
  is $result->{data}{__type}{specifiedByURL},
    'https://example.com/spec/url-scalar',
    'scalar specifiedByURL is exposed';

  my %directives = map { $_->{name} => $_ } @{ $result->{data}{__schema}{directives} || [] };
  ok $directives{mask}{isRepeatable}, 'custom repeatable directive is exposed';
  ok !$directives{upper}{isRepeatable}, 'non-repeatable directive stays false';
};

subtest 'custom executable field directive materializes variable arguments on native runtime' => sub {
  my $result = $schema->execute(
    'query Q($enabled: Boolean!) { hello @mask(enabled: $enabled) }',
    variables => { enabled => 1 },
  );

  is_deeply $result, {
    data => { hello => '***' },
  }, 'FIELD directive middleware sees materialized variable args';
};

subtest 'post-resolve directive API preserves directive order' => sub {
  my $result = $schema->execute('{ hello @bracket @bang }');

  is_deeply $result, {
    data => { hello => '[hello!]' },
  }, 'post-resolve directives compose in source order';
};

subtest 'native specialization freezes runtime directive payloads for variable-driven directives' => sub {
  my $runtime = $schema->build_native_runtime;
  my $program = $runtime->compile_program('query Q($enabled: Boolean!) { hello @mask(enabled: $enabled) }');
  my $specialized = $runtime->specialize_program_for_native(
    $program,
    variables => { enabled => 1 },
  );
  my $descriptor = GraphQL::Houtou::XS::VM::native_program_descriptor_xs($specialized);
  my $op = $descriptor->{blocks_compact}[0][4][0];

  is $op->[18], 1, 'runtime directive payload becomes static after specialization';
  is $op->[19][0]{arguments}{enabled}, 1, 'specialized payload stores materialized boolean value';
};

subtest 'schema-level executable directives do not force unrelated slots off the native fast path' => sub {
  my $runtime_schema = $schema->build_runtime;
  my $exec_struct = $runtime_schema->to_native_exec_struct;
  my ($hello_slot) = grep { ($_->schema_slot_key || '') eq 'DirectiveQuery.hello' } @{ $runtime_schema->slot_catalog || [] };

  ok $hello_slot, 'hello slot exists';
  is $hello_slot->resolver_mode, 'NATIVE', 'hello slot keeps native resolver mode';
  is $hello_slot->resolver_shape, 'EXPLICIT', 'hello slot remains explicit-native';
  is $exec_struct->{slot_catalog_exec}[ $hello_slot->schema_slot_index ]{callback_abi_code}, 3,
    'hello slot keeps the explicit-native callback ABI';
};

subtest 'custom directives on fragment spreads are inherited onto field resolution' => sub {
  my $result = $schema->execute(q{
    {
      viewer {
        ...NameParts @upper
      }
    }
    fragment NameParts on DirectiveUser {
      name
    }
  });

  is_deeply $result, {
    data => {
      viewer => {
        name => 'ANA',
      },
    },
  }, 'fragment-spread directive is applied when the field resolves';
};

subtest 'field-definition directives wrap the default resolver path' => sub {
  my $blocked = $schema->execute(
    '{ secret }',
    root_value => { secret => sub { 'shh' } },
    context => { role => 'guest' },
  );

  is $blocked->{data}{secret}, undef, 'blocked field resolves to undef';
  like $blocked->{errors}[0]{message}, qr/forbidden/, 'blocked field records middleware error';

  my $allowed = $schema->execute(
    '{ secret }',
    root_value => { secret => sub { 'shh' } },
    context => { role => 'admin' },
  );

  is_deeply $allowed, {
    data => { secret => 'shh' },
  }, 'field-definition directive can allow the default resolver';
};

done_testing;
