#!perl

use 5.010;
use strict;
use warnings;

use File::Create::Layout;
use Test::Exception;
use Test::More 0.98;

is_deeply(File::Create::Layout::_parse_layout(""),
          [], "empty");
is_deeply(File::Create::Layout::_parse_layout("\n# comment1\n # comment2"),
          [], "blanks and comments ignored");

subtest "indentation" => sub {
    dies_ok { File::Create::Layout::_parse_layout("foo\n  bar") }
        "indent after non-dir -> dies";
    lives_ok { File::Create::Layout::_parse_layout("foo/\n  bar") }
        "indent after dir -> ok";
    dies_ok { File::Create::Layout::_parse_layout("  foo\nbar") }
        "deindent less than zero level -> dies";
    dies_ok { File::Create::Layout::_parse_layout("foo/\n  bar\n baz") }
        "deindent to unknown indent -> dies";
    lives_ok { File::Create::Layout::_parse_layout("foo/\n  bar\nbaz") }
        "deindent to known indent -> ok";

    my $res = File::Create::Layout::_parse_layout("a/\n  b");
    is($res->[0]{level}, 0);
    is($res->[1]{level}, 1);
};

subtest "filename" => sub {
    #dies_ok { File::Create::Layout::_parse_layout("") }
    #    "filename must not be empty";
    dies_ok { File::Create::Layout::_parse_layout(q[""]) }
        "filename must not be empty (json)";
    dies_ok { File::Create::Layout::_parse_layout(q["]) }
        "invalid filename -> dies (json) 1";
    dies_ok { File::Create::Layout::_parse_layout(q["foo]) }
        "invalid filename -> dies (json) 2";
    dies_ok { File::Create::Layout::_parse_layout(q["foo/"]) }
        "invalid filename -> dies (json) slash";
    dies_ok { File::Create::Layout::_parse_layout(q[.]) }
        "filename must not be .";
    dies_ok { File::Create::Layout::_parse_layout(q[..]) }
        "filename must not be ..";

    my $res = File::Create::Layout::_parse_layout(q(a.txt));
    ok(!$res->[0]{is_dir});
    is($res->[0]{name}, "a.txt");

    $res = File::Create::Layout::_parse_layout(q("a b"/));
    ok($res->[0]{is_dir});
    is($res->[0]{name}, "a b");
};

subtest "perm/owner" => sub {
    dies_ok { File::Create::Layout::_parse_layout("foo(") }
        "invalid syntax 1";
    dies_ok { File::Create::Layout::_parse_layout("foo()") }
        "invalid syntax 2";
    dies_ok { File::Create::Layout::_parse_layout("foo(a,b,c)") }
        "invalid syntax 3";
    dies_ok { File::Create::Layout::_parse_layout("foo(a,b,600,d)") }
        "invalid syntax 4";

    my $res = File::Create::Layout::_parse_layout("foo(600)");
    is($res->[0]{name}, "foo");
    is($res->[0]{perm}, 0600);
    is($res->[0]{perm_octal}, "600");

    $res = File::Create::Layout::_parse_layout("foo(root,bin,600)");
    is($res->[0]{name}, "foo");
    is($res->[0]{perm}, 0600);
    is($res->[0]{perm_octal}, "600");
    is($res->[0]{user}, "root");
    is($res->[0]{group}, "bin");
};

subtest symlink => sub {
    dies_ok { File::Create::Layout::_parse_layout("foo/ -> bar") }
        "symlink cannot be directory";
    dies_ok { File::Create::Layout::_parse_layout(q(foo -> "bar)) }
        "invalid symlink target name (json) 1";
    dies_ok { File::Create::Layout::_parse_layout(q(foo -> "")) }
        "symlink target name (json) cannot be empty";

    my $res = File::Create::Layout::_parse_layout("a -> b");
    ok($res->[0]{is_symlink});
    is($res->[0]{symlink_target}, "b");

    $res = File::Create::Layout::_parse_layout(q(a -> "b c"));
    ok($res->[0]{is_symlink});
    is($res->[0]{symlink_target}, "b c");
};

subtest content => sub {
    dies_ok { File::Create::Layout::_parse_layout(q(foo/ "content":"bar")) }
        "dir cannot have content";

    my $res = File::Create::Layout::_parse_layout(q(foo "content":"bar"));
    is($res->[0]{name}, "foo");
    is($res->[0]{content}, "bar");
};

done_testing;
