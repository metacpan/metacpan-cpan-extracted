use strict;
use warnings;

use Test::More tests => 2;
use Cwd;
use File::chdir;
use File::Path 'remove_tree';

diag "\n\nRemove TV Show and test-data Folders after competing tests\n";
{
  local $CWD = getcwd() . "/t/";
  remove_tree("TV Shows");
  ok(!-e $CWD . "TV Shows", "Successfully removed TV Show Folder.");
  remove_tree("test-data", "Successfully Removed test-data Folder.");
  ok(!-e $CWD . "test-data");
}
