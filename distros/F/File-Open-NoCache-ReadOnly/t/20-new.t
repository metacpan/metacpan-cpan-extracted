#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 2;

use_ok('File::Open::NoCache::ReadOnly');

# isa_ok(File::Open::NoCache::ReadOnly->new(), 'File::Open::NoCache::ReadOnly', 'Creating File::Open::NoCache::ReadOnly object');
# isa_ok(File::Open::NoCache::ReadOnly::new(), 'File::Open::NoCache::ReadOnly', 'Creating File::Open::NoCache::ReadOnly object');
# isa_ok(File::Open::NoCache::ReadOnly->new->new(), 'File::Open::NoCache::ReadOnly', 'Cloning File::Open::NoCache::ReadOnly object');
ok(!defined(File::Open::NoCache::ReadOnly::new()));
