#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Document::Stembolt::Content;

my $content;
$content = Document::Stembolt::Content->read_string(<<_END_);
# vim: #
---
hello: world
---
This is the body
_END_

ok($content);
is($content->preamble, "# vim: #\n");
cmp_deeply($content->header, { qw/hello world/ });
cmp_deeply($content->body, "This is the body\n");

$content->read_string(<<_END_);
bye: world
---
A different body
_END_

ok($content);
is($content->preamble, undef);
cmp_deeply($content->header, { qw/bye world/ });
cmp_deeply($content->body, "A different body\n");

$content->read_string(<<_END_);
Just a body
_END_

ok($content);
is($content->preamble, undef);
cmp_deeply($content->header, {});
cmp_deeply($content->body, "Just a body\n");

$content->header({ qw/alpha beta/ });
is($content->write_string, <<_END_);
alpha: beta
---
Just a body
_END_

$content->preamble(\"Whatever");
is($content->write_string, <<_END_);
Whatever
---
alpha: beta
---
Just a body
_END_

$content = Document::Stembolt::Content->new;
$content->header->{1} = 0;
is($content->write_string, <<_END_);
1: 0
---
_END_

open DOCUMENT, "t/assets/document";
$content = Document::Stembolt::Content->read( \*DOCUMENT );
is($content->preamble, "# vim: #\n");
cmp_deeply($content->header, { qw/hello world/ });
cmp_deeply($content->body, "This is the body\n");
