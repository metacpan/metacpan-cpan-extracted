use warnings;
use strict;

use Module::Build 0.2808;
use Test::More;

BEGIN {
	plan skip_all => "these tests rely on Unix commands"
		unless Module::Build->is_unixish;
	plan tests => 14;
	use_ok "IPC::Filter", qw(filter);
}

my($result, $err);

sub test_filter($@) {
	my($data, @cmd) = @_;
	$result = eval { filter($data, @cmd) };
	$err = $@;
}

test_filter("foo\n");
is($err, "filter: invalid command\n");

test_filter("foo\n", "-");
is($err, "filter: invalid command\n");

test_filter("foo\n", "cat");
is($err, "");
is($result, "foo\n");

test_filter("foo\n", "tr", "abfor", "ABFOR");
is($err, "");
is($result, "FOO\n");

test_filter("foo\n", "tr abfor ABFOR");
is($err, "");
is($result, "FOO\n");

test_filter("foo\n", "tr abfor ABFOR; echo bar");
is($err, "");
is($result, "FOO\nbar\n");

test_filter("foo\n", "{ exit 1; }");
is($err, "filter: process exited with status 1\n");

test_filter("foo\n", "echo >&2 bar; exit 1");
is($err, "filter: process exited with status 1\nbar\n");

test_filter("foo\n", "echo >&2 bar; kill -9 \$\$");
is($err, "filter: process died on SIGKILL\n");

1;
