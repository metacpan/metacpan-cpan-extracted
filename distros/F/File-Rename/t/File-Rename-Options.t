# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Rename.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('File::Rename::Options') };

#########################

# test 2

my $ok = do { local @ARGV = (1); File::Rename::Options::GetOptions() };
ok($ok, 'File::Rename::Options::GetOptions' );

ok(	
    $File::Rename::Options::VERSION <= 
    do { require File::Rename; eval $File::Rename::VERSION },
    'File::Rename::Option version not ahead of distribution version'
)

