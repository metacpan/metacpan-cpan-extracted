# Copyright (C) 2016-2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use common::sense;

use Test::More tests => 31;

use File::Globstar::ListMatch;

my ($matcher, $input);

$input = <<EOF;
hello.pl
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->matchInclude('hello.pl'), 'regular match';
ok $matcher->matchInclude('path/to/hello.pl'), 'basename match';
ok $matcher->matchInclude('/path/to/hello.pl'), 'basename match with leading slash';
ok !$matcher->matchInclude('goodbye.pl'), 'regular mismatch';
ok !$matcher->matchInclude('hello/goodbye.pl'), 'basename mismatch';


$input = <<EOF;
/hello.pl
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->matchInclude('hello.pl'), 'full path match';
ok !$matcher->matchInclude('path/to/hello.pl'), 'match in subdirectory';

$input = <<EOF;
*.o
!o.o
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->matchInclude('path/to/compiled.o'), 'wildcard match';
ok !$matcher->matchInclude('o.o'), 'negated match';
ok !$matcher->matchInclude('path/to/o.o'), 'negated match in subdirectory';

$input = <<EOF;
FooBar
EOF
$matcher = File::Globstar::ListMatch->new(\$input, ignoreCase => 1);
ok $matcher->matchInclude('FooBar'), 'ignoreCase exact';
ok $matcher->matchInclude('foobar'), 'ignoreCase lower';
ok $matcher->matchInclude('FOOBAR'), 'ignoreCase upper';

$input = <<EOF;
src
!src
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->matchInclude('src', 1), 'include: exact negation';
ok !$matcher->matchInclude('src/hello.c'), 'include: exact negation, inside';

$input = <<EOF;
src
!src
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->matchInclude('src', 1), 'exclude: exact negation';
ok !$matcher->matchInclude('src/hello.c'), 'exclude: exact negation, inside';

$input = <<EOF;
src
!/src
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->matchInclude('src', 1), 'exclude: /negation';
ok !$matcher->matchInclude('src/hello.c'), 'exclude: /negation, inside';

$input = <<EOF;
src
!src/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->matchInclude('src', 1), 'exclude: negation/';
ok !$matcher->matchInclude('src/hello.c'), 'exclude: negation/, inside';

$input = <<EOF;
src
!/src/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->matchInclude('src', 1), 'exclude: /negation/';
ok !$matcher->matchInclude('src/hello.c'), 'exclude: /negation/, inside';

$input = <<EOF;
src
!src/*.c
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->matchInclude('src', 1), 'exclude: directory inside';
ok !$matcher->matchInclude('src/hello.c'), 'exclude: file inside';

$input = <<EOF;
src
!src/sample
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok $matcher->matchInclude('src', 1), 'exclude: directory';
ok !$matcher->matchInclude('src/sample'), 'exclude: file in directory';

$input = <<EOF;
node_modules/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
ok !$matcher->matchInclude('node_modules', 0), 'non-directory match';
ok $matcher->matchInclude('node_modules', 1), 'explicit directory match';
ok $matcher->matchInclude('node_modules/'), 'implicit directory match';
ok $matcher->matchInclude('node_modules/', 0), 'implicit override directory match';
