#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use JavaScript::Dependency::Manager;

{
  my $mgr = JavaScript::Dependency::Manager->new(
    lib_dir => ['t/js-lib'],
    recurse => 0,
    provisions => {
      extjs => [qw(t/js-lib/ext/ext-all.js t/js-lib/ext/ext-all-debug.js)],
      'ext-core' => ['t/js-lib/ext/ext-core.js'],
    },
    requirements => {
      't/js-lib/ext/ext-all.js' => ['ext-core'],
    },
  );

  is_deeply
    [$mgr->file_list_for_provisions(['a'])],
    [qw(t/js-lib/ext/ext-core.js t/js-lib/ext/ext-all.js t/js-lib/A.js)],
    'basic deps';

  is_deeply
    [$mgr->file_list_for_provisions([qw(a b c)])],
    [qw(
      t/js-lib/ext/ext-core.js
      t/js-lib/ext/ext-all.js
      t/js-lib/A.js
      t/js-lib/B.js
      t/js-lib/C.js
    )],
    'deps with multiple provisions';

  is_deeply
    [$mgr->file_list_for_provisions([qw(b a c)])],
    [qw(
      t/js-lib/ext/ext-core.js
      t/js-lib/ext/ext-all.js
      t/js-lib/A.js
      t/js-lib/B.js
      t/js-lib/C.js
    )],
    'deps with multiple provisions out of order';
}

{
  my $mgr = JavaScript::Dependency::Manager->new(
    lib_dir => ['t/js-lib'],
    recurse => 1,
    provisions => {
      extjs => [qw(t/js-lib/ext/ext-all.js t/js-lib/ext/ext-all-debug.js)],
    },
    requirements => {
      't/js-lib/ext/ext-all.js' => ['ext-core'],
    },
  );

  is_deeply
    [$mgr->file_list_for_provisions(['a'])],
    [qw(t/js-lib/ext/ext-core.js t/js-lib/ext/ext-all.js t/js-lib/A.js)],
    'recurse option works';
}

done_testing;
