

#########################

use strict;
use warnings;

use Test::More;
use Cwd;
use File::chdir;

use Archive::Tar;

diag "\n\nExtract TV Shows from tar.gz file for testing. This will be removed in the final test\n";
my $tar = Archive::Tar->new;
$tar->read("t/tv-shows.tar.gz");
{
  local $CWD = getcwd . "/t/";
  $tar->extract;
}

my $testdata = Archive::Tar->new;
$testdata->read("t/test-data.tar.gz");
{
  local $CWD = getcwd . "/t/";
  $testdata->extract;
}

diag "\n\nCheck that we have working Testing directories test-data and TV Shows\n";
my $sourceDir = getcwd . '/t/test-data/';

my $ShowDirectory = getcwd . '/t/TV Shows/';

my $filename = $sourceDir;

ok (-d $filename, 'Show Source Directory path is valid') or BAIL_OUT("test-data is not valid.\n");

$filename = $ShowDirectory;

ok (-d $filename, 'TV Show Directory path is valid') or BAIL_OUT("TV Show is not valid.\n");

done_testing();
