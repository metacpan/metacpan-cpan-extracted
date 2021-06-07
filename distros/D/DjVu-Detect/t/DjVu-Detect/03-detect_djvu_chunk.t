use strict;
use warnings;

use DjVu::Detect qw(detect_djvu_chunk);
use File::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $ret = detect_djvu_chunk($data_dir->file('11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu')->s, 'INFO');
is($ret, 1, "'INFO' chunk is present.");

# Test.
$ret = detect_djvu_chunk($data_dir->file('11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu')->s, 'FOO');
is($ret, 0, "'FOO' chunk isn't present.");
