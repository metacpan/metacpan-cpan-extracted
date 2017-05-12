use FileMetadata::Miner::Ext;
use Test;
use strict;

BEGIN { plan tests => 5}

my $miner = FileMetadata::Miner::Ext->new ({});

# 1. Test with non existent file
ok($miner->mine ('t/not_exist', {}));

# 2. Test with file1.ext
my $meta = {};
ok ($miner->mine ('t/miner_ext/file1', $meta));

# 3. Test to see we have all the keys
ok (   defined $meta->{'FileMetadata::Miner::Ext::title'}
    && defined $meta->{'FileMetadata::Miner::Ext::test1'}
    && defined $meta->{'FileMetadata::Miner::Ext::test2'});

# 4. Check value of title
ok ($meta->{'FileMetadata::Miner::Ext::title'} eq 'This is a test');


# 5. Check value of other keys
ok (   $meta->{'FileMetadata::Miner::Ext::test1'} eq 'test1val'
    && $meta->{'FileMetadata::Miner::Ext::test2'} eq 'test2val');

# TODO : Do more tests with other files
