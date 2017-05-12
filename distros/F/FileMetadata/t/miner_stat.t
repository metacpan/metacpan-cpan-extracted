use Test;
use strict;
use POSIX qw(strftime);

BEGIN { plan tests => 10}
my $test_pkg = 'FileMetadata::Miner::Stat';

use FileMetadata::Miner::Stat;

# 1. Test instantiation with empty config to get defaults
my $config = {};
my $miner = FileMetadata::Miner::Stat->new ($config);
ok(1);

# 2. Test the mine method on non existent file
ok (!$miner->mine ('t/not_exist.t', {}));

# Test return values with default config on good file

# 3. Test return for existing file
my $meta = {};
ok ($miner->mine ('t/miner_stat.t', $meta));

# 4. Test to see all keys exist
my ($size, $atime, $mtime, $ctime) = (stat ('t/miner_stat.t'))[7..10];
ok (   defined $meta->{$test_pkg."::size"}
    && defined $meta->{$test_pkg."::ctime"}
    && defined $meta->{$test_pkg."::type"}
    && defined $meta->{$test_pkg."::mtime"});

# 5. Test to see ctime is right
ok (strftime ('%T-%D', localtime($ctime)), $meta->{$test_pkg."::ctime"});

# 6. Test to see mtime is right
ok (strftime ('%T-%D', localtime($mtime)), $meta->{$test_pkg."::mtime"});

# 7. Test to see size is right
ok ($size, $meta->{$test_pkg."::size"});

# 8. Test invalid size config
$config = {};
$config->{'size'} = 'LK';
eval {my $temp = FileMetadata::Miner::Stat->new ($config)};
ok (!("$@" eq ''));

# 9. Test size config KB
$config->{'size'} = 'KB';
$miner = FileMetadata::Miner::Stat->new ($config);
$meta = {};
$miner->mine ('t/miner_stat.t', $meta);
ok ($size/1024 . " KB", $meta->{$test_pkg."::size"});

# 10. Test size config KB
$config->{'size'} = 'MB';
$miner = FileMetadata::Miner::Stat->new ($config);
$meta = {};
$miner->mine ('t/miner_stat.t', $meta);
ok ($size/(1024*1024) ." MB", $meta->{$test_pkg."::size"});

# Test to make sure that file type is right

# TODO : Test Date Config
