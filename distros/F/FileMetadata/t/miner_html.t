use FileMetadata::Miner::HTML;
use Test;
use strict;
use utf8;

BEGIN { plan tests => 5}

my $miner = FileMetadata::Miner::HTML->new ({});

# 1. Test with non existent file
ok($miner->mine ('t/not_exist.html', {}), 0);

# 2. Test with file1
my $meta = {};
ok ($miner->mine ('t/miner_html/file1.html', $meta));

# 3. Test to see we have all the keys
ok (   defined $meta->{'FileMetadata::Miner::HTML::title'}
    && defined $meta->{'FileMetadata::Miner::HTML::test1'}
    && defined $meta->{'FileMetadata::Miner::HTML::test2'});

# 4. Check value of title
ok ($meta->{'FileMetadata::Miner::HTML::title'} eq 'This is a test');


# 5. Check value of other keys
ok (   $meta->{'FileMetadata::Miner::HTML::test1'} eq 'test1val'
    && $meta->{'FileMetadata::Miner::HTML::test2'} eq 'test2val');

# TODO : Do more tests with other files
