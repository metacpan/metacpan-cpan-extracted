use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Langertha;

{
  my $classes = Langertha->available_engine_classes;
  ok(ref($classes) eq 'ARRAY', 'available_engine_classes returns arrayref');
  ok((grep { $_ eq 'Langertha::Engine::OpenAI' } @$classes), 'discovered core engine class');
  ok((grep { $_ eq 'LangerthaX::Engine::TestEngine' } @$classes), 'discovered LangerthaX test engine class');
}

{
  my $ids = Langertha->available_engine_ids;
  ok(ref($ids) eq 'ARRAY', 'available_engine_ids returns arrayref');
  ok((grep { $_ eq 'openai' } @$ids), 'includes core engine id');
  ok((grep { $_ eq 'testengine' } @$ids), 'includes LangerthaX engine id');
}

is(
  Langertha->resolve_engine_class('OpenAI'),
  'Langertha::Engine::OpenAI',
  'resolves core engine short name',
);

is(
  Langertha->resolve_engine_class('Langertha::Engine::OpenAI'),
  'Langertha::Engine::OpenAI',
  'resolves fully-qualified core engine class',
);

is(
  Langertha->resolve_engine_class('TestEngine'),
  'LangerthaX::Engine::TestEngine',
  'falls back to LangerthaX custom engine',
);

eval { Langertha->resolve_engine_class('NoSuchEngine') };
like($@, qr/Engine 'NoSuchEngine' not found/, 'unknown engine croaks');

{
  my $engine = Langertha->new_engine('TestEngine', answer => 42);
  isa_ok($engine, 'LangerthaX::Engine::TestEngine', 'new_engine builds custom engine instance');
  is($engine->{answer}, 42, 'new_engine passes constructor params');
}

{
  eval { Langertha->new_engine('OpenAIBase', api_key => 'k') };
  like($@, qr/url/, 'new_engine surfaces constructor errors from resolved class');
}

{
  eval { Langertha->new_engine('OpenAI', 'api_key') };
  like($@, qr/key\/value pairs/, 'new_engine validates constructor arg pairing');
}

done_testing;
