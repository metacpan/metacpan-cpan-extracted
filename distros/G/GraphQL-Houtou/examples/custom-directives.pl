use strict;
use warnings;

use Data::Dumper;

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Directive;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Boolean $String);

my $Upper = GraphQL::Houtou::Directive->new(
  name => 'upper',
  locations => [qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT)],
  apply_field_result => sub {
    my ($value) = @_;
    return undef if !defined $value;
    return uc $value;
  },
);

my $Mask = GraphQL::Houtou::Directive->new(
  name => 'mask',
  locations => [qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT)],
  args => {
    enabled => { type => $Boolean->non_null },
  },
  apply_field_result => sub {
    my ($value, $source, $field_args, $context, $info, $return_type, $directive_args) = @_;
    return $directive_args->{enabled} ? '***' : $value;
  },
);

my $RequireRole = GraphQL::Houtou::Directive->new(
  name => 'requireRole',
  locations => [qw(FIELD_DEFINITION)],
  args => {
    role => { type => $String->non_null },
  },
  resolve_field => sub {
    my ($next, $source, $field_args, $context, $info, $return_type, $directive_args) = @_;
    die "forbidden\n" if (($context || {})->{role} || '') ne ($directive_args->{role} || '');
    return $next->();
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'ExampleQuery',
    fields => {
      hello => {
        type => $String,
        resolver_mode => 'native',
        resolve => sub { 'hello' },
      },
      secret => {
        type => $String,
        directives => [
          { name => 'requireRole', arguments => { role => 'admin' } },
        ],
      },
    },
  ),
  directives => [
    @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES,
    $Upper,
    $Mask,
    $RequireRole,
  ],
);

my $result = $schema->execute(
  'query Q($enabled: Boolean!) { hello @upper @mask(enabled: $enabled) secret }',
  root_value => { secret => 'classified' },
  context => { role => 'admin' },
  variables => { enabled => 0 },
);

print Dumper($result);
