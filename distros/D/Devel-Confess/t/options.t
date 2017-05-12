use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 19;
use Devel::Confess ();
sub parse;
*parse = \&Devel::Confess::_parse_options;

is_deeply parse(), {}, 'can parse no options';

is_deeply parse('objects'), { objects => 1 }, 'enable boolean option';

is_deeply parse('noobjects'), { objects => !1 }, 'disable boolean option';
is_deeply parse('no_objects'), { objects => !1 }, 'disable boolean option with underscore';
is_deeply parse('no-objects'), { objects => !1 }, 'disable boolean option with dash';

is_deeply parse('objects' => 5),      { objects => 5 }, 'numeric argument separate';
is_deeply parse('objects5'),          { objects => 5 }, 'numeric argument joined';
is_deeply parse('objects' => undef),  { objects => undef }, 'undef argument separate';
is_deeply parse('objects=5'),         { objects => 5 }, 'numeric argument with equals';
is_deeply parse('objects=force'),     { objects => 'force' }, 'string argument with equals';

is_deeply parse('betternames'), { better_names => 1 }, 'missing underscore';
is_deeply parse('better-names'), { better_names => 1 }, 'using dash';

is_deeply parse('dump'), { dump => 3 }, 'dump defaults to 3 when enabled';

is_deeply parse('dump0'), { dump => 1e10000 }, 'dump converts 0 to inf';

eval { parse('noobjects5') };
like $@, qr/noobjects5/, 'invalid: no with numeric joined';

eval { parse('noobjects=5') };
like $@, qr/noobjects=5/, 'invalid: no with numeric equals';

eval { parse('welp') };
like $@, qr/welp/, 'invalid: unrecognized';

eval { parse(undef) };
like $@, qr/\[undef\]/, 'invalid: undef';

eval { parse('welp', 'color', 'guff') };
like $@, qr/welp, guff/, 'multiple invalid';
