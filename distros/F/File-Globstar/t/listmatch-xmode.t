# Copyright (C) 2016-2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use common::sense;

use Test::More tests => 43;

use File::Globstar::ListMatch;

my ($matcher, $input);

$input = <<EOF;
hello.pl
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('hello.pl'), 'regular match';
ok $matcher->match('path/to/hello.pl'), 'basename match';
ok $matcher->match('/path/to/hello.pl'), 'basename match with leading slash';
ok !$matcher->match('goodbye.pl'), 'regular mismatch';
ok !$matcher->match('hello/goodbye.pl'), 'basename mismatch';


$input = <<EOF;
/hello.pl
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('hello.pl'), 'full path match';
ok !$matcher->match('path/to/hello.pl'), 'match in subdirectory';

SKIP: {
    skip "unclear git behavior", 3 if $ENV{FILE_GLOBSTAR_GIT_CHECK_IGNORE};

    $input = <<EOF;
*.o
!o.o
EOF
    $matcher = File::Globstar::ListMatch->new(\$input);
    ok $matcher->match('path/to/compiled.o'), 'wildcard match';
    ok !$matcher->match('o.o'), 'negated match';
    ok !$matcher->match('path/to/o.o'), 'negated match in subdirectory';
}

SKIP: {
    skip "cannot test ignore case with real git", 3 if $ENV{FILE_GLOBSTAR_GIT_CHECK_IGNORE};
    $input = <<EOF;
FooBar
EOF
    $matcher = File::Globstar::ListMatch->new(\$input, ignoreCase => 1);
    ok $matcher->match('FooBar'), 'ignoreCase exact';
    ok $matcher->match('foobar'), 'ignoreCase lower';
    ok $matcher->match('FOOBAR'), 'ignoreCase upper';
}

$input = <<EOF;
src
!src
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('src', 1), 'include: exact negation';
ok !$matcher->match('src/hello.c'), 'include: exact negation, inside';

$input = <<EOF;
src
!src
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('src', 1), 'exclude: exact negation';
ok !$matcher->match('src/hello.c'), 'exclude: exact negation, inside';

$input = <<EOF;
src
!/src
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('src', 1), 'exclude: /negation';
ok !$matcher->match('src/hello.c'), 'exclude: /negation, inside';

$input = <<EOF;
src
!src/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('src', 1), 'exclude: negation/';
ok !$matcher->match('src/hello.c'), 'exclude: negation/, inside';

$input = <<EOF;
src
!/src/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('src', 1), 'exclude: /negation/';
ok !$matcher->match('src/hello.c'), 'exclude: /negation/, inside';

$input = <<EOF;
src
!src/*.c
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('src', 1), 'exclude: directory inside';
ok $matcher->match('src/hello.c'), 'exclude: file inside';

$input = <<EOF;
src
!src/sample
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('src', 1), 'exclude: directory';
ok $matcher->match('src/sample'), 'exclude: file in directory';
ok $matcher->matchExclude('src', 1), 'exclude: directory';
ok $matcher->matchExclude('src/sample'), 'exclude: file in directory';

$input = <<EOF;
node_modules/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('node_modules', 0), 'non-directory match';
ok $matcher->match('node_modules', 1), 'explicit directory match';
ok $matcher->match('node_modules/'), 'implicit directory match';
ok $matcher->match('node_modules/', 0), 'implicit override directory match';

SKIP: {
    skip "avoid git warning", 2 if $ENV{FILE_GLOBSTAR_GIT_CHECK_IGNORE};

    $input = <<EOF;
/
EOF
    $matcher = File::Globstar::ListMatch->new(\$input);
    # Leading slashes are invalid.  The pattern can never match.
    ok !$matcher->match('/'), 'slash';
    ok !$matcher->match('/top-level'), 'top-level';
}

$input =<<EOF;
\/foobar
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('foobar'), 'escaped leading slash';

$input =<<EOF;
foobar\/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('foobar'), 'escaped trailing slash';

$input =<<EOF;
\/foobar\/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->match('foobar'), 'two escaped slashes';

$input =<<EOF;
*/**/index.md
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('bg/some/thing/index.md'), 'matching inner globstar';
ok $matcher->match('bg/index.md'), 'non-matching inner globstar';

$input =<<EOF;
nested/dir/**
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->match('nested/dir/deep/inside'), 'trailing globstar inside';
ok $matcher->match('nested/dir/'), 'trailing globstar, trailing slash';
SKIP: {
    # This should match but does not in git.  The documentation
    # in gitignore(5) is a little vague there, saying that '"/**"
    # matches everything inside' but does not say wether it matches
    # the directory itself or not.  Bash globstar does match, and so
    # do we.
    skip "git bug", 1 if $ENV{FILE_GLOBSTAR_GIT_CHECK_IGNORE};
    ok $matcher->match('nested/dir'), 'trailing globstar, empty';
}

# This file gets required by the git test!

1;
