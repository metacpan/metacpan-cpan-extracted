use strict;
use warnings;

use Test::More (tests => 8);
use Test::Exception;
use File::Temp qw/ tempfile tempdir /;

require_ok( 'Git::LowLevel')            or BAIL_OUT "Can't load Git::LowLevel";
require_ok( 'Git::LowLevel::Reference') or BAIL_OUT "Can't load Git::LowLevel::Reference";
require_ok( 'Git::LowLevel::Tree')      or BAIL_OUT "Can't load Git::LowLevel::Tree";
require_ok( 'Git::LowLevel::Blob')      or BAIL_OUT "Can't load Git::LowLevel::Blob";

#get us a temporary directory for the test git repository
my $git_dir     = tempdir( CLEANUP => 1 );

dies_ok { Git::LowLevel->new(git_dir=>$git_dir) } 'using non git repository in Git::LowLevel->new';

#create a git repository inside
system("cd " . $git_dir . "; git init");

lives_ok { Git::LowLevel->new(git_dir=>$git_dir) } 'using git repository in Git::LowLevel->new';

my $repository = Git::LowLevel->new(git_dir=>$git_dir);

#check if a non existing reference is identified as not exist
my $ref = $repository->getReference("refs/heads/branch");

ok(!$ref->exist() , "non existing reference identified as exist");

# check if tree of non existing reference is empty
my $tree = $ref->getTree();
ok($tree->empty(),"tree of non existing reference is empty");




done_testing;
