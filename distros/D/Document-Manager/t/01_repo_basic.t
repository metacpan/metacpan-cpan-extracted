# Basic repo operations

use strict;
use Test::More tests => 4;

use Document::Repository;

my $dir = 'DMS';

if (-e $dir) { `rm -rf $dir`; }
ok ( ! -e $dir, "Verifying '$dir' does not exist" ) or
   diag("'$dir' already exists and cannot be removed");

my $repo = new Document::Repository( repository_dir => $dir, create_new_repository => 1 );
ok ( defined $repo, 'create new repository' ) or
   diag( $repo->get_error() );

my $filename = 't/test_doc.txt';
if (! -f $filename) { `echo 'testing...' > $filename`; }
ok ( -f $filename, "Ensuring existance of test file '$filename'" );

my $doc_id = $repo->add($filename);
ok ( defined $doc_id, 'adding a doc to the repository' ) or
   diag( $repo->get_error() );


