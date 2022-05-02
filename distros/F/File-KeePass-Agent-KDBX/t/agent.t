#!/usr/bin/env perl

use warnings;
use strict;

use File::Spec;
use FindBin qw($Bin);
use Test::More;

my $os = lc $^O;
plan skip_all => 'OS not supported' if $os ne 'unix' && $os ne 'linux';

require File::KeePass::Agent::KDBX;

my $class = File::KeePass::Agent::KDBX->keepass_class;
is $class, 'File::KeePass::KDBX', 'Get class from keepass_class method';

is File::KeePass::Agent::KDBX::keepass_class(), 'File::KeePass::KDBX',
    'Get class from keepass_class subroutine';

my $agent = File::KeePass::Agent::KDBX->new(keepass_class => 'File::KeePass::KDBX');
is $agent->keepass_class, 'File::KeePass::KDBX', 'Get class from an agent instance';

my $k = $agent->load_keepass(File::Spec->catfile($Bin, 'files', 'Format300.kdbx'), 'a');
isa_ok $k, 'File::KeePass::KDBX', 'Load the correct keepass class from the agent';

is $k->header->{database_name}, 'Test Database Format 0x00030000',
    'Verify the database loaded by the agent';

done_testing;
