# -*- perl -*-

use Test::More tests => 21;

BEGIN { use_ok( 'File::Find::Random' ); }
BEGIN { use_ok( 'Cwd' ); }

use strict;
use File::Spec::Functions;
my $orig_cwd = cwd();
chdir('t') if(-d 't');

my $last_file;
for(1..10) {
    srand(10);

    my $file = File::Find::Random->find('testdir');
    like($file, qr/testdir.\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file from the directory tree - '$file'");
    if($last_file) {
	is($last_file, $file, "Did it return the same file each time?");
    }
    $last_file = $file;
}
chdir($orig_cwd);
