use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw/ tempfile tempdir /;
use String::Random;
my $nr_tests=0;

require_ok( 'Git::LowLevel')            or BAIL_OUT "Can't load Git::LowLevel";
require_ok( 'Git::LowLevel::Reference') or BAIL_OUT "Can't load Git::LowLevel::Reference";
require_ok( 'Git::LowLevel::Tree')      or BAIL_OUT "Can't load Git::LowLevel::Tree";
require_ok( 'Git::LowLevel::Blob')      or BAIL_OUT "Can't load Git::LowLevel::Blob";
$nr_tests+=4;

my $runs=50;              # the number of test runs
$nr_tests+=($runs *4);

my $nr_references=20;     # number of different random references to use
my $max_ref_name=40;      # maximum number of chars in a reference name


#first generate reference names
my @references;
for(my $i=0; $i<$nr_references; $i++)
{
  my $string_gen = String::Random->new(max => $max_ref_name);
  my $name = "refs/heads/" . $string_gen->randregex('[a-zA-Z0-9_]+');
  push(@references, $name);
}

#get us a temporary directory for the test git repository
my $git_dir     = tempdir( CLEANUP => 1 );
#create a git repository inside
system("cd " . $git_dir . "; git init");

# run tests
for (my $i=0; $i<$runs; $i++)
{
  my $repository = Git::LowLevel->new(git_dir=>$git_dir);
  my $refname    = $references[int(rand($nr_references))];
  my $ref;
  lives_ok { $ref = $repository->getReference($refname) } "getting reference " . $refname;
  my $tree       = $ref->getTree();
  my $blob       = $tree->newBlob();
  my $string_gen = String::Random->new(max=>250);
  my $blobpath   = $string_gen->randregex('[a-zA-Z0-9]+');
  my $blobcontent= $string_gen->randregex('[a-zA-Z0-9]+');

  $blob->path($blobpath);
  $blob->_content($blobcontent);
  $tree->add($blob);
  $ref->commit("Added " . $blobpath);

  # now check if blob has been created
  my $repository2= Git::LowLevel->new(git_dir=>$git_dir);
  my $ref2       = $repository2->getReference($refname);

  #try to find blob
  my $file = $ref2->getTree()->find($blobpath);
  ok(defined($file), "find blob " . $blobpath);
  ok(ref($file) eq "Git::LowLevel::Blob","checking for Git::LowLevel::Blob object");
  ok($file->content() eq $blobcontent, "check correct content of blob " . $blobcontent);

}

# test different levels of trees
my $max_level=20;
for(my $i=0; $i<$runs; $i++)
{
  my $level=int(rand($max_level+1));
  $nr_tests+=$level*4+1;
  my $repository = Git::LowLevel->new(git_dir=>$git_dir);
  my $refname    = $references[int(rand($nr_references))];
  my $string_gen = String::Random->new(max=>250);
  my $ref;
  lives_ok { $ref = $repository->getReference($refname) } "getting reference " . $refname;

  my $tree = $ref->getTree();
  my $lasttree=$tree;
  my @trees;
  for(my $t=0; $t<$level; $t++)
  {
    my $nexttree=$lasttree->newTree();
    $nexttree->path($string_gen->randregex('[a-zA-Z0-9]+'));
    $lasttree->add($nexttree);
    push(@trees, $nexttree);
    $lasttree=$nexttree;
  }
  my $blob       = $lasttree->newBlob();
  my $blobpath   = $string_gen->randregex('[a-zA-Z0-9]+');
  my $blobcontent= $string_gen->randregex('[a-zA-Z0-9]+');
  $blob->path($blobpath);
  $blob->_content($blobcontent);
  $lasttree->add($blob);

  $ref->commit("Added tree" );

  #now check if the tree structure exists
  my $repository2 = Git::LowLevel->new(git_dir=>$git_dir);
  my $ref2        = $repository2->getReference($refname);
  my $tree2       = $ref2->getTree();

  my $parent=$tree2;
  for my $t (@trees)
  {
    my $test=$tree->find($t->path);
    ok(defined($test), "something was returned for " . $t->path);
    ok(ref($test) eq "Git::LowLevel::Tree", " Git::LowLevel::Tree object returned for " . $t->path);
    ok($test->path eq $t->path, "check same path in tree object for " . $t->path );
    ok($test->parent->path eq $t->parent->path, "check for same parent path for " . $t->path);

  }


}


done_testing($nr_tests);
