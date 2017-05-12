use Test::More;
sub tests'VERSION { $tests'tests += pop };
sub tests'import { shift; $tests'tests += pop||return }
CHECK{plan tests => $tests'tests;}
$$