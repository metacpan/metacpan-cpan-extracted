use lib (-e 't' ? 't' : 'test'), 'inc';

use TestJS tests => 4;

filters {
    cli => [qw(run_js eval_all join)],
    output => [qw(fix_t)],
};

run_is cli => 'output';

__DATA__
=== Basic
--- cli: js-cpan Foo
--- output
t/testlib/JS/Foo.js

=== Wildcard
--- cli: js-cpan Foo*
--- output
t/testlib/JS/Foo.js
t/testlib/JS/Foo/Bar-min.js
t/testlib/JS/Foo/Bar-min.js.gz
t/testlib/JS/Foo/Bar-pack.js
t/testlib/JS/Foo/Bar.js
t/testlib/JS/Foo/bin/script

=== Specific
--- cli: js-cpan Foo.Bar.js
--- output
t/testlib/JS/Foo/Bar.js

=== Case Insensitivity
--- cli: js-cpan FoO::bAr-MiN
--- output
t/testlib/JS/Foo/Bar-min.js
t/testlib/JS/Foo/Bar-min.js.gz
