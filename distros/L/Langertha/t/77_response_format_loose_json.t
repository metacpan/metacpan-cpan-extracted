use strict;
use warnings;
use Test::More;

# decode_loose_json is now a Role method, callable via $engine->decode_loose_json($text).
# The test composes the role into a throwaway class so we can call it as a method.
{
  package T;
  use Moose;
  with 'Langertha::Role::ResponseFormat';
  __PACKAGE__->meta->make_immutable;
}

my $t = T->new;
sub decode { $t->decode_loose_json(@_) }

is_deeply( decode('{"a":1}'), { a => 1 }, 'plain JSON' );

is_deeply(
  decode("```json\n{\"a\":1,\"b\":\"x\"}\n```"),
  { a => 1, b => 'x' },
  'fenced ```json``` block',
);

is_deeply(
  decode("Sure! Here you go:\n```\n{\"a\":2}\n```\nHope that helps."),
  { a => 2 },
  'plain ``` fence with surrounding prose',
);

is_deeply(
  decode("The answer is {\"a\":3,\"b\":[1,2]} cheers."),
  { a => 3, b => [1,2] },
  'first {...} substring extracted from prose',
);

is( decode(undef), undef, 'undef in -> undef out' );
is( decode(''),    undef, 'empty in -> undef out' );
is( decode('totally not json'), undef, 'unparseable -> undef' );

# Override-friendliness: a subclass can override the method.
{
  package T2;
  use Moose;
  extends 'T';
  override decode_loose_json => sub { return { overridden => 1 } };
  __PACKAGE__->meta->make_immutable;
}
is_deeply( T2->new->decode_loose_json('whatever'), { overridden => 1 },
  'subclass override of decode_loose_json' );

done_testing;
