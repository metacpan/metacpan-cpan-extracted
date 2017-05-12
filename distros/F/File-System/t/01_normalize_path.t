# vim: set ft=perl :

use strict;
use warnings;

use File::Path;
use Test::More tests => 45;

BEGIN { use_ok('File::System') }

-d 't/root' && rmtree('t/root', 1);
mkpath('t/root/bar/baz', 1, 0700);

my $obj = File::System->new('Real', root => 't/root');

is($obj->normalize_path('//////'), '/');
is($obj->normalize_path('/foo/bar/baz/'), '/foo/bar/baz');
is($obj->normalize_path('/././././././././.'), '/');
is($obj->normalize_path('/../foo/../bar/baz/..'), '/bar');
is($obj->normalize_path('foo'), '/foo');
is($obj->normalize_path('/foo'), '/foo');
is($obj->normalize_path('../foo'), '/foo');
is($obj->normalize_path('foo/..'), '/');
is($obj->normalize_path('foo/bar/./..'), '/foo');
is($obj->normalize_path('/foo/bar/./..'), '/foo');
is($obj->normalize_path('/foo/bar/baz/qux/quux/../../../quuux'), '/foo/bar/quuux');

like($obj->normalize_real_path('//////'), qr(t/root$));
like($obj->normalize_real_path('/foo/bar/baz/'), qr(t/root/foo/bar/baz$));
like($obj->normalize_real_path('/././././././././.'), qr(t/root$));
like($obj->normalize_real_path('/../foo/../bar/baz/..'), qr(t/root/bar$));
like($obj->normalize_real_path('foo'), qr(t/root/foo$));
like($obj->normalize_real_path('/foo'), qr(t/root/foo$));
like($obj->normalize_real_path('../foo'), qr(t/root/foo$));
like($obj->normalize_real_path('foo/..'), qr(t/root$));
like($obj->normalize_real_path('foo/bar/./..'), qr(t/root/foo$));
like($obj->normalize_real_path('/foo/bar/./..'), qr(t/root/foo$));
like($obj->normalize_real_path('/foo/bar/baz/qux/quux/../../../quuux'), qr(t/root/foo/bar/quuux$));

$obj = $obj->lookup('bar/baz');
is($obj->normalize_path('//////'), '/');
is($obj->normalize_path('/foo/bar/baz/'), '/foo/bar/baz');
is($obj->normalize_path('/././././././././.'), '/');
is($obj->normalize_path('/../foo/../bar/baz/..'), '/bar');
is($obj->normalize_path('foo'), '/bar/baz/foo');
is($obj->normalize_path('/foo'), '/foo');
is($obj->normalize_path('../foo'), '/bar/foo');
is($obj->normalize_path('foo/..'), '/bar/baz');
is($obj->normalize_path('foo/bar/./..'), '/bar/baz/foo');
is($obj->normalize_path('/foo/bar/./..'), '/foo');
is($obj->normalize_path('/foo/bar/baz/qux/quux/../../../quuux'), '/foo/bar/quuux');

like($obj->normalize_real_path('//////'), qr(t/root$));
like($obj->normalize_real_path('/foo/bar/baz/'), qr(t/root/foo/bar/baz$));
like($obj->normalize_real_path('/././././././././.'), qr(t/root$));
like($obj->normalize_real_path('/../foo/../bar/baz/..'), qr(t/root/bar$));
like($obj->normalize_real_path('foo'), qr(t/root/bar/baz/foo$));
like($obj->normalize_real_path('/foo'), qr(t/root/foo$));
like($obj->normalize_real_path('../foo'), qr(t/root/bar/foo$));
like($obj->normalize_real_path('foo/..'), qr(t/root/bar/baz$));
like($obj->normalize_real_path('foo/bar/./..'), qr(t/root/bar/baz/foo$));
like($obj->normalize_real_path('/foo/bar/./..'), qr(t/root/foo$));
like($obj->normalize_real_path('/foo/bar/baz/qux/quux/../../../quuux'), qr(t/root/foo/bar/quuux$));

rmtree('t/root', 0);
