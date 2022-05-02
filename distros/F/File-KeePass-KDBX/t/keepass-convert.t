#!/usr/bin/env perl

# This is copied nearly verbatim from the File::KeePass distribution to test that File::KeePass::KDBX passes
# the same tests.

use strict;
use warnings;

use File::KeePass::KDBX;
use Test::More;

eval { require File::KeePass } or plan skip_all => 'File::KeePass required to test KDB conversions';

my $pass = "foo";
my $ok;

my $obj1_1 = File::KeePass::KDBX->new;
my $obj1_2 = File::KeePass::KDBX->new;
my $obj2_1 = File::KeePass::KDBX->new;
my $obj2_2 = File::KeePass::KDBX->new;
my $G1 = $obj1_1->add_group({ title => 'personal' });
my $G2 = $obj1_1->add_group({ title => 'career',  group => $G1 });
my $G3 = $obj1_1->add_group({ title => 'finance', group => $G1 });
my $G4 = $obj1_1->add_group({ title => 'banking', group => $G2 });
my $G5 = $obj1_1->add_group({ title => 'credit',  group => $G2 });
my $G6 = $obj1_1->add_group({ title => 'health',  group => $G1 });
my $G7 = $obj1_1->add_group({ title => 'web',     group => $G1 });
my $G8 = $obj1_1->add_group({ title => 'hosting', group => $G7 });
my $G9 = $obj1_1->add_group({ title => 'mail',    group => $G7 });
my $G0 = $obj1_1->add_group({ title => 'Foo'      });

$obj1_1->add_entry({title => "Hey", group => $G1});
$obj1_1->add_entry({title => "Hey2", group => $G1});

$obj1_1->add_entry({title => "Hey3", group => $G5});

my $dump1 = "\n".eval { $obj1_1->dump_groups };

print "# v1 -> v1\n";
$ok = $obj1_2->parse_db($obj1_1->gen_db($pass), $pass, {auto_lock => 0});
my $dump2 = "\n".eval { $obj1_2->dump_groups };
is($dump1, $dump2, "Export v1/import v1 is fine"); TODO: {
    local $TODO = 'File::KeePass::KDBX defaults to a version 2 database';
    is(eval{$obj1_1->header->{'version'}}, undef, 'No version set on pure gen object');
    is($obj1_2->header->{'version'}, 1, 'Correct version 1 of re-import');
};
is(eval{$obj1_1->header->{'version'}}, 2, 'Sersion set on pure gen object');
is($obj1_2->header->{'version'}, 2, 'Correct version 2 of re-import');

print "# v1 new -> v2\n";
$ok = $obj2_1->parse_db($obj1_1->gen_db($pass, {version => 2}), $pass, {auto_lock => 0});
my $dump3 = "\n".eval { $obj2_1->dump_groups };
is($dump2, $dump3, "Export from v1 to v2/import v2 is fine");
TODO: {
    local $TODO = 'File::KeePass::KDBX defaults to a version 2 database';
    is(eval{$obj1_1->header->{'version'}}, undef, 'No version set on pure gen object');
};
is($obj2_1->header->{'version'}, 2, 'Correct version 2 of re-import');

print "# v1 -> v2\n";
$ok = $obj2_1->parse_db($obj1_2->gen_db($pass, {version => 2}), $pass, {auto_lock => 0});
my $dump4 = "\n".eval { $obj2_1->dump_groups };
is($dump3, $dump4, "Export from v1 to v2/import v2 is fine");
is($obj1_2->header->{'version'}, 2, 'V1 object changed to v2');
is($obj2_1->header->{'version'}, 2, 'Correct version 2 of re-import');

print "# v2 -> v2\n";
$ok = $obj2_2->parse_db($obj2_1->gen_db($pass), $pass, {auto_lock => 0});
my $dump5 = "\n".eval { $obj2_2->dump_groups };
is($dump4, $dump5, "Export v2/import v2 is fine");
is($obj2_1->header->{'version'}, 2, 'Correct version 2');
is($obj2_2->header->{'version'}, 2, 'Correct version 2 of re-import');

print "# v2 -> v1\n";
$ok = eval { $obj1_1->parse_db($obj2_2->gen_db($pass, {version => 1}), $pass, {auto_lock => 0}) };
ok($ok, "Gen and parse a db") or diag "Error: $@";
my $dump6 = "\n".eval { $obj1_1->dump_groups };
TODO: {
    local $TODO = 'File::KeePass::KDBX always generates 128-bit UUIDs which are lossfully converted';
    is($dump5, $dump6, "Export v2/import v1 is fine");
};
is($obj2_2->header->{'version'}, 1, 'Correct version 1');
is($obj1_1->header->{'version'}, 1, 'Correct version 1 of re-import');

done_testing;
