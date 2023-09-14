# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl File-Meta-Cache.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;#tests => 1;
use File::Temp qw<mktemp>;

BEGIN { use_ok('File::Meta::Cache') };
use File::Meta::Cache;


#######################
# Make some test files
#
my @file=map mktemp("temp.XXXXXXXX"), 1..1;
`touch $_` for @file;

######################
# Create File Meta Cache
my $cache=File::Meta::Cache->new;

ok defined($cache), "Cache defined";

####################
# Basic test that opening multiple times returns the same value

my $entry=$cache->open($file[0],0);
ok defined($entry), "Open file";

# Test same entry is returned
my $entry2=$cache->open($file[0]);
ok $entry2==$entry, "Same entry";

# Refernce count should be  now (2 external 1 internal)
#
ok $entry->[File::Meta::Cache::valid_]==3, "Reference count";


#Close the entry
$cache->close($entry);

$cache->close($entry2);

# Ref count should now be 1.
ok $entry->[File::Meta::Cache::valid_]==1, "Reference count";

# This should remove the entry
$cache->sweep;

ok $entry->[File::Meta::Cache::valid_]==0, "Entry invalidated";


# So when reopening it, whe shoul have a different array ref
use Fcntl qw<O_RDWR O_WRONLY>;
$entry2=$cache->open($file[0]);

ok $entry!=$entry2, "Different entry";



# Force reopening of file in read write mode


$entry=$cache->open($file[0],O_RDWR, 1);
ok $entry->[File::Meta::Cache::fd_]==$entry2->[File::Meta::Cache::fd_], "Reopend to same fd";




# Test filehandle
# Writing to cached entry
my $ret;
syswrite $entry->[File::Meta::Cache::fh_], "hello";

# Forcing a reopen on the cache entry
# and appending to the file
$entry=$cache->open($file[0], O_RDWR, 1);

# File size should be updated with a force open
#
ok $entry->[File::Meta::Cache::stat_][7]== 5, "File size";

sysseek $entry->[File::Meta::Cache::fh_], 0, 2;
syswrite $entry->[File::Meta::Cache::fh_], "hello";


# Reading the file from the begining
#
sysseek $entry->[File::Meta::Cache::fh_], 0, 0;
my $ret=sysread $entry->[File::Meta::Cache::fh_], my $data, 4096;



ok $data eq "hellohello", "Reopened file content ok";



$cache->update($entry);
# File size should be updated with an update
#
ok $entry->[File::Meta::Cache::stat_][7]== 10, "File size";
# Clean up

unlink $_ for @file;

# Very basic code coverage of disable and enable

ok defined $cache->disable, "Disable ok";

ok defined $cache->enable;

done_testing;
