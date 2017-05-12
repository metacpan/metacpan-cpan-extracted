use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata::Zip';
eval "require $mod" or die $@;

my $base = 'corpus/Dist-Metadata-Test-NoMetaFile-0.1';

# test that instantiating this class directly does not negotiate type
new_ok($mod => [file => "$base.tgz"]);

my $file = "$base.zip";
my $zip = new_ok($mod => [file => $file]);

# file_content, and find_files tested in t/archive.t

# read_archive
isa_ok($zip->read_archive($file), 'Archive::Zip');

done_testing;
