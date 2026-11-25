#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 12;

use_ok('File::URIList');
use_ok('Data::Identifier');

my $data = '';
open(my $fh, '+<', \$data);

my $list = File::URIList->new($fh);
isa_ok($list, 'File::URIList');

$list->write_comment('Hello World!');
is($data, "# Hello World!\015\012", 'Comment worked');

# XXX: Clear fails on memory handles because of truncate().
$list->rewind;
substr($data, 0) = '';
is(length($data), 0, 'List cleared');

$list->write_list('https://example.org', Data::Identifier->new(sid => 1));
is($data, "https://example.org\015\012urn:uuid:ddd60c5c-2934-404f-8f2d-fcb4da88b633\015\012", 'Write worked');

$list->rewind;

my $array = $list->read_as_list;
is(ref($array), 'ARRAY', 'Read back as array');
is(scalar(@{$array}), 2, 'Correct size');
isa_ok($_, 'URI', 'typematch') foreach @{$array};
is($array->[0].'', 'https://example.org', 'entry 0 match');
is($array->[1].'', 'urn:uuid:ddd60c5c-2934-404f-8f2d-fcb4da88b633', 'entry 1 match');

exit 0;
