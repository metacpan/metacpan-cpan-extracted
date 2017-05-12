#!/usr/bin/env perl
#
# Test processing of URIs
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::URIs;
use Mail::Message::Field::Full;

use Test::More tests => 33;

my $mmff  = 'Mail::Message::Field::Full';
my $mmfu  = 'Mail::Message::Field::URIs';

#
# Test single URI
#

my $u = URI->new('http://x.org');
ok(defined $u,                                  "uri creation");
isa_ok($u, 'URI');
is($u->scheme, 'http');

my $uf = $mmfu->new('List-Post' => $u);
ok(defined $uf,                                 "uri field creation");
isa_ok($uf, $mmfu);
is($uf->string, "List-Post: <http://x.org/>\n");
is("$uf", '<http://x.org/>');
my @u = $uf->URIs;
cmp_ok(@u, '==', 1);
isa_ok($u[0], 'URI');

$uf = $mmfu->new('List-Post' => $u);
my $u2 = $uf->addURI('mailto:x@example.com?subject=y');
ok(defined $u2,                                 "auto-create URI");
isa_ok($u2, "URI");
@u = $uf->URIs;
cmp_ok(@u, '==', 2);
isa_ok($u[1], 'URI');
is($u[1]->scheme, "mailto");
is($u[1]->to, 'x@example.com');

my %headers = $u[1]->headers;
is($headers{to}, 'x@example.com');
is($headers{subject}, 'y');
is($uf->string, <<'FOLDED');
List-Post: <http://x.org/>, <mailto:x@example.com?subject=y>
FOLDED

is("$uf", '<http://x.org/>, <mailto:x@example.com?subject=y>');

#
# Test other constructions
#

$uf = $mmff->new("List-Post: <mailto:x\@y.com>, <http://A.org>\n");
ok(defined $uf,                               "create from field");
isa_ok($uf, $mmff);
isa_ok($uf, $mmfu);
@u = $uf->URIs;
cmp_ok(@u, '==', 2);
isa_ok($u[0], 'URI');
is($u[0]->scheme, "mailto");
is($u[0]->to, 'x@y.com');
is("$u[0]", 'mailto:x@y.com');
isa_ok($u[1], 'URI');
is($u[1]->scheme, "http");
is("$u[1]", 'http://a.org/');  # modified by URI::canonical()

is("$uf", '<mailto:x@y.com>, <http://A.org>');
is($uf->string, <<'FOLDED');
List-Post: <mailto:x@y.com>, <http://A.org>
FOLDED

$uf->beautify;
is("$uf", '<http://a.org/>, <mailto:x@y.com>');
