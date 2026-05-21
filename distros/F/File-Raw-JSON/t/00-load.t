#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;

# Smoke: module loaded, plugins registered.

ok(defined $File::Raw::JSON::VERSION, 'VERSION defined');
diag("File::Raw::JSON $File::Raw::JSON::VERSION, "
    . "File::Raw $File::Raw::VERSION, Perl $], $^X");

my $names = File::Raw::list_plugins();
my %have  = map { $_ => 1 } @$names;
ok($have{json},  q('json' plugin registered at BOOT));
ok($have{jsonl}, q('jsonl' plugin registered at BOOT));

ok(defined &File::Raw::JSON::Boolean::TRUE,  'Boolean::TRUE defined');
ok(defined &File::Raw::JSON::Boolean::FALSE, 'Boolean::FALSE defined');

done_testing;
