use Test::More 'no_plan';

use List::Maker;

is_deeply [<'' xx 10>], [('') x 10]              => q{<'' x 10>};
is_deeply [<'a' xx 10>], [('a') x 10]            => q{<'a' x 10>};
is_deeply [<'aaa' xx 3>], [('aaa') x 3]          => q{<'aaa' x 3>};
is_deeply [<'a"a' xx 3>], [('a"a') x 3]          => q{<'a"a' x 3>};

is_deeply [<"" xx 10>], [("") x 10]              => q{<"" x 10>};
is_deeply [<"a" xx 10>], [("a") x 10]            => q{<"a" x 10>};
is_deeply [<"aaa" xx 3>], [("aaa") x 3]          => q{<"aaa" x 3>};
is_deeply [<"a'a" xx 3>], [("a'a") x 3]          => q{<"a'a" x 3>};

is_deeply [<0 xx 10>], [(0) x 10]                => q{<0 x 10>};
is_deeply [<4 xx 10>], [(4) x 10]                => q{<4 x 10>};
is_deeply [<42 xx 3>], [(42) x 3]                => q{<42 x 3>};
is_deeply [<4.2 xx 3>], [(4.2) x 3]              => q{<4.2 x 3>};
