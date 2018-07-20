use strict;
use warnings;

use Test::More (tests => 12);
use Test::Exception;
use File::Temp qw/ tempfile tempdir /;

require_ok( 'Git::LowLevel')            or BAIL_OUT "Can't load Git::LowLevel";
require_ok( 'Git::LowLevel::Reference') or BAIL_OUT "Can't load Git::LowLevel::Reference";
require_ok( 'Git::LowLevel::Tree')      or BAIL_OUT "Can't load Git::LowLevel::Tree";
require_ok( 'Git::LowLevel::Blob')      or BAIL_OUT "Can't load Git::LowLevel::Blob";


#get us a temporary directory for the test git repository
my $git_dir     = tempdir( CLEANUP => 1 );

#create a git repository inside
system("cd " . $git_dir . "; git init");

my $repository = Git::LowLevel->new(git_dir=>$git_dir);
my $ref        = $repository->getReference("refs/heads/branch");
my $tree       = $ref->getTree();

#create a new blob in the root of the tree of non existing reference refs/heads/branch
my $blob=$tree->newBlob();
$blob->path("test");
$blob->_content("this is a test");
lives_ok {$tree->add($blob)} "add Git::LowLevel::Blob object to tree";
dies_ok {$tree->add("string")} "add a string to tree";

# check if tree is not empty anymore
ok(!$tree->empty(),"tree not empty after adding blob");

#commit the tree to the reference
lives_ok {$ref->commit("added blob")} "commit the tree to the reference";

# create a new repository object and check if everything just created exist
my $repository2 = Git::LowLevel->new(git_dir=>$git_dir);
my $ref2        = $repository2->getReference("refs/heads/branch");

#now check if the reference exist
ok($ref2->exist(), "creating/commiting worked");

my $tree2 = $ref2->getTree();
ok(!$tree2->empty(), "tree ist not empty after creating blob");

#check if we can find the blob
my $file = $tree->find("test");

ok(defined($file), "blob test found");
ok($file->content() eq "this is a test", "check correct content of blob");
