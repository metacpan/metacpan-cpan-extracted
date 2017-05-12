package main;
use Evo;

use Test::More;

# exists but can't be required
BAD_INLINE: {
  is My::BadInline::foo(), 'foo';
  local $@;
  eval { require My::BadInline };
  like $@, qr#My/BadInline#;
}

# use Evo -Loaded was executed before this
require My::Inline;

{

  package My::BadInline;
  sub foo {'foo'}

  package My::Inline;
  use Evo -Loaded;
  sub foo {'foo'}
}

use My::Inline;
is My::Inline::foo(), 'foo';

done_testing;
